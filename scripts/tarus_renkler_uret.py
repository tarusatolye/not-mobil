"""tarus.css -> lib/tarus/tarus_renkler_veri.dart (8 tema token değerleri)."""
import re
import sys

css_yolu, cikti = sys.argv[1], sys.argv[2]
css = open(css_yolu, encoding='utf-8').read()

TEMALAR = ['modern', 'sage', 'karanlik', 'ocean', 'sand', 'sunset', 'forest', 'violet']
ALANLAR = [
    ('bg', 'bg'), ('surface', 'surface'), ('card', 'card'), ('card-2', 'card2'),
    ('border', 'border'), ('border-2', 'border2'), ('text', 'text'),
    ('muted2', 'muted2'), ('muted', 'muted'), ('accent', 'accent'),
    ('accent-lt', 'accentLt'), ('success', 'success'), ('warning', 'warning'),
    ('danger', 'danger'), ('modal-bg', 'modalBg'), ('input-bg', 'inputBg'),
    ('ovl-1', 'ovl1'), ('ovl-2', 'ovl2'), ('ovl-3', 'ovl3'), ('ovl-4', 'ovl4'),
    ('ovl-5', 'ovl5'), ('bdr-1', 'bdr1'), ('bdr-2', 'bdr2'), ('bdr-3', 'bdr3'),
]


def blok(ad):
    m = re.search(r'\.theme-' + ad + r'\s*\{(.*?)\n\}', css, re.S)
    if not m:
        raise SystemExit('tema yok: ' + ad)
    return m.group(1)


def deger(govde, ad):
    m = re.search(r'--' + re.escape(ad) + r'\s*:\s*([^;]+);', govde)
    return m.group(1).strip() if m else None


def renk(v):
    v = v.strip()
    if v.startswith('#'):
        h = v[1:]
        if len(h) == 3:
            h = ''.join(c * 2 for c in h)
        return 'Color(0xFF%s)' % h.upper()
    m = re.match(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)', v)
    if m:
        r, g, b = (int(m.group(i)) for i in (1, 2, 3))
        a = float(m.group(4)) if m.group(4) is not None else 1.0
        return 'Color(0x%02X%02X%02X%02X)' % (round(a * 255), r, g, b)
    raise ValueError(v)


def golgeler(v):
    parcalar = re.findall(r'(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(rgba\([^)]*\))', v)
    out = []
    for x, y, blur, c in parcalar:
        ofset = 'Offset.zero' if float(x) == 0 and float(y) == 0 else 'Offset(%s, %s)' % (float(x), float(y))
        out.append('BoxShadow(offset: %s, blurRadius: %s, color: %s)' % (
            ofset, float(blur), renk(c)))
    return '[' + ', '.join(out) + ']'


satirlar = []
for t in TEMALAR:
    g = blok(t)
    alanlar = []
    for css_ad, dart_ad in ALANLAR:
        v = deger(g, css_ad)
        if v is None or v.startswith('var('):
            if css_ad == 'modal-bg':
                v = deger(g, 'card')
            elif css_ad == 'input-bg':
                v = deger(g, 'ovl-3')
            else:
                raise SystemExit('%s: %s yok (%s)' % (t, css_ad, v))
        alanlar.append('    %s: %s,' % (dart_ad, renk(v)))
    alanlar.append('    elev1: %s,' % golgeler(deger(g, 'elev-1')))
    alanlar.append('    elev2: %s,' % golgeler(deger(g, 'elev-2')))
    satirlar.append("  '%s': TarusRenkler(\n%s\n  )," % (t, '\n'.join(alanlar)))

dart = '''// ÜRETİLDİ — elle düzenlemeyin.
// Kaynak: ozluk/tarus-kabuk/css/tarus.css (.theme-* blokları).
// Yeniden üretmek için: python scripts/tarus_renkler_uret.py \\
//   ../ozluk/tarus-kabuk/css/tarus.css lib/tarus/tarus_renkler_veri.dart
part of 'tarus_renkler.dart';

const _temaRenkleri = <String, TarusRenkler>{
%s
};
''' % '\n'.join(satirlar)
open(cikti, 'w', encoding='utf-8', newline='\n').write(dart)
print('ok', cikti)
