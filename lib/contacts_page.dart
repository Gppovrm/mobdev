import 'package:flutter/material.dart';

import 'contact_details_page.dart';
import 'contact_item.dart';
import 'contacts_logic.dart';
import 'contacts_repository.dart';
import 'contacts_state.dart';
import 'l10n/app_localizations.dart';

class ContactsPage extends StatefulWidget {
  final ContactsRepository repository;

  const ContactsPage({super.key, required this.repository});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  ContactsState _state = const ContactsLoading();
  bool _ascending = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() => setState(() {}));
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_requesting) {
      _recheckAccess();
    }
  }

  Future<void> _start() async {
    setState(() => _state = const ContactsLoading());
    try {
      var status = await widget.repository.checkAccess();
      if (status == AccessStatus.denied) {
        status = await _request();
      }
      await _applyStatus(status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const ContactsFailed());
    }
  }

  Future<AccessStatus> _request() async {
    _requesting = true;
    try {
      return await widget.repository.requestAccess();
    } finally {
      _requesting = false;
    }
  }

  Future<void> _applyStatus(AccessStatus status) async {
    if (!mounted) return;
    if (status == AccessStatus.granted) {
      await _load();
    } else {
      setState(() {
        _state = ContactsNoAccess(
          needsSettings: status == AccessStatus.permanentlyDenied,
        );
      });
    }
  }

  Future<void> _load() async {
    setState(() => _state = const ContactsLoading());
    try {
      final contacts = await widget.repository.loadContacts();
      if (!mounted) return;
      setState(() => _state = ContactsLoaded(contacts));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const ContactsFailed());
    }
  }

  Future<void> _recheckAccess() async {
    final AccessStatus status;
    try {
      status = await widget.repository.checkAccess();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final current = _state;
    if (status == AccessStatus.granted && current is ContactsNoAccess) {
      await _load();
    } else if (status != AccessStatus.granted && current is! ContactsNoAccess) {
      setState(() {
        _state = ContactsNoAccess(
          needsSettings: status == AccessStatus.permanentlyDenied,
        );
      });
    }
  }

  Future<void> _onAccessPressed(bool needsSettings) async {
    if (needsSettings) {
      await widget.repository.openSettings();
      return;
    }
    try {
      await _applyStatus(await _request());
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const ContactsFailed());
    }
  }

  void _openDetails(ContactItem contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ContactDetailsPage(repository: widget.repository, contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (state is ContactsLoaded && state.contacts.isNotEmpty)
            IconButton(
              icon: Icon(
                _ascending ? Icons.arrow_downward : Icons.arrow_upward,
              ),
              tooltip: _ascending ? l10n.sortAscending : l10n.sortDescending,
              onPressed: () => setState(() => _ascending = !_ascending),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          ContactsLoading() => _MessageView(
            icon: const CircularProgressIndicator(),
            title: l10n.loading,
          ),
          ContactsNoAccess(needsSettings: final needsSettings) => _MessageView(
            icon: const Icon(Icons.lock_outline, size: 64),
            title: l10n.noAccessTitle,
            message: needsSettings
                ? l10n.noAccessSettingsMessage
                : l10n.noAccessMessage,
            buttonLabel: needsSettings ? l10n.openSettings : l10n.requestAccess,
            onPressed: () => _onAccessPressed(needsSettings),
          ),
          ContactsFailed() => _MessageView(
            icon: const Icon(Icons.error_outline, size: 64),
            title: l10n.loadError,
            buttonLabel: l10n.retry,
            onPressed: _start,
          ),
          ContactsLoaded(contacts: final contacts) => _buildList(
            l10n,
            contacts,
          ),
        },
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n, List<ContactItem> contacts) {
    if (contacts.isEmpty) {
      return _MessageView(
        icon: const Icon(Icons.person_off_outlined, size: 64),
        title: l10n.emptyAddressBook,
      );
    }
    final visible = filterAndSort(
      contacts,
      query: _searchController.text,
      ascending: _ascending,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchHint,
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear,
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(l10n.foundCount(visible.length)),
        ),
        Expanded(
          child: visible.isEmpty
              ? _MessageView(
                  icon: const Icon(Icons.search_off, size: 64),
                  title: l10n.emptySearch,
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final contact = visible[index];
                    final name = contact.name.isEmpty
                        ? l10n.noName
                        : contact.name;
                    return ListTile(
                      leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                      title: Text(name),
                      subtitle: Text(contact.phone ?? l10n.noPhone),
                      trailing: contact.hasEmail
                          ? Icon(
                              Icons.email_outlined,
                              semanticLabel: l10n.hasEmail,
                            )
                          : null,
                      onTap: () => _openDetails(contact),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _MessageView({
    required this.icon,
    required this.title,
    this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final text = message;
    final label = buttonLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (text != null) ...[
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center),
            ],
            if (label != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
