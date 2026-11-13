package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.ProbeBus
import com.dennis.padtest.core.Src
import java.io.File

/**
 * 一、链路自检页（启动页）。
 *
 * 三件事：
 * 1. 手柄识别：列出 InputManager 里的输入设备，标注是否识别到 Xbox 手柄；
 * 2. 注入可见性：最近一次收到 鼠标/滚轮/触摸/按键 的时间（确认 uinput → 系统 → 本 App 通路）；
 * 3. 权限/能力：root 是否可用、/dev/uinput 是否存在可写（只检测，不申请）。
 *
 * 每项给 PASS / FAIL / UNKNOWN 三态和原因；底部可进入其余测试页。
 */
class SelfCheckActivity : ProbeActivity() {

    private lateinit var reportView: TextView
    private lateinit var injectionView: TextView
    private lateinit var deviceView: TextView
    private val handler = Handler(Looper.getMainLooper())

    private val tick = object : Runnable {
        override fun run() {
            refreshInjection()
            refreshReport()
            handler.postDelayed(this, 500)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        CheckRegistry.define("LINK.DEVICES", "自检", "识别到手柄设备")
        CheckRegistry.define("LINK.INJECT", "自检", "注入事件可被接收")
        CheckRegistry.define("LINK.ROOT", "自检", "root 可用")
        CheckRegistry.define("LINK.UINPUT", "自检", "uinput 可写")
        super.onCreate(savedInstanceState)
    }

    override fun buildContent(): View {
        val col = page("链路自检", "先确认「手柄→映射→本 App」这条路是通的，再进各测试页")

        deviceView = mono("扫描中…", 11f)
        col.addView(card(tv("手柄识别", 13f, Color.WHITE), deviceView))

        injectionView = mono("等待事件…", 11f)
        col.addView(card(tv("注入可见性（最近事件）", 13f, Color.WHITE), injectionView))

        val rootState = tv(rootSummary(), 12f)
        col.addView(card(tv("权限 / 能力", 13f, Color.WHITE), rootState))

        reportView = mono("", 11f)
        col.addView(card(tv("自检结果", 13f, Color.WHITE), reportView))

        val nav = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        nav.addView(button("① 光标测试") { open("com.dennis.padtest.ui.CursorTestActivity") })
        nav.addView(button("② 滚动/滑动测试") { open("com.dennis.padtest.ui.ScrollTestActivity") })
        nav.addView(button("③ 按键测试") { open("com.dennis.padtest.ui.KeyTestActivity") })
        nav.addView(button("④ 系统动作测试") { open("com.dennis.padtest.ui.SystemTestActivity") })
        nav.addView(button("导出日志 (CSV)") { exportLog() })
        nav.addView(button("生成报告") { startActivity(android.content.Intent(this, ReportActivity::class.java)) })
        col.addView(card(tv("进入测试", 13f, Color.WHITE), nav))

        scanDevices()
        return scroll(col)
    }

    private fun open(cls: String) {
        startActivity(android.content.Intent().setClassName(this, cls))
    }

    private fun exportLog() {
        val f: File = com.dennis.padtest.core.Exporter.exportLogCsv(this)
        Log.i(ProbeBus.TAG, "exported ${f.absolutePath}")
        reportView.text = "已导出：\n${f.absolutePath}"
    }

    // ------------------------------------------------------------ 手柄识别

    private fun scanDevices() {
        val im = getSystemService(INPUT_SERVICE) as android.hardware.input.InputManager
        val ids = im.inputDeviceIds
        val sb = StringBuilder()
        var pads = 0
        for (id in ids) {
            val d = im.getInputDevice(id) ?: continue
            val sources = d.sources
            val isGamepad = (sources and android.view.InputDevice.SOURCE_GAMEPAD) != 0
            val isJoystick = (sources and android.view.InputDevice.SOURCE_JOYSTICK) != 0
            if (isGamepad || isJoystick) pads++
            if (isGamepad || isJoystick || d.name.contains("xbox", true) ||
                d.name.contains("gamepad", true) || d.name.contains("keyboard", true) ||
                d.name.contains("mouse", true) || d.name.contains("touch", true)
            ) {
                sb.append("[%d] %s\n     sources=0x%x%s%s\n".format(
                    id, d.name, sources,
                    if (isGamepad) " GAMEPAD" else "",
                    if (isJoystick) " JOYSTICK" else "",
                ))
                if (d.vendorId != 0) sb.append("     vid=0x%04x pid=0x%04x\n".format(d.vendorId, d.productId))
            }
        }
        if (sb.isEmpty()) sb.append("未发现输入设备\n")
        sb.append("\n手柄类设备数: ").append(pads)

        val xbox = im.inputDeviceIds.any { id ->
            val n = im.getInputDevice(id)?.name?.lowercase() ?: ""
            n.contains("xbox") || n.contains("microsoft") || n.contains("gamepad") || n.contains("wireless controller")
        }
        if (pads > 0 || xbox) {
            CheckRegistry.pass("LINK.DEVICES", "发现 $pads 个手柄类设备")
        } else {
            CheckRegistry.fail("LINK.DEVICES", "没有识别到 GAMEPAD/JOYSTICK 设备（可能被映射程序独占抓取，见限制说明）")
        }
        deviceView.text = sb.toString()

        // 说明：映射程序用 EVIOCGRAB 独占后，这里看不到手柄本身是正常的；
        // 真正的判据是「注入可见性」是否亮起来。
    }

    // ------------------------------------------------------------ 注入可见性

    private fun refreshInjection() {
        val now = SystemClock.elapsedRealtime()
        val sb = StringBuilder()
        for (s in listOf(Src.MOUSE, Src.WHEEL, Src.TOUCH, Src.KEY)) {
            val at = ProbeBus.lastEventAt(s)
            sb.append("%-4s %s\n".format(s.label, if (at == 0L) "未收到" else "%.1f 秒前".format((now - at) / 1000f)))
        }
        sb.append("\n事件总数: ").append(ProbeBus.count())
        injectionView.text = sb.toString()

        val any = ProbeBus.lastAnyEventAt()
        if (any > 0 && now - any < 30_000) {
            CheckRegistry.pass("LINK.INJECT", "最近 30s 内收到事件")
        } else if (any > 0) {
            CheckRegistry.unknown("LINK.INJECT", "有过事件但已超过 30s")
        } else {
            CheckRegistry.unknown("LINK.INJECT", "还没收到任何注入事件")
        }
    }

    // ------------------------------------------------------------ root / uinput

    private fun rootSummary(): String {
        val sb = StringBuilder()
        val suPaths = listOf("/system/bin/su", "/system/xbin/su", "/sbin/su", "/debug_ramdisk/su")
        val su = suPaths.firstOrNull { File(it).exists() }
        if (su != null) {
            CheckRegistry.pass("LINK.ROOT", "发现 $su")
            sb.append("root: 发现 ").append(su).append('\n')
        } else {
            CheckRegistry.unknown("LINK.ROOT", "本进程命名空间看不到 su（映射程序的 root 在别的命名空间，属正常）")
            sb.append("root: 未发现 su（App 不需要 root，仅展示）\n")
        }
        val uinput = File("/dev/uinput")
        val exists = uinput.exists()
        val canRead = uinput.canRead()
        sb.append("/dev/uinput: ").append(if (exists) "存在" else "不存在")
            .append("，可读=").append(canRead).append('\n')
        if (exists) {
            CheckRegistry.pass("LINK.UINPUT", "/dev/uinput 存在")
        } else {
            CheckRegistry.unknown("LINK.UINPUT", "/dev/uinput 不可见（应用沙箱内常见）")
        }
        sb.append("说明：注入是否成功不看这里，看上面的「注入可见性」")
        return sb.toString()
    }

    private fun refreshReport() {
        val (p, f, u) = CheckRegistry.counts()
        val sb = StringBuilder("通过 $p · 失败 $f · 未测 $u\n")
        for (c in CheckRegistry.all()) {
            sb.append(
                when (c.status) {
                    CheckRegistry.Status.PASS -> "[PASS] "
                    CheckRegistry.Status.FAIL -> "[FAIL] "
                    CheckRegistry.Status.UNKNOWN -> "[ -- ] "
                },
            )
            sb.append(c.title)
            if (c.reason.isNotEmpty()) sb.append(" —— ").append(c.reason)
            sb.append('\n')
        }
        reportView.text = sb.toString()
        refreshOverlay()
    }

    override fun onResume() {
        super.onResume()
        handler.removeCallbacks(tick)
        handler.post(tick)
    }

    override fun onPause() {
        handler.removeCallbacks(tick)
        super.onPause()
    }
}
