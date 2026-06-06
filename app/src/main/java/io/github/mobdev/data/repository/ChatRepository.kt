package io.github.mobdev.data.repository

import android.content.Context
import androidx.core.content.edit
import io.github.mobdev.data.model.LoginRequest
import io.github.mobdev.data.model.Message
import io.github.mobdev.data.model.MessageData
import io.github.mobdev.data.model.TextContent
import io.github.mobdev.data.network.RetrofitClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

class ChatRepository(context: Context) {

    private val api = RetrofitClient.api
    private val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)

    private fun saveToken(token: String) {
        prefs.edit { putString("auth_token", token) }
    }

    private fun getToken(): String? = prefs.getString("auth_token", null)

    private fun saveUsername(username: String) {
        prefs.edit { putString("username", username) }
    }

    fun getUsername(): String? = prefs.getString("username", null)

    fun isLoggedIn(): Boolean = !getToken().isNullOrEmpty()

    fun logout() {
        prefs.edit { clear() }
    }

    suspend fun login(username: String, password: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            try {
                val response = api.login(LoginRequest(username, password))
                if (response.isSuccessful) {
                    val rawResponse = response.body()?.string() ?: ""
                    val token = rawResponse.substringAfter("'").substringBefore("'")
                    saveToken(token)
                    saveUsername(username)
                    Result.success(Unit)
                } else {
                    Result.failure(IOException("Неверный логин или пароль"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    suspend fun getChannels(): Result<List<String>> = withContext(Dispatchers.IO) {
        val token = getToken() ?: return@withContext Result.failure(
            IllegalStateException(ERROR_NOT_LOGGED_IN)
        )
        try {
            val response = api.getChannels(token)
            if (response.isSuccessful) {
                Result.success(response.body() ?: emptyList())
            } else {
                Result.failure(IOException("Ошибка загрузки каналов"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getMessages(channelName: String): Result<List<Message>> =
        withContext(Dispatchers.IO) {
            val token = getToken() ?: return@withContext Result.failure(
                IllegalStateException(ERROR_NOT_LOGGED_IN)
            )
            try {
                val response =
                    api.getMessages(token, channelName, limit = 20, lastId = null, reverse = true)
                if (response.isSuccessful) {
                    val messages = response.body() ?: emptyList()
                    Result.success(messages)
                } else {
                    Result.failure(IOException("Ошибка загрузки сообщений"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    suspend fun sendMessage(channelName: String, text: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            val token = getToken() ?: return@withContext Result.failure(
                IllegalStateException(ERROR_NOT_LOGGED_IN)
            )
            val fromUser = getUsername() ?: return@withContext Result.failure(
                IllegalStateException(ERROR_NO_USERNAME)
            )

            val message = Message(
                from = fromUser,
                to = channelName,
                data = MessageData(textContent = TextContent(text))
            )

            try {
                val response = api.sendMessage(token, message)
                if (response.isSuccessful) {
                    Result.success(Unit)
                } else {
                    Result.failure(IOException("Ошибка отправки"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    companion object {
        private const val ERROR_NOT_LOGGED_IN = "Not logged in"
        private const val ERROR_NO_USERNAME = "No username"
    }
}