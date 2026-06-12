package io.github.mobdev.di

import dagger.Component
import io.github.mobdev.ChatApplication
import io.github.mobdev.ui.auth.LoginActivity
import io.github.mobdev.ui.channel.ChannelActivity
import io.github.mobdev.ui.message.MessageActivity
import javax.inject.Singleton

@Singleton
@Component(
    modules = [
        ContextModule::class,
        NetworkModule::class,
        RepositoryModule::class,
        ViewModelModule::class
    ]
)
interface AppComponent {
    fun inject(application: ChatApplication)
    fun inject(activity: LoginActivity)
    fun inject(activity: ChannelActivity)
    fun inject(activity: MessageActivity)
}