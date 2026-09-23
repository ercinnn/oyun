import 'package:flutter/material.dart';

/// 3B görünümlerin üstündeki yuvarlak, yarı saydam denetim düğmesi
/// (yakınlaştır/uzaklaştır/döndür). `Town3DView` ve `Room3DView` ortak kullanır.
class SceneZoomButton extends StatelessWidget {
  const SceneZoomButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xB3263238),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
