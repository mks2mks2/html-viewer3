import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/nfc_service.dart';
import '../services/url_service.dart';
import 'qr_scanner_screen.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _nfcAvailable = false;
  bool _nfcListening = false;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcService.isAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  void _startNfcScan() async {
    setState(() => _nfcListening = true);
    await NfcService.startSession(
      onUrl: (url) {
        if (!mounted) return;
        setState(() => _nfcListening = false);
        final normalized = UrlService.normalize(url);
        if (normalized != null) {
          _openUrl(normalized);
        } else {
          _showError('URL inválida na tag NFC: $url');
        }
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() => _nfcListening = false);
        _showError(msg);
      },
    );
  }

  void _stopNfcScan() {
    NfcService.stopSession();
    setState(() => _nfcListening = false);
  }

  void _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      final normalized = UrlService.normalize(result);
      if (normalized != null) {
        _openUrl(normalized);
      } else {
        _showError('QR Code não contém uma URL válida.');
      }
    }
  }

  void _openManualUrl() {
    final url = _urlController.text.trim();
    final normalized = UrlService.normalize(url);
    if (normalized != null) {
      _openUrl(normalized);
    } else {
      _showError('Por favor, insira uma URL válida.');
    }
  }

  void _openUrl(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebViewScreen(url: url)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    if (_nfcListening) NfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildQrCard(),
              const SizedBox(height: 16),
              if (_nfcAvailable) ...[
                _buildNfcCard(),
                const SizedBox(height: 16),
              ],
              _buildManualCard(),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
              ),
              child: const Icon(Icons.language_rounded, color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Text('HTML VIEWER',
              style: GoogleFonts.spaceMono(
