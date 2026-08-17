import 'package:flutter/material.dart';

/// Simon Diyor ki oyunundaki 4 sabit kutu; her biri benzersiz bir
/// renk+şekil kombinasyonu. Board hep bu 4 kombinasyondan oluştuğu için
/// (yalnızca ekrandaki sırası her turda karışır) özel bir eşitlik/hash
/// gerektiren bir sınıf yerine tek bir enum yeterli — `StroopColor`/
/// `SequenceTileColor` ile aynı desen.
enum SimonTileId { redCircle, blueSquare, greenTriangle, yellowStar }

extension SimonTileIdInfo on SimonTileId {
  Color get color => switch (this) {
    SimonTileId.redCircle => Colors.red,
    SimonTileId.blueSquare => Colors.blue,
    SimonTileId.greenTriangle => Colors.green,
    SimonTileId.yellowStar => Colors.amber.shade700,
  };

  IconData get icon => switch (this) {
    SimonTileId.redCircle => Icons.circle,
    SimonTileId.blueSquare => Icons.square,
    // Material ikon setinde hazır bir üçgen ikonu yok; change_history en
    // yakın (üçgen şeklinde) hazır ikon.
    SimonTileId.greenTriangle => Icons.change_history,
    SimonTileId.yellowStar => Icons.star,
  };

  String get colorLabel => switch (this) {
    SimonTileId.redCircle => 'Kırmızı',
    SimonTileId.blueSquare => 'Mavi',
    SimonTileId.greenTriangle => 'Yeşil',
    SimonTileId.yellowStar => 'Sarı',
  };

  String get shapeLabel => switch (this) {
    SimonTileId.redCircle => 'Daire',
    SimonTileId.blueSquare => 'Kare',
    SimonTileId.greenTriangle => 'Üçgen',
    SimonTileId.yellowStar => 'Yıldız',
  };
}
