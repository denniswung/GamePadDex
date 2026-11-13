# SPEC — `p000` helper classes of `MouseAccessibilityService` (Gamepad Mouse v2.0.2)

Implementation-grade specification of the small helper classes that
`com.pkyul13.gamepadmouse.MouseAccessibilityService` delegates to, plus a complete
pseudocode for the gamepad `MotionEvent` router `p000/t60`.

---

## 0. Provenance and citation legend

| Citation | File |
|---|---|
| `p000/<x>.java:NN` | `/home/denniswung/gpm/out/sources/p000/<x>.java` (jadx 1.5.0, R8-obfuscated) |
| `MAS.java:NN` | `/home/denniswung/gpm/out/sources/com/pkyul13/gamepadmouse/MouseAccessibilityService.java` (4963 lines) |

Both trees were read through WSL (`wsl -d Ubuntu-24.04 -e cat -n …`); the UNC path
`\\wsl.localhost\Ubuntu-24.04\home\denniswung\gpm\out\sources\p000\` is **not** readable from
this Windows session, the files themselves are.

### 0.1 Decompiler artifacts you must know before reimplementing

`jadx` mis-rendered several constructs in these files. Each is called out inline where it
matters; the summary:

1. **`q60` selector is lost.** `f12518n` is printed as a field initialiser `= 1` for *both*
   constructors (`p000/q60.java:12,20-23,42-45`), which would make `case 0` unreachable.
   Call-site evidence (`MAS.java:1563` "Performing HOME action (Start Button)" → `m2135L(2)`,
   `MAS.java:1577` RECENTS → `m2135L(3)`, `MAS.java:1651` BACK → `n60(4)` → `n60.java:119`
   `m2135L(1)`) proves `(MouseAccessibilityService,int)` ⇒ selector `0` ⇒
   `performGlobalAction(action)`, and `(int,MouseAccessibilityService)` ⇒ selector `1` ⇒
   brightness Toast. See §6.3.
2. **`s60` case 6 ("moveRunnable") is a `try/catch/finally` that jadx split.** The
   `catch (Exception)` copy at `p000/s60.java:191-207` duplicates `p000/s60.java:154-185`;
   the real body is linear. Also `if (sharedPreferences == null) { …getBoolean(…)… }`
   (`p000/s60.java:167-175`, `:196-198`) is **polarity-inverted** — the real test is
   `!= null`, with the `xl3.m8890u("sharedPrefs")` throw on the null branch.
3. **`t60` branch B has two inverted / duplicated blocks** (`p000/t60.java:454-471`,
   `:499-509`) — see the two footnotes at the end of §7.5 for the reconstruction and the
   evidence.
4. Two harmless noise patterns, keep them out of a rewrite:
   * `int i = MouseAccessibilityService.f4074Q1;` (`= 0`, `MAS.java:131`) is a synthetic
     R8 marker read at the top of almost every method (`s60.java:40`, `n60.java:56`,
     `t60.java:521`, `:533`, …). Ignore it.
   * `RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED` is the GMS constant for `""`
     (`r60.java:57,61`); treat it as the empty string.

### 0.2 No file outside this spec was modified.

---

## 1. Object graph

```
MouseAccessibilityService  (AccessibilityService)
 ├─ f4096H  Handler(main looper)              ← every timer below runs on it
 ├─ s60  ×10  f4077A1(0) f4207z1(1) f4089E1(2) f4204y1(3) f4201x1(4)
 │             f4086D1(5) f4107K1(6) f4083C1(7) f4080B1(8) f4110L1(9)
 ├─ n60  ×1 cached (f4188t0 = id 0) + ~20 ad-hoc instances (ids 0..14)
 ├─ o60  ad-hoc (ids 0,1)      q60 ad-hoc (ids 0,1)
 ├─ r60  ×2   f4093G(battery)  f4092F1(screen off)
 ├─ u60  ×1   f4095G1  DisplayManager.DisplayListener
 ├─ v60  ×1   f4091F0  FrameLayout scrim under the on-screen keyboard
 ├─ w60  ×1   f4161j0  GestureResultCallback for scroll gestures
 ├─ x60 / y60          TakeScreenshotCallback (window / display stage)
 ├─ j20  ×1   f4098H1  OnSharedPreferenceChangeListener (service instance)
 ├─ ma0  (generic 2-tuple, also the unit type of `m2144W`)
 ├─ C0575lv f4100I0    Hangul/IME text-buffer model backing the on-screen keyboard
 └─ C0950w f4103J0     accented-Latin composition state (2-key dead-key machine)
```

All helper classes are **synthetic lambda homes**: `/* synthetic */`, `/* renamed from: … */`,
constructors that only copy the outer instance. They hold no logic beyond the callback body.

---

## 2. Service field dictionary (only the fields the helpers touch)

"Lines" = declaration line(s) (`MAS.java`); where a default is set elsewhere the writing
line is given too. All field declarations live in `MAS.java:112-532`; the constructor
initialisers are `MAS.java:533-576`.

| Field | Type | Default | Meaning | Lines |
|---|---|---|---|---|
| `f4163k0` | boolean | false | **Gamepad focus / cursor overlay is active** (written by `m2117X`; log `"setGamepadFocus: "`) | decl 350; write 737 |
| `f4145b0` | boolean | false | Cursor **visible** (fade-in finished / repeat-click enabled) | decl 299; writes 779, 849, 3784 |
| `f4082C0` | boolean | false | **Keyboard/IME mode** active (`m2133J` open, `m2163j` close) | decl 146; true 2317, false 3735 |
| `f4129T` | boolean | **true** | Global "mouse enabled" (`pref_mouse_enabled`) | 518 |
| `f4131U` | boolean | false | `pref_dex_lockscreen_enabled` | — |
| `f4085D0` | boolean | **true** | `pref_keyboard_enabled` | 550 |
| `f4167m0` | boolean | **true** | `pref_l3_toggle_enabled` | 545 |
| `f4173o0` | boolean | false | `pref_swap_ab_buttons` | — |
| `f4191u0` | boolean | false | **Combo modifier held** (L3): HAT / LT / RT fire *user mappings* instead of cursor/scroll | decl 431; writes 1935-1939 |
| `f4075A` / `f4078B` | float | 500 / 1000 | Cursor X / Y (screen px) | 485 / 488 |
| `f4081C` / `f4084D` | int | 1080 / 2400 | Screen W / H (clamp bounds) | 491 / 494 |
| `f4099I` / `f4102J` | float | 0 | Per-frame cursor Δ (normalised −1..1, already accel-shaped) | 191 / 200 |
| `f4105K` / `f4108L` | float | 0 | Per-frame scroll vector (unit-normalised) | 209 / 218 |
| `f4114N` | float | 50 | `pref_mouse_speed` — **px per frame** on display 0 | 500 |
| `f4117O` | float | 30 | `pref_dex_speed` — **px per frame** on non-0 displays | 503 |
| `f4123Q` | float | 1.5 | `pref_mouse_sensitivity`/10 → accel exponent blend | 509 |
| `f4125R` | float | 2.0 | `pref_scroll_speed`/50 | 512 |
| `f4127S` | float | 0.15 | `pref_deadzone`/100 | 515 |
| `f4120P` | int | 100 | `pref_mouse_size` % | 506 |
| `f4133V` | int | 0 | `pref_mouse_timeout` seconds (0 = never) | write 4311 (`j20` 462) |
| `f4118O0` | long | **150** | `pref_kb_nav_interval` — repeat interval (ms) | 556 |
| `f4121P0` | long | **300** | `pref_kb_nav_delay` — initial repeat delay (ms) | 557 |
| `f4193v` | long | **500** | repeat-click interval, `m2140R` clamps to 100..3000 | 482; clamp 2830-2836 |
| `f4176p0` | int | 0 | `pref_l3_long_press_duration` (×100 ms) | write 4219 usage |
| `f4170n0` | int | **106** | `pref_toggle_keycode` (106 = `KEYCODE_BUTTON_THUMBL`) | 546 |
| `f4143a0` | long | `System.currentTimeMillis()` | Last user-activity timestamp (auto-hide) | 527 |
| `f4182r0` | long | 0 | Last dispatched gesture timestamp (touch debounce) | 404 |
| `f4187t` | long | 0 | Last mapped-action timestamp (300 ms debounce) | 419 |
| `f4079B0` | long | 0 | Last brightness-HUD timestamp (500 ms) | 140 |
| `f4140Y0` | long | 0 | Last RT "Enter" timestamp (350 ms gate) | 287 |
| `f4146b1` | long | 0 | Last stick-move timestamp | 302 |
| `f4151e0` | long | 0 | Press-down timestamp for long-press→drag | 317 |
| `f4157h0` | long | 0 | Earliest time for next drag stroke continuation | 332 |
| `f4153f0` | float[2] | — | Last drag point | 530 |
| `f4155g0` | StrokeDescription | null | Live drag stroke | — |
| `f4159i0` | boolean | false | Scroll gesture in flight (cleared only by `w60`) | 338 |
| `f4147c0` | boolean | false | Button **held down** (drag in progress) | 305 |
| `f4149d0` | boolean | false | Button **pressed, not yet dragged** | 311 |
| `f4134V0` | boolean | false | SHIFT latch (keyboard) | — |
| `f4136W0` | boolean | false | second shift-like latch (also set by LT, `t60.java:345`) | — |
| `f4138X0` | boolean | false | CAPS latch | — |
| `f4164k1` / `f4166l1` | int | 0 | keyboard HAT repeat direction X / Y (−1,0,1) | 353 / 359 |
| `f4168m1` | int | 0 | keyboard repeat mode: 0 idle, 1 auto-repeat, 2 latched burst | 365 |
| `f4171n1` | boolean | false | HAT repeat active | 374 |
| `f4174o1` | long | 0 | HAT pressed-but-not-yet-repeating timestamp | 383 |
| `f4177p1` | long | 0 | HAT press timestamp (used by the key handler) | — |
| `f4180q1` | long | 0 | HAT **release** timestamp / toggle-mode anchor | 398 |
| `f4183r1` / `f4186s1` | int | 0 | keyboard nav direction X / Y (Z/RX vs RZ/RY) | 407 / 416 |
| `f4189t1` | boolean | false | keyboard nav repeat active | 425 |
| `f4192u1` | long | 0 | keyboard nav pressed-but-not-yet-repeating timestamp | 434 |
| `f4148c1` / `f4150d1` | int | 0 | keyboard stick direction X / Y (grid navigation) | 308 / 314 |
| `f4152e1` | int | 0 | keyboard stick mode (1 = auto-repeat) | 320 |
| `f4154f1` | long | 0 | keyboard stick released-but-not-yet-stopped timestamp | 323 |
| `f4156g1` | boolean | false | keyboard stick repeat active | 329 |
| `f4158h1` | float | 0 | Left-stick magnitude at last event (speed gate) | 335 |
| `f4190u` | String | null | Active repeat-click mapping name | 428 |
| `f4200x0` | boolean | false | RT latch (edge detect) | 455 |
| `f4197w0` | boolean | false | LT latch (edge detect) | 446 |
| `f4203y0` / `f4206z0` | float | 0 | **Last HAT X / HAT Y** (edge detect for combos) | 464 / 473 |
| `f4076A0` / `f4165l0` | boolean | false | window-handle-clicked sentinel / touch reclaim debounce | — |
| `f4137X` / `f4135W` | String | "#FFA000" / "orange" | Cursor colour / style | 524 / 521 |
| `f4184s` | WakeLock | — | `"GamepadMouse:WakeLock"` | 4399 |
| `f4175p` | LinkedHashMap | {} | displayId → focus `View` (the `t60`s) | 479 |
| `f4172o` | ImageView | null | Cursor sprite window | — |
| `f4178q` | FrameLayout | null | Black-screen / battery HUD window | — |
| `f4088E0` | C1059yy | null | On-screen keyboard view | — |
| `f4091F0` | v60 | null | Keyboard scrim | — |
| `f4097H0` | AccessibilityNodeInfo | null | Currently edited editable node | — |
| `f4100I0` | C0575lv | new | IME text model | 551 |
| `f4103J0` | C0950w | new | Accent/dead-key state | 552 |
| `f4106K0` | EnumC0985wy | `f17925n` (EN) | Active keyboard language | 553 |
| `f4113M1` / `f4116N1` / `f4119O1` | node/float/float | — | Deferred "open keyboard at (x,y)" state for `n60(10)` | — |
| `f4122P1` | Rect | null | Bounds of the field before IME-Enter, for `n60(1)` | — |
| `f4142Z0` / `f4144a1` | float | 0 | Cursor position at keyboard open time | — |

---

## 3. Service method dictionary (obfuscated → behaviour)

Only the methods the helpers call.

| Method | Behaviour | Lines |
|---|---|---|
| `m2157g()` | Stop the **HAT/trigger keyboard-repeat** loop: zero `f4164k1,f4166l1,f4168m1`, `f4171n1=false`, `f4174o1=0`; `removeCallbacks(f4207z1, f4077A1)` | 3427-3436 |
| `m2159h()` | Stop the **keyboard stick** loop: zero `f4148c1,f4150d1,f4152e1`, `f4154f1=0`, `f4156g1=false`, `f4158h1=0`; `removeCallbacks(f4201x1, f4204y1)` | 3472-3483 |
| `m2161i()` | Stop the **keyboard nav** loop: zero `f4183r1,f4186s1`, `f4189t1=false`, `f4192u1=0`; `removeCallbacks(f4080B1, f4083C1)` | 3507-3516 |
| `m2148a0(dx,dy,mode)` | Start HAT/trigger repeat: store dirs+mode, `f4171n1=true`, `f4174o1=0`, `f4177p1=now`, `f4180q1=now` if mode 2, `m2131H(dx,dy)`, `removeCallbacks(f4077A1,f4207z1)`, **`postDelayed(f4207z1, f4121P0)`** | 3091-3108 |
| `m2131H(dx,dy)` | Keyboard caret motion: `dx>0` forward one char (or commit pending jamo), `dx<0` back one char, `dx==0 && dy>0` → `C0575lv.m5205f()` (down a line), `dy<0` → `m5206g()` (up a line); then `m2166l()`, `m2138P()` | 2080-2105 |
| `m2132I(C0911uy key)` | Execute one keyboard-key model action for the highlighted key (`m2130G` backspace, `m2136M` enter, `m2158g0` language, shift/caps toggles, `m2163j(true)` close, TAB, PASTE, cursor-left/right, accent, …) | 2107-2300 |
| `m2130G()` | Keyboard **backspace** (pops accent state, composing buffer, or deletes a char) then `m2166l()` | 2054-2078 |
| `m2136M()` | Keyboard **Enter**: commit + `ACTION_IME_ENTER` (or `\n` in a multi-line field); schedules `n60(1)` at 250 ms or closes the keyboard | 2493-2574 |
| `m2158g0()` | Cycle keyboard language | 3438-3468 |
| `m2134K(sx,sy)` | **Discrete scroll gesture**: guarded by `f4159i0`; `f3 = displayId==0 ? 1.0 : 0.5`; `f6 = f4125R*180*f3`; `moveTo(cursorX, screenH/2)` → `lineTo(cursorX - sx*f6, screenH/2 - sy*f6)`, 150 ms stroke, callback `f4161j0` | 2442-2474 |
| `m2135L(action)` | Re-focus the display's focus view (`m2116T`), dispatch a 50 ms tap (`m2160h0`), then `postDelayed(q60(action), 80)` → `performGlobalAction(action)` (+ brightness-HUD side path) | 2476-2491 |
| `m2136M`, `m2137N(boolean)` | DeX **maximise/restore** of the focused freeform window by clicking the "창 최대화"/"창 복원" (`maximize`/`restore`) accessibility node | 2578-2720 |
| `m2138P()` | Play the keyboard **key-click** sound (`pref_kb_move_sound`) | 2775-2811 |
| `m2139Q()` | Repaint the keyboard's shift/caps state into the `C1059yy` view (`f19487s`, `f19488t`, `m9197d()`) | 2813-2828 |
| `m2140R(name)` | Repeat-click interval = `clamp(pref_mapping_x_<name>_interval, 100, 3000)`, default 500 | 2830-2836 |
| `m2141S()` | Reposition the keyboard window above/below the focused field (`gravity` 48/80) | 2839-2905 |
| `m2142U()` | Reset the idle timer `f4143a0 = now`; if display 0 also `m2129E()` (blackout/hide bookkeeping) | 2909-2917 |
| `m2144W(name)` | Parse `pref_mapping_x_<name>_value` `"x,y"` → `ma0(Float,Float)`; null if missing/invalid | 2951-3010 |
| `m2146Z(String)` | Toast on the main handler | 3063-3065 |
| `m2147a(int)` | `Settings.System screen_brightness += delta` clamped 0..255, then `q60(brightness)` Toast if >500 ms since last | 3067-3089 |
| `m2148a0` … see above | | |
| `m2150b0(x,y)` | **Start a drag** gesture (`continueStroke` root) at (x,y); stores `f4153f0`, `f4155g0` | 3158-3181 |
| `m2152c0(x,y)` | Finish the drag stroke | 3183-… |
| `m2154d0(Integer res)` | **Stop repeat-click**: `f4190u=null`, `removeCallbacks(f4110L1)`, optional toast | 3311-3324 |
| `m2155e0()` / `m2162i0()` / `m2169m0()` | Display re-enumeration / cursor-size & focus refresh | 3326+ |
| `m2156f0(display,tag)` | `takeScreenshot(displayId, executor, y60)`; on throw → `performGlobalAction(9)` | 3410-3420 |
| `m2160h0()` | Dispatch a 50 ms tap at `(0,200)` (display 0) or `(W/2, 5)` | 3486-3505 |
| `m2163j(boolean)` | **Close keyboard mode**: remove scrim, clear `C0575lv`, `f4082C0=false`, stop loops 3/4/5/7/8/9 | 3731-3795 |
| `m2164j0()` | Rebuild the cursor bitmap from `f4135W`/`f4137X` | 3797-3875 |
| `m2165k0()` | `layoutParams.x/y = (int)f4075A/(int)f4078B; updateViewLayout(f4172o)` | 3881-3895 |
| `m2166l()` | Push `C0575lv.m5201b()` into the focused node via `ACTION_SET_TEXT` (with 90 px fallback re-hit-test); returns success | 3897-3985 |
| `m2170n(x,y)` | **Continue drag** stroke: only if `now >= f4157h0`, movement ≥ 1 px, then `f4157h0 = now + 40` | 3994-4030 |
| `m2171n0(ms)` | Gamepad vibration (only devices with source 1025), amplitude `pref_vibration_intensity` (255) | 4032-4062 |
| `m2172o0(dir)` | **Keyboard word-wise caret move** (`dir>0` forward word, `dir<0` backward word) + `m2166l()` + `m2138P()` | 4066-4104 |
| `m2174q(x,y)` | **Single tap gesture** at (x,y), 50 ms | 4501-4513 |
| `m2175r(x,y)` | Double tap (two 50 ms strokes, second at t=150) | 4515-4530 |
| `m2179v(name, fromRepeat)` | **Execute the user mapping** `<name>` (300 ms debounce, Pro-gated): brightness, volume, media, rotate, screenshot, HOME/BACK/RECENTS, `click_location`, `click_location_repeat`, … | 4613-4900 |
| `m2180y(x,y,r)` | Hit-test editable nodes in application windows within radius `r` px | 4919-4947 |
| `m2117X(svc, focus, keepVisible, cause)` | **setGamepadFocus**: attach/detach cursor + toggle `FLAG_NOT_FOCUSABLE` (0x8) on all focus views, centre the cursor if it is near an edge, animate alpha 200 ms, `m2129E()` on off | 693-870 |
| `m2116T(view,displayId)` | `view.post(requestFocus)` | 687-690 |
| `m2129E()` | Hide the black-screen HUD (fade 200 ms), release/re-acquire the wake lock, keep the cursor visible | 2004-2052 |
| `m2125A(x,y)` | Nearest editable node to (x,y) (any application window) | 1098-1150 |
| `m2127C(KeyEvent)` | The whole gamepad **key** state machine (A/B/X/Y, L1/R1, L2/R2, L3/R3, START/SELECT, dpad) | 1250-1958 |
| `m2126B(resId, args)` / `m2146Z` | `getString` / Toast | — |

---

## 4. `p000/s60.java` — the 10-slot timer / loop engine

`public final class s60 implements Runnable` (`p000/s60.java:12`).
Fields: `f13705n` = the id (`:15`), `f13706o` = the service (`:18`).
One cached instance per id, constructed in the service constructor and stored in a field so
that `Handler.removeCallbacks(...)` can address each loop independently:

| id | field | construction |
|---|---|---|
| 0 | `f4077A1` | `MAS.java:564` (`i = 0`, `MAS.java:535`) |
| 1 | `f4207z1` | `MAS.java:563` (`i2 = 1`, `MAS.java:537`) |
| 2 | `f4089E1` | `MAS.java:568` (`i3 = 2`, `MAS.java:538`) |
| 3 | `f4204y1` | `MAS.java:562` |
| 4 | `f4201x1` | `MAS.java:561` |
| 5 | `f4086D1` | `MAS.java:567` |
| 6 | `f4107K1` | `MAS.java:574` |
| 7 | `f4083C1` | `MAS.java:566` |
| 8 | `f4080B1` | `MAS.java:565` |
| 9 | `f4110L1` | `MAS.java:575` |

`switch (i)` dispatch: `p000/s60.java:41`; cases at `:42` (0), `:48` (1), `:76` (2),
`:90` (3), `:96` (4), `:126` (5), `:133` (6), `:212` (7), `:218` (8), `:255` (default = 9).

### 4.1 Summary table

| id | role | first post (caller, delay) | self-reschedule | stops when | service calls |
|---|---|---|---|---|---|
| **0** | HAT/trigger **release gate** (one-shot) | `t60.java:284` `postDelayed(f4077A1, 140)` | — (one-shot) | returns unless `f4168m1==1 && f4174o1!=0 && now-f4174o1>=120` (`s60.java:43`) | `m2157g()` |
| **1** | keyboard **HAT/trigger auto-repeat** | `m2148a0` → `MAS.java:3103-3107` `postDelayed(f4207z1, f4121P0=300)` | `postDelayed(this, f4118O0=150)` (`s60.java:69`) | `!f4082C0`; `f4164k1==0 && f4166l1==0`; `!f4171n1`; mode 1 && `now-f4174o1>=120`; mode 2 && `now-f4180q1>1000` | `m2131H(k1,l1)`; `m2157g()` |
| **2** | keyboard **A/B key repeat** | `MAS.java:1342` `postDelayed(f4089E1, 400)` | `postDelayed(this, 110L)` (`s60.java:84`) | `!f4082C0`; `!f4162j1`; editor `null` or editor action `== ENTER` | `C1059yy.m9199f()`, `m2132I(key)` |
| **3** | keyboard stick **release gate** (one-shot) | `t60.java:301` `postDelayed(f4204y1, 140)` | — | returns unless `f4152e1==1 && f4154f1!=0 && now-f4154f1>=120` (`s60.java:91`) | `m2159h()` |
| **4** | keyboard stick **grid-navigation repeat** | `t60.java:271` `postDelayed(f4201x1, j)` where `j = f4121P0` (300) or `f4118O0*2` (300) | `postDelayed(this, j3)` with `j3 = f4118O0` (150) or `×2` (300) if `f4158h1 < 0.9` (`s60.java:115-120`) | `!f4082C0`; `c1==0 && d1==0`; `!f4156g1`; `f4152e1==1 && now-f4154f1>=120` | `C1059yy.m9196c(c1,d1)`, `m2138P()`, `m2159h()` |
| **5** | keyboard **X/backspace repeat** | `MAS.java:1491` `postDelayed(f4086D1, 400)` | `postDelayed(this, 110L)` (`s60.java:129`) | `!f4082C0`; `!f4160i1` | `m2130G()` |
| **6** | **60 fps frame engine** (cursor move / drag / scroll / auto-hide) | `MAS.java:4403` `handler.post(f4107K1)` (no delay, at service setup) | `finally { postDelayed(this, 16L) }` (`s60.java:210`) — **unconditional, forever** | never stops itself; only `removeCallbacks` at `MAS.java:4141` (`onDestroy`) | `m2165k0`, `m2170n`, `m2150b0`, `m2142U`, `m2134K`, `m2117X(...)`, `m2171n0(40)` |
| **7** | keyboard nav **release gate** (one-shot) | `t60.java:131` `postDelayed(f4083C1, 140)` | — | returns unless `f4192u1!=0 && now-f4192u1>=120` (`s60.java:213`) | `m2161i()` |
| **8** | keyboard **nav repeat** (Z/RX/RY/RZ) | `t60.java:179` `postDelayed(f4080B1, f4121P0=300)` | `postDelayed(this, f4118O0*2)` = 300 (`s60.java:235`, `:249`) | `!f4082C0`; `r1==0 && s1==0`; `!f4189t1`; `now-f4192u1>=120` | `m2172o0(r1)`; `kb.m5205f()/m5206g()`; `m2166l()`; `m2138P()`; `m2161i()` |
| **9** | **repeat-click loop** | `MAS.java:4881` `handler.post(f4110L1)` (immediately, on mapping start) | `postDelayed(this, f4193v)` (`s60.java:269`) | `f4190u == null` (mapping changed/stopped); or guard fails → auto-stop with toast `toast_repeat_stopped_cursor` | `m2144W(name)`, `m2174q(x,y)`, `m2154d0(...)` |

### 4.2 Per-case detail

#### id 0 — HAT/trigger release gate (`s60.java:42-47`)
```java
if (f4168m1 == 1 && f4174o1 != 0 && System.currentTimeMillis() - f4174o1 >= 120) m2157g();
```
Posted **only** from `t60.java:284` at 140 ms, when the HAT has been inside ±0.25 for at least
one frame and no repeat was running. Effectively: *"the user let go of the d-pad for 140 ms →
cancel the pending keyboard repeat."* The `>=120` is a second guard against firing for a
press that was re-armed in the meantime.

#### id 1 — keyboard HAT/trigger auto-repeat (`s60.java:48-75`)
```java
if (f4082C0) {                                     // keyboard mode only
  if (f4164k1 != 0 || f4166l1 != 0) {              // a direction is latched
    now = System.currentTimeMillis();
    if (!f4171n1) { m2157g(); return; }            // cancelled underneath us
    if (f4168m1 == 1) {                            // auto-repeat mode
      if (f4174o1 != 0 && now - f4174o1 >= 120) { m2157g(); return; }
    }
    if (f4168m1 == 2 && now - f4180q1 > 1000) {    // latched-burst mode: 1 s after release
      m2157g(); return;
    }
    m2131H(f4164k1, f4166l1);                      // move the IME caret
    f4096H.postDelayed(this, f4118O0);             // 150 ms
  }
}
```
Two modes exist because the **key handler** starts mode 2 (`MAS.java:1394`
`m2148a0(i7,i8,2)` on dpad key-down in keyboard mode, gated by
`now-f4177p1>120 && now-f4146b1>120`) while **t60** starts mode 1
(`t60.java:199` `m2148a0(i8,i7,1)`). Mode 1 = hold-to-repeat, mode 2 = latched burst that
self-terminates 1 s after the key was released (`f4180q1` is written on key-up at
`MAS.java:1385` / `:1392` and on press in `m2148a0` at `MAS.java:3100`).

#### id 2 — keyboard A/B repeat (`s60.java:76-89`)
```java
if (f4082C0 && f4162j1) {
  C0911uy key = (f4088E0 != null) ? f4088E0.m9199f() : null;    // highlighted key model
  if (key == null || key.f15809f != EnumC0948vy.f17328q) {      // f17328q = ENTER (EnumC0948vy.java:74)
    m2132I(key);                                                // re-execute the key
    f4096H.postDelayed(this, 110L);
  }
}
```
Enter is excluded because `m2136M()` already schedules `n60(1)`; re-firing Enter would
double-submit. Started at 400 ms after A/B key-down (`MAS.java:1335-1342`), cancelled on
key-up (`MAS.java:1345-1348`).

#### id 3 — keyboard stick release gate (`s60.java:90-95`)
```java
if (f4152e1 == 1 && f4154f1 != 0 && now - f4154f1 >= 120) m2159h();
```
Posted at 140 ms from `t60.java:301`.

#### id 4 — keyboard stick grid navigation (`s60.java:96-125`)
```java
if (f4082C0) {
  if (f4148c1 != 0 || f4150d1 != 0) {
    now = System.currentTimeMillis();
    if (!f4156g1) { m2159h(); return; }
    if (f4152e1 == 1 && f4154f1 != 0 && now - f4154f1 >= 120) { m2159h(); return; }
    C1059yy kb = f4088E0;
    if (kb != null && kb.m9196c(f4148c1, f4150d1)) m2138P();   // moved → click sound
    long j3 = f4118O0;                                        // 150
    if (f4158h1 < 0.9f) j3 *= 2;                              // slow stick → 300
    f4096H.postDelayed(this, j3);
  }
}
```
`C1059yy.m9196c(dx,dy)` (`p000/C1059yy.java:335-368`) moves the highlighted key: `dx≠0`
steps within the current row (`clamp(f19479H+dx, 0, rowSize-1)`), `dy≠0` switches row and
picks the column nearest the previous key's centre x — i.e. **D-pad-style keyboard
navigation**. Returns `false` when nothing moved, which suppresses the click sound.

#### id 5 — keyboard X/backspace repeat (`s60.java:126-132`)
```java
if (f4082C0 && f4160i1) { m2130G(); f4096H.postDelayed(this, 110L); }
```
Started at 400 ms (`MAS.java:1491`), cancelled on key-up (`MAS.java:1493-1496`).

#### id 6 — the frame engine (`s60.java:133-211`) — **the core of the app**

Structure: the whole body is inside `try { … } finally { handler.postDelayed(this, 16L); }`
(`s60.java:133-211`), so the loop relaunches itself **every 16 ms unconditionally** — even on
exception, even after any `return`. Decompiler-mangled but semantically:

```java
boolean on = f4163k0;                                  // s60.java:137
if (on && f4129T && (f4099I != 0.0f || f4102J != 0.0f)) {   // :141  ← cursor must move
    float speed = (f4199x == null || f4199x.getDisplayId() == 0) ? f4114N : f4117O;  // :142-147
    f4075A = clamp(f4075A + f4099I * speed, 0, f4081C);                             // :148-151
    f4078B = clamp(f4078B + f4102J * speed, 0, f4084D);                             // :150-152
    m2165k0();                                                                     // :153
    if (f4147c0)      m2170n(f4075A, f4078B);          // continue the drag stroke     :154-155
    else if (f4149d0) { f4149d0=false; f4147c0=true; m2150b0(f4075A, f4078B); }     // :156-160
    m2142U();                                                                       // :161
    if (f4149d0 && !f4147c0 && now - f4151e0 > 500) {   // stationary long-press → drag :162
        Log.i("MouseService", "Stationary long-press detected - converting to drag.");
        f4149d0=false; f4147c0=true; m2150b0(f4075A, f4078B);                        // :164-166
        if (prefs.getBoolean("pref_haptic_feedback", true)) m2171n0(40L);            // :169-170
    }
    if (!f4147c0) {                                     // NOT dragging → also scroll   :177
        float sy = f4108L;
        if (f4105K != 0.0f || sy != 0.0f) {             // :178-179
            if (!f4159i0) m2134K(f4105K, sy);           // one scroll gesture at a time  :180-181
            m2142U();                                   // :183
        }
    }
    return;                                             // :186
}
// ---- no cursor movement this frame ----
if (f4133V > 0 && on && f4129T && !f4082C0 && now - f4143a0 > f4133V * 1000) {  // :188
    MouseAccessibilityService.m2117X(svc, false, false, 6);   // auto-hide / sleep       :189
}
if (on) { …long-press→drag block, identical to :162-176… }     // :191-199
if (on) { …scroll block, identical to :177-185…            }   // :200-207
return;                                                        // :208
```
Notes a reimplementation must preserve:
* Speed is **px per frame** here, not per second (`f4114N = 50`, `f4117O = 30` at 60 fps ⇒
  3000 / 1800 px·s⁻¹ at full deflection). Renaming them "px/s" in a rewrite silently changes
  the feel by 60×.
* Clamp bounds are `[0, screenW]` and `[0, screenH]` inclusive (`lo0.m5052h(v, 0, max)`).
* The scroll block is nested in the movement branch (`:177`), i.e. **you cannot scroll while
  standing still** — scroll only happens on frames where the cursor also moved.
* The auto-hide check runs only on frames *without* movement, which is fine because
  `m2142U()` keeps refreshing `f4143a0` while moving.
* `catch (Exception e) { Log.e("MouseService", "Critical error in moveRunnable: " + e.getMessage()); }`
  (`s60.java:138-140`) — present, and the `finally` keeps the loop alive.
* The `sharedPreferences == null` test at `:168` is **inverted by jadx**; the correct reading
  is `if (prefs != null) { if (prefs.getBoolean("pref_haptic_feedback", true)) m2171n0(40L); }`.

#### id 7 — keyboard nav release gate (`s60.java:212-217`)
```java
if (f4192u1 != 0 && now - f4192u1 >= 120) m2161i();
```

#### id 8 — keyboard nav repeat (`s60.java:218-254`)
```java
if (f4082C0 && (f4183r1 != 0 || f4186s1 != 0)) {
    if (!f4189t1) { m2161i(); return; }
    now = System.currentTimeMillis();
    if (f4192u1 != 0 && now - f4192u1 >= 120) { m2161i(); return; }
    if (f4183r1 != 0) m2172o0(f4183r1);                       // word left / right
    else if (f4186s1 > 0) { if (f4100I0.m5205f()) { m2166l(); m2138P(); } }  // line down
    else                  { if (f4100I0.m5206g()) { m2166l(); m2138P(); } }  // line up
    f4096H.postDelayed(this, f4118O0 * 2);                    // 300 ms
}
```
Started from `t60.java:179`.

#### id 9 — repeat-click loop (`s60.java:255-276`)
```java
String name = f4190u;                                  // active repeat-click mapping
if (name == null) return;
if (f4129T && f4163k0 && f4145b0 && !f4082C0) {
    ma0 loc = m2144W(name);                            // stored "x,y"
    if (loc == null) { Log.w(…"has no valid stored location"); m2154d0(null); return; }
    if (!f4147c0 && !f4159i0 && f4155g0 == null)       // don't tap mid-drag/scroll
        m2174q(((Number) loc.f9986n).floatValue(), ((Number) loc.f9987o).floatValue());
    f4143a0 = System.currentTimeMillis();              // keep the cursor awake
    f4096H.postDelayed(this, f4193v);                  // interval, default 500, 100..3000
} else {
    Log.i("MouseService", "Repeat click auto-stopped: cursor is off");
    m2154d0(Integer.valueOf(R.string.toast_repeat_stopped_cursor));
}
```
Started at `MAS.java:4881` right after the user binds a combo to `click_location_repeat`
(`MAS.java:4865-4881`), stopped by `m2154d0` (`MAS.java:3319`) from: mapping change
(`j20.java:569-572`), mouse off (`j20.java:435`), cursor sleep (`MAS.java:795`), `onDestroy`
(`MAS.java:4114`), or a second press of the same combo (`MAS.java:4859-4862`).

---

## 5. `p000/n60.java` — the 15-slot one-shot dispatcher

`public final class n60 implements Runnable` (`p000/n60.java:18`); fields `f10702n` (id),
`f10703o` (service). Dispatch `switch (i)` at `:39`; cases at
`:40`(0) `:55`(1) `:107`(2) `:113`(3) `:117`(4) `:122`(5) `:126`(6) `:130`(7) `:133`(8)
`:159`(9) `:163`(10) `:189`(11) `:193`(12) `:197`(13) `:201`(default = 14).

| id | posted by | delay | body | effect |
|---|---|---|---|---|
| 0 | `MAS.java:4233` — `onKeyEvent`, gate `z && !f4163k0 && keyCode == f4170n0` (`MAS.java:4225`), cached instance `f4188t0` (`MAS.java:548`) | `j = f4176p0*100` ms (`MAS.java:4219`), only when `f4167m0 && j > 0` (`:4220-4224`) | `if (!f4163k0) { if (prefs.getBoolean("pref_haptic_feedback",true)) m2171n0(100); m2117X(svc,true,false,6); m2142U(); }` (`:40-54`) | **Toggle-key long press wakes the cursor**: vibrate 100 ms, take gamepad focus, show cursor. Cancelled on key-up (`MAS.java:4241-4246`, log `"Wake key UP passed through (long press cancelled)"`) |
| 1 | `n60.java:102`, `MAS.java:2570` | 120 / 250 ms | if keyboard mode: re-hit-test the field at `(f4142Z0,f4144a1)` → if null close keyboard; if its bounds match the pre-Enter `f4122P1` within 24 px on all edges → close keyboard; else adopt the new field as `f4097H0`, rebuild `C0575lv`, move the cursor to the new field centre, `postDelayed(n60(9), 120)` (`:55-106`) | **IME-Enter follow-up**: focus moved to the next field ⇒ keep the keyboard, same field ⇒ close |
| 2 | `MAS.java:800` (fade-out end action) | 200 ms | `if (!f4145b0 && f4172o != null) f4172o.setVisibility(8)` (`:107-112`) | hide the cursor sprite window after it has faded out |
| 3 | `j20.java:76` | 120 ms | `m2141S()` (`:113-116`) | reposition the keyboard after `pref_kb_dex_width/height/pos` changed |
| 4 | `MAS.java:1651` | 50 ms | `m2135L(1)` then `postDelayed(n60(8), 250)` (`:117-121`) | **BACK**: `performGlobalAction(BACK)`, then re-arm focus 250 ms later |
| 5 | `MAS.java:1901` | 0 (post) | Toast `R.string.dex_switch_pro_required` (`:122-125`) | R3 in a DeX/pro-gated context |
| 6 | `MAS.java:3456` (`m2158g0`) | 120 ms | `m2141S()` (`:126-129`) | reposition after a language switch |
| 7 | `MAS.java:3716` | 0 (post) | `m2117X(svc, true, false, 4)` (`:130-132`) | re-take gamepad focus after the black-screen overlay is created |
| 8 | `n60.java:120` | 250 ms | clear `FLAG_NOT_FOCUSABLE` (`flags &= ~8` = `-9`) on the display's focus view, `updateViewLayout`, `requestFocus()` (`:133-158`) | make the gamepad focus view focusable again |
| 9 | `n60.java:102` | 120 ms | `m2141S()` (`:159-162`) | reposition the keyboard after the field changed |
| 10 | `o60.java:48` | 310 ms | if `f4113M1 != null`: null it; if keyboard mode still valid → Pro-gate (`db0.m2408b()`) then `m2133J(node, f4116N1, f4119O1)` else `m2146Z(keyboard_pro_required)`; else `recycle()` (`:163-188`) | **delayed keyboard open** at the double-tapped field |
| 11 | `MAS.java:2411` | 120 ms | `m2141S()` (`:189-192`) | first reposition after the keyboard window is added |
| 12 | `MAS.java:2412` | 600 ms | `m2141S()` (`:193-196`) | second reposition once the IME animation settled |
| 13 | `t60.java:573` | 0 (post) | `m2163j(false)` (`:197-200`) | close the keyboard on `ACTION_OUTSIDE` touch |
| 14 | `t60.java:589` | 65 ms | `f4165l0 = false`; if `f4163k0` → `m2116T(focusView(displayId), displayId)` (`:201-215`) | debounced **focus reclamation** after an ignored focus loss |

---

## 6. Remaining helpers

### 6.1 `p000/o60.java` — "click then maybe open the keyboard" (`:11`, `Runnable`)
Fields: `f11329n` id, `f11330o` service, `f11331p` x, `f11332q` y (`:14-29`).

* **id 0** (`:39-54`), posted at **40 ms** from `MAS.java:1612` (A/B key-*up* after a
  `m2174q` tap, when `f4085D0 && !f4082C0`):
  ```
  if (f4163k0 && !f4082C0 && f4129T && f4085D0 && !f4147c0 && !f4149d0) {
      AccessibilityNodeInfo n = m2180y(x, y, 24.0f);
      if (n != null) { f4113M1 = n; f4116N1 = x; f4119O1 = y; postDelayed(n60(10), 310); }
      else postDelayed(o60(x,y,1), 380);      // retry once, 380 ms later
  }
  ```
* **id 1** (default, `:55-75`):
  ```
  same 6-way guard;
  n = m2180y(x, y, 36.0f);                    // bigger radius on the retry
  if (n == null) { Log.d(…"Keyboard check: no editable node found at (x, y)"); return; }
  if (!db0.m2408b()) { n.recycle(); m2146Z(m2126B(R.string.keyboard_pro_required)); return; }
  m2133J(n, x, y);                            // OPEN the on-screen keyboard
  ```
**Semantics:** a gamepad "click" on an editable field probes with r=24 px; on a miss it retries
once after 380 ms with r=36 px before giving up. The hit node is consumed 310 ms later by
`n60(10)`.

### 6.2 `p000/r60.java` — `BroadcastReceiver`, two instances (`:16`)
* **id 0** = `f4093G`, `ACTION_BATTERY_CHANGED` (`:39-71`): reads `level`/`scale`/`status`;
  charging iff `status ∈ {2,5}`; writes `"%d%%" + (charging ? getString(R.string.charging) : "")`
  into the `TextView` tagged `"batteryView"` inside `f4178q`. Registered only while the
  black-screen overlay is up (`MAS.java:3040`), unregistered in `m2129E`
  (`MAS.java:2017`) and in `onDestroy` (`MAS.java:4170`).
* **id 1** = `f4092F1`, `ACTION_SCREEN_OFF` (`:72-100`):
  ```
  m2154d0(null);                                       // stop repeat-click silently
  if ((display == null || displayId != 0) && f4129T && f4131U) { m2145Y(); return; }   // DeX → blackout overlay
  if (f4163k0) m2117X(svc, false, false, 6);           // else drop gamepad focus
  ```

### 6.3 `p000/q60.java` — `Runnable`, brightness HUD / global action (`:9`)
Fields: `f12518n` selector (`:12`), `f12519o` int payload (`:15`), `f12520p` service (`:18`).
Two synthesized constructors: `q60(int, svc)` (`:20`) and `q60(svc, int)` (`:42`).

```
switch (selector) {
  case 0: performGlobalAction(payload);                        // :33
  default: Toast.makeText(svc, svc.getString(R.string.action_brightness_format,
                         (payload * 100) / 255), Toast.LENGTH_SHORT).show();   // :37
}
```
jadx prints the selector as a constant `1` (`:12`), which would make `case 0` dead. The call
sites prove otherwise — `m2135L(1/2/3)` is reached from the *BACK* / *HOME* / *RECENTS*
handlers (`MAS.java:1651→n60(4)→n60.java:119`, `MAS.java:1563`, `MAS.java:1577`) and posts
`q60(this, action)` (`MAS.java:2489`), while the brightness path posts `q60(brightness, this)`
(`MAS.java:3079`). So: `(svc,int)` ⇒ selector 0 ⇒ `performGlobalAction`; `(int,svc)` ⇒
selector 1 ⇒ brightness Toast.

### 6.4 `p000/u60.java` — `DisplayManager.DisplayListener` (`:10`, field `f15240a`)
* `onDisplayAdded` (`:20-26`): `f4205z = false` ("forced-off" reset), `m2155e0()`, `m2162i0()`.
* `onDisplayChanged` (`:29-48`): if `displayId == 0` and the display state is `1`
  (`Display.STATE_OFF`) and the current focus display is not 0 and `f4129T && f4131U` →
  `m2145Y()` (blackout). Always ends with `m2155e0()`, `m2162i0()`.
* `onDisplayRemoved` (`:51-56`): `m2155e0()`, `m2162i0()`.

### 6.5 `p000/v60.java` — `FrameLayout` scrim under the keyboard (`:11`)
Fields: `f16139n` = the `C1059yy` keyboard view, `f16140o` = service (`:14-17`).
`onTouchEvent` (`:34-51`): on `ACTION_DOWN`, if the touch lies inside the keyboard's window
rect (the decompiled bounds test at `:41-44` is partially lost — it compares `x` against
`x0` and `x0+width`, `y` against `y0` and `y0+height`) it logs
`"Keyboard scrim tapped -> closing keyboard"` and calls `m2163j(true)`; always returns `true`.

### 6.6 `p000/w60.java` — `GestureResultCallback` for scrolls (`:10`, field `f17519a`)
`onCancelled` (`:20-23`) → `Log.w("MouseService", "Scroll gesture cancelled. Resetting state.")`,
`f4159i0 = false`. `onCompleted` (`:26-29`) → `Log.d(…"Scroll gesture completed successfully.")`,
`f4159i0 = false`. I.e. it is the only thing that clears the "scroll in flight" latch used by
`s60` id 6 (`s60.java:180`) and set by `m2134K` (`MAS.java:2447`).

### 6.7 `p000/x60.java` / `p000/y60.java` — `TakeScreenshotCallback` (`x60:11`, `y60:11`)
Three-stage screenshot fallback chain:
1. `x60` = **window** capture: `onSuccess` → `m2128D(result, display, "window")` (`x60.java:30-34`);
   `onFailure` → `log "Window screenshot failed (code=…), trying display capture"` then
   `m2156f0(display, "window-fallback")` (`x60.java:24-28`).
2. `y60` = **display** / system capture: `onSuccess` → `m2128D(result, display, tag)` (`y60.java:33-37`);
   `onFailure` → `log "Display screenshot failed (code=…), falling back to system screenshot"`
   then `performGlobalAction(9)` = `GLOBAL_ACTION_TAKE_SCREENSHOT` (`y60.java:28-31`).
`y60` also carries a `String f19054c` tag so the three stages are distinguishable in the log.

### 6.8 `p000/ma0.java` — generic 2-tuple (`:7`)
`public final class ma0 implements Serializable` with `f9986n`, `f9987o` (`:10-13`), a
`(Object,Object)` constructor (`:15-18`), `equals` via `xl3.m8871b` (`:20-32`), `hashCode`
(`:34-49`), `toString` = `"(a, b)"` (`:51-53`). In this app it is used as:
* the return type of `m2144W(name)` — `ma0(Float x, Float y)` of a stored click location
  (`s60.java:266`, `MAS.java:4839`);
* key/value pairs for the immutable maps in `C0950w`, `C0575lv`, and the cursor-colour map
  `f4101I1` (`MAS.java:569`, `x20.m8738Z(new ma0(...), ...)`).
Reimplement as a `record Pair<A,B>`.

### 6.9 `p000/C0575lv.java` — IME text model + Hangul automaton (`:12`)
Backs everything the on-screen keyboard does; `s60` ids 1/4/8 and `t60` mutate it.
Fields (`:30-45`): `f9697a` committed `StringBuilder`, `f9698b` composing jamo
`StringBuilder`, `f9699c` pending initial consonant, `f9700d` pending vowel,
`f9701e` pending final-consonant index, `f9702f` caret offset (in `f9697a`).

| Member | Behaviour | Lines |
|---|---|---|
| `f9692g` / `f9693h` | 19 initial consonants (U+3131…) / 21 medial vowels (U+314F…) | 15, 18 |
| `f9694i`, `f9695j`, `f9696k` | consonant→index, index→consonant, vowel-combination tables (e.g. `ㅗ+ㅏ→ㅘ`) | 21-27, 47-78 |
| `m5200a(c1,c2,fin)` | compose syllable: `((idx(c1)*21 + idx(c2))*28 + 0xAC00 + fin)` | 82-92 |
| `m5201b()` | full text = committed text with the composing jamo spliced in at the caret | 95-108 |
| `m5202c(char)` | **type one character** (the whole Hangul state machine: consonant, vowel, final, compound vowel, dead-key) | 111-187 |
| `m5203d()` | flush composing jamo into the committed buffer | 190-200 |
| `m5204e()` | "is composing?" | 203-208 |
| `m5205f()` | caret **down one visual line**, preserving the column | 211-232 |
| `m5206g()` | caret **up one visual line**, preserving the column | 235-252 |
| `m5207h()` | the composing string | 255-267 |

Used by `t60` only via `m5205f`/`m5206g` (`t60.java:168,170`) and by `s60` id 8
(`s60.java:241,243`).

### 6.10 `p000/C0950w.java` — accented-Latin dead-key state (`:8`)
Field: `f17376a` pending-accent kind (`:17`); maps `f17374b` = acute/grave set
(`a→á e→é i→í o→ó u→ú A→Á …`, `:11`) and `f17375c` = diaeresis set (`:14`).
`m8492a(char c)` (`:20-34`): if `f17376a == 1` look up `f17374b`, if `== 2` look up
`f17375c`, else `null`; a space always yields `null`; the state is **always** cleared.
`f17376a` is set by `m2149b()` (`MAS.java:3110-3140`, write at `:3129`): `1` normally, `2` when the
shift/caps state changed since the accent key was pressed. Consumed from `m2132I`
(`MAS.java:2238` for `' '`, `MAS.java:2270` for the typed char).

### 6.11 `p000/j20.java` — `OnSharedPreferenceChangeListener`, two instances (`:18`)
Fields: `f8047a` selector, `f8048b` `ContextWrapper` (`:21-29`).
* **id 0** = `MainActivity` instance: pushes pref values back into the settings widgets
  (switches, seek bars, language check boxes, DeX width/height/pos, toggle keycode, L3
  duration). Details belong to the `MainActivity` spec — `j20.java:110-333`.
* **id 1** = the service instance (`f4098H1`, `MAS.java:570`), `j20.java:334-585`. It is the
  **live-apply path for every tuning constant** and therefore the place a reimplementation
  must mirror:

  | pref key | target | line |
  |---|---|---|
  | `pref_mouse_sensitivity` | `f4123Q = v/10.0` (def 20 ⇒ 2.0) | 341 |
  | `pref_scroll_speed` | `f4125R = v/50.0` (def 100 ⇒ 2.0) | 366 |
  | `pref_deadzone` | `f4127S = v/100.0` (def 15 ⇒ 0.15) | 475 |
  | `pref_mouse_speed` | `f4114N = v` (def 50) | 469 |
  | `pref_dex_speed` | `f4117O = v` (def 35) | 549 |
  | `pref_mouse_size` | `f4120P = v` (def 100) + `m2167l0()` | 353-354 |
  | `pref_mouse_timeout` | `f4133V = v` (def 0) + `m2142U()` | 462-463 |
  | `pref_cursor_color` / `_style` | `f4137X` / `f4135W` + `m2164j0()` | 522-542 |
  | `pref_kb_nav_interval` | `f4118O0 = v` (def 150) | 517 |
  | `pref_kb_nav_delay` | `f4121P0 = v` (def 300) | 372 |
  | `pref_keyboard_enabled` | `f4085D0 = v` (def true); closing the keyboard if it becomes false | 554-559 |
  | `pref_mouse_enabled` | `f4129T = v` (def true) + full teardown when false | 430-455 |
  | `pref_swap_ab_buttons` | `f4173o0` | 360 |
  | `pref_l3_toggle_enabled` | `f4167m0` | 347 |
  | `pref_l3_long_press_duration` | `f4176p0` | 489 |
  | `pref_toggle_keycode` | `f4170n0` (def 106) | 511 |
  | `pref_force_mirroring` | `f4090F` + `m2162i0()` | 424-425 |
  | `pref_dex_lockscreen_enabled` | `f4131U` | 496 |
  | `pref_haptic_feedback`, `pref_kb_move_sound` | `m2171n0` gate / `f4124Q0` | —, 483 |
  | `pref_kb_lang_en/ko/es` | `f4109L0/f4112M0/f4115N0`, then refocus keyboard | 377-420 |
  | `pref_kb_dex_width/height/pos` | `f4126R0/f4128S0/f4130T0`, then `m9200g(...)` + `n60(3)@120` | 180-209 |
  | `pref_mapping_x_<name>_type` | if the active repeat-click mapping's type changed → stop it (`toast_repeat_stopped`) | 569-572 |
  | `pref_mapping_x_<name>_interval` | `f4193v = m2140R(name)` (live re-timing of loop 9) | 574-578 |

---

## 7. `p000/t60.java` — the gamepad event surface

`public final class t60 extends View` (`p000/t60.java:14`); field `f14480n` = the service
(`:17`). One instance per **display with `Display.getState() == 2` (`STATE_ON`)** is added to
`f4175p` (`displayId → View`) (`MAS.java:3381-3401`) as:

```
new WindowManager.LayoutParams(15, 15,          // 15×15 px
        2032,                                   // TYPE_ACCESSIBILITY_OVERLAY
        262432,                                 // WATCH_OUTSIDE_TOUCH|LAYOUT_IN_SCREEN|NOT_TOUCH_MODAL
        -3)                                     // PixelFormat.TRANSLUCENT
  gravity = TOP|START (8388659), x = 0, y = 0
  flags |= 8 (FLAG_NOT_FOCUSABLE) when !f4163k0
```
It is not `FLAG_NOT_TOUCHABLE`, which is why it also receives `ACTION_OUTSIDE`/`ACTION_DOWN`.
Callbacks: `dispatchGenericMotionEvent` (`:26`), `onGenericMotionEvent` (`:48`),
`onKeyDown` (`:518`), `onKeyUp` (`:530`), `onTouchEvent` (`:549`).

### 7.1 The four callbacks, short form

| Callback | Behaviour | Lines |
|---|---|---|
| `dispatchGenericMotionEvent` | if `!f4129T` → `super`. If `action == ACTION_SCROLL (8)` and `axis(9)` (`AXIS_VSCROLL`) or `axis(10)` (`AXIS_HSCROLL`) is non-zero → **return `true`** (swallow the legacy wheel event without acting on it). Else `super`. | 26-39 |
| `onKeyDown` / `onKeyUp` | if source has `SOURCE_GAMEPAD (0x401)` or `SOURCE_JOYSTICK|SOURCE_DPAD (0x1000010)` → `f14480n.m2127C(event)`; return `true` if it consumed the key. Else `super`. | 518-539 |
| `onTouchEvent` | `ACTION_OUTSIDE (4)` → if keyboard mode, hit-test the keyboard rect then `getHandler().post(n60(13))`; then: if not dragging and no scroll and `now-f4182r0 >= 300` → if `!f4076A0 && now-f4079B0 >= 1500` sleep the cursor (`m2117X(svc,false,false,2)`, log `"Focus lost to external touch on display N. Sleeping."`), else clear `f4076A0`. If still holding → set `f4165l0` and `postDelayed(n60(14), 65)`. `ACTION_DOWN` and `now-f4182r0 > 500` → `m2117X(svc,false,true,2)` (log `"Direct touch on focus view detected. Sleeping."`). Always returns `true`. | 549-597 |

### 7.2 Axis map actually used

| Axis id | Android name | Read at | Role |
|---|---|---|---|
| 0 | `AXIS_X` | `:88` (kb), `:371` (mouse) | left stick X → keyboard stick nav (kb) / cursor velocity (mouse) |
| 1 | `AXIS_Y` | `:89`, `:372` | left stick Y |
| 9 | `AXIS_VSCROLL` | `:32` | swallowed only (legacy wheel) |
| 10 | `AXIS_HSCROLL` | `:33` | swallowed only |
| 11 | `AXIS_Z` | `:108`, `:373` | (kb) nav horizontal A / (mouse) scroll X A |
| 12 | `AXIS_RX` | `:109`, `:375` | (kb) nav horizontal B / (mouse) scroll X B |
| 13 | `AXIS_RY` | `:111`, `:376` | (kb) nav vertical B / (mouse) scroll Y B |
| 14 | `AXIS_RZ` | `:110`, `:374` | (kb) nav vertical A / (mouse) scroll Y A |
| 15 | `AXIS_HAT_X` | `:86`, `:403` | D-pad X |
| 16 | `AXIS_HAT_Y` | `:87`, `:404` | D-pad Y |
| 17 | `AXIS_LTRIGGER` | `:310`, `:383` | LT (primary) |
| 18 | `AXIS_RTRIGGER` | `:320`, `:393` | RT (primary) |
| 22 | `AXIS_GAS` | `:328`, `:401` | RT (**fallback** when axis 18 reads exactly 0) |
| 23 | `AXIS_BRAKE` | `:318`, `:391` | LT (**fallback** when axis 17 reads exactly 0) |

Nothing else is read. Note the two quirks: the paddings `16777232 = SOURCE_JOYSTICK|SOURCE_DPAD`
and `1025 = SOURCE_GAMEPAD` (`:77`, `:520`, `:532`), and the "if the primary trigger axis is
exactly 0.0, use the 22/23 axis instead" fallback (`:310-329`, `:383-402`).

### 7.3 Deadzones and the two activation masks

```java
float dz      = f4127S;                                  // 0.15 default
float moveDz  = dz + 0.2f; if (moveDz < 0.35f) moveDz = 0.35f;   // :90-94
if (dz < 0.2f) dz = 0.2f;                                        // :95-97
hatActive   = |hatX| > 0.5f || |hatY| > 0.5f;                    // :98-102  (z6)
stickActive = |lx|   > moveDz || |ly| > moveDz;                  // :103-107 (z7)
```
Three different thresholds coexist **on purpose** and must not be unified:
* `0.5` hard threshold for the digital D-pad,
* `f4127S+0.2` (min `0.35`) for *starting* keyboard stick navigation,
* `max(f4127S, 0.2)` for *stopping* it and for the cursor/scroll magnitude test
  (`:292`, `:450`).

That gives a 0.15-wide Schmitt band, and the 0.25 band at `:121` / `:274` is a second
hysteresis for the D-pad release (`|hat| <= 0.25` ⇒ really released).

### 7.4 Cursor acceleration (only in the non-keyboard branch)

Applied per motion event while `|left stick| > f4127S` (`t60.java:455-463`):
```java
float mag = hypot(lx, ly);
float t   = (mag - f4127S) / (1.0f - f4127S);        // 0..1 normalised past the deadzone
float k   = (f4123Q - 1.0f) / 2.0f;                  // sensitivity 1.5 → 0.25 ; 2.0 → 0.5
float shaped = (float)(Math.pow(t, 2.5) * k * 0.9f) + (1.0f - k * 0.9f) * t;
f4099I = (lx / mag) * shaped;
f4102J = (ly / mag) * shaped;
```
So the output is a **unit vector scaled by a 2.5-power ease-in blend**: low deflection is
nearly linear (`1 - 0.9k` slope), high deflection adds the `t^2.5` term up to `0.9k`. With the
defaults (`k = 0.25`) the curve is `0.775·t + 0.225·t^2.5`.

The keyboard branch writes `f4099I = f4102J = 0` (`:362-365`) and instead drives the
keyboard via loops 1/4/8.

### 7.5 Complete pseudocode of `onGenericMotionEvent`

Constants: `SRC_JOY = 16777232`, `SRC_GP = 1025`, `HANDLED = z2`.
All field names are the service's real obfuscated names so this can be diffed against the
decompiled source line by line.

```java
boolean onGenericMotionEvent(MotionEvent ev) {                              // :48
    MouseAccessibilityService S = this.f14480n;
    if (!S.f4129T) return super.onGenericMotionEvent(ev);                   // :74-76

    // ---- only gamepad / joystick sources are interesting ------------------
    if ((ev.getSource() & SRC_JOY) == SRC_JOY || (ev.getSource() & SRC_GP) == SRC_GP) {   // :77
        if (S.f4163k0 && S.f4082C0) {                                       // :79  BRANCH A
            runKeyboardMode(ev, S);                                         // :80-369
            return true;                                                    // :510-512 (z2==true)
        }
        runMouseMode(ev, S);                                                // :370-509 BRANCH B
        if (z2) return true;                                                // :510-512
    }
    return super.onGenericMotionEvent(ev);                                  // :514
}

// ======================= BRANCH A : keyboard / IME mode =======================
void runKeyboardMode(MotionEvent ev, MouseAccessibilityService S) {
    long  now  = System.currentTimeMillis();                                // :85
    float hatX = ev.getAxisValue(15), hatY = ev.getAxisValue(16);           // :86-87  AXIS_HAT_X/Y
    float lx   = ev.getAxisValue(0),  ly   = ev.getAxisValue(1);            // :88-89  AXIS_X/Y

    float dz     = S.f4127S;                                                // :90
    float moveDz = dz + 0.2f; if (moveDz < 0.35f) moveDz = 0.35f;           // :91-94
    if (dz < 0.2f) dz = 0.2f;                                               // :95-97
    boolean hatActive   = Math.abs(hatX) > 0.5f || Math.abs(hatY) > 0.5f;   // :98-102
    boolean stickActive = Math.abs(lx) > moveDz || Math.abs(ly) > moveDz;   // :103-107

    // --- 1. keyboard navigation from Z/RX (horizontal) and RZ/RY (vertical) ---
    float navA = ev.getAxisValue(11);   // AXIS_Z                              :108
    float navB = ev.getAxisValue(12);   // AXIS_RX                             :109
    float navC = ev.getAxisValue(14);   // AXIS_RZ                             :110
    float navD = ev.getAxisValue(13);   // AXIS_RY                             :111
    float navH = (Math.abs(navA) <= Math.abs(navB)) ? navB : navA;          // :112-114  max |Z|,|RX|
    float navV = (Math.abs(navC) >  Math.abs(navD)) ? navC : navD;          // :115-117  max |RZ|,|RY|
    // :118-119  dead locals
    if (Math.abs(navH) <= 0.5f && Math.abs(navV) <= 0.5f) {                 // :120  near centre
        if (Math.abs(navH) <= 0.25f && Math.abs(navV) <= 0.25f) {           // :121  fully released
            if (S.f4189t1 || S.f4183r1 != 0 || S.f4186s1 != 0) {            // :122-123
                if (S.f4189t1) { S.f4189t1 = false; S.f4096H.removeCallbacks(S.f4080B1); }  // :124-127
                if (S.f4192u1 == 0) {                                       // :129
                    S.f4192u1 = now;
                    S.f4096H.postDelayed(S.f4083C1, 140);                   // :130-131  gate id 7
                } else if (now - S.f4192u1 >= 120) {
                    S.m2161i();                                             // :133
                }
            }
        } else {
            S.f4192u1 = 0;                                                  // :137  hysteresis band
        }
    } else {
        S.f4192u1 = 0;                                                      // :140
        int dirX, dirY;
        if (Math.abs(navH) >= Math.abs(navV)) { dirX = (navH > 0 ?  1 : -1); dirY = 0; }   // :141-147
        else                                  { dirY = (navV > 0 ?  1 : -1); dirX = 0; }   // :148-156
        if (dirX != S.f4183r1 || dirY != S.f4186s1 || !S.f4189t1) {          // :157
            S.f4183r1 = dirX; S.f4186s1 = dirY; S.f4189t1 = true;           // :158-160
            S.f4192u1 = 0;                                                  // :162
            if (dirX != 0) S.m2172o0(dirX);                                 // :163-164  word jump
            else {                                                          // :165-176
                boolean moved = (dirY > 0) ? S.f4100I0.m5205f() : S.f4100I0.m5206g();
                if (moved) { S.m2166l(); S.m2138P(); }
            }
            S.f4096H.removeCallbacks(S.f4083C1);                            // :177  id 7
            S.f4096H.removeCallbacks(S.f4080B1);                            // :178  id 8
            S.f4096H.postDelayed(S.f4080B1, S.f4121P0);                     // :179  id 8 @ 300 ms
        }
    }

    // --- 2. D-pad / stick / idle arbitration ---------------------------------
    if (hatActive) {                                                        // :182   (z6)
        S.f4174o1 = 0;                                                      // :183
        if (now - S.f4180q1 > 120) {                                        // :184  release debounce
            int dx, dy;
            if (Math.abs(hatX) >= Math.abs(hatY)) { dx = (hatX > 0 ?  1 : -1); dy = 0; }  // :185-190
            else                                  { dy = (hatY > 0 ?  1 : -1); dx = 0; }  // :191-197
            if (dx != S.f4164k1 || dy != S.f4166l1 || !S.f4171n1)           // :198
                S.m2148a0(dx, dy, 1);                                       // :199  mode 1 = repeat
        }
    } else if (stickActive) {                                               // :202   (z7)
        S.f4146b1  = now;                                                   // :203
        S.f4154f1  = 0;                                                     // :204
        S.f4158h1  = (float) Math.hypot(lx, ly);                            // :205
        int px = S.f4148c1, py = S.f4150d1;                                 // :208-213
        boolean wasActive = (px != 0 || py != 0);                           // :209-213
        int nx, ny;
        if (Math.abs(lx) >= Math.abs(ly) * 1.5f)      { nx = (lx > 0 ?  1 : -1); ny = 0; }   // :214-220
        else if (Math.abs(ly) >= 1.5f * Math.abs(lx)) { ny = (ly > 0 ?  1 : -1); nx = 0; }   // :221-228
        else                                          { nx = px; ny = py; }                 // :229-232
        if (nx == 0 && ny == 0) {                                           // :233  diagonal → dominant
            if (Math.abs(lx) >= Math.abs(ly)) nx = (lx > 0 ? 1 : -1);        // :234-238
            else                              ny = (ly > 0 ? 1 : -1);        // :239-244
        }
        if (nx != px || ny != py || !S.f4156g1) {                            // :246
            boolean keepFast = wasActive && S.f4156g1;                       // :247-251
            S.f4148c1 = nx; S.f4150d1 = ny; S.f4152e1 = 1; S.f4156g1 = true;// :252-255
            if (S.f4088E0 != null && S.f4088E0.m9196c(nx, ny)) S.m2138P();   // :256-259
            S.f4096H.removeCallbacks(S.f4204y1);                             // :260  id 3
            S.f4096H.removeCallbacks(S.f4201x1);                             // :261  id 4
            long delay;
            if (keepFast) delay = (S.f4158h1 < 0.9f) ? S.f4118O0 * 2 : S.f4118O0;  // :262-267
            else          delay = S.f4121P0;                                 // :268-270
            S.f4096H.postDelayed(S.f4201x1, delay);                          // :271  id 4
        }
    } else {                                                                // :273  nothing pressed
        if (Math.abs(hatX) <= 0.25f && Math.abs(hatY) <= 0.25f) {            // :274
            if (S.f4171n1 || S.f4164k1 != 0 || S.f4166l1 != 0) {             // :275-276
                if (S.f4171n1) { S.f4171n1 = false; S.f4096H.removeCallbacks(S.f4207z1); }  // :277-280
                if (S.f4174o1 == 0) {                                        // :282
                    S.f4174o1 = now;
                    S.f4096H.postDelayed(S.f4077A1, 140);                    // :284  gate id 0
                } else if (now - S.f4174o1 >= 120) S.m2157g();               // :285-286
            }
        } else S.f4174o1 = 0;                                                // :290

        if (Math.abs(lx) <= dz && Math.abs(ly) <= dz) {                      // :292
            if (S.f4148c1 != 0 || S.f4150d1 != 0) {                          // :293
                if (S.f4156g1) { S.f4156g1 = false; S.f4096H.removeCallbacks(S.f4201x1); }  // :294-297
                if (S.f4154f1 == 0) {                                        // :298-299
                    S.f4154f1 = now;
                    S.f4096H.postDelayed(S.f4204y1, 140);                    // :301  gate id 3
                } else if (now - S.f4154f1 >= 120) S.m2159h();               // :302-303
            }
        } else S.f4154f1 = 0;                                                // :307
    }

    // --- 3. triggers: RT = Enter, LT = shift latch ---------------------------
    float ltRaw = ev.getAxisValue(17);                                      // :310  AXIS_LTRIGGER
    float lt    = (ltRaw != 0f) ? ltRaw : ev.getAxisValue(23);               // :311-319 (AXIS_BRAKE)
    float rtRaw = ev.getAxisValue(18);                                      // :320  AXIS_RTRIGGER
    float rt    = (rtRaw != 0f) ? rtRaw : ev.getAxisValue(22);               // :321-329 (AXIS_GAS)

    if (rt > 0.5f) {                                                        // :330
        if (!S.f4200x0) {                                                   // :331
            S.f4200x0 = true;
            long t = System.currentTimeMillis();
            if (t - S.f4140Y0 >= 350) { S.f4140Y0 = t; S.m2136M(); }         // :333-337  IME Enter
        }
    } else if (rt < 0.3f) S.f4200x0 = false;                                // :339-341

    if (lt > 0.5f) {                                                        // :342
        if (!S.f4197w0) {                                                   // :343
            S.f4197w0 = true; S.f4136W0 = true; S.m2139Q();                  // :344-346
            if (S.f4111M.getBoolean("pref_haptic_feedback", true)) S.m2171n0(30);  // :347-351
        }
    } else if (lt < 0.3f && S.f4197w0) {                                    // :357
        S.f4197w0 = false; S.f4136W0 = false; S.m2139Q();                    // :358-360
    }

    S.f4099I = 0; S.f4102J = 0; S.f4105K = 0; S.f4108L = 0;                  // :362-365
    S.f4203y0 = hatX; S.f4206z0 = hatY;                                     // :366-367
    S.m2142U();                                                             // :368
}

// ==================== BRANCH B : normal mouse / cursor mode ====================
void runMouseMode(MotionEvent ev, MouseAccessibilityService S) {
    float lx   = ev.getAxisValue(0),  ly   = ev.getAxisValue(1);            // :371-372  AXIS_X/Y
    float sA   = ev.getAxisValue(11);  // AXIS_Z                            // :373
    float sC   = ev.getAxisValue(14);  // AXIS_RZ                           // :374
    float sB   = ev.getAxisValue(12);  // AXIS_RX                           // :375
    float sD   = ev.getAxisValue(13);  // AXIS_RY                           // :376
    float scrollX = (Math.abs(sA) <= Math.abs(sB)) ? sB : sA;               // :377-379
    float scrollY = (Math.abs(sC) <= Math.abs(sD)) ? sD : sC;               // :380-382
    // :383-402  LT = axis17 else axis23 ; RT = axis18 else axis22  (same as branch A)
    float hatX = ev.getAxisValue(15), hatY = ev.getAxisValue(16);           // :403-404  HAT_X/Y
    boolean handled = false;                                                // (= z, :405-447)

    // --- 1. triggers: RT ⇒ maximise/restore, LT ⇒ windowed/restore -----------
    if (S.f4163k0) {                                                        // :405
        boolean rtDown = (rt > 0.5f);                                       // :406-410
        if (rtDown && !S.f4200x0) {                                         // :411
            S.f4200x0 = true;
            if (S.f4191u0) S.m2179v("rt", false);                           // :413-414  combo modifier
            else { S.m2142U(); S.m2137N(true); }                            // :415-418  maximise
            handled = true;                                                 // :420
        } else {
            if (!rtDown && S.f4200x0) S.f4200x0 = false;                    // :422-423
        }
        boolean ltDown = (lt > 0.5f);                                       // :427-431 (see note 1)
        if (ltDown && !S.f4197w0) {                                         // :432
            S.f4197w0 = true;
            if (S.f4191u0) S.m2179v("lt", false);                           // :434-435
            else { S.m2142U(); S.m2137N(false); }                           // :436-439  restore
            handled = true;                                                 // :441
        } else if (!ltDown && S.f4197w0) S.f4197w0 = false;                 // :442-443
    }

    // --- 2. scroll vector from Z/RX/RY/RZ -----------------------------------
    if (S.f4163k0) {                                                        // :448
        float mag = (float) Math.hypot(scrollX, scrollY);                   // :449
        if (mag > S.f4127S) {                                               // :450
            S.f4105K = scrollX / mag;                                       // :451
            S.f4108L = scrollY / mag;                                       // :452
            handled = true;                                                 // :453
            /* --- 3. left-stick cursor velocity (acceleration) ---------------
               NOTE: jadx emitted this block under an impossible
               `if (!f4163k0)` (:454) and duplicated the tail at :499-509.
               Semantically it is simply the else-half of the scroll test. */
            float smag = (float) Math.hypot(lx, ly);                        // :455
            float dzS  = S.f4127S;                                          // :456
            if (smag > dzS) {                                               // :457
                float t = (smag - dzS) / (1.0f - dzS);                      // :458
                float k = (S.f4123Q - 1.0f) / 2.0f;                         // :459
                float sh = (float)(Math.pow(t, 2.5) * k * 0.9f) + (1.0f - k * 0.9f) * t;  // :460
                S.f4099I = (lx / smag) * sh;                                // :461
                S.f4102J = (ly / smag) * sh;                                // :462
                handled = true;                                             // :463
            } else { S.f4099I = 0; S.f4102J = 0; }                          // :464-467
        } else { S.f4105K = 0; S.f4108L = 0; }                             // :494-497

        // --- 4. D-pad as user mappings while the combo modifier is held ------
        if (S.f4191u0) {                                                   // :472-473
            if (hatY < -0.5f && S.f4206z0 >= -0.5f) S.m2179v("up",    false);  // :474-476
            if (hatY >  0.5f && S.f4206z0 <=  0.5f) S.m2179v("down",  false);  // :480-482
            if (hatX < -0.5f && S.f4203y0 >= -0.5f) S.m2179v("left",  false);  // :483-485
            if (hatX >  0.5f && S.f4203y0 <=  0.5f) S.m2179v("right", false);  // :486-488
            handled = true;                                                // :490
        }
        S.f4203y0 = hatX; S.f4206z0 = hatY;                                // :492-493 (also :507-508)
        handled = true;                                                    // :506 (jadx merge)
    }
    // :510  if (z2) return true;
}
```

**Two footnotes on branch B** (both are jadx artefacts, verified against the surrounding
control flow):

1. `t60.java:427-431` reads `if (axisValue > 0.5f) z5 = true; else z5 = false;` where
   `axisValue` is the **LT** value (`:389`), i.e. the LT latch. The reimplementation must use
   `lt > 0.5f`, not `rt`.
2. `t60.java:472` is printed as
   `if (Math.abs(axisValue23) <= 0.1f || Math.abs(axisValue24) > 0.1f)`; the duplicated copy at
   `t60.java:502` shows the intended shape is the **bare `if (f4191u0)`** guard, with the HAT
   edges evaluated on every event. Either reading is functionally identical for a centred
   D-pad, but implementing the `0.1f` form would drop combos while the stick is off-centre;
   implement the plain `f4191u0` guard.

### 7.6 What a clean reimplementation needs to preserve

1. `t60` is inserted **once per display** into `f4175p` and must be the focused view of an
   overlay window; `n60(8)`/`n60(14)`/`m2116T` exist solely to keep it focused, because losing
   focus is what makes the cursor sleep.
2. Returning `false` from `onGenericMotionEvent` lets the gamepad axes reach the foreground
   app; returning `true` swallows them. The current code swallows **everything** while
   `f4163k0` is on (branch A always, branch B via the merged `handled = true`).
3. `f4099I/f4102J/f4105K/f4108L` are **level-triggered per event and consumed by the 16 ms
   loop**; they are not deltas. They are zeroed by branch A (`:362-365`) so that a stick seen
   by a keyboard-mode event never leaks into cursor movement.
4. The cursor overlay itself does not move in `t60` — `t60` only sets velocities; `s60` id 6
   integrates and clamps them.

---

## 8. Consolidated timing table

Every delay/interval constant that appears in these files:

| Value | Where | Meaning |
|---|---|---|
| **16 ms** | `s60.java:210` | frame period of the cursor engine (id 6) |
| **40 ms** | `MAS.java:4022` (`m2170n`) | minimum spacing of drag stroke continuations (`f4157h0 = now + 40`) |
| **40 ms** | `MAS.java:1612` | delay before the "click → maybe open keyboard" probe (`o60` id 0) |
| **50 ms** | `MAS.java:3498`, `:4510`, `:4009`, `:3242` | tap / drag-continue stroke duration (`m2160h0`, `m2174q`, `m2170n`, `m2152c0`) |
| **50 ms** | `MAS.java:1651` | BACK post-processing (`n60(4)`) |
| **65 ms** | `t60.java:589` | focus reclamation debounce (`n60(14)`) |
| **80 ms** | `MAS.java:2489` | `q60` global-action delay inside `m2135L` |
| **110 ms** | `s60.java:84`, `s60.java:129` | keyboard key repeat rate (ids 2, 5) |
| **120 ms** | `s60.java:43,59,64,91,106,213,228,285`; `t60.java:132,184` | repeat-cancel / release hysteresis |
| **120 ms** | `n60.java:102`; `MAS.java:2411`; `MAS.java:3456` | keyboard reposition / field-change follow-up |
| **140 ms** | `t60.java:131,284,301` | release-gate one-shots (`s60` ids 0, 3, 7) |
| **150 ms** | `s60.java:69,116,249` / `f4118O0` | `pref_kb_nav_interval` — repeat interval |
| **150 ms** | `MAS.java:2466` | scroll gesture duration (`m2134K`) |
| **300 ms** | `f4121P0` / `s60.java:179,235,249` | `pref_kb_nav_delay` — initial repeat delay |
| **300 ms** | `MAS.java:4625` | mapped-action debounce (`f4187t`, `m2179v`) |
| **310 ms** | `o60.java:48` | press-and-hold-and-open-keyboard delay |
| **350 ms** | `t60.java:334` | RT → IME-Enter debounce |
| **380 ms** | `o60.java:51` | keyboard-probe retry |
| **400 ms** | `MAS.java:1342`, `MAS.java:1491` | long-press threshold for A/B and X repeats |
| **500 ms** | `s60.java:162` | stationary long-press → drag conversion |
| **500 ms** | `t60.java:592` | "direct touch on focus view" debounce |
| **600 ms** | `MAS.java:2412` | second keyboard reposition |
| **1000 ms** | `s60.java:64` | latched (mode 2) repeat self-timeout |
| **100..3000 ms** | `MAS.java:2834` (`m2140R`) | repeat-click interval, default **500** |
| **0 / ×100 ms** | `MAS.java:4219`, `:4233` | `pref_l3_long_press_duration` → toggle-key wake timer (`n60(0)`) |
| **`f4133V` s** | `s60.java:188` | `pref_mouse_timeout` auto-hide |
| **1500 ms** | `t60.java:578` | external-touch sleep guard |

---

## 9. Reimplementation checklist

1. One `Handler(Looper.getMainLooper())` and **one cached `Runnable` instance per loop**;
   `removeCallbacks(instance)` is the only cancellation mechanism used. Creating fresh
   runnables per post would silently break every stop path listed in §4.1.
2. Loop 6 must re-post itself in a `finally` — the app never cancels it except in `onDestroy`.
3. Loops 0/3/7 are *release gates*: 120 ms of continuous "released" state before the
   corresponding cancel runs; they are re-armed by every motion event that sees the stick
   come down again.
4. Loops 1/4/8 are *keyboard-mode only* (`f4082C0`); loops 2/5 need an additional latch
   (`f4162j1` / `f4160i1`) that the key handler clears on key-up.
5. Speed constants are **per 16 ms frame**, not per second.
6. The scroll gesture is anchored at `(cursorX, screenH/2)` — `f5 = f4084D/2.0f`,
   `path.moveTo(f4, f5)` (`MAS.java:2449`, `:2458`) — a quirk, but it is what the gesture path
   does; the stroke length is `f4125R * 180 * (displayId==0 ? 1.0 : 0.5)` px (`MAS.java:2455`).
7. `w60` is the only place that clears the scroll-in-flight latch; a scroll whose callback
   never fires permanently blocks scrolling. Consider a timeout in a rewrite.
