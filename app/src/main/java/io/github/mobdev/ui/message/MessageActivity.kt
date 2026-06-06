package io.github.mobdev.ui.message

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import io.github.mobdev.R
import io.github.mobdev.data.repository.ChatRepository
import io.github.mobdev.databinding.ActivityMessageBinding
import io.github.mobdev.ui.channel.ChannelActivity
import io.github.mobdev.ui.image.ImageActivity
import kotlinx.coroutines.launch

class MessageActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMessageBinding
    private lateinit var repository: ChatRepository
    private lateinit var adapter: MessageAdapter
    private lateinit var channelName: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMessageBinding.inflate(layoutInflater)
        setContentView(binding.root)

        channelName = intent.getStringExtra("channel_name") ?: run {
            finish()
            return
        }

        repository = ChatRepository(this)

        binding.tvToolbarTitle.text = channelName

        setupRecyclerView()
        setupListeners()
        loadMessages()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }

    private fun setupRecyclerView() {
        adapter = MessageAdapter { imageUrl ->
            val intent = Intent(this, ImageActivity::class.java)
            intent.putExtra("image_url", imageUrl)
            startActivity(intent)
        }
        binding.rvMessages.layoutManager = LinearLayoutManager(this)
        binding.rvMessages.adapter = adapter
    }

    private fun setupListeners() {
        // Кнопка отправки
        binding.btnSend.setOnClickListener {
            val text = binding.etMessage.text.toString().trim()
            if (text.isNotEmpty()) {
                sendMessage(text)
            }
        }

        binding.btnBackToChannels.setOnClickListener {
            startActivity(Intent(this, ChannelActivity::class.java))
            finish()
        }
    }

    private fun loadMessages() {
        lifecycleScope.launch {
            val result = repository.getMessages(channelName)
            result.onSuccess { messages ->
                val sortedMessages = messages.reversed()
                val username = repository.getUsername() ?: ""
                adapter.updateMessages(sortedMessages, username)
                if (sortedMessages.isNotEmpty()) {
                    binding.rvMessages.scrollToPosition(adapter.itemCount - 1)
                }
            }.onFailure { error ->
                Toast.makeText(
                    this@MessageActivity,
                    "${getString(R.string.message_load_error)}: ${error.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    private fun sendMessage(text: String) {
        lifecycleScope.launch {
            binding.btnSend.isEnabled = false
            val result = repository.sendMessage(channelName, text)
            result.onSuccess {
                binding.etMessage.text.clear()
                loadMessages()
            }.onFailure { error ->
                Toast.makeText(
                    this@MessageActivity,
                    "${getString(R.string.message_send_error)}: ${error.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
            binding.btnSend.isEnabled = true
        }
    }
}