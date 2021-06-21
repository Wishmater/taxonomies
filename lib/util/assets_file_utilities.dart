import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

Future<void> copyAssetsDirectory(String assetsDirectoryPath, String destinationDirectoryPath, {
  ValueNotifier<double?>? progressNotifier,
}) async {
  if (assetsDirectoryPath.startsWith('/')) {
    assetsDirectoryPath = assetsDirectoryPath.substring(1);
  }
  final assets = (await getAssetsPaths()).where((e) => e.startsWith(assetsDirectoryPath)).toList();
  for (var i = 0; i < assets.length; ++i) {
    progressNotifier?.value = (i / assets.length);
    final data = await rootBundle.load(assets[i]);
    final destinationFile = File(p.join(destinationDirectoryPath, assets[i]));
    await destinationFile.create(recursive: true);
    await destinationFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}

Future<void> copyAssetsFile(String assetPath, String destinationFilePath) async {

}

Future<List<String>> getAssetsPaths() async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
  return manifestMap.keys.toList();
}