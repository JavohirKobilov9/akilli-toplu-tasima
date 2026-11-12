"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  AdminLine, ApiError, Complaint, STATUSES, Status, User,
  fetchMediaUrl, getAdminComplaints, getAdminLines, login, logout, updateStatus,
} from "../../lib/api";
import ComplaintMap from "../components/complaint-map";
import LineManager from "./line-manager";
import styles from "./admin-panel.module.css";

const TOKEN_KEY = "admin_token";
const USER_KEY = "admin_user";
const PAGE_SIZE = 15;

const lineLabel = (c: Complaint) => (c.line ? `${c.line.code} · ${c.line.name}` : "Hat yok");
const formatDate = (iso: string) =>
  new Date(iso).toLocaleString("tr-TR", { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" });

function countBy(items: Complaint[], key: (c: Complaint) => string) {
  const map = new Map<string, number>();
  items.forEach((c) => map.set(key(c), (map.get(key(c)) ?? 0) + 1));
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}

export default function AdminPanel() {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);

  // Oturum sekme kapanınca silinsin diye sessionStorage kullanılır.
  useEffect(() => {
    try {
      const t = sessionStorage.getItem(TOKEN_KEY);
      const u = sessionStorage.getItem(USER_KEY);
      if (t && u) { setToken(t); setUser(JSON.parse(u)); }
    } catch { /* depolama kapalıysa giriş ekranı açılır */ }
    setReady(true);
  }, []);

  const signOut = useCallback(() => {
    if (token) void logout(token);
    try { sessionStorage.removeItem(TOKEN_KEY); sessionStorage.removeItem(USER_KEY); } catch { /* yoksay */ }
    setToken(null); setUser(null);
  }, [token]);

  if (!ready) return null;
  if (!token || !user) {
    return <LoginForm onLogin={(t, u) => {
      try { sessionStorage.setItem(TOKEN_KEY, t); sessionStorage.setItem(USER_KEY, JSON.stringify(u)); } catch { /* yoksay */ }
      setToken(t); setUser(u);
    }} />;
  }
  return <Dashboard token={token} user={user} onSignOut={signOut} />;
}

function LoginForm({ onLogin }: { onLogin: (token: string, user: User) => void }) {
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setError(null);
    try {
      const { token, user } = await login(identifier.trim(), password);
      if (!["admin", "super_admin"].includes(user.role)) {
        await logout(token);
        setError("Bu panel yalnızca yönetici hesapları içindir.");
        return;
      }
      onLogin(token, user);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Giriş yapılamadı.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className={styles.loginWrap}>
      <form className={styles.loginCard} onSubmit={submit}>
        <span className={styles.kicker}>AKILLI TAŞIT · BARTIN</span>
        <h1>Yönetim Paneli</h1>
        <p>Belediye ve yönetici hesabınla giriş yap.</p>
        <label>E-posta veya telefon
          <input value={identifier} onChange={(e) => setIdentifier(e.target.value)} autoComplete="username" required />
        </label>
        <label>Şifre
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required />
        </label>
        {error && <div className={styles.error} role="alert">{error}</div>}
        <button type="submit" disabled={busy}>{busy ? "Giriş yapılıyor…" : "Giriş yap"}</button>
      </form>
    </main>
  );
}

function Dashboard({ token, user, onSignOut }: { token: string; user: User; onSignOut: () => void }) {
  const [items, setItems] = useState<Complaint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusF, setStatusF] = useState("");
  const [lineF, setLineF] = useState("");
  const [categoryF, setCategoryF] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [openId, setOpenId] = useState<number | null>(null);
  const [tab, setTab] = useState<"complaints" | "map" | "lines">("complaints");
  const [adminLines, setAdminLines] = useState<AdminLine[]>([]);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const [complaints, lineList] = await Promise.all([getAdminComplaints(token), getAdminLines(token)]);
      setItems(complaints);
      setAdminLines(lineList);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) { onSignOut(); return; }
      setError(err instanceof ApiError ? err.message : "Veriler alınamadı.");
    } finally {
      setLoading(false);
    }
  }, [token, onSignOut]);

  useEffect(() => { void load(); }, [load]);

  const lines = useMemo(() => [...new Set(items.map(lineLabel))].sort(), [items]);
  const categories = useMemo(() => [...new Set(items.map((c) => c.category))].sort(), [items]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return items.filter((c) =>
      (!statusF || c.status === statusF) &&
      (!lineF || lineLabel(c) === lineF) &&
      (!categoryF || c.category === categoryF) &&
      (!q || `${c.title} ${c.description} ${c.user_name}`.toLowerCase().includes(q)));
  }, [items, statusF, lineF, categoryF, query]);

  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = filtered.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  async function changeStatus(id: number, status: Status) {
    const before = items;
    setItems((list) => list.map((c) => (c.id === id ? { ...c, status } : c)));
    try {
      await updateStatus(token, id, status);
    } catch (err) {
      setItems(before);
      setError(err instanceof ApiError ? err.message : "Durum güncellenemedi.");
    }
  }

  const byCategory = countBy(items, (c) => c.category).slice(0, 7);
  const byLine = countBy(items, lineLabel).slice(0, 7);

  return (
    <div className={styles.page}>
      <header className={styles.top}>
        <div><span className={styles.kicker}>AKILLI TAŞIT · BARTIN</span><h1>Yönetim Paneli</h1></div>
        <div className={styles.who}>
          <span>{user.name} <small>({user.role === "super_admin" ? "Süper yönetici" : "Yönetici"})</small></span>
          <button className={styles.ghost} onClick={() => void load()}>Yenile</button>
          <button className={styles.ghost} onClick={onSignOut}>Çıkış</button>
        </div>
      </header>

      {error && <div className={styles.error} role="alert">{error}</div>}

      <div className={styles.tabs} role="tablist" aria-label="Bölümler">
        {([["complaints", "Şikayetler"], ["map", "Harita"], ["lines", "Hatlar"]] as const).map(([id, label]) => (
          <button key={id} role="tab" aria-selected={tab === id} className={`${styles.tab} ${tab === id ? styles.tabActive : ""}`} onClick={() => setTab(id)}>
            {label}
          </button>
        ))}
      </div>

      {tab === "map" && <ComplaintMap complaints={items} lines={adminLines} />}
      {tab === "lines" && (
        <LineManager token={token} lines={adminLines}
          onChange={(line) => setAdminLines((list) => list.map((l) => (l.id === line.id ? line : l)))} />
      )}

      {tab === "complaints" && (<>
      <section className={styles.stats} aria-label="Özet">
        <div className={styles.stat}><b>{items.length}</b><span>Toplam şikayet</span></div>
        {STATUSES.map((s) => (
          <div key={s} className={`${styles.stat} ${styles[`s${STATUSES.indexOf(s)}`]}`}>
            <b>{items.filter((c) => c.status === s).length}</b><span>{s}</span>
          </div>
        ))}
      </section>

      <section className={styles.charts}>
        <Bars title="Kategoriye göre" rows={byCategory} total={items.length} />
        <Bars title="Hatta göre (ilk 7)" rows={byLine} total={items.length} />
      </section>

      <section className={styles.filters} aria-label="Filtreler">
        <input placeholder="Ara: başlık, açıklama, kullanıcı" value={query} onChange={(e) => { setQuery(e.target.value); setPage(1); }} />
        <select value={statusF} onChange={(e) => { setStatusF(e.target.value); setPage(1); }}>
          <option value="">Tüm durumlar</option>{STATUSES.map((s) => <option key={s}>{s}</option>)}
        </select>
        <select value={lineF} onChange={(e) => { setLineF(e.target.value); setPage(1); }}>
          <option value="">Tüm hatlar</option>{lines.map((l) => <option key={l}>{l}</option>)}
        </select>
        <select value={categoryF} onChange={(e) => { setCategoryF(e.target.value); setPage(1); }}>
          <option value="">Tüm kategoriler</option>{categories.map((c) => <option key={c}>{c}</option>)}
        </select>
      </section>

      <div className={styles.tableWrap}>
        <table>
          <thead><tr><th>#</th><th>Başlık</th><th>Kategori</th><th>Hat</th><th>Kullanıcı</th><th>Tarih</th><th>Durum</th></tr></thead>
          <tbody>
            {loading && <tr><td colSpan={7} className={styles.empty}>Yükleniyor…</td></tr>}
            {!loading && visible.length === 0 && <tr><td colSpan={7} className={styles.empty}>Bu filtrelerde şikayet yok.</td></tr>}
            {visible.map((c) => (
              <ComplaintRow key={c.id} c={c} token={token} open={openId === c.id}
                onToggle={() => setOpenId(openId === c.id ? null : c.id)} onStatus={(s) => void changeStatus(c.id, s)} />
            ))}
          </tbody>
        </table>
      </div>

      <nav className={styles.pager} aria-label="Sayfalar">
        <button className={styles.ghost} disabled={current <= 1} onClick={() => setPage(current - 1)}>Önceki</button>
        <span>{current} / {pageCount} · {filtered.length} kayıt</span>
        <button className={styles.ghost} disabled={current >= pageCount} onClick={() => setPage(current + 1)}>Sonraki</button>
      </nav>
      </>)}
    </div>
  );
}

function Bars({ title, rows, total }: { title: string; rows: [string, number][]; total: number }) {
  return (
    <div className={styles.card}>
      <h2>{title}</h2>
      {rows.length === 0 && <p className={styles.muted}>Veri yok.</p>}
      {rows.map(([label, n]) => (
        <div key={label} className={styles.barRow}>
          <span title={label}>{label}</span>
          <div className={styles.bar}><i style={{ width: `${total ? (n / total) * 100 : 0}%` }} /></div>
          <b>{n}</b>
        </div>
      ))}
    </div>
  );
}

function ComplaintRow({ c, token, open, onToggle, onStatus }: {
  c: Complaint; token: string; open: boolean; onToggle: () => void; onStatus: (s: Status) => void;
}) {
  return (
    <>
      <tr className={styles.row} onClick={onToggle}>
        <td>{c.id}</td>
        <td>{c.title}</td>
        <td>{c.category}</td>
        <td>{lineLabel(c)}</td>
        <td>{c.user_name}{c.is_guest ? " (misafir)" : ""}</td>
        <td>{formatDate(c.created_at)}</td>
        <td onClick={(e) => e.stopPropagation()}>
          <select className={`${styles.status} ${styles[`s${STATUSES.indexOf(c.status)}`]}`} value={c.status}
            onChange={(e) => onStatus(e.target.value as Status)} aria-label={`Şikayet ${c.id} durumu`}>
            {STATUSES.map((s) => <option key={s}>{s}</option>)}
          </select>
        </td>
      </tr>
      {open && <tr><td colSpan={7} className={styles.detail}><Detail c={c} token={token} /></td></tr>}
    </>
  );
}

function Detail({ c, token }: { c: Complaint; token: string }) {
  const [mediaUrl, setMediaUrl] = useState<string | null>(null);
  const [mediaError, setMediaError] = useState(false);

  useEffect(() => {
    if (!c.media_path) return;
    let url: string | null = null;
    let cancelled = false;
    fetchMediaUrl(token, c.id)
      .then((u) => { if (cancelled) URL.revokeObjectURL(u); else { url = u; setMediaUrl(u); } })
      .catch(() => setMediaError(true));
    return () => { cancelled = true; if (url) URL.revokeObjectURL(url); };
  }, [c.id, c.media_path, token]);

  const hasLocation = c.latitude != null && c.longitude != null;
  return (
    <div className={styles.detailGrid}>
      <div>
        <p>{c.description}</p>
        <dl>
          {c.stop && (<><dt>Durak</dt><dd>{c.stop.name}</dd></>)}
          {c.user_email && (<><dt>E-posta</dt><dd>{c.user_email}</dd></>)}
          {c.user_phone && (<><dt>Telefon</dt><dd>{c.user_phone}</dd></>)}
          {hasLocation && (<><dt>Konum</dt><dd>
            <a href={`https://www.openstreetmap.org/?mlat=${c.latitude}&mlon=${c.longitude}#map=17/${c.latitude}/${c.longitude}`} target="_blank" rel="noreferrer">
              Haritada aç ({Number(c.latitude).toFixed(5)}, {Number(c.longitude).toFixed(5)})
            </a></dd></>)}
        </dl>
      </div>
      {c.media_path && (
        <div className={styles.media}>
          {mediaError && <p className={styles.muted}>Dosya yüklenemedi.</p>}
          {!mediaError && !mediaUrl && <p className={styles.muted}>Dosya yükleniyor…</p>}
          {mediaUrl && (c.media_type ?? "").includes("video")
            // eslint-disable-next-line jsx-a11y/media-has-caption
            ? <video src={mediaUrl} controls />
            // eslint-disable-next-line @next/next/no-img-element
            : mediaUrl && <img src={mediaUrl} alt={`Şikayet ${c.id} fotoğrafı`} />}
        </div>
      )}
    </div>
  );
}
