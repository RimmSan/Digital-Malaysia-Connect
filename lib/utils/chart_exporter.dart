import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:excel/excel.dart' hide Border;

import '../models/internet_penetration_data.dart';
import 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart';

class ChartExporter {
  static Future<void> exportWidgetAsImage({
    required GlobalKey boundaryKey,
    required String fileName,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Chart is not ready to export.');

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Could not convert chart to an image.');

    await saveAndShareBytes(byteData.buffer.asUint8List(), '$fileName.png');
  }

  static Future<void> exportDataAsExcel({
    required List<InternetPenetrationData> data,
    required String metricLabel,
    required String metricKey,
    List<MapEntry<String, double>> forecastRows = const [],
    required String fileName,
  }) async {
    final workbook = Excel.createExcel();
    final sheet = workbook['Connectivity Data'];

    sheet.appendRow([
      TextCellValue('Quarter'),
      TextCellValue('Fixed Broadband Rate'),
      TextCellValue('Mobile Broadband Rate'),
      TextCellValue('Mobile Cellular Rate'),
      TextCellValue('Pay TV Rate'),
      TextCellValue('Type'),
    ]);

    String quarterLabel(DateTime date) => 'Q${((date.month - 1) ~/ 3) + 1} ${date.year}';

    for (final d in data) {
      sheet.appendRow([
        TextCellValue(quarterLabel(d.date)),
        DoubleCellValue(d.fbbRate),
        DoubleCellValue(d.mbbRate),
        DoubleCellValue(d.mcRate),
        DoubleCellValue(d.ptvRate),
        TextCellValue('Actual'),
      ]);
    }

    for (final entry in forecastRows) {
      final row = <CellValue?>[TextCellValue(entry.key), null, null, null, null, TextCellValue('Forecast ($metricLabel)')];
      final columnIndex = {'fbbRate': 1, 'mbbRate': 2, 'mcRate': 3, 'ptvRate': 4}[metricKey];
      if (columnIndex != null) row[columnIndex] = DoubleCellValue(entry.value);
      sheet.appendRow(row);
    }

    if (workbook.sheets.containsKey('Sheet1')) workbook.delete('Sheet1');

    final bytes = workbook.save();
    if (bytes == null) throw Exception('Could not generate the Excel file.');

    await saveAndShareBytes(bytes, '$fileName.xlsx');
  }
}