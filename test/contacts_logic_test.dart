import 'package:contacts/contact_item.dart';
import 'package:contacts/contacts_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const contacts = [
    ContactItem(id: '1', name: 'Мария Иванова', phone: '+7 900 000-00-01'),
    ContactItem(id: '2', name: 'Алексей Петров', hasEmail: true),
    ContactItem(id: '3', name: 'борис', phone: '+7 900 000-00-03'),
    ContactItem(id: '4', name: 'Anna Smith', hasEmail: true),
  ];

  List<String> names(List<ContactItem> items) => [
    for (final item in items) item.name,
  ];

  test('сортировка по имени в прямом порядке', () {
    final result = filterAndSort(contacts, query: '', ascending: true);
    expect(names(result), [
      'Anna Smith',
      'Алексей Петров',
      'борис',
      'Мария Иванова',
    ]);
  });

  test('сортировка по имени в обратном порядке', () {
    final result = filterAndSort(contacts, query: '', ascending: false);
    expect(names(result), [
      'Мария Иванова',
      'борис',
      'Алексей Петров',
      'Anna Smith',
    ]);
  });

  test('поиск по части имени без учёта регистра', () {
    expect(names(filterAndSort(contacts, query: 'БОР', ascending: true)), [
      'борис',
    ]);
    expect(names(filterAndSort(contacts, query: ' ова ', ascending: true)), [
      'Мария Иванова',
    ]);
  });

  test('пустой результат поиска', () {
    expect(filterAndSort(contacts, query: 'zzz', ascending: true), isEmpty);
  });

  test('исходный список не меняется', () {
    final source = List<ContactItem>.of(contacts);
    filterAndSort(source, query: '', ascending: false);
    expect(names(source), names(contacts));
  });
}
