import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;
  final Color? valueColor;

  const MetricCard({
	super.key,
	required this.icon,
	required this.iconBg,
	required this.value,
	required this.label,
	this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
	final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2; // two per row with spacing

	return Container(
  	width: w,
  	padding: const EdgeInsets.all(12),
  	decoration: BoxDecoration(
    	color: Colors.white,
    	borderRadius: BorderRadius.circular(12),
    	border: Border.all(color: Colors.black12),
  	),
  	child: Row(
    	crossAxisAlignment: CrossAxisAlignment.start,
    	children: [
      	Container(
        	padding: const EdgeInsets.all(8),
        	decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        	child: Icon(icon, color: Colors.black87, size: 20),
      	),
      	const SizedBox(width: 10),
      	Expanded(
        	child: Column(
          	crossAxisAlignment: CrossAxisAlignment.start,
          	children: [
            	Text(value,
                	style: TextStyle(
                  	fontSize: 18,
                  	fontWeight: FontWeight.w700,
                  	color: valueColor ?? Colors.black,
                	)),
            	const SizedBox(height: 2),
            	Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A7A7A))),
          	],
        	),
      	),
    	],
  	),
	);
  }
}


