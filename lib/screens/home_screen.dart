import 'package:flutter/material.dart';
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
          _showError('URL invalida na tag NFC: $url');
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
        _showError('QR Code nao contem uma URL valida.');
      }
    }
  }

  void _openManualUrl() {
    final url = _urlController.text.trim();
    final normalized = UrlService.normalize(url);
    if (normalized != null) {
      _openUrl(normalized);
    } else {
      _showError('Por favor, insira uma URL valida.');
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'HTML VIEWER',
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Abra paginas HTML via QR Code ou NFC',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              _buildOptionCard(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: AppTheme.accent,
                title: 'Escanear QR Code',
                subtitle: 'Aponte a camera para um QR Code com URL',
                onTap: _openQrScanner,
              ),
              const SizedBox(height: 16),
              if (_nfcAvailable)
                _buildOptionCard(
                  icon: Icons.nfc_rounded,
                  iconColor: AppTheme.accentSecondary,
                  title: _nfcListening ? 'Aguardando tag NFC...' : 'Aproximar tag NFC',
                  subtitle: _nfcListening
                      ? 'Encoste o dispositivo na tag NFC'
                      : 'Leia uma tag NFC com URL embutida',
                  onTap: _nfcListening ? _stopNfcScan : _startNfcScan,
                  isActive: _nfcListening,
                ),
              if (_nfcAvailable) const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Digitar URL',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      style: GoogleFonts.spaceMono(color: AppTheme.textPrimary, fontSize: 13),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'http://192.168.1.10 ou https://site.com',
                        hintStyle: GoogleFonts.spaceMono(
                            color: AppTheme.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _openManualUrl(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openManualUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'ABRIR',
                          style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.w700, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Suporta redes locais e URLs online',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? iconColor.withOpacity(0.08) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? iconColor.withOpacity(0.5) : AppTheme.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isActive
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: iconColor),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
