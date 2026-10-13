<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\ComplaintComment;
use App\Models\CommentReaction;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    // Bir şikayete ait yorumları getir
    public function index(
        Request $request,
        Complaint $complaint
    ) {
        $userId = $request->user()->id;

        $comments = ComplaintComment::where(
            'complaint_id',
            $complaint->id
        )
            ->with([
                'user:id,name',

                'reactions' => function ($query) use ($userId) {
                    $query->where(
                        'user_id',
                        $userId
                    );
                },
            ])
            ->withCount([
                'reactions as like_count' => function ($query) {
                    $query->where(
                        'reaction',
                        'like'
                    );
                },

                'reactions as dislike_count' => function ($query) {
                    $query->where(
                        'reaction',
                        'dislike'
                    );
                },
            ])
            ->orderBy('created_at', 'desc')
            ->get();

        $data = $comments->map(
            function ($comment) {
                $myReaction =
                    $comment->reactions->first();

                return [
                    'id' => $comment->id,
                    'complaint_id' =>
                        $comment->complaint_id,

                    'comment' =>
                        $comment->comment,

                    'user' => [
                        'id' =>
                            $comment->user->id,
                        'name' =>
                            $comment->user->name,
                    ],

                    'like_count' =>
                        $comment->like_count,

                    'dislike_count' =>
                        $comment->dislike_count,

                    'my_reaction' =>
                        $myReaction
                            ? $myReaction->reaction
                            : null,

                    'created_at' =>
                        $comment->created_at,
                ];
            }
        );

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    // Yeni yorum ekle
    public function store(
        Request $request,
        Complaint $complaint
    ) {
        $validated = $request->validate([
            'comment' =>
                'required|string|min:1|max:1000',
        ]);

        $commentText = trim(
            $validated['comment']
        );

        // Yorum içinde yasaklı kelime/ifade varsa kaydetme
        if (
            $this->containsForbiddenLanguage(
                $commentText
            )
        ) {
            return response()->json([
                'success' => false,
                'message' =>
                    'Yorumunuzda uygun olmayan ifadeler bulunmaktadır. Lütfen yorumunuzu düzenleyiniz.',
            ], 422);
        }

        $comment = ComplaintComment::create([
            'complaint_id' =>
                $complaint->id,

            'user_id' =>
                $request->user()->id,

            'comment' =>
                $commentText,
        ]);

        $comment->load('user:id,name');

        return response()->json([
            'success' => true,
            'message' =>
                'Yorum başarıyla eklendi.',

            'data' => [
                'id' =>
                    $comment->id,

                'complaint_id' =>
                    $comment->complaint_id,

                'comment' =>
                    $comment->comment,

                'user' => [
                    'id' =>
                        $comment->user->id,

                    'name' =>
                        $comment->user->name,
                ],

                'like_count' => 0,
                'dislike_count' => 0,
                'my_reaction' => null,

                'created_at' =>
                    $comment->created_at,
            ],
        ], 201);
    }

    // YouTube tarzı Like / Dislike
    public function react(
        Request $request,
        ComplaintComment $comment
    ) {
        $validated = $request->validate([
            'reaction' =>
                'required|in:like,dislike',
        ]);

        $userId = $request->user()->id;
        $newReaction =
            $validated['reaction'];

        $existingReaction =
            CommentReaction::where(
                'comment_id',
                $comment->id
            )
                ->where(
                    'user_id',
                    $userId
                )
                ->first();

        $myReaction = null;
        $action = '';

        // Kullanıcı daha önce hiç oy vermemiş
        if (!$existingReaction) {
            CommentReaction::create([
                'comment_id' =>
                    $comment->id,

                'user_id' =>
                    $userId,

                'reaction' =>
                    $newReaction,
            ]);

            $myReaction = $newReaction;
            $action = 'added';
        }

        // Aynı butona tekrar bastı:
        // Like -> Like = Like kaldır
        // Dislike -> Dislike = Dislike kaldır
        elseif (
            $existingReaction->reaction ===
            $newReaction
        ) {
            $existingReaction->delete();

            $myReaction = null;
            $action = 'removed';
        }

        // Diğer butona geçti:
        // Like -> Dislike
        // Dislike -> Like
        else {
            $existingReaction->update([
                'reaction' =>
                    $newReaction,
            ]);

            $myReaction = $newReaction;
            $action = 'changed';
        }

        $likeCount =
            CommentReaction::where(
                'comment_id',
                $comment->id
            )
                ->where(
                    'reaction',
                    'like'
                )
                ->count();

        $dislikeCount =
            CommentReaction::where(
                'comment_id',
                $comment->id
            )
                ->where(
                    'reaction',
                    'dislike'
                )
                ->count();

        return response()->json([
            'success' => true,

            'data' => [
                'comment_id' =>
                    $comment->id,

                'like_count' =>
                    $likeCount,

                'dislike_count' =>
                    $dislikeCount,

                'my_reaction' =>
                    $myReaction,

                'action' =>
                    $action,
            ],
        ]);
    }

    // Kullanıcı yalnızca kendi yorumunu silebilir
    public function destroy(
        Request $request,
        ComplaintComment $comment
    ) {
        if (
            (int) $comment->user_id !==
            (int) $request->user()->id
        ) {
            return response()->json([
                'success' => false,
                'message' =>
                    'Bu yorumu silme yetkiniz yok.',
            ], 403);
        }

        $comment->delete();

        return response()->json([
            'success' => true,
            'message' =>
                'Yorum silindi.',
        ]);
    }

    // Küfür/hakaret kontrolü için metni standartlaştırır.
    // Kullanıcının gerçek yorumunu değiştirmez.
    private function normalizeText(
        string $text
    ): string {
        $text = mb_strtolower(
            $text,
            'UTF-8'
        );

        $text = str_replace(
            ['ç', 'ğ', 'ı', 'ö', 'ş', 'ü'],
            ['c', 'g', 'i', 'o', 's', 'u'],
            $text
        );

        $text = preg_replace(
            '/[^a-z0-9\s]/u',
            ' ',
            $text
        );

        $text = preg_replace(
            '/\s+/',
            ' ',
            $text
        );

        return trim($text);
    }

    // config/profanity.php içindeki yasaklı kelime ve ifadeleri kontrol eder.
    private function containsForbiddenLanguage(
        string $text
    ): bool {
        $normalizedText =
            $this->normalizeText($text);

        $searchableText =
            ' ' . $normalizedText . ' ';

        foreach (
            config('profanity.words', [])
            as $forbiddenWord
        ) {
            $normalizedForbidden =
                $this->normalizeText(
                    $forbiddenWord
                );

            if ($normalizedForbidden === '') {
                continue;
            }

            $searchableForbidden =
                ' ' .
                $normalizedForbidden .
                ' ';

            if (
                str_contains(
                    $searchableText,
                    $searchableForbidden
                )
            ) {
                return true;
            }
        }

        return false;
    }
}
