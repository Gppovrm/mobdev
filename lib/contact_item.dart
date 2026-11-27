class ContactItem {
  final String id;
  final String name;
  final String? phone;
  final bool hasEmail;

  const ContactItem({
    required this.id,
    required this.name,
    this.phone,
    this.hasEmail = false,
  });
}
