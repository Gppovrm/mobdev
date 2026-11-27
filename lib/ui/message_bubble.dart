import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../state/chat_store.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool mine;
  final String Function(String link) thumbUrl;
  final void Function(String link) onImageTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.thumbUrl,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final time = DateFormat.Hm().format(message.time);
    final content = message.content;
    return _Bubble(
      mine: mine,
      children: [
        if (!mine)
          Text(
            message.from,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        switch (content) {
          TextContent(text: final text) => SelectableText(text),
          ImageContent(link: final link) => Semantics(
            button: true,
            label: l10n.imageMessage(message.from),
            child: InkWell(
              onTap: () => onImageTap(link),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbUrl(link),
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 80,
                    width: 80,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 80,
                          width: 80,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
          ),
        },
        Text(time, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class OutgoingBubble extends StatelessWidget {
  final OutgoingMessage item;
  final VoidCallback onRetry;
  final VoidCallback onReturn;

  const OutgoingBubble({
    super.key,
    required this.item,
    required this.onRetry,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = switch (item.status) {
      SendStatus.sending => l10n.statusSending,
      SendStatus.sent => l10n.statusSent,
      SendStatus.failed => l10n.statusFailed,
    };
    return _Bubble(
      mine: true,
      children: [
        SelectableText(item.text),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status == SendStatus.sending)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (item.status == SendStatus.failed)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
              ),
            Flexible(
              child: Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: item.status == SendStatus.failed
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (item.status == SendStatus.failed)
          Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: onRetry, child: Text(l10n.retrySend)),
              TextButton(onPressed: onReturn, child: Text(l10n.returnToEditor)),
            ],
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool mine;
  final List<Widget> children;

  const _Bubble({required this.mine, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: children,
          ),
        ),
      ),
    );
  }
}
