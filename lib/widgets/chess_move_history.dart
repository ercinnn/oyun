import 'package:flutter/material.dart';

/// Oynanan hamlelerin listesi ("1. e4 e5", "2. Af3 Ac6" …).
///
/// Tek widget iki yerleşimi de yapar: geniş ekranda tahtanın sağında dikey
/// bir panel ([Axis.vertical]), dar ekranda tahtanın altında yatay kayan bir
/// şerit ([Axis.horizontal]). İkisi de aynı "hamle çiftleri" verisini
/// gösterdiği için ayrı iki widget yazmak yerine [axis] parametresi tercih
/// edildi.
///
/// Her yeni hamlede liste sonuna kaydırılır — kullanıcı elle kaydırmak
/// zorunda kalmadan son hamleyi görsün diye.
class ChessMoveHistory extends StatefulWidget {
  const ChessMoveHistory({
    super.key,
    required this.notations,
    this.axis = Axis.vertical,
  });

  final List<String> notations;
  final Axis axis;

  static const panel = Color(0xFF12161F);
  static const _accent = Color(0xFF6C8CFF);
  static const _text = Color(0xFFE7ECF5);
  static const _muted = Color(0xFF7C8799);

  @override
  State<ChessMoveHistory> createState() => _ChessMoveHistoryState();
}

class _ChessMoveHistoryState extends State<ChessMoveHistory> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ChessMoveHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notations.length != oldWidget.notations.length) {
      // Liste bu frame'de henüz uzamadığı için kaydırma bir sonraki frame'e
      // bırakılıyor. `animateTo` yerine `jumpTo`: sürekli çalışan bir
      // animasyon widget testlerinde `pumpAndSettle`'ı gereksizce uzatır.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Hamleleri "sıra numarası + beyaz + siyah" üçlülerine böler; son çiftte
  /// siyah henüz oynamamış olabilir.
  List<(int, String, String?)> get _rows {
    final rows = <(int, String, String?)>[];
    for (var i = 0; i < widget.notations.length; i += 2) {
      rows.add((
        i ~/ 2 + 1,
        widget.notations[i],
        i + 1 < widget.notations.length ? widget.notations[i + 1] : null,
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final isVertical = widget.axis == Axis.vertical;

    return Container(
      decoration: BoxDecoration(
        color: ChessMoveHistory.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: EdgeInsets.all(isVertical ? 10 : 6),
      child: rows.isEmpty
          ? _EmptyHint(isVertical: isVertical)
          : isVertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 14,
                      color: ChessMoveHistory._muted,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'HAMLELER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: ChessMoveHistory._muted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.notations.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ChessMoveHistory._accent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    itemBuilder: (context, index) => _HistoryRow(
                      row: rows[index],
                      isLast: index == rows.length - 1,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (context, index) => _HistoryChip(
                row: rows[index],
                isLast: index == rows.length - 1,
              ),
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.isVertical});

  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isVertical ? 'Henüz hamle\nyapılmadı' : 'Henüz hamle yapılmadı',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: ChessMoveHistory._muted),
      ),
    );
  }
}

/// Dikey paneldeki tek satır: "12.  Axd5  Vf6".
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row, required this.isLast});

  final (int, String, String?) row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (number, whiteMove, blackMove) = row;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$number.',
              style: const TextStyle(
                fontSize: 11,
                color: ChessMoveHistory._muted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: _MoveText(
              text: whiteMove,
              highlighted: isLast && blackMove == null,
            ),
          ),
          Expanded(
            child: _MoveText(
              text: blackMove ?? '',
              highlighted: isLast && blackMove != null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yatay şeritteki tek öğe: "12. Axd5 Vf6".
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.row, required this.isLast});

  final (int, String, String?) row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (number, whiteMove, blackMove) = row;
    final label = blackMove == null
        ? '$number. $whiteMove'
        : '$number. $whiteMove $blackMove';
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isLast
              ? ChessMoveHistory._accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
            color: isLast
                ? ChessMoveHistory._text
                : ChessMoveHistory._muted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _MoveText extends StatelessWidget {
  const _MoveText({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        color: highlighted
            ? ChessMoveHistory._accent
            : ChessMoveHistory._text,
      ),
    );
  }
}
