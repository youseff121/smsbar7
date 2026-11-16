import 'package:flutter/material.dart';

class HeaderBackground extends StatelessWidget {
  final double height;

  const HeaderBackground({this.height = 120, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Image.asset(
        "assets/images/background.png",
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        height: height,
      ),
    );
  }
}
