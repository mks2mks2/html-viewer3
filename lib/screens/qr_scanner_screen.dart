import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        setState(() => _hasScanned = true);
        _controller.stop();
        Navigator.pop(context, value);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'ESCANEAR QR CODE',
          style: GoogleFonts.spaceMono(
            color: AppTheme.textPrimary,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: AppTheme.accent),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: AppTheme.accent),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent, width: 2),
            ),
            child: Stack(children: _buildCorners()),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Text(
              'Aponte para um QR Code com URL',
              style: GoogleFonts.spaceGrotesk(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.0;
    const color = AppTheme.accent;
    return [
      Positioned(top: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
    ];
  }
}
