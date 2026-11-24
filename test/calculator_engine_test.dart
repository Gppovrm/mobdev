import 'package:calculator/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = CalculatorEngine();

  double valueOf(String expression) {
    final result = engine.evaluate(expression);
    return switch (result) {
      EvalSuccess(value: final value) => value,
      EvalFailure(message: final message) => fail('$expression: $message'),
    };
  }

  String errorOf(String expression) {
    final result = engine.evaluate(expression);
    return switch (result) {
      EvalSuccess(value: final value) => fail('$expression = $value'),
      EvalFailure(message: final message) => message,
    };
  }

  group('приоритет и скобки', () {
    test('умножение раньше сложения', () {
      expect(valueOf('12+5×3'), 27);
    });

    test('скобки меняют порядок', () {
      expect(valueOf('(12+5)×3'), 51);
    });

    test('примеры истории из задания', () {
      expect(valueOf('20÷4+7'), 12);
      expect(valueOf('15.5×2'), 31);
    });

    test('вычитание и деление слева направо', () {
      expect(valueOf('10−4−3'), 3);
      expect(valueOf('100÷10÷5'), 2);
    });

    test('вложенные скобки', () {
      expect(valueOf('2×((3+4)×(5−1))'), 56);
    });

    test('вещественные числа', () {
      expect(valueOf('0.1+0.2'), closeTo(0.3, 1e-12));
      expect(valueOf('.5×4'), 2);
    });

    test('унарный минус', () {
      expect(valueOf('−5+3'), -2);
      expect(valueOf('5−(−3)'), 8);
      expect(valueOf('2×(−3)'), -6);
    });

    test('процент', () {
      expect(valueOf('50%'), 0.5);
      expect(valueOf('200×10%'), 20);
    });
  });

  group('ошибки', () {
    test('деление на ноль', () {
      expect(errorOf('5÷0'), CalculatorEngine.errorDivisionByZero);
      expect(errorOf('5÷(2−2)'), CalculatorEngine.errorDivisionByZero);
    });

    test('неправильные скобки', () {
      expect(errorOf('(2+3'), CalculatorEngine.errorBrackets);
      expect(errorOf('2+3)'), CalculatorEngine.errorBrackets);
      expect(errorOf(')2+3('), CalculatorEngine.errorBrackets);
      expect(errorOf('()'), CalculatorEngine.errorBrackets);
    });

    test('два оператора подряд', () {
      expect(errorOf('2+×3'), CalculatorEngine.errorTwoOperators);
      expect(errorOf('2−−3'), CalculatorEngine.errorTwoOperators);
    });

    test('несколько точек в числе', () {
      expect(errorOf('1.2.3+4'), CalculatorEngine.errorManyDots);
    });

    test('пустое выражение', () {
      expect(errorOf(''), CalculatorEngine.errorEmpty);
      expect(errorOf('   '), CalculatorEngine.errorEmpty);
    });

    test('выражение заканчивается оператором', () {
      expect(errorOf('2+3×'), CalculatorEngine.errorEndsWithOperator);
    });

    test('прочие некорректные выражения не падают', () {
      expect(errorOf('×3'), CalculatorEngine.errorStartsWithOperator);
      expect(errorOf('2(3)'), CalculatorEngine.errorMissingOperator);
      expect(errorOf('%5'), CalculatorEngine.errorPercent);
      expect(errorOf('.'), CalculatorEngine.errorNumber);
      expect(errorOf('(−)'), CalculatorEngine.errorInvalid);
    });
  });

  group('форматирование', () {
    test('целые без дробной части', () {
      expect(CalculatorEngine.format(31), '31');
      expect(CalculatorEngine.format(-2), '−2');
    });

    test('дробные без лишних нулей', () {
      expect(CalculatorEngine.format(0.1 + 0.2), '0.3');
      expect(CalculatorEngine.format(2.5), '2.5');
    });

    test('отрицательное значение для ввода в скобках', () {
      expect(CalculatorEngine.formatForInput(-5), '(−5)');
      expect(CalculatorEngine.formatForInput(5), '5');
    });
  });

  group('смена знака', () {
    test('оборачивает последнее число', () {
      expect(CalculatorEngine.toggleSign('5−3'), '5−(−3)');
      expect(CalculatorEngine.toggleSign('12'), '(−12)');
    });

    test('повторное нажатие возвращает знак', () {
      expect(CalculatorEngine.toggleSign('5−(−3)'), '5−3');
    });

    test('без числа в конце ничего не меняет', () {
      expect(CalculatorEngine.toggleSign('5+'), '5+');
      expect(CalculatorEngine.toggleSign(''), '');
    });
  });
}
