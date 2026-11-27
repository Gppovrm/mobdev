import 'package:flutter_contacts/flutter_contacts.dart';

import 'contact_item.dart';

enum AccessStatus { granted, denied, permanentlyDenied }

abstract interface class ContactsRepository {
  Future<AccessStatus> checkAccess();
  Future<AccessStatus> requestAccess();
  Future<void> openSettings();
  Future<List<ContactItem>> loadContacts();
  Future<Contact?> loadDetails(String id);
}

class DeviceContactsRepository implements ContactsRepository {
  static const _listProperties = {ContactProperty.phone, ContactProperty.email};

  static const _detailsProperties = {
    ContactProperty.name,
    ContactProperty.phone,
    ContactProperty.email,
    ContactProperty.organization,
    ContactProperty.address,
    ContactProperty.event,
    ContactProperty.website,
    ContactProperty.note,
  };

  const DeviceContactsRepository();

  @override
  Future<AccessStatus> checkAccess() async =>
      _toAccess(await FlutterContacts.permissions.check(PermissionType.read));

  @override
  Future<AccessStatus> requestAccess() async =>
      _toAccess(await FlutterContacts.permissions.request(PermissionType.read));

  @override
  Future<void> openSettings() => FlutterContacts.permissions.openSettings();

  @override
  Future<List<ContactItem>> loadContacts() async {
    final contacts = await FlutterContacts.getAll(properties: _listProperties);
    return [
      for (final contact in contacts)
        if (contact.id != null)
          ContactItem(
            id: contact.id!,
            name: contact.displayName?.trim() ?? '',
            phone: _primaryPhone(contact),
            hasEmail: contact.emails.isNotEmpty,
          ),
    ];
  }

  @override
  Future<Contact?> loadDetails(String id) =>
      FlutterContacts.get(id, properties: _detailsProperties);

  String? _primaryPhone(Contact contact) {
    if (contact.phones.isEmpty) return null;
    for (final phone in contact.phones) {
      if (phone.isPrimary == true) return phone.number;
    }
    return contact.phones.first.number;
  }

  AccessStatus _toAccess(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited => AccessStatus.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => AccessStatus.permanentlyDenied,
    PermissionStatus.denied ||
    PermissionStatus.notDetermined => AccessStatus.denied,
  };
}
