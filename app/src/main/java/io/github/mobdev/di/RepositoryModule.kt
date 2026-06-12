package io.github.mobdev.di

import android.content.Context
import dagger.Module
import dagger.Provides
import io.github.mobdev.data.db.AppDatabase
import io.github.mobdev.data.network.ApiService
import io.github.mobdev.data.repository.ChatRepository
import javax.inject.Singleton

@Module
class RepositoryModule {

    @Provides
    @Singleton
    fun provideAppDatabase(context: Context): AppDatabase {
        return AppDatabase.getInstance(context)
    }

    @Provides
    @Singleton
    fun provideChatRepository(
        context: Context,
        apiService: ApiService,
        db: AppDatabase
    ): ChatRepository {
        return ChatRepository(context, apiService, db)
    }
}