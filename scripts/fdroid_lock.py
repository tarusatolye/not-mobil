"""pubspec.lock'tan FOSS yamasının çıkardığı paketleri adla siler.

Satır numaralı yama (patches/pre/pubspec-fdroid.lock.patch) kilit dosyası her güncellendiğinde
kayıyor ve CRLF checkout'ta hiç tutmuyor; çıkarılacak paket adları yine o yamadan okunur.
"""
import re

yama = open('patches/pre/pubspec-fdroid.lock.patch', encoding='utf-8').read().replace('\r', '')
cik = {m.group(1) for m in re.finditer(r'(?m)^-  ([a-z0-9_]+):$', yama)}

kilit = open('pubspec.lock', encoding='utf-8').read().replace('\r\n', '\n')
bloklar = re.split(r'(?m)^(?=  [a-z0-9_]+:$)', kilit)


def ad(blok):
    m = re.match(r'  ([a-z0-9_]+):\n', blok)
    return m.group(1) if m else None


kalan = [b for b in bloklar if ad(b) not in cik]
open('pubspec.lock', 'w', encoding='utf-8', newline='\n').write(''.join(kalan))
print('pubspec.lock: %d paket çıkarıldı (%s)' % (len(bloklar) - len(kalan), ', '.join(sorted(cik))))
