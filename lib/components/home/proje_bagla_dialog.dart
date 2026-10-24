import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/projeler.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

class ProjeBaglaDialog extends StatefulWidget {
  const new({
    super.key,
    required this.existingPath,
    required this.unselectNotes,
    this.projelerArayici,
  });

  final String existingPath;
  final void Function() unselectNotes;

  /// Testlerde özel liste döndürmek için
  final Future<List<PusulaProjesi>> Function(String arama)? projelerArayici;

  static Future<void> dialogAc(
    BuildContext context, {
    required String existingPath,
    required void Function() unselectNotes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ProjeBaglaDialog(
        existingPath: existingPath,
        unselectNotes: unselectNotes,
      ),
    );
  }

  @override
  State<ProjeBaglaDialog> createState() => _ProjeBaglaDialogState();
}

class _ProjeBaglaDialogState extends State<ProjeBaglaDialog> {
  final TextEditingController _aramaController = TextEditingController();
  List<PusulaProjesi> _projeler = [];
  bool _yukleniyor = true;
  String _aramaMetni = '';
  Timer? _aramaZamanlayici;

  @override
  void initState() {
    super.initState();
    _projeleriYukle();
  }

  @override
  void dispose() {
    _aramaZamanlayici?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _projeleriYukle([String arama = '']) async {
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = widget.projelerArayici != null
          ? await widget.projelerArayici!(arama)
          : await fetchPusulaProjects(arama: arama);
      if (mounted) {
        setState(() {
          _projeler = sonuclar;
          _yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  void _aramaDegisti(String deger) {
    setState(() => _aramaMetni = deger.trim().toLowerCase());
    _aramaZamanlayici?.cancel();
    _aramaZamanlayici = Timer(const Duration(milliseconds: 300), () {
      _projeleriYukle(deger.trim());
    });
  }

  Future<void> _projeSec(PusulaProjesi proje) async {
    final etiket = projeEtiketi(proje);
    await projeBagla(
      notYolu: widget.existingPath,
      projeId: proje.id,
      proje: proje,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.unselectNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.tarus.proje.baglandi(proje: etiket))),
    );
  }

  Future<void> _baglantiyiKaldir() async {
    await projeBagiKaldir(notYolu: widget.existingPath);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.unselectNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.tarus.proje.bagiKaldirildi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final dosyaAdi = p.basename(widget.existingPath);
    final bagliProje = notunProjesi(widget.existingPath);

    final gorunenProjeler = _aramaMetni.isEmpty
        ? _projeler
        : _projeler.where((p) {
            final etiket = projeEtiketi(p).toLowerCase();
            return etiket.contains(_aramaMetni);
          }).toList();

    return TarusDialog(
      title: Text(t.tarus.proje.bagla),
      genislik: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Not adı
          Row(
            children: [
              const Icon(TarusIkon.not, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dosyaAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: r.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mevcut bağlı proje varsa göster
          if (bagliProje != null && bagliProje.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: r.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TarusOlcu.rGirdi),
                border: Border.all(color: r.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(TarusIkon.proje, size: 14, color: r.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tarus.proje.bagliProje,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: r.accent,
                          ),
                        ),
                        Text(
                          bagliProje,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: r.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(TarusIkon.sil, size: 16),
                    tooltip: t.tarus.proje.bagiKaldir,
                    onPressed: _baglantiyiKaldir,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Arama kutusu
          TarusMetinAlani(
            controller: _aramaController,
            onChanged: _aramaDegisti,
            hintText: t.tarus.proje.aramaYerTutucu,
            prefixIcon: TarusIkon.proje,
          ),
          const SizedBox(height: 10),

          // Proje listesi
          SizedBox(
            height: 220,
            child: _yukleniyor
                ? const Center(child: TarusMetinCarki())
                : gorunenProjeler.isEmpty
                    ? Center(
                        child: Text(
                          t.tarus.proje.bulunamadi,
                          style: TextStyle(fontSize: 12.5, color: r.muted),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: gorunenProjeler.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: r.bdr1),
                        itemBuilder: (context, index) {
                          final p = gorunenProjeler[index];
                          final etiket = projeEtiketi(p);
                          final seciliMi = etiket == bagliProje;
                          return InkWell(
                            borderRadius:
                                BorderRadius.circular(TarusOlcu.rGirdi),
                            onTap: () => _projeSec(p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    TarusIkon.proje,
                                    size: 16,
                                    color: seciliMi ? r.accent : r.muted,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      etiket,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: seciliMi
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: seciliMi ? r.accent : r.text,
                                      ),
                                    ),
                                  ),
                                  if (seciliMi)
                                    Icon(
                                      TarusIkon.tamam,
                                      size: 16,
                                      color: r.accent,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
