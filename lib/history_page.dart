import 'package:flutter/material.dart';

typedef HistoryEntry = ({String expression, String result});

class HistoryPage extends StatelessWidget {
  final List<HistoryEntry> history;

  const HistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: SafeArea(
        child: history.isEmpty
            ? const Center(child: Text('История пуста'))
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return ListTile(
                    title: Text(entry.expression),
                    subtitle: Text('= ${entry.result}'),
                    onTap: () => Navigator.of(context).pop(entry.expression),
                  );
                },
              ),
      ),
    );
  }
}
