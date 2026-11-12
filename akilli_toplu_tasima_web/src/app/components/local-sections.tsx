"use client";

import { useState } from "react";
import Image from "next/image";
import { ArrowUpRight, BusFront, Check, Heart, Map, MapPin, MessageCircle, Plus } from "lucide-react";
import styles from "./local-sections.module.css";

// Hakkımızda fotoğrafı: kendi fotoğrafını public/images içine koyup bu yolu değiştir.
const aboutImage = "/images/bartin-bus.png";

const stops = ["Orduyeri", "Merkez", "Kemerköprü", "Gölbucağı", "Ağdacı"];

const types = [
  { id: "sikayet", label: "Bir sorun yaşadım", icon: MessageCircle, category: "Şikayet", title: "Bu sabah otobüs durağa uğramadı.", detail: "Merkez · Sefer ve durak", note: "Nerede, ne zaman? Küçük bir detay bile önemli.", color: "blue" },
  { id: "oneri", label: "Bir fikrim var", icon: Plus, category: "Öneri", title: "Durağa bir saat çizelgesi eklesek?", detail: "Ağdacı · Yolcu bilgilendirme", note: "Aklındaki fikri paylaş. Belki başkaları da aynı şeyi düşünüyor.", color: "sand" },
  { id: "tesekkur", label: "Teşekkür etmek istedim", icon: Heart, category: "Teşekkür", title: "Şoförümüz bugün çok yardımcı oldu.", detail: "Orduyeri · Yolcu deneyimi", note: "İyi olanı da konuşalım. Güzel bir deneyim paylaştıkça çoğalır.", color: "mint" },
];

const steps = [
  { title: "Anlat", text: "Ne oldu, nerede, hangi saatte? Şikayetini, önerini ya da teşekkürünü birkaç cümleyle yaz." },
  { title: "Destekle", text: "Aynı durakta bekleyenler notuna destek versin. Ortak sorunlar daha görünür olsun." },
  { title: "Takip et", text: "Notunun hangi aşamada olduğunu tek yerden gör. Çözümleri birlikte görünür kılalım." },
];

export function BridgeArt({ className }: { className?: string }) {
  return <svg className={className} viewBox="0 0 390 125" fill="none" aria-hidden="true">
    <path d="M0 105c44-13 54 13 98 0s54 13 98 0 54 13 98 0 54 13 98 0M0 118c44-13 54 13 98 0s54 13 98 0 54 13 98 0 54 13 98 0" stroke="currentColor" strokeOpacity=".45" strokeWidth="2" />
    <path d="M27 51h335v13h-14v36h-19V83a20 20 0 0 0-40 0v17h-20V83a20 20 0 0 0-40 0v17h-20V83a20 20 0 0 0-40 0v17h-20V83a20 20 0 0 0-40 0v17H89V83a20 20 0 0 0-40 0v17H30V64h-3z" fill="currentColor" fillOpacity=".55" />
    <path d="M28 49h333M35 35h318M44 35v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14m23-14v14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
  </svg>;
}

export function RouteStrip() {
  return <section className={styles.route} aria-label="Bartın’a özel yolcu platformu">
    <div className={styles.routeInner}>
      <span className={styles.plate}><span>TR</span>74</span>
      <div className={styles.routeCopy}><span>BİZİM ŞEHRİN YOLLARI</span><p>Merkezden mahalleye.<br /><strong>Okuldan eve.</strong></p></div>
      <div className={styles.routeTrack}>
        <ol aria-label="Bartın’dan mahalleler">{stops.map(stop => <li key={stop}>{stop}</li>)}</ol>
        <span className={styles.routeBus} aria-hidden="true"><BusFront size={14} /></span>
      </div>
    </div>
  </section>;
}

export function HowItWorks() {
  return <section className={styles.how} id="nasil-calisir" aria-labelledby="how-title">
    <div className={styles.howTop}><div><span className={styles.kicker}>ÜÇ DURAKTA</span><h2 id="how-title">Notun yola<br /><span>böyle çıkar.</span></h2></div><p>Bir şikayet, bir öneri ya da bir teşekkür.<br />Hepsi aynı yoldan geçer.</p></div>
    <ol className={styles.howSteps}>
      {steps.map((step, index) => <li key={step.title}><span className={styles.howDot}>{index + 1}</span><small>DURAK 0{index + 1}</small><h3>{step.title}</h3><p>{step.text}</p></li>)}
      <li className={styles.howEnd}><span className={styles.howDot}><Check size={20} /></span><small>SON DURAK</small><h3>Daha iyi bir yolculuk.</h3></li>
    </ol>
  </section>;
}

export function NeighborhoodMap() {
  return <section className={styles.mapSection} id="bartin-haritasi" aria-labelledby="map-title">
    <div className={styles.mapIntro}>
      <span className={styles.kicker}>BARTIN, DURAK DURAK</span>
      <h2 id="map-title">Senin durağın.<br /><span>Senin mahallen.</span></h2>
      <p>Duraklar, güzergâhlar ve yolcu notları.<br />Şehrin ulaşımını bir arada görmek için yeni bir alan.</p>
      <div className={styles.neighborhoods} aria-label="Mahalleler">{stops.map((stop, i) => <span key={stop}>{i === 1 && <MapPin size={12} />}{stop}</span>)}</div>
    </div>
    <div className={styles.mapSoon}>
      <span className={styles.mapSoonIcon}><Map size={34} strokeWidth={1.4} /></span>
      <h3>Harita alanı yakında burada.</h3>
      <p>Duraklar ve güzergâhlar çok yakında bu alanda olacak.</p>
    </div>
  </section>;
}

export function PassengerVoices() {
  const [selected, setSelected] = useState(0);
  const current = types[selected];
  return <section className={styles.voices} id="soz-sende" aria-labelledby="voices-title">
    <div className={styles.voicesInner}>
      <div className={styles.voicesIntro}><span className={styles.kicker}>SADECE ŞİKAYET DEĞİL</span><h2 id="voices-title">Bir sorun, bir fikir,<br />bir teşekkür.</h2><p>Yolculuğun nasıl geçtiyse, öyle anlat.</p><div className={styles.voiceTabs} role="tablist" aria-label="Paylaşım türleri">{types.map((type, index) => <button key={type.id} id={`voice-tab-${type.id}`} role="tab" type="button" aria-selected={selected === index} aria-controls="voice-example" tabIndex={selected === index ? 0 : -1} onClick={() => setSelected(index)} onKeyDown={event => { if (["ArrowRight", "ArrowLeft", "Home", "End"].includes(event.key)) { event.preventDefault(); const next = event.key === "Home" ? 0 : event.key === "End" ? types.length - 1 : (selected + (event.key === "ArrowRight" ? 1 : -1) + types.length) % types.length; setSelected(next); document.getElementById(`voice-tab-${types[next].id}`)?.focus(); } }}><type.icon size={17} /><span>{type.label}</span><ArrowUpRight size={15} /></button>)}</div></div>
      <div className={`${styles.voiceExample} ${styles[current.color]}`} id="voice-example" role="tabpanel" aria-labelledby={`voice-tab-${current.id}`} tabIndex={0}>
        <div className={styles.voiceBackdrop} aria-hidden="true"><current.icon size={125} strokeWidth={.65} /></div>
        <article className={styles.voicePaper} key={current.id}><div className={styles.paperTop}><span><current.icon size={14} /> {current.category}</span><small>YOLCU NOTU</small></div><h3>{current.title}</h3><span className={styles.paperLocation}><MapPin size={12} />{current.detail}</span><div className={styles.paperBottom}><span className={styles.paperAvatar}>74</span><span>Bartın’dan bir yolcu</span><Check size={15} /></div></article>
        <p className={styles.voiceHint}>{current.note}</p>
      </div>
    </div>
  </section>;
}

export function About() {
  return <section className={styles.about} id="hakkimizda" aria-labelledby="about-title">
    <div className={styles.aboutPhoto}><Image src={aboutImage} alt="Bartın’da bir otobüs durağı" fill sizes="(max-width: 850px) 100vw, 600px" /></div>
    <div className={styles.aboutCopy}>
      <span className={styles.kicker}>NEDEN SADECE BARTIN?</span>
      <h2 id="about-title">Aynı durakta bekleyenler<br /><span>birbirini anlar.</span></h2>
      <p>Okula, işe, eve… Her gün aynı yolları paylaşıyoruz. Akıllı Taşıt, bu yolculukları birlikte daha iyi hâle getirmek için var.</p>
      <ul className={styles.aboutTags}><li><Check size={14} /> Yerel odak</li><li><Check size={14} /> Yapıcı iletişim</li><li><Check size={14} /> Ortak fayda</li></ul>
    </div>
  </section>;
}
