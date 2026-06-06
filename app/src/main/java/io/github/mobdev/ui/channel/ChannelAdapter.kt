package io.github.mobdev.ui.channel

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import io.github.mobdev.R

class ChannelAdapter(
    private val onItemClick: (String) -> Unit
) : RecyclerView.Adapter<ChannelAdapter.ChannelViewHolder>() {

    private var channels = listOf<String>()
    private var selectedChannel: String? = null

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ChannelViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        return ChannelViewHolder(view)
    }

    override fun onBindViewHolder(holder: ChannelViewHolder, position: Int) {
        val channel = channels[position]
        holder.bind(channel)

        // Подсветка выбранного канала
        if (channel == selectedChannel) {
            holder.itemView.setBackgroundColor(
                ContextCompat.getColor(holder.itemView.context, R.color.selected_channel)
            )
        } else {
            holder.itemView.setBackgroundColor(
                ContextCompat.getColor(holder.itemView.context, android.R.color.transparent)
            )
        }

        holder.itemView.setOnClickListener {
            // Сначала снимаем подсветку со старого
            val oldPosition = channels.indexOf(selectedChannel)
            selectedChannel = channel
            // Обновляем старый и новый элементы
            if (oldPosition != -1) notifyItemChanged(oldPosition)
            notifyItemChanged(position)
            onItemClick(channel)
        }
    }

    override fun getItemCount(): Int = channels.size

    fun updateChannels(newChannels: List<String>) {
        channels = newChannels
        selectedChannel = null
        notifyDataSetChanged()
    }

    fun updateSelectedChannel(channel: String) {
        val oldPosition = channels.indexOf(selectedChannel)
        selectedChannel = channel
        if (oldPosition != -1) notifyItemChanged(oldPosition)
        val newPosition = channels.indexOf(selectedChannel)
        if (newPosition != -1) notifyItemChanged(newPosition)
    }

    class ChannelViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val textView: TextView = itemView as TextView

        fun bind(channel: String) {
            textView.text = channel
        }
    }
}