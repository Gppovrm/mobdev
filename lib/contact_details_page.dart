import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'contact_item.dart';
import 'contacts_repository.dart';
import 'l10n/app_localizations.dart';

class ContactDetailsPage extends StatefulWidget {
  final ContactsRepository repository;
  final ContactItem contact;

  const ContactDetailsPage({
    super.key,
    required this.repository,
    required this.contact,
  });

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  late Future<Contact?> _details;

  @override
  void initState() {
    super.initState();
    _details = widget.repository.loadDetails(widget.contact.id);
  }

  void _retry() {
    setState(() {
      _details = widget.repository.loadDetails(widget.contact.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailsTitle)),
      body: SafeArea(
        child: FutureBuilder<Contact?>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.detailsError),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: Text(l10n.retry)),
                  ],
                ),
              );
            }
            final contact = snapshot.data;
            if (contact == null) {
              return Center(child: Text(l10n.contactNotFound));
            }
            return _buildDetails(context, l10n, contact);
          },
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    AppLocalizations l10n,
    Contact contact,
  ) {
    final name = contact.displayName?.trim() ?? '';
    final organizations = [
      for (final organization in contact.organizations)
        [
          organization.name,
          organization.jobTitle,
        ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
    ].where((text) => text.isNotEmpty).toList();
    final addresses = [
      for (final address in contact.addresses) _formatAddress(address),
    ].where((text) => text.isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          name.isEmpty ? l10n.noName : name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _Section(
          title: l10n.phones,
          values: [for (final phone in contact.phones) phone.number],
          emptyText: l10n.noPhones,
        ),
        _Section(
          title: l10n.emails,
          values: [for (final email in contact.emails) email.address],
          emptyText: l10n.noEmails,
        ),
        _Section(title: l10n.organization, values: organizations),
        _Section(title: l10n.addresses, values: addresses),
        _Section(
          title: l10n.events,
          values: [for (final event in contact.events) _formatEvent(event)],
        ),
        _Section(
          title: l10n.websites,
          values: [for (final website in contact.websites) website.url],
        ),
        _Section(
          title: l10n.notes,
          values: [
            for (final note in contact.notes)
              if (note.note.trim().isNotEmpty) note.note.trim(),
          ],
        ),
      ],
    );
  }

  String _formatAddress(Address address) {
    final formatted = address.formatted?.trim();
    if (formatted != null && formatted.isNotEmpty) return formatted;
    return [
      address.street,
      address.city,
      address.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }

  String _formatEvent(Event event) {
    final day = event.day.toString().padLeft(2, '0');
    final month = event.month.toString().padLeft(2, '0');
    final year = event.year;
    return year == null ? '$day.$month' : '$day.$month.$year';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> values;
  final String? emptyText;

  const _Section({required this.title, required this.values, this.emptyText});

  @override
  Widget build(BuildContext context) {
    final empty = emptyText;
    if (values.isEmpty && empty == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 4),
          if (values.isEmpty)
            Text(empty!)
          else
            for (final value in values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
        ],
      ),
    );
  }
}
