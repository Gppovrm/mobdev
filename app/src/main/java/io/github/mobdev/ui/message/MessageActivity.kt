package io.github.mobdev.ui.message

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import io.github.mobdev.R
import io.github.mobdev.databinding.ActivityMessageBinding
import io.github.mobdev.ui.channel.ChannelActivity
import io.github.mobdev.ui.image.ImageActivity
import kotlinx.coroutines.launch
import javax.inject.Inject
import io.github.mobdev.ChatApplication

class MessageActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMessageBinding

    @Inject
    lateinit var viewModelFactory: MessageViewModelFactory

    private val viewModel: MessageViewModel by viewModels { viewModelFactory }

    private lateinit var adapter: MessageAdapter
    private lateinit var channelName: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        (application as ChatApplication).appComponent.inject(this)

        binding = ActivityMessageBinding.inflate(layoutInflater)
        setContentView(binding.root)

        channelName = intent.getStringExtra("channel_name") ?: run {
            finish()
            return
        }

        binding.tvToolbarTitle.text = channelName

        setupRecyclerView()
        setupObservers()
        setupListeners()
        viewModel.loadMessages(channelName)
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

    private fun setupObservers() {
        viewModel.messages.observe(this) { messages ->
            val sortedMessages = messages.reversed()
            val username = viewModel.getCurrentUser() ?: ""
            adapter.updateMessages(sortedMessages, username)
            if (sortedMessages.isNotEmpty()) {
                binding.rvMessages.scrollToPosition(adapter.itemCount - 1)
            }
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.btnSend.isEnabled = !isLoading
        }

        viewModel.sendResult.observe(this) { result ->
            when (result) {
                is SendResult.Success -> {
                    binding.etMessage.text.clear()
                    viewModel.loadMessages(channelName)
                }
                is SendResult.Error -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_SHORT).show()
                }
            }
            viewModel.consumeSendResult()
        }

        viewModel.error.observe(this) { error ->
            error?.let {
                Toast.makeText(this, "${getString(R.string.message_load_error)}: $it", Toast.LENGTH_SHORT).show()
                viewModel.consumeError()
            }
        }
    }

    private fun setupListeners() {
        binding.btnSend.setOnClickListener {
            val text = binding.etMessage.text.toString().trim()
            if (text.isNotEmpty()) {
                viewModel.sendMessage(channelName, text)
            }
        }

        binding.btnBackToChannels.setOnClickListener {
            startActivity(Intent(this, ChannelActivity::class.java))
            finish()
        }
    }
}