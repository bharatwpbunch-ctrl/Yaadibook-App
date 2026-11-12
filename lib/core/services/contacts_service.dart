import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// Lightweight representation of a mobile contact from the device address book.
class DeviceContact {
  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final String? email;

  const DeviceContact({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    this.email,
  });

  String get primaryPhone => phoneNumbers.isNotEmpty ? phoneNumbers.first : '';

  List<String> get phones => phoneNumbers;

  List<String> get emails => email != null ? [email!] : const [];
}

abstract class IContactsService {
  Future<PermissionStatus> checkPermission();
  Future<PermissionStatus> requestPermission();
  Future<List<DeviceContact>> getContacts({String? searchQuery});
}

class DeviceContactsService implements IContactsService {
  @override
  Future<PermissionStatus> checkPermission() async {
    try {
      return await Permission.contacts.status;
    } catch (e, stack) {
      AppLogger.error('Failed to check contacts permission', e, stack);
      return PermissionStatus.denied;
    }
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    try {
      return await Permission.contacts.request();
    } catch (e, stack) {
      AppLogger.error('Failed to request contacts permission', e, stack);
      return PermissionStatus.denied;
    }
  }

  @override
  Future<List<DeviceContact>> getContacts({String? searchQuery}) async {
    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone, ContactProperty.email},
      );

      final List<DeviceContact> results = [];
      final query = searchQuery?.toLowerCase().trim();

      for (final c in contacts) {
        final name = (c.displayName ?? '').trim();
        final phones = c.phones
            .map((p) => p.number.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        if (name.isEmpty && phones.isEmpty) continue;

        // Apply search query filter if provided
        if (query != null && query.isNotEmpty) {
          final matchesName = name.toLowerCase().contains(query);
          final matchesPhone = phones.any(
            (p) => p.replaceAll(' ', '').contains(query),
          );
          if (!matchesName && !matchesPhone) continue;
        }

        results.add(
          DeviceContact(
            id: c.id ?? name,
            displayName: name.isNotEmpty ? name : 'Contact',
            phoneNumbers: phones,
            email: c.emails.isNotEmpty ? c.emails.first.address : null,
          ),
        );
      }

      // Sort alphabetically by name
      results.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      return results;
    } catch (e, stack) {
      AppLogger.error('Failed to fetch device contacts', e, stack);
      return [];
    }
  }
}
