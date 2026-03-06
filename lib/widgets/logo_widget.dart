import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
	return Container(
  	width: 72,
  	height: 72,
  	decoration: const BoxDecoration(
    	color: Color(0xFF3B47FF),
    	shape: BoxShape.circle,
    	boxShadow: [
      	BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 6)),
    	],
  	),
  	child: const Center(
    	child: Icon(Icons.all_inbox_rounded, color: Colors.white, size: 34),
  	),
	);
  }
}
