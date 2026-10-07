import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nextcloud/nextcloud.dart';

/// Eşitlemede kullanıcıya gösterilecek sunucu durumu (Ayarlar → Eşitleme kartı).
///
/// - [EsitlemeUyariTuru.reddedildi]: sunucu isteği kalıcı olarak reddetti (403).
///   Not sunucusu eski uçtan uca şifreli dosyaları (`.sbe`, `config.sbc`) böyle
///   reddeder ve gövdede Türkçe açıklama gönderir («… tarus Not'u güncelleyin.»);
///   [mesaj] o gövdedir.
/// - [EsitlemeUyariTuru.gecici]: sunucu geçici olarak hizmet veremiyor (503;
///   anahtar servisine ulaşılamıyor). Yerel notlara dokunulmaz, eşitleme
///   kendiliğinden yeniden dener.
enum EsitlemeUyariTuru { reddedildi, gecici }

@immutable
class EsitlemeUyarisi {
  const new(this.tur, [this.mesaj]);

  final EsitlemeUyariTuru tur;

  /// Sunucunun gönderdiği açıklama (yalnız [EsitlemeUyariTuru.reddedildi]).
  final String? mesaj;

  /// Son eşitleme uyarısı; başarılı bir listeleme ya da yükleme siler.
  static final son = ValueNotifier<EsitlemeUyarisi?>(null);

  /// Hatadan uyarı üretir; kullanıcıyı ilgilendirmeyen hatalarda `null`.
  static EsitlemeUyarisi? hatadan(Object hata) {
    if (hata is! DynamiteStatusCodeException) return null;
    switch (hata.statusCode) {
      case HttpStatus.forbidden:
        final govde = hata.response.body.trim();
        return EsitlemeUyarisi(
          .reddedildi,
          govde.isEmpty || govde.length > 300 ? null : govde,
        );
      case HttpStatus.serviceUnavailable:
        return const EsitlemeUyarisi(.gecici);
      default:
        return null;
    }
  }

  /// [hata] bir uyarıya karşılık geliyorsa [son]'a yazar.
  static void kaydet(Object hata) {
    final uyari = hatadan(hata);
    if (uyari != null) son.value = uyari;
  }

  /// Sunucu yeniden yanıt verdi: geçici uyarıyı siler. Kalıcı ret ([reddedildi])
  /// yalnız başarılı bir yüklemeyle silinir ([yuklemeBasarili]).
  static void sunucuYanitVerdi() {
    if (son.value?.tur == .gecici) son.value = null;
  }

  static void yuklemeBasarili() => son.value = null;

  @override
  bool operator ==(Object other) =>
      other is EsitlemeUyarisi && other.tur == tur && other.mesaj == mesaj;

  @override
  int get hashCode => Object.hash(tur, mesaj);

  @override
  String toString() => 'EsitlemeUyarisi($tur, $mesaj)';
}
