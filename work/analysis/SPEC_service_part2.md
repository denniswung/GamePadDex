# Gamepad Mouse v2.0.2 — `MouseAccessibilityService` implementation spec, part 2 (lines 2060–3600)

Reverse-engineered from jadx 1.5.0 output, R8-obfuscated (`com.pkyul13.gamepadmouse`, 2.0.2).

Primary artifact: `work/decompile/pkyul13_sources/gamepadmouse/MouseAccessibilityService.java`
(4963 lines). **All citations `MouseAccessibilityService.java:NNNN` refer to that file.**

Scope: methods whose body starts in **2060–3600**, plus the few helpers/handlers that this
range *requires* in order to be implemented faithfully:
`m2117X` (693–870), `m2129E` (2004–2051), `m2125A` (1098–), `m2162i0` (3519–3728),
`m2163j` (3731–3795), `m2164j0` (3798–3878), `m2165k0` (3881–3894), `m2166l` (3897–3939),
`m2167l0` (3942–3961), `m2170n` (3994–4029), `m2172o0` (4067–4102),
`m2173p`/`m2174q`/`m2175r`/`m2176s`/`m2177t`/`m2178u` (4487–4605), `m2180y` (4919–4954).

---

## 0. Provenance, method, and naming

* Every claim below was read directly out of the assigned file. Behaviour of the *handlers*
  (`n60`, `s60`, `q60`, `o60`, `t60`, `v60`, `w60`, `u60`, `y60`, `C0575lv`, `C1059yy`,
  `C0950w`, `C0360g`, `AbstractC0185c0`) lives in `p000/*.java`, which the trimmed dump in
  `work/decompile/pkyul13_sources/` does **not** contain. Those classes were read from the
  original jadx output of the same APK at
  `\\wsl.localhost\Ubuntu-24.04\home\denniswung\gpm\out\sources\p000\`,
  and parity of the *service* file was verified at anchors `2469`, `2578`, `3391`, `3402`,
  `4372`, `1852` — identical line numbers. Inner-class citations are written
  `p000/s60.java:148` and are therefore usable, but if you only trust the trimmed dump,
  read them as "handler called from `MouseAccessibilityService.java:NNNN`".
* Naming is meaningless (R8). Names below are *behavioural* and are used consistently:
  `f4081C` = display width px, `f4084D` = display height px, `f4075A` = cursor X,
  `f4078B` = cursor Y, `f4172o` = cursor `ImageView`, `f4181r` = cursor LayoutParams,
  `f4169n` = display-scoped `WindowManager`, `f4199x` = current `Display`,
  `f4196w` = `DisplayManager`, `f4175p` = `LinkedHashMap<displayId, View>` of focus-catcher
  views, `f4145b0` = "cursor is shown", `f4147c0` = "drag in progress",
  `f4149d0` = "tap pressed, awaiting up", `f4155g0` = live `StrokeDescription`,
  `f4159i0` = "scroll gesture in flight", `f4163k0` = "keyboard overlay mode active",
  `f4082C0` = "keyboard overlay open", `f4129T` = pref `pref_mouse_enabled`,
  `f4109L0/f4112M0/f4115N0` = per-language enabled flags,
  `f4100I0` = Hangul/IME composing buffer, `f4103J0` = dead-key (accent) composer,
  `f4088E0` = keyboard view, `f4091F0` = keyboard scrim container.

---

## 1. Method table (2060–3600 plus required helpers)

| # | Signature (line) | Purpose | Exact behaviour |
|---|---|---|---|
|1|`m2130G()` — 2054 | Keyboard **backspace** | Operates on the IME buffer `f4100I0` in strict priority order: pending final-consonant latch (`f9701e`)→0, else composing vowel (`f9700d`)→null, else composing consonant (`f9699c`)→null, else delete last char of the standalone-jamo builder `f9698b`, else if committed text `f9697a` non-empty **and** caret `f9702f`>0 delete `charAt(f9702f-1)` and decrement caret. Then `m2166l()` pushes the whole buffer into the field. Guarded by `f4082C0` (2056).|
|2|`m2131H(int i, int i2)` — 2080 | Keyboard **caret navigation** | Requires `f4082C0` (2081). `i>0` (right): if a composition is pending (`m5204e()`) commit it (`m5203d`) else `f9702f++` if `< len`. `i<0` (left): always commit composition, then `f9702f--` if `>0`. `i2>0`: `m5205f()` = move caret **one visual line down**, preserving column (`indexOf("\n")`, clamped to next line length). `i2<0`: `m5206g()` = one visual line up. Ends with `m2166l()` + `m2138P()` (tick sound).|
|3|`m2132I(C0911uy key)` — 2107 | **Keyboard key dispatch** (typing) | `key==null` → return. Switch on `key.f15809f` (enum): **ordinal 0** = character key (2260–2288): pick label `f15808e` (shifted) when `capsLock==(shift\|\|sym)` else `f15807d`, then map through dead-key composer `C0950w.m8492a(c)`; insert via `m5202c` + `m2166l`. **ordinal 1** = space (2237–2257): same dead-key mapping on `' '` (dead-key + space yields `'`), fallback plain space. **ordinal 12** → `m2149b()` (accent/dead key). Other ordinals clear the dead-key latch (2125–2131) and then: 2→`m2130G()` backspace; 3→`m2136M()` enter; 4→`m2158g0()` cycle language; 5→toggle `f4134V0` (shift)+`m2139Q()`; 6→toggle `f4138X0` (caps)+`m2139Q()`; 7→`m2163j(true)` close keyboard; 8→insert `'\t'`; 9→paste clipboard `coerceToText(this)` char by char skipping `\n \r \t` (2165–2179); 10/11→arrow keys: if a modifier is held (caps≠shift) move by **line** (`enum==f17334w`→`m5206g` up, otherwise `m5205f` down) otherwise caret −1/+1 with the same commit-then-step logic as `m2131H` (2091–2102); 13→`m2163j(false)` then `startActivity(MainActivity, extra "open_page"="keyboard_settings", flags 805306368 = FLAG_ACTIVITY_NEW_TASK\|FLAG_ACTIVITY_CLEAR_TASK)` (2220–2231). Every path ends with 25 ms haptic via `m2171n0(25)` if `pref_haptic_feedback` (2289–2296).|
|4|`m2133J(AccessibilityNodeInfo n, float x, float y)` — 2304 | **Open the on-screen keyboard overlay** | Returns unless keyboard mode is off and `f4169n != null` (2312). Shows toast `toast_repeat_stopped`, clears the pressed-key set `f4194v0`, sets `f4082C0=true`, stores target node `f4097H0`, click point `f4142Z0/Z1`, resets shift/sym/caps/key-repeat flags (2316–2325), resets repeat state machines (`m2159h`), removes callbacks `f4086D1`(s60#5) and `f4089E1`(s60#2) (2327–2330). Language: from `m2176s()`; exactly 1 → that, else default (`EnumC0985wy.f17925n`) (2331–2341). Seeds the IME buffer with `m2115O(node)` text (hint-aware, 2342–2352). **Builds window W1** (see §2): `C1059yy(context=this.f4202y?:this, displayWidth=f4081C, external=!(displayId==0), callback=C0360g(2,this)→m2132I)`, `setLangToggleEnabled(langCount>=2)`, `setLang(f4106K0)`, `f19487s=f4134V0`(shift), `f19488t=f4138X0`(caps), `m9197d()` rebuild keys, `m9200g(pref_kb_dex_width/100f, pref_kb_dex_height/100f, m2173p())` (2371–2390). Wraps it in `v60` scrim (`setBackgroundColor(570425344)=0x22000000`, 2391–2392), child LP width = `displayWidth*pref_kb_dex_width/100` on phone else `MATCH_PARENT(-1)`, height `WRAP_CONTENT(-2)`, gravity `m2173p()` on phone else `BOTTOM(80)` (2393–2403). `addView` on `f4169n`; on success hides the mouse cursor (`visibility=GONE`, `alpha=0`, 2414–2421), clears key state, `m2142U()`, 60 ms haptic (2425–2429), then schedules `n60(11)` at **120 ms** and `n60(12)` at **600 ms** (both → `m2141S()`), 2411–2412. `addView` failure logs and sets `f4082C0=false` (2435–2438).|
|5|`m2134K(float dx, float dy)` — 2442 | **Discrete scroll gesture** (the real scroll) | SDK≥26 only. Sets `f4159i0=true` (gesture in flight), takes `y0=f4075A`(cursor X!) and `yc=f4084D/2` (**vertical centre of the display**, 2449), display factor `f3 = 1.0f` on display 0 else `0.5f` (2450–2455), `sweep = f4125R * 180.0f * f3` (2456). Path `moveTo(x0, yc)` → `lineTo(x0 - dx*sweep, yc - dy*sweep)` (2457–2459), stamped `f4182r0=now` (2461). One stroke **0 ms start, 150 ms duration** (2466), `setDisplayId(display.getDisplayId())` only when SDK≥30 (2463–2465), dispatched with `GestureResultCallback f4161j0` (w60) which resets `f4159i0` on complete/cancel. Exception path logs "Failed discrete scroll" and clears `f4159i0` (2468–2471). Caller: the 16 ms move loop, `p000/s60.java:181` with `(f4105K, f4108L)` = **normalised right-stick unit vector**.|
|6|`m2135L(int action)` — 2476 | **Request display focus then perform a global action** | `id = f4199x?.displayId ?: 0` (2478–2483); `view = f4175p.get(id)`; if present `m2116T(view, id)` = `view.post(requestFocus)` (2484–2487, helper 687–690). Then `m2160h0()` = fire a synthetic 50 ms "wake/prime" tap (see #31). Then `f4096H.postDelayed(new q60(this, action), 80L)` (2489). `q60` dispatches `performGlobalAction(action)` (`p000/q60.java:33`). Call sites prove the argument is a **GLOBAL_ACTION id**: `m2135L(2)` = HOME on BUTTON_START (1305, log 1562), `m2135L(3)` = RECENTS on BUTTON_SELECT (1318, 1577), `m2135L(1)` = BACK (p000/n60.java:119).|
|7|`m2136M()` — 2493 | Keyboard **Enter** | Requires `f4082C0` (2497). First commits the composition (`m5203d` + `m2166l`, 2501–2502). If SDK≥33 and the target node `isMultiLine()` → insert `'\n'` into the buffer, commit, log, **return** (2505–2516). Else SDK≥30: look up the nearest editable node at the click point (`m2125A(f4142Z0,f4144a1)`, fallback `f4097H0`), scan its `getActionList()` for `ACTION_IME_ENTER`'s id; when found, snapshot its screen bounds into `f4122P1` and `performAction(id)` (2518–2567, all calls try/catch-swallowed, recycles node only if it was freshly obtained). If the action was performed → `postDelayed(new n60(this,1), 250L)`; else log "committed and closed (no IME action available)" and `m2163j(true)` (2569–2574). **`n60(1)` (250 ms later)** re-resolves the editable node at the old click point: no node → close keyboard; node bounds within **24 px** of `f4122P1` on all four edges → IMEM action completed on the same field → close keyboard; otherwise retarget `f4097H0`, re-seed the IME buffer with the new field's text, move the click point to the new bounds centre and post `n60(9)` at 120 ms (`p000/n60.java:55–104`).|
|8|`m2137N(boolean maximize)` — 2578 | **DeX window maximize / restore** via accessibility | Keyword list: maximize → `["창 최대화","최대화","전체 화면","maximize","fullscreen"]`, restore → `["이전 크기로 복원","창 복원","창 모드로 전환","팝업 화면","restore","window"]` (2583–2587). Collects windows **of the current display only**: SDK≥30 `getWindowsOnAllDisplays().get(displayId)`, else `getWindows()` (2588–2608). Pass 1 (2611–2628): for each window root find a node by keyword (`m2123x`, walks up to nearest clickable ancestor) → log, set `f4076A0=true`, `f4079B0=now`, `performAction(16)` (ACTION_CLICK), recycle, return. Pass 2 (2630–2680): find the window handle node (`m2122w(root,"창 핸들")`), click it to expand the menu, then **on the main looper after 300 ms** run the anonymous `p60` runnable which calls `m2151c(keywords)` (§3.1); recycle, return. Fallback (2681–2769): if this is a *restore* on display 0 → "phone screen LT pressed" → `performGlobalAction(1)` (BACK); on DeX → retry direct restore-node click, then retry handle (also `"옵션 더보기"`), and finally a synthetic tap at `(f4081C/2, 30.0f)` with a **50 ms** stroke to hit the title bar (2757–2766).|
|9|`m2138P()` — 2775 | Keyboard **move tick** | Only when `pref_kb_move_sound` (`f4124Q0`, 2777). Lazy `m2178u()` (SoundPool init), `play(soundId, 0.8f, 0.8f, priority 1, loop 0, rate 1.0f)` (2784). Any exception → release SoundPool, null it, then **fallback to `ToneGenerator(AudioManager.STREAM_MUSIC=3, 90)` `startTone(24)`** (2795–2808).|
|10|`m2139Q()` — 2813 | Push shift/caps into the keyboard view | `f19487s = (f4134V0\|\|f4136W0)` (shift/sym), `f19488t = f4138X0` (caps), then `m9197d()` = rebuild key labels (`p000/C1059yy.java:369`). No-op if `f4088E0 == null`.|
|11|`m2140R(String key)` — 2830 | Repeat-click **interval** pref | `lo0.m5054i(pref.getInt("pref_mapping_x_"+key+"_interval", 500), 100, 3000)` → coerced to **100…3000 ms**, default **500** (2832). Stored into `f4193v` (4877).|
|12|`m2141S()` — 2839 | Keyboard **auto-reposition top/bottom** | Requires keyboard open, `f4088E0`, `f4091F0`, `f4097H0` (2848). Reads `rect = node.getBoundsInScreen`, `container.getLocationOnScreen` → `h = container.height`, `kh = keyboard.height`; `top = rect.top - containerY`; `wouldClipBottom = (rect.bottom - containerY) > (h - kh)`; `fieldAboveKeyboard = top < kh`; **move keyboard to TOP (48)** iff `wouldClipBottom && !fieldAboveKeyboard`, else **BOTTOM (80)** — horizontal gravity preserved via `lp.gravity & 7` (2872–2899). Logs "Keyboard repositioned to top/bottom to keep the focused field visible". All exceptions swallowed. Called from `n60(11)`@120 ms, `n60(12)`@600 ms (2411–2412), `n60(6)`@120 ms after language switch (3456) and `n60(3)/(6)/(9)` (p000/n60.java:115,128,161).|
|13|`m2142U()` — 2909 | **Activity/heartbeat stamp + blackout sync** | If `pref_mouse_enabled` (`f4129T`): `f4143a0 = now` (used by the cursor auto-hide timeout, p000/s60.java:188) and, **only when the cursor lives on display 0**, call `m2129E()` = hide the black-screen/lock overlay (2909–2916, 2004–2051). On DeX the blackout is deliberately *not* cleared by activity.|
|14|`m2143V(Bitmap)` — 2920 | Save screenshot PNG | File name `GamepadMouse_yyyyMMdd_HHmmss.png` (Locale.US), `mime_type=image/png`, `relative_path=DCIM/Screenshots`, `date_added=now/1000`; `MediaStore.Images.Media.EXTERNAL_CONTENT_URI.insert`; `compress(PNG, quality 100)`. Returns false on any failure (logs "Failed to save screenshot to MediaStore").|
|15|`m2144W(String key)` — 2951 | Parse **repeat-click point** | Reads `pref_mapping_x_<key>_value` (default `""`), splits on `","` with an empty-delimiter branch, requires exactly 2 parts, parses both as float → `new ma0(Float x, Float y)`; any parse error or wrong arity → `null` (2993–3000).|
|16|`m2145Y()` — 3007 | **Show black screen / lock overlay** | Acquires the `PARTIAL_WAKE_LOCK`… actually `f4184s` for 3000 ms if not held (3020–3027). If `f4178q != null`: enable/clickable/focusable, and if not already visible → `visibility=VISIBLE`, register the `ACTION_BATTERY_CHANGED` receiver once (`f4087E` guard, 3039–3042), set `LayoutParams.screenBrightness = 0.1f` and `updateViewLayout` (3043–3052), fade `alpha 0→1` over **500 ms**, and on display 0 fade the **cursor alpha→0 over 500 ms** (3053–3057).|
|17|`m2146Z(String msg)` — 3063 | Toast on the service handler | `f4096H.post(new RunnableC0698p6(this, 6, msg))` → `Toast.makeText(this, msg, LENGTH_SHORT).show()`.|
|18|`m2147a(int delta)` — 3068 | **Brightness step** (±25 from mappings) | Requires `Settings.System.canWrite`; `new = lo0.m5054i(current + delta, 0, 255)`; writes `screen_brightness`; **rate-limited to one toast per 500 ms** via `f4079B0`, posting `q60(brightness, this)` which shows `action_brightness_format` with `brightness*100/255` (3077–3081, `p000/q60.java:37`); forces `screen_brightness_mode=0` (auto-brightness off) if it was 1 (3082–3084). Called as `m2147a(-25)` / `m2147a(25)` (4674, 4901).|
|19|`m2148a0(int i, int i2, int mode)` — 3091 | **Arm keyboard caret auto-repeat** | Stores direction `f4164k1=i`, `f4166l1=i2`, `f4168m1=mode` (1 = stick, 2 = D-pad), `f4171n1=true`, `f4174o1=0`, `f4177p1=now`, and when `mode==2` also `f4180q1=now` (3091–3101); performs one immediate `m2131H(i,i2)` (3102); cancels `s60#0` and `s60#1` then `postDelayed(s60#1, f4121P0)` = **`pref_kb_nav_delay` (200–1500 ms, default 300)** (3103–3108). `s60#1` re-invokes `m2131H` every `f4118O0` = `pref_kb_nav_interval` (50…500 ms, default 150) and self-cancels via `m2157g()` when input is stale (>120 ms for mode 1, >1000 ms for mode 2) (`p000/s60.java:48–75`). Call sites: 1394 (mode 2, D-pad in keyboard mode), `p000/t60.java:199` (mode 1, left stick).|
|20|`m2149b()` — 3112 | **Dead-key / accent key** (R1 / es-layout key) | Requires `f4082C0`. `C0950w.f17376a` is the latch: 0 none, 1 acute, 2 umlaut. If it is non-zero → clear it and **insert an apostrophe `'` (0x27)** (3130–3145) — this is exactly what `m8492a(' ')` returns while a latch is armed, i.e. "dead key + space = apostrophe". Else arm it: `1`, or `2` when the keyboard is in uppercase state (`capsLock != shift`), no character inserted (3134–3139); additionally if it armed `2` while shift was on and caps off, shift is cleared and `m2139Q()` refreshes labels (3146–3149). Always `setAccentPending(f17376a)` on the view (3150–3153). Dead-key tables: acute `a→á e→é i→í o→ó u→ú A→Á…`, umlaut `a→ä … U→Ü` (`p000/C0950w.java:11,14`).|
|21|`m2150b0(float x, float y)` — 3158 | **Start drag** | `f4182r0=now`; `path.moveTo(x,y)`; cache `f4153f0 = {x,y}`; `f4155g0 = new StrokeDescription(path, 0L, 50L, willContinue=true)` (helper `p000/AbstractC0185c0.java:1354`); builder + `setDisplayId` (SDK≥30) + `addStroke` → `dispatchGesture(build, null, null)` (3168–3175). On exception: log "Failed to start drag", `f4155g0=null` (3176–3179).|
|22|`m2151c(List keywords)` — 3183 | **Re-search window action after opening the handle menu** | Same window collection as #8 (current display only, 3186–3205). For every window root: `m2123x(root, keywords)`; on hit → log "Found window action node after opening handle", set `f4076A0=true`, `f4079B0=now`, `performAction(16)`, recycle, return. Else log "Still couldn't find window action node after clicking handle." (3206–3223). Invoked by the two inline `p60` runnables 300 ms after the handle click.|
|23|`m2152c0(float x, float y)` — 3227 | **End drag** | No-op if no live stroke (`f4155g0==null`, 3230). SDK≥26: `path.moveTo(f4153f0[0], f4153f0[1]) → lineTo(x,y)`, `continueStroke(path, 0L, 50L, willContinue=false)`, null out `f4155g0`, `f4182r0=now`, builder+displayId+dispatch with **no** callback (3236–3251); exception → log "Failed to stop drag" and drop the stroke. SDK<26 → `m2174q(x,y)` plain tap (3258).|
|24|`m2153d(int color)` — 3262 | **Render the arrow cursor bitmap** | Bitmap cache hit when `f4139Y != null && color == f4137X` (3264). Builds a 12-point arrow polygon in a 240×240 space — `(8.3,2.6) (2.6,8.3) (2.2,16.7) (77.2,218.9) (82.4,226.4) (93.6,227.3) (99.7,220.3) (127.9,129.8) (220.3,99.7) (226.9,94.6) (227.8,85.2) (218.9,77.2) (18.1,2.6)` closed (3270–3283). Outline colour = white `-1` when perceived luminance `0.299R+0.587G+0.114B < 128` else `#1A1A1A` (3284–3288). `Bitmap.createBitmap(240,240,ARGB_8888)`, fill with `color`, stroke width **3.5 px**, `Join.ROUND`, `Cap.ROUND`, antialias, drawn twice (fill then outline) (3289–3304). Caches `f4139Y = bitmap; f4141Z = f4137X` (3305–3306).|
|25|`m2154d0(Integer toastRes)` — 3311 | **Stop repeat-click** | Remembers whether a repeat was active (`f4190u != null`), clears `f4190u`, removes `f4110L1` (s60#9) callbacks, and only if a repeat *was* active and a message id was supplied shows `m2146Z(m2126B(res))` — used with `toast_repeat_stopped` (2315) and `toast_repeat_stopped_cursor` (795, 3580).|
|26|`m2155e0()` — 3326 | **Create/destroy per-display focus-catcher windows (W2)** | Enumerates `DisplayManager.getDisplays()`; the "allow external" predicate is `z = db0.m2408b() /*isPro*/ && !f4090F /*pref_force_mirroring*/` (3330–3336). Live set = displays with `state == STATE_ON(2)` **and** (`displayId==0 \|\| z`) (3337–3342). Existing entries whose displayId is not in the live set are removed and their views `removeView`'d through *that view's own* `WindowManager` (3343–3377). For each live display not yet mapped: `createDisplayContext(display)` → (SDK≥30) `createWindowContext(TYPE_ACCESSIBILITY_OVERLAY=2032, null)` → `getSystemService("window")` → `new t60(ctx, this)`, `LayoutParams(15,15,2032,262432,-3)`, `gravity=8388659 (START\|TOP)`, `x=0,y=0`, and **`flags \|= FLAG_NOT_FOCUSABLE(8)` when the keyboard overlay is *not* active** (`!f4163k0`) (3378–3400). Failures only log "Error adding focusView to display N".|
|27|`m2156f0(Display, String stage)` — 3410 | Screenshot one display | `takeScreenshot(displayId or 0, executor f4104J1, y60 callback)`; exception → log + `performGlobalAction(9)` (system screenshot). `y60` success → `m2128D(result, display, stage)` (BITMAP copy out of HARDWARE config, then `m2143V` save, then toast via `h20`); failure → log + `performGlobalAction(9)` (`p000/y60.java:28–37`).|
|28|`m2157g()` — 3427 | Reset D-pad caret-repeat state | Zeros `f4164k1`, `f4166l1`, `f4168m1`, sets `f4171n1=false`, `f4174o1=0`, removes callbacks `s60#1` and `s60#0`.|
|29|`m2158g0()` — 3440 | **Cycle keyboard language** | Requires `f4082C0`. `m2177t()` (re-validate current lang), then if ≥2 languages: next = `(indexOf(current)+1) % size`, store `f4106K0`, clear dead-key latch, push `setLang`+`setAccentPending(0)` into the view, `postDelayed(n60(6), 120L)` (reposition), 40 ms haptic (3440–3466). Called from BUTTON_L1(102) (1403) and key enum 4 (2140).|
|30|`m2159h()` — 3472 | Reset right-stick/keyboard drag state | Zeros `f4148c1`, `f4150d1`, `f4152e1`, `f4154f1`, `f4156g1=false`, `f4158h1=0f`; removes `s60#4` and `s60#3`.|
|31|`m2160h0()` — 3486 | **Priming/wake tap** | If `f4199x != null`: `f4182r0=now`; path starts at `(0.0, 200.0)` **on display 0** or `(f4081C/2, 5.0)` on an external display (3492–3496); single stroke `0 → 50 ms`; `setDisplayId` on SDK≥30; dispatch with no callback (3497–3502). Purpose: give the foreground app a touch/focus event on the display before a global action or after focus churn. Called by `m2135L` (2488) and by the "show cursor" path (`p000/n60.java`/`m2117X:847`).|
|32|`m2161i()` — 3507 | Reset left-stick nav state | Zeros `f4183r1`, `f4186s1`, `f4189t1=false`, `f4192u1`; removes `s60#8` and `s60#7`. Guarded by nothing (state-only).|
|33|`m2162i0()` — 3519 | **Pick the display, (re)build cursor + blackout windows** | See §4 for the decision logic. Summary: pick display → if id or metrics changed: close keyboard (`m2163j(false)`), stop repeat click, remove cursor view, remove every focus view, `f4199x=display`, `f4202y=createDisplayContext(display)`, `f4169n=WM` from `createWindowContext(2032)` on SDK≥30, store new `f4081C/f4084D`; if the displayId changed → centre the cursor at `(w/2,h/2)`, else clamp the old position into the new bounds (3618–3624); `m2155e0()`; create cursor `ImageView` (**W3**) if `f4172o == null` (3626–3659); create the black-screen overlay (**W4**) if `f4178q == null` (3661–3712); `m2167l0()` (cursor size), `m2165k0()` (cursor position), `post(n60(7))` when keyboard mode is on (3713–3717); then the DeX policy: on a non-0 display with `pref_mouse_enabled && pref_dex_lockscreen_enabled` → log "DeX Detected - Blackout will activate on screen timeout", else `m2129E()` (3718–3724).|
|34|`m2163j(boolean keepCursor)` — 3731 | **Close keyboard overlay** | No-op unless open. `f4082C0=false`; recycle retry node `f4113M1`; remove W1 via `f4094G0` (fallback: the view's own WM); null `f4088E0/f4091F0/f4094G0/f4097H0`; clear IME buffer entirely (`f9697a/f9698b` len 0, composing fields null/0); reset dead-key latch, shift/sym/caps/key-repeat flags; `m2159h()`, `m2157g()`, `m2161i()`; remove `s60#5`, `s60#2`. If `keepCursor && f4163k0 && pref_mouse_enabled` → force cursor visible (`visibility=VISIBLE`, `alpha=1.0f`) (3783–3793). Logs "Keyboard mode closed".|
|35|`m2164j0()` — 3798 | **Set cursor drawable/bitmap** | No-op without `f4172o`. If `f4135W` (style name) matches a preset colour map (`f4101I1`: orange #FFA000, blue #2196F3, green #4CAF50, red #F44336, black #212121, white #FFFFFF, purple #9C27B0, cyan #00BCD4, pink #E91E63, yellow #FFEB3B) → switch style to `custom_color` and persist `pref_cursor_style`/`pref_cursor_color` (3803–3814). `custom` → decode `filesDir/custom_cursor.png` with `m2121o` (inSampleSize halving until <512, then downscale so max edge ≤ **512 px**, 949–981); missing/invalid → reset to `orange`, delete file (3815–3837). `custom_color` → `Color.parseColor(#-prefixed f4137X)` → `m2153d(color)`, invalid → reset to orange (3838–3865). Otherwise `setImageResource(R.drawable.ic_mouse_cursor)` (3866–3869). Whole body wrapped: on exception log + fall back to `ic_mouse_cursor`.|
|36|`m2165k0()` — 3881 | **Move the cursor window** | Writes `f4181r.x=(int)f4075A`, `.y=(int)f4078B`, `f4169n.updateViewLayout(f4172o, f4181r)`; exceptions swallowed. This is the *only* per-frame cursor motion call in the 16 ms loop (`p000/s60.java:153`).|
|37|`m2166l()` — 3897 | **Commit the IME buffer into the field** | Requires `f4097H0 != null && f4082C0`. `text = f4100I0.m5201b()` (committed text + composing inserted at caret, `p000/C0575lv.java:95–108`); `performAction(2097152 /*ACTION_SET_TEXT*/, bundle ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE=text)`. On failure retries once on a newly found editable node within **90 px** of the click point (3913–3923). On success and SDK≥33, sets the field selection to `clamp(composingLen + f9702f, 0, text.length())` via `ACTION_SET_SELECTION(131072)` (3924–3933). If both attempts fail → toast `keyboard_unsupported_field` and close the keyboard (3934–3937). Returns success.|
|38|`m2167l0()` — 3942 | **Resize the cursor window** | `size = pref_mouse_size` on display 0, else `(int)(pref_mouse_size * 0.4f)` (3945–3949); assigns `f4181r.width/height` and `updateViewLayout`.|
|39|`m2168m(int keyCode, int phase)` — 3964 | Pressed-key bookkeeping | `f4194v0` contains `keyCode`? if not → false; `phase==1` removes it; returns true. Used by mapping dispatch to suppress repeats.|
|40|`m2169m0()` — 3977 | Service flags | Toggles `AccessibilityServiceInfo.flags` bit **32 (`FLAG_REQUEST_FILTER_KEY_EVENTS`)** per `f4129T`, then `setServiceInfo`. Logs "Service flags updated. MouseEnabled: …". Called from `onServiceConnected` (4379).|
|41|`m2170n(float x, float y)` — 3994 | **Continue drag** (per-frame) | Requires a live `f4155g0` and `now >= f4157h0` (a 40 ms throttle stored at 4022). Moves only if the target moved ≥**1.0 px** in either axis (4003): `path.moveTo(last) → lineTo(new)`, `continueStroke(path, 0L, 50L, willContinue=true)` (replaces the live stroke), updates `f4153f0`, `f4182r0=now`, dispatch with displayId, then `f4157h0 = now + 40`. Exceptions log "Failed to continue drag". Called from the 16 ms loop whenever `f4147c0` is set (`p000/s60.java:155`).|
|42|`m2171n0(long ms)` — 4032 | Haptic feedback | Only when `db0.m2408b()` (Pro) is true, reads `pref_vibration_intensity` (default 255) and vibrates **every input device with source bit 1025 (gamepad/joystick)** that has a vibrator, `VibrationEffect.createOneShot(ms, intensity)` on API≥26. Per-call durations used in this range: **25 ms** (key type, 2292), **60 ms** (keyboard open, 2428), **40 ms** (lang switch, 3460), **30 ms** (sym key, t60:350), **50 ms** (system buttons 1303/1316).|
|43|`m2172o0(int dir)` — 4067 | Word-wise caret movement | `dir>0`: commit composition, then skip a run of whitespace and then a run of non-whitespace (`gd1.m3397k` = isWhitespace) moving the caret right; `dir<0`: same leftwards. Then `m2166l()` + `m2138P()`. Driven by `s60#8` for right-stick X and for the D-pad word step (`p000/t60.java:164`, `p000/s60.java:234`).|
|44|`m2173p()` — 4487 | Keyboard gravity | `pref_kb_dex_pos`: `"left"`→`8388611 (START)`, `"right"`→`8388613 (END)`, else `1 (CENTER_HORIZONTAL)`; result `\| 80 (BOTTOM)`. Default `"center"` → **81**.|
|45|`m2174q(float x, float y)` — 4501 | **Single tap gesture** | `f4182r0=now`; `path.moveTo(x,y)`; single stroke **0 → 50 ms**; `setDisplayId` on SDK≥30; `dispatchGesture(…, null, null)`. Used for click-up (`1610`), SDK<26 drag end (3258) and repeat-click (`p000/s60.java:266`).|
|46|`m2175r(float x, float y)` — 4515 | **Double tap gesture** | `path.moveTo(x,y)`; **two strokes**: `0 → 50 ms` and `150 → 200 ms` (4524–4525) → 100 ms gap; `setDisplayId`; dispatch without callback. Used for long-press alternatives at `(0.8·W, cursorY)` and `(0.2·W, cursorY)` (4660, 4823).|
|47|`m2176s()` — 4530 | Enabled languages | Ordered list: default (EN) if `f4109L0`, KO if `f4112M0`, ES if `f4115N0`; if empty, default is forced in (4543–4545).|
|48|`m2177t()` — 4550 | Validate current language | If `f4106K0` is not in `m2176s()`, set it to the first entry and clear the dead-key latch (`f4103J0.f17376a=0`, `setAccentPending(0)`).|
|49|`m2178u()` — 4578 | Build the move-tick sound | Lazy `SoundPool(maxStreams=2, usage=USAGE_MEDIA(1), contentType=CONTENT_TYPE_SONIFICATION(4))`, synthesises a 7.5 KB WAV (`m2118e`, 44.1 kHz mono 16-bit, 1180 Hz sweep with 17 ms exp decay) into `cacheDir/kb_move_tick_v1.wav`, `load(path, priority 1)`. On failure releases the pool and zeroes the sound id.|
|50|`m2117X(boolean show, boolean hideBlackoutOnDex, int mask)` — 693 | **Cursor / keyboard-mode show-hide machine** (drives W2 focus flags) | `z3 = ((mask & 2) == 0)` = "force re-apply even if the state looks unchanged"; `z2 = hideBlackoutOnDex && ((mask & 4) == 0)` (715–722). Closes keyboard when turning the cursor off (723–725); no-ops when the state is unchanged and `!z3` (727–736). Turning **on**: resize cursor (`m2164j0`), margin `max(0.8*size, 50f)` where `size = pref_mouse_size` on the phone else `size*0.4f`; if the cursor is within that margin of any edge it is **re-centred** to `(W/2, H/2)` then `m2165k0()` (737–778); `f4145b0=true`, `VISIBLE`. Turning **off**: zero stick axes (`f4099I/f4102J/f4105K/f4108L`), `f4159i0=false`, finish a pending drag (`m2152c0(cursorX,cursorY)` when `f4147c0`), `f4149d0=false`, stop repeat-click, clear the pressed set, fade `alpha→0` over **200 ms** then `n60(2)` sets `GONE` (784–803). For every focus view in `f4175p`: set/clear `FLAG_NOT_FOCUSABLE(8)` (`flags = z ? flags & ~8 : flags \| 8`), `updateViewLayout`, then `requestFocus` for the active display or `clearFocus` (815–845). While on: `m2160h0()` priming tap + 200 ms fade-in (846–857). While off: 200 ms fade-out (859–865) and hide the blackout (`m2129E`) when `z2 \|\| !pref_mouse_enabled \|\| displayId == 0` (866–868).|
|51|`m2129E()` — 2004 | Hide black screen overlay | If visible: clickable/focusable/enabled=false, unregister battery receiver, fade `alpha→0` over **200 ms** with end action that sets `visibility=GONE`; if `!f4163k0` restore `screenBrightness=-1.0f` (system) via `updateViewLayout` and reset the wakelock (release + re-acquire 3000 ms); if keyboard mode is on, fade the **cursor back in** over 200 ms (2047–2048).|
|52|`m2125A(float x, float y)` — 1098 | Nearest editable node to a point | Current display's windows, `getType()==TYPE_APPLICATION(1)`, DFS for editable nodes (`m2114F`: not password, has ACTION_SET_TEXT(2097152) or class EditText/AutoCompleteTextView/TextInputEditText, **and** `isFocused()`), chooses minimum rect-distance from `(x,y)` (1122–1180).|
|53|`m2180y(float x, float y, float r)` — 4919 | Editable node within radius | Same window walk, delegates to `m2124z(root, x, y, r)`; radius used: **24 px**, then **36 px** (`p000/o60.java:43,58`), **90 px** (commit retry, 3913).|
|54|`m2126B(int resId, Object...)` — 1183 | Localised string helper | Used for every toast text (`toast_repeat_stopped`, `keyboard_pro_required`, `lockscreen_label`, `dex_switch_pro_required`, `action_brightness_format`, `keyboard_unsupported_field`).|
|55|`m2127C(KeyEvent)` — 1250 | **Gamepad key handler while keyboard mode is on** | Per-key state machine: 108 (BUTTON_START) → `m2135L(2)` = HOME; 109 (BUTTON_SELECT) → `m2135L(3)` = RECENTS (1298–1323); face buttons (96/97, swapped when `pref_swap_ab_buttons`) → `m2132I(m9199f())` with a 400 ms first-repeat kick into `s60#2` (repeats every 110 ms) (1331–1349); B/back combos clear focus and post `n60(4)` (BACK) (1629–1651); D-pad 19/20/21/22 → `m2148a0(dx,dy,2)` with 120 ms staleness guards (1382–1398); DEL 67 → backspace with 400 ms kick into `s60#5` (1484–1499); 99/100 → `'\t'` / `' '` (1479–1483); 102 (L1) → `m2158g0()` language cycle (1401–1406); 103 (R1) → `m2149b()` but **only for the ES layout** (1407–1412); 104 (L2) → toggle `f4136W0` (sym) + `m2139Q()` + 30 ms haptic (1413–1434); 105 (R2) → `m2136M()` (Enter) with a 350 ms debounce (1435–1444); 106 (THUMBL) → toggle caps `f4138X0` + 50 ms haptic (1445–1462); 107 (THUMBR) → select-all (`ACTION_SET_SELECTION` 0…len, 131072) then close keyboard (1463–1476).|

---

## 2. Window / LayoutParams table (every `addView` and its exact args)

`TYPE 2032 = TYPE_ACCESSIBILITY_OVERLAY` for **all four** windows. Form factor `-1 = MATCH_PARENT`,
`-2 = WRAP_CONTENT`, `-3 = PixelFormat.TRANSLUCENT`, `-1` format `= PixelFormat.OPAQUE`.

### W1 — keyboard scrim + keyboard (`v60` extends `FrameLayout`, child `C1059yy` extends `LinearLayout`)
| field | value | line |
|---|---|---|
| `WindowManager.LayoutParams(-1, -1, 2032, 264, -3)` | w=MATCH_PARENT, h=MATCH_PARENT, TYPE_ACCESSIBILITY_OVERLAY, flags **264**, format TRANSLUCENT | 2404 |
| flag decode | `264 = 256 + 8 = FLAG_LAYOUT_IN_SCREEN \| FLAG_NOT_FOCUSABLE` | 2404 |
| `gravity = 80` | `Gravity.BOTTOM` | 2405 |
| scrim colour | `570425344 = 0x22000000` (13 % black) | 2392 |
| child LP (phone) | `FrameLayout.LayoutParams( (int)(displayWidth * pref_kb_dex_width/100), -2, m2173p() )` | 2393–2403 |
| child LP (external display) | `FrameLayout.LayoutParams( -1, -2, 80 )` | 2396–2403 |
| child gravity | `m2173p()` = (`START/END/CENTER_HORIZONTAL`) \| `BOTTOM` → default **81**; after `m2141S()` it may become **48 (TOP)** with horizontal preserved | 4487–4498, 2884–2892 |
| keyboard inner sizing | `m9200g(widthFrac, heightFrac, gravity)`: width frac clamped **0.2…1.0**, height factor `2*pref_kb_dex_height/100` clamped **0.8…4.0**; then `lp.width = displayWidth*widthFrac`, `lp.gravity = (keptVertical ?: givenVertical) \| givenHorizontal` | `p000/C1059yy.java:858–887` |
| add / remove | `f4169n.addView(v60Var, lp)` / `f4094G0.removeView(v60Var)` | 2407 / 3750, 3757 |
| touch behaviour | tap on the scrim outside the keyboard rect → `m2163j(true)` close | `p000/v60.java:34–51` |

### W2 — per-display focus catcher (`t60` extends `View`, one per active display)
| field | value | line |
|---|---|---|
| `WindowManager.LayoutParams(15, 15, 2032, 262432, -3)` | **15×15 px**, TYPE_ACCESSIBILITY_OVERLAY, flags **262432**, TRANSLUCENT | 3391 |
| flag decode | `262432 = 262144 + 256 + 32 = FLAG_WATCH_OUTSIDE_TOUCH \| FLAG_LAYOUT_IN_SCREEN \| FLAG_NOT_TOUCH_MODAL` | 3391 |
| extra flag | `flags \|= 8 (FLAG_NOT_FOCUSABLE)` when `!f4163k0` (keyboard mode off) | 3395–3397 |
| `gravity = 8388659` | `0x800033 = Gravity.START \| Gravity.TOP` | 3392 |
| `x = 0, y = 0` | top-left corner | 3393–3394 |
| context | `createDisplayContext(display)` → SDK≥30 `createWindowContext(2032, null)` → `getSystemService("window")` — **one WindowManager per display** | 3380–3389 |
| add / remove | `windowManager.addView(t60Var, lp)` / `removeView` on display removal, on display change, and in `onDestroy` | 3399 / 3373, 3596, 4147 |
| focus flag toggling | `FLAG_NOT_FOCUSABLE` cleared before `requestFocus` so the view can receive gamepad key/motion events; set again when cursor sleeps (`m2117X:828–840`, `1644`, `n60#8:145`) | — |
| purpose | receives `onGenericMotionEvent` (all stick processing), `onKeyDown/Up` → `m2127C`, `onTouchEvent` ACTION_OUTSIDE → sleep / reclaim | `p000/t60.java:48–514`, 517–598 |

### W3 — mouse cursor (`ImageView`)
| field | value | line |
|---|---|---|
| `WindowManager.LayoutParams(i5, i5, 2032, 792, -3)` where `i5 = f4120P` (`pref_mouse_size`, default 100) | square, TYPE_ACCESSIBILITY_OVERLAY, flags **792**, TRANSLUCENT | 3646–3647 |
| flag decode | `792 = 512 + 256 + 16 + 8 = FLAG_LAYOUT_NO_LIMITS \| FLAG_LAYOUT_IN_SCREEN \| FLAG_NOT_TOUCHABLE \| FLAG_NOT_FOCUSABLE` | 3647 |
| `gravity = 8388659` | `START \| TOP`; `x=(int)f4075A`, `y=(int)f4078B` | 3648–3650 |
| stored as | `this.f4181r` — reused by `m2165k0` (move) and `m2167l0` (resize) | 3651 |
| size on external display | `(int)(pref_mouse_size * 0.4f)` (40 %) | 3948, also 744 |
| add / remove | `f4169n.addView(f4172o, lp)` / `removeView` on display change and in `onDestroy` | 3655 / 3585, 4154 |
| initial visibility | `alpha = f4145b0 ? 1f : 0f`, `visibility = f4145b0 ? VISIBLE(0) : GONE(8)` | 3632–3643 |

### W4 — black-screen / lock replacement (`FrameLayout`, always on **display 0**)
| field | value | line |
|---|---|---|
| `WindowManager.LayoutParams(-1, -1, 2032, 6816136, -1)` | MATCH_PARENT×2, TYPE_ACCESSIBILITY_OVERLAY, flags **6816136**, format **OPAQUE** | 3705 |
| flag decode | `6816136 = 4194304 + 2097152 + 524288 + 256 + 128 + 8 = FLAG_SHOW_WHEN_LOCKED \| FLAG_DISMISS_KEYGUARD \| FLAG_SHOW_WALLPAPER \| FLAG_LAYOUT_IN_SCREEN \| FLAG_KEEP_SCREEN_ON \| FLAG_NOT_FOCUSABLE` | 3705 |
| `screenBrightness = 0.1f` | dims the panel to 10 % instead of turning it off | 3706 |
| content | vertical `LinearLayout` (gravity CENTER) with `TextClock("hh:mm a"/"HH:mm", 48 sp, #FF808080)` + battery `TextView` (18 sp, tag `"batteryView"`), plus `lockscreen_label` `TextView` (14 sp, padding-bottom 100, gravity 81) | 3676–3700 |
| bg / initial | `setBackgroundColor(-16777216)` black, `alpha 0`, `visibility GONE` | 3673–3675 |
| context | `createDisplayContext(displayManager.getDisplay(0))` + `createWindowContext(2032)` — **hard-coded display 0** | 3661–3671 |
| add / remove | `windowManager3.addView(f4178q, lp)` / `removeView` in `onDestroy` | 3708 / 4160 |
| policy | shown/hidden by `m2145Y()` / `m2129E()`; only used when the cursor is on an external display and `pref_dex_lockscreen_enabled` is on | 3718–3724 |

`updateViewLayout` sites in this range: 835 (focus views in `m2117X`), 1647 (focus views, BACK),
2031 & 3050 (blackout brightness), 3889 (cursor move `m2165k0`), 3955 (cursor resize `m2167l0`).

---

## 3. The Runnable inventory (including the two inline `run()` bodies)

### 3.1 The two anonymous `run()` methods inside `m2137N` (p60)
Both copies are byte-identical decompiler artefacts of one lambda, created at 2641 and 2716,
posted on a **main-looper `Handler` with 300 ms delay** (2673 / 2748):

```
run() {                                  // MouseAccessibilityService.java:2658 and 2733
    int which = this.f11907n;            // 0 or 1 (both identical)
    MouseAccessibilityService s = this.f11908o;
    s.m2151c(this.f11909p);              // re-search windows for the keyword list
}
```
Effect: 300 ms after clicking `창 핸들` (window handle) to expand the DeX window menu, re-scan
the current display's windows for the maximise/restore action node and click it once.

### 3.2 `n60(MouseAccessibilityService, int case)` — one-shot UI fixups
| case | body | posted from |
|---|---|---|
|0|if keyboard mode off → haptic 100 ms + `m2117X(this,true,false,6)` + `m2142U()` (show cursor)|4227 (`onKeyEvent` wake key)|
|1|Enter follow-up: re-resolve editable node; close keyboard or retarget (24 px bounds match) then `n60(9)`@120 ms|2570|
|2|`if (!f4145b0) cursorView.setVisibility(GONE)`|800|
|3|`m2141S()`|—|
|4|`m2135L(1)` (BACK) then `n60(8)`@**250 ms**|1651|
|5|Toast `dex_switch_pro_required`|1901|
|6|`m2141S()`|3456|
|7|`m2117X(this,true,false,4)`|3716|
|8|clear `FLAG_NOT_FOCUSABLE` on the active display's focus view, `updateViewLayout`, `requestFocus`|`p000/n60.java:120`|
|9|`m2141S()`|`p000/n60.java:102`|
|10|if keyboard eligible → `m2133J(node, f4116N1, f4119O1)` open keyboard, else toast `keyboard_pro_required`|`p000/o60.java:48`|
|11|`m2141S()`|**2411, delay 120 ms**|
|12|`m2141S()`|**2412, delay 600 ms**|
|13|`m2163j(false)`|`p000/t60.java:573`|
|14|`f4165l0=false`; if keyboard mode → `m2116T(focusView, displayId)` reclaim focus|`p000/t60.java:589` @65 ms|

### 3.3 `s60(MouseAccessibilityService, int case)` — repeating state machines
| case | meaning | interval | posted from |
|---|---|---|---|
|0|stop D-pad repeat if the key was released ≥120 ms ago|one-shot|3428 (`m2157g`), `p000/s60.java:43`|
|1|**keyboard caret auto-repeat**: `m2131H(f4164k1,f4166l1)` then re-post|`f4118O0` (`pref_kb_nav_interval`, default **150 ms**)|3108 (`m2148a0`), after `f4121P0` = `pref_kb_nav_delay` (default **300 ms**)|
|2|**face-button repeat**: `m2132I(keyboardView.m9199f())` re-post **110 ms**; stops on the `f17328q` pseudo key|110 ms|`p000/s60.java:84`|
|3|stop keyboard vertical (right-stick) repeat after 120 ms idle|one-shot|`p000/s60.java:92`|
|4|**keyboard right-stick scroll/nav**: `m9196c(dx,dy)` (move key focus) + `m2138P()`; interval `f4118O0`, **doubled while |stick| < 0.9**|150/300 ms|`p000/s60.java:120`|
|5|**backspace repeat**: `m2130G()` re-post 110 ms while `f4160i1`|110 ms|`p000/s60.java:129`|
|6|**the 16 ms cursor-move loop** — see §6|**16 ms** (`finally { handler.postDelayed(this,16L); }`)|4403 (`onServiceConnected` → `m2164j0` path), `p000/s60.java:210`|
|7|stop left-stick nav repeat ≥120 ms|one-shot|`p000/s60.java:215`|
|8|**left-stick word/line nav**: `m2172o0(x)` (word) or `m5205f/m5206g` (line) with `m2166l()`+`m2138P()`; interval `2*f4118O0`|300 ms|`p000/s60.java:249`|
|9|**repeat click**: re-tap the stored point `m2174q(x,y)` from `m2144W(f4190u)` every `f4193v`; auto-stops with `toast_repeat_stopped_cursor` when the cursor is hidden/keyboard open|`f4193v` = `m2140R()` clamp **100…3000** default 500|4881 / `p000/s60.java:269`|

### 3.4 Other handlers used by this range
* `q60(service,int)` → `performGlobalAction(i)`; `q60(int,service)` → brightness toast `(v*100)/255` (`p000/q60.java:26–40`, called 2489 vs 3079).
* `o60(service,x,y,case)` → keyboard eligibility probe: case 0 finds an editable node within **24 px**, on miss retries case 1 at **380 ms** with a **36 px** radius, then `n60(10)`@**310 ms** (`p000/o60.java:39–74`, called 1612 = 40 ms after a tap).
* `t60` (W2) → `onGenericMotionEvent` is the whole input front-end: deadzone `f4127S`, sensitivity exponent `f4123Q`, cursor velocity `f4099I/f4102J`, right-stick scroll vector `f4105K/f4108L`, trigger/button latching; `onTouchEvent` handles ACTION_OUTSIDE (sleep after 1500 ms of no successful action, 300 ms debounce) and direct touch (sleep).
* `u60` (DisplayListener) → `onDisplayAdded`: `f4205z=false` (clear forced-off) + `m2155e0()` + `m2162i0()`; `onDisplayChanged`: if `id==0 && state==STATE_OFF(1)` and the cursor is *not* on display 0 and `pref_dex_lockscreen_enabled` → `m2145Y()` show blackout, then always `m2155e0()`+`m2162i0()`; `onDisplayRemoved`: `m2155e0()`+`m2162i0()` (`p000/u60.java:20–56`).
* `w60` (GestureResultCallback of the scroll gesture) → on completed/cancelled just `f4159i0=false` (`p000/w60.java:20–29`).
* `y60` (TakeScreenshotCallback) → `m2128D` or `performGlobalAction(9)` (`p000/y60.java`).
* `v60` (W1 scrim) → tap outside keyboard closes it (`p000/v60.java:34`).
* `C0360g(2, this)` → key-tap callback that calls `m2132I(key)` (`p000/C0360g.java`, case 2).
* `RunnableC0698p6(this,6,msg)` → toast (3064); `RunnableC0591ma(view,1)` → `view.requestFocus()` (689); `ViewOnClickListenerC0853td(5,this)` → blackout tap-to-dismiss (3703).

---

## 4. Display / DeX handling

### 4.1 Discovery
* `DisplayManager f4196w` obtained in `onServiceConnected` (`getSystemService("display")`), listener
  `u60` registered on the main handler (4380–4386).
* There is **no** use of `Display.FLAG_PRESENTATION`, `Display.FLAG_EXTRA_BUILT_IN_DISPLAY`,
  `DisplayManager.createVirtualDisplay`, or any `Settings.Global` display override anywhere in
  this class (verified by full-file search). Everything is `getDisplays()` / `getDisplay(id)`
  plus the app's own preference.
* "**Force mirroring**" is *not* an OS mirroring call: `pref_force_mirroring` → `f4090F` (4299)
  is only used to **disable external-display selection**, so the app behaves as if the
  external display did not exist:
  * `m2155e0` predicate: `z = isPro() && !f4090F`; a display is "usable" only if
    `state==STATE_ON && (id==0 || z)` (3332–3342, 3379).
  * `m2162i0` chooses an external display only if `isPro() && !f4090F` (3531).

### 4.2 Which display does the cursor live on? (`m2162i0`, 3519–3724)
```
displays = displayManager.getDisplays()                     // 3529-3530
ext = null
if (isPro() && !pref_force_mirroring)                        // 3531
    ext = first d in displays where d.id != 0 && d.state == STATE_ON(2)   // 3532-3538
display = (ext != null && !f4205z) ? ext : displayManager.getDisplay(0)   // 3541-3548
```
* `f4205z` = "external display forced off" — set false by `onDisplayAdded` (`p000/u60.java:23`).
* The winner becomes `f4199x`; its **real** metrics (`getRealMetrics`) become `f4081C × f4084D`.
* Old cursor coordinates: **re-centred** when the displayId changed (`(w/2, h/2)`, 3619–3620),
  otherwise clamped into the new bounds (`lo0.m5052h(pos, 0, w/h)`, 3622–3623).
* Display change also forces: keyboard close (`m2163j(false)`, 3575–3577), repeat-click stop with
  toast `toast_repeat_stopped_cursor` (3578–3581), cursor view removal + `f4172o=null` (3582–3589),
  **all** focus views removed from `f4175p` (3590–3600), then rebuild `f4199x`, `f4202y`
  (`createDisplayContext`), `f4169n` (`createWindowContext(2032)` on SDK≥30, 3601–3615),
  `m2155e0()` focus views (3625), cursor window (3626) and blackout window (3661).

### 4.3 Per-display window creation
* Overlay **windows are created per display** by re-deriving a `Context` and a `WindowManager`
  from that `Display`: `createDisplayContext(display)` then — on SDK≥30 —
  `.createWindowContext(TYPE_ACCESSIBILITY_OVERLAY=2032, null)`; then `getSystemService("window")`.
  Occurrences: 3380–3389 (focus views), 3602–3615 (cursor), 3662–3671 (blackout).
  The keyboard always uses the *current* display's WM (`f4169n`, 2407).
* Focus catchers: **one per `STATE_ON` display** (including display 0), keyed by displayId in
  `f4175p`; stale ones are removed when the display turns off/disappears (3343–3377).
* Cursor + keyboard + blackout: **exactly one instance each**, living on the chosen display
  (blackout is always display 0 by construction, 3661–3662).
* Display-derived scale factors: cursor window **×0.4** on external (3948), scroll sweep
  **×0.5** on external (2454), `m2117X` edge margin uses `pref_mouse_size*0.4f` (744),
  keyboard `C1059yy` gets `external = (displayId != 0)` which switches its layout mode
  (`f19483o`) and enables the fractional width/height path (`m9200g` early-returns when
  `f19483o == false`, i.e. on the phone, `p000/C1059yy.java:860–862`).

### 4.4 Add / remove / change reactions
`u60` (see §3.4) is the single entry point: any display event → `m2155e0()` (reconcile focus
windows) + `m2162i0()` (reconcile cursor/keyboard/blackout and re-pick the display). Display-0
`STATE_OFF` while the cursor is on an external display triggers the lock-screen blackout
`m2145Y()` (DeX "turn off the phone screen" feature) — enabled by `pref_dex_lockscreen_enabled`
(`f4131U`).

---

## 5. Cursor rendering, sizing, animation, hide timeout

* **Widget**: plain `ImageView`, no custom view class (3631). Created once per display session.
* **Image source**, in priority order (`m2164j0`, 3798):
  1. `pref_cursor_style == "custom"` → `filesDir/custom_cursor.png`, decoded with
     `inJustDecodeBounds` + `inSampleSize` doubling until both dimensions ≥512, then scaled so
     max edge ≤ **512 px** (`m2121o`, 949–981). Missing/0-byte → reset pref to `orange`, delete file.
  2. `"custom_color"` → `Color.parseColor("#"+pref_cursor_color)` → `m2153d(color)` vector render
     (12-vertex arrow in a **240×240** ARGB_8888 bitmap, fill = colour, 3.5 px outline white or
     `#1A1A1A` chosen by luminance ≥128, 3262–3308).
  3. preset colour name (from the 10-entry map `f4101I1`, 572) → converted to `custom_color` and
     persisted (3803–3814).
  4. otherwise `R.drawable.ic_mouse_cursor` (3868, fallback 3874).
* **Size**: window size = `pref_mouse_size` px square on the phone, `×0.4` on EXTERNAL
  (`m2167l0`, 3942–3961; initial creation copies `f4120P` at 3646–3647). Because the window is
  exactly the bitmap's logical size, the bitmap is stretched by the window (no Bitmap scaling).
* **Alpha / visibility**: shown = `alpha 1`, hidden = `alpha 0` + `visibility GONE`.
  Fade **200 ms** in (`851`, `2047`), fade **200 ms** out then `visibility=GONE` (`800`, `862`);
  fade **500 ms** out when the blackout overlay appears on the phone (`3055`).
* **Position**: window `x/y` = `(int)f4075A/(int)f4078B` (`m2165k0`, 3881–3894), gravity START|TOP.
* **Idle / hide timeout**: `f4133V = pref_mouse_timeout` seconds (4311). The 16 ms loop
  (`p000/s60.java:188`) hides the cursor when *no movement and no button activity* for
  `f4133V*1000` ms since `f4143a0` (stamped by `m2142U` on every input) →
  `m2117X(this,false,false,6)`. `f4133V == 0` disables the timeout (default 0,
  seekbar max 56 s).
* **Edge recovery**: when re-shown, if the cursor sits within `max(0.8*size, 50f)` px of any edge
  it is re-centred to `(W/2, H/2)` (`m2117X`, 746–778).
* **Initial values** before first metrics: cursor `(500, 1000)` (485–488), display `1080×2400`
  (491–494), size `100` px (506).

---

## 6. Gesture dispatch reference (every `dispatchGesture` reachable from this range)

All gestures are `GestureDescription` with one or two `StrokeDescription`s; `setDisplayId` is
applied **only on SDK≥30**, always from `f4199x.getDisplayId()`.

| Gesture | Path | Strokes (start, duration) | willContinue | Callback | Line |
|---|---|---|---|---|---|
| click / tap | `moveTo(x,y)` | `(0, 50)` | false | none | 4501–4511 (`m2174q`) |
| double tap | `moveTo(x,y)` | `(0, 50)` + `(150, 50)` | false | none | 4515–4526 (`m2175r`) |
| drag start | `moveTo(x,y)` | `(0, 50)` | **true** | none | 3158–3179 (`m2150b0`) |
| drag continue | `moveTo(last) → lineTo(new)` | `(0, 50)` | **true** | none | 3994–4022 (`m2170n`) |
| drag end | `moveTo(last) → lineTo(new)` | `(0, 50)` | **false** | none | 3227–3250 (`m2152c0`) |
| **discrete scroll** | `moveTo(cx, H/2) → lineTo(cx - dx*sweep, H/2 - dy*sweep)` | `(0, **150**)` | false | `f4161j0` (w60) | 2442–2471 (`m2134K`) |
| priming/wake tap | `(0,200)` on display 0; `(W/2,5)` on external | `(0, 50)` | false | none | 3486–3503 (`m2160h0`) |
| DeX title-bar tap | `(W/2, 30)` | `(0, 50)` | false | none | 2757–2766 |

`StrokeDescription(path, startTimeMs, durationMs)` is the only constructor used; the drag-start
helper always passes `willContinue=true` (`p000/AbstractC0185c0.java`).

---

## 7. Scroll implementation, speed mapping, and the `vertical`/`horizontal` gate

**There is no scrollbar / no `MotionEvent` scroll wheel path.** Scrolling is emulated with a
single straight **swipe stroke** whose length is proportional to the right stick's deflection:

```
sweep = pref_scroll_speed / 50.0f  *  180.0f  *  displayFactor   // 2456
displayFactor = 1.0f (display 0) | 0.5f (external/DeX)           // 2450-2455
path: (cursorX, H/2) -> (cursorX - dx*sweep, H/2 - dy*sweep)     // 2450-2459, duration 150ms
```
* `pref_scroll_speed` default **100** → `f4125R = 2.0f` → `sweep = 360 px` on the phone,
  **180 px** on DeX. Seekbar range 0…400 (`res/layout/activity_main.xml:514`), so sweep is
  `0…1440 px` phone / `0…720 px` DeX. `(dx,dy)` is a **unit vector** (magnitude 1) built from the
  right stick in `p000/t60.java:449–452` (`f4105K = ax/hypot`, `f4108L = ay/hypot`), so only the
  *direction* matters and `sweep` is the full travel per gesture.
* Only one scroll gesture may be in flight: `f4159i0` is set before dispatch (2447) and cleared
  either by the `w60` callback (completed/cancelled) or by the exception path.
* Trigger site: the 16 ms loop, `p000/s60.java:177–185`:
  ```
  if (keyboardMode && mouseEnabled && !dragActive) {
      f = f4105K;                                        // stick X
      if (f == 0.0f || f4108L != 0.0f) {                 // i.e. NOT (x!=0 && y==0)
          if (!f4159i0) m2134K(f, f4108L);
          m2142U();                                      // keep-alive
      }
  }
  ```
  Consequence (quirk): a **purely horizontal** deflection (`x≠0, y==0`) does **not** scroll;
  pure vertical and any diagonal do.
* The stick vector is only non-zero when `hypot(ax,ay) > f4127S` (`pref_deadzone`, default
  `15/100 = 0.15`, `p000/t60.java:449–452`, 4324).
* A separate, *keyboard-mode* scroll/nav path exists: with the keyboard open, the **right stick**
  moves the selected key via `C1059yy.m9196c(dx,dy)` (column ↔ row with column-memory) and the
  **left stick** moves the text caret by word (`m2172o0`) or line (`m5205f/m5206g`)
  (`p000/t60.java:108–181`, `p000/s60.java:218–254`).

---

## 8. Preference-field map (everything this range consumes)

Loaded in `onServiceConnected` 4293–4377 (line = read site), consumed where listed.

| Pref key | Field (default) | Effect in this range |
|---|---|---|
| `pref_mouse_enabled` | `f4129T` (true) | master gate for `m2142U`, `m2117X`, move loop, service key-event flag (`m2169m0`) |
| `pref_force_mirroring` | `f4090F` (false) | disables external-display selection in `m2162i0`/`m2155e0` |
| `pref_dex_lockscreen_enabled` | `f4131U` (false) | enables blackout (`m2145Y`) on DeX |
| `pref_mouse_speed` | `f4114N` (50) | cursor px per frame on display 0 (`p000/s60.java:144`) → `Δx = ax*speed` |
| `pref_dex_speed` | `f4117O` (35) | cursor px per frame on external display (`p000/s60.java:146`) |
| `pref_mouse_size` | `f4120P` (100) | cursor window size; `×0.4` external; edge-margin base `m2117X` |
| `pref_mouse_sensitivity` | `f4123Q` (20 → `/10 = 2.0`) | exponent blend `pow(curve,2.5)*((k-1)/2*0.9) + (1-…)` on stick magnitude (`p000/t60.java:458–462`) |
| `pref_mouse_timeout` | `f4133V` (0 s) | auto-hide cursor after N s idle (`p000/s60.java:188`) |
| `pref_scroll_speed` | `f4125R` (100 → `/50 = 2.0`) | scroll sweep = `f4125R*180*displayFactor` (2456) |
| `pref_deadzone` | `f4127S` (15 → `0.15`) | stick deadzone for cursor + scroll (`p000/t60.java:450`, `472`) |
| `pref_cursor_style` / `pref_cursor_color` | `f4135W`=`"orange"`, `f4137X`=`"#FFA000"` | cursor bitmap selection / tint (`m2164j0`, `m2153d`) |
| `pref_keyboard_enabled` | `f4085D0` (true) | gates keyboard open from a tap (`1608–1613`, `p000/o60.java:42`) |
| `pref_kb_lang_en/ko/es` | `f4109L0`/`f4112M0`/`f4115N0` | language list `m2176s()` |
| `pref_kb_nav_interval` | `f4118O0` (150, UI `p*10+50` → 50…500) | caret/key repeat period (`m2148a0`, `s60#1/#4/#8`) |
| `pref_kb_nav_delay` | `f4121P0` (300, UI `p*50+200` → 200…1500) | initial delay before caret repeat (3108) |
| `pref_kb_move_sound` | `f4124Q0` (false) | enables `m2138P` tick |
| `pref_kb_dex_width` / `_height` / `_pos` | `f4126R0`=50, `f4128S0`=100, `f4130T0`="center" | keyboard geometry `m9200g(f/100, f/100, m2173p())` (2390) and window width (2394) |
| `pref_haptic_feedback` | inline `getBoolean(...,true)` | gates `m2171n0` calls (2291, 2427, 3459, 4259, …) |
| `pref_vibration_intensity` | inline (255) | amplitude in `m2171n0` (4038) |
| `pref_toggle_keycode` | `f4170n0` (106) | wake/long-press key (`onKeyEvent`, 4204) |
| `pref_l3_toggle_enabled`, `pref_l3_long_press_duration` | `f4167m0` (true), `f4176p0` (0 → `*100` ms) | L3 long-press → show/hide cursor (`4219–4237`) |
| `pref_swap_ab_buttons` | `f4173o0` (false) | face-button A/B swap (`1591–1605`, `1325–1331`) |
| `pref_mapping_x_<key>_interval` / `_value` | per-key | repeat-click interval `m2140R` (clamp 100–3000, default 500) and stored point `m2144W` |

---

## 9. Timing constants and magic numbers (with line numbers)

| Value | Meaning | Line(s) |
|---|---|---|
| **16 ms** | cursor-move loop period (60 fps); `postDelayed` in `finally` | `p000/s60.java:210` |
| **50 ms** | every `StrokeDescription` duration (tap, drag start/continue/end, priming tap, title-bar tap) | 4501–4526, 3158, 3994, 3227, 3486, 2757 |
| **150 ms** | discrete-scroll stroke duration | 2466 |
| **100 ms** gap | between the two strokes of the double tap (0–50, 150–200) | 4525 |
| **120 ms** | `n60(11)` keyboard reposition pass 1; `n60(6)` after language switch; D-pad/left-stick/repeat staleness threshold | 2411, 3456, `p000/s60.java:43,59,91,213` |
| **600 ms** | `n60(12)` keyboard reposition pass 2 | 2412 |
| **250 ms** | `n60(1)` after Enter (IME-followup), long-press→drag threshold in the key handler | 2570, 1622 |
| **500 ms** | stationary long-press → drag conversion in the move loop | `p000/s60.java:162` |
| **300 ms** | inline `p60` retry after clicking the window handle; default `pref_kb_nav_delay`; touch debounce before sleeping | 2673, 2748, 557, `p000/t60.java:577` |
| **80 ms** | delay between priming tap and `performGlobalAction` | 2489 |
| **40 ms** | drag-continue throttle (`f4157h0 = now+40`) | 4022 |
| **40 ms** | delay before the keyboard-eligibility probe `o60(0)` | 1612 |
| **310 / 380 / 24 / 36** | keyboard probe: `n60(10)` delay, retry delay, first radius (px), second radius (px) | `p000/o60.java:48,51,43,58` |
| **90 px** | fallback radius for `ACTION_SET_TEXT` retry | 3913 |
| **110 ms** | face-button repeat, backspace repeat | `p000/s60.java:84,129` |
| **140 ms** | kick into right-stick nav repeat | `p000/t60.java:131` |
| **65 ms** | focus reclaim delay after focus loss | `p000/t60.java:589` |
| **1000 ms** | `mode==2` (D-pad) caret repeat stop after last key-up | `p000/s60.java:64` |
| **1500 ms** | "focus lost to external touch → sleep" grace period | `p000/t60.java:578` |
| **500 ms** | direct-touch sleep guard; brightness-toast rate limit | `p000/t60.java:592`, 3078 |
| **3000 ms** | wakelock acquire duration (blackout) | 3025, 2042 |
| **200 ms** | cursor fade in/out | 800, 851, 862, 2020, 2047 |
| **500 ms** | blackout fade in / cursor fade during blackout | 3053, 3055 |
| **0.1f** | blackout `screenBrightness` | 3046, 3706 |
| **570425344** | keyboard scrim colour `0x22000000` | 2392 |
| **240 × 240** | cursor bitmap render canvas | 3289 |
| **3.5f** | cursor outline stroke width | 3300 |
| **128.0f** | luminance threshold selecting white vs `#1A1A1A` outline | 3284 |
| **512** | max edge for custom cursor PNG decode | 957–969 |
| **100** | default cursor window size (`pref_mouse_size`) | 506, 4306 |
| **180.0f** | scroll sweep base factor | 2456 |
| **0.5f** | external-display scroll factor | 2454 |
| **0.4f** | cursor size factor on external display | 744, 3948 |
| **0.8f / 50.0f** | edge-recovery margin `max(0.8*size, 50)` | 746 |
| **0.9f** | right-stick magnitude below which nav repeat interval doubles | `p000/s60.java:117` |
| **0.2f / 0.35f / 0.5f / 0.25f** | keyboard-mode stick thresholds (deadzone slack 0.2, min 0.35, axis trigger 0.5, idle 0.25) | `p000/t60.java:91–97,120–121` |
| **2.5d / 0.9f** | cursor acceleration curve exponent and blend factor | `p000/t60.java:460` |
| **1.0f** | minimum drag step before continuing the stroke | 4003 |
| **0.15f** | default deadzone (`pref_deadzone` 15/100) | 515, 4324 |
| **35 / 50** | default cursor speeds (DeX / phone) | 4303, 4301 |
| **150 / 300** | default nav interval / delay ms | 556, 557 |
| **100 / 3000** | `m2140R` clamp for repeat-click interval | 2832 |
| **24 px** | node-bounds tolerance for "same field" after Enter | `p000/n60.java:72` |
| **30.0f** | y of the DeX title-bar fallback tap | 2759 |
| **200.0f / 5.0f** | priming-tap y on phone / external | 3493, 3495 |
| **805306368** | `Intent` flags `FLAG_ACTIVITY_NEW_TASK\|FLAG_ACTIVITY_CLEAR_TASK` | 2223 |
| **2032** | `TYPE_ACCESSIBILITY_OVERLAY` for all four windows | 2404, 3391, 3647, 3705 |
| **262432 / 792 / 264 / 6816136** | see §2 flag decodes | 3391, 3647, 2404, 3705 |

---

## 10. Pseudocode — cursor move + click + drag + scroll state machine

Compact reconstruction of `p000/t60.java` (input) + `p000/s60.java` case 6 (16 ms loop) +
`MouseAccessibilityService` gesture helpers. State: `cursor{x,y}`, `shown`, `pressed`, `drag`,
`stroke`, `scrollBusy`.

```
// ---------- input front-end: t60.onGenericMotionEvent (source & 1025 or 16777232) ----------
stickL = (AXIS_X, AXIS_Y); stickR = (AXIS_Z|AXIS_RZ merged, AXIS_RX|AXIS_RY merged)
if keyboardMode:                     // stick drives the on-screen keyboard, not the cursor
    navigateKeyFocus(stickR); textCaretRepeat(stickL)      // C1059yy.m9196c / m2131H
    return
hyp   = hypot(stickL)
if hyp > deadzone(f4127S=0.15):                          // t60:449
    curve = pow((hyp-dz)/(1-dz), 2.5)
    k     = sensitivity/1f        // pref_mouse_sensitivity/10, default 2.0
    mag   = curve*((k-1)/2*0.9) + (1-((k-1)/2*0.9))*((hyp-dz)/(1-dz))
    vel   = (stickL/hyp) * mag                            // f4099I, f4102J  (unit * 0..1)
else vel = (0,0)
hypR = hypot(stickR)
if hypR > deadzone: scrollVec = stickR/hypR                // f4105K,f4108L
else                scrollVec = (0,0)

// ---------- 16 ms loop: s60 case 6 (p000/s60.java:133-211) ----------
every16ms:
  try {
    if (keyboardMode && mouseEnabled && (vel != 0)):
        speed = (displayId == 0) ? pref_mouse_speed(50) : pref_dex_speed(35)
        cursor += vel * speed                             // px per frame at 60 fps
        cursor = clamp(cursor, 0..W, 0..H)                 // lo0.m5052h
        moveCursorWindow(cursor)                           // m2165k0, updateViewLayout
        if drag:  continueDrag(cursor)                     // m2170n, 50ms stroke, willContinue
        elif pressed: pressed=false; drag=true; startDrag(cursor)   // m2150b0
        markActivity()                                     // m2142U
        if pressed && !drag && now-pressTs > 500:          // stationary long press
            pressed=false; drag=true; startDrag(cursor)    // + 40 ms haptic (null check inverted by jadx)
        if !drag && scrollVec != 0 && !(scrollVec.x!=0 && scrollVec.y==0):
            if !scrollBusy:                                // f4159i0
                scrollBusy = true
                dispatch(swipe(cursorX, H/2) -> (cursorX-dx*sweep, H/2-dy*sweep),
                         duration=150ms, displayId, cb=w60)   // m2134K
            markActivity()
    else if timeoutSec > 0 && now-lastActivity > timeoutSec*1000 && !keyboardOpen:
        hideCursor()                                       // m2117X(...,false,...,6)
  } finally { post(this, 16) }                             // always re-arm

// ---------- buttons (service onKeyEvent / t60.onKeyDown, gamepad source only) ----------
onButtonDown(BTN_A/click):
    if !drag && !pressed: pressed=true; pressTs=now         // 1619-1621
    if pressed && now-pressTs > 250: pressed=false; drag=true; startDrag(cursor)  // 1622-1625
onButtonUp(BTN_A/click):
    if pressed: pressed=false
        tap(cursor)                                        // m2174q: stroke 0..50ms
        if keyboardEnabled && !keyboardOpen: post(o60(cursor), 40ms)  // open keyboard probe
    elif drag: drag=false; endDrag(cursor)                 // m2152c0: continueStroke(...,false)
onButtonDown(START=108): focusDisplay(); primeTap(); post(performGlobalAction(HOME=2), 80ms)
onButtonDown(SELECT=109): focusDisplay(); primeTap(); post(performGlobalAction(RECENTS=3), 80ms)
onButtonDown(RT with keyboardMode): windowMaximize(true)   // m2137N(true)
onButtonDown(LT with keyboardMode): windowMaximize(false)  // m2137N(false)
on RT/LT axis > 0.5 (mapping enabled): executeMappedAction("rt"/"lt")  // p000/t60.java:414,435

// ---------- scroll gesture completion ----------
w60.onCompleted / onCancelled: scrollBusy = false          // p000/w60.java
```

---

## 11. Notes, quirks, and residual uncertainty

1. **`m2134K` is scroll, not a cursor move.** Despite sitting in the `m213x` cursor-block, its only
   in-service caller is the 16 ms move loop (`p000/s60.java:181`). No other method in the file
   calls it, and no `onScroll`/wheel path exists in the service.
2. **Scroll starts at the vertical screen centre, not at the cursor**: `moveTo(f4075A, f4084D/2)`
   (2448–2458). Only X of the cursor is used. This matters when reimplementing: the swipe is
   vertical-centred so it does not start "inside" the cursor overlay window.
3. **`q60` selector ambiguity.** In the trimmed dump `q60` shows `f12518n = 1` as a field
   initialiser with two synthetic constructors; taken literally, `new q60(this, action)` (2489)
   would hit the *brightness toast* branch while `new q60(brightness, this)` (3079) shows the
   toast. The three `m2135L` call sites (1/2/3) and their logs ("Performing HOME action",
   "Performing RECENTS action", BACK after `n60(4)`) are only consistent with
   `performGlobalAction(action)`. Treat `m2135L(i)` as `GLOBAL_ACTION` ids.
4. **`m2155e0` focus windows are 15×15 px at (0,0)** with `FLAG_WATCH_OUTSIDE_TOUCH` — they are
   invisible focus/key sinks, and their tiny size is what makes `ACTION_OUTSIDE` fire for touches
   anywhere else on that display (`p000/t60.java:549`).
5. **`FLAG_NOT_FOCUSABLE` polarity is inverted between the two paths**: in `m2155e0` the flag is
   set when the keyboard is **off** (3395–3397), while `m2117X` sets it when the cursor is
   **off** (828–833). Both mean "focus only while the feature is active".
6. `m2142U()` deliberately *does not* hide the blackout when the cursor lives on an external
   display (2913) — that is how the phone screen stays dark while DeX is in use.
7. `m2136M`'s multiline branch inserts a literal `'\n'` instead of pressing IME enter (2505–2516),
   and `n60(1)` decides "field changed → keep keyboard" by comparing the new bounds with the
   snapshot taken *before* the action (24 px tolerance, `p000/n60.java:72`).
8. `m2137N` on the phone only implements *restore* (as BACK); *maximize* on the phone is a no-op
   (2768–2769).
9. `m2166l` throttles nothing — every keystroke rewrites the entire field text through
   `ACTION_SET_TEXT` (2097152) and re-places the selection on SDK≥33 (3924–3933), with a 90 px
   re-target fallback and a hard "unsupported field" failure that closes the keyboard.
10. In the 16 ms loop the decompiled `s60` case 6 has duplicated fallback blocks
    (`p000/s60.java:191–208` repeats 162–177); that is a decompiler artefact of the `finally`
    re-post, not two separate behaviours.
11. `m2117X`'s call convention is `(show, hideBlackoutOnDex, mask)`; `mask & 2` clears the
    "force re-apply" flag `z3` and `mask & 4` clears the `z2` blackout-hide override (715–722).
    In-range call sites: `(true,false,6)` wake key, `(false,false,6)` idle timeout,
    `(false,true,2)` direct touch on the focus view, `(true,false,4)` `n60#7`.
