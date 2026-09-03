import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareBytes(List<int> bytes, String fileName) async {
  final file = File('${(await getTemporaryDirectory()).path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)]);
}
