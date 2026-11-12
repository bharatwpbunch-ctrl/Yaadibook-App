import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

/// Service managing customer communication shortcuts (Phone calls & WhatsApp).
class CommunicationService {
  CommunicationService._();

  /// Normalizes phone numbers for consistent comparisons and duplicate detection.
  /// Converts e.g. "+91 98250-12345", "098250 12345", "919825012345" to "9825012345".
  static String normalizePhoneNumber(String raw) {
    if (raw.trim().isEmpty) return '';

    // Remove all whitespace, dashes, parentheses, dots
    var digitsOnly = raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Strip leading '+'
    if (digitsOnly.startsWith('+')) {
      digitsOnly = digitsOnly.substring(1);
    }

    // Strip India country code '91' if it leaves 10 digits
    if (digitsOnly.startsWith('91') && digitsOnly.length == 12) {
      digitsOnly = digitsOnly.substring(2);
    }

    // Strip leading '0' if it leaves 10 digits
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      digitsOnly = digitsOnly.substring(1);
    }

    return digitsOnly;
  }

  /// Formats phone number for WhatsApp with country code (e.g. "919825012345").
  static String formatForWhatsApp(String raw) {
    final normalized = normalizePhoneNumber(raw);
    if (normalized.length == 10) {
      return '91$normalized';
    }
    // If already has country code
    return normalized;
  }

  /// Opens the device's native phone dialer with the customer's phone number.
  /// Does not automatically place the call (per privacy and platform rules).
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Cannot launch phone dialer for: $clean');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to launch phone dialer', e, stack);
      return false;
    }
  }

  /// Opens WhatsApp with a prefilled message.
  /// Requires the user to manually review and send the message inside WhatsApp.
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    final waNumber = formatForWhatsApp(phoneNumber);
    if (waNumber.isEmpty) return false;

    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';

    // Priority 1: Native WhatsApp deep link scheme
    final nativeUri = Uri.parse(
      'whatsapp://send?phone=$waNumber${encodedMessage.isNotEmpty ? '&text=$encodedMessage' : ''}',
    );

    // Priority 2: Universal wa.me web link fallback
    final webUri = Uri.parse(
      'https://wa.me/$waNumber${encodedMessage.isNotEmpty ? '?text=$encodedMessage' : ''}',
    );

    try {
      if (kIsWeb) {
        return await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('WhatsApp is not available on this device');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to open WhatsApp', e, stack);
      return false;
    }
  }

  /// Opens the native SMS app with a prefilled phone number and message.
  /// Never auto-sends; user must review and tap send.
  static Future<bool> openSms({
    required String phoneNumber,
    String? message,
  }) async {
    final clean = phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.isEmpty) return false;

    final encodedBody = message != null ? Uri.encodeComponent(message) : '';
    final uri = Uri.parse(
      'sms:$clean${encodedBody.isNotEmpty ? '?body=$encodedBody' : ''}',
    );

    try {
      if (kIsWeb) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Cannot launch SMS app for: $clean');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to launch SMS app', e, stack);
      return false;
    }
  }

  /// Extracts all {{variable_name}} placeholders from a template string.
  static List<String> extractVariables(String template) {
    final regex = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}');
    final matches = regex.allMatches(template);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  /// Replaces all {{variable_name}} placeholders with provided values.
  static String replaceVariables(String template, Map<String, dynamic> data) {
    var result = template;
    data.forEach((key, val) {
      result = result.replaceAll('{{$key}}', val?.toString() ?? '');
    });
    return result;
  }
}
