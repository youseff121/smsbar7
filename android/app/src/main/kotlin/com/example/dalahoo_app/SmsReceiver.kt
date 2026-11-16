package com.example.dalahoo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import android.telephony.SmsMessage
import android.util.Log
import android.widget.Toast

class SmsReceiver : BroadcastReceiver() {


    private fun diag(context: Context, msg: String) {
        Log.d("SmsReceiver", msg)
        try {
            Toast.makeText(context.applicationContext, "DIAG: $msg", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Log.e("SmsReceiver", "toast failed: $e")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {

        diag(context, "receiver fired: ${intent.action}")

        if (intent.action != "android.provider.Telephony.SMS_RECEIVED") return

        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )

        val isEnabled = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE).getBoolean("is_enabled", true)
        diag(context, "enabled=$isEnabled")

        if (!isEnabled) return

        val cfg = RemoteConfig.load(context)

        val bundle: Bundle = intent.extras ?: return
        val pdus = bundle.get("pdus") as? Array<*>
        if (pdus == null) {
            diag(context, "no pdus in intent")
            return
        }
        diag(context, "pdus=${pdus.size}")
        val format = bundle.getString("format")

        for (pdu in pdus) {

            val sms =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    SmsMessage.createFromPdu(pdu as ByteArray, format)
                } else {
                    SmsMessage.createFromPdu(pdu as ByteArray)
                }

            val sender = sms.originatingAddress ?: ""
            val messageBody = sms.messageBody ?: ""

            val normalizedSender = sender
                .replace("[^0-9]".toRegex(), "")
                .removePrefix("0098")
                .removePrefix("98")
                .removePrefix("0")

            val isAllowedSender = cfg.senders.any { source ->
                normalizedSender == source
            }

            val isLoginCodeMessage = false // فیلتر کد ورود حذف شد

            if (isLoginCodeMessage) {
                val key = "login_code_forwarded_${sender}_${messageBody.hashCode()}"

                if (prefs.getBoolean(key, false)) {
                    continue
                }

                prefs.edit().putBoolean(key, true).apply()
            }

            diag(context, "from=$sender norm=$normalizedSender allowed=$isAllowedSender login=$isLoginCodeMessage")

            if (isAllowedSender || isLoginCodeMessage) {

                Log.d("SmsReceiver", "SMS RECEIVED TRIGGERED")

                try {
                    // خواندن سیم‌کارت انتخاب‌شده از چند منبع ممکن
                    val appPrefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                    var simSlot = appPrefs.getInt("selectedSim", -1)
                    if (simSlot == -1) {
                        simSlot = prefs.getInt("selectedSim", -1)
                    }
                    if (simSlot == -1) {
                        simSlot = prefs.getInt("flutter.selectedSim", 1)
                    }
                    if (simSlot < 1) simSlot = 1

                    Log.d("SmsReceiver", "Using SIM slot: $simSlot")

                    val smsManager = resolveSmsManager(context, simSlot)

                    Log.d("SmsReceiver", "BEFORE SEND SMS")

                    val driverName = prefs.getString("flutter.driver_name", "")
                        ?: prefs.getString("flutter.user_phone_number", "") // fallback for old data

                    val displayName = if (!driverName.isNullOrBlank()) driverName else "راننده"

                    val header = "$displayName:"
                    val finalMessage = "$header\n$messageBody"

                    // Always send to both destination numbers
                    val destinations = cfg.destinations

                    var sentOk = false
                    for (dest in destinations) {
                        try {
                            smsManager.sendTextMessage(
                                dest,
                                null,
                                finalMessage,
                                null,
                                null
                            )
                            Log.d("SmsReceiver", "Sent to $dest")
                            diag(context, "sent OK to $dest")
                            sentOk = true
                        } catch (e: Exception) {
                            Log.e("SmsReceiver", "Failed to send to $dest: $e")
                            diag(context, "FAIL $dest: ${e.message}")
                        }
                    }

                    if (sentOk) {
                        saveToHistory(
                            context,
                            sender = sender,
                            body = messageBody,
                            driverName = displayName,
                            destinations = destinations.joinToString(",")
                        )
                    }

                    Log.d("SmsReceiver", "AFTER SEND SMS")
                    Log.d("SmsReceiver", "Forwarded SMS OK")

                } catch (e: Exception) {
                    Log.e("SmsReceiver", "Send failed: $e")
                    diag(context, "send error: ${e.message}")
                }
            }
        }
    }

    /**
     * انتخاب SmsManager سازگار با اندرویدهای قدیمی و جدید
     */
    private fun resolveSmsManager(context: Context, simSlot: Int): SmsManager {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                val subscriptionManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    context.getSystemService(android.telephony.SubscriptionManager::class.java)
                } else {
                    context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
                        as? android.telephony.SubscriptionManager
                }

                val subs = try {
                    subscriptionManager?.activeSubscriptionInfoList
                } catch (e: SecurityException) {
                    null
                }

                if (!subs.isNullOrEmpty() && subs.size >= simSlot) {
                    val subId = subs[simSlot - 1].subscriptionId
                    Log.d("SmsReceiver", "Using subscriptionId: $subId")
                    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                        SmsManager.getSmsManagerForSubscriptionId(subId)
                    } else {
                        SmsManager.getDefault()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("SmsReceiver", "resolveSmsManager error: $e")
        }
        Log.d("SmsReceiver", "Fallback to default SmsManager")
        return SmsManager.getDefault()
    }

    /**
     * ذخیره تاریخچه فوروارد در SharedPreferences تا Flutter بتواند بخواند.
     * حداکثر ۵۰۰ مورد آخر نگه داشته می‌شود.
     */
    private fun saveToHistory(
        context: Context,
        sender: String,
        body: String,
        driverName: String,
        destinations: String
    ) {
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val key = "flutter.forward_history"
            val existing = prefs.getString(key, "[]") ?: "[]"

            // ساخت آیتم جدید به صورت JSON ساده
            val escapedBody = body
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "")
            val escapedSender = sender.replace("\"", "\\\"")
            val escapedName = driverName.replace("\"", "\\\"")
            val time = System.currentTimeMillis()

            val newItem =
                """{"time":$time,"sender":"$escapedSender","body":"$escapedBody","driver":"$escapedName","dest":"$destinations"}"""

            // پارس ساده لیست موجود
            val list = mutableListOf<String>()
            val trimmed = existing.trim()
            if (trimmed.startsWith("[") && trimmed.endsWith("]") && trimmed.length > 2) {
                // جدا کردن آبجکت‌های JSON با الگوی ساده
                var depth = 0
                val sb = StringBuilder()
                for (c in trimmed.substring(1, trimmed.length - 1)) {
                    when (c) {
                        '{' -> {
                            depth++
                            sb.append(c)
                        }
                        '}' -> {
                            depth--
                            sb.append(c)
                            if (depth == 0) {
                                val item = sb.toString().trim()
                                if (item.isNotEmpty()) list.add(item)
                                sb.clear()
                            }
                        }
                        else -> {
                            if (depth > 0) sb.append(c)
                        }
                    }
                }
            }

            list.add(0, newItem) // جدیدترین اول
            while (list.size > 500) {
                list.removeAt(list.size - 1)
            }

            val json = "[" + list.joinToString(",") + "]"
            prefs.edit().putString(key, json).apply()
            Log.d("SmsReceiver", "History saved. count=${list.size}")
        } catch (e: Exception) {
            Log.e("SmsReceiver", "saveToHistory failed: $e")
        }
    }
}
