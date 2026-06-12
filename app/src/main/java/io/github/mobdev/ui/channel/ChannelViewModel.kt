package io.github.mobdev.ui.channel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.mobdev.data.model.Message
import io.github.mobdev.data.repository.ChatRepository
import kotlinx.coroutines.launch
import javax.inject.Inject

class ChannelViewModel @Inject constructor(
    private val repository: ChatRepository
) : ViewModel() {

    private val _channels = MutableLiveData<List<String>>()
    val channels: LiveData<List<String>> = _channels

    private val _messages = MutableLiveData<List<Message>>()
    val messages: LiveData<List<Message>> = _messages

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun loadChannels() {
        viewModelScope.launch {
            _isLoading.value = true
            val result = repository.getChannels()
            _isLoading.value = false

            result.onSuccess { channels ->
                _channels.value = channels
            }.onFailure { error ->
                _error.value = error.message
            }
        }
    }

    fun loadMessagesForChannel(channel: String) {
        viewModelScope.launch {
            _isLoading.value = true
            val result = repository.getMessages(channel)
            _isLoading.value = false

            result.onSuccess { messages ->
                _messages.value = messages
            }.onFailure { error ->
                _error.value = error.message
            }
        }
    }

    fun logout() {
        repository.logout()
    }

    fun isLoggedIn(): Boolean = repository.isLoggedIn()
    fun getCurrentUser(): String? = repository.getCurrentUser()
    fun clearError() {
        _error.value = null
    }
}