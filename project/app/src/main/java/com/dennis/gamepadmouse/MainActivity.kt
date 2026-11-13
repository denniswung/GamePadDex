package com.dennis.gamepadmouse

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.text.InputType
import android.view.Display
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.CompoundButton
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import androidx.core.content.ContextCompat
import androidx.core.view.GravityCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.drawerlayout.widget.DrawerLayout
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.navigation.NavigationView
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Settings UI.
 *
 * One activity, one drawer, seven pages.  The pages are sibling containers
 * inside a single [ScrollView]; [showPage] makes exactly one of them VISIBLE -
 * the same trick the original app uses.
 *
 * Every value is written straight into [Prefs] (the same key names as the
 * original app), which is the only channel between this activity and
 * [MouseAccessibilityService].
 */
class MainActivity : AppCompatActivity() {

    private data class Page(val layoutId: Int, val titleRes: Int, val navId: Int)

    private lateinit var prefs: SharedPreferences
    private lateinit var drawer: DrawerLayout
    private lateinit var toolbar: MaterialToolbar
    private lateinit var navView: NavigationView
    private lateinit var pageScroll: ScrollView
    private lateinit var statusView: TextView

    private var currentPage = R.id.layout_settings_general
    private var mouseModeOn = false
    private var rootAvailable: Boolean? = null
    private var rootProbeOnce = false

    private val pages = listOf(
        Page(R.id.layout_initial_setup, R.string.page_initial_setup, R.id.nav_initial_setup),
        Page(R.id.layout_settings_general, R.string.general_settings, R.id.nav_general_settings),
        Page(R.id.layout_settings_pointer, R.string.pointer_sensitivity, R.id.nav_pointer_settings),
        Page(R.id.layout_root_dex, R.string.root_dex_settings, R.id.nav_root_dex),
        Page(R.id.layout_button_mapping, R.string.custom_key_mapping, R.id.nav_mapping),
        Page(R.id.layout_settings_keyboard, R.string.keyboard_settings, R.id.nav_keyboard_settings),
        Page(R.id.layout_about, R.string.about, R.id.nav_about),
    )

    private val mappingRowIds = linkedMapOf(
        "lb" to R.id.btn_map_x_lb,
        "rb" to R.id.btn_map_x_rb,
        "lt" to R.id.btn_map_x_lt,
        "rt" to R.id.btn_map_x_rt,
        "up" to R.id.btn_map_x_up,
        "down" to R.id.btn_map_x_down,
        "left" to R.id.btn_map_x_left,
        "right" to R.id.btn_map_x_right,
    )

    private val mappingValueIds = linkedMapOf(
        "lb" to R.id.tv_map_x_lb_val,
        "rb" to R.id.tv_map_x_rb_val,
        "lt" to R.id.tv_map_x_lt_val,
        "rt" to R.id.tv_map_x_rt_val,
        "up" to R.id.tv_map_x_up_val,
        "down" to R.id.tv_map_x_down_val,
        "left" to R.id.tv_map_x_left_val,
        "right" to R.id.tv_map_x_right_val,
    )

    /** the cursor-colour palette of the original app (36 entries, same order) */
    private val palette = listOf(
        "#F44336", "#E53935", "#B71C1C", "#FF8A80", "#8E0E4F", "#E91E63",
        "#F06292", "#F48FB1", "#9C27B0", "#CE93D8", "#4A148C", "#3F51B5",
        "#2196F3", "#1976D2", "#82B1FF", "#00BCD4", "#4DD0E1", "#006064",
        "#4CAF50", "#2E7D32", "#A5D6A7", "#00C853", "#FFEB3B", "#FBC02D",
        "#FFF176", "#F57F17", "#FFA000", "#FB8C00", "#FFB74D", "#E65100",
        "#795548", "#BCAAA4", "#FFFFFF", "#212121", "#9E9E9E", "#616161",
    )

    private val cursorPngPicker =
        registerForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
            if (uri != null) importCursorPng(uri)
        }

    private val stateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == MouseAccessibilityService.ACTION_STATE) {
                mouseModeOn = intent.getBooleanExtra(MouseAccessibilityService.EXTRA_MOUSE_ON, false)
                refreshStatus()
            }
        }
    }

    // ==================================================================== init

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // scripted entry point: am start -n <pkg>/.MainActivity -e action toggle|snap|debug
        if (handleIntentAction()) return

        prefs = Prefs.get(this)
        setContentView(R.layout.activity_main)

        drawer = findViewById(R.id.main)
        toolbar = findViewById(R.id.main_toolbar)
        navView = findViewById(R.id.nav_drawer)
        pageScroll = findViewById(R.id.page_scroll)
        statusView = findViewById(R.id.tv_status)

        // Android 15+ 强制 edge-to-edge: 不处理 insets 时工具栏会被状态栏压住
        val content = findViewById<android.view.View>(R.id.main_content)
        ViewCompat.setOnApplyWindowInsetsListener(content) { v, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        ViewCompat.requestApplyInsets(content)

        toolbar.setNavigationOnClickListener { drawer.openDrawer(GravityCompat.START) }
        findViewById<TextView>(R.id.tv_drawer_version).text =
            getString(R.string.app_version_format, versionName())

        navView.setNavigationItemSelectedListener { item ->
            val page = pages.firstOrNull { it.navId == item.itemId }
            if (page != null) {
                showPage(page.layoutId)
                true
            } else {
                false
            }
        }

        applyMappingDefaults()

        bindInitialSetupPage()
        bindGeneralPage()
        bindPointerPage()
        bindRootDexPage()
        bindMappingPage()
        bindKeyboardPage()
        bindAboutPage()

        refreshToggleKeyLabel()
        refreshMappingLabels()
        refreshCursorLabel()

        val requested = intent?.getStringExtra("open_page")
        val start = when {
            requested == "keyboard_settings" -> R.id.layout_settings_keyboard
            !prefs.getBoolean(Prefs.INITIAL_SETUP_SHOWN, false) -> R.id.layout_initial_setup
            else -> R.id.layout_settings_general
        }
        showPage(start)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getStringExtra("open_page") == "keyboard_settings") {
            showPage(R.id.layout_settings_keyboard)
        }
    }

    /** fullscreen switch: hide/show the status bar according to the pref */
    private fun applyStatusBar() {
        val hide = prefs.getBoolean(Prefs.HIDE_STATUSBAR, true)
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        if (hide) {
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.statusBars())
        } else {
            controller.show(WindowInsetsCompat.Type.statusBars())
        }
    }

    override fun onResume() {
        super.onResume()
        ContextCompat.registerReceiver(
            this,
            stateReceiver,
            IntentFilter(MouseAccessibilityService.ACTION_STATE),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        applyStatusBar()
        refreshStatus()
        probeRoot()
        refreshMappingLabels()
        refreshCursorLabel()
        refreshToggleKeyLabel()
    }

    override fun onPause() {
        try {
            unregisterReceiver(stateReceiver)
        } catch (_: Throwable) {
        }
        super.onPause()
    }

    /** @return true when this launch was only a scripted command and the activity is gone */
    private fun handleIntentAction(): Boolean {
        when (intent?.getStringExtra("action")) {
            "toggle" -> {
                sendBroadcast(Intent(MouseAccessibilityService.ACTION_TOGGLE).setPackage(packageName))
                finish()
                return true
            }

            "snap" -> {
                sendBroadcast(Intent(MouseAccessibilityService.ACTION_SNAP).setPackage(packageName))
                finish()
                return true
            }

            "debug" -> {
                val i = Intent(MouseAccessibilityService.ACTION_DEBUG).setPackage(packageName)
                val src = intent ?: return false
                if (src.hasExtra("mx")) i.putExtra("mx", src.getFloatExtra("mx", -1f))
                if (src.hasExtra("my")) i.putExtra("my", src.getFloatExtra("my", -1f))
                if (src.getBooleanExtra("double", false)) i.putExtra("double", true)
                sendBroadcast(i)
                finish()
                return true
            }
        }
        return false
    }

    // ============================================================ navigation

    private fun showPage(layoutId: Int) {
        val page = pages.firstOrNull { it.layoutId == layoutId } ?: pages[1]
        for (p in pages) {
            findViewById<View>(p.layoutId).visibility =
                if (p.layoutId == page.layoutId) View.VISIBLE else View.GONE
        }
        currentPage = page.layoutId
        toolbar.setTitle(page.titleRes)
        navView.setCheckedItem(page.navId)
        pageScroll.scrollTo(0, 0)
        drawer.closeDrawers()
        if (page.layoutId == R.id.layout_root_dex) {
            refreshStatus()
            probeRoot()
        }
    }

    // ========================================================= initial setup

    private fun bindInitialSetupPage() {
        findViewById<Button>(R.id.btn_open_settings).setOnClickListener {
            openAccessibilitySettings()
        }
        findViewById<Button>(R.id.btn_battery_optimization).setOnClickListener {
            requestIgnoreBatteryOptimizations()
        }
        findViewById<Button>(R.id.btn_accept_continue).setOnClickListener {
            prefs.edit().putBoolean(Prefs.INITIAL_SETUP_SHOWN, true).apply()
            toast(R.string.initial_setup_done)
            showPage(R.id.layout_settings_general)
        }
    }

    private fun openAccessibilitySettings() {
        try {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        } catch (t: Throwable) {
            toast("Cannot open accessibility settings: ${t.message}")
        }
    }

    @Suppress("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName"))
            )
        } catch (t: Throwable) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Throwable) {
                toast("Cannot open battery settings")
            }
        }
    }

    // =============================================================== general

    private fun bindGeneralPage() {
        bindSwitch(R.id.switch_mouse_enabled, Prefs.MOUSE_ENABLED, true)
        bindSwitch(R.id.switch_l3_toggle_enabled, Prefs.TOGGLE_ENABLED, true)
        bindSwitch(R.id.switch_swap_ab_buttons, Prefs.SWAP_AB, false)
        bindSwitch(R.id.switch_hide_statusbar, Prefs.HIDE_STATUSBAR, true) { applyStatusBar() }
        bindSwitch(R.id.switch_haptic_feedback, Prefs.HAPTIC, true)

        findViewById<View>(R.id.btn_customize_toggle_key).setOnClickListener {
            showToggleKeyDialog()
        }

        // long press duration: 0..10 in 100 ms steps, 0 = instant
        bindSeek(
            R.id.seekbar_l3_long_press, R.id.tv_l3_long_press_val,
            Prefs.L3_LONG_PRESS, 0, min = 0, step = 1, maxValue = 10,
        ) { v ->
            if (v == 0) getString(R.string.long_press_instant)
            else String.format(Locale.US, "%.1f", v / 10f) + getString(R.string.seconds_unit)
        }

        bindSeek(
            R.id.seekbar_vibration_intensity, R.id.tv_vibration_intensity_val,
            Prefs.VIBRATION, 255, min = 0, step = 1, maxValue = 255,
        ) { v -> v.toString() }

        findViewById<Button>(R.id.btn_reset_defaults).setOnClickListener {
            confirmReset()
        }
    }

    private fun showToggleKeyDialog() {
        val dialog = MaterialAlertDialogBuilder(this)
            .setTitle(R.string.press_gamepad_button_title)
            .setMessage(R.string.press_gamepad_button_msg)
            .setNeutralButton(R.string.reset_toggle_key_default) { _, _ ->
                prefs.edit().putInt(Prefs.TOGGLE_KEYCODE, 106).apply()
                refreshToggleKeyLabel()
            }
            .setNegativeButton(R.string.cancel, null)
            .create()

        dialog.setOnKeyListener { d, keyCode, event ->
            if (event.action != KeyEvent.ACTION_DOWN) return@setOnKeyListener false
            val blocked = intArrayOf(
                KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
                KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT,
                KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_CAMERA,
            )
            if (keyCode in blocked) {
                toast(R.string.toast_dpad_not_allowed)
                return@setOnKeyListener true
            }
            prefs.edit().putInt(Prefs.TOGGLE_KEYCODE, keyCode).apply()
            refreshToggleKeyLabel()
            d.dismiss()
            true
        }
        dialog.show()
    }

    private fun refreshToggleKeyLabel() {
        findViewById<TextView>(R.id.tv_current_toggle_key).text =
            keyCodeName(Prefs.toggleKeycode(prefs))
    }

    private fun keyCodeName(code: Int): String = when (code) {
        96 -> "Button A"
        97 -> "Button B"
        99 -> "Button X"
        100 -> "Button Y"
        102 -> "L1 (LB)"
        103 -> "R1 (RB)"
        104 -> "L2 (LT)"
        105 -> "R2 (RT)"
        106 -> "L3"
        107 -> "R3"
        108 -> "Start"
        109 -> "Select"
        110 -> "Mode (Xbox)"
        else -> KeyEvent.keyCodeToString(code)
            .removePrefix("KEYCODE_BUTTON_")
            .removePrefix("KEYCODE_")
    }

    private fun confirmReset() {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.reset_all_settings)
            .setMessage(R.string.reset_confirm_msg)
            .setPositiveButton(R.string.reset) { _, _ -> resetAllSettings() }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun resetAllSettings() {
        // the original keeps the cursor colour, language, first-run flags and the
        // activation-button toggle flag across a reset
        val keep = listOf(
            Prefs.CURSOR_COLOR, Prefs.LANGUAGE, Prefs.INITIAL_SETUP_SHOWN,
            Prefs.DRAWER_HINT_DONE, Prefs.TOGGLE_ENABLED,
        )
        val saved = LinkedHashMap<String, Any?>()
        for (k in keep) {
            if (prefs.contains(k)) saved[k] = prefs.all[k]
        }
        prefs.edit().clear().commit()
        val editor = prefs.edit()
        for ((k, v) in saved) {
            when (v) {
                is String -> editor.putString(k, v)
                is Boolean -> editor.putBoolean(k, v)
                is Int -> editor.putInt(k, v)
                is Long -> editor.putLong(k, v)
                is Float -> editor.putFloat(k, v)
            }
        }
        editor.commit()
        applyMappingDefaults()
        toast(R.string.settings_reset_toast)
        recreate()
    }

    private fun applyMappingDefaults() {
        val editor = prefs.edit()
        var dirty = false
        for ((slot, action) in Prefs.DEFAULT_MAPPING) {
            val key = Prefs.mappingType(slot)
            if (!prefs.contains(key)) {
                editor.putString(key, action)
                dirty = true
            }
        }
        if (dirty) editor.apply()
    }

    // =============================================================== pointer

    private fun bindPointerPage() {
        findViewById<View>(R.id.btn_select_cursor_style).setOnClickListener {
            showCursorStyleDialog()
        }

        bindSeek(
            R.id.seekbar_size, R.id.tv_size_val,
            Prefs.MOUSE_SIZE, 100, min = 40, step = 1, maxValue = 200,
        ) { v -> v.toString() }

        bindSeek(
            R.id.seekbar_speed, R.id.tv_speed_val,
            Prefs.MOUSE_SPEED, 50, min = 10, step = 1, maxValue = 200,
        ) { v -> v.toString() }

        bindSeek(
            R.id.seekbar_dex_speed, R.id.tv_dex_speed_val,
            Prefs.DEX_SPEED, 35, min = 10, step = 1, maxValue = 200,
        ) { v -> v.toString() }

        bindSeek(
            R.id.seekbar_sensitivity, R.id.tv_sensitivity_val,
            Prefs.SENSITIVITY, 20, min = 10, step = 1, maxValue = 30,
        ) { v -> String.format(Locale.US, "%.1f", v / 10f) }

        bindSeek(
            R.id.seekbar_scroll_speed, R.id.tv_scroll_speed_val,
            Prefs.SCROLL_SPEED, 100, min = 10, step = 1, maxValue = 400,
        ) { v -> v.toString() }

        bindSeek(
            R.id.seekbar_deadzone, R.id.tv_deadzone_val,
            Prefs.DEADZONE, 15, min = 1, step = 1, maxValue = 50,
        ) { v -> "$v%" }

        bindTimeoutSeek()
    }

    /** the auto-hide seek bar: 0 = never, otherwise 5..60 s (value = progress + 4) */
    private fun bindTimeoutSeek() {
        val bar = findViewById<SeekBar>(R.id.seekbar_timeout)
        val label = findViewById<TextView>(R.id.tv_timeout_val)
        bar.max = 56

        fun valueOf(progress: Int) = if (progress == 0) 0 else progress + 4
        fun progressOf(value: Int) = when {
            value <= 0 -> 0
            value < 5 -> 1
            else -> value - 4
        }.coerceIn(0, 56)

        bar.progress = progressOf(prefs.getInt(Prefs.MOUSE_TIMEOUT, 0))
        label.text = timeoutLabel(valueOf(bar.progress))
        bar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, progress: Int, fromUser: Boolean) {
                val v = valueOf(progress)
                label.text = timeoutLabel(v)
                prefs.edit().putInt(Prefs.MOUSE_TIMEOUT, v).apply()
            }

            override fun onStartTrackingTouch(sb: SeekBar?) = Unit
            override fun onStopTrackingTouch(sb: SeekBar?) = Unit
        })
    }

    private fun timeoutLabel(value: Int): String =
        if (value == 0) getString(R.string.never)
        else "$value" + getString(R.string.seconds_unit)

    // cursor style -------------------------------------------------------------

    private fun showCursorStyleDialog() {
        val items = arrayOf(
            getString(R.string.cursor_color_orange),
            getString(R.string.cursor_custom_color),
            getString(R.string.cursor_custom_png),
        )
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.cursor_style)
            .setItems(items) { _, which ->
                when (which) {
                    0 -> {
                        prefs.edit().putString(Prefs.CURSOR_STYLE, "orange").apply()
                        refreshCursorLabel()
                    }

                    1 -> showColorGrid()

                    else -> cursorPngPicker.launch("image/png")
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showColorGrid() {
        val current = normalizeColor(prefs.getString(Prefs.CURSOR_COLOR, "#FFA000") ?: "#FFA000")
            ?: "#FFA000"
        val density = resources.displayMetrics.density
        val pad = (12 * density).toInt()
        val cellHeight = (46 * density).toInt()
        val margin = (3 * density).toInt()
        val vPad = (10 * density).toInt()

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
        }

        var dialog: AlertDialog? = null

        // 36 colours + the "Type HEX" cell, five per row
        val cells: List<String?> = palette + listOf(null)
        for (rowCells in cells.chunked(5)) {
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (hex in rowCells) {
                val cell = TextView(this).apply {
                    gravity = Gravity.CENTER
                    textSize = 10f
                    setPadding(4, vPad, 4, vPad)
                }
                val lp = LinearLayout.LayoutParams(0, cellHeight, 1f)
                lp.setMargins(margin, margin, margin, margin)
                cell.layoutParams = lp
                if (hex == null) {
                    cell.setBackgroundColor(Color.parseColor("#E0E0E0"))
                    cell.setTextColor(Color.BLACK)
                    cell.text = getString(R.string.cursor_color_manual)
                    cell.setOnClickListener {
                        dialog?.dismiss()
                        showHexEntryDialog()
                    }
                } else {
                    val color = try {
                        Color.parseColor(hex)
                    } catch (t: Throwable) {
                        Color.GRAY
                    }
                    cell.setBackgroundColor(color)
                    val luma = 0.299f * Color.red(color) + 0.587f * Color.green(color) +
                        0.114f * Color.blue(color)
                    cell.setTextColor(if (luma < 140f) Color.WHITE else Color.BLACK)
                    cell.text = if (hex.equals(current, true)) "\u2713 $hex" else hex
                    cell.setOnClickListener {
                        applyCursorColor(hex)
                        dialog?.dismiss()
                    }
                }
                row.addView(cell)
            }
            container.addView(row)
        }

        val scroll = ScrollView(this).apply {
            isFillViewport = true
            addView(container)
        }

        dialog = MaterialAlertDialogBuilder(this)
            .setTitle(R.string.cursor_custom_color)
            .setView(scroll)
            .setNegativeButton(R.string.cancel, null)
            .create()
        dialog.show()
    }

    private fun showHexEntryDialog() {
        val density = resources.displayMetrics.density
        val input = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_TEXT
            hint = getString(R.string.cursor_color_hint)
            setText(prefs.getString(Prefs.CURSOR_COLOR, "#FFA000"))
            setSingleLine(true)
        }
        val wrapper = FrameLayout(this).apply {
            setPadding((16 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), 0)
            addView(input)
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.cursor_custom_color)
            .setView(wrapper)
            .setPositiveButton(R.string.ok) { _, _ ->
                val normalized = normalizeColor(input.text.toString())
                if (normalized == null) {
                    toast(R.string.cursor_color_invalid)
                } else {
                    applyCursorColor(normalized)
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun applyCursorColor(hex: String) {
        prefs.edit()
            .putString(Prefs.CURSOR_COLOR, hex)
            .putString(Prefs.CURSOR_STYLE, "custom_color")
            .apply()
        refreshCursorLabel()
    }

    /** accepts #RGB / #RRGGBB (with or without '#'), returns "#RRGGBB" or null */
    private fun normalizeColor(input: String): String? {
        val m = Regex("^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$").matchEntire(input.trim()) ?: return null
        var body = m.groupValues[1].uppercase(Locale.US)
        if (body.length == 3) {
            body = "" + body[0] + body[0] + body[1] + body[1] + body[2] + body[2]
        }
        return "#$body"
    }

    private fun refreshCursorLabel() {
        val style = prefs.getString(Prefs.CURSOR_STYLE, "orange") ?: "orange"
        val color = normalizeColor(prefs.getString(Prefs.CURSOR_COLOR, "#FFA000") ?: "#FFA000")
        var label: String

        when (style) {
            "custom_color" -> {
                if (color == null) {
                    prefs.edit().putString(Prefs.CURSOR_STYLE, "orange").apply()
                    label = getString(R.string.cursor_color_orange)
                } else {
                    prefs.edit().putString(Prefs.CURSOR_COLOR, color).apply()
                    label = getString(R.string.cursor_custom_color) + " ($color)"
                }
            }

            "custom" -> {
                val png = File(filesDir, "custom_cursor.png")
                if (png.exists() && png.length() > 0L) {
                    label = getString(R.string.cursor_custom_png)
                } else {
                    prefs.edit().putString(Prefs.CURSOR_STYLE, "orange").apply()
                    label = getString(R.string.cursor_color_orange)
                }
            }

            else -> label = getString(R.string.cursor_color_orange)
        }
        findViewById<TextView>(R.id.tv_current_cursor_style).text = label
    }

    private fun importCursorPng(uri: Uri) {
        try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                toast(R.string.cursor_png_load_failed)
                return
            }
            var sample = 1
            val longest = max(bounds.outWidth, bounds.outHeight)
            while (longest / (sample * 2) >= 512) sample *= 2

            val decodeOptions = BitmapFactory.Options().apply { inSampleSize = sample }
            val decoded = contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it, null, decodeOptions)
            }
            if (decoded == null) {
                toast(R.string.cursor_png_load_failed)
                return
            }
            val edge = max(decoded.width, decoded.height)
            val scaled = if (edge > 512) {
                val factor = 512f / edge
                Bitmap.createScaledBitmap(
                    decoded,
                    max(1, (decoded.width * factor).roundToInt()),
                    max(1, (decoded.height * factor).roundToInt()),
                    true,
                )
            } else {
                decoded
            }
            FileOutputStream(File(filesDir, "custom_cursor.png")).use { out ->
                scaled.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            if (scaled !== decoded) decoded.recycle()
            prefs.edit().putString(Prefs.CURSOR_STYLE, "custom").apply()
            refreshCursorLabel()
        } catch (t: Throwable) {
            toast(R.string.cursor_png_load_failed)
        }
    }

    // ============================================================== root / DeX

    private fun bindRootDexPage() {
        bindSwitch(R.id.switch_root_enabled, Prefs.ROOT_ENABLED, true)
        bindSwitch(R.id.switch_native_pointer, Prefs.NATIVE_POINTER, true)
        bindSwitch(R.id.switch_force_mirroring, Prefs.FORCE_MIRRORING, false)

        findViewById<Button>(R.id.btn_toggle_mouse_mode).setOnClickListener {
            sendBroadcast(Intent(MouseAccessibilityService.ACTION_TOGGLE).setPackage(packageName))
            toast(R.string.toggle_requested)
        }
    }

    private fun accessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, MouseAccessibilityService::class.java)
        val enabled = try {
            Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            )
        } catch (t: Throwable) {
            null
        } ?: return false
        return enabled.split(':').any { it.equals(expected.flattenToString(), true) } ||
            enabled.contains(packageName)
    }

    private fun activeDisplayIsDex(): Boolean {
        val desktopUiMode = try {
            resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK ==
                Configuration.UI_MODE_TYPE_DESK
        } catch (t: Throwable) {
            false
        }
        val externalOn = try {
            val dm = getSystemService(DisplayManager::class.java)
            dm.displays.any {
                it.displayId != Display.DEFAULT_DISPLAY && it.state == Display.STATE_ON
            }
        } catch (t: Throwable) {
            false
        }
        return desktopUiMode || externalOn
    }

    private fun probeRoot() {
        if (!prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {
            rootAvailable = false
            refreshStatus()
            return
        }
        if (rootAvailable == true || rootProbeOnce) {
            refreshStatus()
            return
        }
        rootProbeOnce = true
        Thread {
            val available = try {
                RootInput.hasRoot()
            } catch (t: Throwable) {
                false
            }
            runOnUiThread {
                rootAvailable = available
                refreshStatus()
            }
        }.apply { name = "gpm-root-probe" }.start()
    }

    private fun refreshStatus() {
        if (!::statusView.isInitialized) return
        val rootText = when (rootAvailable) {
            true -> getString(R.string.status_connected)
            false -> getString(R.string.status_not_connected)
            null -> getString(R.string.status_checking)
        }
        val text = buildString {
            append(getString(R.string.status_accessibility)).append(": ")
            append(
                getString(
                    if (accessibilityServiceEnabled()) R.string.status_enabled
                    else R.string.status_disabled
                )
            ).append('\n')
            append(getString(R.string.status_root)).append(": ")
            if (!prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {
                append(getString(R.string.status_disabled))
            } else {
                append(rootText)
            }
            append('\n')
            append(getString(R.string.status_display)).append(": ")
            append(
                getString(
                    if (activeDisplayIsDex()) R.string.status_display_dex
                    else R.string.status_display_phone
                )
            ).append('\n')
            append(getString(R.string.status_mouse_mode)).append(": ")
            append(
                getString(
                    if (mouseModeOn) R.string.status_on else R.string.status_off
                )
            )
        }
        statusView.text = text
    }

    // ========================================================= button mapping


    // ---------------- full-key + combo mapping UI ----------------
    private fun bindFullKeyMapping() {
        val anchor = findViewById<View>(R.id.btn_map_x_lb)
        val parent = anchor.parent as? LinearLayout ?: return
        parent.addView(uiSection(getString(R.string.full_key_mapping_title)))
        parent.addView(uiDesc(getString(R.string.full_key_mapping_hint)))
        for (name in Prefs.BUTTONS) {
            val row = uiRow(buttonLabel(name), actionLabel(prefs.getString(Prefs.btnType(name), "default") ?: "default"))
            row.tag = name
            row.setOnClickListener { showButtonActionPicker(name, row) }
            parent.addView(row)
        }
        parent.addView(uiSection(getString(R.string.combos_title)))
        for (i in 0 until Prefs.COMBO_COUNT) {
            val row = uiRow(comboLabel(i), comboActionLabel(i))
            row.tag = i
            row.setOnClickListener { showComboKeyPicker(i, row) }
            parent.addView(row)
        }
    }

    private fun buttonLabel(name: String): String = when (name) {
        "l3" -> "L3"; "r3" -> "R3"; "lb" -> "LB"; "rb" -> "RB"; "lt" -> "LT"; "rt" -> "RT"
        else -> name.uppercase(Locale.US)
    }

    private fun comboLabel(i: Int): String {
        val keys = prefs.getString(Prefs.comboKeys(i), "") ?: ""
        return getString(
            R.string.combo_row_format, i + 1,
            if (keys.isBlank()) getString(R.string.combo_empty) else keys.split("+").joinToString(" + ") { buttonLabel(it.trim()) }
        )
    }

    private fun comboActionLabel(i: Int): String {
        val t = prefs.getString(Prefs.comboType(i), "none") ?: "none"
        return if (t == "none" || t == "default") getString(R.string.action_none) else actionLabel(t)
    }

    private fun actionLabel(action: String): String = when (action) {
        "default" -> getString(R.string.action_default)
        "mouse_click" -> getString(R.string.action_click_location)   // reuse label
        "back" -> getString(R.string.action_home)
        "toggle_mouse" -> getString(R.string.mouse_service_enabled)
        "scroll_up", "scroll_down" -> getString(R.string.scroll_speed)
        "key_combo" -> getString(R.string.action_key_combo)
        "dex_fullscreen" -> getString(R.string.action_dex_fullscreen)
        else -> getString(actionLabelRes(action))
    }

    private fun uiSection(text: String): TextView = TextView(this, null, 0, R.style.GpmSection).apply {
        this.text = text
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(18) }
    }

    private fun uiDesc(text: String): TextView = TextView(this, null, 0, R.style.GpmDesc).apply {
        this.text = text
    }

    private fun uiRow(label: String, value: String): LinearLayout {
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL
        row.setPadding(0, dp(12), 0, dp(12))
        row.isClickable = true
        val l = TextView(this, null, 0, R.style.GpmLabel).apply { text = label }
        val v = TextView(this, null, 0, R.style.GpmValue).apply {
            text = value
            tag = "value"
        }
        row.addView(l, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(v, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ))
        return row
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun showButtonActionPicker(name: String, row: LinearLayout) {
        val actions = listOf("default") + Prefs.ACTIONS + Prefs.EXTRA_ACTIONS
        val labels = actions.map { actionLabel(it) }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(buttonLabel(name))
            .setItems(labels) { _, which ->
                prefs.edit().putString(Prefs.btnType(name), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = actionLabel(actions[which])
                if (actions[which] == "key_combo") askCombo(actions[which]) { combo ->
                    prefs.edit().putString(Prefs.btnValue(name), combo).apply()
                    (row.findViewWithTag<TextView>("value"))?.text = combo
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }


    private fun askCombo(action: String, onValue: (String) -> Unit) {
        val input = android.widget.EditText(this).apply {
            hint = "ctrl+alt+f"
            setText(prefs.getString(Prefs.btnValue("_last_combo"), "ctrl+alt+f") ?: "ctrl+alt+f")
            setPadding(dp(16), dp(8), dp(16), dp(8))
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.action_key_combo))
            .setView(input)
            .setPositiveButton(R.string.ok) { _, _ ->
                val v = input.text.toString().trim().lowercase(Locale.US)
                prefs.edit().putString(Prefs.btnValue("_last_combo"), v).apply()
                onValue(v)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showComboKeyPicker(i: Int, row: LinearLayout) {
        val names = Prefs.BUTTONS
        val labels = names.map { buttonLabel(it) }.toTypedArray()
        val existing = (prefs.getString(Prefs.comboKeys(i), "") ?: "").split("+")
        val checked = BooleanArray(names.size)
        for (idx in names.indices) {
            for (k in existing) {
                if (k.trim() == names[idx]) checked[idx] = true
            }
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.combo_keys_title))
            .setMultiChoiceItems(labels, checked) { _, which, isChecked -> checked[which] = isChecked }
            .setPositiveButton(R.string.ok) { _, _ ->
                val keys = names.filterIndexed { idx, _ -> checked[idx] }.joinToString("+")
                prefs.edit().putString(Prefs.comboKeys(i), keys).apply()
                val comboRow = row
                if (keys.isBlank()) {
                    prefs.edit().putString(Prefs.comboType(i), "none").apply()
                    (comboRow.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)
                } else {
                    showComboActionPicker(i, comboRow)
                }
                (comboRow.getChildAt(0) as TextView).text = comboLabel(i)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showComboActionPicker(i: Int, row: LinearLayout) {
        val actions = listOf("none") + Prefs.ACTIONS + Prefs.EXTRA_ACTIONS
        val labels = actions.map { actionLabel(it) }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(comboLabel(i))
            .setItems(labels) { _, which ->
                prefs.edit().putString(Prefs.comboType(i), actions[which]).apply()
                (row.findViewWithTag<TextView>("value"))?.text = comboActionLabel(i)
                if (actions[which] == "key_combo") askCombo(actions[which]) { combo ->
                    prefs.edit().putString(Prefs.comboValue(i), combo).apply()
                    (row.findViewWithTag<TextView>("value"))?.text = combo
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }


    private fun bindAlwaysGrab() {
        val sw = findViewById<androidx.appcompat.widget.SwitchCompat>(R.id.switch_always_grab)
        if (sw == null) return
        sw.isChecked = Prefs.alwaysGrab(prefs)
        sw.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean(Prefs.ALWAYS_GRAB, checked).apply()
            // apply immediately: grab now, or release if mouse mode is off
            runCatching { gpmService?.applyAlwaysGrab(checked) }
        }
    }

    private fun bindMappingPage() {
        bindFullKeyMapping()
        bindAlwaysGrab()
        for ((slot, rowId) in mappingRowIds) {
            findViewById<View>(rowId).setOnClickListener { showActionPicker(slot) }
            findViewById<View>(rowId).setOnLongClickListener {
                val type = prefs.getString(Prefs.mappingType(slot), "none") ?: "none"
                if (type == "click_location_repeat") {
                    showIntervalPicker(slot)
                } else {
                    toast("Only \"Repeat Click at Location\" rows have an interval")
                }
                true
            }
        }
    }

    private fun showActionPicker(slot: String) {
        val labels = Prefs.ACTIONS.map { getString(actionLabelRes(it)) }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.select_action_title, slot.uppercase(Locale.US)))
            .setItems(labels) { _, which -> onActionPicked(slot, Prefs.ACTIONS[which]) }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun actionLabelRes(action: String): Int = when (action) {
        "launch_app" -> R.string.action_launch_app
        "home" -> R.string.action_home
        "recents" -> R.string.action_recents
        "vol_up" -> R.string.action_vol_up
        "vol_down" -> R.string.action_vol_down
        "mute" -> R.string.action_mute
        "bright_up" -> R.string.action_bright_up
        "bright_down" -> R.string.action_bright_down
        "media_forward" -> R.string.action_media_forward
        "media_rewind" -> R.string.action_media_rewind
        "screenshot" -> R.string.action_screenshot
        "rotate" -> R.string.action_rotate
        "click_location" -> R.string.action_click_location
        "click_location_repeat" -> R.string.action_click_location_repeat
        else -> R.string.action_none
    }

    private fun onActionPicked(slot: String, action: String) {
        when (action) {
            "launch_app" -> pickApp(slot)

            "bright_up", "bright_down", "rotate" -> {
                if (!Settings.System.canWrite(this)) promptWriteSettings()
                saveAction(slot, action)
            }

            "click_location" -> {
                saveAction(slot, action, "")
                showGuide(
                    R.string.click_location_guide_title,
                    R.string.click_location_guide_msg,
                ) { }
            }

            "click_location_repeat" -> {
                val previous = prefs.getString(Prefs.mappingType(slot), "none") ?: "none"
                val previousValue = prefs.getString(Prefs.mappingValue(slot), "") ?: ""
                val keepValue = if (previous == "click_location_repeat") previousValue else ""
                saveAction(slot, action, keepValue)
                if (previous == "click_location_repeat") {
                    showIntervalPicker(slot)
                } else {
                    showGuide(
                        R.string.click_location_repeat_guide_title,
                        R.string.click_location_repeat_guide_msg,
                    ) { showIntervalPicker(slot) }
                }
            }

            else -> saveAction(slot, action)
        }
    }

    private fun saveAction(slot: String, action: String, value: String? = null) {
        val editor = prefs.edit().putString(Prefs.mappingType(slot), action)
        if (value != null) editor.putString(Prefs.mappingValue(slot), value)
        editor.apply()
        refreshMappingLabels()
    }

    private fun pickApp(slot: String) {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = try {
            pm.queryIntentActivities(intent, 0)
                .mapNotNull { info ->
                    val activityInfo = info.activityInfo ?: return@mapNotNull null
                    val label = activityInfo.loadLabel(pm)?.toString() ?: activityInfo.packageName
                    label to activityInfo.packageName
                }
                .distinctBy { it.second }
                .sortedBy { it.first.lowercase(Locale.US) }
        } catch (t: Throwable) {
            emptyList()
        }
        if (apps.isEmpty()) {
            toast(R.string.app_not_found)
            return
        }
        val labels = apps.map { it.first }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.select_app)
            .setItems(labels) { _, which ->
                saveAction(slot, "launch_app", apps[which].second)
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    /** brightness / rotation need Settings.System write access */
    private fun promptWriteSettings() {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.permission_required)
            .setMessage(R.string.brightness_permission_msg)
            .setPositiveButton(R.string.open_settings) { _, _ ->
                try {
                    startActivity(
                        Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                            .setData(Uri.parse("package:$packageName"))
                    )
                } catch (t: Throwable) {
                    toast("Cannot open settings: ${t.message}")
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showGuide(titleRes: Int, messageRes: Int, onOk: () -> Unit) {
        MaterialAlertDialogBuilder(this)
            .setTitle(titleRes)
            .setMessage(messageRes)
            .setPositiveButton(R.string.ok) { _, _ -> onOk() }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showIntervalPicker(slot: String) {
        val presets = intArrayOf(100, 200, 500, 1000, 2000, 3000)
        val current = prefs.getInt(Prefs.mappingInterval(slot), 500).coerceIn(100, 3000)
        val items = presets.map { String.format(Locale.US, getString(R.string.repeat_interval_format), it / 1000f) } +
            getString(R.string.repeat_interval_custom)
        val checkedIndex = presets.indexOf(current).let { if (it >= 0) it else presets.size }

        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.repeat_interval_title)
            .setSingleChoiceItems(items.toTypedArray(), checkedIndex) { dialog, which ->
                if (which < presets.size) {
                    setRepeatInterval(slot, presets[which])
                    dialog.dismiss()
                } else {
                    dialog.dismiss()
                    showCustomIntervalDialog(slot, current)
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showCustomIntervalDialog(slot: String, current: Int) {
        val density = resources.displayMetrics.density
        val input = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_NUMBER
            hint = getString(R.string.repeat_interval_hint)
            setText(current.toString())
            setSingleLine(true)
        }
        val wrapper = FrameLayout(this).apply {
            setPadding((16 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), 0)
            addView(input)
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.repeat_interval_title)
            .setView(wrapper)
            .setPositiveButton(R.string.ok) { _, _ ->
                val ms = input.text.toString().trim().toIntOrNull()
                if (ms == null || ms < 100 || ms > 3000) {
                    toast(R.string.repeat_interval_range_msg)
                } else {
                    setRepeatInterval(slot, ms)
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    /**
     * Stores the per-slot interval. [Prefs.REPEAT_INTERVAL] (the key
     * [ActionDispatcher] reads for the repeat-click action) is mirrored so the
     * service actually honours the value chosen here.
     */
    private fun setRepeatInterval(slot: String, ms: Int) {
        prefs.edit()
            .putInt(Prefs.mappingInterval(slot), ms)
            .putInt(Prefs.REPEAT_INTERVAL, ms)
            .apply()
        refreshMappingLabels()
        toast(getString(R.string.repeat_interval_saved, ms))
    }

    private fun refreshMappingLabels() {
        for ((slot, valueId) in mappingValueIds) {
            val type = prefs.getString(Prefs.mappingType(slot), "none") ?: "none"
            val value = prefs.getString(Prefs.mappingValue(slot), "") ?: ""
            findViewById<TextView>(valueId).text = mappingLabel(slot, type, value)
        }
    }

    private fun mappingLabel(slot: String, type: String, value: String): String {
        val suffix = if (value.isNotBlank()) " ($value)" else ""
        return when (type) {
            "none" -> getString(R.string.action_none)

            "launch_app" -> if (value.isBlank()) {
                getString(R.string.action_launch_app)
            } else {
                appLabel(value)
            }

            "click_location" -> getString(R.string.action_click_location) + suffix

            "click_location_repeat" -> {
                val interval = prefs.getInt(Prefs.mappingInterval(slot), 500)
                getString(R.string.action_click_location_repeat) +
                    " \u00b7 " +
                    String.format(Locale.US, getString(R.string.repeat_interval_format), interval / 1000f) +
                    suffix
            }

            else -> getString(actionLabelRes(type))
        }
    }

    private fun appLabel(pkg: String): String = try {
        val pm = packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    } catch (t: Throwable) {
        getString(R.string.app_not_found)
    }

    // ============================================================== keyboard

    private fun bindKeyboardPage() {
        bindSwitch(R.id.switch_keyboard_input, Prefs.KEYBOARD_ENABLED, true)
        bindSwitch(R.id.switch_kb_move_sound, Prefs.KB_MOVE_SOUND, false)

        bindLanguageCheck(R.id.cb_kb_lang_en, Prefs.KB_LANG_EN, true)
        bindLanguageCheck(R.id.cb_kb_lang_ko, Prefs.KB_LANG_KO, true)
        bindLanguageCheck(R.id.cb_kb_lang_es, Prefs.KB_LANG_ES, false)

        // 50..500 ms, step 10 (progress = (value - 50) / 10)
        bindSeek(
            R.id.seekbar_kb_repeat, R.id.tv_kb_repeat_val,
            Prefs.KB_NAV_INTERVAL, 150, min = 50, step = 10, maxValue = 500,
        ) { v -> String.format(Locale.US, "%.2f", v / 1000f) + getString(R.string.seconds_unit) }

        // 200..1500 ms, step 50 (progress = (value - 200) / 50)
        bindSeek(
            R.id.seekbar_kb_delay, R.id.tv_kb_delay_val,
            Prefs.KB_NAV_DELAY, 300, min = 200, step = 50, maxValue = 1500,
        ) { v -> String.format(Locale.US, "%.2f", v / 1000f) + getString(R.string.seconds_unit) }

        // 20..100 %, step 1
        bindSeek(
            R.id.seekbar_kb_dex_width, R.id.tv_kb_dex_width_val,
            Prefs.KB_DEX_WIDTH, 50, min = 20, step = 1, maxValue = 100,
        ) { v -> getString(R.string.kb_dex_pct_format, v) }

        // 40..200 %, step 5
        bindSeek(
            R.id.seekbar_kb_dex_height, R.id.tv_kb_dex_height_val,
            Prefs.KB_DEX_HEIGHT, 100, min = 40, step = 5, maxValue = 200,
        ) { v -> getString(R.string.kb_dex_pct_format, v) }

        val group = findViewById<RadioGroup>(R.id.rg_kb_dex_pos)
        when (prefs.getString(Prefs.KB_DEX_POS, "center")) {
            "left" -> group.check(R.id.rb_kb_dex_pos_left)
            "right" -> group.check(R.id.rb_kb_dex_pos_right)
            else -> group.check(R.id.rb_kb_dex_pos_center)
        }
        group.setOnCheckedChangeListener { _, checkedId ->
            val pos = when (checkedId) {
                R.id.rb_kb_dex_pos_left -> "left"
                R.id.rb_kb_dex_pos_right -> "right"
                else -> "center"
            }
            prefs.edit().putString(Prefs.KB_DEX_POS, pos).apply()
        }
    }

    /** at least one keyboard language has to stay selected */
    private fun bindLanguageCheck(id: Int, key: String, def: Boolean) {
        val box = findViewById<CheckBox>(id)
        box.isChecked = prefs.getBoolean(key, def)
        box.setOnCheckedChangeListener { view, checked ->
            if (!checked) {
                val others = listOf(
                    Prefs.KB_LANG_EN to R.id.cb_kb_lang_en,
                    Prefs.KB_LANG_KO to R.id.cb_kb_lang_ko,
                    Prefs.KB_LANG_ES to R.id.cb_kb_lang_es,
                ).filter { it.second != id }
                val anyOther = others.any { findViewById<CheckBox>(it.second).isChecked }
                if (!anyOther) {
                    (view as CompoundButton).isChecked = true
                    toast(R.string.kb_lang_min_toast)
                    return@setOnCheckedChangeListener
                }
            }
            prefs.edit().putBoolean(key, checked).apply()
        }
    }

    // ================================================================= about

    private fun bindAboutPage() {
        findViewById<TextView>(R.id.tv_about_version).text =
            getString(R.string.app_version_format, versionName())
        findViewById<Button>(R.id.btn_play_link).setOnClickListener {
            openOriginalListing()
        }
    }

    private fun openOriginalListing() {
        val url = "https://play.google.com/store/apps/details?id=com.pkyul13.gamepadmouse"
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        } catch (t: Throwable) {
            toast("Cannot open browser")
        }
    }

    private fun versionName(): String = try {
        packageManager.getPackageInfo(packageName, 0).versionName ?: ""
    } catch (t: Throwable) {
        ""
    }

    // =============================================================== helpers

    private fun bindSwitch(id: Int, key: String, def: Boolean, onChange: (() -> Unit)? = null) {
        val view = findViewById<SwitchCompat>(id)
        view.isChecked = prefs.getBoolean(key, def)
        view.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean(key, checked).apply()
            onChange?.invoke()
        }
    }

    /**
     * Binds a seek bar whose stored value is `min + progress * step`.
     * The label always shows the live value and every change is persisted.
     */
    private fun bindSeek(
        barId: Int,
        labelId: Int,
        key: String,
        def: Int,
        min: Int,
        step: Int,
        maxValue: Int,
        format: (Int) -> String,
    ) {
        val bar = findViewById<SeekBar>(barId)
        val label = findViewById<TextView>(labelId)
        val span = (maxValue - min) / step
        bar.max = span

        fun valueOf(progress: Int) = min + progress * step
        fun progressOf(value: Int) = ((value - min) / step).coerceIn(0, span)

        bar.progress = progressOf(prefs.getInt(key, def))
        label.text = format(valueOf(bar.progress))

        bar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, progress: Int, fromUser: Boolean) {
                val value = valueOf(progress)
                label.text = format(value)
                prefs.edit().putInt(key, value).apply()
            }

            override fun onStartTrackingTouch(sb: SeekBar?) = Unit
            override fun onStopTrackingTouch(sb: SeekBar?) = Unit
        })
    }

    private fun toast(messageRes: Int) {
        Toast.makeText(this, messageRes, Toast.LENGTH_SHORT).show()
    }

    private fun toast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
}
