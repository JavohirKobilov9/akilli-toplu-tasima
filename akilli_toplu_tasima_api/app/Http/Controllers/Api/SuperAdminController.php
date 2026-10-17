<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class SuperAdminController extends Controller
{
    // Süper yönetici yardımcı yöneticileri listeler.
    public function admins(Request $request)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        $admins = User::query()
            ->where('role', 'admin')
            ->orderBy('name')
            ->get([
                'id',
                'name',
                'email',
                'role',
                'frozen_at',
            ])
            ->map(function (User $admin) {
                return [
                    'id' => $admin->id,
                    'name' => $admin->name,
                    'email' => $admin->email,
                    'role' => $admin->role,
                    'status' => $admin->frozen_at === null
                        ? 'Aktif'
                        : 'Dondurulmuş',
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $admins,
        ]);
    }

    // Yalnızca süper yönetici yeni yardımcı yönetici oluşturabilir.
    public function store(Request $request)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        // E-posta karşılaştırmalarının tutarlı olması için standartlaştır.
        $email = $request->input('email');
        if (is_string($email)) {
            $request->merge([
                'email' => mb_strtolower(trim($email), 'UTF-8'),
            ]);
        }

        $validated = $request->validate([
            'name' => 'required|string|min:2|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:8|max:72|confirmed',
        ], [
            'email.unique' => 'Bu e-posta adresi zaten kullanılıyor.',
            'password.confirmed' => 'Şifre tekrarı eşleşmiyor.',
        ]);

        // Rol, istemciden alınmaz. Sunucu tarafından atanır.
        $admin = User::create([
            'name' => trim($validated['name']),
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $admin->role = 'admin';
        $admin->save();

        return response()->json([
            'success' => true,
            'message' => 'Yardımcı yönetici hesabı oluşturuldu.',
            'data' => [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
                'role' => $admin->role,
                'status' => 'Aktif',
            ],
        ], 201);
    }

    // Süper yönetici bir yardımcı yöneticinin adını/e-postasını düzenler.
    public function update(Request $request, int $admin)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        // Yalnızca admin rolündeki hesaplar düzenlenebilir.
        // Süper yönetici veya normal kullanıcı hesabı hedeflenemez.
        $target = User::query()
            ->where('role', 'admin')
            ->findOrFail($admin);

        $email = $request->input('email');
        if (is_string($email)) {
            $request->merge([
                'email' => mb_strtolower(trim($email), 'UTF-8'),
            ]);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($target->id),
            ],
        ], [
            'email.unique' => 'Bu e-posta adresi başka bir hesapta kullanılıyor.',
        ]);

        $newEmail = $validated['email'];
        if ($target->email !== $newEmail) {
            $target->email_verified_at = null;
        }

        $target->name = trim($validated['name']);
        $target->email = $newEmail;
        $target->save();

        return response()->json([
            'success' => true,
            'message' => 'Yardımcı yönetici bilgileri güncellendi.',
            'data' => [
                'id' => $target->id,
                'name' => $target->name,
                'email' => $target->email,
                'role' => $target->role,
                'status' => $target->frozen_at === null ? 'Aktif' : 'Dondurulmuş',
            ],
        ]);
    }

    // Hesabı silmeden, yardımcı yöneticinin yönetim yetkisini kaldırır.
    public function revoke(Request $request, int $admin)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        // Süper adminin kendisi veya normal kullanıcılar etkilenmez.
        $target = User::query()
            ->where('role', 'admin')
            ->findOrFail($admin);

        $target->role = 'user';
        $target->save();

        // Eski yönetici oturumları artık API'ye erişemesin.
        $target->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Yönetici yetkisi kaldırıldı. Hesap normal kullanıcı olarak korundu.',
            'data' => [
                'id' => $target->id,
                'role' => $target->role,
            ],
        ]);
    }

    // Super admin, aktif normal kullanıcı hesaplarından birini yönetici yapabilir.
    // Yetkisi daha önce kaldırılan hesaplar da bu listede yer alır.
    public function users(Request $request)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        $users = User::query()
            ->where('role', 'user')
            ->whereNull('frozen_at')
            ->orderBy('name')
            ->get(['id', 'name', 'email', 'role'])
            ->map(function (User $user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    // Super admin normal kullanıcıyı tekrar/ilk kez yardımcı yönetici yapar.
    // Hesap ID, şifre ve şikayet kayıtları korunur.
    public function promote(Request $request, int $user)
    {
        if ($request->user()?->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için süper yönetici yetkisi gereklidir.',
            ], 403);
        }

        // Süper yöneticiler ve mevcut yöneticiler hedeflenemez.
        // Dondurulmuş hesapların yeniden etkinleşmeden terfi etmesi engellenir.
        $target = User::query()
            ->where('role', 'user')
            ->whereNull('frozen_at')
            ->findOrFail($user);

        $target->role = 'admin';
        $target->save();

        // Kullanıcı eski rolüyle açık oturum taşımasın; tekrar giriş yapsın.
        $target->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kullanıcı yardımcı yönetici yapıldı.',
            'data' => [
                'id' => $target->id,
                'name' => $target->name,
                'email' => $target->email,
                'role' => $target->role,
            ],
        ]);
    }
}
