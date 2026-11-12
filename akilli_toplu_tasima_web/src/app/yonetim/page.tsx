import type { Metadata } from "next";
import AdminPanel from "./admin-panel";

export const metadata: Metadata = { title: "Yönetim Paneli | Akıllı Taşıt" };

export default function Page() {
  return <AdminPanel />;
}
