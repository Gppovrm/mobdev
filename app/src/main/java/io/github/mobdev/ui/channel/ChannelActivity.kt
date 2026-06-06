package io.github.mobdev.ui.channel

import android.content.Intent
import android.os.Bundle
import android.widget.FrameLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.github.mobdev.R
import io.github.mobdev.data.repository.ChatRepository
import io.github.mobdev.databinding.ActivityChannelBinding
import io.github.mobdev.ui.auth.LoginActivity
import io.github.mobdev.ui.image.ImageActivity
import io.github.mobdev.ui.message.MessageActivity
import io.github.mobdev.ui.message.MessageAdapter
import kotlinx.coroutines.launch

class ChannelActivity : AppCompatActivity() {

    private lateinit var binding: ActivityChannelBinding
    private lateinit var repository: ChatRepository
    private lateinit var channelAdapter: ChannelAdapter
    private lateinit var messageAdapter: MessageAdapter
    private lateinit var messageRecyclerView: RecyclerView
    private var selectedChannel: String? = null

    private val messageContainer: FrameLayout?
        get() = findViewById(R.id.messageContainer)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChannelBinding.inflate(layoutInflater)
        setContentView(binding.root)

        repository = ChatRepository(this)

        if (!repository.isLoggedIn()) {
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            return
        }

        selectedChannel = savedInstanceState?.getString("selected_channel")

        setupRecyclerView()
        setupListeners()
        loadChannels()

        selectedChannel?.takeIf { isLandscape() }?.let {
            loadMessagesForChannel(it)
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString("selected_channel", selectedChannel)
    }

    private fun isLandscape(): Boolean {
        return messageContainer?.isVisible == true
    }

    private fun setupRecyclerView() {
        channelAdapter = ChannelAdapter { channel ->
            selectedChannel = channel
            channelAdapter.updateSelectedChannel(channel)
            if (isLandscape()) {
                loadMessagesForChannel(channel)
            } else {
                val intent = Intent(this, MessageActivity::class.java)
                intent.putExtra("channel_name", channel)
                startActivity(intent)
            }
        }
        binding.rvChannels.layoutManager = LinearLayoutManager(this)
        binding.rvChannels.adapter = channelAdapter
    }

    private fun setupListeners() {
        binding.btnLogout.setOnClickListener {
            repository.logout()
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
        }
    }

    private fun loadChannels() {
        lifecycleScope.launch {
            repository.getChannels().onSuccess { channels ->
                channelAdapter.updateChannels(channels)
            }.onFailure { error ->
                Toast.makeText(this@ChannelActivity, "Ошибка: ${error.message}", Toast.LENGTH_SHORT)
                    .show()
            }
        }
    }

    private fun loadMessagesForChannel(channel: String) {
        lifecycleScope.launch {
            repository.getMessages(channel).onSuccess { messages ->
                if (isLandscape()) {
                    messageContainer?.isVisible = true
                    val sortedMessages = messages.reversed()
                    val username = repository.getUsername() ?: ""

                    if (!::messageAdapter.isInitialized) {
                        initMessageRecyclerView()
                    }
                    messageAdapter.updateMessages(sortedMessages, username)
                    messageRecyclerView.scrollToPosition(messageAdapter.itemCount - 1)
                }
            }.onFailure { error ->
                Toast.makeText(this@ChannelActivity, "Ошибка: ${error.message}", Toast.LENGTH_SHORT)
                    .show()
            }
        }
    }

    private fun initMessageRecyclerView() {
        val container = messageContainer ?: return

        messageAdapter = MessageAdapter { imageUrl ->
            val intent = Intent(this, ImageActivity::class.java)
            intent.putExtra("image_url", imageUrl)
            startActivity(intent)
        }
        messageRecyclerView = RecyclerView(this).apply {
            layoutManager = LinearLayoutManager(this@ChannelActivity)
            adapter = messageAdapter
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        container.addView(messageRecyclerView)
    }
}