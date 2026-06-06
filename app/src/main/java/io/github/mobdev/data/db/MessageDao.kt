package io.github.mobdev.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface MessageDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(messages: List<MessageEntity>)

    @Query("SELECT * FROM messages WHERE channelId = :channelId ORDER BY timestamp DESC")
    suspend fun getForChannel(channelId: String): List<MessageEntity>

    @Query("DELETE FROM messages WHERE channelId = :channelId")
    suspend fun clearChannel(channelId: String)
}