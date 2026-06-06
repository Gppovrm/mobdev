package io.github.mobdev.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey
    val id: Long,
    val channelId: String,
    val fromUser: String,
    val text: String?,
    val imageLink: String?,
    val timestamp: Long
)