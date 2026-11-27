package com.bel.liaison_officer

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import java.io.File
import java.security.MessageDigest

/**
 * On-device checks for a rooted, emulated, debugged, hooked or re-signed app
 * (VAPT HIGH-05). Runs locally; nothing leaves the phone. Results are hints
 * a skilled attacker can hide, so the Dart side warns and logs, and the
 * server stays the real gate.
 */
object DeviceIntegrity {

    private val suPaths = listOf(
        "/system/bin/su", "/system/xbin/su", "/sbin/su", "/system/su",
        "/system/bin/.ext/su", "/system/usr/we-need-root/su", "/system/app/Superuser.apk",
        "/data/local/su", "/data/local/bin/su", "/data/local/xbin/su", "/su/bin/su",
        "/system/sbin/su", "/vendor/bin/su", "/cache/su", "/dev/su",
    )

    private val rootPackages = listOf(
        "com.topjohnwu.magisk", "io.github.huskydg.magisk", "io.github.vvb2060.magisk",
        "eu.chainfire.supersu", "com.noshufou.android.su", "com.koushikdutta.superuser",
        "com.thirdparty.superuser", "com.yellowes.su", "me.weishu.kernelsu",
        "de.robv.android.xposed.installer", "org.lsposed.manager",
    )

    fun check(context: Context): Map<String, Any?> {
        val reasons = mutableListOf<String>()

        val rooted = rootReasons(context).also { reasons += it }.isNotEmpty()
        val emulator = isEmulator().also { if (it) reasons += "emulator" }
        val debugger = Debug.isDebuggerConnected().also { if (it) reasons += "debugger attached" }
        val hooked = hookReasons().also { reasons += it }.isNotEmpty()
        val debuggable =
            (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        val signature = signatureMatches(context)
        if (signature == false) reasons += "signature mismatch (repackaged app)"

        return mapOf(
            "rooted" to rooted,
            "emulator" to emulator,
            "debuggerAttached" to debugger,
            "hooked" to hooked,
            "debuggable" to debuggable,
            "signatureValid" to signature,
            "reasons" to reasons,
        )
    }

    private fun rootReasons(context: Context): List<String> {
        val out = mutableListOf<String>()
        if (suPaths.any { File(it).exists() }) out += "su binary"
        if (Build.TAGS?.contains("test-keys") == true) out += "test-keys build"
        val pm = context.packageManager
        val found = rootPackages.firstOrNull { pkg ->
            try {
                pm.getPackageInfo(pkg, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
        if (found != null) out += "root app $found"
        return out
    }

    private fun isEmulator(): Boolean {
        val fp = Build.FINGERPRINT.orEmpty()
        val model = Build.MODEL.orEmpty()
        val product = Build.PRODUCT.orEmpty()
        val hardware = Build.HARDWARE.orEmpty()
        return fp.startsWith("generic") || fp.contains("emulator") || fp.contains("sdk_gphone") ||
            model.contains("Emulator") || model.contains("Android SDK built for") ||
            hardware == "goldfish" || hardware == "ranchu" || hardware.contains("vbox") ||
            product.startsWith("sdk") || product.contains("emulator") ||
            Build.MANUFACTURER.orEmpty().contains("Genymotion") ||
            Build.BRAND.orEmpty().startsWith("generic")
    }

    private fun hookReasons(): List<String> {
        val out = mutableListOf<String>()
        val maps = try {
            File("/proc/self/maps").readText()
        } catch (e: Exception) {
            ""
        }
        if (maps.contains("frida", ignoreCase = true) || maps.contains("gum-js", ignoreCase = true)) {
            out += "frida"
        }
        val fridaThreads = try {
            File("/proc/self/task").listFiles()?.any { task ->
                val name = File(task, "comm").takeIf { it.exists() }?.readText()?.trim().orEmpty()
                name == "gum-js-loop" || name == "gmain" || name == "gdbus" || name == "pool-frida"
            } ?: false
        } catch (e: Exception) {
            false
        }
        if (fridaThreads && "frida" !in out) out += "frida"
        if (maps.contains("XposedBridge") || maps.contains("lspd") || classExists("de.robv.android.xposed.XposedBridge")) {
            out += "xposed"
        }
        return out
    }

    private fun classExists(name: String): Boolean = try {
        Class.forName(name)
        true
    } catch (e: Throwable) {
        false
    }

    /**
     * True when the APK is signed with the release key it was built for,
     * false when it was re-signed, null when no release key was configured
     * at build time (debug / unsigned builds).
     */
    private fun signatureMatches(context: Context): Boolean? {
        val expected = BuildConfig.RELEASE_CERT_SHA256
        if (expected.isBlank()) return null
        return try {
            val info = context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
            val signers = info.signingInfo?.apkContentsSigners ?: return false
            val digest = MessageDigest.getInstance("SHA-256")
            signers.any { sig ->
                digest.digest(sig.toByteArray()).joinToString("") { "%02X".format(it) } ==
                    expected.uppercase()
            }
        } catch (e: Exception) {
            false
        }
    }
}
