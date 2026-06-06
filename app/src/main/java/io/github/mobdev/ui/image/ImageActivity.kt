package io.github.mobdev.ui.image

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import io.github.mobdev.databinding.ActivityImageBinding

class ImageActivity : AppCompatActivity() {

    private lateinit var binding: ActivityImageBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityImageBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val imageUrl = intent.getStringExtra("image_url") ?: run {
            finish()
            return
        }
        val fullUrl = "http://faerytea.name:8008/img/$imageUrl"

        Glide.with(this)
            .load(fullUrl)
            .into(binding.ivFullImage)

        binding.ivFullImage.setOnClickListener {
            finish()
        }
    }
}