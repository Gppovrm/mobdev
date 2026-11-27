import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/drafts_storage.dart';
import 'data/session_storage.dart';
import 'l10n/app_localizations.dart';
import 'state/home_store.dart';
import 'state/session_store.dart';
import 'ui/home_page.dart';
import 'ui/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final drafts = PrefsDraftsStorage();
  final session = SessionStore(api, const SecureSessionStorage(), drafts)
    ..restore();
  runApp(ChatApp(api: api, drafts: drafts, session: session));
}

class ChatApp extends StatelessWidget {
  final ApiClient api;
  final DraftsStorage drafts;
  final SessionStore session;

  const ChatApp({
    super.key,
    required this.api,
    required this.drafts,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: drafts),
        ChangeNotifierProvider.value(value: session),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final current = store.session;
    if (store.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (current == null) return const LoginPage();
    return ChangeNotifierProvider(
      key: ValueKey(current.token),
      create: (context) => HomeStore(
        api: context.read<ApiClient>(),
        drafts: context.read<DraftsStorage>(),
        session: current,
      ),
      child: const HomePage(),
    );
  }
}
