sealed class EvalResult {
  const EvalResult();
}

final class EvalSuccess extends EvalResult {
  final double value;
  const EvalSuccess(this.value);
}

final class EvalFailure extends EvalResult {
  final String message;
  const EvalFailure(this.message);
}

class CalculationException implements Exception {
  final String message;
  const CalculationException(this.message);
}

class CalculatorEngine {
  static const operators = {'+', '−', '×', '÷'};

  static const errorEmpty = 'Пустое выражение';
  static const errorDivisionByZero = 'Деление на ноль';
  static const errorBrackets = 'Неправильная расстановка скобок';
  static const errorTwoOperators = 'Два оператора подряд';
  static const errorManyDots = 'Несколько точек в одном числе';
  static const errorEndsWithOperator = 'Выражение заканчивается оператором';
  static const errorStartsWithOperator = 'Выражение начинается с оператора';
  static const errorMissingOperator = 'Пропущен оператор';
  static const errorPercent = 'Неверное использование %';
  static const errorNumber = 'Некорректное число';
  static const errorOverflow = 'Слишком большое число';
  static const errorInvalid = 'Некорректное выражение';

  EvalResult evaluate(String expression) {
    try {
      final tokens = _tokenize(expression);
      _validate(tokens);
      final parser = _Parser(tokens);
      final value = parser.parse();
      if (!value.isFinite) {
        throw const CalculationException(errorOverflow);
      }
      return EvalSuccess(value == 0 ? 0 : value);
    } on CalculationException catch (error) {
      return EvalFailure(error.message);
    }
  }

  List<Object> _tokenize(String expression) {
    final source = expression
        .replaceAll(' ', '')
        .replaceAll('-', '−')
        .replaceAll('*', '×')
        .replaceAll('/', '÷');
    if (source.isEmpty) {
      throw const CalculationException(errorEmpty);
    }
    final tokens = <Object>[];
    var i = 0;
    while (i < source.length) {
      final char = source[i];
      if (_isDigitOrDot(char)) {
        final start = i;
        while (i < source.length && _isDigitOrDot(source[i])) {
          i++;
        }
        final text = source.substring(start, i);
        if ('.'.allMatches(text).length > 1) {
          throw const CalculationException(errorManyDots);
        }
        final number = double.tryParse(text);
        if (number == null) {
          throw const CalculationException(errorNumber);
        }
        tokens.add(number);
        continue;
      }
      if (operators.contains(char) ||
          char == '(' ||
          char == ')' ||
          char == '%') {
        tokens.add(char);
        i++;
        continue;
      }
      throw const CalculationException(errorInvalid);
    }
    return tokens;
  }

  bool _isDigitOrDot(String char) => '0123456789.'.contains(char);

  void _validate(List<Object> tokens) {
    var depth = 0;
    Object? previous;
    for (final token in tokens) {
      final isValue = token is double || token == ')' || token == '%';
      final previousIsValue =
          previous is double || previous == ')' || previous == '%';

      if (token is String && operators.contains(token)) {
        final isUnaryMinus =
            token == '−' && (previous == null || previous == '(');
        if (!isUnaryMinus) {
          if (previous == null) {
            throw const CalculationException(errorStartsWithOperator);
          }
          if (previous is String && operators.contains(previous)) {
            throw const CalculationException(errorTwoOperators);
          }
          if (previous == '(') {
            throw const CalculationException(errorInvalid);
          }
        }
      } else if (token == '%') {
        if (!previousIsValue) {
          throw const CalculationException(errorPercent);
        }
      } else if (token == '(') {
        if (previousIsValue) {
          throw const CalculationException(errorMissingOperator);
        }
        depth++;
      } else if (token == ')') {
        if (depth == 0 || previous == '(') {
          throw const CalculationException(errorBrackets);
        }
        depth--;
      } else if (isValue && previousIsValue) {
        throw const CalculationException(errorMissingOperator);
      }
      previous = token;
    }
    if (previous is String && operators.contains(previous)) {
      throw const CalculationException(errorEndsWithOperator);
    }
    if (depth != 0) {
      throw const CalculationException(errorBrackets);
    }
  }

  static String format(double value) {
    final text = value.abs().toStringAsPrecision(12);
    final String digits;
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      digits = value.abs().toInt().toString();
    } else if (text.contains('e')) {
      final parts = text.split('e');
      digits = '${_trimZeros(parts[0])}e${parts[1]}';
    } else {
      digits = _trimZeros(text);
    }
    return value < 0 ? '−$digits' : digits;
  }

  static String _trimZeros(String text) {
    if (!text.contains('.')) return text;
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  static String formatForInput(double value) {
    final text = format(value);
    return value < 0 ? '(−${text.substring(1)})' : text;
  }

  static String toggleSign(String expression) {
    final negative = RegExp(r'\(−([\d.]+%*)\)$').firstMatch(expression);
    if (negative != null) {
      return expression.replaceRange(
        negative.start,
        negative.end,
        negative.group(1)!,
      );
    }
    final positive = RegExp(r'[\d.]+%*$').firstMatch(expression);
    if (positive != null) {
      return expression.replaceRange(
        positive.start,
        positive.end,
        '(−${positive.group(0)})',
      );
    }
    return expression;
  }
}

class _Parser {
  final List<Object> tokens;
  var _position = 0;

  _Parser(this.tokens);

  double parse() {
    final value = _expression();
    if (_position != tokens.length) {
      throw const CalculationException(CalculatorEngine.errorInvalid);
    }
    return value;
  }

  Object? get _current => _position < tokens.length ? tokens[_position] : null;

  double _expression() {
    var value = _term();
    while (_current == '+' || _current == '−') {
      final operator = _current;
      _position++;
      final right = _term();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (_current == '×' || _current == '÷') {
      final operator = _current;
      _position++;
      final right = _unary();
      if (operator == '×') {
        value *= right;
      } else {
        if (right == 0) {
          throw const CalculationException(
            CalculatorEngine.errorDivisionByZero,
          );
        }
        value /= right;
      }
    }
    return value;
  }

  double _unary() {
    if (_current == '−') {
      _position++;
      return -_unary();
    }
    return _postfix();
  }

  double _postfix() {
    var value = _primary();
    while (_current == '%') {
      _position++;
      value /= 100;
    }
    return value;
  }

  double _primary() {
    final token = _current;
    switch (token) {
      case double number:
        _position++;
        return number;
      case '(':
        _position++;
        final value = _expression();
        if (_current != ')') {
          throw const CalculationException(CalculatorEngine.errorBrackets);
        }
        _position++;
        return value;
      default:
        throw const CalculationException(CalculatorEngine.errorInvalid);
    }
  }
}
