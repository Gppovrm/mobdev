import 'package:contacts/contact_item.dart';
import 'package:contacts/contacts_page.dart';
import 'package:contacts/contacts_repository.dart';
import 'package:contacts/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRepository implements ContactsRepository {
  AccessStatus checkResult;
  AccessStatus requestResult;
  List<ContactItem> contacts;
  bool failLoad;
  int loadCalls = 0;
  int requestCalls = 0;
  int settingsCalls = 0;

  FakeRepository({
    this.checkResult = AccessStatus.granted,
    this.requestResult = AccessStatus.granted,
    this.contacts = const [],
    this.failLoad = false,
  });

  @override
  Future<AccessStatus> checkAccess() async => checkResult;

  @override
  Future<AccessStatus> requestAccess() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<void> openSettings() async => settingsCalls++;

  @override
  Future<List<ContactItem>> loadContacts() async {
    loadCalls++;
    if (failLoad) throw Exception('read error');
    return contacts;
  }

  @override
  Future<Contact?> loadDetails(String id) async =>
      Contact(id: id, displayName: 'Мария Иванова');
}

Widget app(ContactsRepository repository) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: ContactsPage(repository: repository),
);

void main() {
  const people = [
    ContactItem(id: '1', name: 'Мария Иванова', phone: '+7 900 000-00-01'),
    ContactItem(id: '2', name: 'Алексей Петров', hasEmail: true),
  ];

  testWidgets('показывает список, телефон и счётчик', (tester) async {
    await tester.pumpWidget(app(FakeRepository(contacts: people)));
    await tester.pumpAndSettle();
    expect(find.text('Мария Иванова'), findsOneWidget);
    expect(find.text('+7 900 000-00-01'), findsOneWidget);
    expect(find.text('Нет телефона'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.text('Найдено: 2'), findsOneWidget);
  });

  testWidgets('поиск не перечитывает адресную книгу', (tester) async {
    final repository = FakeRepository(contacts: people);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'мар');
    await tester.pump();
    expect(find.text('Найдено: 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(repository.loadCalls, 1);
  });

  testWidgets('возврат с экрана деталей не загружает контакты снова', (
    tester,
  ) async {
    final repository = FakeRepository(contacts: people);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мария Иванова'));
    await tester.pumpAndSettle();
    expect(find.text('Телефонов нет'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Мария Иванова'), findsOneWidget);
    expect(repository.loadCalls, 1);
  });

  testWidgets('пустая адресная книга отличается от отказа', (tester) async {
    await tester.pumpWidget(app(FakeRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Адресная книга пуста'), findsOneWidget);
    expect(find.text('Нет доступа к контактам'), findsNothing);
  });

  testWidgets('отказ показывает кнопку повторного запроса', (tester) async {
    final repository = FakeRepository(
      checkResult: AccessStatus.denied,
      requestResult: AccessStatus.denied,
      contacts: people,
    );
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Нет доступа к контактам'), findsOneWidget);
    repository.requestResult = AccessStatus.granted;
    await tester.tap(find.text('Запросить доступ'));
    await tester.pumpAndSettle();
    expect(find.text('Мария Иванова'), findsOneWidget);
    expect(repository.requestCalls, 2);
  });

  testWidgets('если запрос недоступен, предлагает настройки', (tester) async {
    final repository = FakeRepository(
      checkResult: AccessStatus.permanentlyDenied,
    );
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть настройки'));
    await tester.pumpAndSettle();
    expect(repository.settingsCalls, 1);
  });

  testWidgets('после возврата из настроек проверяет разрешение', (
    tester,
  ) async {
    final repository = FakeRepository(
      checkResult: AccessStatus.permanentlyDenied,
      contacts: people,
    );
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    repository.checkResult = AccessStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Мария Иванова'), findsOneWidget);
  });

  testWidgets('ошибка чтения показывает состояние ошибки', (tester) async {
    await tester.pumpWidget(app(FakeRepository(failLoad: true)));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось прочитать контакты'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
