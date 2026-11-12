"use client";

import { useEffect, useState } from "react";
import { AdminLine, MapComplaint, getPublicComplaints, getPublicLines } from "../../lib/api";
import ComplaintMap from "./complaint-map";
import styles from "./complaint-map.module.css";

// Ana sayfadaki harita: giriş gerektirmeyen herkese açık API uçlarından gerçek veriyi çeker.
export default function LiveMap() {
  const [complaints, setComplaints] = useState<MapComplaint[]>([]);
  const [lines, setLines] = useState<AdminLine[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all([getPublicComplaints(), getPublicLines()])
      .then(([c, l]) => { if (!cancelled) { setComplaints(c); setLines(l); } })
      .catch(() => { if (!cancelled) setError("Harita verileri şu an alınamadı. Lütfen daha sonra tekrar dene."); });
    return () => { cancelled = true; };
  }, []);

  return (
    <div>
      {error && <div className={styles.error} role="alert">{error}</div>}
      <ComplaintMap complaints={complaints} lines={lines} height={420} />
    </div>
  );
}
