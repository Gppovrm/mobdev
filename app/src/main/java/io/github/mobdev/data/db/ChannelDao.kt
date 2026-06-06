package io.github.mobdev.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface ChannelDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(channels: List<ChannelEntity>)

    @Query("SELECT * FROM channels")
    suspend fun getAll(): List<ChannelEntity>

    @Query("DELETE FROM channels")
    suspend fun clearAll()
}