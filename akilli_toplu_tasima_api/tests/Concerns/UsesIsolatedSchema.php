<?php

namespace Tests\Concerns;

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

/**
 * Her test için geçici bir PostgreSQL şeması oluşturur ve sonra siler.
 * Böylece gerçek proje verilerine dokunulmaz (RefreshDatabase kullanılmaz).
 */
trait UsesIsolatedSchema
{
    private ?string $isolatedSchemaName = null;

    protected function createIsolatedSchema(): void
    {
        $this->isolatedSchemaName = 'feature_test_' . bin2hex(random_bytes(8));
        DB::connection('pgsql')->statement('CREATE SCHEMA ' . $this->isolatedSchemaName);
        $connection = config('database.connections.pgsql');
        $connection['search_path'] = $this->isolatedSchemaName;
        config(['database.connections.feature_test' => $connection, 'database.default' => 'feature_test']);
        Artisan::call('migrate', ['--database' => 'feature_test', '--force' => true]);
    }

    protected function dropIsolatedSchema(): void
    {
        DB::disconnect('feature_test');
        if ($this->isolatedSchemaName !== null && preg_match('/^feature_test_[a-f0-9]{16}$/', $this->isolatedSchemaName)) {
            DB::connection('pgsql')->statement('DROP SCHEMA ' . $this->isolatedSchemaName . ' CASCADE');
        }
    }
}
