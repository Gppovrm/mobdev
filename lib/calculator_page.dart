import 'package:flutter/material.dart';

import 'calculator_engine.dart';
import 'history_page.dart';

enum KeyKind { digit, operator, function, memory, equals }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const _historyLimit = 10;

  static const _portraitKeys = [
    [('MC', 1), ('MR', 1), ('M−', 1), ('M+', 1)],
    [('C', 1), ('(', 1), (')', 1), ('⌫', 1)],
    [('7', 1), ('8', 1), ('9', 1), ('÷', 1)],
    [('4', 1), ('5', 1), ('6', 1), ('×', 1)],
    [('1', 1), ('2', 1), ('3', 1), ('−', 1)],
    [('±', 1), ('0', 1), ('.', 1), ('+', 1)],
    [('%', 1), ('=', 3)],
  ];

  static const _landscapeKeys = [
    [('MC', 1), ('(', 1), (')', 1), ('7', 1), ('8', 1), ('9', 1), ('÷', 1)],
    [('MR', 1), ('C', 1), ('⌫', 1), ('4', 1), ('5', 1), ('6', 1), ('×', 1)],
    [('M−', 1), ('%', 1), ('±', 1), ('1', 1), ('2', 1), ('3', 1), ('−', 1)],
    [('M+', 1), ('0', 2), ('.', 1), ('=', 2), ('+', 1)],
  ];

  final _engine = CalculatorEngine();
  final List<HistoryEntry> _history = [];
  String _expression = '';
  String _lastExpression = '';
  String? _result;
  String? _error;
  double? _memory;
  bool _justCalculated = false;

  KeyKind _kindOf(String label) {
    if ('0123456789.'.contains(label)) return KeyKind.digit;
    if (CalculatorEngine.operators.contains(label)) return KeyKind.operator;
    if (label == '=') return KeyKind.equals;
    if (label.startsWith('M')) return KeyKind.memory;
    return KeyKind.function;
  }

  void _press(String label) {
    switch (label) {
      case 'C':
        _clear();
      case '⌫':
        _backspace();
      case '±':
        _toggleSign();
      case '=':
        _calculate();
      case 'M+':
        _changeMemory(1);
      case 'M−':
        _changeMemory(-1);
      case 'MR':
        _recallMemory();
      case 'MC':
        _clearMemory();
      default:
        _input(label);
    }
  }

  void _input(String symbol) {
    setState(() {
      final startsNew = _kindOf(symbol) == KeyKind.digit || symbol == '(';
      if (_justCalculated && startsNew) {
        _expression = '';
      }
      _expression += symbol;
      _error = null;
      _justCalculated = false;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _lastExpression = '';
      _result = null;
      _error = null;
      _justCalculated = false;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _error = null;
      _justCalculated = false;
    });
  }

  void _toggleSign() {
    setState(() {
      _expression = CalculatorEngine.toggleSign(_expression);
      _error = null;
      _justCalculated = false;
    });
  }

  void _calculate() {
    final result = _engine.evaluate(_expression);
    setState(() {
      switch (result) {
        case EvalSuccess(value: final value):
          final text = CalculatorEngine.format(value);
          _history.insert(0, (expression: _expression, result: text));
          if (_history.length > _historyLimit) {
            _history.removeLast();
          }
          _lastExpression = _expression;
          _result = text;
          _expression = text;
          _error = null;
          _justCalculated = true;
        case EvalFailure(message: final message):
          _error = message;
      }
    });
  }

  void _changeMemory(int sign) {
    final result = _engine.evaluate(_expression);
    setState(() {
      switch (result) {
        case EvalSuccess(value: final value):
          _memory = (_memory ?? 0) + sign * value;
          _error = null;
        case EvalFailure(message: final message):
          _error = message;
      }
    });
  }

  void _recallMemory() {
    final memory = _memory;
    if (memory == null) return;
    setState(() {
      final text = CalculatorEngine.formatForInput(memory);
      final last = _expression.isEmpty
          ? ''
          : _expression[_expression.length - 1];
      final canAppend =
          _expression.isEmpty ||
          CalculatorEngine.operators.contains(last) ||
          last == '(';
      _expression = canAppend && !_justCalculated ? _expression + text : text;
      _error = null;
      _justCalculated = false;
    });
  }

  void _clearMemory() {
    setState(() => _memory = null);
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) =>
            HistoryPage(history: List<HistoryEntry>.unmodifiable(_history)),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _expression = selected;
      _error = null;
      _justCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        toolbarHeight: landscape ? 40 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История',
            onPressed: _openHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: landscape ? 2 : 3, child: _buildDisplay(landscape)),
            Expanded(
              flex: landscape ? 4 : 7,
              child: _buildKeypad(landscape ? _landscapeKeys : _portraitKeys),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(bool landscape) {
    final colors = Theme.of(context).colorScheme;
    final memory = _memory;
    final error = _error;
    final result = _result;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: landscape ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                memory == null ? '' : 'M = ${CalculatorEngine.format(memory)}',
                style: TextStyle(color: colors.primary, fontSize: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  error ?? (result == null ? '' : '$_lastExpression = $result'),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: landscape ? 16 : 20,
                    color: error == null
                        ? colors.onSurfaceVariant
                        : colors.error,
                  ),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _expression.isEmpty ? '0' : _expression,
              style: TextStyle(fontSize: landscape ? 36 : 56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(List<List<(String, int)>> rows) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (label, flex) in row)
                    Expanded(flex: flex, child: _buildKey(label)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (_kindOf(label)) {
      KeyKind.digit => (colors.surfaceContainerHighest, colors.onSurface),
      KeyKind.operator => (Colors.orange, Colors.white),
      KeyKind.equals => (Colors.deepOrange, Colors.white),
      KeyKind.memory => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      KeyKind.function => (colors.surfaceContainerHigh, colors.primary),
    };
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _press(label),
        child: Text(label, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
