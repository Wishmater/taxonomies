import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:taxonomies/models/instance.dart';
import 'package:taxonomies/router.dart';
import 'package:dartx/dartx.dart';

class QrPage extends StatefulWidget {

  static String? lastResult;

  @override
  _QrPageState createState() => _QrPageState();

}

class _QrPageState extends State<QrPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        controller?.pauseCamera();
      } else if (Platform.isIOS) {
        controller?.resumeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.first.then((scanData) async {
      if (result==null) {
        result = scanData;
        String query = scanData.code;
        int index = query.lastIndexOf('=');
        if (index>=0) {
          query = query.substring(index+1);
        }
        final lines = LineSplitter.split(query).where((element) => element.isNotEmpty);
        query = lines.isEmpty ? '' : lines.first.trim();
        print('QR Type: ${scanData.format.formatName}');
        print('QR Raw: ${scanData.code}');
        print('QR Read: $query');
        var instances = await Instance.getSearchResults(query);
        var exact = instances.where((element) => element.name.toUpperCase()==query.toUpperCase()).toList();
        if (exact.isNotEmpty) instances = exact;
        print(instances);
        if (instances.length==1) {
          print(instances.first.name);
          MyFluroRouter.cache = instances.first;
          Navigator.of(context).pushReplacementNamed('/view?id=${instances.first.id}');
        } else {
          QrPage.lastResult = query;
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.settings.name!='/search');
          Navigator.of(context).pushNamed('/search');
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

}