import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final Color? borderColor;

  const SectionCard({
	super.key,
	required this.child,
	this.bgColor,
	this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
	return Container(
  	padding: const EdgeInsets.all(14),
  	decoration: BoxDecoration(
    	color: bgColor ?? Colors.white,
    	borderRadius: BorderRadius.circular(12),
    	border: Border.all(color: borderColor ?? Colors.black12),
  	),
  	child: child,
	);
  }
}


