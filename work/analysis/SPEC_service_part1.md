# Gamepad Mouse v2.0.2 — `MouseAccessibilityService` spec, PART 1 (lines 1–2060)

Scope: `work/decompile/pkyul13_sources/gamepadmouse/MouseAccessibilityService.java`, lines **1–2060**.
Everything outside that range is referenced only as a *callee* (its own part covers it).

**Citation convention**: `MouseAccessibilityService.java:NNNN` = a line in the decompiled Java file above.
Because jadx destroyed the control flow of `m2127C` (the decompiler itself emits
"Code decompiled incorrectly" warnings at `MouseAccessibilityService.java:1208-1245`), that one method was
additionally cross-checked against the real bytecode:
`apktool d base.apk` → `smali/com/pkyul13/gamepadmouse/MouseAccessibilityService.smali`,
method `C(Landroid/view/KeyEvent;)Z` (smali lines 5110–8950).
Where the smali contradicts jadx, **the smali reading is used** and the jadx artefact is called out.
Never trust the literal `if (z19)` / `? true : true` shapes in `MouseAccessibilityService.java:1325-1330`
and `MouseAccessibilityService.java:1943-1957` — they are decompiler debris (see §5.3).

Helper classes live in package `p000` and are **not** part of this file; they are cited by file name only
(`p000/s60.java` = the 10 delayed repeat runnables, `p000/n60.java` = one-shot UI runnables, `p000/o60.java` =
the double-tap-to-type detector, `p000/q60.java` = global-action / toast runnables, `p000/t60.java` = the
joystick `onGenericMotionEvent` handler that produces the stick axes).

---

## 1. Class shape

`public final class MouseAccessibilityService extends AccessibilityService` (`MouseAccessibilityService.java:128`).

* One instance per accessibility-service connection; it owns **three floating windows per display**:
  1. a per-display invisible/1-px **focus-holder view** stored in `f4175p` (`displayId -> View`),
  2. the **mouse cursor** `ImageView` `f4172o`,
  3. the **on-screen keyboard** overlay (`f4091F0` container + `f4088E0` widget) used when
     "keyboard mode" (`f4082C0`) is on.
* All key input arrives through `onKeyEvent` (`:4185-4275`, outside scope); it forwards to `m2127C` **only** for
  gamepad-sourced events while mouse mode is on (`:4271`), see §5.0.
* Cursor motion is driven by a 16 ms `Handler` loop (`f4107K1`, an `s60` with id 6 — `MouseAccessibilityService.java:574`);
  the analog sticks write `f4099I/f4102J` (left, cursor) and `f4105K/f4108L` (right, scroll).

---

## 2. Field table

All declarations are grouped at `MouseAccessibilityService.java:128-576`; defaults either come from the field
initializer (shown with its line) or from `loadPrefs()` at `MouseAccessibilityService.java:4291-4376`
(that loader is outside part 1 but is the only writer of the "pref" fields, so it is cited here to make the
defaults meaningful — the *key strings* are quoted verbatim from it).

Legend: `—` = no initializer, JVM default (`false` / `0` / `null`).

| Obf. field | Type | Default (line) | Inferred meaning | Key evidence |
|---|---|---|---|---|
| `f4074Q1` | static int | 0 (`:131`) | R8 `$r8$classId` placeholder; read only as a discarded no-op (`:2664`, `:2668`, `:2739`, `:2743`) | `:131` |
| `f4076A0` | boolean | false | "system window-menu action node was found & clicked" latch | `:2619`, `:2638`, `:3213` |
| `f4077A1` | `s60` id 0 | — (`:137`) | runnable: validator for the legacy dpad-hold "mode 1" (dead path, see §5.5) | `:564`, `s60.java` case 0 |
| `f4079B0` | long | 0 | timestamp of the last acted-on event; also the 500 ms throttle for the brightness toast | `:2620`, `:2639`, `:3078-3080`, `:3214` |
| `f4080B1` | `s60` id 8 | — (`:143`) | runnable: keyboard word-delete / line-jump auto-repeat | `:565`, `s60.java` case 8 |
| `f4082C0` | boolean | false | **keyboard (text-entry overlay) mode active** | `:723`, `:1283`, `:2056`, `:3735` |
| `f4083C1` | `s60` id 7 | — (`:149`) | runnable: release-validator of the id-8 repeat group | `:566`, `s60.java` case 7 |
| `f4085D0` | boolean | true (`:550`) | pref `pref_keyboard_enabled` — master switch for keyboard mode / double-tap-to-type | `:1611`, `:4346` |
| `f4086D1` | `s60` id 5 | — (`:155`) | runnable: **backspace auto-repeat** (110 ms) | `:567`, `:1485`, `s60.java` case 5 |
| `f4087E` | boolean | false | `BATTERY_CHANGED` receiver (`f4093G`) currently registered | `:158`, `:2016-2018`, `:3039-3041` |
| `f4088E0` | `C1059yy` | null | on-screen **keyboard widget** (setLang / setAccentPending / `m9199f` selected key) | `:1336`, `:2408`, `:2815-2825` |
| `f4089E1` | `s60` id 2 | — (`:164`) | runnable: **key auto-repeat** of the highlighted key (110 ms) | `:568`, `:1332`, `s60.java` case 2 |
| `f4090F` | boolean | false (`:4299`) | pref `pref_force_mirroring` — allow DeX displays even if Pro/mirroring | `:3332`, `:3531` |
| `f4091F0` | `v60` | null | keyboard overlay **container** view | `:2409`, `:2848`, `:3744` |
| `f4092F1` | `r60` id 1 | — (`:173`) | `BroadcastReceiver` for `ACTION_SCREEN_OFF` | `:569`, `:4387`, `:4130` |
| `f4093G` | `r60` id 0 | — (`:176`) | `BroadcastReceiver` for `ACTION_BATTERY_CHANGED` (clock in blackout overlay) | `:536`, `:3040`, `:2017` |
| `f4094G0` | WindowManager | null | WindowManager used for the keyboard overlay | `:2410`, `:3748-3757` |
| `f4095G1` | `u60` | — (`:182`) | `DisplayListener` | `:570`, `:4384-4386` |
| `f4097H0` | AccessibilityNodeInfo | null | **currently targeted editable node** (cursor position) | `:1464`, `:2503`, `:3900` |
| `f4098H1` | `j20` | — (`:188`) | `OnSharedPreferenceChangeListener` | `:571`, `:4290`, `:4135` |
| `f4099I` | float | 0 | **left stick X** in −1..1 (producer: `p000/t60.java`, normalised with dead-zone/pow); cleared here on mouse-off `:785` | `:785` |
| `f4100I0` | `C0575lv` | — (`:551`) | text composer buffer (string, cursor index, pending accent) | `:1358`, `:2057-2074` |
| `f4101I1` | Map | 10 entries (`:572`) | color name → hex map (`orange`→`#FFA000`, `blue`, `green`, `red`, `black`, `white`, `purple`, `cyan`, `pink`, `yellow`) | `:572`, `:3803` |
| `f4102J` | float | 0 | **left stick Y** in −1..1 (producer: `p000/t60.java`); cleared here on mouse-off `:786` | `:786` |
| `f4103J0` | `C0950w` | — (`:552`) | accent-pending state holder (`f17376a` = 0/1/2 shown on keyboard) | `:2125-2130`, `:3129-3153` |
| `f4104J1` | ExecutorService | single thread (`:573`) | background executor for screenshot save | `:3419`, `:4761` |
| `f4105K` | float | 0 | **right stick X** (scroll direction/magnitude; producer `p000/t60.java`); cleared on mouse-off `:787` | `:787`, `:2459` |
| `f4106K0` | `EnumC0985wy` | `.n` (`:553`) | current **keyboard language** (en/ko/es) | `:1408`, `:3445-3451` |
| `f4107K1` | `s60` id 6 | — (`:574`) | runnable: **16 ms cursor/gesture loop** | `:574`, `:4141`, `s60.java` case 6 |
| `f4108L` | float | 0 | **right stick Y** (scroll; producer `p000/t60.java`); cleared on mouse-off `:788` | `:788`, `:2460` |
| `f4109L0` | boolean | true (`:554`) | pref `pref_kb_lang_en` | `:4349`, `:4532` |
| `f4110L1` | `s60` id 9 | — (`:224`) | runnable: **repeat-click timer** | `:575`, `:3319`, `s60.java` case 9 |
| `f4111M` | SharedPreferences | null | `GamepadMousePrefs` store | `:1184`, `:4287-4289` |
| `f4112M0` | boolean | true (`:555`) | pref `pref_kb_lang_ko` | `:4352`, `:4537` |
| `f4113M1` | AccessibilityNodeInfo | null | candidate editable node found under the cursor, pending the 310 ms "open keyboard" commit (written by `p000/o60.java` + `p000/n60.java` case 10) | `:233`, `:3736-3743` |
| `f4115N0` | boolean | false (`:4355`) | pref `pref_kb_lang_es` | `:4540` |
| `f4116N1` | float | 0 | X where `f4113M1` was found (written by `p000/o60.java`) | `:239` |
| `f4118O0` | long | 150 (`:556`) | pref `pref_kb_nav_interval` — caret-repeat interval | `:4357`, `s60.java` case 1/4/8 |
| `f4119O1` | float | 0 | Y where `f4113M1` was found (written by `p000/o60.java`) | `:245` |
| `f4120P` | int | 100 (`:506`) | pref `pref_mouse_size` — cursor size in px (×0.4 on non-primary display) | `:742-744`, `:3945-3951` |
| `f4121P0` | long | 300 (`:557`) | pref `pref_kb_nav_delay` — hold delay before caret repeat | `:3108`, `:4359` |
| `f4122P1` | Rect | null | screen bounds of the field the last IME action targeted (detects field change) | `:2544`, `n60.java` case 1 |
| `f4124Q0` | boolean | false (`:4362`) | pref `pref_kb_move_sound` — keyboard move tick on/off | `:2357`, `:2777` |
| `f4126R0` | int | 50 (`:558`) | pref `pref_kb_dex_width` | `:4365` |
| `f4128S0` | int | 100 (`:559`) | pref `pref_kb_dex_height` | `:4368` |
| `f4130T0` | String | `"center"` (`:560`) | pref `pref_kb_dex_pos` | `:4372` |
| `f4131U` | boolean | false (`:4296`) | pref `pref_dex_lockscreen_enabled` | `:3719` |
| `f4132U0` | ToneGenerator | null | fallback beep when SoundPool fails | `:2796-2807`, `:4118-4122` |
| `f4133V` | int | 0 (`:4311`) | pref `pref_mouse_timeout` — seconds of idle before mouse mode auto-off | `:4311`, `s60.java` case 6 |
| `f4134V0` | boolean | false | secondary shift/caps state (toggled by on-screen keyboard key #5, cleared by `m2149b`; enters the uppercase test in `m2139Q`) | `:2144`, `:2817`, `:3772` |
| `f4135W` | String | `"orange"` (`:521`) | pref `pref_cursor_style` (`orange`/`custom`/`custom_color`) | `:3803-3868` |
| `f4136W0` | boolean | false | **shift active** (L2 in keyboard mode) | `:1415-1426`, `:3773` |
| `f4137X` | String | `"#FFA000"` (`:524`) | pref `pref_cursor_color` | `:3805`, `:3264` |
| `f4138X0` | boolean | false | **symbol/number layer active** (THUMBL in keyboard mode) | `:1448`, `:2822` |
| `f4139Y` | Bitmap | null | cached cursor bitmap | `:3264-3267`, `:3305` |
| `f4140Y0` | long | 0 | timestamp of the last ENTER key (350 ms throttle) | `:1438-1439` |
| `f4141Z` | String | null | color the cached bitmap `f4139Y` was rendered with | `:3264`, `:3306` |
| `f4142Z0` | float | 0 | center X of the field that owns the keyboard | `:2521`, `:4116` |
| `f4143a0` | long | `currentTimeMillis()` (`:527`) | last user-interaction timestamp (idle timeout base) | `:2911`, `s60.java` case 6 |
| `f4144a1` | float | 0 | center Y of that field | `:2521`, `:4119` |
| `f4145b0` | boolean | false | **cursor is visible** | `:779`, `:807`, `:1413` |
| `f4146b1` | long | 0 | legacy "last dpad action" timestamp — **never written in the whole app**, so the guard `now-f4146b1>120` at `:1393` is always true | `:302`, `:1393` |
| `f4147c0` | boolean | false | **drag gesture in progress** (left button held/dragging) | `:1614-1616`, `:1624` |
| `f4148c1` | int | 0 | keyboard-mode dpad cursor X (grid step) | `:2422`, `s60.java` case 4 |
| `f4149d0` | boolean | false | left-button **"press pending"** (down seen, not yet resolved to click or drag) | `:1608-1621` |
| `f4150d1` | int | 0 | keyboard-mode dpad cursor Y | `:2423` |
| `f4151e0` | long | 0 | time of the pending press (250 ms long-press test) | `:1621-1622` |
| `f4152e1` | int | 0 | keyboard-mode stick nav step counter | `:2473` |
| `f4153f0` | float[2] | `new float[2]` (`:530`) | last drag point `{x,y}` | `:3163-3165`, `:3237-3239`, `:4011` |
| `f4154f1` | long | 0 | keyboard stick-nav timestamp | `:2476` |
| `f4155g0` | `GestureDescription.StrokeDescription` | null | the **live drag stroke** being continued every frame | `:3167`, `:3242`, `:3999` |
| `f4156g1` | boolean | false | keyboard stick-nav active | `:2477` |
| `f4157h0` | long | 0 | earliest time the drag stroke may be continued (40 ms pacing) | `:4001`, `:4022` |
| `f4158h1` | float | 0 | keyboard stick-nav magnitude | `:2478`, `s60.java` case 4 |
| `f4159i0` | boolean | false | a smooth-scroll gesture is currently in flight | `:789`, `:2447`, `:2470` |
| `f4160i1` | boolean | false | X-button **repeat active** (backspace) | `:1488`, `:1495` |
| `f4161j0` | `w60` | `new w60(this)` if SDK≥26 (`:539-544`) | `GestureResultCallback` for the scroll gesture | `:2467` |
| `f4162j1` | boolean | false | A-button **repeat active** (key autorepeat) | `:1335`, `:1346` |
| `f4163k0` | boolean | false | **MOUSE MODE ACTIVE** (the master state; also gates what `m2127C` consumes) | `:737`, `:1283`, `:1528`, `:1584` |
| `f4164k1` | int | 0 | last dpad **horizontal** dir (−1/0/+1) held for repeat | `:3092`, `:1386` |
| `f4165l0` | boolean | false | **unused** (only the declaration exists in the decompiled app) | `:356` |
| `f4166l1` | int | 0 | last dpad **vertical** dir (−1/0/+1) | `:3093`, `:1387` |
| `f4167m0` | boolean | true (`:545`) | pref `pref_l3_toggle_enabled` — L3/THUMBL toggles mouse mode | `:4314`, `:1529`, `:1542` |
| `f4168m1` | int | 0 | dpad-hold mode: 0 = none, **2 = caret/arrow repeat** (mode 1 exists only in dead code) | `:3094`, `:3430` |
| `f4169n` | WindowManager | null | WindowManager for the **cursor** window | `:3887`, `:3953` |
| `f4170n0` | int | 106 (`:546`) | pref `pref_toggle_keycode` — key that turns mouse mode **on** (106 = THUMBL) | `:4317`, `:1512` |
| `f4171n1` | boolean | false | dpad hold active | `:3095`, `:3431` |
| `f4172o` | ImageView | null | **the cursor view** | `:780-812`, `:3889` |
| `f4173o0` | boolean | false (`:4320`) | pref `pref_swap_ab_buttons` — **swap A/B** | `:1325`, `:1591` |
| `f4174o1` | long | 0 | mode-1 dpad-hold timestamp (dead path) | `:3096`, `:3432` |
| `f4175p` | `LinkedHashMap` | empty (`:479`) | `displayId(Integer) -> focus-holder View` | `:815-845`, `:3719` |
| `f4176p0` | int | 0 (`:4327`) | pref `pref_l3_long_press_duration` (×100 ms) for "hold L3 to enable mouse" | `:4219-4220` |
| `f4177p1` | long | 0 | timestamp of the last dpad **down** accepted | `:3098`, `:1393` |
| `f4178q` | FrameLayout | null | black-screen / lockscreen overlay | `:2010-2050`, `:3704` |
| `f4179q0` | boolean | false | "wake-key long press pending" | `:4230-4243` |
| `f4180q1` | long | 0 | timestamp of the last dpad event (mode-2 stale check, 1000 ms) | `:3097-3100`, `s60.java` case 1 |
| `f4181r` | `WindowManager.LayoutParams` | null | layout params of the cursor window | `:3882-3889` |
| `f4182r0` | long | 0 | time of the last dispatched gesture | `:3160`, `:4503` |
| `f4183r1` | int | 0 | keyboard-mode word-delete counter | `:3508`, `s60.java` case 8 |
| `f4184s` | `PowerManager.WakeLock` | null | keep-screen-on lock (3000 ms acquires) | `:2036-2043` |
| `f4185s0` | Handler | main looper (`:547`) | handler for the wake-key long-press timer | `:4228` |
| `f4186s1` | int | 0 | keyboard-mode line-jump counter | `:3509` |
| `f4187t` | long | 0 | time of the last mapped action (300 ms debounce in `m2179v`) | `:4624-4629` |
| `f4188t0` | `n60` id 0 | — (`:548`) | runnable: enable mouse mode (fired after the L3 long press) | `:4227`, `n60.java` case 0 |
| `f4189t1` | boolean | false | keyboard repeat group active | `:3510` |
| `f4190u` | String | null | repeat-click target mapping name | `:3313-3318`, `s60.java` default |
| `f4191u0` | boolean | false | **X button held** = "mapped-action modifier" | `:1939`, `:1664`, `:1693` |
| `f4192u1` | long | 0 | keyboard repeat group timestamp | `:3511` |
| `f4193v` | long | 500 (`:482`) | repeat-click interval in ms | `:4879`, `s60.java` default |
| `f4194v0` | HashSet | empty (`:549`) | keycodes currently held as mapped buttons | `:1661`, `:3966`, `:796` |
| `f4195v1` | SoundPool | null | keyboard move-tick SoundPool (max 2 streams) | `:4581`, `:4123-4127` |
| `f4196w` | DisplayManager | null | display manager | `:4383`, `:3530` |
| `f4197w0` | boolean | false | **unused** | `:446` |
| `f4198w1` | int | 0 | SoundPool sound id of the move tick | `:4592`, `:2783` |
| `f4199x` | Display | null | **active display** (0 = phone, else DeX/external) | `:729`, `:1103`, `:3540` |
| `f4200x0` | boolean | false | **unused** | `:455` |
| `f4201x1` | `s60` id 4 | — (`:561`) | runnable: keyboard stick-cursor repeat | `:3479` |
| `f4202y` | Context | null | cached context | `:2360` |
| `f4203y0` | float | 0 | **unused** | `:464` |
| `f4204y1` | `s60` id 3 | — (`:562`) | runnable: validator of the id-4 group | `:3482` |
| `f4205z` | boolean | false | force the **primary (phone) display** instead of DeX (R3 toggle) | `:1893`, `:3541` |
| `f4206z0` | float | 0 | **unused** | `:473` |
| `f4207z1` | `s60` id 1 | — (`:563`) | runnable: **dpad hold → caret repeat** driver | `:3106`, `:3433` |
| `f4075A` | float | 500.0 (`:485`) | **cursor X** (px) | `:774`, `:3884` |
| `f4078B` | float | 1000.0 (`:488`) | **cursor Y** (px) | `:775`, `:3885` |
| `f4081C` | int | 1080 (`:491`) | **screen width** | `:754`, `:3884` |
| `f4084D` | int | 2400 (`:494`) | **screen height** | `:767`, `:3885` |
| `f4096H` | Handler | main looper (`:497`) | primary handler for every animation/repeat | `:1281`, `:1341` |
| `f4114N` | float | 50.0 (`:500`) | pref `pref_mouse_speed` (px per frame on display 0) | `:4301` |
| `f4117O` | float | 30.0 (`:503`) | pref `pref_dex_speed` (px per frame on DeX) | `:4303` |
| `f4123Q` | float | 1.5 (`:509`) | pref `pref_mouse_sensitivity / 10` → **effective default 2.0** (pref default 20) | `:4308` |
| `f4125R` | float | 2.0 (`:512`) | pref `pref_scroll_speed / 50` → 2.0 (pref default 100) | `:2456`, `:4322` |
| `f4127S` | float | 0.15 (`:515`) | pref `pref_deadzone / 100` → 0.15 | `:4324` |
| `f4129T` | boolean | true (`:518`) | pref `pref_mouse_enabled` — the whole feature switch | `:4293`, `:726`, `:784` |

---

## 3. Constructor (`MouseAccessibilityService.java:533-576`)

1. `f4093G = new r60(this, 0)` — battery receiver (`:536`).
2. `f4161j0 = SDK_INT>=26 ? new w60(this) : null` — gesture callback (`:539-544`).
3. `f4167m0 = true`, `f4170n0 = 106` (`:545-546`) — L3 toggle defaults.
4. `f4185s0 = new Handler(main)`, `f4188t0 = new n60(this,0)`, `f4194v0 = new HashSet()` (`:547-549`).
5. `f4085D0 = true`, `f4106K0 = EnumC0985wy.n`, `f4109L0 = f4112M0 = true`,
   `f4118O0 = 150`, `f4121P0 = 300`, `f4126R0 = 50`, `f4128S0 = 100`, `f4130T0 = "center"` (`:550-560`).
6. All 10 `s60` runnables are created with **fixed ids** (`:561-575`) — the id is the `switch` selector in
   `p000/s60.java`, so the ids are part of the contract:

   | field | s60 id | posted by | delay | body (from `s60.java`) |
   |---|---|---|---|---|
   | `f4077A1` | 0 | (removed only, never posted in this version) | – | validates a legacy dpad "mode 1" hold |
   | `f4207z1` | 1 | `m2148a0` (`:3108`) | `f4121P0` = 300 ms | caret repeat every `f4118O0` = 150 ms; stops after 1000 ms of no dpad event |
   | `f4089E1` | 2 | `m2127C` (`:1342`) | 400 ms | re-applies the highlighted key every 110 ms while `f4162j1` |
   | `f4204y1` | 3 | (removed only) | – | release-validator for stick nav |
   | `f4201x1` | 4 | `m2161i`/onCreate | – | stick cursor move + `m2138P`, interval `f4118O0` (×2 if `f4158h1<0.9`) |
   | `f4086D1` | 5 | `m2127C` (`:1491`) | 400 ms | backspace every 110 ms while `f4160i1` |
   | `f4107K1` | 6 | self-reposting | 16 ms | the cursor/gesture main loop (movement, drag, idle timeout) |
   | `f4083C1` | 7 | (removed only) | – | release-validator for the id-8 group |
   | `f4080B1` | 8 | keyboard mode | – | word delete (`m2172o0`) / line jump, interval `2*f4118O0` |
   | `f4110L1` | 9 | repeat-click start | `f4193v` = 500 ms | taps the stored mapping location |

7. `f4092F1 = new r60(this,1)`, `f4095G1 = new u60(this)`, `f4098H1 = new j20(this,1)` (`:569-571`).
8. `f4101I1` = the 10-entry color map (`:572`), `f4104J1` = single-thread executor (`:573`).

---

## 4. Method table (lines 1–2060)

| Method | Line | Purpose | Exact behaviour |
|---|---|---|---|
| `static boolean m2114F(node)` | `:579` | "is this node an editable text field?" | Returns `false` for `isPassword()` (`:582`), returns `true` if any `AccessibilityAction` id == **2097152** (`ACTION_SET_TEXT`, `:592`), else `true` iff class name ends-with/contains `EditText`, `AutoCompleteTextView` or `TextInputEditText` (`:604-609`); any exception ⇒ `false` (`:610`). |
| `static String m2115O(node)` | `:622` | seed text for the keyboard buffer | Reads `getText()`; on API≥31 also `getHintText()` + `isShowingHintText()` + `getContentDescription()`. Returns the text **only if** it is non-empty, the hint is not being shown, and it differs from the hint and from the content description (`:651-653`); otherwise `""` (`:628`, `:672-674`). Always logs `Keyboard seed: …` (`:661`). |
| `static void m2116T(View,int displayId)` | `:687` | request focus for the overlay of a display | `Log.d("Requesting focus for display: N")` then `view.post(new RunnableC0591ma(view,1))` (`:688-689`). |
| `static void m2117X(svc, boolean enable, boolean keepBlackout, int mask)` | `:693` | **turn mouse mode ON/OFF and re-wire every overlay window** | Full algorithm in §5.1. |
| `static byte[] m2118e()` | `:873` | synthesize the keyboard "move tick" WAV in memory | 3748 samples @44100 Hz mono 16-bit (`:875-896`): frequency ramp `1180 − (1−e^(−t/0.005))·260` Hz (`:880`), 3 ms attack, 17 ms exp decay (`:881-885`), waveform `(sin(2φ)·0.32 + sin φ)·0.5·env`, clamped to ±1 (`:886-891`). Wrapped in a RIFF/WAVE header (`:897-917`); `m2119f` writes little-endian u32 (`:924-926`). Returned length 7540. |
| `static final void m2119f(out,int)` | `:924` | write LE int32 | `{b, b>>8, b>>16, 0}` — 4 bytes, top byte forced 0 (`:925`). |
| `static void m2120k(node,ArrayList out)` | `:929` | collect focused editable nodes (post-order) | Recurses all children first (`:931-942`), recycling children not kept (`:935-940`), then appends `node` iff `m2114F(node) && node.isFocused()` (`:943-945`). |
| `static Bitmap m2121o(File)` | `:949` | decode a downscaled custom cursor bitmap | Two-pass `BitmapFactory`: bounds → power-of-two `inSampleSize` while both halves stay ≥512 (`:955-961`), decode (`:964`), then scale so the longer side ≤ **512** (`:966-975`); recycles intermediates; `null` on failure (`:978-980`). |
| `static AccessibilityNodeInfo m2122w(node,String text)` | `:984` | find first **clickable** node whose text/description contains `text` | `isClickable()` and (`contentDescription` or `text` `contains`, case-insensitive via `ek0.m2910T(str,needle,true)`) (`:1000`); DFS otherwise (`:1003-1013`). |
| `static AccessibilityNodeInfo m2123x(node,List labels)` | `:1019` | find first **clickable ancestor** of a node whose contentDescription matches a label | lowercases `contentDescription` (`:1025`), compares with `ek0.m2909S` (`:1038`), then walks parents until `isClickable()` (`:1040-1047`); DFS (`:1052-1062`). |
| `static AccessibilityNodeInfo m2124z(node,float x,float y,float tol)` | `:1068` | hit-test editable fields with tolerance | DFS children first; for editable nodes returns the node whose screen bounds **expanded by `tol`** contain (x,y) (`:1083-1085`). |
| `AccessibilityNodeInfo m2125A(float x,float y)` | `:1098` | nearest editable node within 700 px, on the active display | Enumerates windows of the active display (`getWindowsOnAllDisplays()` on API≥30, else `getWindows()`, `:1110-1121`), keeps only `TYPE_APPLICATION` (`:1127`), collects focused editable nodes via `m2120k` (`:1129`), computes the rectangle **distance** `hypot(dx,dy)` (`:1136-1160`) and keeps the minimum with `hypot ≤ 700.0` (`:1161`); recycles the loser (`:1162-1172`). |
| `String m2126B(int resId, Object… args)` | `:1183` | localized string with a per-app language override | Opens `GamepadMousePrefs` (`:1184`), falls back to `ko`/`es` if the system language is one of them, else `en` (`:1185-1188`), then overrides from pref `pref_language` (`:1189-1192`), builds a configuration-scoped context (`:1193-1196`) and calls `getString` (with `Arrays.copyOf` for args) (`:1197-1204`). |
| **`boolean m2127C(KeyEvent)`** | `:1250` | **the whole gamepad key router** | §5. |
| `void m2128D(ScreenshotResult,Display,String stage)` | `:1964` | save an accessibility screenshot | Wraps the `HardwareBuffer` → `Bitmap` (`:1970-1973`), closes the buffer, converts `HARDWARE`→`ARGB_8888` (`:1976-1983`), logs stage/size (`:1987`), saves via `m2143V` and posts the result back on the main handler (`:1989-1991`). On **any** exception logs and falls back to `performGlobalAction(9)` = take-screenshot (`:1997-2000`). |
| `void m2129E()` | `:2004` | hide the blackout overlay + restore brightness/wakelock | If the overlay exists and is visible: disable it, unregister the battery receiver, and animate alpha→0 over **200 ms** with an end-action that hides it (`:2010-2021`). When mouse mode is off it also resets `screenBrightness` to `-1` (`:2022-2034`) and re-acquires the wakelock for **3000 ms** (`:2035-2045`). When mouse mode is on it fades the cursor **in** over 200 ms (`:2047-2049`). |
| `void m2130G()` | `:2054` | backspace / delete one unit in the composer | Outside scope beyond `:2077`; the visible part shows it first clears a pending accent (`f9701e`), then pending composed char, then the undo buffer, then deletes the char before the cursor (`:2058-2074`) and commits via `m2166l()`. |

---

## 5. `m2127C(KeyEvent)` — complete decision list

Signature `public final boolean m2127C(KeyEvent keyEvent)` at `MouseAccessibilityService.java:1250`.
Return value semantics: **`true` = the event is consumed** (the system/app never sees it),
**`false` = let the event through**.

### 5.0 When is `m2127C` even called? (critical wiring fact, `:4271`)

`onKeyEvent` is the only caller, and its last line is

```java
if (!z || !this.f4163k0 || !m2127C(keyEvent)) return super.onKeyEvent(keyEvent);
return true;
```

(`MouseAccessibilityService.java:4271-4274`) where `z` = the event source is a **gamepad/joystick**
(`(source & 1025) == 1025 || (source & 16777232) == 16777232`, `:4199-4203`).
Consequences for the decision list below:

* `m2127C` is **only entered while mouse mode is ON** (`f4163k0 == true`) and the event came from a gamepad.
  ⇒ **BLOCK B** therefore only ever runs as `f4163k0 == true && f4082C0 == false`.
* Everything inside `m2127C` that can only happen with `f4163k0 == false` is **dead code** in this build:
  B1 ("enter mouse mode" `:1527-1541`), B5 (`:1584-1586`), and the `!f4163k0` guards scattered through
  §5.2. Mouse mode is entered elsewhere: `onKeyEvent` `:4225-4247` (L3 long press ⇒ `n60` id 0) and
  `:4249-4264` (plain L3/MODE ⇒ `m2117X(this,true,false,6)`); MODE/L3 release still exits through **B2**.
* When `m2127C` returns `false`, the key is handed to `super.onKeyEvent` (`:4272`), i.e. it goes to whatever
  currently has input focus.

Preamble:

| # | Condition | Effect | |
|---|---|---|---|
| 0 | `keyCode == 4` (BACK) | **`return false`** — never consumed here | `:1277-1279` |
| 0b | local `z15` = (`action==0 && repeatCount==0`) | "fresh key-down" flag used by nearly every branch | `:1286-1290` |
| — | Branch on `f4163k0 && f4082C0` | both mouse mode **and** keyboard mode ⇒ **BLOCK A** (`:1283`), else **BLOCK B** (`:1511`) | |

### 5.1 BLOCK A — mouse mode + keyboard mode (`:1283-1510`)

Order of evaluation, first match wins. `A-ish` = `keyCode == (f4173o0 ? 97 : 96)`, `B-ish` = `keyCode == (f4173o0 ? 96 : 97)`
(`MouseAccessibilityService.java:1325-1330`; verified in smali at `:cond_9`–`:goto_5` — jadx's `if (z19)`
wrapper is bogus, the real condition is the A/Ish test).

| # | Keycode | Guard | Effect | Return |
|---|---|---|---|---|
| A0 | (dead) 4 | — | `m2163j(true)` — unreachable, the preamble already returned | `:1291-1295` |
| A1 | any | — | `m2142U()`: set `f4143a0 = now`; if the active display is 0 also `m2129E()` (hide blackout) | `:1297`, `:2909-2917` |
| A2 | **108** (START) | `action == 0` | haptic **50 ms** iff pref `pref_haptic_feedback` (default true); `m2135L(2)` = re-focus the display's overlay (`m2116T`), `m2160h0()` wake tap, then **GLOBAL_ACTION_HOME** after 80 ms (`:2476-2490` + `p000/q60.java`) | `true` (`:1298-1310`) |
| A3 | **109** (SELECT) | `action == 0` | haptic 50 ms; `m2135L(3)` = same prologue then **GLOBAL_ACTION_RECENTS** | `true` (`:1311-1323`) |
| A4 | **A-ish (96/97)** | `z15 && !f4162j1` | `f4162j1 = true`; take the highlighted key from the keyboard widget (`f4088E0.m9199f()`), apply it with `m2132I`; `removeCallbacks(f4089E1)` then `postDelayed(f4089E1, 400)` ⇒ **key autorepeat: first at 400 ms, then every 110 ms** | `true` (`:1331-1344`) |
| A5 | A-ish | `action == 1` | `f4162j1 = false`; cancel the repeat | `true` (`:1345-1349`) |
| A6 | A-ish | `action == 2/3/…` | nothing (falls through to the final `return true`) | `true` |
| A7 | **B-ish (97/96)** | `action == 0` | `m2163j(true)` — **close the keyboard overlay**, keep mouse mode | `true` (`:1350-1354`) |
| A8 | **67** (DEL) | `action == 0` | `m2130G()` — delete one character/unit | `true` (`:1505-1507`) |
| A9 | **110** (MODE) | `action == 0` | `m2163j(false)` (close keyboard) **and** `m2117X(this,false,false,6)` (**exit mouse mode**) | `true` (`:1500-1503`) |
| A10 | **99** (X) | `z15` | `f4160i1 = true`; `m2130G()`; cancel+post `f4086D1` after **400 ms** ⇒ **backspace autorepeat first at 400 ms then every 110 ms** | `true` (`:1485-1492`) |
| A11 | 99 | `action == 1` | `f4160i1 = false`; cancel repeat | `true` (`:1494-1497`) |
| A12 | **100** (Y) | `z15` | append `' '` to the composer (`f4100I0.m5202c(' ')`) and commit (`m2166l()`) | `true` (`:1479-1483`) |
| A13 | **19/20/21/22** (dpad) | any | Compute `h`: LEFT(21) = −1, RIGHT(22) = +1, else 0; `v`: UP(19) = −1, DOWN(20) = +1, else 0 (`:1365-1381`). **UP:** `f4180q1 = now`; if `f4168m1 == 2 && h == f4164k1 && v == f4166l1` ⇒ `m2157g()` (release the hold) `:1384-1389`. **DOWN:** `f4180q1 = now`; only if `now − f4177p1 > 120` **and** `now − f4146b1 > 120` **and** (direction changed **or** no hold active) ⇒ `m2148a0(h, v, 2)` `:1392-1396`. Otherwise the event is swallowed (anti-driver-repeat). `m2148a0` stores the direction, sets `f4171n1 = true`, does one immediate caret move `m2131H(h,v)` and schedules the repeat after `f4121P0` = **300 ms** (`:3091-3109`) | `true` either way |
| A14 | **102** (L1) | `z15` | `m2158g0()` — cycle to the next enabled keyboard language | `true` (`:1401-1405`) |
| A15 | **103** (R1) | `z15 && f4106K0 == EnumC0985wy.p` | `m2149b()` — accent/long-press vowel handling | `true` (`:1407-1411`) |
| A16 | **104** (L2) | `action == 1 && f4136W0` | `f4136W0 = false` (shift released); `m2139Q()` repaint | `true` (`:1413-1418`) |
| A17 | 104 | `action == 0 && repeatCount == 0 && !f4136W0` | `f4136W0 = true` (shift latched); `m2139Q()`; haptic **30 ms** iff pref | `true` (`:1419-1432`) |
| A18 | **105** (R2) | `z15 && now − f4140Y0 ≥ 350` | `f4140Y0 = now`; `m2136M()` = **ENTER / IME action**, throttled to one per **350 ms** | `true` (`:1435-1443`) |
| A19 | **106** (THUMBL) | `z15` | if `f4082C0` toggle the symbol layer `f4138X0 ^= 1` and `m2139Q()`; haptic 50 ms | `true` (`:1445-1461`) |
| A20 | **107** (THUMBR) | `z15 && m2166l() && f4097H0 != null` | `performAction(131072 /*ACTION_SET_SELECTION*/, {0, len})` = **select all**, `m2138P()` (tick sound), then `m2163j(true)` (close keyboard) | `true` (`:1463-1476`) |
| A21 | anything else | — | falls to the method tail | `true` (`:1960`) |

### 5.2 BLOCK B — mouse mode on, keyboard mode off (`:1511-1959`)

(A mouse-mode-**off** entry is impossible; see §5.0. In this build BLOCK B is the normal "mouse-only" router,
and B1/B5 below are vestigial.)

Pre-computed booleans (`:1512-1526`): `z1 = keyCode == f4170n0`, `z2 = keyCode == 106`, `z3 = keyCode == 110`.

| # | Condition | Effect | Return |
|---|---|---|---|
| B1 | `z15` and **mouse mode off** and ((`z1 && f4167m0`) \|\| `z3`) | haptic 50 ms; `m2117X(this,true,false,6)` = **ENTER mouse mode**; `m2142U()` — *dead code in this build*, see §5.0 | `true` (`:1527-1541`) |
| B2 | `z15` and **mouse mode on** and ((`z2 && f4167m0`) \|\| `z3`) | haptic 50 ms; `m2117X(this,false,false,6)` = **EXIT mouse mode** | `true` (`:1542-1553`) |
| B3 | **108** (START), `action == 0` | haptic 50 ms; `Log "Performing HOME action (Start Button)"`; `m2135L(2)` → HOME after 80 ms. Same effect as A2 — duplicated because the two blocks do not share code | `true` (`:1555-1568`) |
| B4 | **109** (SELECT), `action == 0` | haptic 50 ms; `Log "Performing RECENTS action (Select Button)"`; `m2135L(3)` (= A3) | `true` (`:1569-1582`) |
| B5 | `!f4163k0` | nothing — *unreachable in this build* (§5.0) | **`false`** (`:1584-1586`) |
| B6 | any | `m2142U()`; `Log.i("Key Event: code=… (NAME), action=…")` | `:1587-1590` |
| B7 | **A-ish** (`:1591-1627`) | **left mouse button**: see §5.4 | `true` |
| B8 | **B-ish** (`:1628-1657`) | **BACK**: iff `action==0 && f4163k0`: haptic 50 ms, `Log "Performing BACK action"`, then for **every** focus-holder view in `f4175p`: `lp.flags \|= 8` (FLAG_NOT_FOCUSABLE), `updateViewLayout`, `clearFocus()` (`:1636-1650`), then `postDelayed(n60(this,4), 50)` — which after 50 ms runs `m2135L(1)` = **GLOBAL_ACTION_BACK** and after another 250 ms clears flag 8 again and `requestFocus()` | `true` (`:1628-1657`) |
| B9 | **99** (X) (`:1933-1940`) | `f4191u0 = (action == 0)` — **X is the mapped-action modifier** | `true` while in mouse mode |
| B10 | **100** (Y) (`:1904-1926`) | iff `f4163k0`: haptic on key-down, then `AudioManager.dispatchMediaKeyEvent(KeyEvent(action==0?0:1, 85))` = **PLAY/PAUSE** | `true` |
| B11 | **107** (THUMBR / R3) (`:1885-1903`) | iff `action==0`: `db0.m2408b()` (Pro?) ⇒ haptic, `Log "R3 Pressed - Toggling Active Display"`, `f4205z ^= 1`, `m2162i0()`; else `Log "…Pro Feature Restricted"` + `post(n60(this,5))` = "Pro required" toast | `true` |
| B12 | **19/20** (dpad up/down) (`:1663-1690`) | iff `action==0 && f4163k0 && f4191u0` ⇒ `m2179v("up"/"down", repeatCount>0)`; otherwise **swallowed with no action** | `true` |
| B13 | **21** (LEFT) (`:1691-1720`) | if `f4191u0`: on down `f4194v0.add(21)` + `m2179v("left", repeat)`; on up `f4194v0.remove(21)`. Else if `m2168m(21,action)` (already in the held set) swallow. Else `dispatchMediaKeyEvent(KeyEvent(action, 89))` = **REWIND** | `true` |
| B14 | **22** (RIGHT) (`:1721-1750`) | same shape with `"right"` / media key **90** = **FAST_FORWARD** | `true` |
| B15 | **102** (L1) (`:1753-1793`) | if `f4191u0`: `"lb"` mapped action; else haptic-on-down + media key **88** = **MEDIA_PREVIOUS** | `true` |
| B16 | **103** (R1) (`:1794-1834`) | if `f4191u0`: `"rb"`; else media key **87** = **MEDIA_NEXT** | `true` |
| B17 | **104** (L2) (`:1835-1858`) | iff `action==0 && f4163k0`: if `f4191u0` ⇒ `m2179v("lt", repeat)`; else haptic + `Log "LT Pressed - Windowed Mode / Restore"` + `m2137N(false)` | `true` |
| B18 | **105** (R2) (`:1859-1882`) | iff `action==0 && f4163k0`: if `f4191u0` ⇒ `m2179v("rt", repeat)`; else haptic + `Log "RT Pressed - Maximize/Restore Window"` + `m2137N(true)` | `true` |
| B19 | anything else | final gate: `if (!f4163k0) return false; if (keyCode == 106 && !f4167m0) return false;` | `true` (`:1927-1932`) |

Notes:
* `m2179v(name, isRepeat)` (`:4613`) is **Pro-gated** and **debounced to 300 ms** (`:4624-4628`), reads
  `pref_mapping_x_<name>_type` / `_value` and ignores auto-repeat for `click_location_repeat` (`:4640-4643`).
* `m2168m(keyCode, action)` (`:3964-3974`) = "is this keycode already in `f4194v0`"; it also **removes** it on
  `action == 1`, so a button pressed as a mapped key never leaks a media-key event on release.

### 5.3 What the Java decompile got wrong (§ jadx artefacts)

* `:1325-1330` — `boolean z19 = (z16 = this.f4173o0) ? true : true;` and the doubled
  `keyCode == 97 || keyCode == 97` are a collapsed version of the two independent tests
  `A-ish = keyCode == (swap?97:96)` and `B-ish = keyCode == (swap?96:97)`.
  **Consequence:** the listing suggests "when `f4173o0` is set the A branch runs for *any* key".
  That is false; in bytecode the A branch is entered only for the A-ish keycode.
* `:1591-1604` and `:1943-1957` — same collapse. Verified order in smali: compute `A-ish`, compute `B-ish`,
  `if (A-ish) {…click…} else if (B-ish) {…BACK…} else {…generic…}`.
* `:1291-1295` — the `keyCode == 4` re-test inside block A is **unreachable** (preamble returns first).
* `:1664-1750` — the `if (this.f4163k0) break; break;` pairs are dead code; all those paths return `true`.
* `:1930` `if (keyCode == 106 && !f4167m0) return false;` is the tail gate (B19), not a L1-specific test.

### 5.4 The A-button "click / long-press-drag / double-click" state machine (`:1591-1627`)

State: `f4149d0` = press pending, `f4151e0` = press time, `f4147c0` = dragging.

* **DOWN** (`:1619-1621`): if neither dragging nor pending ⇒ `f4149d0 = true; f4151e0 = now`.
* **DOWN, repeat** (`:1622-1626`): if pending and `now − f4151e0 > 250` ⇒ `f4149d0 = false; f4147c0 = true;
  m2150b0(cursorX, cursorY)` = **long press (250 ms) becomes a drag** (a real down-move-up gesture that stays open).
* **UP** (`:1607-1618`): if pending ⇒ `f4149d0 = false; m2174q(x,y)` = **tap** (50 ms stroke at the cursor), and if
  `f4085D0 && !f4082C0` ⇒ `postDelayed(new o60(this,x,y,0), 40)` = arm the **double-tap-to-type** detector.
  Else if dragging ⇒ `f4147c0 = false; m2152c0(x,y)` = **end drag** (continueStroke → lineTo, 50 ms, `willContinue=false`).
* The move loop (`s60` id 6) also converts a *stationary* press older than **500 ms** into a drag and emits the
  "Stationary long-press detected - converting to drag." log.

`o60` double-tap detector (40 ms after the click): only if mouse mode && !keyboard && `f4129T` && `f4085D0`
&& !dragging && !pending, it hit-tests an editable node within **24 px**; if none, it **retries once after 380 ms**
with a **36 px** radius; if found it stores the node in `f4113M1` and posts `n60(10)` after **310 ms**, which opens the
keyboard on it (`m2133J`) — Pro-gated (`m2146Z("keyboard_pro_required")` otherwise).

### 5.5 "double-tap a direction = drag/scroll" — what actually exists

There is **no** "double-tap a dpad direction to enter drag/scroll" path in lines 1–2060. The mechanisms that
exist are:

1. **Direction double-tap is suppressed, not special-cased.** Same-direction down within **120 ms** is swallowed
   (`now − f4177p1 > 120` at `:1393`), which is what makes a physical dpad whose driver auto-repeats fast still
   produce one caret step per press. `f4146b1` (the second 120 ms guard) is **never assigned anywhere**, so it is
   always 0 and its guard is always true — an artefact, most likely of a removed feature.
2. **Hold ⇒ repeat.** Holding a dpad direction starts the caret repeat after `f4121P0` = **300 ms** and repeats every
   `f4118O0` = **150 ms** (`m2148a0`, `:3091-3109`, plus `s60` id 1, which self-terminates when no dpad event arrived
   for **1000 ms**).
3. **Dead legacy path.** `f4168m1 == 1` is the "dpad moves the cursor/drag continuously" mode — the runnables that
   service it (`s60` id 0 at `f4077A1`, and the `f4174o1` 120 ms release validator) are still wired and still
   removed (`:3103-3107`, `:3433-3436`), but **nothing in the app ever calls `m2148a0(...,1)`** (the only call is
   `m2148a0(i7,i8,2)` at `:1394`), so mode 1 is unreachable.
4. **Actual drag/scroll sources**: left stick → cursor (`f4099I/f4102J`, speed `f4114N`=50 on display 0 /
   `f4117O`=30 elsewhere), right stick → scroll (`f4105K/f4108L` → `m2134K`: a discrete **150 ms** swipe that starts
   at (`f4075A`, `f4084D/2`) and ends at `(f4075A − s·f4125R·180·k, f4084D/2 − s·f4125R·180·k)` where `k = 1` on
   display 0 and `k = 0.5` elsewhere, `MouseAccessibilityService.java:2448-2466`), A-button long press → touch drag (§5.4).
5. **A real double-tap exists** but as a *gesture*: `m2175r` (`:4515`) dispatches two 50 ms taps at t=0 and t=150 ms;
   it is used by the mapped action `media_forward` (`m2179v`, `:4660`).

### 5.6 Long-press behaviours, complete list

| Where | Threshold | Effect |
|---|---|---|
| A button held down | **250 ms** (`:1622`) | click becomes DRAG (`f4147c0 = true`, `m2150b0`) |
| A button held, cursor stationary | **500 ms** (`s60` id 6) | press converted to drag + 40 ms haptic |
| dpad held | **300 ms** then 150 ms steps (`:3108`, `s60` id 1) | caret repeat in keyboard mode |
| A button held in keyboard mode | **400 ms** then 110 ms steps (`:1342`, `s60` id 2) | repeats the highlighted key |
| X held in keyboard mode | **400 ms** then 110 ms steps (`:1491`, `s60` id 5) | backspace repeat |
| R2 / ENTER | **350 ms** minimum gap (`:1438`) | fires `m2136M()` at most 2.9×/s |
| cursor over editable field | **310 ms** after the second tap | opens keyboard on that field (`n60` id 10) |
| L3 (THUMBL) held | `f4176p0 × 100 ms` pref (`:4219-4220`, handler outside scope) | enables mouse mode (cancel on release) |
| mapped action debounce | **300 ms** (`:4625`) | ignores repeated mapped actions |

---

## 6. SharedPreferences keys read in lines 1–2060

Only two `getSharedPreferences`-file reads and one preference key are touched in this range:

| Key (verbatim) | Line(s) | Where used |
|---|---|---|
| `"GamepadMousePrefs"` (file name, mode `0`) | `:1184` | `m2126B` — to read `pref_language` |
| `"pref_language"` | `:1189` | `m2126B` — overrides the system locale for every user-facing string |
| `"pref_haptic_feedback"` (default `true`) | `:1302`, `:1315`, `:1425`, `:1453`, `:1532`, `:1545`, `:1559`, `:1573`, `:1632`, `:1773`, `:1814`, `:1848`, `:1872`, `:1889`, `:1908` | every vibration in `m2127C`: 50 ms for START/SELECT/BACK/LT/RT/R3/THUMBL and every mapped action, 30 ms for the L2 shift latch |

All other pref reads in this class happen **outside** the assigned range:
`:2291`, `:2427`, `:2832`, `:2956`, `:3459`, `:3809`, `:3828`, `:3859`, `:4038`, `:4259`, `:4287-4372`, `:4633`, `:4636`, `:4647`.
The full key→field map (needed to interpret the `pref_*` fields of §2) is the loader at `:4291-4376`
(`pref_mouse_enabled`, `pref_dex_lockscreen_enabled`, `pref_force_mirroring`, `pref_mouse_speed`, `pref_dex_speed`,
`pref_mouse_size`, `pref_mouse_sensitivity`, `pref_mouse_timeout`, `pref_l3_toggle_enabled`, `pref_toggle_keycode`,
`pref_swap_ab_buttons`, `pref_scroll_speed`, `pref_deadzone`, `pref_l3_long_press_duration`, `pref_cursor_style`,
`pref_cursor_color`, `pref_keyboard_enabled`, `pref_kb_lang_en`, `pref_kb_lang_ko`, `pref_kb_lang_es`,
`pref_kb_nav_interval`, `pref_kb_nav_delay`, `pref_kb_move_sound`, `pref_kb_dex_width`, `pref_kb_dex_height`,
`pref_kb_dex_pos`).

---

## 7. Hard-coded constants in lines 1–2060

| Constant | Line(s) | Meaning |
|---|---|---|
| `2097152` | `:592` | `AccessibilityAction` id `ACTION_SET_TEXT` → "node is a text field" |
| `4` / `0` | `:1277`, `:1286` | `KEYCODE_BACK`, `ACTION_DOWN` |
| `400L` | `:1342` | A-button key autorepeat: initial delay (keyboard mode) |
| `350` | `:1438` | ENTER (R2) throttle window |
| `400L` | `:1491` | X/backspace autorepeat: initial delay (keyboard mode) |
| `120` | `:1393` (twice) | dpad re-press suppression window |
| `250` | `:1622` | A-button long-press → drag threshold |
| `40L` | `:1612` | delay before the double-tap-to-type detector runs |
| `50L` | `:1651` | delay before GLOBAL_ACTION_BACK is fired |
| `+250L` (`n60(8)`, outside range) | `:1651` | re-focus the overlay 250 ms after BACK |
| `50L` | `:1303, 1316, 1454, 1533, 1546, 1560, 1574, 1633, 1773, 1814, 1848, 1872, 1889, 1908` | haptic length for every button |
| `30L` | `:1426` | shorter haptic for the shift (L2) latch |
| `200L` | `:800`, `:851`, `:862`, `:2020`, `:2047` | cursor / blackout fade durations |
| `3000L` | `:2042` | WakeLock re-acquire duration in `m2129E` |
| `0.4f` | `:744` | cursor size factor on a non-primary display |
| `0.8f` and `50.0f` | `:746` | edge margin = `max(0.8·size, 50)` px |
| `1080`, `2400` | `:491`, `:494` | default screen width/height until the real display is measured |
| `500.0f`, `1000.0f` | `:485`, `:488` | initial cursor position |
| `700.0f` | `:1161` | max distance for `m2125A` node search |
| `512` | `:957`, `:968` | max cursor-bitmap edge / sampling floor |
| `44100`, `3748`, `7496`, `7532`, `7540`, `88200` | `:875-917` | WAV synthesis: 44.1 kHz, mono, 16-bit, 3748 sample frames (7496 data bytes), 7540-byte file |
| `1180.0`, `260.0`, `0.005`, `0.003`, `0.017`, `0.32`, `32767.0` | `:880-892` | tone sweep: f0 1180 Hz, −260 Hz sweep with 5 ms constant, 3 ms attack, 17 ms decay, 2nd harmonic 0.32, 16-bit full scale |
| `500` | `:482` | `f4193v` default repeat-click interval (ms) |
| `150` | `:556` | `f4118O0` caret-repeat interval default |
| `300` | `:557` | `f4121P0` caret hold delay default |
| `106` | `:546` | default L3/THUMBL keycode |

Runtime thresholds that live in `s60.java` (not in this file but part of the same behaviour):
16 ms (§cursor loop), 110 ms (ids 2/5 repeats), 150 ms (id 1 repeat), 120 ms (id 0/1/3/7 release validators),
1000 ms (id 1 mode-2 stale limit), 400 ms (id 2 initial), 500 ms (stationary press → drag), 40 ms (drag stroke pacing,
`MouseAccessibilityService.java:4022`), 50 ms (tap stroke length, `:4510`), 150 ms (scroll swipe, `:2466`).

---

## 8. `m2117X` — mouse-mode switch, step by step (`:693-870`)

Argument `mask` is a Kotlin default-argument bitmask: bit 2 (`&2`) ⇒ the "skip the early-return check" is *off*,
bit 4 (`&4`) ⇒ `z2` is forced `false`. All four in-range call sites pass `6` (`:1502`, `:1535`, `:1548`) ⇒
`z3 = false`, `z2 = false`; the only other caller (`n60` case 7) passes `4` ⇒ `z3 = true`, `z2 = false`.

1. `:723-725` If turning **off** while `f4082C0` ⇒ `m2163j(false)` closes the keyboard first.
2. `:726` Turning **on** requires `f4129T` (`pref_mouse_enabled`); when off it proceeds regardless.
3. `:727-736` If `mask&2 == 0` (i.e. `z3`) **and** the state already equals the requested state ⇒ early return
   (for "off": run `m2129E()` unless `z2`/DeX conditions, `:729-733`).
4. `:737` `f4163k0 = z` — **the state flip**.
5. **ON** (`:738-783`):
   * `m2164j0()` loads/prepares the cursor drawable (`:739`, `:3798-3878`);
   * cursor size `f2 = f4120P` on display 0, else `f4120P * 0.4` (`:740-745`), margin = `max(0.8f2, 50)` (`:746`);
   * if the cursor is within that margin of any edge ⇒ **re-centre to the screen centre** and `m2165k0()` (`:747-778`);
   * `f4145b0 = true`, cursor `setVisibility(0)` (`:779-783`).
6. **OFF** (`:784-804`): zero both sticks (`f4099I/f4102J/f4105K/f4108L`, `:785-788`), clear `f4159i0` (`:789`),
   if a drag is open finish it (`m2152c0(f4075A,f4078B)`, `:790-793`), clear the pending press (`:794`),
   `m2154d0(toast_repeat_stopped_cursor)` stops the repeat-click (`:795`), clear the held-key set `f4194v0` (`:796`),
   and if the cursor was visible fade it to alpha 0 over **200 ms** ending with `n60(id 2)` (hide) (`:797-803`).
7. `:805-813` Force the cursor alpha to 1 if `f4145b0`, else 0.
8. `:814-845` **For every display's focus-holder view** (`f4175p`): clear (`flags &= ~8`, i.e. remove
   `FLAG_NOT_FOCUSABLE`) when enabling, or set `flags |= 8` when disabling; `updateViewLayout`;
   then, when enabling **only for the active display's id**, `m2116T(view, displayId)` (post `requestFocus`),
   otherwise `view.clearFocus()`. All wrapped in a try/catch that logs
   `Failed to update focus view for display N:` (`:834-844`).
9. `:846-868` When enabling: `m2160h0()` (a 50 ms tap at (0,200) on the phone display or (width/2, 5) on DeX,
   `:3486-3504`) and fade the cursor in over 200 ms. When disabling: fade out (200 ms) and, if `z2 || !f4129T ||
   active display is 0`, call `m2129E()` to tear the blackout down (`:859-868`).

---

## 9. Caveats / things a re-implementation must not copy blindly

1. `m2127C` returns `true` for **almost everything** while mouse mode is on (B19 `:1927-1932`), including keys it does
   nothing with (e.g. dpad UP/DOWN without X). Only two `false` paths are live: keycode 4 (`:1277`) and
   `keyCode == 106 && !f4167m0` (`:1930`); the third (`!f4163k0`, `:1585`) cannot be reached (§5.0).
2. `f4177p1`/`f4180q1` are updated **before** the guard is tested, so a suppressed repeat still refreshes
   `f4180q1` — that is what makes the `s60` id-1 "1000 ms stale" check work.
3. `f4146b1` is dead (§5.5) — do not emulate it.
4. Mode 1 of `f4168m1` is dead — the `s60` id-0 runnable can never fire (`m2148a0` is only ever called with mode 2).
5. `m2122w`/`m2123x`/`m2124z` all recycle nodes they don't return; `m2120k` deliberately keeps the focused editable
   nodes alive (`:935`) and the caller must recycle them (see `m2125A` `:1162-1176`).
6. `m2126B` re-creates a configuration `Context` **on every call** (`:1194-1196`) — cheap enough here because it is only
   used for toasts, but it is a per-call allocation.
