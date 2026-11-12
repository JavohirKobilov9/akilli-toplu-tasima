"use client";

import { Fragment, useState } from "react";
import { AdminLine, ApiError, updateLine } from "../../lib/api";
import { lineColor } from "../../lib/lineColors";
import styles from "./admin-panel.module.css";

export default function LineManager({ token, lines, onChange }: {
  token: string; lines: AdminLine[]; onChange: (line: AdminLine) => void;
}) {
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState({ name: "", transport_type: "", start_point: "", end_point: "" });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  function startEdit(l: AdminLine) {
    setEditId(l.id); setError(null);
    setForm({ name: l.name, transport_type: l.transport_type, start_point: l.start_point ?? "", end_point: l.end_point ?? "" });
  }

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (editId === null) return;
    setBusy(true); setError(null);
    try {
      const updated = await updateLine(token, editId, {
        name: form.name.trim(),
        transport_type: form.transport_type.trim(),
        start_point: form.start_point.trim() || null,
        end_point: form.end_point.trim() || null,
      });
      onChange(updated);
      setEditId(null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Hat güncellenemedi.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className={styles.tableWrap}>
      {error && <div className={styles.error} role="alert">{error}</div>}
      <table>
        <thead><tr><th>Hat</th><th>Ad</th><th>Tür</th><th>Başlangıç</th><th>Bitiş</th><th>Güzergâh</th><th /></tr></thead>
        <tbody>
          {lines.length === 0 && <tr><td colSpan={7} className={styles.empty}>Hat bulunamadı.</td></tr>}
          {lines.map((l) => (
            <Fragment key={l.id}>
              <tr>
                <td><span className={styles.dot} style={{ background: lineColor(l.code) }} />{l.code}{!l.is_active && " (pasif)"}</td>
                <td>{l.name}</td>
                <td>{l.transport_type}</td>
                <td>{l.start_point ?? "—"}</td>
                <td>{l.end_point ?? "—"}</td>
                <td>{l.route_geometry?.coordinates?.length ? `${l.route_geometry.coordinates.length} nokta` : "yok"}</td>
                <td>
                  <button className={styles.ghost} onClick={() => (editId === l.id ? setEditId(null) : startEdit(l))}>
                    {editId === l.id ? "Kapat" : "Düzenle"}
                  </button>
                </td>
              </tr>
              {editId === l.id && (
                <tr>
                  <td colSpan={7} className={styles.detail}>
                    <form className={styles.lineForm} onSubmit={save}>
                      <label>Ad<input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required maxLength={255} /></label>
                      <label>Tür<input value={form.transport_type} onChange={(e) => setForm({ ...form, transport_type: e.target.value })} required maxLength={255} /></label>
                      <label>Başlangıç<input value={form.start_point} onChange={(e) => setForm({ ...form, start_point: e.target.value })} maxLength={255} /></label>
                      <label>Bitiş<input value={form.end_point} onChange={(e) => setForm({ ...form, end_point: e.target.value })} maxLength={255} /></label>
                      <button type="submit" className={styles.primary} disabled={busy}>{busy ? "Kaydediliyor…" : "Kaydet"}</button>
                    </form>
                    <p className={styles.muted}>Hat kodu ve aktiflik durumu güvenlik nedeniyle panelden değiştirilemez.</p>
                  </td>
                </tr>
              )}
            </Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );
}
