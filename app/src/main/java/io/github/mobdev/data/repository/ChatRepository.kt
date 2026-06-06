package io.github.mobdev.data.repository

import android.content.Context
import io.github.mobdev.data.db.AppDatabase
import io.github.mobdev.data.db.ChannelEntity
import io.github.mobdev.data.db.MessageEntity
import io.github.mobdev.data.model.LoginRequest
import io.github.mobdev.data.model.Message
import io.github.mobdev.data.model.MessageData
import io.github.mobdev.data.model.TextContent
import io.github.mobdev.data.network.RetrofitClient
import io.github.mobdev.utils.NetworkMonitor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import java.io.IOException

class ChatRepository(private val context: Context) {

    private val api = RetrofitClient.api
    private val db = AppDatabase.getInstance(context)
    private val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    private val networkMonitor = NetworkMonitor(context)

    private fun getToken(): String? = prefs.getString("auth_token", null)
    private fun saveToken(token: String) = prefs.edit().putString("auth_token", token).apply()
    fun getCurrentUser(): String? = prefs.getString("username", null)
    private fun saveUsername(name: String) = prefs.edit().putString("username", name).apply()

    fun isLoggedIn() = !getToken().isNullOrEmpty()
    fun logout() = prefs.edit().clear().apply()

    suspend fun login(username: String, password: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            try {
                val response = api.login(LoginRequest(username, password))
                if (response.isSuccessful) {
                    val token =
                        response.body()?.string()?.substringAfter("'")?.substringBefore("'") ?: ""
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
        val token =
            getToken() ?: return@withContext Result.failure(IllegalStateException("Not logged in"))

        if (networkMonitor.isOnline.first()) {
            runCatching {
                val response = api.getChannels(token)
                if (response.isSuccessful) {
                    response.body() ?: emptyList()
                } else throw IOException("Ошибка сервера")
            }.onSuccess { channels ->
                db.channelDao().insertAll(channels.map { ChannelEntity(it) })
                return@withContext Result.success(channels)
            }.onFailure {
                db.channelDao().getAll().map { it.name }.takeIf { it.isNotEmpty() }
                    ?.let { return@withContext Result.success(it) }
            }
        }
// Офлайн берём из кэша
        db.channelDao().getAll().map { it.name }.takeIf { it.isNotEmpty() }
            ?.let { return@withContext Result.success(it) }
            ?: Result.failure(IOException("Нет данных"))
    }

    suspend fun getMessages(channelName: String): Result<List<Message>> =
        withContext(Dispatchers.IO) {
            val token = getToken()
                ?: return@withContext Result.failure(IllegalStateException("Not logged in"))

            if (networkMonitor.isOnline.first()) {
                runCatching {
                    val response = api.getMessages(token, channelName, 20, null, true)
                    if (response.isSuccessful) response.body() ?: emptyList()
                    else throw IOException("Ошибка сервера")
                }.onSuccess { messages ->
                    db.messageDao().clearChannel(channelName)
                    db.messageDao().insertAll(messages.map { msg ->
                        MessageEntity(
                            id = msg.id ?: System.currentTimeMillis(),
                            channelId = channelName,
                            fromUser = msg.from,
                            text = msg.data.textContent?.text,
                            imageLink = msg.data.imageContent?.link,
                            timestamp = msg.time ?: System.currentTimeMillis()
                        )
                    })
                    return@withContext Result.success(messages)
                }.onFailure {
                    db.messageDao().getForChannel(channelName).takeIf { it.isNotEmpty() }
                        ?.let { cached ->
                            return@withContext Result.success(cached.map { entity ->
                                Message(
                                    id = entity.id,
                                    from = entity.fromUser,
                                    to = channelName,
                                    data = MessageData(textContent = entity.text?.let {
                                        TextContent(
                                            it
                                        )
                                    }),
                                    time = entity.timestamp
                                )
                            })
                        }
                }
            }
            // Офлайн
            db.messageDao().getForChannel(channelName).takeIf { it.isNotEmpty() }
                ?.let { cached ->
                    return@withContext Result.success(cached.map { entity ->
                        Message(
                            id = entity.id,
                            from = entity.fromUser,
                            to = channelName,
                            data = MessageData(textContent = entity.text?.let { TextContent(it) }),
                            time = entity.timestamp
                        )
                    })
                }
            Result.failure(IOException("Нет данных"))
        }

    suspend fun sendMessage(channelName: String, text: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            val token = getToken()
                ?: return@withContext Result.failure(IllegalStateException("Not logged in"))
            val fromUser = getCurrentUser() ?: return@withContext Result.failure(
                IllegalStateException("No username")
            )

            if (!networkMonitor.isOnline.first()) {
                return@withContext Result.failure(IOException("Нет интернета"))
            }

            val message = Message(
                from = fromUser,
                to = channelName,
                data = MessageData(textContent = TextContent(text))
            )
            return@withContext try {
                val response = api.sendMessage(token, message)
                if (response.isSuccessful) {
                    getMessages(channelName) // обнов кэш
                    Result.success(Unit)
                } else {
                    Result.failure(IOException("Ошибка отправки"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
}