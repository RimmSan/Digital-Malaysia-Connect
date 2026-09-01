import 'package:flutter/material.dart';

class DataSourceLabel extends StatelessWidget {
  const DataSourceLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.source_outlined, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          'Data source: Malaysian Government Open Data (data.gov.my)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}