import 'package:flutter/material.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/data/version.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/surum_notlari.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Not marka rengi (`marka.json` → not.renk).
const _notRengi = Color(0xFFAC865A);

/// Hakkında ve sürüm notları (STANDARTLAR §19, §19e; kabuk
/// `HakkindaSayfasi` düzeni): kimlik kartı, yetenekler ve geliştirici,
/// lisans, sürüm notları. Geniş ekranda iki sütun, telefonda tek sütun.
class HakkindaSayfasi extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width >= 860;
    final sol = <Widget>[
      const _KimlikKarti(),
      const SizedBox(height: TarusOlcu.blokArasi),
      const _YeteneklerKarti(),
      const SizedBox(height: TarusOlcu.blokArasi),
      const _LisansKarti(),
    ];
    const sag = _SurumNotlariKarti();
    return Scaffold(
      appBar: AppBar(title: Text(t.tarus.hakkinda)),
      body: SafeArea(
        top: false,
        child: genis
            ? Padding(
                padding: const EdgeInsets.all(TarusOlcu.sayfaYatay),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 85, child: ListView(children: sol)),
                    const SizedBox(width: TarusOlcu.sayfaYatay),
                    const Expanded(
                      flex: 115,
                      child: SingleChildScrollView(child: sag),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(TarusOlcu.sayfaYatay),
                children: [
                  ...sol,
                  const SizedBox(height: TarusOlcu.blokArasi),
                  sag,
                ],
              ),
      ),
    );
  }
}

class const _KimlikKarti() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    Widget alan(String etiket, Widget deger) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket, style: TextStyle(fontSize: 11, color: r.muted2)),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: r.text,
            ),
            child: deger,
          ),
        ],
      ),
    );
    return TarusKart(
      padding: const EdgeInsets.all(TarusOlcu.kart + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: r.elev1,
                ),
                child: const TarusNotIsareti(boyut: 64),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'tarus '),
                      TextSpan(
                        text: 'Not',
                        style: TextStyle(color: _notRengi),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: r.text,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t.tarus.urunTanimi,
            style: TextStyle(fontSize: 13, color: r.muted2, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: r.bdr1)),
            ),
            child: Row(
              children: [
                alan(
                  t.tarus.uygulama,
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'tarus '),
                        TextSpan(
                          text: 'Not',
                          style: TextStyle(color: _notRengi),
                        ),
                      ],
                    ),
                  ),
                ),
                alan(
                  t.tarus.surum,
                  Text(buildName, style: TextStyle(color: r.accent)),
                ),
                alan(t.tarus.ilkYayin, const Text(ilkYayin)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _YeteneklerKarti() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final yetenekler = [
      (
        TarusIkon.dolmaKalem,
        t.tarus.yetenek.kalemBaslik,
        t.tarus.yetenek.kalem,
      ),
      (TarusIkon.kagit, t.tarus.yetenek.sayfaBaslik, t.tarus.yetenek.sayfa),
      (TarusIkon.klasor, t.tarus.yetenek.klasorBaslik, t.tarus.yetenek.klasor),
      (
        TarusIkon.esitle,
        t.tarus.yetenek.esitlemeBaslik,
        t.tarus.yetenek.esitleme,
      ),
      (
        TarusIkon.disaAktar,
        t.tarus.yetenek.disaAktarBaslik,
        t.tarus.yetenek.disaAktar,
      ),
    ];
    return TarusKart(
      padding: const EdgeInsets.all(TarusOlcu.kart + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (ikon, baslik, aciklama) in yetenekler)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: r.ovl1,
                  borderRadius: BorderRadius.circular(TarusOlcu.rLg),
                  border: Border.all(color: r.bdr1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: r.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(TarusOlcu.rMd),
                        border: Border.all(
                          color: r.accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(ikon, size: 16, color: r.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            baslik,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: r.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            aciklama,
                            style: TextStyle(
                              fontSize: 12,
                              color: r.muted2,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 12),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: r.bdr1)),
            ),
            child: Row(
              children: [
                Text(
                  t.tarus.gelistirici,
                  style: TextStyle(fontSize: 12, color: r.muted2),
                ),
                const Spacer(),
                Tooltip(
                  message: 'tarus web sitesi',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => launchUrl(Uri.parse('https://tarus.tr')),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          const TarusIsareti(boyut: 18),
                          const SizedBox(width: 6),
                          Text(
                            'tarus',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: r.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GPL-3.0 bildirimi ve kaynak bağlantıları (TARUS_NOT.md → Lisans).
class const _LisansKarti() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    Widget baglanti(String metin, Uri adres) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 20,
      leading: const Icon(TarusIkon.disBaglanti, size: 16),
      title: Text(metin, style: TextStyle(fontSize: 13, color: r.accent)),
      onTap: () => launchUrl(adres),
    );
    return TarusKart(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.tarus.lisans,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: r.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppInfo.tarusLisansNotu,
            style: TextStyle(fontSize: 12, color: r.muted2, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            t.appInfo.licenseNotice(buildYear: buildYear),
            style: TextStyle(fontSize: 11, color: r.muted, height: 1.45),
          ),
          const SizedBox(height: 4),
          baglanti(t.tarus.kaynakKodu, AppInfo.kaynakKoduUrl),
          baglanti(t.tarus.saberProjesi, AppInfo.saberKaynakUrl),
          baglanti(t.appInfo.licenseButton, AppInfo.licenseUrl),
          baglanti(t.appInfo.privacyPolicyButton, AppInfo.privacyPolicyUrl),
        ],
      ),
    );
  }
}

class const _SurumNotlariKarti() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return TarusKart(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.tarus.surumNotlari,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: r.text,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < surumNotlari.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i == surumNotlari.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: r.bdr1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surumNotlari[i].surum,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: r.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          surumNotlari[i].tarih,
                          style: TextStyle(fontSize: 11, color: r.muted2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      surumNotlari[i].not,
                      style: TextStyle(
                        fontSize: 13,
                        color: r.muted2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
