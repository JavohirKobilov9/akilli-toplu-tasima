<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AccountDeletionService;
use Illuminate\Console\Command;

class DeleteExpiredFrozenAccounts extends Command
{
    protected $signature = 'accounts:delete-expired-frozen';

    protected $description =
        '90 günü dolan dondurulmuş hesapları ve bağlı verilerini siler.';

    public function handle(AccountDeletionService $deletionService): int
    {
        $limitDate = now()->subDays(90);

        $deletedCount = 0;
        $failedCount = 0;

        User::query()
            ->whereNotNull('frozen_at')
            ->where('frozen_at', '<=', $limitDate)
            ->where('role', '!=', 'super_admin')
            ->chunkById(100, function ($users) use (
                $deletionService,
                &$deletedCount,
                &$failedCount
            ) {
                foreach ($users as $user) {
                    try {
                        $deletionService->delete($user);

                        $deletedCount++;

                        $this->info(
                            "Kullanıcı #{$user->id} kalıcı olarak silindi."
                        );
                    } catch (\Throwable $e) {
                        report($e);

                        $failedCount++;

                        $this->error(
                            "Kullanıcı #{$user->id} silinemedi."
                        );
                    }
                }
            });

        $this->info(
            "İşlem tamamlandı. Silinen: {$deletedCount}, Hata: {$failedCount}."
        );

        return $failedCount > 0
            ? self::FAILURE
            : self::SUCCESS;
    }
}
