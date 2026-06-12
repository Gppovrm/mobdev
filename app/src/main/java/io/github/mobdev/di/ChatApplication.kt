package io.github.mobdev

import android.app.Application
import io.github.mobdev.di.AppComponent
import io.github.mobdev.di.DaggerAppComponent
import io.github.mobdev.di.ContextModule

class ChatApplication : Application() {

    lateinit var appComponent: AppComponent
        private set

    override fun onCreate() {
        super.onCreate()
        appComponent = DaggerAppComponent.builder()
            .contextModule(ContextModule(this))
            .build()
        appComponent.inject(this)
    }
}