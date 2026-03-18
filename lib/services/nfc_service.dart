import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<void> startSession({
    required void Function(String url) onUrl,
    required void Function(String message) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final url = _extractUrl(tag);
            if (url != null) {
              await NfcManager.instance.stopSession();
              onUrl(url);
            } else {
              await NfcManager.instance.stopSession(
                errorMessage: 'Nenhuma URL encontrada na tag NFC.',
              );
              onError('Nenhuma URL encontrada na tag NFC.');
            }
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessage: e.toString(),
            );
            onError(e.toString());
          }
        },
      );
    } catch (e) {
      onError('Erro ao iniciar NFC: $e');
    }
  }

  static Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }

  static String? _extractUrl(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef != null && ndef.cachedMessage != null) {
      for (final record in ndef.cachedMessage!.records) {
        final url = _parseNdefRecord(record);
        if (url != null) return url;
      }
    }
    return null;
  }

  static String? _parseNdefRecord(NdefRecord record) {
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        record.type.length == 1 &&
        record.type[0] == 0x55) {
      return _parseUriRecord(record.payload);
    }
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        record.type.length == 1 &&
        record.type[0] == 0x54) {
      final text = _parseTextRecord(record.payload);
      if (text != null &&
          (text.startsWith('http://') || text.startsWith('https://'))) {
        return text;
      }
    }
    return null;
  }

  static String? _parseUriRecord(List<int> payload) {
    if (payload.isEmpty) return null;
    const prefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://',
      'tel:', 'mailto:', 'ftp://anonymous:anonymous@', 'ftp://ftp.',
      'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
      'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:', 'pop:',
      'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
      'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:',
      'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:',
    ];
    final prefixCode = payload[0];
    final prefix = prefixCode < prefixes.length ? prefixes[prefixCode] : '';
    final rest = String.fromCharCodes(payload.sublist(1));
    return '$prefix$rest';
  }

  static String? _parseTextRecord(List<int> payload) {
    if (payload.isEmpty) return null;
    final langLength = payload[0] & 0x3F;
    final textStart = 1 + langLength;
    if (textStart >= payload.length) return null;
    return String.fromCharCodes(payload.sublist(textStart));
  }
}
