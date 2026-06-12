package io.github.mobdev.ui.message

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.mobdev.data.model.Message
import io.github.mobdev.data.repository.ChatRepository
import kotlinx.coroutines.launch
import javax.inject.Inject

class MessageViewModel @Inject constructor(
    private val repository: ChatRepository
) : ViewModel() {

    private val _messages = MutableLiveData<List<Message>>()
    val messages: LiveData<List<Message>> = _messages

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _sendResult = MutableLiveData<SendResult>()
    val sendResult: LiveData<SendResult> = _sendResult

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun loadMessages(channelName: String) {
        viewModelScope.launch {
            _isLoading.value = true
            val result = repository.getMessages(channelName)
            _isLoading.value = false

            result.onSuccess { messages ->
                _messages.value = messages
            }.onFailure { error ->
                _error.value = error.message
            }
        }
    }

    fun sendMessage(channelName: String, text: String) {
        if (text.isEmpty()) return

        viewModelScope.launch {
            _isLoading.value = true
            val result = repository.sendMessage(channelName, text)
            _isLoading.value = false

            result.onSuccess {
                _sendResult.value = SendResult.Success
            }.onFailure { error ->
                _sendResult.value = SendResult.Error(error.message ?: "Ошибка отправки")
            }
        }
    }

    fun getCurrentUser(): String? = repository.getCurrentUser()

    fun consumeSendResult() {
        _sendResult.value = null
    }

    fun consumeError() {
        _error.value = null
    }
}

sealed class SendResult {
    object Success : SendResult()
    data class Error(val message: String) : SendResult()
}