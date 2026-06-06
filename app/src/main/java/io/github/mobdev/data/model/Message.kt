package io.github.mobdev.data.model

import com.google.gson.annotations.SerializedName

data class LoginRequest(
    val name: String,
    val pwd: String
)

data class Message(
    val id: Long? = null,
    val from: String,
    val to: String,
    val data: MessageData,
    val time: Long? = null
)

data class MessageData(
    @SerializedName("Text")
    val textContent: TextContent? = null,
    @SerializedName("Image")
    val imageContent: ImageContent? = null
)

data class TextContent(
    val text: String
)

data class ImageContent(
    val link: String
)