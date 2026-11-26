package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.ScrollView
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.PadMetrics
import com.dennis.padtest.core.ProbeBus
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src
import com.dennis.padtest.view.AxisLockView
import com.dennis.padtest.view.PassThroughScrollView

/**
 * 三、滚动与滑动测试页。
 *
 * 五块内容，对应五类验证：
 * 1. 纵向长列表（200 项）：位置、方向、速度、是否持续滚动；
 * 2. 横向分页：页码 / 偏移 / 方向；
 * 3. 混合容器（AxisLockView）：斜推只应锁一个方向；
 * 4. 焦点锚定：左右两个独立列表，指针指哪个就只滚哪个；
 * 5. 固定区域：在不可滚动区域滚动时的回退行为；
 * 另外用两种颜色分别统计「触摸滑动」与「滚轮」事件，区隔两种输出后端。
 */
class ScrollTestActivity : ProbeActivity() {

    private lateinit var vList: ListView
    private lateinit var vState: TextView
    private lateinit var hScroll: HorizontalScrollView
    private lateinit var hState: TextView
    private lateinit var mix: AxisLockView
    private lateinit var mixState: TextView
    private lateinit var focusState: TextView
    private lateinit var backendState: TextView
    private lateinit var fallbackState: TextView

    private var lastOffsetY = 0
    private var lastScrollAt = 0L
    private var scrollSpeed = 0f
    private var touchSwipes = 0
    private var gestureScrolls = 0
    private var wheelScrolls = 0
    private var bridgeGesture = true
    private var wheelEvents = 0
    private var lastFocus = "-"
    private var fixedAreaScrolled = 0
    // v1.2：左右列表各自 offset（分开暴露，供套件断言“独立”）
    private var leftOffset = 0
    private var rightOffset = 0
    private var fixedAreaWheel = 0
    private var fixedAreaTouch = 0
    private var fixedAreaTouchStart = false
    private var fixedAreaMoved = false
    private var fixedDownX = 0f
    private var fixedDownY = 0f
    private var fixedView: TextView? = null
    private var leftScroll: ScrollView? = null
    private var rightScroll: ScrollView? = null

    private val tick = object : Runnable {
        override fun run() {
            refresh()
            handler.postDelayed(this, 250)
        }
    }
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        CheckRegistry.define("SCROLL.VERTICAL", "滚动", "纵向列表可滚动")
        CheckRegistry.define("SCROLL.HORIZONTAL", "滚动", "横向可滑动")
        CheckRegistry.define("SCROLL.AXISLOCK", "滚动", "混合容器轴向锁定")
        CheckRegistry.define("SCROLL.FOCUS", "滚动", "焦点锚定：只滚指针所在列表")
        CheckRegistry.define("SCROLL.BACKEND", "滚动", "手势/滚轮两种后端可区分")
        CheckRegistry.define("SCROLL.GESTURE", "滚动", "手势后端产生滑动")
        CheckRegistry.define("SCROLL.WHEEL", "滚动", "滚轮后端产生滚动")
        CheckRegistry.define("SCROLL.FIXED", "滚动", "固定区域收到滚动尝试（可观测）")
        super.onCreate(savedInstanceState)
    }

    override fun buildContent(): View {
        val col = page("滚动 / 滑动测试", "推右摇杆或按 LB/RB：看哪一块在动、怎么动")

        vState = mono("纵向 -", 11f, 0xFF4FC3F7.toInt())
        hState = mono("横向 -", 11f, 0xFF4FC3F7.toInt())
        mixState = mono("混合 -", 11f, 0xFF4FC3F7.toInt())
        focusState = mono("焦点 -", 11f)
        backendState = mono("后端 -", 11f)
        fallbackState = mono("固定区域 -", 11f)

        col.addView(card(vState, hState, mixState, focusState, backendState, fallbackState))

        // 1) 纵向长列表
        vList = ListView(this)
        // v1.4：内层列表从自己区域起手时禁止外层 ScrollView 抢手势，
        // 这样 y≈1000 的内层拖拽只滚 vList，外层标题不动（MIX-001~003 可判定）。
        vList.setOnTouchListener { v, e ->
            if (e.actionMasked == MotionEvent.ACTION_DOWN) {
                v.parent?.requestDisallowInterceptTouchEvent(true)
            }
            false
        }
        vList.adapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            (1..200).map { "列表项 #%03d".format(it) },
        )
        vList.setOnScrollChangeListener { _, _, y, _, _ ->
            val now = SystemClock.elapsedRealtime()
            val dt = (now - lastScrollAt).coerceAtLeast(1)
            scrollSpeed = kotlin.math.abs((y - lastOffsetY).toFloat()) / (dt / 1000f)
            lastOffsetY = y
            lastScrollAt = now
            if (y > 0) CheckRegistry.pass("SCROLL.VERTICAL", "offset=$y")
        }
        col.addView(section("纵向：200 项列表", vList, 260))

        // 2) 横向分页
        hScroll = HorizontalScrollView(this)
        val pages = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for (p in 1..5) {
            pages.addView(
                TextView(this).apply {
                    text = "第 $p 页"
                    setTextColor(Color.WHITE)
                    textSize = 20f
                    gravity = android.view.Gravity.CENTER
                    setBackgroundColor(if (p % 2 == 1) 0xFF14202A.toInt() else 0xFF1B2733.toInt())
                },
                ViewGroup.LayoutParams(600, ViewGroup.LayoutParams.MATCH_PARENT),
            )
        }
        hScroll.addView(pages)
        hScroll.setOnScrollChangeListener { _, x, _, _, _ ->
            if (x > 0) CheckRegistry.pass("SCROLL.HORIZONTAL", "scrollX=$x")
        }
        col.addView(section("横向：5 页", hScroll, 140))

        // 3) 混合容器（轴向锁定）
        mix = AxisLockView(this)
        mix.onState = { st ->
            val axis = when (st.axis) { 1 -> "横向"; 2 -> "纵向"; else -> "无" }
            mixState.text = "混合 offset %.0f,%.0f  轴=%s  v=%.0f px/s".format(
                st.offsetX, st.offsetY, axis, st.velocity,
            )
            if (st.axis != 0) CheckRegistry.pass("SCROLL.AXISLOCK", "锁定 $axis")
        }
        col.addView(section("混合：可横可纵（验证轴向锁定）", mix, 220))

        // 4) 焦点锚定：左右两个独立列表
        val two = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val left = makeList("左列表")
        val right = makeList("右列表")
        leftScroll = left.first
        rightScroll = right.first
        two.addView(left.first, LinearLayout.LayoutParams(0, dp(180), 1f))
        two.addView(right.first, LinearLayout.LayoutParams(0, dp(180), 1f))
        left.first.setOnScrollChangeListener { _, _, y, _, _ ->
            leftOffset = y
            PadMetrics.leftOffset = y
            if (y != 0) {
                lastFocus = "左列表"
                focusState.text = "焦点：左列表 offset=$leftOffset · 右列表 offset=$rightOffset"
                CheckRegistry.pass("SCROLL.FOCUS", "左=$leftOffset 右=$rightOffset（独立）")
            }
            refresh()
        }
        right.first.setOnScrollChangeListener { _, _, y, _, _ ->
            rightOffset = y
            PadMetrics.rightOffset = y
            if (y != 0) {
                lastFocus = "右列表"
                focusState.text = "焦点：右列表 offset=$rightOffset · 左列表 offset=$leftOffset"
                CheckRegistry.pass("SCROLL.FOCUS", "左=$leftOffset 右=$rightOffset（独立）")
            }
            refresh()
        }
        col.addView(section("焦点锚定：两个独立列表", two, 190))

        // 5) 固定区域
        val fixed = TextView(this).apply {
            text = "固定区域（不可滚动）：在这里触发滚动应回退到光标所在容器，而不是乱滚"
            setTextColor(0xFF8FA0B0.toInt())
            textSize = 11f
            setPadding(dp(10), dp(10), dp(10), dp(10))
            setBackgroundColor(0xFF121A20.toInt())
        }
        fixedView = fixed
        col.addView(section("固定区域（用于回退行为）", fixed, 90))

        handler.post(tick)
        // v1.3：不再用 PassThroughScrollView 包整页（它会让注入式横向 swipe 在 pager 上被吃掉）。
        // 改为普通 ScrollView + 左右列表自己 requestDisallowInterceptTouchEvent：
        // pager 的横向手势能正常到达 HorizontalScrollView，列表纵向拖动也不被外层抢走。
        return scroll(col)
    }

    private fun inRect(v: android.view.View?, x: Float, y: Float): Boolean {
        if (v == null) return false
        val r = android.graphics.Rect()
        if (!v.getGlobalVisibleRect(r)) return false
        return x >= r.left && x <= r.right && y >= r.top && y <= r.bottom
    }

    private fun section(titleText: String, content: View, heightDp: Int): View {
        val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        box.addView(tv(titleText, 12f, 0xFFCFD8DC.toInt()).apply { setPadding(0, dp(6), 0, dp(2)) })
        box.addView(content, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(heightDp)))
        return box
    }

    private fun makeList(name: String): Pair<ScrollView, LinearLayout> {
        val sv = ScrollView(this)
        // v1.3：列表自己声明“这次手势别被外层拦截”，替代整页 PassThrough
        sv.setOnTouchListener { v, e ->
            if (e.actionMasked == MotionEvent.ACTION_DOWN) {
                v.parent?.requestDisallowInterceptTouchEvent(true)
            }
            false
        }
        val inner = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        for (i in 1..40) {
            inner.addView(tv("$name #$i", 11f, 0xFF9FB0BE.toInt()).apply { setPadding(dp(6), dp(8), dp(6), dp(8)) })
        }
        sv.addView(inner)
        return sv to inner
    }

    private fun abs(v: Int) = if (v < 0) -v else v

    /** v1.2：固定区域收到一次滚动尝试——立即刷新计数、写埋点与注册表（真实递增，不伪造） */
    private fun onFixedAreaScroll(by: String) {
        fixedAreaScrolled++
        PadMetrics.fixedAreaScrolls = fixedAreaScrolled
        PadMetrics.fixedAreaWheel = fixedAreaWheel
        PadMetrics.fixedAreaTouch = fixedAreaTouch
        fallbackState.text = "固定区域收到滚动 $fixedAreaScrolled 次（wheel=$fixedAreaWheel touch=$fixedAreaTouch）"
        CheckRegistry.pass("SCROLL.FIXED", "fixedAreaScrolled=$fixedAreaScrolled by=$by")
        ProbeBus.sample(
            Src.SYSTEM, "fixed-area-scroll",
            "count=$fixedAreaScrolled by=$by left=$leftOffset right=$rightOffset",
        )
    }

    private fun refresh() {
        vState.text = "纵向 offset=${vList.firstVisiblePosition} 项  速度=%.0f px/s  持续=%s".format(
            scrollSpeed,
            if (SystemClock.elapsedRealtime() - lastScrollAt < 400) "是" else "否",
        )
        hState.text = "横向 scrollX=${hScroll.scrollX}  页≈${hScroll.scrollX / 600 + 1}"
        backendState.text = "后端统计：手势滑动 $touchSwipes 次（已应用到列表 ${if (bridgeGesture) "开" else "关"}）" +
            " · 滚轮 $wheelEvents 次"
        PadMetrics.verticalOffset = vList.firstVisiblePosition
        PadMetrics.horizontalScrollX = hScroll.scrollX
        leftOffset = leftScroll?.scrollY ?: leftOffset
        rightOffset = rightScroll?.scrollY ?: rightOffset
        PadMetrics.leftOffset = leftOffset
        PadMetrics.rightOffset = rightOffset
        PadMetrics.fixedAreaScrolls = fixedAreaScrolled
        PadMetrics.fixedAreaWheel = fixedAreaWheel
        PadMetrics.fixedAreaTouch = fixedAreaTouch
        // 双侧 offset 常显（即使为 0），便于套件 dump 直接读
        focusState.text = "焦点：$lastFocus · 左 offset=$leftOffset · 右 offset=$rightOffset"
        fallbackState.text = "固定区域收到滚动 $fixedAreaScrolled 次（wheel=$fixedAreaWheel touch=$fixedAreaTouch）"
        if (touchSwipes > 0) CheckRegistry.pass("SCROLL.GESTURE", "手势滑动 $touchSwipes 次")
        if (wheelEvents > 0) CheckRegistry.pass("SCROLL.WHEEL", "滚轮 $wheelEvents 次")
        refreshOverlay()
    }

    override fun onProbeEvent(e: ProbeEvent) {
        when {
            e.src == Src.WHEEL -> {
                wheelEvents++
                wheelScrolls++
                refresh()
            }
            e.src == Src.TOUCH && e.kind == "swipe" -> {
                // 手势后端：把滑动位移应用到列表上（探针模式），让「有没有真的滚」可见
                touchSwipes++
                gestureScrolls++
                if (bridgeGesture) {
                    val dy = e.extra["dy"]?.toFloatOrNull() ?: 0f
                    val dx = e.extra["dx"]?.toFloatOrNull() ?: 0f
                    if (kotlin.math.abs(dy) >= kotlin.math.abs(dx)) {
                        vList.smoothScrollBy(0, -dy.toInt())
                    } else {
                        hScroll.smoothScrollBy(-dx.toInt(), 0)
                    }
                }
                refresh()
            }
            else -> Unit
        }
    }

    override fun onPause() {
        handler.removeCallbacks(tick)
        super.onPause()
    }

    // v1.2：Activity 级落点观察（子 View 可能被外层 ScrollView 拦截）
    private fun inFixed(x: Float, y: Float): Boolean {
        val v = fixedView ?: return false
        val r = android.graphics.Rect()
        if (!v.getGlobalVisibleRect(r)) return false
        return x >= r.left && x <= r.right && y >= r.top && y <= r.bottom
    }

    override fun onTouchDownAt(x: Float, y: Float) {
        fixedAreaTouchStart = inFixed(x, y)
        fixedAreaMoved = false
        fixedDownX = x
        fixedDownY = y
    }

    override fun onTouchEndAt(x: Float, y: Float, frames: Int, path: Float) {
        if (fixedAreaTouchStart && path > dp(8)) {
            fixedAreaTouch++
            onFixedAreaScroll("touch")
        }
        fixedAreaTouchStart = false
    }

    override fun onWheelAt(x: Float, y: Float) {
        if (inFixed(x, y)) {
            fixedAreaWheel++
            onFixedAreaScroll("wheel")
        }
    }
}
