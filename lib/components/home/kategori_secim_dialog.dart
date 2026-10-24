import 'package:flutter/material.dart';
import 'package:saber/tarus/kategori.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Notun kategorisini (Özel / Şirket İçi / Proje) belirleme diyaloğu
/// (Web `HomeDashboard.tsx` kategori modalı karşılığı).
class KategoriSecimDialog extends StatefulWidget {
  const new({
    super.key,
    required this.filePath,
    this.onSaved,
  });

  final String filePath;
  final VoidCallback? onSaved;

  @override
  State<KategoriSecimDialog> createState() => _KategoriSecimDialogState();
}

class _KategoriSecimDialogState extends State<KategoriSecimDialog> {
  late NotKategorisi _seciliKategori;
  late final TextEditingController _projeController;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    final mevcut = notKategorisiAl(widget.filePath);
    _seciliKategori = mevcut.kategori;
    _projeController = TextEditingController(text: mevcut.projeAdi ?? '');
  }

  @override
  void dispose() {
    _projeController.dispose();
    super.dispose();
  }

  String get _notAdi {
    final temiz = kanonikNotYolu(widget.filePath);
    final idx = temiz.lastIndexOf('/');
    return idx >= 0 ? temiz.substring(idx + 1) : temiz;
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);

    final projeAdi = _projeController.text.trim();
    await kategoriDegistir(
      notYolu: widget.filePath,
      kategori: _seciliKategori,
      projeAdi: _seciliKategori == NotKategorisi.proje && projeAdi.isNotEmpty ? projeAdi : null,
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TarusDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kategori ve Proje Belirle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _notAdi,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: r.muted,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Not Kategorisi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: r.muted2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final kat in NotKategorisi.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: kat == NotKategorisi.values.last ? 0 : 6,
                    ),
                    child: _KategoriSecenekButonu(
                      kategori: kat,
                      secili: _seciliKategori == kat,
                      isDark: isDark,
                      r: r,
                      onTap: () {
                        setState(() {
                          _seciliKategori = kat;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (_seciliKategori == NotKategorisi.proje) ...[
            const SizedBox(height: 14),
            Text(
              'Pusula Projesi / Proje Adı',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: r.muted2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _projeController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: r.text),
              decoration: InputDecoration(
                hintText: 'Örn. PRJ-12 · Kadıköy Konut',
                hintStyle: TextStyle(color: r.muted, fontSize: 13),
                filled: true,
                fillColor: r.inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TarusOlcu.rSm),
                  borderSide: BorderSide(color: r.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TarusOlcu.rSm),
                  borderSide: BorderSide(color: r.accent, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TarusDialogDugmesi(
          onPressed: _kaydediliyor ? null : () => Navigator.of(context).pop(),
          isCancelAction: true,
          child: const Text('Vazgeç'),
        ),
        TarusDialogDugmesi(
          onPressed: _kaydediliyor ? null : _kaydet,
          isDefaultAction: true,
          child: Text(_kaydediliyor ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}

class _KategoriSecenekButonu extends StatelessWidget {
  const new({
    required this.kategori,
    required this.secili,
    required this.isDark,
    required this.r,
    required this.onTap,
  });

  final NotKategorisi kategori;
  final bool secili;
  final bool isDark;
  final TarusRenkler r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final katRenk = KategoriRenkleri.renk(kategori, isDark: isDark);
    final ikon = kategoriIkonu(kategori);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TarusOlcu.rSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: secili
                ? katRenk.withValues(alpha: isDark ? 0.20 : 0.12)
                : r.card,
            borderRadius: BorderRadius.circular(TarusOlcu.rSm),
            border: Border.all(
              color: secili
                  ? katRenk
                  : r.bdr2,
              width: secili ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ikon,
                size: 18,
                color: secili ? katRenk : r.muted2,
              ),
              const SizedBox(height: 5),
              Text(
                kategori.etiket,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  color: secili ? katRenk : r.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
