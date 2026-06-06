package io.github.mobdev.ui.auth

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import io.github.mobdev.R
import io.github.mobdev.data.repository.ChatRepository
import io.github.mobdev.databinding.ActivityLoginBinding
import io.github.mobdev.ui.channel.ChannelActivity
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private lateinit var repository: ChatRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        repository = ChatRepository(this)

        if (repository.isLoggedIn()) {
            startActivity(Intent(this, ChannelActivity::class.java))
            finish()
            return
        }

        binding.btnLogin.setOnClickListener {
            val username = binding.etUsername.text.toString().trim()
            val password = binding.etPassword.text.toString().trim()

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, getString(R.string.login_error_empty), Toast.LENGTH_SHORT)
                    .show()
                return@setOnClickListener
            }

            lifecycleScope.launch {
                binding.btnLogin.isEnabled = false
                binding.btnLogin.text = getString(R.string.login_button)

                val result = repository.login(username, password)
                result.onSuccess {
                    startActivity(Intent(this@LoginActivity, ChannelActivity::class.java))
                    finish()
                }.onFailure { error ->
                    val msg = if (error.message?.contains("401") == true) {
                        getString(R.string.login_error_invalid)
                    } else {
                        getString(R.string.login_error_network)
                    }
                    Toast.makeText(this@LoginActivity, msg, Toast.LENGTH_LONG).show()
                    binding.btnLogin.isEnabled = true
                    binding.btnLogin.text = getString(R.string.login_button)
                }
            }
        }
    }
}