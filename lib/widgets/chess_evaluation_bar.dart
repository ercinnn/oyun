import 'package:flutter/material.dart';

/// Tahtanın solundaki dikey değerlendirme çubuğu: beyazın kazanma şansı kadarı
/// beyaz, kalanı siyah dolar. Her hamleden sonra
/// `ChessController.whiteWinChance` değiştiği için çubuk yumuşak bir geçişle
/// ilerler/geriler.
///
/// Çubuk tahtayla birlikte döner ([flipped]): tahtanın altında hangi renk
/// duruyorsa çubuğun altında da o renk dolar, yoksa iki kişilik modda her
/// hamlede tahta dönerken çubuk ters okunurdu.
class ChessEvaluationBar extends StatelessWidget {
  const ChessEvaluationBar({
    super.key,
    required this.whiteWinChance,
    required this.flipped,
  });

  /// 0.0 = siyah kazanıyor, 1.0 = beyaz kazanıyor.
  final double whiteWinChance;

  final bool flipped;

  static const _panel = Color(0xFF12161F);
  static const _whiteFill = Color(0xFFF2F4F8);
  static const _blackFill = Color(0xFF272C36);
  static const _accent = Color(0xFF6C8CFF);

  @override
  Widget build(BuildContext context) {
    final chance = whiteWinChance.clamp(0.0, 1.0);
    // Alttaki rengin payı: tahta dönmemişse altta beyaz durur.
    final bottomFraction = flipped ? 1 - chance : chance;
    final bottomColor = flipped ? _blackFill : _whiteFill;
    final topColor = flipped ? _whiteFill : _blackFill;
    final percent = (chance * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Readout(
          value: flipped ? percent : 100 - percent,
          forWhite: flipped,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: topColor)),
                    // Alt renk aşağıdan yukarı doğru büyüyen bir dolgu.
                    // `Positioned.fill` şart: `FractionallySizedBox` oranı
                    // uygulamak için sınırlı (bounded) bir yükseklik ister,
                    // yalnızca bottom'a sabitlenmiş bir Positioned ise
                    // sonsuz yükseklik verir.
                    Positioned.fill(
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        heightFactor: bottomFraction,
                        widthFactor: 1,
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(color: bottomColor),
                      ),
                    ),
                    // Ortadaki eşitlik çizgisi — çubuğun hangi yöne
                    // kaydığını okumak için sabit bir referans.
                    const Center(
                      child: SizedBox(
                        height: 1,
                        width: double.infinity,
                        child: ColoredBox(color: _accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _Readout(
          value: flipped ? 100 - percent : percent,
          forWhite: !flipped,
        ),
      ],
    );
  }
}

/// Çubuğun iki ucundaki kazanma yüzdesi (0-100). Rakamlar tabular (sabit
/// genişlikli) çizilir ki değer değişirken metin sağa sola oynamasın —
/// dijital gösterge hissi bunun üzerine kurulu. Yüzde işareti bilerek yok:
/// çubuk yalnızca ~30 piksel geniş, "%100" ikinci satıra kaçıyordu.
///
/// [forWhite] göstergenin hangi tarafa ait olduğunu söyler; siyahın rakamı
/// taş rengiyle değil açık gri çizilir — koyu panelin üstünde koyu gri
/// okunmuyordu.
class _Readout extends StatelessWidget {
  const _Readout({required this.value, required this.forWhite});

  final int value;
  final bool forWhite;

  static const _blackSideText = Color(0xFF9AA5B5);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: ChessEvaluationBar._panel,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: forWhite ? ChessEvaluationBar._whiteFill : _blackSideText,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
