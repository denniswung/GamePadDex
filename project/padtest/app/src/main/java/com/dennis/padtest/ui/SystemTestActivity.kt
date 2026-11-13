package com.dennis.padtest.ui

import android.content.Context
import android.graphics.Color
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src

/**
 * 五、系统动作测试页。
 *
 * 能可靠观测的：音量（AudioManager）、屏幕亮灭（PowerManager）、缩放注入键（Ctrl+Plus/Minus）、
 * 上一次被强停/被杀的时间（进程重启检测）。
 * 不能可靠观测的（已明确标注，不假装能测）：通知栏展开状态、媒体会话曲目、
 * 系统缩放比例（第三方 App 不可读）。
 */
class SystemTestActivity : ProbeActivity() {

    private lateinit var volumeView: TextView
    private lateinit var screenView: TextView
    private lateinit var mediaView: TextView
    private lateinit var zoomView: TextView
    private lateinit var forceStopView: TextView
    private lateinit var notifView: TextView

    private var lastVolume = -1
    private val volumeHistory = ArrayList<String>()
    private var lastInteractive: Boolean? = null
    private var screenChangedAt = 0L
    private var zoomIn = 0
    private var zoomOut = 0
    private var mediaToggles = 0

    private val am by lazy { getSystemService(Context.AUDIO_SERVICE) as AudioManager }
    private val pm by lazy { getSystemService(Context.POWER_SERVICE) as PowerManager }

    private val handler = Handler(Looper.getMainLooper())
    private val tick = object : Runnable {
        override fun run() {
            refresh()
            handler.postDelayed(this, 500)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        CheckRegistry.define("SYS.VOLUME", "系统", "音量键可改音量")
        CheckRegistry.define("SYS.SCREEN", "系统", "屏幕状态可读且有变化")
        CheckRegistry.define("SYS.ZOOM", "系统", "缩放键可观测")
        CheckRegistry.define("SYS.FORCESTOP", "系统", "强停后能记录上次终止时间")
        CheckRegistry.define("SYS.MEDIA", "系统", "媒体键可观测")
        CheckRegistry.define("SYS.NOTIF", "系统", "通知栏状态可观测（受限）")
        markProcessStart()
        super.onCreate(savedInstanceState)
    }

    override fun buildContent(): View {
        val col = page("系统动作测试", "音量 / 屏幕 / 缩放 / 强停 / 媒体 / 通知栏")

        volumeView = mono("音量 -", 12f, 0xFF4FC3F7.toInt())
        screenView = mono("屏幕 -", 12f)
        mediaView = mono("媒体 -", 12f)
        zoomView = mono("缩放 -", 12f)
        forceStopView = mono("强停 -", 12f)
        notifView = mono("通知栏 -", 12f)

        col.addView(card(volumeView, screenView))
        col.addView(card(mediaView, zoomView))
        col.addView(card(forceStopView))
        col.addView(card(
            tv("通知栏", 12f, Color.WHITE),
            notifView,
            tv(
                "限制：第三方 App 无法可靠读取通知栏展开状态（需要无障碍/系统签名）。\n" +
                    "替代验证：展开通知栏后用截图或映射程序日志确认动作已注入。",
                11f,
                0xFF7C8B99.toInt(),
            ),
        ))
        return scroll(col)
    }

    // ---------------------------------------------------------------- 强停检测

    private fun sp() = getSharedPreferences("lifecycle", Context.MODE_PRIVATE)

    private fun markProcessStart() {
        // 若上次退出不是正常 onPause（比如被强停），marker 会留着
        val alive = sp().getBoolean("alive", false)
        val aliveAt = sp().getLong("alive_at", 0L)
        if (alive && aliveAt > 0) {
            CheckRegistry.pass("SYS.FORCESTOP", "上次未正常退出：${ProbeEvent.timeText(aliveAt)}")
        }
        sp().edit().putBoolean("alive", true)
            .putLong("alive_at", System.currentTimeMillis())
            .putLong("process_start", SystemClock.elapsedRealtime())
            .apply()
    }

    private fun lastForceStopText(): String {
        val alive = sp().getBoolean("alive", false)
        val aliveAt = sp().getLong("alive_at", 0L)
        val sb = StringBuilder()
        sb.append("本次进程启动：").append(ProbeEvent.timeText(System.currentTimeMillis())).append('\n')
        if (aliveAt > 0) {
            sb.append("上一次心跳：").append(ProbeEvent.timeText(aliveAt)).append('\n')
        }
        sb.append(
            if (alive) "判定：上次是正常退出（onPause 已清理）" else "判定：上次被强制终止（未见 onPause）",
        ).append('\n')
        sb.append("用法：让映射程序对前台应用执行「强停」，再打开本页看时间")
        return sb.toString()
    }

    // ---------------------------------------------------------------- 刷新

    private fun refresh() {
        val vol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val pct = if (max > 0) vol * 100 / max else 0
        if (lastVolume >= 0 && vol != lastVolume) {
            volumeHistory.add("${ProbeEvent.timeText(System.currentTimeMillis())} $lastVolume→$vol")
            while (volumeHistory.size > 8) volumeHistory.removeAt(0)
            CheckRegistry.pass("SYS.VOLUME", "音量 $lastVolume → $vol")
        }
        lastVolume = vol
        volumeView.text = "音量 %d%%（%d/%d）".format(pct, vol, max) +
            if (volumeHistory.isEmpty()) "" else "\n变化历史：\n" + volumeHistory.joinToString("\n")

        val interactive = pm.isInteractive
        if (lastInteractive != null && interactive != lastInteractive) {
            screenChangedAt = SystemClock.elapsedRealtime()
            CheckRegistry.pass("SYS.SCREEN", "状态变化 → ${if (interactive) "亮" else "灭"}")
        }
        lastInteractive = interactive
        screenView.text = "屏幕：${if (interactive) "亮" else "灭"}" +
            (if (screenChangedAt > 0) "  最近变化 ${(SystemClock.elapsedRealtime() - screenChangedAt) / 1000}s 前" else "") +
            "\n缩放注入：放大 $zoomIn 次 / 缩小 $zoomOut 次"
        zoomView.text = "缩放：Ctrl+Plus $zoomIn 次，Ctrl+Minus $zoomOut 次" +
            (if (zoomIn + zoomOut > 0) "\n（映射程序的缩放是注入组合键，这里能看到即为链路通）" else "\n（按 LT/RT 试试）")
        mediaView.text = "媒体：播放/暂停键 $mediaToggles 次" +
            "\n限制：曲目/会话状态需要 MediaSessionManager 的通知监听权限，未申请"
        forceStopView.text = lastForceStopText()
        notifView.text = "状态：未检测（权限不足）"
        if (zoomIn + zoomOut > 0) CheckRegistry.pass("SYS.ZOOM", "捕获到 ${zoomIn + zoomOut} 次缩放")
        if (mediaToggles > 0) CheckRegistry.pass("SYS.MEDIA", "捕获到 $mediaToggles 次媒体键")
        refreshOverlay()
    }

    override fun onProbeEvent(e: ProbeEvent) {
        if (e.src != Src.KEY || e.kind != "key-down") return
        when (e.extra["code"]?.toIntOrNull()) {
            android.view.KeyEvent.KEYCODE_PLUS -> zoomIn++
            android.view.KeyEvent.KEYCODE_MINUS -> zoomOut++
            android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> mediaToggles++
        }
    }

    override fun onResume() {
        super.onResume()
        handler.post(tick)
    }

    override fun onPause() {
        handler.removeCallbacks(tick)
        // 正常退出：清掉 marker，这样“被强停”才可区分
        sp().edit().putBoolean("alive", false).apply()
        super.onPause()
    }
}
