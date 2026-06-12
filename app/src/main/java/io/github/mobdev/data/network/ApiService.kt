package io.github.mobdev.data.network

import io.github.mobdev.data.model.LoginRequest
import io.github.mobdev.data.model.Message
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @POST("/login")
    @Headers("Content-Type: application/json")
    suspend fun login(
        @Body request: LoginRequest
    ): Response<ResponseBody>

    @GET("/channels")
    suspend fun getChannels(
        @Header("X-Auth-Token") token: String
    ): Response<List<String>>

    @GET("/channel/{channelName}")
    suspend fun getMessages(
        @Header("X-Auth-Token") token: String,
        @Path("channelName") channelName: String,
        @Query("limit") limit: Int = 20,
        @Query("lastKnownId") lastId: Long? = null,
        @Query("reverse") reverse: Boolean = true
    ): Response<List<Message>>

    @POST("/messages")
    suspend fun sendMessage(
        @Header("X-Auth-Token") token: String,
        @Body message: Message
    ): Response<Unit>
}