// not-mobil: Saber'den kalan iOS/macOS/Linux/Windows ikonlarını tarus Not işaretiyle yeniden üretir.
// Kaynak: ozluk/tarus-kabuk/marka/marka.json (renk, glif). Çalıştırma (not-mobil kökünden): node scripts/tarus_ikonlari.mjs .
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const KOK = path.resolve(process.argv[2]);
const MARKA = path.resolve(KOK, '..', 'ozluk', 'tarus-kabuk', 'marka');
const { sharpBul } = await import(pathToFileURL(path.join(MARKA, 'sharp-bul.mjs')).href);
const sharp = sharpBul();
const marka = JSON.parse(fs.readFileSync(path.join(MARKA, 'marka.json'), 'utf8'));
const u = marka.urunler.find((x) => x.anahtar === 'not');
const RENK = u.renk; // #AC865A
const GLIF = u.glif.icerik; // 24x24 ızgara

// 24'lük glifi (x, y)'den başlayıp s ölçekle çizer.
const glif = (x, y, s, renk) =>
  `<g transform="translate(${x} ${y}) scale(${s})" fill="${renk}">${GLIF}</g>`;
const svg = (ic, w = 1024, h = 1024) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">\n  <title>tarus Not</title>\n  ${ic}\n</svg>\n`;

// Plakalı işaretin oranları (svg/not.svg): köşe %18,75, glif kutusu plakanın %75'i.
const plaka = (x, y, k, renk = RENK) =>
  `<rect x="${x}" y="${y}" width="${k}" height="${k}" rx="${(k * 0.1875).toFixed(2)}" fill="${renk}"/>` +
  glif(x + k * 0.125, y + k * 0.125, (k * 0.75) / 24, '#ffffff');

const KAYNAK = {
  // iOS açık ikon: köşesiz, opak (iOS kendisi maskeler).
  icon_opaque: svg(`<rect width="1024" height="1024" fill="${RENK}"/>${glif(128, 128, 32, '#ffffff')}`),
  // iOS koyu: zemini sistem verir, glif marka renginde.
  icon_ios_dark: svg(glif(128, 128, 32, RENK)),
  // iOS renklendirilebilir: sistem gri tonlamayla boyar; glif beyaz.
  icon_ios_tintable: svg(glif(128, 128, 32, '#ffffff')),
  // Android maskelenebilir: kenara kadar zemin, glif %80 güvenli alanın içinde (576 px).
  icon_maskable: svg(`<rect width="1024" height="1024" fill="${RENK}"/>${glif(224, 224, 24, '#ffffff')}`),
  // Android tek renk: yalnız glif, maskelenebilir ile aynı ölçek.
  icon_monochrome: svg(glif(224, 224, 24, '#ffffff')),
  // macOS: 1024 tuvalde 824'lük plaka (Apple ızgarası), köşe marka oranında.
  icon_macos: svg(plaka(100, 100, 824)),
  // Linux (snap, AppImage): plakalı işaretin kendisi.
  icon_linux: svg(plaka(0, 0, 1024)),
};

const png = (s, w, h = w) =>
  sharp(Buffer.from(s), { density: 288 }).resize(w, h, { fit: 'fill' }).png({ compressionLevel: 9 }).toBuffer();
const yaz = (p, veri) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, veri); return path.relative(KOK, p); };
const yazilan = [];

for (const [ad, s] of Object.entries(KAYNAK)) {
  yazilan.push(yaz(path.join(KOK, 'assets/icon', `${ad}.svg`), s));
  yazilan.push(yaz(path.join(KOK, 'assets/icon', `${ad}.png`), await png(s, 1024)));
}

// iOS AppIcon.appiconset (açık / koyu / renklendirilebilir).
const iosDir = path.join(KOK, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
const iosIc = JSON.parse(fs.readFileSync(path.join(iosDir, 'Contents.json'), 'utf8'));
for (const im of iosIc.images) {
  if (!im.filename) continue;
  const boyut = Math.round(parseFloat(im.size) * parseInt(im.scale, 10));
  const gorunum = (im.appearances || []).map((a) => a.value)[0];
  const kaynak = gorunum === 'dark' ? KAYNAK.icon_ios_dark : gorunum === 'tinted' ? KAYNAK.icon_ios_tintable : KAYNAK.icon_opaque;
  let veri = await png(kaynak, boyut);
  // Açık ikon opak olmalı (alfa kanalı App Store'da reddedilir).
  if (!gorunum) veri = await sharp(veri).flatten({ background: RENK }).removeAlpha().png({ compressionLevel: 9 }).toBuffer();
  yazilan.push(yaz(path.join(iosDir, im.filename), veri));
}

// macOS AppIcon.appiconset.
const macDir = path.join(KOK, 'macos/Runner/Assets.xcassets/AppIcon.appiconset');
const macIc = JSON.parse(fs.readFileSync(path.join(macDir, 'Contents.json'), 'utf8'));
for (const im of macIc.images) {
  if (!im.filename) continue;
  const boyut = Math.round(parseFloat(im.size) * parseInt(im.scale, 10));
  yazilan.push(yaz(path.join(macDir, im.filename), await png(KAYNAK.icon_macos, boyut)));
}

// iOS 26 / macOS 26 katmanlı ikon (Icon Composer `AppIcon.icon`): tek katman, beyaz glif;
// zemin marka rengi, koyu görünümde siyah zemin + marka renginde glif, renklendirilebilirde gri.
const rgb = (hex) => hex.match(/[0-9a-f]{2}/gi).map((h) => (parseInt(h, 16) / 255).toFixed(5)).join(',');
const iconJson = {
  'fill-specializations': [
    { value: { solid: `srgb:${rgb(RENK)},1.00000` } },
    { appearance: 'dark', value: { solid: 'srgb:0.00000,0.00000,0.00000,1.00000' } },
  ],
  groups: [{
    layers: [{
      'fill-specializations': [
        { appearance: 'dark', value: { solid: `srgb:${rgb(RENK)},1.00000` } },
        { appearance: 'tinted', value: { 'automatic-gradient': 'gray:0.94850,1.00000' } },
      ],
      glass: false,
      'image-name': 'foreground.svg',
      name: 'foreground',
      position: { scale: 1, 'translation-in-points': [0, 0] },
    }],
    shadow: { kind: 'neutral', opacity: 0.5 },
    translucency: { enabled: true, value: 0.5 },
  }],
  'supported-platforms': { circles: ['watchOS'], squares: 'shared' },
};
for (const d of ['ios/Runner/AppIcon.icon', 'macos/AppIcon.icon']) {
  const dir = path.join(KOK, d);
  for (const eski of ['shadowedPaper.svg', 'yellowPaper.svg']) {
    const p = path.join(dir, 'Assets', eski);
    if (fs.existsSync(p)) { fs.unlinkSync(p); yazilan.push('- ' + path.relative(KOK, p)); }
  }
  yazilan.push(yaz(path.join(dir, 'Assets/foreground.svg'), svg(glif(128, 128, 32, '#ffffff'))));
  yazilan.push(yaz(path.join(dir, 'icon.json'), JSON.stringify(iconJson, null, 2) + '\n'));
}

// Windows: PNG-in-ICO, plakalı işaret.
const icoBoyut = [16, 24, 32, 48, 64, 128, 256];
const pngler = [];
for (const b of icoBoyut) pngler.push({ boyut: b, veri: await png(KAYNAK.icon_linux, b) });
const bas = Buffer.alloc(6 + 16 * pngler.length);
bas.writeUInt16LE(0, 0); bas.writeUInt16LE(1, 2); bas.writeUInt16LE(pngler.length, 4);
let ofset = bas.length;
pngler.forEach(({ boyut, veri }, i) => {
  const o = 6 + 16 * i;
  bas.writeUInt8(boyut >= 256 ? 0 : boyut, o); bas.writeUInt8(boyut >= 256 ? 0 : boyut, o + 1);
  bas.writeUInt16LE(1, o + 4); bas.writeUInt16LE(32, o + 6);
  bas.writeUInt32LE(veri.length, o + 8); bas.writeUInt32LE(ofset, o + 12);
  ofset += veri.length;
});
yazilan.push(yaz(path.join(KOK, 'windows/runner/resources/app_icon.ico'), Buffer.concat([bas, ...pngler.map((p) => p.veri)])));

console.log(yazilan.length + ' dosya'); console.log(yazilan.filter((y) => y.startsWith('-') || !y.includes('Icon-App') && !y.includes('app_icon-')).join('\n'));
