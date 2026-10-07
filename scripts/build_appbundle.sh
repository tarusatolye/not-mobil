#!/usr/bin/env bash
# tarus Not — Google Play için imzalı Android App Bundle (.aab).
#
#   ./scripts/build_appbundle.sh
#
# - FOSS derlemesi (ozluk/tarus.md §4.2, Not Mobil satırı: lisans): kapalı kaynak Onyx SDK'sı,
#   şifresiz HTTP boox deposu ve Sentry çıkarılır. Yama çalışma ağacını geçici
#   değiştirir; betik bitince (hata olsa da) HEAD'e geri alınır. Bu yüzden ağaç
#   temiz olmalı.
# - İmza: git dışı android/key.properties (Play App Signing'de YÜKLEME anahtarı;
#   TARUS_NOT.md → İmza anahtarı). Yoksa durur.
# - Çıktı (output/, git dışı): tarus-not-<sürüm>.aab ve GPL-3.0 §6 için aynı
#   commit'in kaynak arşivi not-mobil-<sürüm>-kaynak.tar.gz.
# - Gerekenler: Flutter (submodules/flutter), Rust (rust-toolchain.toml), JDK.
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER="${FLUTTER:-submodules/flutter/bin/flutter}"

if [ ! -f android/key.properties ]; then
  echo "android/key.properties yok: release imzası olmadan AAB derlenmez (TARUS_NOT.md → İmza anahtarı)." >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "Çalışma ağacı temiz değil: önce commit edin (FOSS yaması bitince ağaç HEAD'e geri alınır)." >&2
  git status --short >&2
  exit 1
fi

surum=$(grep -oE "buildName = '[^']+'" lib/data/version.dart | cut -d"'" -f2)
commit=$(git rev-parse --short HEAD)
mkdir -p output

geri_al() {
  # Yalnız izlenen dosyalar (key.properties ve output/ git dışı, dokunulmaz).
  git checkout -- . 2>/dev/null || true
  rm -rf tmpfdroid
  if [ -x android/gradlew ]; then (cd android && ./gradlew --stop >/dev/null 2>&1) || true; fi
}
trap geri_al EXIT

echo "== tarus Not $surum ($commit): FOSS yaması"
./patches/pre/remove_proprietary_dependencies.sh
patch pubspec.lock < patches/pre/pubspec-fdroid.lock.patch

echo "== flutter build appbundle --release"
"$FLUTTER" build appbundle --release \
  --dart-define=FLAVOR="Google Play" \
  --dart-define=APP_STORE="Google Play" \
  --dart-define=UPDATE_CHECK="false"

aab="output/tarus-not-$surum.aab"
mv build/app/outputs/bundle/release/app-release.aab "$aab"

echo "== GPL-3.0 kaynak arşivi"
git archive --format=tar.gz --prefix="not-mobil-$surum/" -o "output/not-mobil-$surum-kaynak.tar.gz" HEAD

echo "== imza"
if command -v jarsigner >/dev/null; then
  jarsigner -verify "$aab" | tail -1
else
  echo "jarsigner yok (JDK bin PATH'te değil); imzayı Play Console yüklemede denetler."
fi

ls -l "$aab" "output/not-mobil-$surum-kaynak.tar.gz"
if command -v sha256sum >/dev/null; then sha256sum "$aab"; fi
echo "Play Console › Test › Dahili test › Yeni sürüm: $aab yükleyin; sürüm notu store/play/tr-TR/yenilikler.txt."
