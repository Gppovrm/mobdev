import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/chat_store.dart';
import '../state/home_store.dart';
import 'error_text.dart';
import 'message_bubble.dart';

class ChatView extends StatefulWidget {
  final ChatStore chat;

  const ChatView({super.key, required this.chat});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _textController = TextEditingController();
  late final ScrollController _scrollController;
  bool _draftApplied = false;

  ChatStore get _chat => widget.chat;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _chat.scrollOffset,
    );
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _chat.addListener(_onChatChanged);
    _applyDraft();
    _chat.start();
  }

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _applyDraft() {
    if (_draftApplied || !_chat.ready) return;
    _draftApplied = true;
    _textController.text = _chat.draft;
  }

  void _onChatChanged() {
    if (!_draftApplied && _chat.ready) {
      _applyDraft();
    }
  }

  void _onTextChanged() {
    if (_draftApplied) _chat.updateDraft(_textController.text);
    setState(() {});
  }

  void _onScroll() {
    final position = _scrollController.position;
    _chat.scrollOffset = position.pixels;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _chat.loadOlder();
    }
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _chat.send(text);
  }

  Future<void> _retry(OutgoingMessage item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.retryDialogTitle),
        content: Text(l10n.retryDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sendAgain),
          ),
        ],
      ),
    );
    if (confirmed == true) _chat.retry(item.localId);
  }

  void _returnToEditor(OutgoingMessage item) {
    final text = _chat.takeBack(item.localId);
    if (text == null) return;
    final current = _textController.text;
    _textController.text = current.trim().isEmpty ? text : '$current\n$text';
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) => Column(
        children: [
          if (_chat.refreshError != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                dense: true,
                title: Text(
                  '${l10n.refreshError}: ${errorText(l10n, _chat.refreshError!)}',
                ),
                trailing: TextButton(
                  onPressed: _chat.refresh,
                  child: Text(l10n.retry),
                ),
              ),
            ),
          Expanded(child: _buildMessages(l10n)),
          const Divider(height: 1),
          _buildComposer(l10n),
        ],
      ),
    );
  }

  Widget _buildMessages(AppLocalizations l10n) {
    final messages = _chat.messages;
    final outgoing = _chat.outgoing.reversed.toList();
    final initialError = _chat.initialError;
    if (messages.isEmpty && outgoing.isEmpty) {
      if (initialError != null) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorText(l10n, initialError),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _chat.loadInitial,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        );
      }
      if (!_chat.loadedOnce) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(child: Text(l10n.messagesEmpty));
    }
    final home = context.read<HomeStore>();
    final me = home.session.name;
    final count = outgoing.length + messages.length + 1;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index < outgoing.length) {
          final item = outgoing[index];
          return OutgoingBubble(
            key: ValueKey(item.localId),
            item: item,
            onRetry: () => _retry(item),
            onReturn: () => _returnToEditor(item),
          );
        }
        final messageIndex = index - outgoing.length;
        if (messageIndex < messages.length) {
          final message = messages[messageIndex];
          return MessageBubble(
            key: ValueKey(message.id),
            message: message,
            mine: message.from == me,
            thumbUrl: home.thumbUrl,
            onImageTap: home.showImage,
          );
        }
        return _buildHistoryEdge(l10n);
      },
    );
  }

  Widget _buildHistoryEdge(AppLocalizations l10n) {
    final Widget child;
    final olderError = _chat.olderError;
    if (_chat.loadingOlder) {
      child = const CircularProgressIndicator();
    } else if (olderError != null) {
      child = Column(
        children: [
          Text(
            '${l10n.loadOlderError}: ${errorText(l10n, olderError)}',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _chat.loadOlder, child: Text(l10n.retry)),
        ],
      );
    } else if (_chat.hasMore && _chat.loadedOnce) {
      child = TextButton(
        onPressed: _chat.loadOlder,
        child: Text(l10n.loadOlder),
      );
    } else {
      child = Text(
        l10n.historyStart,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(child: child),
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    final canSend = _draftApplied && _textController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: _draftApplied,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.messageField,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: l10n.send,
            onPressed: canSend ? _send : null,
          ),
        ],
      ),
    );
  }
}
