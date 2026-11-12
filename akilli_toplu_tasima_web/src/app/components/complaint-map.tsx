"use client";

import { useEffect, useRef, useState } from "react";
import type { Map as LeafletMap, LayerGroup } from "leaflet";
import "leaflet/dist/leaflet.css";
import type { AdminLine, MapComplaint } from "../../lib/api";
import { lineColor } from "../../lib/lineColors";
import styles from "./complaint-map.module.css";

const BARTIN: [number, number] = [41.635, 32.337];

// Hem yönetim panelinde hem ana sayfada kullanılan harita: hat güzergâhları + hat renginde şikayet pinleri.
export default function ComplaintMap({ complaints, lines, height = 560 }: {
  complaints: MapComplaint[]; lines: AdminLine[]; height?: number;
}) {
  const el = useRef<HTMLDivElement>(null);
  const mapRef = useRef<LeafletMap | null>(null);
  const layerRef = useRef<LayerGroup | null>(null);
  const [ready, setReady] = useState(false);
  const [lineF, setLineF] = useState("");

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const L = (await import("leaflet")).default;
      if (cancelled || !el.current || mapRef.current) return;
      const map = L.map(el.current).setView(BARTIN, 12);
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: "&copy; OpenStreetMap contributors",
      }).addTo(map);
      layerRef.current = L.layerGroup().addTo(map);
      mapRef.current = map;
      setReady(true);
    })();
    return () => {
      cancelled = true;
      mapRef.current?.remove();
      mapRef.current = null;
      layerRef.current = null;
      setReady(false);
    };
  }, []);

  useEffect(() => {
    if (!ready) return;
    void (async () => {
      const L = (await import("leaflet")).default;
      const layer = layerRef.current;
      const map = mapRef.current;
      if (!layer || !map) return;
      layer.clearLayers();
      const bounds: [number, number][] = [];

      // Güzergâhlar (GeoJSON [boylam, enlem] -> Leaflet [enlem, boylam])
      lines
        .filter((l) => (!lineF || l.code === lineF) && (l.route_geometry?.coordinates?.length ?? 0) > 1)
        .forEach((l) => {
          const pts = l.route_geometry!.coordinates.map(([lon, lat]) => [lat, lon] as [number, number]);
          L.polyline(pts, { color: lineColor(l.code), weight: 5, opacity: 0.75 })
            .bindTooltip(`${l.code} · ${l.name}`)
            .addTo(layer);
          if (lineF) bounds.push(...pts);
        });

      // Şikayet pinleri: hat rengiyle
      complaints
        .filter((c) => c.latitude != null && c.longitude != null && (!lineF || c.line?.code === lineF))
        .forEach((c) => {
          const pos: [number, number] = [Number(c.latitude), Number(c.longitude)];
          // Metin DOM ile eklenir (HTML olarak yorumlanmaz).
          const popup = document.createElement("div");
          const title = document.createElement("strong");
          title.textContent = c.title;
          const meta = document.createElement("div");
          meta.textContent = `${c.category} · ${c.status}${c.line ? ` · ${c.line.code}` : ""}`;
          popup.append(title, meta);
          L.circleMarker(pos, { radius: 8, color: "#fff", weight: 2, fillColor: lineColor(c.line?.code), fillOpacity: 0.95 })
            .bindPopup(popup)
            .addTo(layer);
          bounds.push(pos);
        });

      if (bounds.length > 0) map.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 });
      else map.setView(BARTIN, 12);
    })();
  }, [ready, complaints, lines, lineF]);

  const usedCodes = [...new Set(complaints.map((c) => c.line?.code).filter((x): x is string => !!x))].sort();
  const located = complaints.filter((c) => c.latitude != null && c.longitude != null).length;

  return (
    <section className={styles.panel}>
      <div className={styles.toolbar}>
        <select value={lineF} onChange={(e) => setLineF(e.target.value)} aria-label="Hat filtresi">
          <option value="">Tüm hatlar</option>
          {lines.map((l) => <option key={l.id} value={l.code}>{l.code} · {l.name}</option>)}
        </select>
        <span className={styles.muted}>{located} konumlu şikayet</span>
      </div>
      <div ref={el} className={styles.box} style={{ "--map-height": `${height}px` } as React.CSSProperties} />
      <div className={styles.legend}>
        {usedCodes.map((code) => (
          <span key={code}><i style={{ background: lineColor(code) }} />{code}</span>
        ))}
      </div>
    </section>
  );
}
