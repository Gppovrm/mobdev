package io.github.mobdev.ui.message

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import io.github.mobdev.data.model.Message
import io.github.mobdev.databinding.ItemMessageInBinding
import io.github.mobdev.databinding.ItemMessageOutBinding

class MessageAdapter(
    private val onImageClick: (String) -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    private var messages = listOf<Message>()
    private var currentUser = ""

    private val TYPE_IN = 0
    private val TYPE_OUT = 1

    fun updateMessages(newMessages: List<Message>, username: String = "") {
        currentUser = username
        messages = newMessages
        notifyDataSetChanged()
    }

    override fun getItemViewType(position: Int): Int {
        val msg = messages[position]
        return if (msg.from == currentUser) TYPE_OUT else TYPE_IN
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            TYPE_OUT -> {
                val binding = ItemMessageOutBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
                OutgoingViewHolder(binding)
            }

            else -> {
                val binding =
                    ItemMessageInBinding.inflate(LayoutInflater.from(parent.context), parent, false)
                IncomingViewHolder(binding)
            }
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val msg = messages[position]
        val text = msg.data.textContent?.text
        val image = msg.data.imageContent?.link

        when (holder) {
            is OutgoingViewHolder -> {
                if (text != null) {
                    holder.bind(text)
                } else if (image != null) {
                    holder.bindImage(image, onImageClick)
                }
            }

            is IncomingViewHolder -> {
                if (text != null) {
                    holder.bind(msg.from, text)
                } else if (image != null) {
                    holder.bindImage(msg.from, image, onImageClick)
                }
            }
        }
    }

    override fun getItemCount(): Int = messages.size

//    Входящие сообщения (слева)

    class IncomingViewHolder(private val binding: ItemMessageInBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(from: String, text: String) {
            binding.tvSender.text = from
            binding.tvMessage.text = text
            binding.tvMessage.visibility = View.VISIBLE
            binding.ivImage.visibility = View.GONE
        }

        fun bindImage(from: String, image: String, onClick: (String) -> Unit) {
            binding.tvSender.text = from
            val thumbUrl = "http://faerytea.name:8008/thumb/$image"
            Glide.with(itemView.context)
                .load(thumbUrl)
                .into(binding.ivImage)
            binding.ivImage.visibility = View.VISIBLE
            binding.tvMessage.visibility = View.GONE
            binding.ivImage.setOnClickListener { onClick(image) }
        }
    }

//    Исходящие сообщения (справа)

    class OutgoingViewHolder(private val binding: ItemMessageOutBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(text: String) {
            binding.tvMessage.text = text
            binding.tvMessage.visibility = View.VISIBLE
            binding.ivImage.visibility = View.GONE
        }

        fun bindImage(image: String, onClick: (String) -> Unit) {
            val thumbUrl = "http://faerytea.name:8008/thumb/$image"
            Glide.with(itemView.context)
                .load(thumbUrl)
                .into(binding.ivImage)
            binding.ivImage.visibility = View.VISIBLE
            binding.tvMessage.visibility = View.GONE
            binding.ivImage.setOnClickListener { onClick(image) }
        }
    }
}