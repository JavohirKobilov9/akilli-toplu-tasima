<?php

namespace Tests\Feature;

use App\Models\Complaint;
use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ComplaintMediaTest extends TestCase
{
    private ?string $isolatedSchema = null;

    protected function setUp(): void
    {
        parent::setUp();
        $this->isolatedSchema = 'media_test_' . bin2hex(random_bytes(8));
        DB::connection('pgsql')->statement('CREATE SCHEMA ' . $this->isolatedSchema);
        $connection = config('database.connections.pgsql');
        $connection['search_path'] = $this->isolatedSchema;
        config(['database.connections.media_test' => $connection, 'database.default' => 'media_test']);
        Artisan::call('migrate', ['--database' => 'media_test', '--force' => true]);
        Storage::fake('public');
    }

    protected function tearDown(): void
    {
        try {
            DB::disconnect('media_test');
            if ($this->isolatedSchema !== null && preg_match('/^media_test_[a-f0-9]{16}$/', $this->isolatedSchema)) {
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

    private function photo(User $owner): Complaint
    {
        $path = 'complaints/evidence.png';
        Storage::disk('public')->put($path, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWZkAAAAASUVORK5CYII='));
        $complaint = Complaint::create([
            'user_id' => $owner->id, 'title' => 'Durak sorunu', 'category' => 'Durak',
            'description' => 'Durakta bakım gerekiyor.', 'status' => 'Beklemede',
            'latitude' => 41.63, 'longitude' => 32.33,
        ]);
        $complaint->media_path = $path;
        $complaint->media_type = 'photo';
        $complaint->save();
        return $complaint;
    }

    public function test_owner_and_both_admin_roles_can_view_photo_but_other_users_cannot(): void
    {
        $owner = $this->user();
        $complaint = $this->photo($owner);
        $url = '/api/complaints/' . $complaint->id . '/media';
        $this->getJson($url)->assertUnauthorized();
        Sanctum::actingAs($this->user());
        $this->getJson($url)->assertForbidden();
        foreach ([$owner, $this->user('admin'), $this->user('super_admin')] as $viewer) {
            Sanctum::actingAs($viewer);
            $response = $this->get($url)->assertOk()->assertHeader('Content-Type', 'image/png');
            $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
            $this->assertStringContainsString('private', $response->headers->get('Cache-Control'));
        }
    }

    public function test_video_supports_byte_ranges_for_seeking(): void
    {
        $owner = $this->user();
        $complaint = $this->photo($owner);
        Storage::disk('public')->put('complaints/video.mp4', '0123456789');
        $complaint->media_path = 'complaints/video.mp4';
        $complaint->media_type = 'video';
        $complaint->save();
        Sanctum::actingAs($owner);
        $this->withHeader('Range', 'bytes=0-3')->get('/api/complaints/' . $complaint->id . '/media')
            ->assertStatus(206)->assertHeader('Content-Range', 'bytes 0-3/10')->assertHeader('Content-Length', '4');
    }

    public function test_missing_files_and_paths_outside_complaints_are_not_served(): void
    {
        $owner = $this->user();
        $complaint = $this->photo($owner);
        Sanctum::actingAs($owner);
        foreach (['complaints/missing.png', '../secret', 'complaints/../secret', null] as $path) {
            $complaint->media_path = $path;
            $complaint->save();
            $this->getJson('/api/complaints/' . $complaint->id . '/media')->assertNotFound();
        }
    }

    public function test_media_metadata_is_available_in_admin_and_passenger_responses(): void
    {
        $owner = $this->user();
        $complaint = $this->photo($owner);
        Sanctum::actingAs($this->user('admin'));
        $this->getJson('/api/admin/complaints')->assertOk()
            ->assertJsonPath('data.0.media_path', 'complaints/evidence.png')
            ->assertJsonPath('data.0.media_type', 'photo')
            ->assertJsonPath('data.0.latitude', '41.6300000');
        Sanctum::actingAs($owner);
        $this->getJson('/api/my-complaints')->assertOk()->assertJsonPath('data.0.media_type', 'photo');
        $this->getJson('/api/complaints/' . $complaint->id)->assertOk()->assertJsonPath('data.media_type', 'photo');
    }
}
