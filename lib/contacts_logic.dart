import 'contact_item.dart';

List<ContactItem> filterAndSort(
  List<ContactItem> contacts, {
  required String query,
  required bool ascending,
}) {
  final normalized = query.trim().toLowerCase();
  final result =
      contacts
          .where((contact) => contact.name.toLowerCase().contains(normalized))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return ascending ? result : result.reversed.toList();
}
