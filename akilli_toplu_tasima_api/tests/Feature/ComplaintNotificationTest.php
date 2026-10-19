<?php

namespace Tests\Feature;

use App\Models\Complaint;
use App\Models\ComplaintNotification;
use App\Models\User;
use App\Services\FirebasePushService;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ComplaintNotificationTest extends TestCase
{
    private ?string $isolatedSchema = null;

    protected function setUp(): void
    {
        parent::setUp();
        // RefreshDatabase kullanılmaz: mevcut proje verilerine dokunulmaz.
        $this->isolatedSchema = 'notification_test_' . bin2hex(random_bytes(8));
        DB::connection('pgsql')->statement('CREATE SCHEMA ' . $this->isolatedSchema);
        $connection = config('database.connections.pgsql');
        $connection['search_path'] = $this->isolatedSchema;
        config(['database.connections.notification_test' => $connection, 'database.default' => 'notification_test']);
        Artisan::call('migrate', ['--database' => 'notification_test', '--force' => true]);
        config(['services.firebase.project_id' => null, 'services.firebase.credentials' => null]);
    }

    protected function tearDown(): void
    {
        try {
            DB::disconnect('notification_test');
            if ($this->isolatedSchema !== null && preg_match('/^notification_test_[a-f0-9]{16}$/', $this->isolatedSchema)) {
                DB::connection('pgsql')->statement('DROP SCHEMA ' . $this->isolatedSchema . ' CASCADE');
            }
        } finally {
            parent::tearDown();
        }
    }

    private function user(string $role = 'user'): User
    {
        $user = User::factory()->create();
        $user->role = $role;
        $user->save();
        return $user;
    }

    private function complaint(?User $owner): Complaint
    {
        return Complaint::create([
            'user_id' => $owner?->id,
            'title' => 'Otobüs gecikti',
            'category' => 'Gecikme',
            'description' => 'Otobüs duraktan geç geldi.',
            'status' => 'Beklemede',
        ]);
    }

    public function test_both_admin_roles_notify_only_the_owner_and_skip_unchanged_status(): void
    {
        foreach (['admin', 'super_admin'] as $role) {
            $owner = $this->user();
            $complaint = $this->complaint($owner);
            Sanctum::actingAs($this->user($role));
            $url = '/api/complaints/' . $complaint->id . '/status';
            $this->patchJson($url, ['status' => 'İnceleniyor'])->assertOk();
            $this->patchJson($url, ['status' => 'İnceleniyor'])->assertOk();
            $this->patchJson($url, ['status' => 'Çözüldü'])->assertOk();
            $this->assertSame(2, ComplaintNotification::where('user_id', $owner->id)->count());
            $this->assertSame('Çözüldü', $complaint->fresh()->status);
        }
    }

    public function test_passenger_cannot_change_status_or_create_notification(): void
    {
        $owner = $this->user();
        $complaint = $this->complaint($owner);
        Sanctum::actingAs($owner);
        $this->patchJson('/api/complaints/' . $complaint->id . '/status', ['status' => 'Çözüldü'])->assertForbidden();
        $this->assertSame(0, ComplaintNotification::count());
        $this->assertSame('Beklemede', $complaint->fresh()->status);
    }

    public function test_notifications_are_private_and_read_state_is_idempotent(): void
    {
        $owner = $this->user();
        $complaint = $this->complaint($owner);
        Sanctum::actingAs($this->user('admin'));
        $this->patchJson('/api/complaints/' . $complaint->id . '/status', ['status' => 'Çözüldü'])->assertOk();
        $item = ComplaintNotification::firstOrFail();
        Sanctum::actingAs($this->user());
        $this->getJson('/api/notifications')->assertOk()->assertJsonPath('unread_count', 0)->assertJsonCount(0, 'data.data');
        $this->patchJson('/api/notifications/' . $item->id . '/read')->assertNotFound();
        Sanctum::actingAs($owner);
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 1);
        $this->patchJson('/api/notifications/' . $item->id . '/read')->assertOk();
        $readAt = $item->fresh()->read_at->toISOString();
        $this->patchJson('/api/notifications/' . $item->id . '/read')->assertOk();
        $this->assertSame($readAt, $item->fresh()->read_at->toISOString());
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 0);
    }

    public function test_guest_update_and_invalid_status_do_not_create_notifications(): void
    {
        $complaint = $this->complaint(null);
        Sanctum::actingAs($this->user('admin'));
        $url = '/api/complaints/' . $complaint->id . '/status';
        $this->patchJson($url, ['status' => 'invalid'])->assertUnprocessable();
        $this->assertSame('Beklemede', $complaint->fresh()->status);
        $this->patchJson($url, ['status' => 'Çözüldü'])->assertOk();
        $this->assertSame(0, ComplaintNotification::count());
    }

    public function test_push_device_is_removed_when_its_login_session_is_revoked(): void
    {
        $owner = $this->user();
        $token = $owner->createToken('test');
        $this->withToken($token->plainTextToken)->postJson('/api/push-devices', ['token' => 'test-device-token'])->assertOk();
        $this->assertSame(1, DB::table('push_devices')->count());
        $owner->tokens()->delete();
        $this->assertSame(0, DB::table('push_devices')->count());
    }

    public function test_notification_endpoints_require_login(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
        $this->patchJson('/api/notifications/1/read')->assertUnauthorized();
        $this->postJson('/api/push-devices', ['token' => 'device'])->assertUnauthorized();
    }

    public function test_push_payload_and_expired_device_cleanup_without_contacting_firebase(): void
    {
        $owner = $this->user();
        $complaint = $this->complaint($owner);
        $project = 'notification-test';
        $path = 'fake-credentials-not-read';
        config(['services.firebase.project_id' => $project, 'services.firebase.credentials' => $path]);
        Cache::put('fcm-oauth:' . hash('sha256', $project . ':' . $path), 'fake-oauth-token', 100);
        foreach (['active-device', 'expired-device'] as $device) {
            DB::table('push_devices')->insert([
                'user_id' => $owner->id, 'token' => $device,
                'token_hash' => hash('sha256', $device), 'created_at' => now(), 'updated_at' => now(),
            ]);
        }
        Http::fake(['fcm.googleapis.com/*' => function ($request) {
            return $request['message']['token'] === 'expired-device'
                ? Http::response(['error' => ['details' => [['errorCode' => 'UNREGISTERED']]]], 404)
                : Http::response(['name' => 'projects/notification-test/messages/123']);
        }]);
        Sanctum::actingAs($this->user('super_admin'));
        $this->patchJson('/api/complaints/' . $complaint->id . '/status', ['status' => 'Çözüldü'])->assertOk();
        Http::assertSentCount(2);
        Http::assertSent(fn ($request) =>
            $request->hasHeader('Authorization', 'Bearer fake-oauth-token') &&
            $request['message']['notification']['title'] === 'Şikayetinizin durumu güncellendi' &&
            $request['message']['data']['complaint_id'] === (string) $complaint->id
        );
        $this->assertSame(['active-device'], DB::table('push_devices')->pluck('token')->all());
    }

    public function test_push_failure_keeps_the_status_and_inbox_notification(): void
    {
        $owner = $this->user();
        $complaint = $this->complaint($owner);
        config(['services.firebase.project_id' => 'test', 'services.firebase.credentials' => 'fake']);
        Cache::put('fcm-oauth:' . hash('sha256', 'test:fake'), 'fake-token', 100);
        DB::table('push_devices')->insert([
            'user_id' => $owner->id, 'token' => 'device', 'token_hash' => hash('sha256', 'device'),
            'created_at' => now(), 'updated_at' => now(),
        ]);
        Http::fake(['fcm.googleapis.com/*' => Http::response([], 503)]);
        Sanctum::actingAs($this->user('admin'));
        $this->patchJson('/api/complaints/' . $complaint->id . '/status', ['status' => 'İnceleniyor'])->assertOk();
        Http::assertSentCount(1);
        $this->assertSame('İnceleniyor', $complaint->fresh()->status);
        $this->assertSame(1, ComplaintNotification::where('user_id', $owner->id)->count());
    }
}
