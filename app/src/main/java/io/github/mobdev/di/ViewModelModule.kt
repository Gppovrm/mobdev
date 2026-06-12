package io.github.mobdev.di

import dagger.Module
import dagger.Provides
import io.github.mobdev.data.repository.ChatRepository
import io.github.mobdev.ui.auth.LoginViewModel
import io.github.mobdev.ui.auth.LoginViewModelFactory
import io.github.mobdev.ui.channel.ChannelViewModel
import io.github.mobdev.ui.channel.ChannelViewModelFactory
import io.github.mobdev.ui.message.MessageViewModel
import io.github.mobdev.ui.message.MessageViewModelFactory
import javax.inject.Singleton

@Module
class ViewModelModule {

    @Provides
    @Singleton
    fun provideLoginViewModel(repository: ChatRepository): LoginViewModel {
        return LoginViewModel(repository)
    }

    @Provides
    @Singleton
    fun provideLoginViewModelFactory(viewModel: LoginViewModel): LoginViewModelFactory {
        return LoginViewModelFactory(viewModel)
    }

    @Provides
    @Singleton
    fun provideChannelViewModel(repository: ChatRepository): ChannelViewModel {
        return ChannelViewModel(repository)
    }

    @Provides
    @Singleton
    fun provideChannelViewModelFactory(viewModel: ChannelViewModel): ChannelViewModelFactory {
        return ChannelViewModelFactory(viewModel)
    }

    @Provides
    @Singleton
    fun provideMessageViewModel(repository: ChatRepository): MessageViewModel {
        return MessageViewModel(repository)
    }

    @Provides
    @Singleton
    fun provideMessageViewModelFactory(viewModel: MessageViewModel): MessageViewModelFactory {
        return MessageViewModelFactory(viewModel)
    }
}