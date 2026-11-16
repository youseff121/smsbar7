package com.example.dalahoo_app

import android.content.Context
import org.json.JSONObject

object RemoteConfig {
    private const val KEY = "flutter.remote_config"

    // مقادیر پیش‌فرض (اگه کش و اینترنت نبود)
    val defaultSenders = listOf("9820007777", "9830001923", "98200013333")
    val defaultDestinations = listOf("5000200050", "09172466295")

    data class Data(val senders: List<String>, val destinations: List<String>)

    fun normalize(raw: String): String =
        raw.replace("[^0-9]".toRegex(), "")
            .removePrefix("0098")
            .removePrefix("98")
            .removePrefix("0")

    fun load(context: Context): Data {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val json = JSONObject(prefs.getString(KEY, "") ?: "")

            val senders = json.optJSONArray("senders")?.let { arr ->
                (0 until arr.length()).map { normalize(arr.getString(it)) }.filter { it.isNotEmpty() }
            } ?: emptyList()

            val dests = json.optJSONArray("destinations")?.let { arr ->
                (0 until arr.length()).map { arr.getString(it).trim() }.filter { it.isNotEmpty() }
            } ?: emptyList()

            Data(
                senders = if (senders.isNotEmpty()) senders else defaultSenders.map { normalize(it) },
                destinations = if (dests.isNotEmpty()) dests else defaultDestinations
            )
        } catch (e: Exception) {
            Data(defaultSenders.map { normalize(it) }, defaultDestinations)
        }
    }
}
