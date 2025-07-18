import 'dart:convert';
import 'package:checkutil/Mobile/Qrcodes/home_qr.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasPermission = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isDenied) {
      print('Permissão da câmera negada.');
    } else if (status.isPermanentlyDenied) {
      print('Permissão negada permanentemente. Abrindo configurações...');
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code')),
      body: _hasPermission
          ? MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleScanResult(barcode.rawValue!);
                    break; // Evita múltiplos processamentos
                  }
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _handleScanResult(String scanData) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      print('QR Code escaneado: $scanData');

      final Uri? uri = Uri.tryParse(scanData);
      if (uri != null && uri.hasAbsolutePath) {
        print('Redirecionando para link externo: $scanData');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      final Map<String, dynamic> decodedData = jsonDecode(scanData);
      if (decodedData.containsKey('tag') && decodedData.containsKey('unidade')) {
        final String tag = decodedData['tag'];
        final String unidade = decodedData['unidade'];
        
        print('Redirecionando para HomeQRScreen com tag: $tag e unidade: $unidade');
        _navigateToHomeQR(tag, unidade);
      } else {
        print('Nenhuma tag encontrada, lidando com outras informações...');
        _navigateToEquipmentDetails(decodedData);
      }
    } catch (e) {
      print('Erro ao processar QR Code: $e');
    } finally {
      // Aguarda um segundo antes de permitir nova leitura
      await Future.delayed(const Duration(seconds: 1));
      _isProcessing = false;
    }
  }

  void _navigateToHomeQR(String tag, String unidade) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HomeQRScreen(tag: tag, unidade: unidade),
    ),
  );
}


  void _navigateToEquipmentDetails(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(data: data),
      ),
    );
  }
}

class EquipmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const EquipmentDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Equipamento')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tag: ${data['tag']}', style: const TextStyle(fontSize: 18)),
            Text('Tipo: ${data['tipoEquipamento']}', style: const TextStyle(fontSize: 18)),
            Text('Unidade: ${data['unidade']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => launchUrl(
                Uri.parse(data['url']),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Acessar Link'),
            ),
          ],
        ),
      ),
    );
  }
}
