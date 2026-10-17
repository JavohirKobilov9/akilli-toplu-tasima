<?php

namespace App\Services;

use App\Models\CommentReaction;
use App\Models\Complaint;
use App\Models\ComplaintComment;
use App\Models\EmailChangeCode;
use App\Models\PasswordResetCode;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class AccountDeletionService
{
    public function delete(User $user): void
    {
        $profilePhotoPath = $user->profile_photo_path;

        $mediaPaths = Complaint::where('user_id', $user->id)
            ->whereNotNull('media_path')
            ->pluck('media_path')
            ->filter()
            ->unique()
            ->values()
            ->all();

        DB::transaction(function () use ($user) {
            $complaintIds = Complaint::where(
                'user_id',
                $user->id
            )->pluck('id');

            $ownCommentIds = ComplaintComment::where(
                'user_id',
                $user->id
            )->pluck('id');

            $commentsOnOwnComplaints = ComplaintComment::whereIn(
                'complaint_id',
                $complaintIds
            )->pluck('id');

            $commentIds = $ownCommentIds
                ->merge($commentsOnOwnComplaints)
                ->unique()
                ->values();

            CommentReaction::where('user_id', $user->id)
                ->orWhereIn('comment_id', $commentIds)
                ->delete();

            ComplaintComment::where('user_id', $user->id)
                ->orWhereIn('complaint_id', $complaintIds)
                ->delete();

            Complaint::where('user_id', $user->id)->delete();

            PasswordResetCode::where('user_id', $user->id)
                ->delete();

            EmailChangeCode::where('user_id', $user->id)
                ->delete();

            $user->tokens()->delete();

            $user->delete();
        });

        $disk = Storage::disk('public');

        
if ($profilePhotoPath) {
    // Aynı profil fotoğrafını başka bir kullanıcı kullanıyorsa koru.
    $usedByAnotherUser = User::query()
        ->where('profile_photo_path', $profilePhotoPath)
        ->exists();

    if (!$usedByAnotherUser) {
        try {
            if (!$disk->delete($profilePhotoPath)) {
                Log::warning('Profil fotoğrafı silinemedi.', [
                    'user_id' => $user->id,
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning('Profil fotoğrafı silinirken hata oluştu.', [
                'user_id' => $user->id,
            ]);
        }
    }
}


        foreach ($mediaPaths as $path) {
            // Aynı dosya başka bir şikayette kullanılıyorsa koru.
            if (Complaint::where('media_path', $path)->exists()) {
                continue;
            }

            try {
                $disk->delete($path);
            } catch (\Throwable $e) {
                Log::warning('Şikayet medyası silinemedi.', [
                    'user_id' => $user->id,
                ]);
            }
        }
    }
}
