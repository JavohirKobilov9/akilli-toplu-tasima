<?php

namespace Tests\Feature;

use App\Models\Line;
use App\Models\Stop;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesIsolatedSchema;
use Tests\TestCase;

class AuthAndComplaintTest extends TestCase
{
    use UsesIsolatedSchema;

    protected function setUp(): void
    {
        parent::setUp();
        $this->createIsolatedSchema();
    }

    protected function tearDown(): void
    {
        try {
            $this->dropIsolatedSchema();
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

    private function line(string $code = 'BRT99'): Line
    {
        return Line::create([
            'code' => $code,
            'name' => 'Test Hattı',
            'transport_type' => 'Otobüs',
            'is_active' => true,
        ]);
    }

    private function payload(Line $line, array $override = []): array
    {
        return array_merge([
            'title' => 'otobüs geç geldi',
            'category' => 'Sefer Gecikmesi',
            'description' => 'Otobüs duraktan yirmi dakika geç geldi.',
            'line_id' => $line->id,
            'latitude' => 41.635,
            'longitude' => 32.337,
        ], $override);
    }

    public function test_login_returns_token_for_valid_credentials(): void
    {
        $user = $this->user();

        $this->postJson('/api/login', ['identifier' => $user->email, 'password' => 'password'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['token', 'user' => ['id', 'name']]);
    }

    public function test_login_rejects_wrong_password(): void
    {
        $user = $this->user();

        $this->postJson('/api/login', ['identifier' => $user->email, 'password' => 'yanlis-sifre'])
            ->assertStatus(422);
    }

    public function test_login_is_rate_limited(): void
    {
        $last = null;
        for ($i = 0; $i < 12; $i++) {
            $last = $this->postJson('/api/login', ['identifier' => "yok{$i}@example.com", 'password' => 'x']);
        }

        $last->assertStatus(429);
    }

    public function test_register_creates_account(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test Kullanıcı',
            'email' => 'yeni.kullanici@example.com',
            'password' => 'Sifre12345',
            'password_confirmation' => 'Sifre12345',
        ]);

        $this->assertContains($response->getStatusCode(), [200, 201], $response->getContent());
        $this->assertDatabaseHas('users', ['email' => 'yeni.kullanici@example.com']);
    }

    public function test_complaint_requires_login(): void
    {
        $line = $this->line();

        $this->postJson('/api/complaints', $this->payload($line))->assertStatus(401);
    }

    public function test_logged_in_user_can_create_complaint(): void
    {
        $line = $this->line();
        Sanctum::actingAs($this->user());

        $this->postJson('/api/complaints', $this->payload($line))
            ->assertStatus(201)
            ->assertJsonPath('data.status', 'Beklemede')
            ->assertJsonPath('data.title', 'Otobüs geç geldi');

        $this->assertDatabaseCount('complaints', 1);
    }

    public function test_complaint_validation_errors(): void
    {
        $line = $this->line();
        Sanctum::actingAs($this->user());

        $this->postJson('/api/complaints', $this->payload($line, ['description' => 'kısa']))->assertStatus(422);
        $this->postJson('/api/complaints', $this->payload($line, ['line_id' => 999999]))->assertStatus(422);
        $this->postJson('/api/complaints', $this->payload($line, ['latitude' => 120]))->assertStatus(422);
        $this->assertDatabaseCount('complaints', 0);
    }

    public function test_stop_must_belong_to_selected_line(): void
    {
        $line = $this->line('BRT98');
        $stop = Stop::create(['code' => 'DRK-TEST', 'name' => 'Başka Durak', 'latitude' => 41.6, 'longitude' => 32.3]);
        Sanctum::actingAs($this->user());

        $this->postJson('/api/complaints', $this->payload($line, ['stop_id' => $stop->id]))
            ->assertStatus(422)
            ->assertJsonValidationErrors('stop_id');
    }

    public function test_profanity_filter_blocks_complaint_text(): void
    {
        $line = $this->line();
        Sanctum::actingAs($this->user());

        $this->postJson('/api/complaints', $this->payload($line, ['description' => 'Şoför tam bir orospu çocuğu gibi davrandı.']))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
        $this->postJson('/api/complaints', $this->payload($line, ['title' => 'AMK şoför']))
            ->assertStatus(422);
        $this->assertDatabaseCount('complaints', 0);
    }

    public function test_profanity_filter_allows_clean_text(): void
    {
        $line = $this->line();
        Sanctum::actingAs($this->user());

        $this->postJson('/api/complaints', $this->payload($line, ['description' => 'Kampüs durağında otobüs hiç durmadı.']))
            ->assertStatus(201);
    }

    public function test_stops_endpoint_lists_active_stops_with_lines(): void
    {
        $line = $this->line('BRT97');
        $stop = Stop::create(['code' => 'DRK-1', 'name' => 'Merkez', 'latitude' => 41.635, 'longitude' => 32.337]);
        $hidden = Stop::create(['code' => 'DRK-2', 'name' => 'Pasif', 'latitude' => 41.6, 'longitude' => 32.3, 'is_active' => false]);
        $line->stops()->attach($stop->id, ['stop_order' => 1]);

        $response = $this->getJson('/api/stops')->assertOk();

        $this->assertSame(['Merkez'], collect($response->json('data'))->pluck('name')->all());
        $this->assertSame('BRT97', $response->json('data.0.lines.0.code'));
        $this->assertNotContains($hidden->name, collect($response->json('data'))->pluck('name')->all());
    }

    public function test_admin_complaint_list_requires_admin_role(): void
    {
        $this->getJson('/api/admin/complaints')->assertStatus(401);

        Sanctum::actingAs($this->user('user'));
        $this->getJson('/api/admin/complaints')->assertStatus(403);

        Sanctum::actingAs($this->user('admin'));
        $this->getJson('/api/admin/complaints')->assertOk()->assertJsonPath('success', true);
    }
}
