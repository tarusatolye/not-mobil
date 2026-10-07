import 'package:flutter/material.dart';
import 'package:saber/tarus/tarus_renkler.dart';

class FaqListView extends StatelessWidget {
  const new({super.key, required this.items, this.shrinkWrap = false});

  final List<FaqItem> items;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      itemBuilder: (BuildContext context, int index) {
        return _FaqTile(item: items[index]);
      },
    );
  }
}

class _FaqTile extends StatelessWidget {
  const new({required this.item});

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return ExpansionTile(
      tilePadding: const .symmetric(horizontal: 4),
      childrenPadding: const .fromLTRB(4, 0, 4, 12),
      expandedAlignment: .centerLeft,
      title: Text(
        item.question,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: r.text,
        ),
      ),
      children: [
        SelectableText(
          item.answer,
          style: TextStyle(fontSize: 13, color: r.muted2, height: 1.5),
        ),
      ],
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  new(this.question, this.answer);
}
