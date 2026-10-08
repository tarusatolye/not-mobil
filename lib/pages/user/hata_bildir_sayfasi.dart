import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/nextcloud/hata_bildir.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Hata bildir ekranı: başlık, açıklama, isteğe bağlı ekran görüntüsü.
/// Kayıt sistem.tarus.tr Hata Panosu'nda `not.tarus.tr` altında görünür.
class HataBildirSayfasi extends StatefulWidget {
  const new({super.key, this.modul = 'Not Mobil'});

  /// Bildirimin açıldığı ekran (Pusula'da "modül").
  final String modul;

  @override
  State<HataBildirSayfasi> createState() => _HataBildirSayfasiState();
}

class _HataBildirSayfasiState extends State<HataBildirSayfasi> {
  final _baslik = TextEditingController();
  final _aciklama = TextEditingController();
  Uint8List? _goruntu;
  var _goruntuTuru = 'image/png';
  var _gonderiliyor = false;

  @override
  void dispose() {
    _baslik.dispose();
    _aciklama.dispose();
    super.dispose();
  }

  Future<void> _goruntuSec() async {
    final dosya = await FilePicker.pickFile(
      type: FileType.image,
      compressionQuality: 60,
    );
    final yol = dosya?.path;
    if (yol == null) return;
    final veri = await File(yol).readAsBytes();
    final uzanti = (dosya!.extension ?? 'png').toLowerCase();
    if (!mounted) return;
    setState(() {
      _goruntu = veri;
      _goruntuTuru = uzanti == 'jpg' || uzanti == 'jpeg'
          ? 'image/jpeg'
          : 'image/$uzanti';
    });
  }

  Future<void> _gonder() async {
    final mesajci = ScaffoldMessenger.of(context);
    if (_baslik.text.trim().isEmpty || _aciklama.text.trim().isEmpty) {
      mesajci.showSnackBar(
        const SnackBar(content: Text('Başlık ve açıklama zorunlu.')),
      );
      return;
    }
    setState(() => _gonderiliyor = true);
    try {
      await HataBildir.gonder(
        baslik: _baslik.text,
        aciklama: _aciklama.text,
        modul: widget.modul,
        goruntu: _goruntu,
        goruntuTuru: _goruntuTuru,
      );
      mesajci.showSnackBar(
        const SnackBar(content: Text('Teşekkürler, bildiriminiz iletildi.')),
      );
      if (mounted) Navigator.of(context).pop();
    } on HataBildirHatasi catch (e) {
      mesajci.showSnackBar(SnackBar(content: Text(e.mesaj)));
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final bagli = HataBildir.bagliMi;
    return Scaffold(
      appBar: AppBar(title: const Text('Hata bildir')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const .fromLTRB(
              TarusOlcu.sayfaYatay + 4,
              TarusOlcu.sayfaUst,
              TarusOlcu.sayfaYatay + 4,
              32,
            ),
            children: [
              // Bildirimin geldiği ekran (Pusula'da modül) rozeti.
              Align(
                alignment: .centerLeft,
                child: Container(
                  padding: const .symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: r.ovl2,
                    borderRadius: const .all(.circular(999)),
                    border: Border.all(color: r.bdr1),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Icon(TarusIkon.hataBildir, size: 14, color: r.muted2),
                      const SizedBox(width: 6),
                      Text(
                        'Ekran: ${widget.modul}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: r.muted2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!bagli) ...[
                const SizedBox(height: TarusOlcu.blokArasi),
                Container(
                  padding: const .all(12),
                  decoration: BoxDecoration(
                    color: r.warning.withValues(alpha: 0.12),
                    borderRadius: const .all(.circular(TarusOlcu.rLg)),
                    border: Border.all(
                      color: r.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      Icon(TarusIkon.uyari, size: 18, color: r.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hata bildirmek için önce Pusula eşitleme '
                          'belirteciyle bağlanın.',
                          style: TextStyle(
                            fontSize: 13,
                            color: r.text,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _baslik,
                maxLength: 255,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Kısaca ne oldu?',
                ),
              ),
              const SizedBox(height: TarusOlcu.aralik),
              TextField(
                controller: _aciklama,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ne yapıyordunuz, ne bekliyordunuz, ne oldu?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_goruntu != null)
                TarusKart(
                  golge: false,
                  padding: const .all(8),
                  child: Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: const .all(.circular(TarusOlcu.rSm)),
                          child: Image.memory(
                            _goruntu!,
                            height: 220,
                            fit: .contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: r.barBg,
                            borderRadius: const .all(.circular(TarusOlcu.rMd)),
                            border: Border.all(color: r.bdr1),
                          ),
                          child: TarusIkonDugmesi(
                            tooltip: 'Görüntüyü kaldır',
                            ikon: TarusIkon.kapat,
                            boyut: 36,
                            ikonBoyutu: 18,
                            onPressed: () => setState(() => _goruntu = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _goruntuSec,
                  icon: const Icon(TarusIkon.gorselEkle, size: 18),
                  label: const Text('Ekran görüntüsü ekle (isteğe bağlı)'),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: TarusOlcu.birincilDugme,
                child: FilledButton.icon(
                  onPressed: _gonderiliyor || !bagli ? null : _gonder,
                  icon: _gonderiliyor
                      ? const TarusMetinCarki()
                      : const Icon(TarusIkon.gonder, size: 18),
                  label: const Text('Gönder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
