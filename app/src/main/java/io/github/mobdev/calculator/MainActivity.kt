package io.github.mobdev.calculator

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import io.github.mobdev.R
import java.text.DecimalFormat

// простой калькулятор
// считает double, сохраняет при повороте, не падает
class MainActivity : AppCompatActivity() {

    private lateinit var tvResult: TextView

    private var currentNumber = ""      // то что сейчас на экране
    private var firstNumber = 0.0       // первое число для операции
    private var operator = ""           // + - × ÷
    private var isOperatorPressed = false // нажали оператор?

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        tvResult = findViewById(R.id.tvResult)

        if (savedInstanceState != null) {
            currentNumber = savedInstanceState.getString("currentNumber", "")
            firstNumber = savedInstanceState.getDouble("firstNumber", 0.0)
            operator = savedInstanceState.getString("operator", "")
            isOperatorPressed = savedInstanceState.getBoolean("isOperatorPressed", false)
            tvResult.text = currentNumber.ifEmpty { "0" }
        } else {
            tvResult.text = "0"
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("currentNumber", currentNumber)
        outState.putDouble("firstNumber", firstNumber)
        outState.putString("operator", operator)
        outState.putBoolean("isOperatorPressed", isOperatorPressed)
    }

    // цифры от 0 до 9
    fun onNumberClick(view: View) {
        val number = (view as Button).text.toString()

        if (isOperatorPressed) {
            currentNumber = ""
            isOperatorPressed = false
        }

        if (currentNumber.length < 15) {
            currentNumber += number
            tvResult.text = currentNumber
        }
    }

    // + - × ÷
    fun onOperatorClick(view: View) {
        val newOperator = (view as Button).text.toString()

        if (currentNumber.isNotEmpty() && !isOperatorPressed) {
            if (operator.isNotEmpty()) calculate()
            firstNumber = currentNumber.toDouble()
            operator = newOperator
            isOperatorPressed = true
        } else if (operator.isNotEmpty() && isOperatorPressed) {
            operator = newOperator
        }
    }

    // равно
    fun onEqualsClick(view: View) {
        if (currentNumber.isNotEmpty() && operator.isNotEmpty()) {
            val secondNumber = currentNumber.toDouble()
            val result = when (operator) {
                "+" -> firstNumber + secondNumber
                "-" -> firstNumber - secondNumber
                "×" -> firstNumber * secondNumber
                "÷" -> if (secondNumber != 0.0) firstNumber / secondNumber else null
                else -> null
            }

            if (result != null) {
                formatAndDisplayResult(result)
                operator = ""
                isOperatorPressed = true
            } else {
                tvResult.text = "Error"
                currentNumber = ""
                firstNumber = 0.0
                operator = ""
                isOperatorPressed = true
            }
        }
    }

    // очистить всё
    fun onClearClick(view: View) {
        currentNumber = ""
        firstNumber = 0.0
        operator = ""
        isOperatorPressed = false
        tvResult.text = "0"
    }

    // точка для дробных чисел
    fun onDecimalClick(view: View) {
        if (!currentNumber.contains(".")) {
            currentNumber = if (currentNumber.isEmpty()) "0." else "$currentNumber."
            tvResult.text = currentNumber
        }
    }

    // вычисления для цепочки
    private fun calculate() {
        if (currentNumber.isEmpty()) return

        val secondNumber = currentNumber.toDouble()
        val result = try {
            when (operator) {
                "+" -> firstNumber + secondNumber
                "-" -> firstNumber - secondNumber
                "×" -> firstNumber * secondNumber
                "÷" -> if (secondNumber != 0.0) firstNumber / secondNumber else null
                else -> null
            }
        } catch (e: Exception) {
            null
        }

        if (result != null) {
            formatAndDisplayResult(result)
        } else {
            tvResult.text = "Error"
            currentNumber = ""
            firstNumber = 0.0
            operator = ""
            isOperatorPressed = true
        }
    }

    // форматируем результат (5.0 → 5, 3.14 → 3.14)
    private fun formatAndDisplayResult(result: Double) {
        val formattedResult = if (result == result.toLong().toDouble()) {
            result.toLong().toString()
        } else {
            DecimalFormat("#.########").format(result)
        }
        tvResult.text = formattedResult
        currentNumber = formattedResult
        firstNumber = result
    }
}