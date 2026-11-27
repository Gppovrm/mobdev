import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/home_store.dart';
import 'error_text.dart';

class ChannelsPanel extends StatelessWidget {
  const ChannelsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<HomeStore>();
    final channels = store.channels;
    final error = store.error;

    if (!store.loadedOnce) {
      if (store.loading || error == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return _CenteredMessage(
        text: errorText(l10n, error),
        buttonLabel: l10n.retry,
        onPressed: () => store.loadChannels(force: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => store.loadChannels(force: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (error != null)
            SliverToBoxAdapter(
              child: _ErrorBanner(
                text: errorText(l10n, error),
                buttonLabel: l10n.retry,
                onPressed: () => store.loadChannels(force: true),
              ),
            ),
          if (channels.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _CenteredMessage(
                text: l10n.channelsEmpty,
                buttonLabel: l10n.refresh,
                onPressed: () => store.loadChannels(force: true),
              ),
            )
          else
            SliverList.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text(channel, overflow: TextOverflow.ellipsis),
                  selected: channel == store.selected,
                  onTap: () => store.select(channel),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _CenteredMessage({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ErrorBanner({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
