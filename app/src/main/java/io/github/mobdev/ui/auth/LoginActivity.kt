package io.github.mobdev.ui.auth

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import io.github.mobdev.R
import io.github.mobdev.databinding.ActivityLoginBinding
import io.github.mobdev.ui.channel.ChannelActivity
import javax.inject.Inject
import io.github.mobdev.ChatApplication

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding

    @Inject
    lateinit var viewModelFactory: LoginViewModelFactory

    private val viewModel: LoginViewModel by viewModels { viewModelFactory }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        (application as ChatApplication).appComponent.inject(this)

        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        if (viewModel.isLoggedIn()) {
            startActivity(Intent(this, ChannelActivity::class.java))
            finish()
            return
        }

        setupObservers()
        setupListeners()
    }

    private fun setupObservers() {
        viewModel.loginResult.observe(this) { result ->
            when (result) {
                is LoginResult.Success -> {
                    startActivity(Intent(this, ChannelActivity::class.java))
                    finish()
                }
                is LoginResult.Error -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                }
            }
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.btnLogin.isEnabled = !isLoading
            binding.btnLogin.text = if (isLoading) "Вход..." else getString(R.string.login_button)
        }
    }

    private fun setupListeners() {
        binding.btnLogin.setOnClickListener {
            val username = binding.etUsername.text.toString().trim()
            val password = binding.etPassword.text.toString().trim()
            viewModel.login(username, password)
        }
    }
}