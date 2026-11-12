"use client";

import { useState } from "react";
import Image from "next/image";
import { Accessibility, ArrowDown, ArrowLeft, ArrowRight, ArrowUpRight, Armchair, BusFront, Check, Clock3, Heart, MapPin, MessageCircle, Plus, Route, ThumbsUp } from "lucide-react";
import { About, BridgeArt, HowItWorks, NeighborhoodMap, PassengerVoices, RouteStrip } from "./local-sections";
import styles from "./visual-home.module.css";

const kinds = { "Şikayet": "kBlue", "Öneri": "kAmber", "Teşekkür": "kGreen" } as const;

const notes = [
  { name: "Elif", initials: "EY", area: "Merkez", time: "07:45", topic: "Sefer saatleri", title: "Sabah otobüsünü beklerken işe geç kalıyorum.", kind: "Şikayet", supports: 12 },
  { name: "Mehmet", initials: "MK", area: "Ağdacı", time: "08:10", topic: "Duraklar", title: "Duraktaki yeni saat çizelgesi çok işimize yaradı.", kind: "Teşekkür", supports: 24, image: "/images/bartin-bus.png" },
  { name: "Zeynep", initials: "ZA", area: "Gölbucağı", time: "09:30", topic: "Erişilebilirlik", title: "Bebek arabasıyla binmek biraz daha kolay olabilir.", kind: "Öneri", supports: 18 },
  { name: "Berk", initials: "BD", area: "Kemerköprü", time: "17:55", topic: "Sefer saatleri", title: "İş çıkışına bir ek sefer, hepimize iyi gelir.", kind: "Öneri", supports: 31, image: "/images/bartin-bus.png" },
  { name: "Selin", initials: "SÇ", area: "Orduyeri", time: "12:20", topic: "Duraklar", title: "Durağın adını araç içinde de duymak isterim.", kind: "Öneri", supports: 16 },
  { name: "Ali", initials: "AT", area: "Merkez", time: "07:05", topic: "Araç konforu", title: "Bu sabah tertemiz bir otobüsle yola çıktık. Teşekkürler!", kind: "Teşekkür", supports: 9 },
] as const;

const stories = [
  { title: "Bir saat çizelgesi. Daha az bekleyiş.", text: "“Durakta ne kadar bekleyeceğimi artık biliyorum.”", name: "Mehmet K.", area: "Ağdacı", category: "Durak bilgisi", image: "/images/bartin-bus.png", alt: "Ağaçlarla çevrili bir durakta mavi beyaz otobüs", resolved: true },
  { title: "Yolculuk herkes için kolay olsun.", text: "“Rampayı kullanabilmek, bizim için büyük bir kolaylık.”", name: "Zeynep A.", area: "Gölbucağı", category: "Erişilebilirlik", image: "/images/passenger.png", alt: "Otobüste pencere yanında oturan yolcu", resolved: false },
  { title: "İyi bir yolculuğun da sözü var.", text: "“Yardımcı olan şoförümüze bir teşekkür bırakmak istedim.”", name: "Ali T.", area: "Merkez", category: "Yolcu deneyimi", image: "/images/bartin-bus.png", alt: "Mavi beyaz şehir otobüsü", resolved: true },
];

const topics = [
  { icon: Clock3, name: "Sefer saatleri", tag: "Zamanında yola", color: "#2465c7" },
  { icon: Route, name: "Durak & güzergâh", tag: "Doğru durakta", color: "#2c8a6e" },
  { icon: Armchair, name: "Araç konforu", tag: "Rahat bir yolculuk", color: "#e39a1d" },
  { icon: Accessibility, name: "Erişilebilirlik", tag: "Herkes için ulaşım", color: "#c8553d" },
];

const menu = [
  { href: "#nasil-calisir", label: "Nasıl çalışır?" },
  { href: "#yolcu-notlari", label: "Yolcu notları" },
  { href: "#konular", label: "Konular" },
  { href: "#bartin-haritasi", label: "Harita" },
  { href: "#hakkimizda", label: "Hakkımızda" },
];

function Logo({ light = false }: { light?: boolean }) {
  return <a href="#" className={`${styles.logo} ${light ? styles.logoLight : ""}`} aria-label="Akıllı Taşıt ana sayfa"><span><BusFront size={26} strokeWidth={1.8} /><i /></span><strong>akıllı<span>taşıt</span><small>BARTIN</small></strong></a>;
}

function LedSign() {
  return <div className={styles.led} role="img" aria-label="74 Bartın: şikayet, öneri, teşekkür">
    <span className={styles.ledCode}>74</span>
    <span className={styles.ledWindow} aria-hidden="true"><span className={styles.ledRoll}>{["ŞİKAYET", "ÖNERİ", "TEŞEKKÜR", "HEPSİ BURADA", "ŞİKAYET"].map((word, i) => <span key={i}>{word}</span>)}</span></span>
  </div>;
}

export default function VisualHome() {
  const [storyIndex, setStoryIndex] = useState(0);
  const story = stories[storyIndex];

  return <div className={styles.page}>
    <div className={styles.topline}><div className={styles.shell}><span><i /> 74 · BARTIN’IN YOLCU PLATFORMU</span><span>Çok yakında yayında</span></div></div>
    <header className={styles.header}><div className={styles.shell}><Logo /><nav aria-label="Ana menü">{menu.map(item => <a key={item.href} href={item.href}>{item.label}</a>)}</nav><div className={styles.account}><button disabled>Giriş yap</button><button disabled className={styles.signup}>Kayıt ol <ArrowUpRight size={16} /></button></div></div></header>

    <main>
      <section className={`${styles.hero} ${styles.shell}`} aria-labelledby="visual-title">
        <div className={styles.heroCopy}><LedSign /><h1 id="visual-title">Yolculuk senin.<br /><span>Söz de senin.</span></h1><p>Şikayet, öneri, teşekkür.<br />Bartın’ın ulaşımı burada konuşulur.</p><div className={styles.heroActions}><button disabled className={styles.primary}>Deneyimini paylaş <Plus size={18} /></button><a href="#nasil-calisir" aria-label="Nasıl çalıştığına göz at"><ArrowDown size={20} /></a></div><div className={styles.heroCaption}><span className={styles.miniAvatars}><i>E</i><i>M</i><i>Z</i></span><span>Aynı şehir. Farklı hikâyeler.</span></div></div>
        <div className={styles.collage}>
          <div className={styles.photoMain}><Image sizes="(max-width: 600px) 75vw, 420px" loading="eager" src="/images/passenger.png" alt="Otobüs penceresinden dışarı bakan yolcu" width="1536" height="1024" fetchPriority="high" /><span><i /> Bir yolculuktan fazlası.</span></div>
          <div className={styles.stopSign} aria-hidden="true"><div className={styles.stopPanel}><BusFront size={30} strokeWidth={1.6} /><strong>DURAK</strong></div><div className={styles.stopName}>Kemerköprü<small>BARTIN · 74</small></div><i /></div>
          <div className={styles.busTile}><Image sizes="(max-width: 600px) 50vw, 300px" src="/images/bartin-bus.png" alt="Mavi beyaz şehir otobüsü" width="1536" height="1024" /><span><BusFront size={13} /> BARTIN</span></div>
          <div className={styles.ticketNote}><span>YOLCU NOTU <b>08:12</b></span><strong>“Durakta saat bilgisi olsa…”</strong><small><MapPin size={11} /> Orduyeri</small></div>
          <span className={styles.collageLocation}><MapPin size={12} /> 41°38′ K · 32°20′ D</span>
        </div>
      </section>

      <RouteStrip />

      <HowItWorks />

      <section className={styles.notesSection} id="yolcu-notlari" aria-labelledby="notes-title">
        <div className={`${styles.sectionTop} ${styles.shell}`}><div><span className={styles.kicker}>ŞEHRİN İÇİNDEN</span><h2 id="notes-title">Yolculuk biter.<br className={styles.mobileBreak} /> Hikâyesi kalır.</h2></div><ul className={styles.kindLegend} aria-label="Not türleri">{Object.entries(kinds).map(([kind, cls]) => <li key={kind} className={styles[cls]}><i />{kind}</li>)}</ul></div>
        <div className={styles.streams}>
          {[notes, [...notes.slice(3), ...notes.slice(0, 3)]].map((row, rowIndex) => <div className={styles.streamWindow} key={rowIndex} tabIndex={0} role="region" aria-label={`Yolcu notları, sıra ${rowIndex + 1}`}><div className={`${styles.track} ${rowIndex === 1 ? styles.secondTrack : ""}`}>
            {[0, 1].map(copy => <div className={styles.noteGroup} key={copy} aria-hidden={copy === 1 ? true : undefined}>{row.map((note, index) => <article className={`${styles.noteCard} ${styles[kinds[note.kind]]}`} key={note.initials}>
              <div className={styles.noteBody}><div className={styles.noteText}><div className={styles.person}><span className={styles.avatar}>{note.initials}</span><span><strong>{note.name}</strong><small>{note.area} <span>·</span> {note.time}</small></span><em>{note.kind}</em></div><h3>{note.title}</h3></div>
                {"image" in note && index % 2 !== 0 && <Image sizes="90px" className={styles.noteImage} src={note.image} alt="" width="90" height="110" loading="lazy" />}</div>
              <div className={styles.noteStub}><span><i />{note.topic}</span><span><ThumbsUp size={11} /> {note.supports}</span></div>
            </article>)}</div>)}
          </div></div>)}
        </div>
      </section>

      <section className={`${styles.topicsSection} ${styles.shell}`} id="konular" aria-labelledby="topics-title"><div className={styles.sectionTop}><div><span className={styles.kicker}>NEREDEN BAŞLAYALIM?</span><h2 id="topics-title">Yolun hangi tarafı?</h2></div><span className={styles.sectionAside}>Küçük bir detay, büyük bir fark.</span></div><div className={styles.topicGrid}>
        {topics.map((topic, index) => <a key={topic.name} href="#yolcu-notlari" className={styles.topic} style={{ "--c": topic.color } as React.CSSProperties}><div><span>0{index + 1}</span><ArrowUpRight size={18} /></div><topic.icon size={50} strokeWidth={1.2} /><span className={styles.topicName}>{topic.name}</span><small>{topic.tag}</small><i /></a>)}
      </div></section>

      <NeighborhoodMap />

      <section className={styles.featureSection} id="bir-not" aria-labelledby="feature-title"><div className={styles.featureBackdrop} aria-hidden="true"><span>74</span></div><div className={styles.shell}><div className={styles.featureTop}><div><span className={styles.kicker}>BİR NOT, BİR DEĞİŞİM</span><h2 id="feature-title">İyi ki söylenmiş.</h2></div><div className={styles.sliderControls}><span>0{storyIndex + 1}<i>/03</i></span><button type="button" aria-label="Önceki hikâye" onClick={() => setStoryIndex((storyIndex + stories.length - 1) % stories.length)}><ArrowLeft size={18} /></button><button type="button" aria-label="Sonraki hikâye" onClick={() => setStoryIndex((storyIndex + 1) % stories.length)}><ArrowRight size={18} /></button></div></div>
        <div className={styles.featureCard} key={storyIndex}><div className={styles.featureImage}><Image sizes="(max-width: 600px) 100vw, 600px" src={story.image} alt={story.alt} width="1536" height="1024" loading="lazy" /><span><MapPin size={12} /> {story.area}, Bartın</span></div><div className={styles.featureCopy} aria-live="polite"><span className={styles.featureBadge}>{story.resolved ? <Check size={13} /> : <MessageCircle size={13} />} {story.resolved ? "Çözüme giden bir not" : "Bir yolcu önerisi"}</span><h3>{story.title}</h3><p>{story.text}</p><div><span className={styles.featureAvatar}>{story.name[0]}</span><span><strong>{story.name}</strong><small>{story.category}</small></span><Heart size={21} /></div></div></div>
      </div></section>

      <PassengerVoices />

      <About />

      <section className={`${styles.closing} ${styles.shell}`} aria-labelledby="closing-title"><div className={styles.ticket}>
        <div className={styles.ticketMain}><span className={styles.kicker}>BU ŞEHİRDE SENİN DE SÖZÜN VAR</span><h2 id="closing-title">Bir not da<br /><span>sen bırak.</span></h2><button disabled className={styles.ticketButton}>Deneyimini paylaş <ArrowUpRight size={17} /></button><small>Çok yakında Bartın’da.</small></div>
        <div className={styles.ticketStub}><span className={styles.stubTitle}><BusFront size={14} /> BİNİŞ KARTI</span><dl><div><dt>NEREDEN</dt><dd>Senin durağın</dd></div><div><dt>NEREYE</dt><dd>Daha iyi bir yolculuk</dd></div><div><dt>KALKIŞ</dt><dd>Çok yakında</dd></div></dl><span className={styles.stubCode} aria-hidden="true"><i />74</span></div>
      </div></section>
    </main>

    <footer className={styles.footer}><BridgeArt className={styles.footerBridge} /><div className={styles.shell}><div className={styles.footerMain}><Logo light /><nav aria-label="Alt menü">{menu.map(item => <a key={item.href} href={item.href}>{item.label}</a>)}</nav><span><MapPin size={14} /> Bartın’da, Bartın için.</span></div><div className={styles.footerBottom}><span>© 2026 Akıllı Taşıt</span><span>Bağımsız bir proje tanıtımıdır; resmî bir kurumla bağlantılı değildir. Sayfadaki paylaşımlar ve görseller temsilidir.</span></div></div></footer>
  </div>;
}
