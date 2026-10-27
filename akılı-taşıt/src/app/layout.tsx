import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Akıllı Taşıt | Bartın’da ulaşımın sesi ol",
  description: "Bartın’da daha iyi bir toplu ulaşım için ortak bir alan. Otobüs yolculuklarına dair şikayet, öneri ve çözümleri buluşturmayı amaçlayan bağımsız platform.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="tr"><body>{children}</body></html>;
}
