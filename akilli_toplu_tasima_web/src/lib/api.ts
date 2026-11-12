// Laravel REST API istemcisi. Mobil uygulama ile aynı uçları kullanır.
const BASE = (process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api").replace(/\/$/, "");

export const STATUSES = ["Beklemede", "İnceleniyor", "Çözüldü"] as const;
export type Status = (typeof STATUSES)[number];

export type User = { id: number; name: string; email: string | null; role: string };

export type Complaint = {
  id: number;
  title: string;
  category: string;
  description: string;
  media_path: string | null;
  media_type: string | null;
  latitude: string | number | null;
  longitude: string | number | null;
  line: { id: number; code: string; name: string } | null;
  stop: { id: number; name: string } | null;
  status: Status;
  created_at: string;
  user_name: string;
  user_email: string | null;
  user_phone: string | null;
  is_guest: boolean;
};

export class ApiError extends Error {
  constructor(message: string, public status: number) {
    super(message);
  }
}

async function request<T>(path: string, token: string | null, init: RequestInit = {}): Promise<T> {
  let res: Response;
  try {
    res = await fetch(`${BASE}${path}`, {
      ...init,
      headers: {
        Accept: "application/json",
        ...(init.body ? { "Content-Type": "application/json" } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });
  } catch {
    throw new ApiError("Sunucuya ulaşılamadı. API çalışıyor mu?", 0);
  }
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const firstError = body?.errors ? (Object.values(body.errors)[0] as string[])[0] : undefined;
    throw new ApiError(firstError ?? body?.message ?? `İstek başarısız (${res.status})`, res.status);
  }
  return body as T;
}

export const login = (identifier: string, password: string) =>
  request<{ token: string; user: User }>("/login", null, {
    method: "POST",
    body: JSON.stringify({ identifier, password }),
  });

export const logout = (token: string) => request("/logout", token, { method: "POST" }).catch(() => undefined);

export const getAdminComplaints = (token: string) =>
  request<{ data: Complaint[] }>("/admin/complaints", token).then((r) => r.data);

export const updateStatus = (token: string, id: number, status: Status) =>
  request(`/complaints/${id}/status`, token, { method: "PATCH", body: JSON.stringify({ status }) });

// Medya özel dosyadır; token ile çekilip geçici bir adrese çevrilir.
export async function fetchMediaUrl(token: string, id: number): Promise<string> {
  const res = await fetch(`${BASE}/complaints/${id}/media`, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new ApiError("Dosya açılamadı.", res.status);
  return URL.createObjectURL(await res.blob());
}

// Haritada gösterilmek için gereken en az alanlar (admin ve herkese açık liste ortak kullanır).
export type MapComplaint = {
  id: number;
  title: string;
  category: string;
  status: string;
  latitude: string | number | null;
  longitude: string | number | null;
  line: { code: string } | null;
};

// Herkese açık uçlar: giriş gerekmez. Kişisel veri haritaya aktarılmaz.
export const getPublicComplaints = () =>
  request<{ data: MapComplaint[] }>("/complaints", null).then((r) => r.data);

export const getPublicLines = () =>
  request<{ data: AdminLine[] }>("/lines", null).then((r) => r.data);

export type AdminLine = {
  id: number;
  code: string;
  name: string;
  transport_type: string;
  start_point: string | null;
  end_point: string | null;
  is_active: boolean;
  // GeoJSON LineString: [boylam, enlem] çiftleri
  route_geometry: { type: string; coordinates: [number, number][] } | null;
};

export const getAdminLines = (token: string) =>
  request<{ data: AdminLine[] }>("/admin/lines", token).then((r) => r.data);

export const updateLine = (
  token: string,
  id: number,
  data: Pick<AdminLine, "name" | "transport_type" | "start_point" | "end_point">,
) =>
  request<{ data: AdminLine }>(`/admin/lines/${id}`, token, { method: "PUT", body: JSON.stringify(data) }).then((r) => r.data);
