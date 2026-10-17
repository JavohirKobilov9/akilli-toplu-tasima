<?php

namespace App\Console\Commands;

use App\Models\Complaint;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CleanupOrphanComplaintMedia extends Command
{
    protected $signature =
        'complaints:cleanup-orphan-media
        {--dry-run : Dosyaları silmeden sadece göster}
        {--grace=60 : Son kaç dakika içindeki dosyalara dokunulmasın}';

    protected $description =
        'Veritabanında artık kullanılmayan şikayet fotoğraf ve videolarını temizler.';

    public function handle(): int
    {
        if (
            !Schema::hasColumn(
                'complaints',
                'media_path'
            )
        ) {
            $this->error(
                'complaints tablosunda media_path alanı bulunamadı.'
            );

            return self::FAILURE;
        }

        $disk = Storage::disk('public');

        $allFiles =
            $disk->allFiles('complaints');

        if (empty($allFiles)) {
            $this->info(
                'Temizlenecek medya dosyası bulunamadı.'
            );

            return self::SUCCESS;
        }

        $referencedFiles =
            Complaint::query()
                ->whereNotNull('media_path')
                ->pluck('media_path')
                ->map(
                    fn ($path) =>
                        $this->normalizePath(
                            (string) $path
                        )
                )
                ->filter()
                ->unique()
                ->flip();

        $dryRun =
            (bool) $this->option('dry-run');

        $graceMinutes =
            max(
                0,
                (int) $this->option('grace')
            );

        $limitTimestamp =
            now()
                ->subMinutes($graceMinutes)
                ->timestamp;

        $deletedCount = 0;
        $orphanCount = 0;
        $recentCount = 0;

        foreach ($allFiles as $file) {
            $normalizedFile =
                $this->normalizePath($file);

            if (
                $referencedFiles->has(
                    $normalizedFile
                )
            ) {
                continue;
            }

            try {
                $lastModified =
                    $disk->lastModified($file);
            } catch (\Throwable $e) {
                $this->warn(
                    "Dosya tarihi okunamadı: {$file}"
                );

                continue;
            }

            // Yeni yüklenmiş dosyayı yanlışlıkla
            // silmemek için bekleme süresi.
            if (
                $lastModified >
                $limitTimestamp
            ) {
                $recentCount++;
                continue;
            }

            $orphanCount++;

            if ($dryRun) {
                $this->line(
                    "[SİLİNECEK] {$file}"
                );

                continue;
            }

            if ($disk->delete($file)) {
                $deletedCount++;

                $this->line(
                    "[SİLİNDİ] {$file}"
                );
            } else {
                $this->warn(
                    "[SİLİNEMEDİ] {$file}"
                );
            }
        }

        if ($dryRun) {
            $this->info(
                "Dry-run tamamlandı. "
                . "{$orphanCount} yetim dosya bulundu. "
                . "{$recentCount} yeni dosyaya dokunulmadı."
            );
        } else {
            $this->info(
                "Temizlik tamamlandı. "
                . "{$deletedCount} dosya silindi. "
                . "{$recentCount} yeni dosyaya dokunulmadı."
            );
        }

        return self::SUCCESS;
    }

    private function normalizePath(
        string $path
    ): string {
        $path =
            str_replace(
                '\\',
                '/',
                trim($path)
            );

        $path =
            ltrim(
                $path,
                '/'
            );

        // Eğer ileride URL saklanırsa
        // /storage/... kısmını ayıklar.
        if (
            Str::contains(
                $path,
                '/storage/'
            )
        ) {
            $path =
                Str::after(
                    $path,
                    '/storage/'
                );
        }

        if (
            Str::startsWith(
                $path,
                'storage/'
            )
        ) {
            $path =
                Str::after(
                    $path,
                    'storage/'
                );
        }

        if (
            Str::startsWith(
                $path,
                'public/'
            )
        ) {
            $path =
                Str::after(
                    $path,
                    'public/'
                );
        }

        return $path;
    }
}