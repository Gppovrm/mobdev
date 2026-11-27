import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/home_store.dart';
import '../state/session_store.dart';
import 'channels_panel.dart';
import 'chat_view.dart';
import 'image_viewer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final store = context.read<HomeStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) => store.loadChannels());
  }

  void _onBack(HomeStore store) {
    if (store.openImage != null) {
      store.closeImage();
    } else if (store.selected != null) {
      store.closeChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<HomeStore>();
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final selected = store.selected;
    final image = store.openImage;

    final Widget page;
    if (image != null) {
      page = ImageViewer(url: store.imageUrl(image), onClose: store.closeImage);
    } else if (landscape) {
      page = Scaffold(
        appBar: _channelsAppBar(l10n),
        body: SafeArea(
          child: Row(
            children: [
              const Expanded(flex: 2, child: ChannelsPanel()),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: selected == null
                    ? Center(child: Text(l10n.selectChat))
                    : Column(
                        children: [
                          ListTile(
                            title: Text(
                              selected,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RefreshButton(channel: selected),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: l10n.closeChat,
                                  onPressed: store.closeChat,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ChatView(
                              key: ValueKey(selected),
                              chat: store.chatFor(selected),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    } else if (selected != null) {
      page = Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: store.closeChat),
          title: Text(selected, overflow: TextOverflow.ellipsis),
          actions: [_RefreshButton(channel: selected)],
        ),
        body: SafeArea(
          child: ChatView(
            key: ValueKey(selected),
            chat: store.chatFor(selected),
          ),
        ),
      );
    } else {
      page = Scaffold(
        appBar: _channelsAppBar(l10n),
        body: const SafeArea(child: ChannelsPanel()),
      );
    }

    return PopScope(
      canPop: image == null && selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack(store);
      },
      child: page,
    );
  }

  AppBar _channelsAppBar(AppLocalizations l10n) => AppBar(
    title: Text(l10n.channelsTitle),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: l10n.logout,
        onPressed: () => context.read<SessionStore>().logout(),
      ),
    ],
  );
}

class _RefreshButton extends StatelessWidget {
  final String channel;

  const _RefreshButton({required this.channel});

  @override
  Widget build(BuildContext context) {
    final chat = context.read<HomeStore>().chatFor(channel);
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) => IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: AppLocalizations.of(context).refresh,
        onPressed: chat.refreshing || chat.loadingInitial ? null : chat.refresh,
      ),
    );
  }
}
