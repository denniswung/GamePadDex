# SPEC — `MainActivity` (com.pkyul13.gamepadmouse)

Version analyzed: **Gamepad mouse v2.0.2** (`versionCode 44`, `versionName 2.0.2`, minSdk 32, targetSdk 36 —
`AndroidManifest.xml:3-14`).
Primary source: `work/decompile/pkyul13_sources/gamepadmouse/MainActivity.java` (4450 lines).

---

## 0. Provenance / how to read the citations

| Citation form | Meaning |
|---|---|
| `MainActivity.java:1234` | line in `work/decompile/pkyul13_sources/gamepadmouse/MainActivity.java` (the 4450-line jadx 1.5.0 output). |
| `p000/xxx.java:NN` | helper class (R8-inlined lambda target). **These files are not present in `work/decompile/pkyul13_sources`** — that tree only contains the `gamepadmouse` package. They were recovered for this spec by re-decompiling `work/apk/base.apk` with jadx 1.5.1 into a scratch dir (`~/gpmfull/out/sources/p000/*.java`). Line numbers refer to that decompile. Always verify against the APK. |
| `MouseAccessibilityService.java:NN` | `work/decompile/pkyul13_sources/gamepadmouse/MouseAccessibilityService.java` (4963 lines). Used only to document *where a preference is consumed*. |
| `layout:...`, `strings.xml:NN`, `colors.xml:NN` | `work/decompile/res/**`. |

### Decompiler artifacts you must know about

1. **`import android.R;` at `MainActivity.java:3` is spurious/mixed.** The class uses *both* `com.pkyul13.gamepadmouse.R` and `android.R`; jadx emitted bare `R.` for both. Resolve each symbol against the app resources first; if absent, it is `android.R`:
   * `R.string.ok` (`MainActivity.java:4423`) — app has no `ok` → **`android.R.string.ok` = "OK"**.
   * `R.color.holo_green_dark` (`:308`), `R.color.holo_blue_light` (`:4194`), `R.color.darker_gray` (`:4195`) — not in app `colors.xml` → `android.R.color.holo_green_dark` `#669900`, `holo_blue_light` `#33b5e5`, `darker_gray` `#444444`.
   * `R.style.Theme.Black.NoTitleBar.Fullscreen` (`:1128`, `:2802`, …) — app styles have no such name → `android.R.style.Theme.Black.NoTitleBar.Fullscreen`.
   * Everything else resolves to the app `R` (`R.string.general_settings`, `R.id.*`, `R.string.cancel`, …).
2. **All lambdas are inlined at every call site.** The click handler `v10` (cases 0–7) is physically duplicated ~10× inside `onCreate`; `a20` (pro-gated switch handler) is duplicated 3×; `d20`, `f20`, `m20`, `k20` are duplicated too. Consequently `onCreate` spans `MainActivity.java:885-4149` as one gigantic nested method. The *semantic* classes are: `p000/v10` (8-way `View.OnClickListener`), `p000/a20` (3-way pro-gated `OnCheckedChangeListener`), `p000/r20`/`p000/s20` (seek bars), `p000/t10` (language + dex-pos check boxes), `p000/u10` (plain switches), `p000/j20` (preference-change listener, both activity and service instances), `p000/l20` (mapping action picker), `p000/c20` (dialog positive buttons), `p000/i20` (language pick + repeat-interval OK), `p000/e20` (initial-setup accept/decline), `p000/o20`/`p000/p20`/`p000/u20`/`p000/t20` (custom color + app picker), `p000/ViewOnClickListenerC0837sy` (mapping row click / custom color entry), `p000/ViewOnClickListenerC0853td` (dismiss-only clicks), `p000/k20` (mapping row long-click), `p000/RunnableC0151b2` (drawer hint popup, cases 7/8), `p000/C0360g` (pro-state broadcaster), `p000/w10` (pro-tab refresher), `p000/h20` (UI-thread trampoline). A faithful reimplementation should reintroduce these as named classes/listeners instead of the inlined form.
3. jadx dropped the `switch` case index of `e20`'s constructors; it was recovered in `-m fallback` mode: **`e20(MainActivity, Dialog)` ⇒ case 0** (accept), **`e20(Dialog, MainActivity)` ⇒ case 1** (decline/exit).

---

## 1. Class / field layout

`public final class MainActivity extends AbstractActivityC0439i4` (`MainActivity.java:112`) —
`AbstractActivityC0439i4` is `androidx.appcompat.app.AppCompatActivity`.

### 1.1 Resource / view fields

| Field | Type | Init / default | Purpose | Lines |
|---|---|---|---|---|
| `f4054M` | `static final int` | `0` | jadx/R8 synthetic "lambda capture" sentinel; referenced by every lambda as a no-op int. Keep as unused `static final int` in a replica. | 115 |
| `f4055A` | `NavigationView` | `null` | Material drawer nav view (`R.id.nav_drawer`). | 118, 3722 |
| `f4056B` | `MaterialToolbar` | `null` | Toolbar (`R.id.main_toolbar`), used to set per-page title. | 121, 906 |
| `f4057C` | `int` | `0` | **Current page layout id** (`R.id.layout_settings_general`, … ). Set by `m2099t`. Used to re-set toolbar title on pro refresh (`:390`). | 124, 268 |
| `f4058D` | `boolean` | `false` | Re-entrancy guard while programmatically ticking the DeX-position check boxes (`m2097r`, `j20`). | 127, 233/237, 210/223 |
| `f4059E` | `PopupWindow` | `null` | The one-shot "tap ☰" hint bubble; dismissed in `onPause`. | 130, 4230 |
| `f4067t` | `SharedPreferences` | `null` | **`getSharedPreferences("GamepadMousePrefs", 0)`** — the single settings store. Assigned at `:980`. | 148, 978-980 |
| `f4068u` | `FirebaseAnalytics` | `null` | `FirebaseAnalytics.getInstance(app)` singleton. | 151, 947-953 |
| `f4070w` | `AdView` | `null` | Banner AdView (created lazily when not Pro). | 154, 638-642 |
| `f4071x` | `FrameLayout` | `null` | Ad container `R.id.layout_ad_container`. | 157, 4351 |
| `f4072y` | `w10` | `null` | Pro-tab UI refresher (calls `m2100u`). | 160, 3390 |
| `f4073z` | `x10` | `null` | `onNewIntent` forwarder → `m2098s` (`open_page` extra). | 163, 3726 |

### 1.2 Numeric / state fields

| Field | Type | Init | Purpose | Lines |
|---|---|---|---|---|
| `f4069v` | `float` | **`0.15f`** | Dead-zone radius used by the stick test in `onGenericMotionEvent`; kept in sync with `pref_deadzone/100f` at `:2777-2778`. | 166, 4196-4197 |
| `f4061G` | `final int` | `AdRequest.MAX_CONTENT_URL_LENGTH` = **512** | Max edge (px) for the imported custom cursor PNG (`C0296eb.onActivityResult` uses it as the downscale target). | 172, `C0296eb.java:238` |

### 1.3 Helper / listener fields

| Field | Type | Init | Purpose | Lines |
|---|---|---|---|---|
| `f4060F` | `final C0360g` | `new C0360g(1, this)` | `InterfaceC0610mt` (a `Function1<Boolean,Unit>`) used as the **Pro-state listener**; registered into `db0.f4582f`; on fire it posts `h20(mainActivity, isPro)` → `m2103B(isPro)` + `w10.mo2481b()`. | 169, 966-971, `C0360g.java:33-38`, `h20.java:33-41` |
| `f4062H` | `final AbstractC0509k2` | `registerForActivityResult(new C0472j2(0), new C0296eb(5, this))` | **ActivityResultLauncher** for `ActivityResultContracts.GetContent` (`ACTION_GET_CONTENT` + `CATEGORY_OPENABLE`, MIME `image/png`) used to import a custom cursor PNG. Launched at `:1242` / `:1548` / `:1861` with `launch("image/png", null)`. | 176-178, `C0472j2.java:25-33` |
| `f4063I` | `final j20` | `new j20(this, 0)` | `OnSharedPreferenceChangeListener` for the **activity** (case 0 = sync widgets when prefs change elsewhere, e.g. from the service). Registered `onResume` `:4263`, unregistered `onPause` `:4244`. | 179, `j20.java:100-307` |
| `f4064J` | `final List` | `[100, 200, 500, 1000, 2000, 3000]` | Preset repeat-click intervals (ms). Note `200` is encoded as `Scheduler.MAX_GREEDY_SCHEDULER_LIMIT` (WorkManager constant = 200 — `androidx/work/impl/Scheduler.java:8`). | 180, 4370-4386 |
| `f4065K` | `final Map` | `orange→#FFA000, blue→#2196F3, green→#4CAF50, red→#F44336, black→#212121, white→#FFFFFF, purple→#9C27B0, cyan→#00BCD4, pink→#E91E63, yellow→#FFEB3B` | Legacy named cursor-style → hex colour; used only for migration in `m2104C`. | 181, 677-688 |
| `f4066L` | `final List` | 36 hex strings (see §11.3) | Colour palette of the "Custom Color" grid. | 182, 1263 |

---

## 2. Persistence model

Two `SharedPreferences` files, both `MODE_PRIVATE (0)`:

| File | Keys | Owner |
|---|---|---|
| **`GamepadMousePrefs`** | all behavioural settings + mappings (`MainActivity.java:844`, `:978`) | Activity **and** `MouseAccessibilityService` (`MouseAccessibilityService.java:4111` is its cached instance). |
| **`GamepadMouseProPrefs`** | `is_pro_version` (bool, default `false`), `debug_pro_override` (bool, default `true`) | `p000/db0.java` (ProManager) only. |

### 2.1 Full key table (`GamepadMousePrefs`)

Types as stored. "Written by" = MainActivity path; "Read by service" = field/behaviour in `MouseAccessibilityService`.

| # | Key | Type | Default | Valid range / values | Stored by | Consumed as |
|---|---|---|---|---|---|---|
| 1 | `pref_mouse_enabled` | boolean | `true` | – | `u10` case 2 (`u10.java:65`) | `f4129T`; when `false` → cursor views hidden, repeat-click stopped (`j20.java:397-423`) |
| 2 | `pref_toggle_keycode` | int | **`106`** (KEYCODE_BUTTON_THUMBL / "L3") | any keycode **except** the blocked set `{19,20,21,22,23}` (D-pad) and `{4,24,25,26}` (BACK, VOLUME_UP, VOLUME_DOWN, CAMERA) | `d20` (`MainActivity.java:1389`, `:1695`, `:2008`, `:2685`, `:3063`, `:3366`, `:3674`, `:4014`), reset `c20` case 2 (`c20.java:94`) | `f4170n0` |
| 3 | `pref_l3_long_press_duration` | int | `0` | 0–10 (units of 100 ms; 0 = instant) | `r20` default branch (`r20.java:232`), on **stop tracking** | `f4176p0` |
| 4 | `pref_swap_ab_buttons` | boolean | `false` | – | `u10` case 3 (`u10.java:81`) | `f4173o0` |
| 5 | `pref_dex_lockscreen_enabled` | boolean | `false` | – (Pro) | `a20` case 0 (`MainActivity.java:2072`…`2239`) | `f4131U` |
| 6 | `pref_force_mirroring` | boolean | `false` | – | `u10` case 4 (`u10.java:92`) | `f4090F` |
| 7 | `pref_haptic_feedback` | boolean | `true` | – (Pro) | `a20` case 2 (`MainActivity.java:2116`…`2283`) | read live before every vibration (`MouseAccessibilityService.java:1302` **30+ sites**) |
| 8 | `pref_vibration_intensity` | int | **`255`** | 0–255 | `s20` (`s20.java:37`, Pro gate) | amplitude for gamepad vibrator (`MouseAccessibilityService.java:4038-4046`) |
| 9 | `pref_mouse_speed` | int | **`50`** | 10–200 (UI clamps <10 → 10) | `r20` case 4 | `f4114N` (raw) |
| 10 | `pref_dex_speed` | int | **`35`** | 10–200 (Pro; UI clamps) | `r20` case 5 | `f4117O` (raw) |
| 11 | `pref_mouse_size` | int | **`100`** | 40–200 (UI clamps <40 → 40) | `r20` case 6 | `f4120P` |
| 12 | `pref_mouse_sensitivity` | int | **`20`** | 10–30, i.e. `progress+10`; float = v/10 ∈ 1.0–3.0 | `r20` case 7 | `f4123Q = v/10.0f` |
| 13 | `pref_mouse_timeout` | int | `0` | `0`=never, else `progress+4` ⇒ 5–60 s (values 1–4 are unreachable via UI) | `r20` case 8 | `f4133V` (seconds) |
| 14 | `pref_scroll_speed` | int | **`100`** | 10–400 (UI clamps <10 → 10) | `r20` case 9 | `f4125R = v/50.0f` |
| 15 | `pref_deadzone` | int | **`15`** | 1–50 (UI clamps <1 → 1); float = v/100 | `r20` case 10 | `f4127S = v/100.0f` |
| 16 | `pref_cursor_style` | String | **`"orange"`** | `"orange"`, `"custom_color"`, `"custom"` (legacy names migrated) | cursor-style dialog (`MainActivity.java:682`, `:700`, `:722`, `:1323`, `C0296eb.java:296`), reset `c20.java:61` | `f4135W` |
| 17 | `pref_cursor_color` | String | **`"#FFA000"`** | `#RRGGBB` (normalized upper-case) | colour grid (`MainActivity.java:1320`), HEX entry (`o20.java:50`) | `f4137X` |
| 18 | `pref_language` | String | OS locale if `ko`/`es`, else `"en"` | `"en"`, `"ko"`, `"es"` | `:1084` init, `i20` case 0 (`i20.java:53`) | activity only (`attachBaseContext`, `MouseAccessibilityService.java:1189`) |
| 19 | `pref_kb_lang_en` | boolean | `true` | – | `t10` case 4 | `f4109L0` |
| 20 | `pref_kb_lang_ko` | boolean | `true` | – | `t10` case 5 (default) | `f4112M0` |
| 21 | `pref_kb_lang_es` | boolean | `false` | – | `t10` case 0 | `f4115N0` |
| 22 | `pref_kb_nav_interval` | int | **`150`** | `progress*10+50` ⇒ 50–500 ms | `r20` case 0, stop-tracking only | `f4118O0` |
| 23 | `pref_kb_nav_delay` | int | **`300`** | `progress*50+200` ⇒ 200–1500 ms | `r20` case 1, stop-tracking only | `f4121P0` |
| 24 | `pref_kb_move_sound` | boolean | `false` | – | `u10` case 0 | `f4124Q0` |
| 25 | `pref_kb_dex_width` | int | **`50`** | `progress+20` ⇒ 20–100 (%) | `r20` case 2, stop-tracking only | `f4126R0` |
| 26 | `pref_kb_dex_height` | int | **`100`** | `progress*5+40` ⇒ 40–200 (%) | `r20` case 3, stop-tracking only | `f4128S0` |
| 27 | `pref_kb_dex_pos` | String | **`"center"`** | `"left"`,`"center"`,`"right"` | `m2097r` (`MainActivity.java:240`) | `f4130T0` |
| 28 | `pref_keyboard_enabled` | boolean | `true` | – (Pro) | `a20` case 1 | `f4085D0` |
| 29 | `pref_mapping_x_<slot>_type` | String | `"none"` | see §6.2 action ids | mapping dialog `l20` | read **live** on every combo press (`MouseAccessibilityService.java:4633`) |
| 30 | `pref_mapping_x_<slot>_value` | String | `""` | package name (`app`) or `"x,y"` floats (`click_location*`) | `l20`, `p20`, service | `MouseAccessibilityService.java:4636`, `:4849`, `:4888` |
| 31 | `pref_mapping_x_<slot>_interval` | int | **`500`** | 100–3000 ms (clamped by `lo0.m5054i`) | `m2113z` (`MainActivity.java:4403`), `i20` default (`i20.java:99`) | `m2140R` (`MouseAccessibilityService.java:2832`) |
| 32 | `pref_initial_setup_shown` | boolean | `false` | – | `e20` accept (`e20.java:39`) | **never read** |
| 33 | `pref_drawer_hint_done` | boolean | `false` | – | `RunnableC0151b2` case 7 (`:224`) | `m2111x` (`MainActivity.java:4338`) |
| 34 | `pref_l3_toggle_enabled` | boolean | `true` | – | **service only** (`MouseAccessibilityService.java:3871`, `j20.java:320`) | `f4167m0` |

`<slot>` ∈ `lb, rb, lt, rt, up, down, left, right` (8 slots, `MainActivity.java:1056`, `:3695`).

---

## 3. Activity ⇄ service communication

**There is no broadcast and (almost) no Intent between the components.** All settings travel through the
`GamepadMousePrefs` SharedPreferences file; both processes register their own
`OnSharedPreferenceChangeListener` and therefore react to writes from the other side:

* Activity instance: `f4063I = new j20(this, 0)` → `j20.java` case 0 (syncs widgets, `MainActivity.java:179`, `:4244`, `:4263`).
* Service instance: `new j20(this, 1)` → `j20.java` case 1 (updates the service's cached fields, e.g. `j20.java:314`, `:326`, `:397`, `:442`, `:478`).
* Writes use `apply()` everywhere except the **Reset All Settings** path which uses `commit()` (`c20.java:82`).

### 3.1 Intent strings that *do* exist

| Direction | Action / class | Flags | Extras | Source |
|---|---|---|---|---|
| Activity → system | `"android.settings.ACCESSIBILITY_SETTINGS"` | `268435456` (FLAG_ACTIVITY_NEW_TASK) | – | `MainActivity.java:1144-1146`, `:1450`, `:1763`, `:2440`, `:2818`, `:3769`; `e20.java:42` |
| Activity → system | `"android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS"` | `268435456` | – | `MainActivity.java:1150-1152` (+7 duplicate inlined copies) |
| Activity → system | `"android.settings.action.MANAGE_WRITE_SETTINGS"` with `data = package:<applicationId>` | `268435456` | – | `c20.java:111-115` (from `m2107m`) |
| Activity → system | `"android.intent.action.GET_CONTENT"` + `CATEGORY_OPENABLE`, type `"image/png"` | – | – | `C0472j2.java:31` (via `f4062H`) |
| Activity → chooser | `"android.intent.action.SEND"`, type `"text/plain"` | – | `"android.intent.extra.TEXT" = app_name + "\n" + https://play.google.com/store/apps/details?id=<pkg>` | `C0833su.java:179-193` (nav_share) |
| Activity → store | `"market://details?id=<pkg>"`, fallback `"android.intent.action.VIEW"` + `https://play.google.com/store/apps/details?id=<pkg>` | – | – | `C0833su.java:191-196` (nav_rate) |
| Activity → mail | `"android.intent.action.SENDTO"`, data `"mailto:"` | – | `"android.intent.extra.EMAIL" = ["pkyul13@gmail.com"]`, `"android.intent.extra.SUBJECT" = R.string.contact_email_subject` | `C0833su.java:203-211` (nav_contact) |
| **Service → Activity** | explicit `new Intent(service, MainActivity.class)` | `805306368` = `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_SINGLE_TOP` | **`"open_page" = "keyboard_settings"`** (String) | `MouseAccessibilityService.java:2222-2224` |
| Activity consumes | `getIntent().getStringExtra("open_page")` == `"keyboard_settings"` → `navigationView.setCheckedItem(R.id.nav_keyboard_settings)` + show `R.id.layout_settings_keyboard`; then the extra is removed | – | – | `MainActivity.java:248-262` (`m2098s`), `:3731` |

### 3.2 Cross-component static state

| Static | Type | Meaning | Lines |
|---|---|---|---|
| `db0.f4577a` | `boolean` | cached Pro (`is_pro_version`) | `db0.java:192` |
| `db0.f4578b` | `boolean` | build is debuggable (`ApplicationInfo.flags & 2`) | `db0.java:189` |
| `db0.f4579c` | `boolean` | debug Pro override (`debug_pro_override`, default `true`) | `db0.java:191` |
| `db0.m2408b()` | `static boolean` | **`isPro() = debug ? override : is_pro_version`** — the single gate used everywhere | `db0.java:199-201` |
| `db0.f4580d` | `BillingClient` | Play Billing client | `db0.java:213-216` |
| `db0.f4581e` | `boolean` | billing connected flag |  |
| `db0.f4582f` | `CopyOnWriteArrayList` | registered Pro-state listeners (`f4060F` is one) | `db0.java:182`, `:206` |
| `db0.f4583g` | `Handler` (main looper) | used to broadcast Pro state changes | `db0.java:185`, `:208` |
| `MainActivity.f4054M` | `int` | lambda-capture sentinel | 115 |
| `MouseAccessibilityService.f4074Q1` | `int` | lambda-capture sentinel of the service | referenced in `j20.java:311` etc. |

---

## 4. Lifecycle behaviour

Order of the important overrides: `attachBaseContext` → `onCreate` → `onResume`/`onPause` → `onNewIntent` → `onDestroy`.
There is **no** `onStart`/`onStop`/`onSaveInstanceState`/`onActivityResult`/`onRequestPermissionsResult`/`onConfigurationChanged`.

### 4.1 `attachBaseContext(Context)` — `MainActivity.java:842-858`
1. `prefs = context.getSharedPreferences("GamepadMousePrefs", 0)`.
2. `lang = Locale.getDefault().getLanguage()`; if not `ko`/`es` → `"en"`.
3. `lang = prefs.getString("pref_language", lang)` (null-safe).
4. `Locale.setDefault(Locale.forLanguageTag(lang))`, clone `Configuration`, `setLocale`, then
   `super.attachBaseContext(context.createConfigurationContext(cfg))`.
   ⇒ language is applied before the view hierarchy inflates; switching language calls `recreate()`.

### 4.2 `onCreate(Bundle)` — `MainActivity.java:885-4149`
| Step | Lines | Notes |
|---|---|---|
| `super.onCreate` | 896 | |
| `setContentView(R.layout.activity_main)` | 897 | |
| `setTitle(R.string.app_name)` | 898 | |
| Drawer wiring: `DrawerLayout` `R.id.main`, insets listeners on `R.id.main_content` / `R.id.drawer_container`, `MaterialToolbar R.id.main_toolbar`, `ActionBarDrawerToggle` (`C0150b1`) + sync state | 899-941 | |
| `m2101w(drawerLayout)` — installs touch-slop intercept on all `SwitchCompat`/`CheckBox` | 941, 398-438 | 8 dp horizontal slop, ratio 1.5 |
| FirebaseAnalytics init (double-checked singleton) | 942-953 | |
| `user_type` user-property = `"pro_user"` / `"free_user"` | 954-964 | `qj2.m6543g(new qk2(...,"user_type",value,...))` |
| `db0.m2407a(this)` (loads Pro flags, starts Billing) + register `f4060F` | 965-971 | |
| `MobileAds.initialize(this, no-op)` then `m2112y()` (banner setup), all in `try/catch(Throwable)` logging `"AdMob"` | 972-977 | |
| `f4067t = getSharedPreferences("GamepadMousePrefs", 0)` | 978-980 | |
| First-run defaults for 6 mapping slots: **`up`→`vol_up`, `down`→`vol_down`, `lb`→`mute`, `left`→`media_rewind`, `right`→`media_forward`, `rt`→`screenshot`, `rb`→`none`** — each only `if (!prefs.contains(key))` | 981-1055 | note `lt` is never defaulted ⇒ `"none"` |
| Migration: any slot whose type == `"back"` → type `"none"` and `remove(..._value)` | 1056-1072 | |
| Language button text + click | 1073-1105, 1181-1207 | |
| Cursor-style button click | 1411-1416, 1208-1367 | |
| `m2104C()` (cursor label, migration) | 1717 | |
| `switch_mouse_enabled` set + listener (`u10` 2) | 1718-1723 | |
| Toggle-key button click (`v10` 7) + `m2106E()` | 1724-1729, 2030 | |
| `seekbar_l3_long_press` (`r20` 11) | 2031-2038 | |
| `switch_swap_ab_buttons` (`u10` 3) | 2039-2043 | |
| `switch_dex_lockscreen` (`a20` 0, Pro) | 2044-2124 | |
| `switch_force_mirroring` (`u10` 4) | 2125-2129 | |
| `switch_keyboard_input` (`a20` 1, Pro) | 2130-2210 | |
| `switch_haptic_feedback` (`a20` 2, Pro) | 2211-2291 | |
| KB language check boxes (`t10` 4/5/0) + `m2105D()` | 2292-2309 | min-1-language toast guard |
| `seekbar_kb_repeat` (`r20` 0), `seekbar_kb_delay` (`r20` 1), `switch_kb_move_sound` (`u10` 0), `seekbar_kb_dex_width` (`r20` 2), `seekbar_kb_dex_height` (`r20` 3), DeX-pos check boxes (`t10` 1/2/3) | 2310-2361 | |
| `switch_debug_pro` visibility/checked + listener (`u10` 1) — only if `db0.f4578b` (debuggable) | 2362-2377 | otherwise `GONE` |
| `seekbar_vibration_intensity` (`s20`), `seekbar_speed` (`r20` 4), `seekbar_dex_speed` (`r20` 5) | 2378-2401 | |
| `iv_guide` click (`v10` 0) | 2402-2404 | |
| **Initial-setup dialog** if `!m2109p()` (accessibility service not enabled) | 2707-2724 | see §4.6 |
| `seekbar_size` (`r20` 6), `seekbar_sensitivity` (`r20` 7), `seekbar_timeout` (`r20` 8), `seekbar_scroll_speed` (`r20` 9), `seekbar_deadzone` (`r20` 10) | 2725-2781 | |
| `btn_open_settings` (`v10` 1) | 2782 | |
| `btn_battery_optimization` (`v10` 2) | 3084-3085 | |
| Pro tab: `tv_pro_status`, `tv_pro_desc`, `btn_buy_pro`, `w10`, `m2100u(...)`, click (`v10` 3) | 3387-3393 | |
| Mapping rows loop: 8 × (`btn_map_x_<slot>`, `tv_map_x_<slot>_val`), click = `ViewOnClickListenerC0837sy(this, slot, 1)`, long-click = `k20` | 3695-3720 | |
| NavigationView: `f4055A`, `nav_pro` title = `m2110v()`, `setItemIconTintList(null)`, page list, `x10`, item listener `y10`, checked = `nav_general_settings`, `m2099t(... layout_settings_general)`, `m2111x()`, `m2098s(...getIntent())` | 3721-3731 | |
| `btn_reset_defaults` (`v10` 4) | 3733 | |
| `tv_drawer_version` = `getString(R.string.app_version_format, packageInfo.versionName)` (uses `PackageInfoFlags.of` on API≥33) | 4035-4049 | catch(Exception) → printStackTrace |

### 4.3 `onResume()` — `MainActivity.java:4252-4308`
1. `super.onResume()`.
2. If `!db0.m2408b()` and `f4070w != null` → `adView.resume()` (inside try/catch).
3. `f4067t.registerOnSharedPreferenceChangeListener(f4063I)`.
4. Re-sync: `switch_mouse_enabled` (`pref_mouse_enabled`, true), `seekbar_l3_long_press` + `tv_l3_long_press_val` (`pref_l3_long_press_duration`, 0), `switch_swap_ab_buttons` (`pref_swap_ab_buttons`, false), `switch_haptic_feedback` (`pref_haptic_feedback`, true).
5. `m2102A()` (mapping labels) + `m2111x()` (drawer hint).

### 4.4 `onPause()` — `MainActivity.java:4229-4249`
1. Dismiss `f4059E` popup if non-null.
2. `adView.pause()` in try/catch.
3. `super.onPause()`.
4. `unregisterOnSharedPreferenceChangeListener(f4063I)`.

### 4.5 `onNewIntent` / `onDestroy`
* `onNewIntent(Intent)` — `:4218-4226`: `super`, `setIntent(intent)`, `f4073z.mo3287e(intent)` → `m2098s` (page jump from `open_page`).
* `onDestroy()` — `:4152-4165`: remove `f4060F` from `db0.f4582f`, `adView.destroy()` (try/catch), `super.onDestroy()`.

### 4.6 Dialog flows
* **Initial setup / accessibility disclosure** (`MainActivity.java:2707-2724`): shown whenever
  `!m2109p()`, i.e. on *every* launch while the accessibility service is not enabled (the stored
  `pref_initial_setup_shown` is written but never read). `Dialog dialog = new Dialog(this)`;
  `requestWindowFeature(1)` (NO_TITLE); `setContentView(R.layout.dialog_initial_setup)`;
  window background `ColorDrawable(0)` (transparent); `setCancelable(false)`; width =
  `(int)(displayMetrics.widthPixels * 0.9)`, height `-2`.
  * `btn_dialog_accept` → `e20` case 0: `pref_initial_setup_shown = true`, dismiss, `startActivity(ACCESSIBILITY_SETTINGS | NEW_TASK)`.
  * `btn_dialog_decline` → `e20` case 1: dismiss, **`finishAffinity()`**.
* **Brightness permission** (`m2107m`, `:861-871`): if `!Settings.System.canWrite(this)` → Material dialog
  title `R.string.permission_required`, msg `R.string.brightness_permission_msg`, positive
  `R.string.open_settings` → `c20` case 6 → `MANAGE_WRITE_SETTINGS` for own package; negative `R.string.cancel`.
  Called before writing mapping types `bright_up`, `bright_down`, `rotate` (`l20.java:93`, `:97`, `:110`).
* **Guide image** (`v10` case 0): remembers `getRequestedOrientation()`, forces `setRequestedOrientation(0)`
  (landscape), shows `Dialog(theme = android Theme.Black.NoTitleBar.Fullscreen)` with
  `R.layout.dialog_full_screen_image` + `R.drawable.guide`; tapping the image (`ViewOnClickListenerC0853td` 3)
  or dismissing restores the previous requested orientation (`b20`).
* **Pro-feature dialog** pattern (used ~10×): title `R.string.pro_feature` (or literal `"Pro Feature"`),
  message one of `R.string.dex_pro_msg` / `R.string.keyboard_pro_required` / `R.string.haptic_pro_msg` /
  `R.string.vibration_pro_msg` / `"Custom Key Mapping is only available in the Pro version."`,
  positive `R.string.upgrade` → `db0.m2411e(activity)` (billing flow), negative `R.string.cancel`.

### 4.7 Permissions / requests
| Needs | How obtained | Lines |
|---|---|---|
| Accessibility service | `Intent(ACTION_ACCESSIBILITY_SETTINGS)` (no runtime permission API) | `:1144`, `e20.java:42` |
| Ignore battery optimizations | `Intent(IGNORE_BATTERY_OPTIMIZATION_SETTINGS)` | `:1150` |
| `WRITE_SETTINGS` (brightness, rotation) | `Intent(MANAGE_WRITE_SETTINGS, package:…)` after `Settings.System.canWrite` check | `c20.java:111`, `m2107m` |
| Accessibility enabled test | `Settings.Secure.getString(cr, "enabled_accessibility_services")` contains `new ComponentName(this, MouseAccessibilityService.class).flattenToString()` | `m2109p`, `:4311-4319` |
| Storage / notification | none requested by the activity | – |

### 4.8 Foreground service / notification
**None.** No `startForeground`, no `Notification`, no notification channel anywhere in `MainActivity` or
`MouseAccessibilityService` (verified by grep over both files). The `<uses-permission
android:name="android.permission.FOREGROUND_SERVICE"/>` in the manifest is unused by app code (WorkManager
dependency). The only persistent component is the accessibility service, which is system-bound.

### 4.9 Configuration changes
Manifest declares `android:configChanges="smallestScreenSize|screenSize|screenLayout|orientation"` for the
activity (`AndroidManifest.xml:82`), so rotation/resize does **not** recreate it; `Activity`'s
`onConfigurationChanged` is not overridden. `windowSoftInputMode="stateAlwaysHidden"`.

---

## 5. Page model (drawer navigation)

`m2099t(activity, pages, toolbar, pageId)` (`MainActivity.java:265-296`) stores `f4057C = pageId`, sets all
pages' visibility to `VISIBLE(0)` only for the selected id (others `GONE(8)`), and sets the toolbar title:

| Page layout id | Toolbar title |
|---|---|
| `R.id.layout_settings_general` | `R.string.general_settings` |
| `R.id.layout_settings_pointer` | `R.string.pointer_sensitivity` |
| `R.id.layout_settings_keyboard` | `R.string.keyboard_settings` |
| `R.id.layout_initial_setup` | `R.string.page_initial_setup` |
| `R.id.layout_how_to_use` | `R.string.how_to_use` |
| `R.id.layout_pro_tab` | `m2110v()` = `nav_pro_features` (Pro) else `nav_pro_buy` (free) |
| anything else | `R.string.app_name` |

Page list order (`MainActivity.java:3725`):
`[layout_settings_general, layout_settings_pointer, layout_settings_keyboard, layout_pro_tab, layout_initial_setup, layout_how_to_use]`.
Default page = `layout_settings_general` (`:3728-3729`).

Drawer item ids → action (`p000/C0833su.java:164-227`, the `NavigationView` presenter calling `y10`):

| Menu item | Layout shown |
|---|---|
| `nav_general_settings` | `layout_settings_general` |
| `nav_pointer_settings` | `layout_settings_pointer` |
| `nav_keyboard_settings` | `layout_settings_keyboard` |
| `nav_initial_setup` | `layout_initial_setup` |
| `nav_how_to_use` | `layout_how_to_use` |
| `nav_pro` | `layout_pro_tab` **and** `m2100u(...)` (refresh Pro tab) |
| `nav_share` | `ACTION_SEND` chooser + analytics `share_app` |
| `nav_rate` | `market://` (fallback Play URL) + analytics `rate_app` |
| `nav_contact` | `mailto:` (fallback toast `contact_email_fallback`) + analytics `contact_developer` |

After every selection: dismiss `f4059E` popup, `drawerLayout.closeDrawers()` (`d=false`), return `true`.

`m2111x()` (`:4335-4346`): if `!pref_drawer_hint_done` **and** `m2109p()` → after **900 ms** post
`RunnableC0151b2(7, this)`, which (guards: not finishing/destroyed, pref still false) sets
`pref_drawer_hint_done = true`, opens the drawer, and shows a `PopupWindow` (TextView, 14 sp,
`R.color.text_primary`, background `R.drawable.bubble_hint_bg`, padding 16/10 dp, elevation 12)
anchored `showAsDropDown(toolbar, 8dp, 0)`; the popup auto-dismisses after **10000 ms**
(`WorkRequest.MIN_BACKOFF_MILLIS`) via `RunnableC0151b2(8, popup)`, and tapping it dismisses
(`ViewOnClickListenerC0853td` 2).

---

## 6. Gamepad button mapping system

### 6.1 Model
A *mapping row* binds the **combo `X + <slot>`** (physical `KEYCODE_BUTTON_X` = 99 as a held modifier +
one of 8 slot keys) to one action. 8 independent slots:

| slot | UI label (`activity_main.xml`) | keycode pressed with X held |
|---|---|---|
| `lb` | `X + LB` | `KEYCODE_BUTTON_L1` = 102 |
| `rb` | `X + RB` | `KEYCODE_BUTTON_R1` = 103 |
| `lt` | `X + LT` | `KEYCODE_BUTTON_L2` = 104 |
| `rt` | `X + RT` | `KEYCODE_BUTTON_R2` = 105 |
| `up` | `X + Dpad Up` | `KEYCODE_DPAD_UP` = 19 |
| `down` | `X + Dpad Down` | `KEYCODE_DPAD_DOWN` = 20 |
| `left` | `X + Dpad Left` | `KEYCODE_DPAD_LEFT` = 21 |
| `right` | `X + Dpad Right` | `KEYCODE_DPAD_RIGHT` = 22 |

Storage layout (3 keys per slot, no serialized/combined format — plain scalar prefs):

```
pref_mapping_x_<slot>_type      String   action id (see §6.2), default "none"
pref_mapping_x_<slot>_value     String   payload, default ""  (package name, or "x,y")
pref_mapping_x_<slot>_interval  int      repeat interval ms, default 500
```

**Combo detection is in the service** (`MouseAccessibilityService.java:1662-1870`): `KEYCODE_BUTTON_X` = **99**
toggles the modifier flag `f4191u0` on key-down/up (`:1933-1940`); while it is `true` the DPAD/L1/R1/L2/R2
key-down events call `m2179v("<slot>", isRepeat)` instead of their normal navigation behaviour
(`:1670, :1684, :1701, :1731, :1763, :1804, :1843, :1867`). `m2179v` (`:4613-4916`) then reads the three
prefs **live** and executes the action, with a **Pro gate first** (`:4617-4622`,
log `"Action blocked: Pro status required"`), a **300 ms debounce** (`:4623-4629`) and a haptic tick
(`pref_haptic_feedback`, 50 ms) whenever the type is not `"none"` (`:4644-4654`).

### 6.2 Full action list (order = index in the selection dialog, `ViewOnClickListenerC0837sy.java:61`)

| idx | stored `type` | `R.string` label | UI text | extra behaviour on selection |
|---|---|---|---|---|
| 0 | `none` | `action_none` | None | clears type only |
| 1 | `app` | `action_launch_app` | Launch App | opens launcher-app picker (see below); stores `value = packageName` |
| 2 | `home` | `action_home` | Home | |
| 3 | `recents` | `action_recents` | Recents | |
| 4 | `vol_up` | `action_vol_up` | Volume Up | |
| 5 | `vol_down` | `action_vol_down` | Volume Down | |
| 6 | `mute` | `action_mute` | Mute | |
| 7 | `bright_up` | `action_bright_up` | Brightness Up | calls `m2107m()` (WRITE_SETTINGS prompt) first |
| 8 | `bright_down` | `action_bright_down` | Brightness Down | calls `m2107m()` |
| 9 | `media_forward` | `action_media_forward` | Fast Forward (10s) | |
| 10 | `media_rewind` | `action_media_rewind` | Rewind (10s) | |
| 11 | `screenshot` | `action_screenshot` | Screenshot | |
| 12 | `rotate` | `action_rotate` | Screen Rotation | calls `m2107m()` |
| 13 | `click_location` | `action_click_location` | Click Specific Location | sets `value = ""`, shows `click_location_guide_title` / `click_location_guide_msg` (OK only) |
| 14 | `click_location_repeat` | `action_click_location_repeat` | Repeat Click at Location | if previous type ≠ repeat → `value = ""` and show `click_location_repeat_guide_title` / `..._msg` with OK → `m2113z(slot)` (interval picker) / Cancel; if already repeat → straight to `m2113z(slot)` |

Dialog title: `getString(R.string.select_action_title, slot.toUpperCase(Locale.ROOT))` — "Select Action for X + RB".
Implemented in `p000/l20.java:37-170` (dialog listener) + `ViewOnClickListenerC0837sy.java:47-72` (opener).

**App picker** (`l20.java:55-76`, `p000/p20.java`, `p000/u20.java`, `p000/t20.java`):
`PackageManager.queryIntentActivities(Intent(ACTION_MAIN).addCategory(CATEGORY_LAUNCHER), 0)`, sorted by
lower-cased label (`t20` case 0), rendered with `R.layout.item_app_picker` (`img_app_icon`, `txt_app_name`),
title `R.string.select_app`; selecting one writes `type="app"`, `value=<activityInfo.packageName>` (`p20.java:105`).
If the app later disappears, the label falls back to `R.string.app_not_found` (`MainActivity.java:516`).

### 6.3 "Click location" payload format

* Stored in `pref_mapping_x_<slot>_value` as **`String.format(Locale.US, "%.1f,%.1f", x, y)`** — two floats
  separated by a comma, one decimal place (`MouseAccessibilityService.java:4849`, `:4888`).
* `x`/`y` are the current overlay cursor position in display pixels.
* Capture only happens if the cursor is on (`f4145b0`), otherwise toast
  `R.string.toast_turn_on_mouse_to_capture`.
* Parsed back by `m2144W(slot)` and clicked with `m2174q(x, y)` (`:4836-4843`).
* `click_location`: press = click at the stored point; if `value` empty = capture.
* `click_location_repeat`: only one slot can be repeating at a time (`f4190u`).
  * press when already repeating on this slot → stop (+ toast `toast_repeat_stopped`);
  * press when repeating on another slot → move repeat there (toast `toast_repeat_replaced`);
  * press with a stored coordinate → start repeating every `_interval` ms (toast
    `toast_repeat_started_format` with `repeat_interval_format`);
  * press with empty `value` → capture coordinate (toast `toast_repeat_location_captured`).
* `pref_mouse_enabled = false` stops repeating (`toast_repeat_stopped_cursor`); changing a slot's `_type`
  away from `click_location_repeat` stops it (`j20.java:526-535`).

### 6.4 Repeat-interval editor (`m2113z`, `MainActivity.java:4366-4449`)
* Triggered by **long-pressing a mapping row** whose current type is `click_location_repeat`
  (`k20` / `MainActivity.java:3699-3718`).
* Current value clamped with `lo0.m5054i(value, 100, 3000)` (default 500).
* Single-choice list: each item of `f4064J` formatted with `R.string.repeat_interval_format`
  (`%1$.1fs`) + a final `R.string.repeat_interval_custom` ("Custom…"); preselected index = index of the
  clamped value, else the last ("Custom…").
* Choosing a preset → `pref_mapping_x_<slot>_interval = <preset>`, then `m2102A()`.
* Choosing "Custom…" → second dialog with `EditText` (`inputType=2` numeric, prefilled with the current value,
  hint `R.string.repeat_interval_hint` = "Milliseconds (100 ~ 3000)", padding 48/24/48/0 dp, soft keyboard
  forced with `window.setSoftInputMode(4)`); OK (`i20` default case) parses an int, validates
  **100 ≤ v ≤ 3000** (else toast `R.string.repeat_interval_range_msg`) and stores it.

### 6.5 Mapping label rendering (`m2102A`, `MainActivity.java:443-608`)
For each of the 8 slots, read `_type` (default `"none"`) and `_value` (default `""`) and set
`tv_map_x_<slot>_val`:

| type | label |
|---|---|
| `none` / unknown | `R.string.action_none` |
| `home`,`recents`,`vol_up`,`vol_down`,`mute`,`bright_up`,`bright_down`,`media_forward`,`media_rewind`,`screenshot`,`rotate` | the corresponding `R.string.action_*` |
| `app` | `PackageManager.getApplicationLabel(getApplicationInfo(value, 0))`; on exception `R.string.app_not_found` |
| `click_location` | `action_click_location` + `" (" + value + ")"` when value non-empty |
| `click_location_repeat` | `action_click_location_repeat` + `" · " + getString(R.string.repeat_interval_format, interval/1000.0)` + optional `" (" + value + ")"` |

### 6.6 Default mapping table (as coded)

First-run defaults, written with `putString(...).apply()` only when the key is absent
(`MainActivity.java:981-1055`):

| slot | default type |
|---|---|
| `up` | `vol_up` |
| `down` | `vol_down` |
| `lb` | `mute` |
| `left` | `media_rewind` |
| `right` | `media_forward` |
| `rt` | `screenshot` |
| `rb` | `none` (explicitly written) |
| `lt` | *(nothing written — reads as `"none"`)* |

`_value` and `_interval` are never defaulted on first run (⇒ `""` / `500`).

"Reset All Settings" (`c20.java:42-86`) removes all three keys for all 8 slots and then re-applies exactly the
same six defaults; it also rewrites every other preference to its default **except**
`pref_cursor_color`, `pref_language`, `pref_initial_setup_shown`, `pref_drawer_hint_done`,
`pref_l3_toggle_enabled` and the Pro file. Notable pro-dependency in the reset: `pref_haptic_feedback` and
`pref_keyboard_enabled` are set to `db0.m2408b()` (i.e. `true` only for Pro), and `pref_dex_speed` is only
written when Pro (`c20.java:47`, `:50`, `:53-55`). After the reset: toast
`R.string.settings_reset_toast`, `finish()`, re-`startActivity(getIntent())`, `overridePendingTransition(0,0)`.

### 6.7 Cursor toggle key (`pref_toggle_keycode`)
* Default `106` = `KEYCODE_BUTTON_THUMBL` ("L3").
* Chooser dialog (`v10` case 7, duplicated at `MainActivity.java:1673-1712` etc.): title
  `press_gamepad_button_title`, message `press_gamepad_button_msg`, neutral `reset_toggle_key_default`
  ("Reset to Default (L3)") → `c20` case 2 → keycode 106, negative `cancel`, and a
  `DialogInterface.OnKeyListener` (`d20`) that intercepts **key-down** events:
  * keycodes `19,20,21,22,23` (D-pad) and `4,24,25,26` (BACK/VOLUME_UP/VOLUME_DOWN/CAMERA) are **rejected**
    with `Toast(R.string.toast_dpad_not_allowed)`;
  * anything else is stored (`putInt`) and the dialog is dismissed.
* Display (`m2106E`, `:777-839`): hard-coded names for 96–110:

| code | label |
|---|---|
| 96 | `Button A` |
| 97 | `Button B` |
| 99 | `Button X` |
| 100 | `Button Y` |
| 102 | `L1 (LB)` |
| 103 | `R1 (RB)` |
| 104 | `L2 (LT)` |
| 105 | `R2 (RT)` |
| 106 | `L3` |
| 107 | `R3` |
| 108 | `Start` |
| 109 | `Select` |
| 110 | `Mode (Xbox)` |
| other | `KeyEvent.keyCodeToString(i)` with `"KEYCODE_BUTTON_"` and `"KEYCODE_"` prefixes stripped |

---

## 7. Settings features — UI, mapping, application

Legend for "apply": no Intent is sent; the write lands in `GamepadMousePrefs` and the service's `j20`
listener updates its cached field.

### 7.1 General page (`layout_settings_general`)

| UI | id | Pref | Value mapping | Apply |
|---|---|---|---|---|
| Switch "Mouse Service Enabled" | `switch_mouse_enabled` | `pref_mouse_enabled` (true) | on/off | `j20.java:397-423` → `f4129T`, hides cursor & stops repeat when off; analytics `toggle_mouse_service` with `Bundle{"enabled": bool}` (`u10.java:66-71`) |
| Row "Change Activation Button" (`tv_customize_toggle_key_label` + `tv_current_toggle_key`) | `btn_customize_toggle_key` | `pref_toggle_keycode` (106) | see §6.7 | `f4170n0` |
| "Long Press Duration" + `tv_l3_long_press_val` | `seekbar_l3_long_press`, `max=10` | `pref_l3_long_press_duration` (0) | `0`→"Instant", else `p/10` s (`m2108o`) | `f4176p0` |
| Switch "Swap A/B Buttons" + desc | `switch_swap_ab_buttons`, `tv_swap_ab_buttons_desc` | `pref_swap_ab_buttons` (false) | | `f4173o0` |
| Switch "Enable DeX Mode Lockscreen (Pro)" + desc | `switch_dex_lockscreen`, `tv_dex_lockscreen_desc` | `pref_dex_lockscreen_enabled` (false) | Pro-gated | `f4131U` |
| Switch "Mirroring Mode" + desc | `switch_force_mirroring`, `tv_force_mirroring_desc` | `pref_force_mirroring` (false) | | `f4090F` |
| Switch "Haptic Feedback (Pro)" | `switch_haptic_feedback` | `pref_haptic_feedback` (true) | Pro-gated | read live |
| Switch "Pro Version (Debug Override)" + desc | `switch_debug_pro`, `tv_debug_pro_desc` | *Pro file* `debug_pro_override` (true) | only visible if `db0.f4578b` | `db0.f4579c` + broadcast |
| "Vibration Intensity" + `tv_vibration_intensity_val` | `seekbar_vibration_intensity`, `max=255` | `pref_vibration_intensity` (255) | 0–255 | amplitude (`MouseAccessibilityService.java:4046`) |
| Language row | `btn_select_language`, `tv_current_language` | `pref_language` ("en") | `en`/`ko`/`es` | `recreate()` |
| "Reset to Defaults" | `btn_reset_defaults` | – | – | see §6.6 |

### 7.2 Pointer & sensitivity page (`layout_settings_pointer`)

| UI | id (max) | Pref (default) | formula / display | Apply |
|---|---|---|---|---|
| Cursor style row | `btn_select_cursor_style`, `tv_current_cursor_style` | `pref_cursor_style` ("orange"), `pref_cursor_color` ("#FFA000") | see §7.3 | service `f4135W`/`f4137X` (re-render cursor) |
| "Cursor Size" + `tv_size_val` | `seekbar_size`, `max=200` | `pref_mouse_size` (100) | progress = value; write `max(p,40)`; label = number | `f4120P` + `m2167l0()` |
| "Pointer Speed" + `tv_speed_val` | `seekbar_speed`, `max=200` | `pref_mouse_speed` (50) | write `max(p,10)`; label = number | `f4114N` |
| "DeX Pointer Speed (Pro)" + `tv_dex_speed_val` | `seekbar_dex_speed`, `max=200` | `pref_dex_speed` (35) | write `max(p,10)`; label = number; disabled when free | `f4117O` |
| "Sensitivity (Curve)" + `tv_sensitivity_val` | `seekbar_sensitivity`, `max=20` | `pref_mouse_sensitivity` (20) | progress `p`; **value `p+10`**; label `String.format("%.1f", (p+10)/10f)` ⇒ 1.0–3.0; analytics `change_sensitivity` `{value: float}` | `f4123Q = v/10f` |
| "Auto-Hide Timeout" + `tv_timeout_val` | `seekbar_timeout`, `max=56` | `pref_mouse_timeout` (0) | progress→value: `p==0 ? 0 : p+4` ⇒ 0 = "Never", else `"<v>s"` (5–60 s); reverse map for display: `0→0`, `<5→1`, else `v-4` | `f4133V` |
| "Scroll Speed" + `tv_scroll_speed_val` | `seekbar_scroll_speed`, `max=400` | `pref_scroll_speed` (100) | write `max(p,10)`; analytics `change_scroll_speed` `{value:int}` | `f4125R = v/50f` |
| "Gamepad Deadzone" + `tv_deadzone_val` | `seekbar_deadzone`, `max=50` | `pref_deadzone` (15) | clamp `max(p,1)`, float `v/100`, label `"%.2f"`; also sets `f4069v`; analytics `change_deadzone` `{value:float}` | `f4127S = v/100f` |
| Stick test block | `tv_lstick_val`, `progress_lstick_test` (max 100), `tv_rstick_val`, `progress_rstick_test` (max 100), `tv_test_status` | – | live from `onGenericMotionEvent` | – |

### 7.3 Cursor style picker (`btn_select_cursor_style`, `f20`/`m20`/`ViewOnClickListenerC0837sy` 2/`o20` 0)
1. Dialog title `R.string.cursor_style`, cancel only; body = vertical `LinearLayout`, padding
   16/4/16/8 dp with two 16 sp rows (padding 8/14/8/14 dp): `cursor_custom_color`, `cursor_custom_png`.
2. **Custom Color** → scrollable dialog title `R.string.cursor_custom_color`, content padding 12/8/12/4 dp,
   a 5-column grid over `f4066L` **plus a trailing `null` entry** (36 colours + "Type HEX"), each cell
   `TextView`: gravity center, text size 10 sp, padding 4/10/4/10 dp, `LayoutParams(0, 46dp, weight=1)`,
   margin 3 dp, background = the colour, cell text = the hex string (or `"✓ " + hex` for the current value);
   text colour = white when perceived luma `0.299R+0.587G+0.114B < 140` else black.
   The `null` cell renders `"#E0E0E0"` background, black text, label `R.string.cursor_color_manual`
   ("Type HEX") and opens a single-line `EditText` dialog (`ViewOnClickListenerC0837sy` case 2 →
   `FrameLayout` padding 16 dp, hint `#FFA000`, prefilled with `pref_cursor_color`; OK → `o20` case 0 →
   `m2096q(text)`; invalid → toast `R.string.cursor_color_invalid`; valid → `pref_cursor_color = normalized`,
   `pref_cursor_style = "custom_color"`, `m2104C()`).
3. **Custom PNG** → `f4062H.launch("image/png", null)`; on result (`C0296eb.onActivityResult`): read stream,
   decode bounds, compute power-of-two `inSampleSize` so that `min(w,h)/sampleSize >= 512`, decode,
   downscale so max edge ≤ `f4061G` (512), compress PNG at quality 100 into
   `getFilesDir()/custom_cursor.png`, set `pref_cursor_style = "custom"`, `m2104C()`.
   On any exception: `Toast(R.string.cursor_png_load_failed)`.
4. `m2104C()` label + migration (`MainActivity.java:671-754`): if `pref_cursor_style` is one of the legacy
   names in `f4065K`, rewrite `pref_cursor_style="custom_color"` + `pref_cursor_color=<hex>`;
   if `"custom"` but the PNG is missing/0-length/undecodable → delete it and fall back to `"orange"`;
   if `"custom_color"` but `m2096q(pref_cursor_color)` is invalid → fall back to `"orange"`;
   label = `cursor_custom_color + " (" + hex + ")"`, or `cursor_custom_png`, or `cursor_color_orange`.

### 7.4 Keyboard page (`layout_settings_keyboard`) — fully Pro-gated
`m2100u` disables/enables these views and sets the page `alpha` to `0.5` (free) / `1.0` (Pro)
(`MainActivity.java:353-385`).

| UI | id (max) | Pref (default) | formula |
|---|---|---|---|
| Switch "Gamepad Keyboard Input (Pro)" + desc | `switch_keyboard_input`, `tv_keyboard_input_desc` | `pref_keyboard_enabled` (true) | Pro gate via `a20` case 1 |
| KB test field (title/desc/seed text) | `edittext_kb_test` (initial text `R.string.kb_test_seed`) | – | Pro-gated only |
| "Keyboard languages" | `cb_kb_lang_en`, `cb_kb_lang_ko`, `cb_kb_lang_es` | `pref_kb_lang_en` (true), `pref_kb_lang_ko` (true), `pref_kb_lang_es` (false) | cannot untick the last one → toast `R.string.kb_lang_min_toast` and re-check |
| "Key move repeat interval (sec)" + `tv_kb_repeat_val` | `seekbar_kb_repeat`, `max=45` | `pref_kb_nav_interval` (150) | progress = `(v-50)/10`; value = `p*10+50`; label = `m2095n(v)` = `"%.2f"` of v/1000 |
| "Key move hold delay (sec)" + `tv_kb_delay_val` | `seekbar_kb_delay`, `max=26` | `pref_kb_nav_delay` (300) | progress = `(v-200)/50`; value = `p*50+200`; label `m2095n(v)` |
| Switch "Key move sound" + desc | `switch_kb_move_sound`, `tv_kb_move_sound_desc` | `pref_kb_move_sound` (false) | |
| "DeX keyboard width" + `tv_kb_dex_width_val` | `seekbar_kb_dex_width`, `max=80` | `pref_kb_dex_width` (50) | progress `v-20`; value `p+20`; label `kb_dex_pct_format` (`%1$d%%`) |
| "DeX keyboard height" + `tv_kb_dex_height_val` | `seekbar_kb_dex_height`, `max=32` | `pref_kb_dex_height` (100) | progress `(v-40)/5`; value `p*5+40`; label `%d%%` |
| "DeX keyboard position" | `cb_kb_dex_pos_left/center/right` | `pref_kb_dex_pos` ("center") | exclusive selection via `m2097r` (guard `f4058D`) |
| Guide text | `tv_kb_guide` | – | `R.string.kb_guide_body`, plus `"\n" + kb_guide_es_line` when `pref_kb_lang_es` (`m2105D`, `:757-774`) |

Important: the four *keyboard* seek bars (`kb_nav_interval`, `kb_nav_delay`, `kb_dex_width`,
`kb_dex_height`) only persist in `onStopTrackingTouch`; all *pointer* seek bars persist on every
`onProgressChanged` (`r20.java:181-239` vs `:33-173`).

### 7.5 Pro tab (`layout_pro_tab`)

| id | contents |
|---|---|
| `tv_pro_status` | `pro_version_active` (colour `android.R.color.holo_green_dark` `#669900`) or `pro_version_inactive` (colour `R.color.text_primary` `#1f1f1f`) |
| `tv_pro_desc` | `R.string.pro_desc` (feature list) |
| `btn_buy_pro` | `R.string.upgrade_to_pro`; hidden when Pro |
| `layout_pro_r3_desc` | multi-display explanation; **hidden for free users** (`GONE`) |
| `custom_key_mapping` label | `R.string.custom_key_mapping` ("Custom Key Mapping (X + Button)") |
| 8 mapping rows | `btn_map_x_<slot>` + `tv_map_x_<slot>_val` |

`m2100u` (`MainActivity.java:299-393`) is the single "sync Pro UI" routine:
* Pro → status text/colour active, hide buy button + `tv_pro_desc`, show `layout_pro_r3_desc`;
  Free → inactive, show buy button + desc, hide `layout_pro_r3_desc`;
* force-off and **disable** `switch_haptic_feedback`, `switch_dex_lockscreen`, `switch_keyboard_input`,
  `seekbar_vibration_intensity`, `seekbar_dex_speed` when free; set `tv_dex_lockscreen_desc` /
  `tv_keyboard_input_desc` alpha `0.5` vs `1.0`;
* enable/disable the 12 keyboard views (`cb_kb_lang_en/ko/es`, `seekbar_kb_repeat`, `seekbar_kb_delay`,
  `switch_kb_move_sound`, `seekbar_kb_dex_width`, `seekbar_kb_dex_height`,
  `cb_kb_dex_pos_left/center/right`, `edittext_kb_test`) and set `layout_settings_keyboard` alpha 0.5/1.0;
* refresh the `nav_pro` menu title (`m2110v()`), and if the current page is the Pro tab, the toolbar title.

The same routine is re-invoked through `w10` whenever the Pro state changes (`C0360g` → `h20` → `m2103B` + `m2100u`).

### 7.6 Ads
* `m2112y()` (`:4349-4363`): `f4071x = findViewById(R.id.layout_ad_container)`, ensures `f4060F` is registered
  in `db0.f4582f`, then `m2103B(db0.m2408b())`.
* `m2103B(boolean isPro)` (`:611-661`):
  * Pro: container `GONE`, `removeAllViews()`, `adView.pause()`.
  * Free: container `VISIBLE`; lazily create `AdView` with `AdSize.BANNER`,
    `setAdUnitId(R.string.admob_banner_id)` = `ca-app-pub-3134210842182311/5819818753`,
    `setAdListener(v20)` (on `onAdLoaded` → container `VISIBLE` unless Pro; on `onAdFailedToLoad` → log only),
    add to container, `loadAd(new AdRequest.Builder().build())`.
  * All wrapped in `try/catch(Throwable)` logging `"AdMob"`.
* App id in manifest: `ca-app-pub-3134210842182311~8381673963` (`AndroidManifest.xml:76-78`).
* `MobileAds.initialize(this, no-op listener)` at `:973`.

---

## 8. Numeric constants (complete)

| Constant | Value | Where / meaning | Lines |
|---|---|---|---|
| Dead-zone default | `0.15f` | `f4069v`, stick-test threshold; `pref_deadzone` 15/100 | 166, 4196 |
| Dead-zone UI range | 1–50 → 0.01–0.50 | `seekbar_deadzone max=50` | layout 539-545 |
| `pref_mouse_size` range | 40–200 (default 100) | `seekbar_size max=200` | 2725-2732 |
| `pref_mouse_speed` range | 10–200 (default 50) | `seekbar_speed max=200` | 2386-2393 |
| `pref_dex_speed` range | 10–200 (default 35) | `seekbar_dex_speed max=200` | 2394-2401 |
| sensitivity | value 10–30, ×0.1 ⇒ 1.0–3.0 (default 20 ⇒ 2.0) | `seekbar_sensitivity max=20`, progress=v-10 | 2733-2740 |
| auto-hide timeout | 0 (never) or 5–60 s in 1 s steps (default 0) | `seekbar_timeout max=56`, value=p+4 | 2741-2760 |
| scroll speed | 10–400 (default 100); service multiplier v/50 ⇒ 0.2–8.0 | `seekbar_scroll_speed max=400` | 2761-2768 |
| vibration intensity | 0–255 (default 255) | `seekbar_vibration_intensity max=255` | 2378-2385 |
| long press duration | 0–10 ⇒ 0–1.0 s, step 0.1 s (default 0 = instant) | `seekbar_l3_long_press max=10` | 2031-2038, `m2108o` |
| `pref_kb_nav_interval` | 50–500 ms, step 10 (default 150) | `seekbar_kb_repeat max=45` | 2310-2317 |
| `pref_kb_nav_delay` | 200–1500 ms, step 50 (default 300) | `seekbar_kb_delay max=26` | 2318-2325 |
| `pref_kb_dex_width` | 20–100 % (default 50) | `seekbar_kb_dex_width max=80` | 2331-2338 |
| `pref_kb_dex_height` | 40–200 %, step 5 (default 100) | `seekbar_kb_dex_height max=32` | 2339-2346 |
| repeat interval presets | `100, 200, 500, 1000, 2000, 3000` ms | `f4064J` | 180 |
| repeat interval default | `500` ms | `getInt(..., "_interval", 500)` | 570, 4369 |
| repeat interval clamp | `100 … 3000` | `lo0.m5054i` | 4369, 4414 |
| cursor PNG max edge | `512` px | `f4061G` = `AdRequest.MAX_CONTENT_URL_LENGTH` | 172, `C0296eb.java:238` |
| colour-grid candidate luma threshold | `140.0f` | white vs black cell text | 1302-1306 |
| colour grid cell height | `46dp`, margin `3dp`, text `10sp`, hr padding `4dp/10dp` | 1296-1299 |
| colour grid columns | `5` | 1265-1271 |
| drawer hint delay | `900 ms` | `postDelayed(..., 900L)` | 4341 |
| drawer hint popup auto-dismiss | `10000 ms` | `WorkRequest.MIN_BACKOFF_MILLIS` | `RunnableC0151b2` case 7 |
| touch-slop for switch/checkbox intercept | `8dp` (`density * 8.0f`), ratio `1.5` | `m2101w` | 400, 415 |
| initial-setup dialog width | `0.9 * widthPixels` | | 2719 |
| initial-setup dialog radius/elevation | 16 dp / 8 dp (CardView, in layout) | `dialog_initial_setup.xml` | |
| service action debounce | `300 ms` | mapping execution | `MouseAccessibilityService.java:4625` |
| service haptic tick | `50 ms` | on mapped action | `:4648` |

Label formatters:
* `m2095n(int ms)` = `String.format(Locale.US, "%.2f", ms/1000f)` (`:186-188`).
* `m2108o(int tenths)` = `"Instant"` if 0 else `String.format(Locale.US,"%.1f", v/10f) + "s"` (`:874-881`).
* `m2096q(String)` = colour normalizer: accepts `#RGB`, `#RRGGBB`, `RGB`, `RRGGBB`
  (`^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$`), expands 3-digit to 6, upper-cases, prefixes `#`; returns
  `null` when invalid (`:191-229`).

### 8.1 Scroll/gate helper `m2101w(View)` (`:398-438`)
Recursively walks the view tree; for every `SwitchCompat`/`CheckBox` installs an `OnTouchListener` that, when a
drag exceeds `8dp` horizontally and is more than `1.5×` the vertical delta, calls
`parent.requestDisallowInterceptTouchEvent(true)` so a horizontal drag on a switch inside the scroll view does
not start the drawer.

---

## 9. Pro / IAP (paywall)

| Item | Value |
|---|---|
| Billing library | `com.android.billingclient:billing` 9.0.0 (`AndroidManifest.xml:101-103`) |
| Product id | **`pro_upgrade`**, type `BillingClient.ProductType.INAPP` (one-time) (`db0.java:226`) |
| Price | not hard-coded; comes from Play `ProductDetails` (query → `BillingFlowParams` → `launchBillingFlow`, `C0296eb.java:onProductDetailsResponse`) |
| Pro flag | `GamepadMouseProPrefs` → `is_pro_version` (bool) (`db0.java:192`, `:206`) |
| Verification | none client-side beyond `Purchase.getPurchaseState()==1` + acknowledge (`cb0.java:45-60`); `queryPurchases` re-checks on connect (`cb0.java:65-86`) |
| Debug override | only if `ApplicationInfo.flags & FLAG_DEBUGGABLE`; switch in General page writes `debug_pro_override` (default `true`) — `db0.java:189-201`, `u10.java:44-55` |
| listeners | `db0.f4582f` list; activity registers `f4060F`; on change → `m2103B` + `m2100u` (`C0360g`, `h20`) |

### 9.1 Feature gating matrix

| Feature | Free | Pro | Gate location |
|---|---|---|---|
| Banner ads | shown | hidden & paused | `m2103B` (`:611`), `onAdResume` guard (`:4256`) |
| Custom key mapping (all 8 rows) | click → "Pro Feature" dialog | editable | `ViewOnClickListenerC0837sy` case 1 (`:51-60`) — hard-coded English strings here |
| Haptic feedback switch | forced off + disabled | usable | `m2100u:319-323`, `a20` case 2 |
| Vibration intensity seekbar | disabled; any touch snaps to 255 + Pro dialog | usable | `m2100u:351`, `s20.java:30-52` |
| DeX lockscreen switch | forced off + disabled | usable | `m2100u:324-337`, `a20` case 0 |
| DeX pointer speed seekbar | disabled | usable | `m2100u:352` |
| Keyboard input switch + entire keyboard page | forced off, all controls disabled, page alpha 0.5 | usable | `m2100u:338-385`, `a20` case 1 |
| Multi-display (R3 / DeX) description block | hidden (`layout_pro_r3_desc` GONE) | shown | `m2100u:311/317` |
| Click-location / repeat-click actions | not reachable through UI (mapping locked) and blocked in the service | allowed | `MouseAccessibilityService.java:4615-4621` |
| Everything else (cursor, speeds, size, timeout, scroll, deadzone, language, reset, toggle key, ads for Pro…) | free | free | – |

Paywall dialog strings: `pro_feature` ("Pro Feature"), `upgrade` ("Upgrade"), `cancel`, plus
`dex_pro_msg`, `keyboard_pro_required`, `haptic_pro_msg`, `vibration_pro_msg`. Positive button always calls
`db0.m2411e(activity)` (case 3/4/5/7 of `c20`, case 0/default too).

### 9.2 License check (pairip) — implications for a re-implementation
`AndroidManifest.xml` sets `android:name="com.pairip.application.Application"` (`:68`) and declares
`com.pairip.licensecheck.LicenseActivity` (`:335-337`), plus `com.android.vending.CHECK_LICENSE`
(`:354`). This is Google Play's **pairip** integrity/licence wrapper: `Application.attachBaseContext`
runs a native VM check and starts `LicenseActivity` when the licence/signature check fails, which then exits
the app (typically "download from Play"). Practical consequences for a clean re-implementation:
* do not port pairip — it is not app behaviour and cannot work outside the signed Play distribution;
* the "Pro" state is only persisted locally, so a re-implementation must implement its own billing;
* all `db0.*` calls are safe no-ops until billing connects (`f4581e`), so the UI degrades to "free" if
  Play Billing is unavailable.

---

## 10. Device / vendor-specific code

* **Samsung DeX** — there is **no** `Build.MODEL` string test, no `sem.*` reflection, no
  `Configuration.DESKTOP_MODE` check in `MainActivity` (verified by grep). DeX is handled structurally:
  * settings: `pref_dex_lockscreen_enabled`, `pref_dex_speed`, `pref_force_mirroring`,
    `pref_kb_dex_width/height/pos` (the last three size/position the on-screen keyboard on the external
    monitor);
  * the service decides "DeX" by inspecting the `DisplayManager` and `Display.getDisplayId() != 0`
    (`MouseAccessibilityService.java:3331`, `:3530`, `:3718-3724`), shows a "blackout" overlay
    (`WindowManager.LayoutParams` type 2032, `screenBrightness = 0.1f`, `:3705-3706`) and follows
    `Display.FLAG_*`/`DisplayManager` callbacks; it also drives DeX window chrome by
    walking the accessibility tree for the "Restore" / title-bar handle (`:2689-2757`).
* **`Settings` keys written** (by the service, never by the activity):
  `accelerometer_rotation = 0` and `user_rotation = 0|1` for the *rotate* action
  (`MouseAccessibilityService.java:4685-4689`, guarded by `Settings.System.canWrite`);
  `screen_brightness` for *brightness up/down* (`m2147a(±25)`, `:4674`, `:4901`).
* **`WRITE_SETTINGS`** — declared in manifest, checked in `m2107m` (`:862`) and in the service before
  writing (`:4681`); prompt path is `MANAGE_WRITE_SETTINGS` with `package:` URI (`c20.java:111`).
* **Vibration** uses the *gamepad's own* vibrator: iterate `InputDevice.getDeviceIds()`, require
  `sources & 1025 == 1025` (SOURCE_GAMEPAD) and `device.getVibrator().hasVibrator()`, then
  `VibrationEffect.createOneShot(durationMs, pref_vibration_intensity)`
  (`MouseAccessibilityService.java:4031-4052`) — Pro only.
* Screenshot uses `AccessibilityService.takeScreenshot` with `canTakeScreenshot="true"` in the config; falls
  back to `performGlobalAction(GLOBAL_ACTION_TAKE_SCREENSHOT)` on failure (`:1989-2000`).

---

## 11. Resource inventory (must be reproduced exactly)

### 11.1 Layouts used by `MainActivity`
| Layout | Purpose |
|---|---|
| `activity_main.xml` (83 KB) | whole screen: `DrawerLayout` (`main`) → `main_content` (Coordinator/AppBar with `main_toolbar`, `content_container` holding the 6 page layouts, `layout_bottom_bar` with `layout_ad_container`) + `drawer_container` with `NavigationView` (`nav_drawer`) and `tv_drawer_version` |
| `dialog_initial_setup.xml` | CardView (radius 16 dp, elevation 8 dp, `@color/surface`), ScrollView → LinearLayout 24 dp padding: title 20 sp bold `accessibility_disclosure_title`, body 14 sp `accessibility_disclosure_text`, divider, two buttons `btn_dialog_decline` (`accent_red`, text button) / `btn_dialog_accept` (`accent_blue` filled) |
| `dialog_full_screen_image.xml` | black FrameLayout + `iv_full_screen` (`@drawable/guide`, fitCenter) + "Tap to close" 12 sp `#88ffffff` |
| `drawer_header.xml` | 110 dp horizontal bar, launcher icon 44 dp + app name 18 sp bold |
| `drawer_menu.xml` | 4 groups: Settings (`nav_general_settings`, `nav_pointer_settings`), Pro (`nav_pro`, `nav_keyboard_settings`), Manual (`nav_initial_setup`, `nav_how_to_use`), App (`nav_share`, `nav_rate`, `nav_contact`) |
| `item_app_picker.xml` | `img_app_icon` + `txt_app_name` for the launch-app picker |

### 11.2 View ids referenced from code (all of them)
`main`, `main_content`, `drawer_container`, `main_toolbar`, `content_container`,
`layout_settings_general`, `layout_settings_pointer`, `layout_settings_keyboard`, `layout_pro_tab`,
`layout_initial_setup`, `layout_how_to_use`, `layout_bottom_bar`, `layout_ad_container`, `nav_drawer`,
`tv_drawer_version`, `nav_general_settings`, `nav_pointer_settings`, `nav_keyboard_settings`, `nav_pro`,
`nav_initial_setup`, `nav_how_to_use`, `nav_share`, `nav_rate`, `nav_contact`,
`switch_mouse_enabled`, `btn_customize_toggle_key`, `tv_customize_toggle_key_label`, `tv_current_toggle_key`,
`l3_long_press_duration`(label text), `tv_l3_long_press_val`, `seekbar_l3_long_press`,
`switch_swap_ab_buttons`, `tv_swap_ab_buttons_desc`, `switch_dex_lockscreen`, `tv_dex_lockscreen_desc`,
`switch_force_mirroring`, `tv_force_mirroring_desc`, `switch_haptic_feedback`, `switch_debug_pro`,
`tv_debug_pro_desc`, `seekbar_vibration_intensity`, `tv_vibration_intensity_val`,
`btn_select_language`, `tv_current_language`, `btn_reset_defaults`,
`btn_select_cursor_style`, `tv_current_cursor_style`, `seekbar_size`, `tv_size_val`, `seekbar_speed`,
`tv_speed_val`, `seekbar_dex_speed`, `tv_dex_speed_val`, `seekbar_sensitivity`, `tv_sensitivity_val`,
`seekbar_timeout`, `tv_timeout_val`, `seekbar_scroll_speed`, `tv_scroll_speed_val`, `seekbar_deadzone`,
`tv_deadzone_val`, `progress_lstick_test`, `progress_rstick_test`, `tv_lstick_val`, `tv_rstick_val`,
`tv_test_status`, `switch_keyboard_input`, `tv_keyboard_input_desc`, `edittext_kb_test`,
`cb_kb_lang_en`, `cb_kb_lang_ko`, `cb_kb_lang_es`, `seekbar_kb_repeat`, `tv_kb_repeat_val`,
`seekbar_kb_delay`, `tv_kb_delay_val`, `switch_kb_move_sound`, `tv_kb_move_sound_desc`,
`seekbar_kb_dex_width`, `tv_kb_dex_width_val`, `seekbar_kb_dex_height`, `tv_kb_dex_height_val`,
`cb_kb_dex_pos_left`, `cb_kb_dex_pos_center`, `cb_kb_dex_pos_right`, `tv_kb_guide`,
`tv_pro_status`, `tv_pro_desc`, `btn_buy_pro`, `layout_pro_r3_desc`,
`btn_map_x_lb`, `btn_map_x_rb`, `btn_map_x_lt`, `btn_map_x_rt`, `btn_map_x_up`, `btn_map_x_down`,
`btn_map_x_left`, `btn_map_x_right`, `tv_map_x_lb_val`, `tv_map_x_rb_val`, `tv_map_x_lt_val`,
`tv_map_x_rt_val`, `tv_map_x_up_val`, `tv_map_x_down_val`, `tv_map_x_left_val`, `tv_map_x_right_val`,
`btn_open_settings`, `btn_battery_optimization`, `iv_guide`, `iv_full_screen`,
`btn_dialog_accept`, `btn_dialog_decline`, `img_app_icon`, `txt_app_name`,
`drawer_hint_bubble`(string only).

### 11.3 Drawables / colors / styles
* Drawables: `guide` (full-screen manual image), `bubble_hint_bg` (popup background), `ic_settings`,
  `ic_mouse_cursor_white`, `ic_star_yellow`, `ic_keyboard`, `ic_help`, `ic_manual`, `ic_share`, `ic_star`,
  `ic_mail`, `mipmap/ic_launcher(_round)`.
* App colors: `accent_red #c62828`, `accent_blue #2196f3`, `surface #ffffff`, `divider #d3d8dc`,
  `drawer_header_bg #dde8f4`, `text_primary #1f1f1f`, `text_secondary #37474f`, `text_muted #616161`,
  `text_faint #777777`, `text_value #5f5f5f`, `text_guide #455a64`, `app_bg #f4f6f8`, `icon_tint #546e7a`,
  `accent_orange #e65100`, `accent_green #2e7d32`, `accent_pro #8a5a00`.
* Android colors: `holo_green_dark #669900`, `holo_blue_light #33b5e5`, `darker_gray #444444`.
* Styles: app theme `Theme.GamepadMouse` (`styles.xml`), `android Theme.Black.NoTitleBar.Fullscreen` for the
  guide dialog.
* The 36-colour palette (`f4066L`, `MainActivity.java:182`), in order:
  `#F44336 #E53935 #B71C1C #FF8A80 #8E0E4F #E91E63 #F06292 #F48FB1 #9C27B0 #CE93D8 #4A148C #3F51B5
   #2196F3 #1976D2 #82B1FF #00BCD4 #4DD0E1 #006064 #4CAF50 #2E7D32 #A5D6A7 #00C853 #FFEB3B #FBC02D
   #FFF176 #F57F17 #FFA000 #FB8C00 #FFB74D #E65100 #795548 #BCAAA4 #FFFFFF #212121 #9E9E9E #616161`.

### 11.4 Strings used by `MainActivity` (app-specific; exact values in `res/values/strings.xml`)
`app_name` "Gamepad mouse" · `action_none` "None" · `action_launch_app` "Launch App" · `action_home` "Home" ·
`action_recents` "Recents" · `action_vol_up` "Volume Up" · `action_vol_down` "Volume Down" · `action_mute` "Mute" ·
`action_bright_up` "Brightness Up" · `action_bright_down` "Brightness Down" · `action_media_forward` "Fast Forward (10s)" ·
`action_media_rewind` "Rewind (10s)" · `action_screenshot` "Screenshot" · `action_rotate` "Screen Rotation" ·
`action_click_location` "Click Specific Location" · `action_click_location_repeat` "Repeat Click at Location" ·
`app_not_found` "App not found" · `app_version_format` "Version %s" · `general_settings` "General Settings" ·
`pointer_sensitivity` "Pointer & Sensitivity" · `keyboard_settings` "Keyboard Settings" · `page_initial_setup` /
`initial_setup` / `nav_initial_setup` "Initial Setup" · `how_to_use` "How to Use" · `nav_pro` "PRO" ·
`nav_pro_buy` "Buy Pro version" · `nav_pro_features` "Pro features" · `pro_version_active` "Pro Version (Active)" ·
`pro_version_inactive` "Pro Version (Inactive)" · `pro_desc` · `pro_feature` "Pro Feature" · `upgrade` "Upgrade" ·
`upgrade_to_pro` "Upgrade to Pro" · `cancel` "Cancel" · `ok`(android) "OK" · `reset` "Reset" ·
`reset_all_settings` "Reset All Settings" · `reset_confirm_msg` · `reset_to_defaults` "Reset to Defaults" ·
`reset_toggle_key_default` "Reset to Default (L3)" · `settings_reset_toast` "Settings Reset to Defaults" ·
`cursor_style` "Cursor Style" · `cursor_custom_color` "Custom Color" · `cursor_custom_png` "Custom PNG Image" ·
`cursor_color_orange` "Orange (Default)" · `cursor_color_manual` "Type HEX" · `cursor_color_invalid` ·
`cursor_png_load_failed` "Failed to load image." · `select_language` "Select Language" · `lang_en` "English" ·
`lang_ko` "한국어 (Korean)" · `lang_es` "Español (Spanish)" · `mouse_service_enabled` "Mouse Service Enabled" ·
`customize_toggle_key` "Change Activation Button" · `l3_long_press_duration` "Long Press Duration" ·
`long_press_instant` "Instant" · `seconds_unit` "s" · `swap_ab_buttons_title` "Swap A/B Buttons" ·
`swap_ab_buttons_desc` "B: Cursor Click / A: Back Action" · `dex_lockscreen_enabled_pro` ·
`dex_lockscreen_desc` · `dex_pro_msg` · `force_mirroring_title` "Mirroring Mode" · `force_mirroring_desc` ·
`haptic_feedback_pro` "Haptic Feedback (Pro)" · `haptic_pro_msg` · `vibration_intensity` "Vibration Intensity" ·
`vibration_pro_msg` · `debug_pro_toggle` · `debug_pro_desc` · `pointer_size` "Cursor Size" ·
`pointer_speed` "Pointer Speed" · `dex_pointer_speed_pro` "DeX Pointer Speed (Pro)" ·
`sensitivity_curve` "Sensitivity (Curve)" · `auto_hide_timeout` "Auto-Hide Timeout" · `never` "Never" ·
`scroll_speed` "Scroll Speed" · `deadzone_title` "Gamepad Deadzone" · `stick_test_suffix` ·
`keyboard_input_pro` · `keyboard_input_desc` · `keyboard_pro_required` · `kb_test_title` "Keyboard test field" ·
`kb_test_desc` · `kb_test_seed` · `kb_languages_title` · `kb_lang_en/ko/es` · `kb_lang_min_toast` ·
`kb_nav_interval` · `kb_nav_delay` · `kb_move_sound` · `kb_move_sound_desc` ·
`kb_dex_width_title` · `kb_dex_height_title` · `kb_dex_pos_title` · `kb_dex_pos_left/center/right` ·
`kb_dex_pct_format` "%1$d%%" · `kb_guide_title` · `kb_guide_body` · `kb_guide_es_line` ·
`custom_key_mapping` "Custom Key Mapping (X + Button)" · `select_action_title` "Select Action for X + %1$s" ·
`select_app` "Select App" · `click_location_guide_title` · `click_location_guide_msg` ·
`click_location_repeat_guide_title` · `click_location_repeat_guide_msg` · `repeat_interval_title` ·
`repeat_interval_format` "%1$.1fs" · `repeat_interval_custom` "Custom…" · `repeat_interval_hint` ·
`repeat_interval_range_msg` · `toast_dpad_not_allowed` · `press_gamepad_button_title` ·
`press_gamepad_button_msg` · `permission_required` · `brightness_permission_msg` · `open_settings` ·
`open_accessibility_settings` · `disable_battery_optimization` · `setup_step_1/2/3` ·
`accessibility_disclosure_title/text` · `btn_accept_continue` · `btn_decline_exit` · `pro_tip_title/desc` ·
`control_guide_title/desc` · `game_freeze_tip_title/desc` · `pro_r3_control_title/desc` ·
`drawer_hint_bubble` "Tap the ☰ button to open the menu" · `tap_to_close` · `admob_banner_id` ·
`contact_email_subject` · `contact_email_fallback` · `share_app` · `rate_app` · `nav_contact` ·
`app_category` · `nav_settings` · `nav_manual` · `nav_pro_category` ·
service-side toasts: `toast_location_captured`, `toast_repeat_location_captured`, `toast_repeat_replaced`,
`toast_repeat_started_format`, `toast_repeat_stopped`, `toast_repeat_stopped_cursor`,
`toast_turn_on_mouse_to_capture`, `toast_screenshot_saved`, `toast_screenshot_failed` · `lockscreen_label`.

### 11.5 `VerticalFriendlySeekBar` (`gamepadmouse/VerticalFriendlySeekBar.java`, 90 lines)
An `AppCompatSeekBar` that only starts tracking when the initial movement is **more vertical than 1.5×
horizontal** and beyond `ViewConfiguration.getScaledTouchSlop()`; while tracking it swallows the events
(`onTouchEvent` returns `true`), which keeps a vertical page scroll from being stolen by the seek bar.
All app seek bars are this class (see `activity_main.xml` `<com.pkyul13.gamepadmouse.VerticalFriendlySeekBar>`).

### 11.6 `accessibility_service_config.xml`
`description=@string/app_name`, `accessibilityEventTypes=typeAllMask`, `feedbackGeneric`,
`notificationTimeout=100`, `canRetrieveWindowContent=true`, `canRequestFilterKeyEvents=true`,
`canPerformGestures=true`, `canTakeScreenshot=true`. The service is declared
`android:label="Gamepad Mouse Service"`, `permission=BIND_ACCESSIBILITY_SERVICE`, `exported=false`
(`AndroidManifest.xml:89-100`).

---

## 12. Analytics events emitted by the UI layer

| Event | Params | Where |
|---|---|---|
| user property `user_type` | `"pro_user"` / `"free_user"` | `MainActivity.java:954-964` |
| `click_upgrade_pro` | – | `v10` case 3 (`:1157`, `:1463`, … `:3782`) |
| `change_key_mapping` | `key` = slot, `action` = type | `l20.java:150-160` |
| `change_sensitivity` | `value` (float, v/10) | `r20.java:100-104` |
| `change_scroll_speed` | `value` (int) | `r20.java:137-141` |
| `change_deadzone` | `value` (float, p/100) | `r20.java:158-162` |
| `toggle_mouse_service` | `enabled` (bool) | `u10.java:66-70` |
| `share_app`, `rate_app`, `contact_developer` | – | `C0833su.java:188`, `:200`, `:216` |

---

## 13. Re-implementation checklist / gotchas

1. **Single source of truth is the `GamepadMousePrefs` file**; no IPC. A replica can keep this design
   (activity writes, service observes) — it is what makes the two components so loosely coupled.
2. `pref_cursor_style` has three states only (`orange` / `custom_color` / `custom`); the named presets are
   *legacy* and are migrated on every `onCreate`/label refresh (`m2104C`). Do not build a preset list UI.
3. `pref_initial_setup_shown` is dead code — the disclosure dialog is driven purely by
   "is the accessibility service enabled".
4. Seek-bar write timing differs: keyboard prefs commit on release, pointer prefs commit continuously.
5. `pref_mouse_timeout` UI cannot express 1–4 s (progress 0 = never, progress 1 = 5 s). Replicate the
   odd formula exactly if bit-compatible behaviour is wanted; a clean reimplementation may choose to fix it.
6. `lt` has **no** first-run default (implicit `none`), and `rb` is explicitly set to `none` — this asymmetry
   is intentional in the original.
7. `pref_haptic_feedback`/`pref_keyboard_enabled` are `true` by default but forced to `false` and disabled for
   free users; the stored value is *not* overwritten (so an upgrade immediately re-activates them).
8. Mapping rows write through `SharedPreferences.Editor` **immediately** after the dialog selection and then
   call `m2102A()`; the action-picker dialog uses `apply()` at the end of the click handler (`l20.java:148`).
9. The `click_location*` values are `"x,y"` strings with one decimal — do not store ints (the service parses
   floats and compares with tolerances).
10. Only one repeat-click slot may be armed at a time (`f4190u`), and it is stopped by: pressing it again,
    changing that slot's type, or turning the mouse off.
11. The `open_page` intent extra is the only cross-component navigation contract; it is single-use
    (removed after consumption) and relies on `FLAG_ACTIVITY_SINGLE_TOP` to reach `onNewIntent`.
12. Every dialog in the app is built from `C1027y2`/`DialogC1064z2` (MaterialAlertDialogBuilder) — the
    replica can use `MaterialAlertDialogBuilder` directly; the field assignments (`f15166d` title,
    `f15168f` message, `f15169g`/`f15170h` neutral, `f15171i` negative, `f15173k` items,
    `f15175m` item listener, `f15176n` custom view, `f15178p` checked item, `f15177o` single-choice)
    map 1:1 onto it.

---

## 14. Features that do **not** exist (do not invent them)

Cross-checked against *every* `pref_*` literal in the whole APK (only app keys are listed in §2 — the two
other literals found, `pref_listener` and `pref_signal_timeout_duration_in_ms`, belong to GMS Ads internals
`gads:*` flags in `p000/ei1.java`, `p000/vg1.java`). There is:

* no pointer **acceleration/curve exponent** setting (only the linear `pref_mouse_sensitivity` divisor);
* no **invert X/Y**, no **swap sticks**, no **trigger-as-click** setting;
* no **preset/profile** system (no save/load of mapping sets);
* no **overlay style/theme** beyond the cursor colour/PNG; no cursor *trail*, no *highlight* colour;
* no **double-click / right-click** mapping, no **drag speed**;
* no **notification**, no **foreground service**, no **quick-settings tile**, no **widget**;
* no **backup/restore** or **export/import** of settings (`allowBackup="true"` only, via
  `@xml/backup_rules` / `@xml/data_extraction_rules`);
* no **price strings** in resources (price comes from Play Billing);
* no **AdMob interstitial/rewarded** — banner only;
* no **`Build.MODEL` / `sem.*`** vendor probing anywhere in the app code;
* only **one** cursor-toggle key (`pref_toggle_keycode`), no per-game shortcuts.

