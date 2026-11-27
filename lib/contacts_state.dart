import 'contact_item.dart';

sealed class ContactsState {
  const ContactsState();
}

final class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

final class ContactsNoAccess extends ContactsState {
  final bool needsSettings;
  const ContactsNoAccess({required this.needsSettings});
}

final class ContactsLoaded extends ContactsState {
  final List<ContactItem> contacts;
  const ContactsLoaded(this.contacts);
}

final class ContactsFailed extends ContactsState {
  const ContactsFailed();
}
