package io.github.mobdev.ui.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.mobdev.data.repository.ChatRepository
import kotlinx.coroutines.launch
import javax.inject.Inject

class LoginViewModel @Inject constructor(
    private val repository: ChatRepository
) : ViewModel() {

    private val _loginResult = MutableLiveData<LoginResult>()
    val loginResult: LiveData<LoginResult> = _loginResult

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    fun isLoggedIn(): Boolean = repository.isLoggedIn()

    fun login(username: String, password: String) {
        if (username.isEmpty() || password.isEmpty()) {
            _loginResult.value = LoginResult.Error("Заполните все поля")
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            val result = repository.login(username, password)
            _isLoading.value = false

            result.onSuccess {
                _loginResult.value = LoginResult.Success
            }.onFailure { error ->
                val msg = if (error.message?.contains("401") == true) {
                    "Неверный логин или пароль"
                } else {
                    "Ошибка сети"
                }
                _loginResult.value = LoginResult.Error(msg)
            }
        }
    }
}

sealed class LoginResult {
    object Success : LoginResult()
    data class Error(val message: String) : LoginResult()
}