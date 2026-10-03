import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/nextcloud/hata_bildir.dart';

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
    final renk = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hata bildir')),
      body: ListView(
        padding: const .all(16),
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: renk.error),
              const SizedBox(width: 8),
              Text(
                'Ekran: ${widget.modul}',
                style: TextStyle(fontSize: 12, color: renk.onSurfaceVariant),
              ),
            ],
          ),
          if (!HataBildir.bagliMi) ...[
            const SizedBox(height: 12),
            Text(
              'Hata bildirmek için önce Pusula eşitleme belirteciyle bağlanın.',
              style: TextStyle(color: renk.error),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _baslik,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              hintText: 'Kısaca ne oldu?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aciklama,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Ne yapıyordunuz, ne bekliyordunuz, ne oldu?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_goruntu != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: .circular(8),
                  child: Image.memory(_goruntu!, height: 220, fit: .contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Görüntüyü kaldır',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _goruntu = null),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _goruntuSec,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Ekran görüntüsü ekle (isteğe bağlı)'),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _gonderiliyor || !HataBildir.bagliMi ? null : _gonder,
            icon: _gonderiliyor
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
