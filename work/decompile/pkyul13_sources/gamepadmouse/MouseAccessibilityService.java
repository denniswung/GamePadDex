package com.pkyul13.gamepadmouse;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.accessibilityservice.GestureDescription;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorSpace;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.hardware.HardwareBuffer;
import android.hardware.display.DisplayManager;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.SoundPool;
import android.media.ToneGenerator;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.provider.MediaStore;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.SparseArray;
import android.view.Display;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewPropertyAnimator;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextClock;
import android.widget.TextView;
import androidx.work.impl.WorkManagerImpl;
import com.google.android.gms.ads.RequestConfiguration;
import com.pkyul13.gamepadmouse.MouseAccessibilityService;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import p000.AbstractC0185c0;
import p000.AbstractC0449ie;
import p000.AbstractC0484je;
import p000.AbstractC0521ke;
import p000.AbstractC0783rh;
import p000.AbstractC0815sc;
import p000.C0245cx;
import p000.C0360g;
import p000.C0419hl;
import p000.C0455il;
import p000.C0575lv;
import p000.C0911uy;
import p000.C0950w;
import p000.C1059yy;
import p000.EnumC0948vy;
import p000.EnumC0985wy;
import p000.RunnableC0151b2;
import p000.RunnableC0591ma;
import p000.RunnableC0698p6;
import p000.ViewOnClickListenerC0853td;
import p000.db0;
import p000.dk0;
import p000.ek0;
import p000.gd1;
import p000.h20;
import p000.hg1;
import p000.j20;
import p000.lh0;
import p000.lo0;
import p000.ma0;
import p000.n60;
import p000.o60;
import p000.q60;
import p000.r60;
import p000.s60;
import p000.t60;
import p000.tq1;
import p000.u60;
import p000.v60;
import p000.w60;
import p000.x20;
import p000.x60;
import p000.xl3;
import p000.y60;

/* compiled from: r8-map-id-8c60900aeda595a73b778d06a0c2b0d30b6fd2caefbddc6926c14247c48afd52 */
/* loaded from: classes.dex */
public final class MouseAccessibilityService extends AccessibilityService {

    /* renamed from: Q1 */
    public static final /* synthetic */ int f4074Q1 = 0;

    /* renamed from: A0 */
    public boolean f4076A0;

    /* renamed from: A1 */
    public final s60 f4077A1;

    /* renamed from: B0 */
    public long f4079B0;

    /* renamed from: B1 */
    public final s60 f4080B1;

    /* renamed from: C0 */
    public boolean f4082C0;

    /* renamed from: C1 */
    public final s60 f4083C1;

    /* renamed from: D0 */
    public boolean f4085D0;

    /* renamed from: D1 */
    public final s60 f4086D1;

    /* renamed from: E */
    public boolean f4087E;

    /* renamed from: E0 */
    public C1059yy f4088E0;

    /* renamed from: E1 */
    public final s60 f4089E1;

    /* renamed from: F */
    public boolean f4090F;

    /* renamed from: F0 */
    public v60 f4091F0;

    /* renamed from: F1 */
    public final r60 f4092F1;

    /* renamed from: G */
    public final r60 f4093G;

    /* renamed from: G0 */
    public WindowManager f4094G0;

    /* renamed from: G1 */
    public final u60 f4095G1;

    /* renamed from: H0 */
    public AccessibilityNodeInfo f4097H0;

    /* renamed from: H1 */
    public final j20 f4098H1;

    /* renamed from: I */
    public float f4099I;

    /* renamed from: I0 */
    public final C0575lv f4100I0;

    /* renamed from: I1 */
    public final Map f4101I1;

    /* renamed from: J */
    public float f4102J;

    /* renamed from: J0 */
    public final C0950w f4103J0;

    /* renamed from: J1 */
    public final ExecutorService f4104J1;

    /* renamed from: K */
    public float f4105K;

    /* renamed from: K0 */
    public EnumC0985wy f4106K0;

    /* renamed from: K1 */
    public final s60 f4107K1;

    /* renamed from: L */
    public float f4108L;

    /* renamed from: L0 */
    public boolean f4109L0;

    /* renamed from: L1 */
    public final s60 f4110L1;

    /* renamed from: M */
    public SharedPreferences f4111M;

    /* renamed from: M0 */
    public boolean f4112M0;

    /* renamed from: M1 */
    public AccessibilityNodeInfo f4113M1;

    /* renamed from: N0 */
    public boolean f4115N0;

    /* renamed from: N1 */
    public float f4116N1;

    /* renamed from: O0 */
    public long f4118O0;

    /* renamed from: O1 */
    public float f4119O1;

    /* renamed from: P0 */
    public long f4121P0;

    /* renamed from: P1 */
    public Rect f4122P1;

    /* renamed from: Q0 */
    public boolean f4124Q0;

    /* renamed from: R0 */
    public int f4126R0;

    /* renamed from: S0 */
    public int f4128S0;

    /* renamed from: T0 */
    public String f4130T0;

    /* renamed from: U */
    public boolean f4131U;

    /* renamed from: U0 */
    public ToneGenerator f4132U0;

    /* renamed from: V */
    public int f4133V;

    /* renamed from: V0 */
    public boolean f4134V0;

    /* renamed from: W0 */
    public boolean f4136W0;

    /* renamed from: X0 */
    public boolean f4138X0;

    /* renamed from: Y */
    public Bitmap f4139Y;

    /* renamed from: Y0 */
    public long f4140Y0;

    /* renamed from: Z */
    public String f4141Z;

    /* renamed from: Z0 */
    public float f4142Z0;

    /* renamed from: a1 */
    public float f4144a1;

    /* renamed from: b0 */
    public boolean f4145b0;

    /* renamed from: b1 */
    public long f4146b1;

    /* renamed from: c0 */
    public boolean f4147c0;

    /* renamed from: c1 */
    public int f4148c1;

    /* renamed from: d0 */
    public boolean f4149d0;

    /* renamed from: d1 */
    public int f4150d1;

    /* renamed from: e0 */
    public long f4151e0;

    /* renamed from: e1 */
    public int f4152e1;

    /* renamed from: f1 */
    public long f4154f1;

    /* renamed from: g0 */
    public GestureDescription.StrokeDescription f4155g0;

    /* renamed from: g1 */
    public boolean f4156g1;

    /* renamed from: h0 */
    public long f4157h0;

    /* renamed from: h1 */
    public float f4158h1;

    /* renamed from: i0 */
    public boolean f4159i0;

    /* renamed from: i1 */
    public boolean f4160i1;

    /* renamed from: j0 */
    public final w60 f4161j0;

    /* renamed from: j1 */
    public boolean f4162j1;

    /* renamed from: k0 */
    public boolean f4163k0;

    /* renamed from: k1 */
    public int f4164k1;

    /* renamed from: l0 */
    public boolean f4165l0;

    /* renamed from: l1 */
    public int f4166l1;

    /* renamed from: m0 */
    public boolean f4167m0;

    /* renamed from: m1 */
    public int f4168m1;

    /* renamed from: n */
    public WindowManager f4169n;

    /* renamed from: n0 */
    public int f4170n0;

    /* renamed from: n1 */
    public boolean f4171n1;

    /* renamed from: o */
    public ImageView f4172o;

    /* renamed from: o0 */
    public boolean f4173o0;

    /* renamed from: o1 */
    public long f4174o1;

    /* renamed from: p0 */
    public int f4176p0;

    /* renamed from: p1 */
    public long f4177p1;

    /* renamed from: q */
    public FrameLayout f4178q;

    /* renamed from: q0 */
    public boolean f4179q0;

    /* renamed from: q1 */
    public long f4180q1;

    /* renamed from: r */
    public WindowManager.LayoutParams f4181r;

    /* renamed from: r0 */
    public long f4182r0;

    /* renamed from: r1 */
    public int f4183r1;

    /* renamed from: s */
    public PowerManager.WakeLock f4184s;

    /* renamed from: s0 */
    public final Handler f4185s0;

    /* renamed from: s1 */
    public int f4186s1;

    /* renamed from: t */
    public long f4187t;

    /* renamed from: t0 */
    public final n60 f4188t0;

    /* renamed from: t1 */
    public boolean f4189t1;

    /* renamed from: u */
    public String f4190u;

    /* renamed from: u0 */
    public boolean f4191u0;

    /* renamed from: u1 */
    public long f4192u1;

    /* renamed from: v0 */
    public final HashSet f4194v0;

    /* renamed from: v1 */
    public SoundPool f4195v1;

    /* renamed from: w */
    public DisplayManager f4196w;

    /* renamed from: w0 */
    public boolean f4197w0;

    /* renamed from: w1 */
    public int f4198w1;

    /* renamed from: x */
    public Display f4199x;

    /* renamed from: x0 */
    public boolean f4200x0;

    /* renamed from: x1 */
    public final s60 f4201x1;

    /* renamed from: y */
    public Context f4202y;

    /* renamed from: y0 */
    public float f4203y0;

    /* renamed from: y1 */
    public final s60 f4204y1;

    /* renamed from: z */
    public boolean f4205z;

    /* renamed from: z0 */
    public float f4206z0;

    /* renamed from: z1 */
    public final s60 f4207z1;

    /* renamed from: p */
    public final LinkedHashMap f4175p = new LinkedHashMap();

    /* renamed from: v */
    public long f4193v = 500;

    /* renamed from: A */
    public float f4075A = 500.0f;

    /* renamed from: B */
    public float f4078B = 1000.0f;

    /* renamed from: C */
    public int f4081C = 1080;

    /* renamed from: D */
    public int f4084D = 2400;

    /* renamed from: H */
    public final Handler f4096H = new Handler(Looper.getMainLooper());

    /* renamed from: N */
    public float f4114N = 50.0f;

    /* renamed from: O */
    public float f4117O = 30.0f;

    /* renamed from: P */
    public int f4120P = 100;

    /* renamed from: Q */
    public float f4123Q = 1.5f;

    /* renamed from: R */
    public float f4125R = 2.0f;

    /* renamed from: S */
    public float f4127S = 0.15f;

    /* renamed from: T */
    public boolean f4129T = true;

    /* renamed from: W */
    public String f4135W = "orange";

    /* renamed from: X */
    public String f4137X = "#FFA000";

    /* renamed from: a0 */
    public long f4143a0 = System.currentTimeMillis();

    /* renamed from: f0 */
    public final float[] f4153f0 = new float[2];

    /* JADX WARN: Type inference failed for: r6v9, types: [w, java.lang.Object] */
    public MouseAccessibilityService() {
        w60 w60Var;
        int i = 0;
        this.f4093G = new r60(this, i);
        int i2 = 1;
        int i3 = 2;
        if (Build.VERSION.SDK_INT >= 26) {
            w60Var = new w60(this);
        } else {
            w60Var = null;
        }
        this.f4161j0 = w60Var;
        this.f4167m0 = true;
        this.f4170n0 = 106;
        this.f4185s0 = new Handler(Looper.getMainLooper());
        this.f4188t0 = new n60(this, 0);
        this.f4194v0 = new HashSet();
        this.f4085D0 = true;
        this.f4100I0 = new C0575lv();
        this.f4103J0 = new Object();
        this.f4106K0 = EnumC0985wy.f17925n;
        this.f4109L0 = true;
        this.f4112M0 = true;
        this.f4118O0 = 150L;
        this.f4121P0 = 300L;
        this.f4126R0 = 50;
        this.f4128S0 = 100;
        this.f4130T0 = "center";
        this.f4201x1 = new s60(this, 4);
        this.f4204y1 = new s60(this, 3);
        this.f4207z1 = new s60(this, i2);
        this.f4077A1 = new s60(this, i);
        this.f4080B1 = new s60(this, 8);
        this.f4083C1 = new s60(this, 7);
        this.f4086D1 = new s60(this, 5);
        this.f4089E1 = new s60(this, i3);
        this.f4092F1 = new r60(this, i2);
        this.f4095G1 = new u60(this);
        this.f4098H1 = new j20(this, i2);
        this.f4101I1 = x20.m8738Z(new ma0("orange", "#FFA000"), new ma0("blue", "#2196F3"), new ma0("green", "#4CAF50"), new ma0("red", "#F44336"), new ma0("black", "#212121"), new ma0("white", "#FFFFFF"), new ma0("purple", "#9C27B0"), new ma0("cyan", "#00BCD4"), new ma0("pink", "#E91E63"), new ma0("yellow", "#FFEB3B"));
        this.f4104J1 = Executors.newSingleThreadExecutor();
        this.f4107K1 = new s60(this, 6);
        this.f4110L1 = new s60(this, 9);
    }

    /* renamed from: F */
    public static boolean m2114F(AccessibilityNodeInfo accessibilityNodeInfo) {
        String str;
        try {
            if (accessibilityNodeInfo.isPassword()) {
                return false;
            }
            try {
                List<AccessibilityNodeInfo.AccessibilityAction> actionList = accessibilityNodeInfo.getActionList();
                if (actionList != null) {
                    List<AccessibilityNodeInfo.AccessibilityAction> list = actionList;
                    if (!(list instanceof Collection) || !list.isEmpty()) {
                        Iterator<T> it = list.iterator();
                        while (it.hasNext()) {
                            if (((AccessibilityNodeInfo.AccessibilityAction) it.next()).getId() == 2097152) {
                                return true;
                            }
                        }
                    }
                }
            } catch (Exception unused) {
            }
            CharSequence className = accessibilityNodeInfo.getClassName();
            if (className == null || (str = className.toString()) == null) {
                str = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
            }
            if (!ek0.m2909S(str, "EditText") && !ek0.m2909S(str, "AutoCompleteTextView")) {
                if (!ek0.m2909S(str, "TextInputEditText")) {
                    return false;
                }
            }
            return true;
        } catch (Exception unused2) {
            return false;
        }
    }

    /* JADX WARN: Can't wrap try/catch for region: R(14:1|(1:40)|5|(3:34|35|(10:37|8|(2:10|11)|14|15|(1:17)|19|(1:29)|30|31))|7|8|(0)|14|15|(0)|19|(1:29)|30|31) */
    /* JADX WARN: Removed duplicated region for block: B:10:0x0027 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Removed duplicated region for block: B:17:0x0031 A[Catch: Exception -> 0x0035, TRY_LEAVE, TryCatch #1 {Exception -> 0x0035, blocks: (B:15:0x002b, B:17:0x0031), top: B:14:0x002b }] */
    /* renamed from: O */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public static String m2115O(AccessibilityNodeInfo accessibilityNodeInfo) {
        String str;
        CharSequence hintText;
        String obj;
        CharSequence contentDescription;
        CharSequence text = accessibilityNodeInfo.getText();
        String str2 = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
        if (text == null || (str = text.toString()) == null) {
            str = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
        }
        String str3 = null;
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                hintText = accessibilityNodeInfo.getHintText();
            } catch (Exception unused) {
            }
            if (hintText != null) {
                obj = hintText.toString();
                boolean z = false;
                if (Build.VERSION.SDK_INT >= 31) {
                    try {
                        z = accessibilityNodeInfo.isShowingHintText();
                    } catch (Exception unused2) {
                    }
                }
                contentDescription = accessibilityNodeInfo.getContentDescription();
                if (contentDescription != null) {
                    str3 = contentDescription.toString();
                }
                if (str.length() != 0 && !z && ((obj == null || !xl3.m8871b(ek0.m2915Y(str).toString(), ek0.m2915Y(obj).toString())) && (obj != null || str3 == null || !xl3.m8871b(ek0.m2915Y(str).toString(), ek0.m2915Y(str3).toString())))) {
                    str2 = str;
                }
                StringBuilder m6827q = AbstractC0783rh.m6827q("Keyboard seed: text='", str, "' hint='", obj, "' showingHint=");
                m6827q.append(z);
                m6827q.append(" cd='");
                m6827q.append(str3);
                m6827q.append("' -> seed='");
                m6827q.append(str2);
                m6827q.append("'");
                Log.i("MouseService", m6827q.toString());
                return str2;
            }
        }
        obj = null;
        boolean z2 = false;
        if (Build.VERSION.SDK_INT >= 31) {
        }
        contentDescription = accessibilityNodeInfo.getContentDescription();
        if (contentDescription != null) {
        }
        if (str.length() != 0) {
            str2 = str;
        }
        StringBuilder m6827q2 = AbstractC0783rh.m6827q("Keyboard seed: text='", str, "' hint='", obj, "' showingHint=");
        m6827q2.append(z2);
        m6827q2.append(" cd='");
        m6827q2.append(str3);
        m6827q2.append("' -> seed='");
        m6827q2.append(str2);
        m6827q2.append("'");
        Log.i("MouseService", m6827q2.toString());
        return str2;
    }

    /* renamed from: T */
    public static void m2116T(View view, int i) {
        Log.d("MouseService", "Requesting focus for display: " + i);
        view.post(new RunnableC0591ma(view, 1));
    }

    /* renamed from: X */
    public static void m2117X(MouseAccessibilityService mouseAccessibilityService, boolean z, boolean z2, int i) {
        boolean z3;
        ViewPropertyAnimator animate;
        ViewPropertyAnimator alpha;
        ViewPropertyAnimator duration;
        ViewPropertyAnimator withEndAction;
        Display display;
        ViewPropertyAnimator animate2;
        ViewPropertyAnimator alpha2;
        ViewPropertyAnimator duration2;
        ViewPropertyAnimator animate3;
        ViewPropertyAnimator alpha3;
        ViewPropertyAnimator duration3;
        WindowManager.LayoutParams layoutParams;
        Display display2;
        float f;
        float f2;
        boolean z4;
        boolean z5;
        boolean z6;
        boolean z7;
        Display display3;
        if ((i & 2) != 0) {
            z3 = false;
        } else {
            z3 = true;
        }
        if ((i & 4) != 0) {
            z2 = false;
        }
        if (!z && mouseAccessibilityService.f4082C0) {
            mouseAccessibilityService.m2163j(false);
        }
        if (!z || mouseAccessibilityService.f4129T) {
            if (!z3 && mouseAccessibilityService.f4163k0 == z) {
                if (!z) {
                    if (z2 || !mouseAccessibilityService.f4129T || ((display3 = mouseAccessibilityService.f4199x) != null && display3.getDisplayId() == 0)) {
                        mouseAccessibilityService.m2129E();
                        return;
                    }
                    return;
                }
                return;
            }
            mouseAccessibilityService.f4163k0 = z;
            if (z) {
                mouseAccessibilityService.m2164j0();
                Display display4 = mouseAccessibilityService.f4199x;
                if (display4 != null && display4.getDisplayId() == 0) {
                    f2 = mouseAccessibilityService.f4120P;
                } else {
                    f2 = mouseAccessibilityService.f4120P * 0.4f;
                }
                float max = Math.max(0.8f * f2, 50.0f);
                float f3 = mouseAccessibilityService.f4075A;
                if (f3 <= max) {
                    z4 = true;
                } else {
                    z4 = false;
                }
                float f4 = f3 + f2;
                float f5 = mouseAccessibilityService.f4081C;
                if (f4 >= f5 - max) {
                    z5 = true;
                } else {
                    z5 = false;
                }
                float f6 = mouseAccessibilityService.f4078B;
                if (f6 <= max) {
                    z6 = true;
                } else {
                    z6 = false;
                }
                float f7 = f6 + f2;
                float f8 = mouseAccessibilityService.f4084D;
                if (f7 >= f8 - max) {
                    z7 = true;
                } else {
                    z7 = false;
                }
                if (z4 || z5 || z6 || z7) {
                    mouseAccessibilityService.f4075A = f5 / 2.0f;
                    mouseAccessibilityService.f4078B = f8 / 2.0f;
                    mouseAccessibilityService.m2165k0();
                    Log.i("MouseService", "Cursor was near edge (" + mouseAccessibilityService.f4075A + ", " + mouseAccessibilityService.f4078B + "). Centered to (" + mouseAccessibilityService.f4081C + "/2, " + mouseAccessibilityService.f4084D + "/2).");
                }
                mouseAccessibilityService.f4145b0 = true;
                ImageView imageView = mouseAccessibilityService.f4172o;
                if (imageView != null) {
                    imageView.setVisibility(0);
                }
            } else {
                mouseAccessibilityService.f4099I = 0.0f;
                mouseAccessibilityService.f4102J = 0.0f;
                mouseAccessibilityService.f4105K = 0.0f;
                mouseAccessibilityService.f4108L = 0.0f;
                mouseAccessibilityService.f4159i0 = false;
                if (mouseAccessibilityService.f4147c0) {
                    mouseAccessibilityService.m2152c0(mouseAccessibilityService.f4075A, mouseAccessibilityService.f4078B);
                    mouseAccessibilityService.f4147c0 = false;
                }
                mouseAccessibilityService.f4149d0 = false;
                mouseAccessibilityService.m2154d0(Integer.valueOf(R.string.toast_repeat_stopped_cursor));
                mouseAccessibilityService.f4194v0.clear();
                if (mouseAccessibilityService.f4145b0) {
                    mouseAccessibilityService.f4145b0 = false;
                    ImageView imageView2 = mouseAccessibilityService.f4172o;
                    if (imageView2 != null && (animate = imageView2.animate()) != null && (alpha = animate.alpha(0.0f)) != null && (duration = alpha.setDuration(200L)) != null && (withEndAction = duration.withEndAction(new n60(mouseAccessibilityService, 2))) != null) {
                        withEndAction.start();
                    }
                }
            }
            ImageView imageView3 = mouseAccessibilityService.f4172o;
            if (imageView3 != null) {
                if (mouseAccessibilityService.f4145b0) {
                    f = 1.0f;
                } else {
                    f = 0.0f;
                }
                imageView3.setAlpha(f);
            }
            Log.i("MouseService", "setGamepadFocus: " + z);
            for (Map.Entry entry : mouseAccessibilityService.f4175p.entrySet()) {
                int intValue = ((Number) entry.getKey()).intValue();
                View view = (View) entry.getValue();
                Object systemService = view.getContext().getSystemService("window");
                systemService.getClass();
                WindowManager windowManager = (WindowManager) systemService;
                ViewGroup.LayoutParams layoutParams2 = view.getLayoutParams();
                if (layoutParams2 instanceof WindowManager.LayoutParams) {
                    layoutParams = (WindowManager.LayoutParams) layoutParams2;
                } else {
                    layoutParams = null;
                }
                if (layoutParams != null) {
                    int i2 = layoutParams.flags;
                    if (z) {
                        layoutParams.flags = i2 & (-9);
                    } else {
                        layoutParams.flags = i2 | 8;
                    }
                    try {
                        windowManager.updateViewLayout(view, layoutParams);
                        if (z && (display2 = mouseAccessibilityService.f4199x) != null && intValue == display2.getDisplayId()) {
                            m2116T(view, intValue);
                        } else {
                            view.clearFocus();
                        }
                    } catch (Exception e) {
                        Log.e("MouseService", "Failed to update focus view for display " + intValue + ": " + e.getMessage());
                    }
                }
            }
            if (z) {
                mouseAccessibilityService.m2160h0();
                if (!mouseAccessibilityService.f4145b0) {
                    mouseAccessibilityService.f4145b0 = true;
                    ImageView imageView4 = mouseAccessibilityService.f4172o;
                    if (imageView4 != null && (animate3 = imageView4.animate()) != null && (alpha3 = animate3.alpha(1.0f)) != null && (duration3 = alpha3.setDuration(200L)) != null) {
                        duration3.start();
                        return;
                    }
                    return;
                }
                return;
            }
            if (mouseAccessibilityService.f4145b0) {
                mouseAccessibilityService.f4145b0 = false;
                ImageView imageView5 = mouseAccessibilityService.f4172o;
                if (imageView5 != null && (animate2 = imageView5.animate()) != null && (alpha2 = animate2.alpha(0.0f)) != null && (duration2 = alpha2.setDuration(200L)) != null) {
                    duration2.start();
                }
            }
            if (z2 || !mouseAccessibilityService.f4129T || ((display = mouseAccessibilityService.f4199x) != null && display.getDisplayId() == 0)) {
                mouseAccessibilityService.m2129E();
            }
        }
    }

    /* renamed from: e */
    public static byte[] m2118e() {
        double exp;
        byte[] bArr = new byte[7496];
        double d = 0.0d;
        for (int i = 0; i < 3748; i++) {
            double d2 = i / 44100.0d;
            double d3 = 1.0d;
            d += ((1180.0d - ((1.0d - Math.exp((-d2) / 0.005d)) * 260.0d)) * 6.283185307179586d) / 44100.0d;
            if (d2 < 0.003d) {
                exp = d2 / 0.003d;
            } else {
                exp = Math.exp((-(d2 - 0.003d)) / 0.017d);
            }
            double sin = ((Math.sin(2.0d * d) * 0.32d) + Math.sin(d)) * 0.5d * exp;
            if (sin < -1.0d) {
                d3 = -1.0d;
            } else if (sin <= 1.0d) {
                d3 = sin;
            }
            int i2 = (int) (d3 * 32767.0d);
            int i3 = i * 2;
            bArr[i3] = (byte) (i2 & 255);
            bArr[i3 + 1] = (byte) ((i2 >> 8) & 255);
        }
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream(7540);
        Charset charset = AbstractC0815sc.f13968a;
        byte[] bytes = "RIFF".getBytes(charset);
        bytes.getClass();
        byteArrayOutputStream.write(bytes);
        m2119f(byteArrayOutputStream, 7532);
        byte[] bytes2 = "WAVEfmt ".getBytes(charset);
        bytes2.getClass();
        byteArrayOutputStream.write(bytes2);
        m2119f(byteArrayOutputStream, 16);
        byteArrayOutputStream.write(new byte[]{1, 0});
        byteArrayOutputStream.write(new byte[]{1, 0});
        m2119f(byteArrayOutputStream, 44100);
        m2119f(byteArrayOutputStream, 88200);
        byteArrayOutputStream.write(new byte[]{2, 0});
        byteArrayOutputStream.write(new byte[]{16, 0});
        byte[] bytes3 = "data".getBytes(charset);
        bytes3.getClass();
        byteArrayOutputStream.write(bytes3);
        m2119f(byteArrayOutputStream, 7496);
        byteArrayOutputStream.write(bArr);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        byteArray.getClass();
        return byteArray;
    }

    /* renamed from: f */
    public static final void m2119f(ByteArrayOutputStream byteArrayOutputStream, int i) {
        byteArrayOutputStream.write(new byte[]{(byte) i, (byte) (i >> 8), (byte) (i >> 16), 0});
    }

    /* renamed from: k */
    public static void m2120k(AccessibilityNodeInfo accessibilityNodeInfo, ArrayList arrayList) {
        int childCount = accessibilityNodeInfo.getChildCount();
        for (int i = 0; i < childCount; i++) {
            AccessibilityNodeInfo child = accessibilityNodeInfo.getChild(i);
            if (child != null) {
                m2120k(child, arrayList);
                if (!arrayList.contains(child)) {
                    try {
                        child.recycle();
                    } catch (Exception unused) {
                    }
                }
            }
        }
        if (m2114F(accessibilityNodeInfo) && accessibilityNodeInfo.isFocused()) {
            arrayList.add(accessibilityNodeInfo);
        }
    }

    /* renamed from: o */
    public static Bitmap m2121o(File file) {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(file.getAbsolutePath(), options);
        if (options.outWidth > 0 && options.outHeight > 0) {
            int i = 1;
            while (true) {
                int i2 = i * 2;
                if (options.outWidth / i2 < 512 || options.outHeight / i2 < 512) {
                    break;
                }
                i = i2;
            }
            BitmapFactory.Options options2 = new BitmapFactory.Options();
            options2.inSampleSize = i;
            Bitmap decodeFile = BitmapFactory.decodeFile(file.getAbsolutePath(), options2);
            if (decodeFile != null) {
                int max = Math.max(decodeFile.getWidth(), decodeFile.getHeight());
                if (max > 512) {
                    float f = 512.0f / max;
                    Bitmap createScaledBitmap = Bitmap.createScaledBitmap(decodeFile, Math.max(1, (int) (decodeFile.getWidth() * f)), Math.max(1, (int) (decodeFile.getHeight() * f)), true);
                    createScaledBitmap.getClass();
                    if (createScaledBitmap != decodeFile) {
                        decodeFile.recycle();
                    }
                    return createScaledBitmap;
                }
                return decodeFile;
            }
            return null;
        }
        return null;
    }

    /* renamed from: w */
    public static AccessibilityNodeInfo m2122w(AccessibilityNodeInfo accessibilityNodeInfo, String str) {
        String str2;
        String str3;
        if (accessibilityNodeInfo != null) {
            CharSequence contentDescription = accessibilityNodeInfo.getContentDescription();
            if (contentDescription != null) {
                str2 = contentDescription.toString();
            } else {
                str2 = null;
            }
            CharSequence text = accessibilityNodeInfo.getText();
            if (text != null) {
                str3 = text.toString();
            } else {
                str3 = null;
            }
            if (accessibilityNodeInfo.isClickable() && ((str2 != null && ek0.m2910T(str2, str, true)) || (str3 != null && ek0.m2910T(str3, str, true)))) {
                return accessibilityNodeInfo;
            }
            int childCount = accessibilityNodeInfo.getChildCount();
            for (int i = 0; i < childCount; i++) {
                AccessibilityNodeInfo child = accessibilityNodeInfo.getChild(i);
                AccessibilityNodeInfo m2122w = m2122w(child, str);
                if (m2122w != null) {
                    return m2122w;
                }
                if (child != null) {
                    child.recycle();
                }
            }
        }
        return null;
    }

    /* renamed from: x */
    public static AccessibilityNodeInfo m2123x(AccessibilityNodeInfo accessibilityNodeInfo, List list) {
        String str;
        String obj;
        if (accessibilityNodeInfo != null) {
            CharSequence contentDescription = accessibilityNodeInfo.getContentDescription();
            if (contentDescription != null && (obj = contentDescription.toString()) != null) {
                str = obj.toLowerCase(Locale.ROOT);
                str.getClass();
            } else {
                str = null;
            }
            if (str != null) {
                List list2 = list;
                if (!(list2 instanceof Collection) || !list2.isEmpty()) {
                    Iterator it = list2.iterator();
                    while (true) {
                        if (!it.hasNext()) {
                            break;
                        }
                        if (ek0.m2909S(str, (String) it.next())) {
                            AccessibilityNodeInfo obtain = AccessibilityNodeInfo.obtain(accessibilityNodeInfo);
                            while (obtain != null) {
                                if (obtain.isClickable()) {
                                    return obtain;
                                }
                                AccessibilityNodeInfo parent = obtain.getParent();
                                obtain.recycle();
                                obtain = parent;
                            }
                        }
                    }
                }
            }
            int childCount = accessibilityNodeInfo.getChildCount();
            for (int i = 0; i < childCount; i++) {
                AccessibilityNodeInfo child = accessibilityNodeInfo.getChild(i);
                AccessibilityNodeInfo m2123x = m2123x(child, list);
                if (child != null) {
                    child.recycle();
                }
                if (m2123x != null) {
                    return m2123x;
                }
            }
        }
        return null;
    }

    /* renamed from: z */
    public static AccessibilityNodeInfo m2124z(AccessibilityNodeInfo accessibilityNodeInfo, float f, float f2, float f3) {
        if (accessibilityNodeInfo != null) {
            int childCount = accessibilityNodeInfo.getChildCount();
            for (int i = 0; i < childCount; i++) {
                AccessibilityNodeInfo child = accessibilityNodeInfo.getChild(i);
                AccessibilityNodeInfo m2124z = m2124z(child, f, f2, f3);
                if (m2124z != null) {
                    return m2124z;
                }
                if (child != null) {
                    child.recycle();
                }
            }
            if (m2114F(accessibilityNodeInfo)) {
                try {
                    accessibilityNodeInfo.getBoundsInScreen(new Rect());
                    if (f >= r0.left - f3 && f <= r0.right + f3 && f2 >= r0.top - f3 && f2 <= r0.bottom + f3) {
                        return accessibilityNodeInfo;
                    }
                    return null;
                } catch (Exception unused) {
                    return null;
                }
            }
            return null;
        }
        return null;
    }

    /* renamed from: A */
    public final AccessibilityNodeInfo m2125A(float f, float f2) {
        int i;
        AccessibilityNodeInfo root;
        float f3;
        SparseArray windowsOnAllDisplays;
        Display display = this.f4199x;
        if (display != null) {
            i = display.getDisplayId();
        } else {
            i = 0;
        }
        ArrayList arrayList = new ArrayList();
        if (Build.VERSION.SDK_INT >= 30) {
            windowsOnAllDisplays = getWindowsOnAllDisplays();
            List list = (List) windowsOnAllDisplays.get(i);
            if (list != null) {
                arrayList.addAll(list);
            }
        } else {
            List<AccessibilityWindowInfo> windows = getWindows();
            if (windows != null) {
                arrayList.addAll(windows);
            }
        }
        int size = arrayList.size();
        AccessibilityNodeInfo accessibilityNodeInfo = null;
        float f4 = Float.MAX_VALUE;
        for (int i2 = 0; i2 < size; i2++) {
            AccessibilityWindowInfo accessibilityWindowInfo = (AccessibilityWindowInfo) arrayList.get(i2);
            if (accessibilityWindowInfo.getType() == 1 && (root = accessibilityWindowInfo.getRoot()) != null) {
                ArrayList arrayList2 = new ArrayList();
                m2120k(root, arrayList2);
                Iterator it = arrayList2.iterator();
                it.getClass();
                while (it.hasNext()) {
                    Object next = it.next();
                    next.getClass();
                    AccessibilityNodeInfo accessibilityNodeInfo2 = (AccessibilityNodeInfo) next;
                    Rect rect = new Rect();
                    try {
                        accessibilityNodeInfo2.getBoundsInScreen(rect);
                        float f5 = rect.left;
                        float f6 = 0.0f;
                        if (f < f5) {
                            f3 = f5 - f;
                        } else {
                            float f7 = rect.right;
                            if (f > f7) {
                                f3 = f - f7;
                            } else {
                                f3 = 0.0f;
                            }
                        }
                        float f8 = rect.top;
                        if (f2 < f8) {
                            f6 = f8 - f2;
                        } else {
                            float f9 = rect.bottom;
                            if (f2 > f9) {
                                f6 = f2 - f9;
                            }
                        }
                        float hypot = (float) Math.hypot(f3, f6);
                        if (hypot <= 700.0f && hypot < f4) {
                            if (accessibilityNodeInfo != null) {
                                try {
                                    accessibilityNodeInfo.recycle();
                                } catch (Exception unused) {
                                }
                            }
                            accessibilityNodeInfo = accessibilityNodeInfo2;
                            f4 = hypot;
                        } else {
                            accessibilityNodeInfo2.recycle();
                        }
                    } catch (Exception unused2) {
                    }
                }
                root.recycle();
            }
        }
        return accessibilityNodeInfo;
    }

    /* renamed from: B */
    public final String m2126B(int i, Object... objArr) {
        SharedPreferences sharedPreferences = getSharedPreferences("GamepadMousePrefs", 0);
        String language = Locale.getDefault().getLanguage();
        if (!xl3.m8871b(language, "ko") && !xl3.m8871b(language, "es")) {
            language = "en";
        }
        String string = sharedPreferences.getString("pref_language", language);
        if (string != null) {
            language = string;
        }
        Locale forLanguageTag = Locale.forLanguageTag(language);
        Configuration configuration = new Configuration(getResources().getConfiguration());
        configuration.setLocale(forLanguageTag);
        Context createConfigurationContext = createConfigurationContext(configuration);
        if (objArr.length == 0) {
            String string2 = createConfigurationContext.getString(i);
            string2.getClass();
            return string2;
        }
        String string3 = createConfigurationContext.getString(i, Arrays.copyOf(objArr, objArr.length));
        string3.getClass();
        return string3;
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    /* JADX WARN: Code restructure failed: missing block: B:290:0x03c2, code lost:
    
        if (r19.f4163k0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:320:0x0484, code lost:
    
        if (r19.f4163k0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:341:0x04be, code lost:
    
        if (r19.f4163k0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:464:0x062d, code lost:
    
        if (r19.f4191u0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:46:0x0085, code lost:
    
        r8 = false;
     */
    /* JADX WARN: Code restructure failed: missing block: B:479:0x0650, code lost:
    
        if (r19.f4191u0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:513:0x06c4, code lost:
    
        if (r19.f4163k0 != false) goto L583;
     */
    /* JADX WARN: Code restructure failed: missing block: B:552:0x0435, code lost:
    
        if (r19.f4163k0 != false) goto L583;
     */
    /* JADX WARN: Failed to find 'out' block for switch in B:298:0x0447. Please report as an issue. */
    /* JADX WARN: Failed to find 'out' block for switch in B:299:0x044a. Please report as an issue. */
    /* JADX WARN: Removed duplicated region for block: B:272:0x0346 A[ADDED_TO_REGION] */
    /* JADX WARN: Removed duplicated region for block: B:276:0x0356  */
    /* JADX WARN: Removed duplicated region for block: B:525:0x03ca  */
    /* JADX WARN: Removed duplicated region for block: B:554:0x034f A[ADDED_TO_REGION] */
    /* renamed from: C */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public final boolean m2127C(KeyEvent keyEvent) {
        boolean z;
        boolean z2;
        boolean z3;
        int i;
        boolean z4;
        boolean z5;
        WindowManager.LayoutParams layoutParams;
        boolean z6;
        int i2;
        boolean z7;
        boolean z8;
        int i3;
        boolean z9;
        int i4;
        boolean z10;
        int i5;
        boolean z11;
        int i6;
        boolean z12;
        boolean z13;
        boolean z14;
        boolean z15;
        boolean z16;
        boolean z17;
        int i7;
        AccessibilityNodeInfo accessibilityNodeInfo;
        if (keyEvent.getKeyCode() == 4) {
            return false;
        }
        boolean z18 = this.f4163k0;
        Handler handler = this.f4096H;
        C0911uy c0911uy = null;
        if (z18 && this.f4082C0) {
            int keyCode = keyEvent.getKeyCode();
            int action = keyEvent.getAction();
            if (action == 0 && keyEvent.getRepeatCount() == 0) {
                z15 = true;
            } else {
                z15 = false;
            }
            if (keyCode == 4) {
                if (action == 0) {
                    m2163j(true);
                    return true;
                }
            } else {
                m2142U();
                if (keyCode == 108) {
                    if (action == 0) {
                        SharedPreferences sharedPreferences = this.f4111M;
                        if (sharedPreferences != null) {
                            if (sharedPreferences.getBoolean("pref_haptic_feedback", true)) {
                                m2171n0(50L);
                            }
                            m2135L(2);
                            return true;
                        }
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                } else if (keyCode == 109) {
                    if (action == 0) {
                        SharedPreferences sharedPreferences2 = this.f4111M;
                        if (sharedPreferences2 != null) {
                            if (sharedPreferences2.getBoolean("pref_haptic_feedback", true)) {
                                m2171n0(50L);
                            }
                            m2135L(3);
                            return true;
                        }
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                } else {
                    boolean z19 = (z16 = this.f4173o0) ? true : true;
                    if (!z16 ? !(keyCode == 97 || keyCode == 97) : !(keyCode == 96 || keyCode == 96)) {
                        z17 = false;
                    } else {
                        z17 = true;
                    }
                    if (z19) {
                        s60 s60Var = this.f4089E1;
                        if (z15) {
                            if (!this.f4162j1) {
                                this.f4162j1 = true;
                                C1059yy c1059yy = this.f4088E0;
                                if (c1059yy != null) {
                                    c0911uy = c1059yy.m9199f();
                                }
                                m2132I(c0911uy);
                                handler.removeCallbacks(s60Var);
                                handler.postDelayed(s60Var, 400L);
                                return true;
                            }
                        } else if (action == 1) {
                            this.f4162j1 = false;
                            handler.removeCallbacks(s60Var);
                            return true;
                        }
                    } else if (z17) {
                        if (action == 0) {
                            m2163j(true);
                            return true;
                        }
                    } else if (keyCode != 67) {
                        if (keyCode != 110) {
                            if (keyCode != 99) {
                                C0575lv c0575lv = this.f4100I0;
                                if (keyCode != 100) {
                                    switch (keyCode) {
                                        case 19:
                                        case 20:
                                        case hg1.zzm /* 21 */:
                                        case WorkManagerImpl.MAX_PRE_JOB_SCHEDULER_API_LEVEL /* 22 */:
                                            int i8 = -1;
                                            if (keyCode != 21) {
                                                if (keyCode != 22) {
                                                    i7 = 0;
                                                } else {
                                                    i7 = 1;
                                                }
                                            } else {
                                                i7 = -1;
                                            }
                                            if (keyCode != 19) {
                                                if (keyCode != 20) {
                                                    i8 = 0;
                                                } else {
                                                    i8 = 1;
                                                }
                                            }
                                            long currentTimeMillis = System.currentTimeMillis();
                                            if (action != 0) {
                                                if (action == 1) {
                                                    this.f4180q1 = currentTimeMillis;
                                                    if (this.f4168m1 == 2 && i7 == this.f4164k1 && i8 == this.f4166l1) {
                                                        m2157g();
                                                        return true;
                                                    }
                                                }
                                            } else {
                                                this.f4180q1 = currentTimeMillis;
                                                if (currentTimeMillis - this.f4177p1 > 120 && currentTimeMillis - this.f4146b1 > 120 && (i7 != this.f4164k1 || i8 != this.f4166l1 || !this.f4171n1)) {
                                                    m2148a0(i7, i8, 2);
                                                    return true;
                                                }
                                            }
                                            break;
                                        default:
                                            switch (keyCode) {
                                                case 102:
                                                    if (z15) {
                                                        m2158g0();
                                                        return true;
                                                    }
                                                    break;
                                                case 103:
                                                    if (z15 && this.f4106K0 == EnumC0985wy.f17927p) {
                                                        m2149b();
                                                        return true;
                                                    }
                                                    break;
                                                case 104:
                                                    if (action != 0) {
                                                        if (action == 1 && this.f4136W0) {
                                                            this.f4136W0 = false;
                                                            m2139Q();
                                                            return true;
                                                        }
                                                    } else if (keyEvent.getRepeatCount() == 0 && !this.f4136W0) {
                                                        this.f4136W0 = true;
                                                        m2139Q();
                                                        SharedPreferences sharedPreferences3 = this.f4111M;
                                                        if (sharedPreferences3 != null) {
                                                            if (sharedPreferences3.getBoolean("pref_haptic_feedback", true)) {
                                                                m2171n0(30L);
                                                                return true;
                                                            }
                                                        } else {
                                                            xl3.m8890u("sharedPrefs");
                                                            throw null;
                                                        }
                                                    }
                                                    break;
                                                case 105:
                                                    if (z15) {
                                                        long currentTimeMillis2 = System.currentTimeMillis();
                                                        if (currentTimeMillis2 - this.f4140Y0 >= 350) {
                                                            this.f4140Y0 = currentTimeMillis2;
                                                            m2136M();
                                                            return true;
                                                        }
                                                    }
                                                    break;
                                                case 106:
                                                    if (z15) {
                                                        if (this.f4082C0) {
                                                            this.f4138X0 = !this.f4138X0;
                                                            m2139Q();
                                                        }
                                                        SharedPreferences sharedPreferences4 = this.f4111M;
                                                        if (sharedPreferences4 != null) {
                                                            if (sharedPreferences4.getBoolean("pref_haptic_feedback", true)) {
                                                                m2171n0(50L);
                                                                return true;
                                                            }
                                                        } else {
                                                            xl3.m8890u("sharedPrefs");
                                                            throw null;
                                                        }
                                                    }
                                                    break;
                                                case 107:
                                                    if (z15 && m2166l() && (accessibilityNodeInfo = this.f4097H0) != null) {
                                                        try {
                                                            Bundle bundle = new Bundle();
                                                            bundle.putInt("ACTION_ARGUMENT_SELECTION_START_INT", 0);
                                                            bundle.putInt("ACTION_ARGUMENT_SELECTION_END_INT", c0575lv.m5201b().length());
                                                            accessibilityNodeInfo.performAction(131072, bundle);
                                                            m2138P();
                                                        } catch (Exception unused) {
                                                        }
                                                        m2163j(true);
                                                        break;
                                                    }
                                                    break;
                                            }
                                    }
                                } else if (z15 && this.f4082C0) {
                                    c0575lv.m5202c(' ');
                                    m2166l();
                                    return true;
                                }
                            } else {
                                s60 s60Var2 = this.f4086D1;
                                if (z15) {
                                    if (!this.f4160i1) {
                                        this.f4160i1 = true;
                                        m2130G();
                                        handler.removeCallbacks(s60Var2);
                                        handler.postDelayed(s60Var2, 400L);
                                        return true;
                                    }
                                } else if (action == 1) {
                                    this.f4160i1 = false;
                                    handler.removeCallbacks(s60Var2);
                                    return true;
                                }
                            }
                        } else if (action == 0) {
                            m2163j(false);
                            m2117X(this, false, false, 6);
                            return true;
                        }
                    } else if (action == 0) {
                        m2130G();
                        return true;
                    }
                }
            }
        } else {
            if (keyEvent.getKeyCode() == this.f4170n0) {
                z = true;
            } else {
                z = false;
            }
            if (keyEvent.getKeyCode() == 106) {
                z2 = true;
            } else {
                z2 = false;
            }
            if (keyEvent.getKeyCode() == 110) {
                z3 = true;
            } else {
                z3 = false;
            }
            if (keyEvent.getAction() == 0 && keyEvent.getRepeatCount() == 0) {
                if (!this.f4163k0) {
                    if ((z && this.f4167m0) || z3) {
                        SharedPreferences sharedPreferences5 = this.f4111M;
                        if (sharedPreferences5 != null) {
                            if (sharedPreferences5.getBoolean("pref_haptic_feedback", true)) {
                                m2171n0(50L);
                            }
                            m2117X(this, true, false, 6);
                            m2142U();
                            return true;
                        }
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                } else if ((z2 && this.f4167m0) || z3) {
                    SharedPreferences sharedPreferences6 = this.f4111M;
                    if (sharedPreferences6 != null) {
                        if (sharedPreferences6.getBoolean("pref_haptic_feedback", true)) {
                            m2171n0(50L);
                        }
                        m2117X(this, false, false, 6);
                        return true;
                    }
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            }
            if (keyEvent.getKeyCode() == 108) {
                if (keyEvent.getAction() == 0) {
                    SharedPreferences sharedPreferences7 = this.f4111M;
                    if (sharedPreferences7 != null) {
                        if (sharedPreferences7.getBoolean("pref_haptic_feedback", true)) {
                            m2171n0(50L);
                        }
                        Log.i("MouseService", "Performing HOME action (Start Button)");
                        m2135L(2);
                        return true;
                    }
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            } else if (keyEvent.getKeyCode() == 109) {
                if (keyEvent.getAction() == 0) {
                    SharedPreferences sharedPreferences8 = this.f4111M;
                    if (sharedPreferences8 != null) {
                        if (sharedPreferences8.getBoolean("pref_haptic_feedback", true)) {
                            m2171n0(50L);
                        }
                        Log.i("MouseService", "Performing RECENTS action (Select Button)");
                        m2135L(3);
                        return true;
                    }
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            } else {
                if (!this.f4163k0) {
                    return false;
                }
                int keyCode2 = keyEvent.getKeyCode();
                int action2 = keyEvent.getAction();
                m2142U();
                Log.i("MouseService", "Key Event: code=" + keyCode2 + " (" + KeyEvent.keyCodeToString(keyCode2) + "), action=" + action2);
                boolean z20 = this.f4173o0;
                if (z20) {
                    if (keyCode2 != 97 && keyCode2 != 97) {
                        i = 96;
                        z4 = false;
                        z5 = z20 ? true : true;
                        if (!z4) {
                        }
                    } else {
                        z4 = true;
                        i = 96;
                        if (z20 ? !(keyCode2 == 97 || keyCode2 == 97) : !(keyCode2 == i || keyCode2 == i)) {
                            z5 = false;
                        }
                        if (!z4) {
                            if (action2 != 0) {
                                if (action2 == 1) {
                                    if (this.f4149d0) {
                                        this.f4149d0 = false;
                                        m2174q(this.f4075A, this.f4078B);
                                        if (this.f4085D0 && !this.f4082C0) {
                                            handler.postDelayed(new o60(this, this.f4075A, this.f4078B, 0), 40L);
                                        }
                                    } else if (this.f4147c0) {
                                        this.f4147c0 = false;
                                        m2152c0(this.f4075A, this.f4078B);
                                    }
                                }
                            } else if (!this.f4147c0 && !this.f4149d0) {
                                this.f4149d0 = true;
                                this.f4151e0 = System.currentTimeMillis();
                            } else if (this.f4149d0 && System.currentTimeMillis() - this.f4151e0 > 250) {
                                this.f4149d0 = false;
                                this.f4147c0 = true;
                                m2150b0(this.f4075A, this.f4078B);
                            }
                        } else {
                            if (z5) {
                                if (action2 == 0 && this.f4163k0) {
                                    SharedPreferences sharedPreferences9 = this.f4111M;
                                    if (sharedPreferences9 != null) {
                                        if (sharedPreferences9.getBoolean("pref_haptic_feedback", true)) {
                                            m2171n0(50L);
                                        }
                                        Log.i("MouseService", "Performing BACK action");
                                        for (View view : this.f4175p.values()) {
                                            ViewGroup.LayoutParams layoutParams2 = view.getLayoutParams();
                                            if (layoutParams2 instanceof WindowManager.LayoutParams) {
                                                layoutParams = (WindowManager.LayoutParams) layoutParams2;
                                            } else {
                                                layoutParams = null;
                                            }
                                            if (layoutParams != null) {
                                                layoutParams.flags |= 8;
                                                Object systemService = view.getContext().getSystemService("window");
                                                systemService.getClass();
                                                ((WindowManager) systemService).updateViewLayout(view, layoutParams);
                                                view.clearFocus();
                                            }
                                        }
                                        handler.postDelayed(new n60(this, 4), 50L);
                                    } else {
                                        xl3.m8890u("sharedPrefs");
                                        throw null;
                                    }
                                }
                            }
                            if (keyCode2 != 99) {
                                if (keyCode2 != 100) {
                                    if (keyCode2 != 107) {
                                        HashSet hashSet = this.f4194v0;
                                        switch (keyCode2) {
                                            case 19:
                                                if (action2 == 0 && this.f4163k0 && this.f4191u0) {
                                                    if (keyEvent.getRepeatCount() > 0) {
                                                        z7 = true;
                                                    } else {
                                                        z7 = false;
                                                    }
                                                    m2179v("up", z7);
                                                    return true;
                                                }
                                                if (this.f4163k0) {
                                                    break;
                                                }
                                                break;
                                            case 20:
                                                if (action2 == 0 && this.f4163k0 && this.f4191u0) {
                                                    if (keyEvent.getRepeatCount() > 0) {
                                                        z8 = true;
                                                    } else {
                                                        z8 = false;
                                                    }
                                                    m2179v("down", z8);
                                                    return true;
                                                }
                                                if (this.f4163k0) {
                                                    break;
                                                }
                                                break;
                                            case hg1.zzm /* 21 */:
                                                if (this.f4163k0) {
                                                    if (this.f4191u0) {
                                                        if (action2 == 0) {
                                                            hashSet.add(Integer.valueOf(keyCode2));
                                                            if (keyEvent.getRepeatCount() > 0) {
                                                                z9 = true;
                                                            } else {
                                                                z9 = false;
                                                            }
                                                            m2179v("left", z9);
                                                            return true;
                                                        }
                                                        hashSet.remove(Integer.valueOf(keyCode2));
                                                        return true;
                                                    }
                                                    if (!m2168m(keyCode2, action2)) {
                                                        Object systemService2 = getSystemService("audio");
                                                        systemService2.getClass();
                                                        AudioManager audioManager = (AudioManager) systemService2;
                                                        if (action2 == 0) {
                                                            i3 = 0;
                                                        } else {
                                                            i3 = 1;
                                                        }
                                                        audioManager.dispatchMediaKeyEvent(new KeyEvent(i3, 89));
                                                        return true;
                                                    }
                                                }
                                                break;
                                            case WorkManagerImpl.MAX_PRE_JOB_SCHEDULER_API_LEVEL /* 22 */:
                                                if (this.f4163k0) {
                                                    if (this.f4191u0) {
                                                        if (action2 == 0) {
                                                            hashSet.add(Integer.valueOf(keyCode2));
                                                            if (keyEvent.getRepeatCount() > 0) {
                                                                z10 = true;
                                                            } else {
                                                                z10 = false;
                                                            }
                                                            m2179v("right", z10);
                                                            return true;
                                                        }
                                                        hashSet.remove(Integer.valueOf(keyCode2));
                                                        return true;
                                                    }
                                                    if (!m2168m(keyCode2, action2)) {
                                                        Object systemService3 = getSystemService("audio");
                                                        systemService3.getClass();
                                                        AudioManager audioManager2 = (AudioManager) systemService3;
                                                        if (action2 == 0) {
                                                            i4 = 0;
                                                        } else {
                                                            i4 = 1;
                                                        }
                                                        audioManager2.dispatchMediaKeyEvent(new KeyEvent(i4, 90));
                                                        return true;
                                                    }
                                                }
                                                break;
                                            default:
                                                switch (keyCode2) {
                                                    case 102:
                                                        if (this.f4163k0) {
                                                            if (this.f4191u0) {
                                                                if (action2 == 0) {
                                                                    hashSet.add(Integer.valueOf(keyCode2));
                                                                    if (keyEvent.getRepeatCount() > 0) {
                                                                        z11 = true;
                                                                    } else {
                                                                        z11 = false;
                                                                    }
                                                                    m2179v("lb", z11);
                                                                    return true;
                                                                }
                                                                hashSet.remove(Integer.valueOf(keyCode2));
                                                                return true;
                                                            }
                                                            if (!m2168m(keyCode2, action2)) {
                                                                if (action2 == 0) {
                                                                    SharedPreferences sharedPreferences10 = this.f4111M;
                                                                    if (sharedPreferences10 != null) {
                                                                        if (sharedPreferences10.getBoolean("pref_haptic_feedback", true)) {
                                                                            m2171n0(50L);
                                                                        }
                                                                    } else {
                                                                        xl3.m8890u("sharedPrefs");
                                                                        throw null;
                                                                    }
                                                                }
                                                                Object systemService4 = getSystemService("audio");
                                                                systemService4.getClass();
                                                                AudioManager audioManager3 = (AudioManager) systemService4;
                                                                if (action2 == 0) {
                                                                    i5 = 0;
                                                                } else {
                                                                    i5 = 1;
                                                                }
                                                                audioManager3.dispatchMediaKeyEvent(new KeyEvent(i5, 88));
                                                                return true;
                                                            }
                                                        }
                                                        break;
                                                    case 103:
                                                        if (this.f4163k0) {
                                                            if (this.f4191u0) {
                                                                if (action2 == 0) {
                                                                    hashSet.add(Integer.valueOf(keyCode2));
                                                                    if (keyEvent.getRepeatCount() > 0) {
                                                                        z12 = true;
                                                                    } else {
                                                                        z12 = false;
                                                                    }
                                                                    m2179v("rb", z12);
                                                                    return true;
                                                                }
                                                                hashSet.remove(Integer.valueOf(keyCode2));
                                                                return true;
                                                            }
                                                            if (!m2168m(keyCode2, action2)) {
                                                                if (action2 == 0) {
                                                                    SharedPreferences sharedPreferences11 = this.f4111M;
                                                                    if (sharedPreferences11 != null) {
                                                                        if (sharedPreferences11.getBoolean("pref_haptic_feedback", true)) {
                                                                            m2171n0(50L);
                                                                        }
                                                                    } else {
                                                                        xl3.m8890u("sharedPrefs");
                                                                        throw null;
                                                                    }
                                                                }
                                                                Object systemService5 = getSystemService("audio");
                                                                systemService5.getClass();
                                                                AudioManager audioManager4 = (AudioManager) systemService5;
                                                                if (action2 == 0) {
                                                                    i6 = 0;
                                                                } else {
                                                                    i6 = 1;
                                                                }
                                                                audioManager4.dispatchMediaKeyEvent(new KeyEvent(i6, 87));
                                                                return true;
                                                            }
                                                        }
                                                        break;
                                                    case 104:
                                                        if (action2 == 0 && this.f4163k0) {
                                                            if (this.f4191u0) {
                                                                if (keyEvent.getRepeatCount() > 0) {
                                                                    z13 = true;
                                                                } else {
                                                                    z13 = false;
                                                                }
                                                                m2179v("lt", z13);
                                                                return true;
                                                            }
                                                            SharedPreferences sharedPreferences12 = this.f4111M;
                                                            if (sharedPreferences12 != null) {
                                                                if (sharedPreferences12.getBoolean("pref_haptic_feedback", true)) {
                                                                    m2171n0(50L);
                                                                }
                                                                Log.i("MouseService", "LT Pressed - Windowed Mode / Restore");
                                                                m2137N(false);
                                                            } else {
                                                                xl3.m8890u("sharedPrefs");
                                                                throw null;
                                                            }
                                                        }
                                                        break;
                                                    case 105:
                                                        if (action2 == 0 && this.f4163k0) {
                                                            if (this.f4191u0) {
                                                                if (keyEvent.getRepeatCount() > 0) {
                                                                    z14 = true;
                                                                } else {
                                                                    z14 = false;
                                                                }
                                                                m2179v("rt", z14);
                                                                return true;
                                                            }
                                                            SharedPreferences sharedPreferences13 = this.f4111M;
                                                            if (sharedPreferences13 != null) {
                                                                if (sharedPreferences13.getBoolean("pref_haptic_feedback", true)) {
                                                                    m2171n0(50L);
                                                                }
                                                                Log.i("MouseService", "RT Pressed - Maximize/Restore Window");
                                                                m2137N(true);
                                                            } else {
                                                                xl3.m8890u("sharedPrefs");
                                                                throw null;
                                                            }
                                                        }
                                                        break;
                                                }
                                        }
                                    } else if (action2 == 0) {
                                        if (db0.m2408b()) {
                                            SharedPreferences sharedPreferences14 = this.f4111M;
                                            if (sharedPreferences14 != null) {
                                                if (sharedPreferences14.getBoolean("pref_haptic_feedback", true)) {
                                                    m2171n0(50L);
                                                }
                                                Log.i("MouseService", "R3 Pressed - Toggling Active Display");
                                                this.f4205z = !this.f4205z;
                                                m2162i0();
                                                return true;
                                            }
                                            xl3.m8890u("sharedPrefs");
                                            throw null;
                                        }
                                        Log.i("MouseService", "R3 Pressed - Pro Feature Restricted");
                                        handler.post(new n60(this, 5));
                                        return true;
                                    }
                                } else if (this.f4163k0) {
                                    if (action2 == 0) {
                                        SharedPreferences sharedPreferences15 = this.f4111M;
                                        if (sharedPreferences15 != null) {
                                            if (sharedPreferences15.getBoolean("pref_haptic_feedback", true)) {
                                                m2171n0(50L);
                                            }
                                        } else {
                                            xl3.m8890u("sharedPrefs");
                                            throw null;
                                        }
                                    }
                                    Object systemService6 = getSystemService("audio");
                                    systemService6.getClass();
                                    AudioManager audioManager5 = (AudioManager) systemService6;
                                    if (action2 == 0) {
                                        i2 = 0;
                                    } else {
                                        i2 = 1;
                                    }
                                    audioManager5.dispatchMediaKeyEvent(new KeyEvent(i2, 85));
                                    return true;
                                }
                                if (!this.f4163k0) {
                                    return false;
                                }
                                if (keyEvent.getKeyCode() == 106 && !this.f4167m0) {
                                    return false;
                                }
                            } else {
                                if (action2 == 0) {
                                    z6 = true;
                                } else {
                                    z6 = false;
                                }
                                this.f4191u0 = z6;
                            }
                        }
                    }
                } else {
                    i = 96;
                    if (keyCode2 == 96 || keyCode2 == 96) {
                        z4 = true;
                        if (z20) {
                        }
                        if (!z4) {
                        }
                    }
                    z4 = false;
                    if (z20) {
                    }
                    if (!z4) {
                    }
                }
            }
        }
        return true;
    }

    /* renamed from: D */
    public final void m2128D(AccessibilityService.ScreenshotResult screenshotResult, Display display, String str) {
        HardwareBuffer hardwareBuffer;
        ColorSpace colorSpace;
        Bitmap wrapHardwareBuffer;
        Bitmap.Config config;
        try {
            hardwareBuffer = screenshotResult.getHardwareBuffer();
            if (hardwareBuffer != null) {
                colorSpace = screenshotResult.getColorSpace();
                wrapHardwareBuffer = Bitmap.wrapHardwareBuffer(hardwareBuffer, colorSpace);
                if (wrapHardwareBuffer != null) {
                    hardwareBuffer.close();
                    Bitmap.Config config2 = wrapHardwareBuffer.getConfig();
                    config = Bitmap.Config.HARDWARE;
                    if (config2 == config) {
                        Bitmap copy = wrapHardwareBuffer.copy(Bitmap.Config.ARGB_8888, false);
                        wrapHardwareBuffer.recycle();
                        copy.getClass();
                        wrapHardwareBuffer = copy;
                    }
                    if (display != null) {
                        DisplayMetrics displayMetrics = new DisplayMetrics();
                        display.getRealMetrics(displayMetrics);
                        Log.i("MouseService", "Screenshot stage=" + str + " bitmap=" + wrapHardwareBuffer.getWidth() + "x" + wrapHardwareBuffer.getHeight() + " display=" + displayMetrics.widthPixels + "x" + displayMetrics.heightPixels);
                    }
                    boolean m2143V = m2143V(wrapHardwareBuffer);
                    wrapHardwareBuffer.recycle();
                    this.f4096H.post(new h20(m2143V, this));
                    return;
                }
                throw new IllegalStateException("bitmap wrap failed");
            }
            throw new IllegalStateException("no hardware buffer");
        } catch (Exception e) {
            Log.e("MouseService", "Screenshot capture/save failed, falling back to system screenshot", e);
            performGlobalAction(9);
        }
    }

    /* renamed from: E */
    public final void m2129E() {
        ImageView imageView;
        ViewPropertyAnimator animate;
        ViewPropertyAnimator alpha;
        ViewPropertyAnimator duration;
        PowerManager.WakeLock wakeLock;
        FrameLayout frameLayout = this.f4178q;
        if (frameLayout != null) {
            if (frameLayout.getVisibility() == 0) {
                frameLayout.setClickable(false);
                frameLayout.setFocusable(false);
                frameLayout.setEnabled(false);
                if (this.f4087E) {
                    unregisterReceiver(this.f4093G);
                    this.f4087E = false;
                }
                frameLayout.animate().alpha(0.0f).setDuration(200L).withEndAction(new RunnableC0151b2(9, frameLayout)).start();
            }
            if (!this.f4163k0) {
                ViewGroup.LayoutParams layoutParams = frameLayout.getLayoutParams();
                layoutParams.getClass();
                WindowManager.LayoutParams layoutParams2 = (WindowManager.LayoutParams) layoutParams;
                if (layoutParams2.screenBrightness != -1.0f) {
                    layoutParams2.screenBrightness = -1.0f;
                    try {
                        Object systemService = frameLayout.getContext().getSystemService("window");
                        systemService.getClass();
                        ((WindowManager) systemService).updateViewLayout(frameLayout, layoutParams2);
                    } catch (Exception unused) {
                    }
                }
                try {
                    PowerManager.WakeLock wakeLock2 = this.f4184s;
                    if (wakeLock2 != null && wakeLock2.isHeld() && (wakeLock = this.f4184s) != null) {
                        wakeLock.release();
                    }
                    PowerManager.WakeLock wakeLock3 = this.f4184s;
                    if (wakeLock3 != null) {
                        wakeLock3.acquire(3000L);
                    }
                } catch (Exception unused2) {
                }
            }
            if (this.f4163k0 && (imageView = this.f4172o) != null && (animate = imageView.animate()) != null && (alpha = animate.alpha(1.0f)) != null && (duration = alpha.setDuration(200L)) != null) {
                duration.start();
            }
        }
    }

    /* renamed from: G */
    public final void m2130G() {
        int i;
        if (this.f4082C0) {
            C0575lv c0575lv = this.f4100I0;
            StringBuilder sb = c0575lv.f9697a;
            StringBuilder sb2 = c0575lv.f9698b;
            if (c0575lv.f9701e != 0) {
                c0575lv.f9701e = 0;
            } else if (c0575lv.f9700d != null) {
                c0575lv.f9700d = null;
            } else if (c0575lv.f9699c != null) {
                c0575lv.f9699c = null;
            } else if (sb2.length() > 0) {
                sb2.setLength(sb2.length() - 1);
            } else {
                if (sb.length() == 0 || (i = c0575lv.f9702f) <= 0) {
                    return;
                }
                sb.deleteCharAt(i - 1);
                c0575lv.f9702f--;
            }
            m2166l();
        }
    }

    /* renamed from: H */
    public final void m2131H(int i, int i2) {
        if (!this.f4082C0) {
            return;
        }
        C0575lv c0575lv = this.f4100I0;
        if (i > 0) {
            if (c0575lv.m5204e()) {
                c0575lv.m5203d();
            } else if (c0575lv.f9702f < c0575lv.f9697a.length()) {
                c0575lv.f9702f++;
            }
        } else if (i < 0) {
            c0575lv.m5203d();
            int i3 = c0575lv.f9702f;
            if (i3 > 0) {
                c0575lv.f9702f = i3 - 1;
            }
        } else if (i2 > 0) {
            c0575lv.m5205f();
        } else if (i2 < 0) {
            c0575lv.m5206g();
        }
        m2166l();
        m2138P();
    }

    /* renamed from: I */
    public final void m2132I(C0911uy c0911uy) {
        boolean z;
        String str;
        Character ch;
        char charAt;
        Character ch2;
        boolean z2;
        boolean z3;
        if (c0911uy != null) {
            EnumC0948vy enumC0948vy = c0911uy.f15809f;
            if (this.f4082C0) {
                int ordinal = enumC0948vy.ordinal();
                C0950w c0950w = this.f4103J0;
                C0575lv c0575lv = this.f4100I0;
                int i = 0;
                if (ordinal != 0) {
                    if (ordinal != 1) {
                        if (ordinal != 12) {
                            if (c0950w.f17376a != 0) {
                                c0950w.f17376a = 0;
                                C1059yy c1059yy = this.f4088E0;
                                if (c1059yy != null) {
                                    c1059yy.setAccentPending(c0950w.f17376a);
                                }
                            }
                            switch (enumC0948vy.ordinal()) {
                                case 2:
                                    m2130G();
                                    break;
                                case 3:
                                    m2136M();
                                    break;
                                case 4:
                                    m2158g0();
                                    break;
                                case 5:
                                    if (this.f4082C0) {
                                        this.f4134V0 = !this.f4134V0;
                                        m2139Q();
                                        break;
                                    }
                                    break;
                                case 6:
                                    if (this.f4082C0) {
                                        this.f4138X0 = !this.f4138X0;
                                        m2139Q();
                                        break;
                                    }
                                    break;
                                case 7:
                                    m2163j(true);
                                    break;
                                case 8:
                                    c0575lv.m5202c('\t');
                                    m2166l();
                                    break;
                                case 9:
                                    if (this.f4082C0) {
                                        Object systemService = getSystemService("clipboard");
                                        systemService.getClass();
                                        ClipData primaryClip = ((ClipboardManager) systemService).getPrimaryClip();
                                        if (primaryClip != null && primaryClip.getItemCount() != 0) {
                                            String obj = primaryClip.getItemAt(0).coerceToText(this).toString();
                                            if (obj.length() != 0) {
                                                int length = obj.length();
                                                while (i < length) {
                                                    char charAt2 = obj.charAt(i);
                                                    if (charAt2 != '\n' && charAt2 != '\r' && charAt2 != '\t') {
                                                        c0575lv.m5202c(charAt2);
                                                    }
                                                    i++;
                                                }
                                                m2166l();
                                                break;
                                            }
                                        }
                                    }
                                    break;
                                case 10:
                                case 11:
                                    boolean z4 = this.f4138X0;
                                    if (!this.f4134V0 && !this.f4136W0) {
                                        z2 = false;
                                    } else {
                                        z2 = true;
                                    }
                                    if (z4 != z2) {
                                        z3 = true;
                                    } else {
                                        z3 = false;
                                    }
                                    if (enumC0948vy == EnumC0948vy.f17334w) {
                                        i = 1;
                                    }
                                    if (z3) {
                                        if (i != 0) {
                                            c0575lv.m5206g();
                                        } else {
                                            c0575lv.m5205f();
                                        }
                                    } else if (i != 0) {
                                        c0575lv.m5203d();
                                        int i2 = c0575lv.f9702f;
                                        if (i2 > 0) {
                                            c0575lv.f9702f = i2 - 1;
                                        }
                                    } else if (c0575lv.m5204e()) {
                                        c0575lv.m5203d();
                                    } else if (c0575lv.f9702f < c0575lv.f9697a.length()) {
                                        c0575lv.f9702f++;
                                    }
                                    m2166l();
                                    break;
                                case 13:
                                    m2163j(false);
                                    Intent intent = new Intent(this, (Class<?>) MainActivity.class);
                                    intent.addFlags(805306368);
                                    intent.putExtra("open_page", "keyboard_settings");
                                    try {
                                        startActivity(intent);
                                        break;
                                    } catch (Exception e) {
                                        Log.w("MouseService", "Could not open keyboard settings page: " + e.getMessage());
                                        break;
                                    }
                            }
                        } else {
                            m2149b();
                        }
                    } else {
                        if (c0950w.f17376a != 0) {
                            ch2 = c0950w.m8492a(' ');
                        } else {
                            ch2 = null;
                        }
                        boolean z5 = this.f4082C0;
                        if (ch2 != null) {
                            char charValue = ch2.charValue();
                            if (z5) {
                                c0575lv.m5202c(charValue);
                                m2166l();
                            }
                            C1059yy c1059yy2 = this.f4088E0;
                            if (c1059yy2 != null) {
                                c1059yy2.setAccentPending(c0950w.f17376a);
                            }
                        } else if (z5) {
                            c0575lv.m5202c(' ');
                            m2166l();
                        }
                    }
                } else {
                    boolean z6 = this.f4138X0;
                    if (!this.f4134V0 && !this.f4136W0) {
                        z = false;
                    } else {
                        z = true;
                    }
                    if (z6 == z || (str = c0911uy.f15808e) == null) {
                        str = c0911uy.f15807d;
                    }
                    if (str.length() > 0) {
                        if (c0950w.f17376a != 0) {
                            ch = c0950w.m8492a(str.charAt(0));
                        } else {
                            ch = null;
                        }
                        if (ch != null) {
                            charAt = ch.charValue();
                        } else {
                            charAt = str.charAt(0);
                        }
                        if (this.f4082C0) {
                            c0575lv.m5202c(charAt);
                            m2166l();
                        }
                        C1059yy c1059yy3 = this.f4088E0;
                        if (c1059yy3 != null) {
                            c1059yy3.setAccentPending(c0950w.f17376a);
                        }
                    }
                }
                SharedPreferences sharedPreferences = this.f4111M;
                if (sharedPreferences != null) {
                    if (sharedPreferences.getBoolean("pref_haptic_feedback", true)) {
                        m2171n0(25L);
                        return;
                    }
                    return;
                }
                xl3.m8890u("sharedPrefs");
                throw null;
            }
        }
    }

    /* renamed from: J */
    public final void m2133J(AccessibilityNodeInfo accessibilityNodeInfo, float f, float f2) {
        WindowManager windowManager;
        EnumC0985wy enumC0985wy;
        boolean z;
        boolean z2;
        boolean z3;
        int i;
        int i2;
        if (this.f4082C0 || (windowManager = this.f4169n) == null) {
            return;
        }
        m2154d0(Integer.valueOf(R.string.toast_repeat_stopped));
        this.f4194v0.clear();
        this.f4082C0 = true;
        this.f4097H0 = accessibilityNodeInfo;
        this.f4142Z0 = f;
        this.f4144a1 = f2;
        this.f4134V0 = false;
        this.f4136W0 = false;
        this.f4138X0 = false;
        this.f4160i1 = false;
        this.f4162j1 = false;
        m2159h();
        s60 s60Var = this.f4086D1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        handler.removeCallbacks(this.f4089E1);
        ArrayList m2176s = m2176s();
        if (m2176s.size() == 1) {
            if (!m2176s.isEmpty()) {
                enumC0985wy = (EnumC0985wy) m2176s.get(0);
            } else {
                throw new NoSuchElementException("List is empty.");
            }
        } else {
            enumC0985wy = EnumC0985wy.f17925n;
        }
        this.f4106K0 = enumC0985wy;
        String m2115O = m2115O(accessibilityNodeInfo);
        C0575lv c0575lv = this.f4100I0;
        StringBuilder sb = c0575lv.f9697a;
        sb.setLength(0);
        c0575lv.f9698b.setLength(0);
        c0575lv.f9699c = null;
        c0575lv.f9700d = null;
        c0575lv.f9701e = 0;
        c0575lv.f9702f = 0;
        sb.append(m2115O);
        c0575lv.f9702f = sb.length();
        this.f4103J0.f17376a = 0;
        m2159h();
        m2157g();
        m2161i();
        if (this.f4124Q0) {
            m2178u();
        }
        Context context = this.f4202y;
        if (context == null) {
            context = this;
        }
        int i3 = this.f4081C;
        Display display = this.f4199x;
        if (display != null && display.getDisplayId() == 0) {
            z = true;
        } else {
            z = false;
        }
        C1059yy c1059yy = new C1059yy(context, i3, !z, new C0360g(2, this));
        Display display2 = this.f4199x;
        if (display2 != null && display2.getDisplayId() == 0) {
            z2 = true;
        } else {
            z2 = false;
        }
        if (m2176s().size() >= 2) {
            z3 = true;
        } else {
            z3 = false;
        }
        c1059yy.setLangToggleEnabled(z3);
        c1059yy.setLang(this.f4106K0);
        boolean z4 = this.f4134V0;
        boolean z5 = this.f4138X0;
        c1059yy.f19487s = z4;
        c1059yy.f19488t = z5;
        c1059yy.m9197d();
        c1059yy.m9200g(this.f4126R0 / 100.0f, this.f4128S0 / 100.0f, m2173p());
        v60 v60Var = new v60(c1059yy, this, c1059yy.getContext());
        v60Var.setBackgroundColor(570425344);
        if (!z2) {
            i = (int) ((this.f4081C * this.f4126R0) / 100.0f);
        } else {
            i = -1;
        }
        if (!z2) {
            i2 = m2173p();
        } else {
            i2 = 80;
        }
        v60Var.addView(c1059yy, new FrameLayout.LayoutParams(i, -2, i2));
        WindowManager.LayoutParams layoutParams = new WindowManager.LayoutParams(-1, -1, 2032, 264, -3);
        layoutParams.gravity = 80;
        try {
            windowManager.addView(v60Var, layoutParams);
            this.f4088E0 = c1059yy;
            this.f4091F0 = v60Var;
            this.f4094G0 = windowManager;
            handler.postDelayed(new n60(this, 11), 120L);
            handler.postDelayed(new n60(this, 12), 600L);
            this.f4145b0 = false;
            ImageView imageView = this.f4172o;
            if (imageView != null) {
                imageView.setVisibility(8);
            }
            ImageView imageView2 = this.f4172o;
            if (imageView2 != null) {
                imageView2.setAlpha(0.0f);
            }
            this.f4148c1 = 0;
            this.f4150d1 = 0;
            m2142U();
            SharedPreferences sharedPreferences = this.f4111M;
            if (sharedPreferences != null) {
                if (sharedPreferences.getBoolean("pref_haptic_feedback", true)) {
                    m2171n0(60L);
                }
                Log.i("MouseService", "Keyboard mode opened at (" + f + ", " + f2 + "). lang=" + this.f4106K0);
                return;
            }
            xl3.m8890u("sharedPrefs");
            throw null;
        } catch (Exception e) {
            Log.e("MouseService", "Failed to add keyboard overlay: " + e.getMessage());
            this.f4082C0 = false;
        }
    }

    /* renamed from: K */
    public final void m2134K(float f, float f2) {
        float f3;
        Display display;
        int i = Build.VERSION.SDK_INT;
        if (i >= 26) {
            this.f4159i0 = true;
            float f4 = this.f4075A;
            float f5 = this.f4084D / 2.0f;
            Display display2 = this.f4199x;
            if (display2 != null && display2.getDisplayId() == 0) {
                f3 = 1.0f;
            } else {
                f3 = 0.5f;
            }
            float f6 = this.f4125R * 180.0f * f3;
            Path path = new Path();
            path.moveTo(f4, f5);
            path.lineTo(f4 - (f * f6), f5 - (f2 * f6));
            try {
                this.f4182r0 = System.currentTimeMillis();
                GestureDescription.Builder builder = new GestureDescription.Builder();
                if (i >= 30 && (display = this.f4199x) != null) {
                    builder.setDisplayId(display.getDisplayId());
                }
                builder.addStroke(new GestureDescription.StrokeDescription(path, 0L, 150L));
                dispatchGesture(builder.build(), this.f4161j0, null);
            } catch (Exception e) {
                Log.e("MouseService", "Failed discrete scroll: " + e.getMessage());
                this.f4159i0 = false;
            }
        }
    }

    /* renamed from: L */
    public final void m2135L(int i) {
        int i2;
        Display display = this.f4199x;
        if (display != null) {
            i2 = display.getDisplayId();
        } else {
            i2 = 0;
        }
        View view = (View) this.f4175p.get(Integer.valueOf(i2));
        if (view != null) {
            m2116T(view, i2);
        }
        m2160h0();
        this.f4096H.postDelayed(new q60(this, i), 80L);
    }

    /* renamed from: M */
    public final void m2136M() {
        AccessibilityNodeInfo.AccessibilityAction accessibilityAction;
        boolean z;
        boolean z2;
        if (!this.f4082C0) {
            return;
        }
        C0575lv c0575lv = this.f4100I0;
        c0575lv.m5203d();
        m2166l();
        AccessibilityNodeInfo accessibilityNodeInfo = this.f4097H0;
        boolean z3 = false;
        if (accessibilityNodeInfo != null && Build.VERSION.SDK_INT >= 33) {
            try {
                z2 = accessibilityNodeInfo.isMultiLine();
            } catch (Exception unused) {
                z2 = false;
            }
            if (z2) {
                c0575lv.m5202c('\n');
                m2166l();
                Log.i("MouseService", "Keyboard Enter: newline inserted (multiline field)");
                return;
            }
        }
        if (Build.VERSION.SDK_INT >= 30) {
            accessibilityAction = AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER;
            int id = accessibilityAction.getId();
            AccessibilityNodeInfo m2125A = m2125A(this.f4142Z0, this.f4144a1);
            if (m2125A != null) {
                z = true;
            } else {
                z = false;
            }
            if (m2125A == null) {
                m2125A = this.f4097H0;
            }
            if (m2125A != null) {
                try {
                    List<AccessibilityNodeInfo.AccessibilityAction> actionList = m2125A.getActionList();
                    actionList.getClass();
                    List<AccessibilityNodeInfo.AccessibilityAction> list = actionList;
                    if (!(list instanceof Collection) || !list.isEmpty()) {
                        Iterator<T> it = list.iterator();
                        while (it.hasNext()) {
                            if (((AccessibilityNodeInfo.AccessibilityAction) it.next()).getId() == id) {
                                Rect rect = new Rect();
                                try {
                                    m2125A.getBoundsInScreen(rect);
                                } catch (Exception unused2) {
                                }
                                this.f4122P1 = rect;
                                try {
                                    z3 = m2125A.performAction(id);
                                } catch (Exception unused3) {
                                }
                                if (z) {
                                    try {
                                        m2125A.recycle();
                                    } catch (Exception unused4) {
                                    }
                                }
                                Log.i("MouseService", "Keyboard Enter: ACTION_IME_ENTER performed=" + z3);
                            }
                        }
                    }
                } catch (Exception unused5) {
                }
                if (z) {
                    try {
                        m2125A.recycle();
                    } catch (Exception unused6) {
                    }
                }
            }
        }
        if (z3) {
            this.f4096H.postDelayed(new n60(this, 1), 250L);
        } else {
            Log.i("MouseService", "Keyboard Enter: committed and closed (no IME action available)");
            m2163j(true);
        }
    }

    /* renamed from: N */
    public final void m2137N(final boolean z) {
        final List m4409W;
        int i;
        Display display;
        SparseArray windowsOnAllDisplays;
        if (z) {
            m4409W = AbstractC0484je.m4409W("창 최대화", "최대화", "전체 화면", "maximize", "fullscreen");
        } else {
            m4409W = AbstractC0484je.m4409W("이전 크기로 복원", "창 복원", "창 모드로 전환", "팝업 화면", "restore", "window");
        }
        ArrayList arrayList = new ArrayList();
        Display display2 = this.f4199x;
        final int i2 = 0;
        if (display2 != null) {
            i = display2.getDisplayId();
        } else {
            i = 0;
        }
        if (Build.VERSION.SDK_INT >= 30) {
            windowsOnAllDisplays = getWindowsOnAllDisplays();
            windowsOnAllDisplays.getClass();
            List list = (List) windowsOnAllDisplays.get(i);
            if (list != null) {
                arrayList.addAll(list);
            }
        } else {
            List<AccessibilityWindowInfo> windows = getWindows();
            if (windows != null) {
                arrayList.addAll(windows);
            }
        }
        int size = arrayList.size();
        int i3 = 0;
        while (true) {
            final int i4 = 1;
            if (i3 < size) {
                AccessibilityNodeInfo root = ((AccessibilityWindowInfo) arrayList.get(i3)).getRoot();
                if (root != null) {
                    AccessibilityNodeInfo m2123x = m2123x(root, m4409W);
                    if (m2123x != null) {
                        Log.i("MouseService", "Found window action node directly: " + ((Object) m2123x.getContentDescription()));
                        this.f4076A0 = true;
                        this.f4079B0 = System.currentTimeMillis();
                        m2123x.performAction(16);
                        m2123x.recycle();
                        root.recycle();
                        return;
                    }
                    root.recycle();
                }
                i3++;
            } else {
                Log.i("MouseService", "Window action node not found directly. Searching for window handle to expand menu...");
                int size2 = arrayList.size();
                for (int i5 = 0; i5 < size2; i5++) {
                    AccessibilityNodeInfo root2 = ((AccessibilityWindowInfo) arrayList.get(i5)).getRoot();
                    if (root2 != null) {
                        AccessibilityNodeInfo m2122w = m2122w(root2, "창 핸들");
                        if (m2122w != null) {
                            Log.i("MouseService", "Found window handle: " + ((Object) m2122w.getContentDescription()) + ". Clicking it to reveal menu.");
                            this.f4076A0 = true;
                            this.f4079B0 = System.currentTimeMillis();
                            m2122w.performAction(16);
                            new Handler(Looper.getMainLooper()).postDelayed(new Runnable(this, m4409W, z, i2) { // from class: p60

                                /* renamed from: n */
                                public final /* synthetic */ int f11907n;

                                /* renamed from: o */
                                public final /* synthetic */ MouseAccessibilityService f11908o;

                                /* renamed from: p */
                                public final /* synthetic */ List f11909p;

                                {
                                    this.f11907n = i2;
                                    this.f11908o = this;
                                }

                                @Override // java.lang.Runnable
                                public final void run() {
                                    int i6 = this.f11907n;
                                    List list2 = this.f11909p;
                                    MouseAccessibilityService mouseAccessibilityService = this.f11908o;
                                    switch (i6) {
                                        case 0:
                                            int i7 = MouseAccessibilityService.f4074Q1;
                                            mouseAccessibilityService.m2151c(list2);
                                            return;
                                        default:
                                            int i8 = MouseAccessibilityService.f4074Q1;
                                            mouseAccessibilityService.m2151c(list2);
                                            return;
                                    }
                                }
                            }, 300L);
                            m2122w.recycle();
                            root2.recycle();
                            return;
                        }
                        root2.recycle();
                    }
                }
                Log.w("MouseService", "Window action node and handle not found for maximize=" + z + ".");
                if (!z) {
                    Display display3 = this.f4199x;
                    if (display3 != null && display3.getDisplayId() == 0) {
                        Log.i("MouseService", "Phone screen LT pressed: Performing BACK action (giving up on windowed mode on phone)");
                        performGlobalAction(1);
                        return;
                    }
                    Log.i("MouseService", "DeX LT pressed: Attempting native Restore button or Title Bar toggle.");
                    int size3 = arrayList.size();
                    for (int i6 = 0; i6 < size3; i6++) {
                        AccessibilityNodeInfo root3 = ((AccessibilityWindowInfo) arrayList.get(i6)).getRoot();
                        if (root3 != null) {
                            AccessibilityNodeInfo m2123x2 = m2123x(root3, m4409W);
                            if (m2123x2 != null) {
                                Log.i("MouseService", "Found DeX Restore node directly.");
                                m2123x2.performAction(16);
                                m2123x2.recycle();
                                root3.recycle();
                                return;
                            }
                            root3.recycle();
                        }
                    }
                    int size4 = arrayList.size();
                    while (i2 < size4) {
                        AccessibilityNodeInfo root4 = ((AccessibilityWindowInfo) arrayList.get(i2)).getRoot();
                        if (root4 != null) {
                            AccessibilityNodeInfo m2122w2 = m2122w(root4, "창 핸들");
                            if (m2122w2 == null) {
                                m2122w2 = m2122w(root4, "옵션 더보기");
                            }
                            if (m2122w2 != null) {
                                Log.i("MouseService", "Found DeX Window Handle (" + ((Object) m2122w2.getContentDescription()) + "). Clicking to expand menu.");
                                m2122w2.performAction(16);
                                this.f4096H.postDelayed(new Runnable(this, m4409W, z, i4) { // from class: p60

                                    /* renamed from: n */
                                    public final /* synthetic */ int f11907n;

                                    /* renamed from: o */
                                    public final /* synthetic */ MouseAccessibilityService f11908o;

                                    /* renamed from: p */
                                    public final /* synthetic */ List f11909p;

                                    {
                                        this.f11907n = i4;
                                        this.f11908o = this;
                                    }

                                    @Override // java.lang.Runnable
                                    public final void run() {
                                        int i62 = this.f11907n;
                                        List list2 = this.f11909p;
                                        MouseAccessibilityService mouseAccessibilityService = this.f11908o;
                                        switch (i62) {
                                            case 0:
                                                int i7 = MouseAccessibilityService.f4074Q1;
                                                mouseAccessibilityService.m2151c(list2);
                                                return;
                                            default:
                                                int i8 = MouseAccessibilityService.f4074Q1;
                                                mouseAccessibilityService.m2151c(list2);
                                                return;
                                        }
                                    }
                                }, 300L);
                                m2122w2.recycle();
                                root4.recycle();
                                return;
                            }
                            root4.recycle();
                        }
                        i2++;
                    }
                    Log.i("MouseService", "DeX Restore failed: Tapping Title Bar area at top-center.");
                    Path path = new Path();
                    path.moveTo(this.f4081C / 2.0f, 30.0f);
                    GestureDescription.StrokeDescription strokeDescription = new GestureDescription.StrokeDescription(path, 0L, 50L);
                    GestureDescription.Builder builder = new GestureDescription.Builder();
                    builder.addStroke(strokeDescription);
                    if (Build.VERSION.SDK_INT >= 30 && (display = this.f4199x) != null) {
                        builder.setDisplayId(display.getDisplayId());
                    }
                    dispatchGesture(builder.build(), null, null);
                    return;
                }
                return;
            }
        }
    }

    /* renamed from: P */
    public final void m2138P() {
        int i;
        if (this.f4124Q0) {
            try {
                if (this.f4195v1 == null || this.f4198w1 == 0) {
                    m2178u();
                }
                SoundPool soundPool = this.f4195v1;
                if (soundPool != null && (i = this.f4198w1) != 0) {
                    soundPool.play(i, 0.8f, 0.8f, 1, 0, 1.0f);
                    return;
                }
            } catch (Exception unused) {
                SoundPool soundPool2 = this.f4195v1;
                if (soundPool2 != null) {
                    soundPool2.release();
                }
                this.f4195v1 = null;
                this.f4198w1 = 0;
            }
            try {
                ToneGenerator toneGenerator = this.f4132U0;
                if (toneGenerator == null) {
                    toneGenerator = new ToneGenerator(3, 90);
                    this.f4132U0 = toneGenerator;
                }
                toneGenerator.startTone(24);
            } catch (Exception unused2) {
                ToneGenerator toneGenerator2 = this.f4132U0;
                if (toneGenerator2 != null) {
                    toneGenerator2.release();
                }
                this.f4132U0 = null;
            }
        }
    }

    /* renamed from: Q */
    public final void m2139Q() {
        boolean z;
        C1059yy c1059yy = this.f4088E0;
        if (c1059yy != null) {
            if (!this.f4134V0 && !this.f4136W0) {
                z = false;
            } else {
                z = true;
            }
            boolean z2 = this.f4138X0;
            c1059yy.f19487s = z;
            c1059yy.f19488t = z2;
            c1059yy.m9197d();
        }
    }

    /* renamed from: R */
    public final long m2140R(String str) {
        if (this.f4111M != null) {
            return lo0.m5054i(r2.getInt("pref_mapping_x_" + str + "_interval", 500), 100, 3000);
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: S */
    public final void m2141S() {
        C1059yy c1059yy;
        v60 v60Var;
        AccessibilityNodeInfo accessibilityNodeInfo;
        boolean z;
        boolean z2;
        FrameLayout.LayoutParams layoutParams;
        int i;
        String str;
        if (this.f4082C0 && (c1059yy = this.f4088E0) != null && (v60Var = this.f4091F0) != null && (accessibilityNodeInfo = this.f4097H0) != null) {
            Rect rect = new Rect();
            try {
                accessibilityNodeInfo.getBoundsInScreen(rect);
                if (!rect.isEmpty()) {
                    int[] iArr = new int[2];
                    v60Var.getLocationOnScreen(iArr);
                    int height = v60Var.getHeight();
                    int height2 = c1059yy.getHeight();
                    if (height > 0 && height2 > 0) {
                        int i2 = rect.top;
                        boolean z3 = true;
                        int i3 = iArr[1];
                        int i4 = i2 - i3;
                        if (rect.bottom - i3 > height - height2) {
                            z = true;
                        } else {
                            z = false;
                        }
                        if (i4 < height2) {
                            z2 = true;
                        } else {
                            z2 = false;
                        }
                        ViewGroup.LayoutParams layoutParams2 = c1059yy.getLayoutParams();
                        if (layoutParams2 instanceof FrameLayout.LayoutParams) {
                            layoutParams = (FrameLayout.LayoutParams) layoutParams2;
                        } else {
                            layoutParams = null;
                        }
                        if (layoutParams != null) {
                            if (!z || z2) {
                                z3 = false;
                            }
                            int i5 = layoutParams.gravity;
                            int i6 = i5 & 7;
                            if (z3) {
                                i = 48;
                            } else {
                                i = 80;
                            }
                            int i7 = i6 | i;
                            if (i5 != i7) {
                                layoutParams.gravity = i7;
                                c1059yy.setLayoutParams(layoutParams);
                                if (z3) {
                                    str = "top";
                                } else {
                                    str = "bottom";
                                }
                                Log.i("MouseService", "Keyboard repositioned to " + str + " to keep the focused field visible");
                            }
                        }
                    }
                }
            } catch (Exception unused) {
            }
        }
    }

    /* renamed from: U */
    public final void m2142U() {
        if (this.f4129T) {
            this.f4143a0 = System.currentTimeMillis();
            Display display = this.f4199x;
            if (display != null && display.getDisplayId() == 0) {
                m2129E();
            }
        }
    }

    /* renamed from: V */
    public final boolean m2143V(Bitmap bitmap) {
        OutputStream openOutputStream;
        try {
            String format = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
            ContentValues contentValues = new ContentValues();
            contentValues.put("_display_name", "GamepadMouse_" + format + ".png");
            contentValues.put("mime_type", "image/png");
            contentValues.put("relative_path", "DCIM/Screenshots");
            contentValues.put("date_added", Long.valueOf(System.currentTimeMillis() / 1000));
            Uri insert = getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues);
            if (insert != null && (openOutputStream = getContentResolver().openOutputStream(insert)) != null) {
                try {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, openOutputStream);
                    openOutputStream.close();
                    return true;
                } finally {
                }
            }
            return false;
        } catch (Exception e) {
            Log.e("MouseService", "Failed to save screenshot to MediaStore", e);
            return false;
        }
    }

    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r2v2, types: [java.util.List] */
    /* JADX WARN: Type inference failed for: r2v3 */
    /* JADX WARN: Type inference failed for: r2v4, types: [java.util.List] */
    /* JADX WARN: Type inference failed for: r2v6, types: [java.util.ArrayList] */
    /* renamed from: W */
    public final ma0 m2144W(String str) {
        ?? m7761r;
        SharedPreferences sharedPreferences = this.f4111M;
        if (sharedPreferences != null) {
            String str2 = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
            String string = sharedPreferences.getString("pref_mapping_x_" + str + "_value", RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED);
            if (string != null) {
                str2 = string;
            }
            String[] strArr = {","};
            String str3 = strArr[0];
            if (str3.length() == 0) {
                List asList = Arrays.asList(strArr);
                asList.getClass();
                lh0 lh0Var = new lh0(new C0455il(str2, new dk0(asList)));
                m7761r = new ArrayList(AbstractC0521ke.m4717Y(lh0Var));
                Iterator it = lh0Var.iterator();
                while (true) {
                    C0419hl c0419hl = (C0419hl) it;
                    if (!c0419hl.hasNext()) {
                        break;
                    }
                    C0245cx c0245cx = (C0245cx) c0419hl.next();
                    c0245cx.getClass();
                    m7761r.add(str2.subSequence(c0245cx.f4325n, c0245cx.f4326o + 1).toString());
                }
            } else {
                int m2911U = ek0.m2911U(str2, str3, 0, false);
                if (m2911U != -1) {
                    ArrayList arrayList = new ArrayList(10);
                    int i = 0;
                    do {
                        arrayList.add(str2.subSequence(i, m2911U).toString());
                        i = str3.length() + m2911U;
                        m2911U = ek0.m2911U(str2, str3, i, false);
                    } while (m2911U != -1);
                    arrayList.add(str2.subSequence(i, str2.length()).toString());
                    m7761r = arrayList;
                } else {
                    m7761r = tq1.m7761r(str2.toString());
                }
            }
            if (m7761r.size() == 2) {
                try {
                    return new ma0(Float.valueOf(Float.parseFloat((String) m7761r.get(0))), Float.valueOf(Float.parseFloat((String) m7761r.get(1))));
                } catch (Exception unused) {
                    return null;
                }
            }
            return null;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: Y */
    public final void m2145Y() {
        boolean z;
        ImageView imageView;
        ViewPropertyAnimator animate;
        ViewPropertyAnimator alpha;
        ViewPropertyAnimator duration;
        if (this.f4178q != null) {
            z = true;
        } else {
            z = false;
        }
        Log.i("MouseService", "showBlackScreen() called. View exists: " + z);
        try {
            PowerManager.WakeLock wakeLock = this.f4184s;
            if (wakeLock != null && !wakeLock.isHeld()) {
                Log.d("MouseService", "Acquiring WakeLock to wake screen");
                PowerManager.WakeLock wakeLock2 = this.f4184s;
                if (wakeLock2 != null) {
                    wakeLock2.acquire(3000L);
                }
            }
        } catch (Exception e) {
            Log.e("MouseService", "WakeLock error: " + e.getMessage());
        }
        FrameLayout frameLayout = this.f4178q;
        if (frameLayout != null) {
            frameLayout.setEnabled(true);
            frameLayout.setClickable(true);
            frameLayout.setFocusable(true);
            if (frameLayout.getVisibility() != 0) {
                Log.i("MouseService", "Showing Black Screen Overlay");
                frameLayout.setVisibility(0);
                if (!this.f4087E) {
                    registerReceiver(this.f4093G, new IntentFilter("android.intent.action.BATTERY_CHANGED"));
                    this.f4087E = true;
                }
                ViewGroup.LayoutParams layoutParams = frameLayout.getLayoutParams();
                layoutParams.getClass();
                WindowManager.LayoutParams layoutParams2 = (WindowManager.LayoutParams) layoutParams;
                layoutParams2.screenBrightness = 0.1f;
                try {
                    Object systemService = frameLayout.getContext().getSystemService("window");
                    systemService.getClass();
                    ((WindowManager) systemService).updateViewLayout(frameLayout, layoutParams2);
                } catch (Exception unused) {
                }
                frameLayout.animate().alpha(1.0f).setDuration(500L).start();
                Display display = this.f4199x;
                if (display != null && display.getDisplayId() == 0 && (imageView = this.f4172o) != null && (animate = imageView.animate()) != null && (alpha = animate.alpha(0.0f)) != null && (duration = alpha.setDuration(500L)) != null) {
                    duration.start();
                }
            }
        }
    }

    /* renamed from: Z */
    public final void m2146Z(String str) {
        this.f4096H.post(new RunnableC0698p6(this, 6, str));
    }

    /* renamed from: a */
    public final void m2147a(int i) {
        try {
            if (!Settings.System.canWrite(this)) {
                Log.w("MouseService", "Cannot adjust brightness: WRITE_SETTINGS permission not granted");
                return;
            }
            ContentResolver contentResolver = getContentResolver();
            int m5054i = lo0.m5054i(Settings.System.getInt(contentResolver, "screen_brightness") + i, 0, 255);
            Settings.System.putInt(contentResolver, "screen_brightness", m5054i);
            long currentTimeMillis = System.currentTimeMillis();
            if (currentTimeMillis - this.f4079B0 > 500) {
                this.f4096H.post(new q60(m5054i, this));
                this.f4079B0 = currentTimeMillis;
            }
            if (Settings.System.getInt(contentResolver, "screen_brightness_mode") == 1) {
                Settings.System.putInt(contentResolver, "screen_brightness_mode", 0);
            }
        } catch (Exception e) {
            Log.e("MouseService", "Failed to adjust brightness: " + e.getMessage());
        }
    }

    /* renamed from: a0 */
    public final void m2148a0(int i, int i2, int i3) {
        this.f4164k1 = i;
        this.f4166l1 = i2;
        this.f4168m1 = i3;
        this.f4171n1 = true;
        this.f4174o1 = 0L;
        long currentTimeMillis = System.currentTimeMillis();
        this.f4177p1 = currentTimeMillis;
        if (i3 == 2) {
            this.f4180q1 = currentTimeMillis;
        }
        m2131H(i, i2);
        s60 s60Var = this.f4077A1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        s60 s60Var2 = this.f4207z1;
        handler.removeCallbacks(s60Var2);
        handler.postDelayed(s60Var2, this.f4121P0);
    }

    /* renamed from: b */
    public final void m2149b() {
        boolean z;
        boolean z2;
        Character ch;
        if (this.f4082C0) {
            boolean z3 = this.f4138X0;
            int i = 1;
            if (!this.f4134V0 && !this.f4136W0) {
                z = false;
            } else {
                z = true;
            }
            if (z3 != z) {
                z2 = true;
            } else {
                z2 = false;
            }
            C0950w c0950w = this.f4103J0;
            if (c0950w.f17376a != 0) {
                c0950w.f17376a = 0;
                ch = '\'';
            } else {
                if (z2) {
                    i = 2;
                }
                c0950w.f17376a = i;
                ch = null;
            }
            if (ch != null) {
                char charValue = ch.charValue();
                if (this.f4082C0) {
                    this.f4100I0.m5202c(charValue);
                    m2166l();
                }
            } else if (c0950w.f17376a == 2 && this.f4134V0 && !this.f4138X0) {
                this.f4134V0 = false;
                m2139Q();
            }
            C1059yy c1059yy = this.f4088E0;
            if (c1059yy != null) {
                c1059yy.setAccentPending(c0950w.f17376a);
            }
        }
    }

    /* renamed from: b0 */
    public final void m2150b0(float f, float f2) {
        Display display;
        this.f4182r0 = System.currentTimeMillis();
        Path path = new Path();
        path.moveTo(f, f2);
        float[] fArr = this.f4153f0;
        fArr[0] = f;
        fArr[1] = f2;
        try {
            this.f4155g0 = AbstractC0185c0.m1354d(path);
            GestureDescription.Builder builder = new GestureDescription.Builder();
            if (Build.VERSION.SDK_INT >= 30 && (display = this.f4199x) != null) {
                builder.setDisplayId(display.getDisplayId());
            }
            GestureDescription.StrokeDescription strokeDescription = this.f4155g0;
            strokeDescription.getClass();
            builder.addStroke(strokeDescription);
            dispatchGesture(builder.build(), null, null);
        } catch (Exception e) {
            Log.e("MouseService", "Failed to start drag: " + e.getMessage());
            this.f4155g0 = null;
        }
    }

    /* renamed from: c */
    public final void m2151c(List list) {
        int i;
        SparseArray windowsOnAllDisplays;
        ArrayList arrayList = new ArrayList();
        Display display = this.f4199x;
        if (display != null) {
            i = display.getDisplayId();
        } else {
            i = 0;
        }
        if (Build.VERSION.SDK_INT >= 30) {
            windowsOnAllDisplays = getWindowsOnAllDisplays();
            windowsOnAllDisplays.getClass();
            List list2 = (List) windowsOnAllDisplays.get(i);
            if (list2 != null) {
                arrayList.addAll(list2);
            }
        } else {
            List<AccessibilityWindowInfo> windows = getWindows();
            if (windows != null) {
                arrayList.addAll(windows);
            }
        }
        int size = arrayList.size();
        for (int i2 = 0; i2 < size; i2++) {
            AccessibilityNodeInfo root = ((AccessibilityWindowInfo) arrayList.get(i2)).getRoot();
            if (root != null) {
                AccessibilityNodeInfo m2123x = m2123x(root, list);
                if (m2123x != null) {
                    Log.i("MouseService", "Found window action node after opening handle: " + ((Object) m2123x.getContentDescription()));
                    this.f4076A0 = true;
                    this.f4079B0 = System.currentTimeMillis();
                    m2123x.performAction(16);
                    m2123x.recycle();
                    root.recycle();
                    return;
                }
                root.recycle();
            }
        }
        Log.w("MouseService", "Still couldn't find window action node after clicking handle.");
    }

    /* renamed from: c0 */
    public final void m2152c0(float f, float f2) {
        GestureDescription.StrokeDescription continueStroke;
        Display display;
        if (this.f4155g0 == null) {
            return;
        }
        int i = Build.VERSION.SDK_INT;
        if (i >= 26) {
            try {
                Path path = new Path();
                float[] fArr = this.f4153f0;
                path.moveTo(fArr[0], fArr[1]);
                path.lineTo(f, f2);
                GestureDescription.StrokeDescription strokeDescription = this.f4155g0;
                strokeDescription.getClass();
                continueStroke = strokeDescription.continueStroke(path, 0L, 50L, false);
                this.f4155g0 = null;
                this.f4182r0 = System.currentTimeMillis();
                GestureDescription.Builder builder = new GestureDescription.Builder();
                if (i >= 30 && (display = this.f4199x) != null) {
                    builder.setDisplayId(display.getDisplayId());
                }
                builder.addStroke(continueStroke);
                dispatchGesture(builder.build(), null, null);
                return;
            } catch (Exception e) {
                Log.e("MouseService", "Failed to stop drag: " + e.getMessage());
                this.f4155g0 = null;
                return;
            }
        }
        m2174q(f, f2);
    }

    /* renamed from: d */
    public final Bitmap m2153d(int i) {
        int parseColor;
        if (this.f4139Y != null && xl3.m8871b(this.f4141Z, this.f4137X)) {
            Bitmap bitmap = this.f4139Y;
            bitmap.getClass();
            return bitmap;
        }
        Path path = new Path();
        path.moveTo(8.3f, 2.6f);
        path.lineTo(2.6f, 8.3f);
        path.lineTo(2.2f, 16.699999f);
        path.lineTo(77.2f, 218.9f);
        path.lineTo(82.399994f, 226.4f);
        path.lineTo(93.6f, 227.29999f);
        path.lineTo(99.700005f, 220.3f);
        path.lineTo(127.9f, 129.79999f);
        path.lineTo(220.3f, 99.700005f);
        path.lineTo(226.90001f, 94.6f);
        path.lineTo(227.8f, 85.200005f);
        path.lineTo(218.9f, 77.2f);
        path.lineTo(18.099998f, 2.6f);
        path.close();
        if ((Color.blue(i) * 0.114f) + (Color.green(i) * 0.587f) + (Color.red(i) * 0.299f) < 128.0f) {
            parseColor = -1;
        } else {
            parseColor = Color.parseColor("#1A1A1A");
        }
        Bitmap createBitmap = Bitmap.createBitmap(240, 240, Bitmap.Config.ARGB_8888);
        createBitmap.getClass();
        Canvas canvas = new Canvas(createBitmap);
        Paint paint = new Paint();
        paint.setAntiAlias(true);
        paint.setColor(i);
        paint.setStyle(Paint.Style.FILL);
        Paint paint2 = new Paint();
        paint2.setAntiAlias(true);
        paint2.setColor(parseColor);
        paint2.setStyle(Paint.Style.STROKE);
        paint2.setStrokeWidth(3.5f);
        paint2.setStrokeJoin(Paint.Join.ROUND);
        paint2.setStrokeCap(Paint.Cap.ROUND);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, paint2);
        this.f4139Y = createBitmap;
        this.f4141Z = this.f4137X;
        return createBitmap;
    }

    /* renamed from: d0 */
    public final void m2154d0(Integer num) {
        boolean z;
        if (this.f4190u != null) {
            z = true;
        } else {
            z = false;
        }
        this.f4190u = null;
        this.f4096H.removeCallbacks(this.f4110L1);
        if (z && num != null) {
            m2146Z(m2126B(num.intValue(), new Object[0]));
        }
    }

    /* renamed from: e0 */
    public final void m2155e0() {
        Display[] displays;
        boolean z;
        Set set;
        DisplayManager displayManager = this.f4196w;
        if (displayManager != null && (displays = displayManager.getDisplays()) != null) {
            if (db0.m2408b() && !this.f4090F) {
                z = true;
            } else {
                z = false;
            }
            ArrayList arrayList = new ArrayList();
            for (Display display : displays) {
                if (display.getState() == 2 && (display.getDisplayId() == 0 || z)) {
                    arrayList.add(display);
                }
            }
            ArrayList arrayList2 = new ArrayList(AbstractC0521ke.m4717Y(arrayList));
            int size = arrayList.size();
            int i = 0;
            while (i < size) {
                Object obj = arrayList.get(i);
                i++;
                arrayList2.add(Integer.valueOf(((Display) obj).getDisplayId()));
            }
            Set m4164d0 = AbstractC0449ie.m4164d0(arrayList2);
            LinkedHashMap linkedHashMap = this.f4175p;
            Set keySet = linkedHashMap.keySet();
            keySet.getClass();
            if (m4164d0.isEmpty()) {
                set = AbstractC0449ie.m4164d0(keySet);
            } else {
                LinkedHashSet linkedHashSet = new LinkedHashSet();
                for (Object obj2 : keySet) {
                    if (!m4164d0.contains(obj2)) {
                        linkedHashSet.add(obj2);
                    }
                }
                set = linkedHashSet;
            }
            Iterator it = set.iterator();
            while (it.hasNext()) {
                View view = (View) linkedHashMap.remove(Integer.valueOf(((Number) it.next()).intValue()));
                if (view != null) {
                    try {
                        Object systemService = view.getContext().getSystemService("window");
                        systemService.getClass();
                        ((WindowManager) systemService).removeView(view);
                    } catch (Exception unused) {
                    }
                }
            }
            for (Display display2 : displays) {
                if (display2.getState() == 2 && ((display2.getDisplayId() == 0 || z) && !linkedHashMap.containsKey(Integer.valueOf(display2.getDisplayId())))) {
                    Context createDisplayContext = createDisplayContext(display2);
                    if (Build.VERSION.SDK_INT >= 30) {
                        try {
                            createDisplayContext = createDisplayContext.createWindowContext(2032, null);
                        } catch (Exception unused2) {
                        }
                    }
                    Object systemService2 = createDisplayContext.getSystemService("window");
                    systemService2.getClass();
                    WindowManager windowManager = (WindowManager) systemService2;
                    t60 t60Var = new t60(createDisplayContext, this);
                    WindowManager.LayoutParams layoutParams = new WindowManager.LayoutParams(15, 15, 2032, 262432, -3);
                    layoutParams.gravity = 8388659;
                    layoutParams.x = 0;
                    layoutParams.y = 0;
                    if (!this.f4163k0) {
                        layoutParams.flags |= 8;
                    }
                    try {
                        windowManager.addView(t60Var, layoutParams);
                        linkedHashMap.put(Integer.valueOf(display2.getDisplayId()), t60Var);
                    } catch (Exception e) {
                        Log.e("MouseService", "Error adding focusView to display " + display2.getDisplayId() + ": " + e.getMessage());
                    }
                }
            }
        }
    }

    /* renamed from: f0 */
    public final void m2156f0(Display display, String str) {
        int i;
        if (display != null) {
            i = display.getDisplayId();
        } else {
            i = 0;
        }
        try {
            Log.i("MouseService", "Screenshot stage=" + str + " displayId=" + i);
            takeScreenshot(i, this.f4104J1, new y60(this, display, str));
        } catch (Exception e) {
            Log.e("MouseService", "takeScreenshot call failed, falling back to system screenshot", e);
            performGlobalAction(9);
        }
    }

    /* renamed from: g */
    public final void m2157g() {
        this.f4164k1 = 0;
        this.f4166l1 = 0;
        this.f4168m1 = 0;
        this.f4171n1 = false;
        this.f4174o1 = 0L;
        s60 s60Var = this.f4207z1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        handler.removeCallbacks(this.f4077A1);
    }

    /* renamed from: g0 */
    public final void m2158g0() {
        if (this.f4082C0) {
            m2177t();
            ArrayList m2176s = m2176s();
            if (m2176s.size() >= 2) {
                EnumC0985wy enumC0985wy = (EnumC0985wy) m2176s.get((m2176s.indexOf(this.f4106K0) + 1) % m2176s.size());
                this.f4106K0 = enumC0985wy;
                this.f4103J0.f17376a = 0;
                C1059yy c1059yy = this.f4088E0;
                if (c1059yy != null) {
                    c1059yy.setLang(enumC0985wy);
                }
                C1059yy c1059yy2 = this.f4088E0;
                if (c1059yy2 != null) {
                    c1059yy2.setAccentPending(0);
                }
                this.f4096H.postDelayed(new n60(this, 6), 120L);
                SharedPreferences sharedPreferences = this.f4111M;
                if (sharedPreferences != null) {
                    if (sharedPreferences.getBoolean("pref_haptic_feedback", true)) {
                        m2171n0(40L);
                        return;
                    }
                    return;
                }
                xl3.m8890u("sharedPrefs");
                throw null;
            }
        }
    }

    /* renamed from: h */
    public final void m2159h() {
        this.f4148c1 = 0;
        this.f4150d1 = 0;
        this.f4152e1 = 0;
        this.f4154f1 = 0L;
        this.f4156g1 = false;
        this.f4158h1 = 0.0f;
        s60 s60Var = this.f4201x1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        handler.removeCallbacks(this.f4204y1);
    }

    /* renamed from: h0 */
    public final void m2160h0() {
        Display display = this.f4199x;
        if (display != null) {
            int displayId = display.getDisplayId();
            this.f4182r0 = System.currentTimeMillis();
            Path path = new Path();
            if (displayId == 0) {
                path.moveTo(0.0f, 200.0f);
            } else {
                path.moveTo(this.f4081C / 2.0f, 5.0f);
            }
            GestureDescription.Builder builder = new GestureDescription.Builder();
            builder.addStroke(new GestureDescription.StrokeDescription(path, 0L, 50L));
            if (Build.VERSION.SDK_INT >= 30) {
                builder.setDisplayId(displayId);
            }
            dispatchGesture(builder.build(), null, null);
        }
    }

    /* renamed from: i */
    public final void m2161i() {
        this.f4183r1 = 0;
        this.f4186s1 = 0;
        this.f4189t1 = false;
        this.f4192u1 = 0L;
        s60 s60Var = this.f4080B1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        handler.removeCallbacks(this.f4083C1);
    }

    /* renamed from: i0 */
    public final void m2162i0() {
        Display[] displays;
        Display display;
        boolean z;
        boolean z2;
        DisplayManager displayManager;
        Display display2;
        float f;
        int i;
        WindowManager windowManager;
        DisplayManager displayManager2 = this.f4196w;
        if (displayManager2 != null && (displays = displayManager2.getDisplays()) != null) {
            if (db0.m2408b() && !this.f4090F) {
                int length = displays.length;
                for (int i2 = 0; i2 < length; i2++) {
                    display = displays[i2];
                    if (display.getDisplayId() != 0 && display.getState() == 2) {
                        break;
                    }
                }
            }
            display = null;
            if (display == null || this.f4205z) {
                DisplayManager displayManager3 = this.f4196w;
                if (displayManager3 != null) {
                    display = displayManager3.getDisplay(0);
                } else {
                    display = null;
                }
            }
            if (display != null) {
                DisplayMetrics displayMetrics = new DisplayMetrics();
                display.getRealMetrics(displayMetrics);
                int i3 = displayMetrics.widthPixels;
                int i4 = displayMetrics.heightPixels;
                if (i3 == this.f4081C && i4 == this.f4084D) {
                    z = false;
                } else {
                    z = true;
                }
                Display display3 = this.f4199x;
                if (display3 != null && display3.getDisplayId() == display.getDisplayId()) {
                    z2 = true;
                } else {
                    z2 = false;
                }
                boolean z3 = !z2;
                if (!z2 || z) {
                    StringBuilder m6826p = AbstractC0783rh.m6826p("Display Update: ID=", display.getDisplayId(), ", Dim=", i3, "x");
                    m6826p.append(i4);
                    m6826p.append(" (ID Changed: ");
                    m6826p.append(z3);
                    m6826p.append(", Dim Changed: ");
                    m6826p.append(z);
                    m6826p.append(")");
                    Log.i("MouseService", m6826p.toString());
                    if (this.f4082C0) {
                        m2163j(false);
                    }
                    if (this.f4190u != null) {
                        Log.i("MouseService", "Repeat click stopped: active display changed");
                        m2154d0(Integer.valueOf(R.string.toast_repeat_stopped_cursor));
                    }
                    try {
                        ImageView imageView = this.f4172o;
                        if (imageView != null && (windowManager = this.f4169n) != null) {
                            windowManager.removeView(imageView);
                        }
                    } catch (Exception unused) {
                    }
                    this.f4172o = null;
                    Iterator it = this.f4175p.entrySet().iterator();
                    while (it.hasNext()) {
                        Map.Entry entry = (Map.Entry) it.next();
                        try {
                            Object systemService = ((View) entry.getValue()).getContext().getSystemService("window");
                            systemService.getClass();
                            ((WindowManager) systemService).removeView((View) entry.getValue());
                        } catch (Exception unused2) {
                        }
                        it.remove();
                    }
                    this.f4199x = display;
                    Context createDisplayContext = createDisplayContext(display);
                    this.f4202y = createDisplayContext;
                    if (Build.VERSION.SDK_INT >= 30) {
                        try {
                            createDisplayContext.getClass();
                            createDisplayContext = createDisplayContext.createWindowContext(2032, null);
                        } catch (Exception unused3) {
                            createDisplayContext = this.f4202y;
                        }
                    }
                    createDisplayContext.getClass();
                    Object systemService2 = createDisplayContext.getSystemService("window");
                    systemService2.getClass();
                    this.f4169n = (WindowManager) systemService2;
                    this.f4081C = i3;
                    this.f4084D = i4;
                    if (!z2) {
                        this.f4075A = i3 / 2.0f;
                        this.f4078B = i4 / 2.0f;
                    } else {
                        this.f4075A = lo0.m5052h(this.f4075A, 0.0f, i3);
                        this.f4078B = lo0.m5052h(this.f4078B, 0.0f, this.f4084D);
                    }
                    m2155e0();
                    if (this.f4172o == null) {
                        Context context = this.f4202y;
                        if (context == null) {
                            context = this;
                        }
                        ImageView imageView2 = new ImageView(context);
                        if (this.f4145b0) {
                            f = 1.0f;
                        } else {
                            f = 0.0f;
                        }
                        imageView2.setAlpha(f);
                        if (this.f4145b0) {
                            i = 0;
                        } else {
                            i = 8;
                        }
                        imageView2.setVisibility(i);
                        this.f4172o = imageView2;
                        m2164j0();
                        int i5 = this.f4120P;
                        WindowManager.LayoutParams layoutParams = new WindowManager.LayoutParams(i5, i5, 2032, 792, -3);
                        layoutParams.gravity = 8388659;
                        layoutParams.x = (int) this.f4075A;
                        layoutParams.y = (int) this.f4078B;
                        this.f4181r = layoutParams;
                        try {
                            WindowManager windowManager2 = this.f4169n;
                            if (windowManager2 != null) {
                                windowManager2.addView(this.f4172o, layoutParams);
                            }
                        } catch (Exception e) {
                            Log.e("MouseService", "Error adding cursorView: " + e.getMessage());
                        }
                    }
                    if (this.f4178q == null && (displayManager = this.f4196w) != null && (display2 = displayManager.getDisplay(0)) != null) {
                        Context createDisplayContext2 = createDisplayContext(display2);
                        if (Build.VERSION.SDK_INT >= 30) {
                            try {
                                createDisplayContext2 = createDisplayContext2.createWindowContext(2032, null);
                            } catch (Exception unused4) {
                            }
                        }
                        Object systemService3 = createDisplayContext2.getSystemService("window");
                        systemService3.getClass();
                        WindowManager windowManager3 = (WindowManager) systemService3;
                        FrameLayout frameLayout = new FrameLayout(createDisplayContext2);
                        frameLayout.setBackgroundColor(-16777216);
                        frameLayout.setAlpha(0.0f);
                        frameLayout.setVisibility(8);
                        LinearLayout linearLayout = new LinearLayout(createDisplayContext2);
                        linearLayout.setOrientation(1);
                        linearLayout.setGravity(17);
                        TextClock textClock = new TextClock(createDisplayContext2);
                        textClock.setFormat12Hour("hh:mm a");
                        textClock.setFormat24Hour("HH:mm");
                        textClock.setTextSize(48.0f);
                        textClock.setTextColor(-7829368);
                        textClock.setGravity(17);
                        TextView textView = new TextView(createDisplayContext2);
                        textView.setTextSize(18.0f);
                        textView.setTextColor(-7829368);
                        textView.setGravity(17);
                        textView.setPadding(0, 16, 0, 0);
                        textView.setTag("batteryView");
                        linearLayout.addView(textClock);
                        linearLayout.addView(textView);
                        frameLayout.addView(linearLayout, new FrameLayout.LayoutParams(-2, -2, 17));
                        TextView textView2 = new TextView(createDisplayContext2);
                        textView2.setText(m2126B(R.string.lockscreen_label, new Object[0]));
                        textView2.setTextSize(14.0f);
                        textView2.setTextColor(-12303292);
                        textView2.setGravity(17);
                        textView2.setPadding(0, 0, 0, 100);
                        frameLayout.addView(textView2, new FrameLayout.LayoutParams(-2, -2, 81));
                        frameLayout.setClickable(true);
                        frameLayout.setFocusable(true);
                        frameLayout.setOnClickListener(new ViewOnClickListenerC0853td(5, this));
                        this.f4178q = frameLayout;
                        WindowManager.LayoutParams layoutParams2 = new WindowManager.LayoutParams(-1, -1, 2032, 6816136, -1);
                        layoutParams2.screenBrightness = 0.1f;
                        try {
                            windowManager3.addView(this.f4178q, layoutParams2);
                        } catch (Exception e2) {
                            Log.e("MouseService", "Error adding black screen view: " + e2.getMessage());
                        }
                    }
                    m2167l0();
                    m2165k0();
                    if (this.f4163k0) {
                        this.f4096H.post(new n60(this, 7));
                    }
                    Display display4 = this.f4199x;
                    if ((display4 == null || display4.getDisplayId() != 0) && this.f4129T && this.f4131U) {
                        Log.i("MouseService", "DeX Detected - Blackout will activate on screen timeout");
                    } else {
                        Log.i("MouseService", "Phone Screen, Service Disabled or Lockscreen Disabled - Hiding Blackout");
                        m2129E();
                    }
                }
            }
        }
    }

    /* renamed from: j */
    public final void m2163j(boolean z) {
        if (!this.f4082C0) {
            return;
        }
        this.f4082C0 = false;
        AccessibilityNodeInfo accessibilityNodeInfo = this.f4113M1;
        if (accessibilityNodeInfo != null) {
            try {
                accessibilityNodeInfo.recycle();
            } catch (Exception unused) {
            }
            this.f4113M1 = null;
        }
        v60 v60Var = this.f4091F0;
        if (v60Var != null) {
            try {
                try {
                    WindowManager windowManager = this.f4094G0;
                    if (windowManager != null) {
                        windowManager.removeView(v60Var);
                    }
                } catch (Exception unused2) {
                }
            } catch (Exception unused3) {
                Object systemService = v60Var.getContext().getSystemService("window");
                systemService.getClass();
                ((WindowManager) systemService).removeView(v60Var);
            }
        }
        this.f4088E0 = null;
        this.f4091F0 = null;
        this.f4094G0 = null;
        this.f4097H0 = null;
        C0575lv c0575lv = this.f4100I0;
        c0575lv.f9697a.setLength(0);
        c0575lv.f9698b.setLength(0);
        c0575lv.f9699c = null;
        c0575lv.f9700d = null;
        c0575lv.f9701e = 0;
        c0575lv.f9702f = 0;
        this.f4103J0.f17376a = 0;
        this.f4134V0 = false;
        this.f4136W0 = false;
        this.f4160i1 = false;
        this.f4162j1 = false;
        m2159h();
        m2157g();
        m2161i();
        s60 s60Var = this.f4086D1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        handler.removeCallbacks(this.f4089E1);
        if (z && this.f4163k0 && this.f4129T) {
            this.f4145b0 = true;
            ImageView imageView = this.f4172o;
            if (imageView != null) {
                imageView.setVisibility(0);
            }
            ImageView imageView2 = this.f4172o;
            if (imageView2 != null) {
                imageView2.setAlpha(1.0f);
            }
        }
        Log.i("MouseService", "Keyboard mode closed");
    }

    /* renamed from: j0 */
    public final void m2164j0() {
        Integer num;
        Bitmap m2121o;
        if (this.f4172o != null) {
            try {
                String str = (String) this.f4101I1.get(this.f4135W);
                if (str != null) {
                    this.f4137X = str;
                    this.f4135W = "custom_color";
                    SharedPreferences sharedPreferences = this.f4111M;
                    if (sharedPreferences != null) {
                        sharedPreferences.edit().putString("pref_cursor_style", "custom_color").putString("pref_cursor_color", str).apply();
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
                if (xl3.m8871b(this.f4135W, "custom")) {
                    File file = new File(getFilesDir(), "custom_cursor.png");
                    if (file.exists() && file.length() > 0 && (m2121o = m2121o(file)) != null) {
                        ImageView imageView = this.f4172o;
                        if (imageView != null) {
                            imageView.setImageBitmap(m2121o);
                            return;
                        }
                        return;
                    }
                    this.f4135W = "orange";
                    SharedPreferences sharedPreferences2 = this.f4111M;
                    if (sharedPreferences2 != null) {
                        sharedPreferences2.edit().putString("pref_cursor_style", "orange").apply();
                        if (file.exists()) {
                            file.delete();
                        }
                        Log.w("MouseService", "Custom cursor file missing or invalid. Resetting to default.");
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
                if (xl3.m8871b(this.f4135W, "custom_color")) {
                    String str2 = this.f4137X;
                    try {
                        if (!ek0.m2914X(str2, "#")) {
                            str2 = "#".concat(str2);
                        }
                        num = Integer.valueOf(Color.parseColor(str2));
                    } catch (Exception unused) {
                        num = null;
                    }
                    if (num != null) {
                        ImageView imageView2 = this.f4172o;
                        if (imageView2 != null) {
                            imageView2.setImageBitmap(m2153d(num.intValue()));
                            return;
                        }
                        return;
                    }
                    this.f4135W = "orange";
                    SharedPreferences sharedPreferences3 = this.f4111M;
                    if (sharedPreferences3 != null) {
                        sharedPreferences3.edit().putString("pref_cursor_style", "orange").apply();
                        Log.w("MouseService", "Custom cursor color '" + this.f4137X + "' is invalid. Resetting to default.");
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
                ImageView imageView3 = this.f4172o;
                if (imageView3 != null) {
                    imageView3.setImageResource(R.drawable.ic_mouse_cursor);
                }
            } catch (Exception e) {
                Log.e("MouseService", "Failed to update cursor appearance", e);
                ImageView imageView4 = this.f4172o;
                if (imageView4 != null) {
                    imageView4.setImageResource(R.drawable.ic_mouse_cursor);
                }
            }
        }
    }

    /* renamed from: k0 */
    public final void m2165k0() {
        WindowManager.LayoutParams layoutParams = this.f4181r;
        if (layoutParams != null) {
            layoutParams.x = (int) this.f4075A;
            layoutParams.y = (int) this.f4078B;
            try {
                WindowManager windowManager = this.f4169n;
                if (windowManager != null) {
                    windowManager.updateViewLayout(this.f4172o, layoutParams);
                }
            } catch (Exception unused) {
            }
        }
    }

    /* renamed from: l */
    public final boolean m2166l() {
        boolean z;
        AccessibilityNodeInfo m2180y;
        AccessibilityNodeInfo accessibilityNodeInfo = this.f4097H0;
        if (accessibilityNodeInfo == null || !this.f4082C0) {
            return false;
        }
        C0575lv c0575lv = this.f4100I0;
        String m5201b = c0575lv.m5201b();
        try {
            Bundle bundle = new Bundle();
            bundle.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", m5201b);
            z = accessibilityNodeInfo.performAction(2097152, bundle);
        } catch (Exception unused) {
            z = false;
        }
        if (!z && (m2180y = m2180y(this.f4142Z0, this.f4144a1, 90.0f)) != null) {
            this.f4097H0 = m2180y;
            try {
                Bundle bundle2 = new Bundle();
                bundle2.putCharSequence("ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE", m5201b);
                z = m2180y.performAction(2097152, bundle2);
            } catch (Exception unused2) {
                z = false;
            }
            accessibilityNodeInfo = m2180y;
        }
        if (z && Build.VERSION.SDK_INT >= 33) {
            try {
                int m5054i = lo0.m5054i(c0575lv.m5207h().length() + c0575lv.f9702f, 0, m5201b.length());
                Bundle bundle3 = new Bundle();
                bundle3.putInt("ACTION_ARGUMENT_SELECTION_START_INT", m5054i);
                bundle3.putInt("ACTION_ARGUMENT_SELECTION_END_INT", m5054i);
                accessibilityNodeInfo.performAction(131072, bundle3);
            } catch (Exception unused3) {
            }
        }
        if (!z) {
            m2146Z(m2126B(R.string.keyboard_unsupported_field, new Object[0]));
            m2163j(true);
        }
        return z;
    }

    /* renamed from: l0 */
    public final void m2167l0() {
        WindowManager.LayoutParams layoutParams = this.f4181r;
        if (layoutParams != null) {
            int i = this.f4120P;
            Display display = this.f4199x;
            if (display == null || display.getDisplayId() != 0) {
                i = (int) (this.f4120P * 0.4f);
            }
            layoutParams.width = i;
            layoutParams.height = i;
            try {
                WindowManager windowManager = this.f4169n;
                if (windowManager != null) {
                    windowManager.updateViewLayout(this.f4172o, layoutParams);
                }
            } catch (Exception e) {
                Log.e("MouseService", "Failed to update cursor size: " + e.getMessage());
            }
        }
    }

    /* renamed from: m */
    public final boolean m2168m(int i, int i2) {
        Integer valueOf = Integer.valueOf(i);
        HashSet hashSet = this.f4194v0;
        if (!hashSet.contains(valueOf)) {
            return false;
        }
        if (i2 == 1) {
            hashSet.remove(Integer.valueOf(i));
        }
        return true;
    }

    /* renamed from: m0 */
    public final void m2169m0() {
        AccessibilityServiceInfo serviceInfo = getServiceInfo();
        if (serviceInfo == null) {
            return;
        }
        boolean z = this.f4129T;
        int i = serviceInfo.flags;
        if (z) {
            serviceInfo.flags = i | 32;
        } else {
            serviceInfo.flags = i & (-33);
        }
        setServiceInfo(serviceInfo);
        Log.i("MouseService", "Service flags updated. MouseEnabled: " + this.f4129T);
    }

    /* renamed from: n */
    public final void m2170n(float f, float f2) {
        int i;
        GestureDescription.StrokeDescription continueStroke;
        Display display;
        float[] fArr = this.f4153f0;
        if (this.f4155g0 != null) {
            long currentTimeMillis = System.currentTimeMillis();
            if (currentTimeMillis >= this.f4157h0 && (i = Build.VERSION.SDK_INT) >= 26) {
                try {
                    if (Math.abs(fArr[0] - f) >= 1.0f || Math.abs(fArr[1] - f2) >= 1.0f) {
                        Path path = new Path();
                        path.moveTo(fArr[0], fArr[1]);
                        path.lineTo(f, f2);
                        GestureDescription.StrokeDescription strokeDescription = this.f4155g0;
                        strokeDescription.getClass();
                        continueStroke = strokeDescription.continueStroke(path, 0L, 50L, true);
                        this.f4155g0 = continueStroke;
                        fArr[0] = f;
                        fArr[1] = f2;
                        this.f4182r0 = System.currentTimeMillis();
                        GestureDescription.Builder builder = new GestureDescription.Builder();
                        if (i >= 30 && (display = this.f4199x) != null) {
                            builder.setDisplayId(display.getDisplayId());
                        }
                        GestureDescription.StrokeDescription strokeDescription2 = this.f4155g0;
                        strokeDescription2.getClass();
                        builder.addStroke(strokeDescription2);
                        dispatchGesture(builder.build(), null, null);
                        this.f4157h0 = currentTimeMillis + 40;
                    }
                } catch (Exception e) {
                    Log.e("MouseService", "Failed to continue drag: " + e.getMessage());
                }
            }
        }
    }

    /* renamed from: n0 */
    public final void m2171n0(long j) {
        VibrationEffect createOneShot;
        if (db0.m2408b()) {
            try {
                SharedPreferences sharedPreferences = this.f4111M;
                if (sharedPreferences != null) {
                    int i = sharedPreferences.getInt("pref_vibration_intensity", 255);
                    if (i > 0) {
                        for (int i2 : InputDevice.getDeviceIds()) {
                            InputDevice device = InputDevice.getDevice(i2);
                            if (device != null && (device.getSources() & 1025) == 1025) {
                                Vibrator vibrator = device.getVibrator();
                                if (vibrator.hasVibrator()) {
                                    if (Build.VERSION.SDK_INT >= 26) {
                                        createOneShot = VibrationEffect.createOneShot(j, i);
                                        vibrator.vibrate(createOneShot);
                                    } else {
                                        vibrator.vibrate(j);
                                    }
                                }
                            }
                        }
                        return;
                    }
                    return;
                }
                xl3.m8890u("sharedPrefs");
                throw null;
            } catch (Exception e) {
                Log.e("MouseService", "Failed to vibrate: " + e.getMessage());
            }
        }
    }

    /* renamed from: o0 */
    public final void m2172o0(int i) {
        C0575lv c0575lv = this.f4100I0;
        if (i > 0) {
            StringBuilder sb = c0575lv.f9697a;
            if (c0575lv.m5204e()) {
                c0575lv.m5203d();
            } else if (c0575lv.f9702f < sb.length()) {
                int i2 = c0575lv.f9702f;
                while (i2 < sb.length() && gd1.m3397k(sb.charAt(i2))) {
                    i2++;
                }
                while (i2 < sb.length() && !gd1.m3397k(sb.charAt(i2))) {
                    i2++;
                }
                c0575lv.f9702f = i2;
            } else {
                return;
            }
        } else {
            StringBuilder sb2 = c0575lv.f9697a;
            c0575lv.m5203d();
            int i3 = c0575lv.f9702f;
            if (i3 <= 0) {
                return;
            }
            while (i3 > 0 && gd1.m3397k(sb2.charAt(i3 - 1))) {
                i3--;
            }
            while (i3 > 0 && !gd1.m3397k(sb2.charAt(i3 - 1))) {
                i3--;
            }
            c0575lv.f9702f = i3;
        }
        m2166l();
        m2138P();
    }

    @Override // android.app.Service
    public final void onDestroy() {
        PowerManager.WakeLock wakeLock;
        WindowManager windowManager;
        LinkedHashMap linkedHashMap = this.f4175p;
        super.onDestroy();
        if (this.f4082C0) {
            m2163j(false);
        }
        this.f4190u = null;
        s60 s60Var = this.f4110L1;
        Handler handler = this.f4096H;
        handler.removeCallbacks(s60Var);
        this.f4194v0.clear();
        ToneGenerator toneGenerator = this.f4132U0;
        if (toneGenerator != null) {
            toneGenerator.release();
        }
        this.f4132U0 = null;
        SoundPool soundPool = this.f4195v1;
        if (soundPool != null) {
            soundPool.release();
        }
        this.f4195v1 = null;
        this.f4198w1 = 0;
        try {
            unregisterReceiver(this.f4092F1);
        } catch (Exception unused) {
        }
        SharedPreferences sharedPreferences = this.f4111M;
        if (sharedPreferences != null) {
            sharedPreferences.unregisterOnSharedPreferenceChangeListener(this.f4098H1);
        }
        DisplayManager displayManager = this.f4196w;
        if (displayManager != null) {
            displayManager.unregisterDisplayListener(this.f4095G1);
        }
        handler.removeCallbacks(this.f4107K1);
        try {
            for (View view : linkedHashMap.values()) {
                try {
                    Object systemService = view.getContext().getSystemService("window");
                    systemService.getClass();
                    ((WindowManager) systemService).removeView(view);
                } catch (Exception unused2) {
                }
            }
            linkedHashMap.clear();
            ImageView imageView = this.f4172o;
            if (imageView != null && (windowManager = this.f4169n) != null) {
                windowManager.removeView(imageView);
            }
            FrameLayout frameLayout = this.f4178q;
            if (frameLayout != null) {
                Object systemService2 = frameLayout.getContext().getSystemService("window");
                systemService2.getClass();
                ((WindowManager) systemService2).removeView(frameLayout);
            }
        } catch (Exception unused3) {
        }
        PowerManager.WakeLock wakeLock2 = this.f4184s;
        if (wakeLock2 != null && wakeLock2.isHeld() && (wakeLock = this.f4184s) != null) {
            wakeLock.release();
        }
        if (this.f4087E) {
            try {
                unregisterReceiver(this.f4093G);
            } catch (Exception unused4) {
            }
            this.f4087E = false;
        }
    }

    /* JADX WARN: Code restructure failed: missing block: B:62:0x010f, code lost:
    
        if (r14.getAction() == 1) goto L82;
     */
    @Override // android.accessibilityservice.AccessibilityService
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public final boolean onKeyEvent(KeyEvent keyEvent) {
        boolean z;
        boolean z2;
        boolean z3;
        boolean z4;
        boolean z5;
        boolean z6;
        keyEvent.getClass();
        int keyCode = keyEvent.getKeyCode();
        int action = keyEvent.getAction();
        int source = keyEvent.getSource();
        StringBuilder m6826p = AbstractC0783rh.m6826p("Global KeyEvent received: code=", keyCode, ", action=", action, ", source=");
        m6826p.append(source);
        Log.d("MouseService_GlobalKey", m6826p.toString());
        if ((keyEvent.getSource() & 1025) != 1025 && (keyEvent.getSource() & 16777232) != 16777232) {
            z = false;
        } else {
            z = true;
        }
        if (keyEvent.getKeyCode() == this.f4170n0) {
            z2 = true;
        } else {
            z2 = false;
        }
        if (keyEvent.getKeyCode() == 106) {
            z3 = true;
        } else {
            z3 = false;
        }
        if (keyEvent.getKeyCode() == 110) {
            z4 = true;
        } else {
            z4 = false;
        }
        long j = this.f4176p0 * 100;
        if (this.f4167m0 && j > 0) {
            z5 = true;
        } else {
            z5 = false;
        }
        if (z && !this.f4163k0 && z2) {
            int action2 = keyEvent.getAction();
            n60 n60Var = this.f4188t0;
            Handler handler = this.f4185s0;
            if (action2 == 0) {
                if (!this.f4179q0) {
                    if (z5) {
                        handler.removeCallbacks(n60Var);
                        handler.postDelayed(n60Var, j);
                        this.f4179q0 = true;
                        Log.d("MouseService", "Wake key DOWN passed through (waiting for " + j + "ms long press)");
                        return false;
                    }
                }
                return true;
            }
            if (keyEvent.getAction() == 1 && this.f4179q0) {
                handler.removeCallbacks(n60Var);
                this.f4179q0 = false;
                Log.d("MouseService", "Wake key UP passed through (long press cancelled)");
                return false;
            }
        }
        boolean z7 = this.f4163k0;
        if ((!z7 && ((z2 && this.f4167m0 && !z5) || z4)) || (z7 && ((z3 && this.f4167m0) || z4))) {
            z6 = true;
        } else {
            z6 = false;
        }
        if (z && z6) {
            if (keyEvent.getAction() == 0) {
                if (!this.f4163k0) {
                    SharedPreferences sharedPreferences = this.f4111M;
                    if (sharedPreferences != null) {
                        if (sharedPreferences.getBoolean("pref_haptic_feedback", true)) {
                            m2171n0(50L);
                        }
                        m2117X(this, true, false, 6);
                        m2142U();
                        return true;
                    }
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            }
        }
        if (!z || !this.f4163k0 || !m2127C(keyEvent)) {
            return super.onKeyEvent(keyEvent);
        }
        return true;
    }

    @Override // android.accessibilityservice.AccessibilityService
    public final void onServiceConnected() {
        Log.i("MouseService", "onServiceConnected - Configuring service");
        db0.m2407a(this);
        AccessibilityServiceInfo accessibilityServiceInfo = new AccessibilityServiceInfo();
        accessibilityServiceInfo.eventTypes = -1;
        accessibilityServiceInfo.feedbackType = 16;
        accessibilityServiceInfo.notificationTimeout = 100L;
        accessibilityServiceInfo.flags = 98;
        setServiceInfo(accessibilityServiceInfo);
        SharedPreferences sharedPreferences = getSharedPreferences("GamepadMousePrefs", 0);
        sharedPreferences.getClass();
        this.f4111M = sharedPreferences;
        sharedPreferences.registerOnSharedPreferenceChangeListener(this.f4098H1);
        SharedPreferences sharedPreferences2 = this.f4111M;
        if (sharedPreferences2 != null) {
            this.f4129T = sharedPreferences2.getBoolean("pref_mouse_enabled", true);
            SharedPreferences sharedPreferences3 = this.f4111M;
            if (sharedPreferences3 != null) {
                this.f4131U = sharedPreferences3.getBoolean("pref_dex_lockscreen_enabled", false);
                SharedPreferences sharedPreferences4 = this.f4111M;
                if (sharedPreferences4 != null) {
                    this.f4090F = sharedPreferences4.getBoolean("pref_force_mirroring", false);
                    if (this.f4111M != null) {
                        this.f4114N = r0.getInt("pref_mouse_speed", 50);
                        if (this.f4111M != null) {
                            this.f4117O = r0.getInt("pref_dex_speed", 35);
                            SharedPreferences sharedPreferences5 = this.f4111M;
                            if (sharedPreferences5 != null) {
                                this.f4120P = sharedPreferences5.getInt("pref_mouse_size", 100);
                                if (this.f4111M != null) {
                                    this.f4123Q = r0.getInt("pref_mouse_sensitivity", 20) / 10.0f;
                                    SharedPreferences sharedPreferences6 = this.f4111M;
                                    if (sharedPreferences6 != null) {
                                        this.f4133V = sharedPreferences6.getInt("pref_mouse_timeout", 0);
                                        SharedPreferences sharedPreferences7 = this.f4111M;
                                        if (sharedPreferences7 != null) {
                                            this.f4167m0 = sharedPreferences7.getBoolean("pref_l3_toggle_enabled", true);
                                            SharedPreferences sharedPreferences8 = this.f4111M;
                                            if (sharedPreferences8 != null) {
                                                this.f4170n0 = sharedPreferences8.getInt("pref_toggle_keycode", 106);
                                                SharedPreferences sharedPreferences9 = this.f4111M;
                                                if (sharedPreferences9 != null) {
                                                    this.f4173o0 = sharedPreferences9.getBoolean("pref_swap_ab_buttons", false);
                                                    if (this.f4111M != null) {
                                                        this.f4125R = r0.getInt("pref_scroll_speed", 100) / 50.0f;
                                                        if (this.f4111M != null) {
                                                            this.f4127S = r0.getInt("pref_deadzone", 15) / 100.0f;
                                                            SharedPreferences sharedPreferences10 = this.f4111M;
                                                            if (sharedPreferences10 != null) {
                                                                this.f4176p0 = sharedPreferences10.getInt("pref_l3_long_press_duration", 0);
                                                                SharedPreferences sharedPreferences11 = this.f4111M;
                                                                if (sharedPreferences11 != null) {
                                                                    String str = "orange";
                                                                    String string = sharedPreferences11.getString("pref_cursor_style", "orange");
                                                                    if (string != null) {
                                                                        str = string;
                                                                    }
                                                                    this.f4135W = str;
                                                                    SharedPreferences sharedPreferences12 = this.f4111M;
                                                                    if (sharedPreferences12 != null) {
                                                                        String str2 = "#FFA000";
                                                                        String string2 = sharedPreferences12.getString("pref_cursor_color", "#FFA000");
                                                                        if (string2 != null) {
                                                                            str2 = string2;
                                                                        }
                                                                        this.f4137X = str2;
                                                                        SharedPreferences sharedPreferences13 = this.f4111M;
                                                                        if (sharedPreferences13 != null) {
                                                                            this.f4085D0 = sharedPreferences13.getBoolean("pref_keyboard_enabled", true);
                                                                            SharedPreferences sharedPreferences14 = this.f4111M;
                                                                            if (sharedPreferences14 != null) {
                                                                                this.f4109L0 = sharedPreferences14.getBoolean("pref_kb_lang_en", true);
                                                                                SharedPreferences sharedPreferences15 = this.f4111M;
                                                                                if (sharedPreferences15 != null) {
                                                                                    this.f4112M0 = sharedPreferences15.getBoolean("pref_kb_lang_ko", true);
                                                                                    SharedPreferences sharedPreferences16 = this.f4111M;
                                                                                    if (sharedPreferences16 != null) {
                                                                                        this.f4115N0 = sharedPreferences16.getBoolean("pref_kb_lang_es", false);
                                                                                        if (this.f4111M != null) {
                                                                                            this.f4118O0 = r0.getInt("pref_kb_nav_interval", 150);
                                                                                            if (this.f4111M != null) {
                                                                                                this.f4121P0 = r0.getInt("pref_kb_nav_delay", 300);
                                                                                                SharedPreferences sharedPreferences17 = this.f4111M;
                                                                                                if (sharedPreferences17 != null) {
                                                                                                    this.f4124Q0 = sharedPreferences17.getBoolean("pref_kb_move_sound", false);
                                                                                                    SharedPreferences sharedPreferences18 = this.f4111M;
                                                                                                    if (sharedPreferences18 != null) {
                                                                                                        this.f4126R0 = sharedPreferences18.getInt("pref_kb_dex_width", 50);
                                                                                                        SharedPreferences sharedPreferences19 = this.f4111M;
                                                                                                        if (sharedPreferences19 != null) {
                                                                                                            this.f4128S0 = sharedPreferences19.getInt("pref_kb_dex_height", 100);
                                                                                                            SharedPreferences sharedPreferences20 = this.f4111M;
                                                                                                            if (sharedPreferences20 != null) {
                                                                                                                String str3 = "center";
                                                                                                                String string3 = sharedPreferences20.getString("pref_kb_dex_pos", "center");
                                                                                                                if (string3 != null) {
                                                                                                                    str3 = string3;
                                                                                                                }
                                                                                                                this.f4130T0 = str3;
                                                                                                                this.f4163k0 = false;
                                                                                                                this.f4145b0 = false;
                                                                                                                m2169m0();
                                                                                                                Object systemService = getSystemService("display");
                                                                                                                systemService.getClass();
                                                                                                                DisplayManager displayManager = (DisplayManager) systemService;
                                                                                                                this.f4196w = displayManager;
                                                                                                                u60 u60Var = this.f4095G1;
                                                                                                                Handler handler = this.f4096H;
                                                                                                                displayManager.registerDisplayListener(u60Var, handler);
                                                                                                                registerReceiver(this.f4092F1, new IntentFilter("android.intent.action.SCREEN_OFF"));
                                                                                                                m2162i0();
                                                                                                                m2164j0();
                                                                                                                m2154d0(null);
                                                                                                                this.f4145b0 = false;
                                                                                                                ImageView imageView = this.f4172o;
                                                                                                                if (imageView != null) {
                                                                                                                    imageView.setVisibility(8);
                                                                                                                }
                                                                                                                ImageView imageView2 = this.f4172o;
                                                                                                                if (imageView2 != null) {
                                                                                                                    imageView2.setAlpha(0.0f);
                                                                                                                }
                                                                                                                Object systemService2 = getSystemService("power");
                                                                                                                systemService2.getClass();
                                                                                                                this.f4184s = ((PowerManager) systemService2).newWakeLock(268435466, "GamepadMouse:WakeLock");
                                                                                                                handler.post(this.f4107K1);
                                                                                                                Log.i("MouseService", "Setup complete: " + this.f4081C + " x " + this.f4084D);
                                                                                                                return;
                                                                                                            }
                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                            throw null;
                                                                                                        }
                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                        throw null;
                                                                                                    }
                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                    throw null;
                                                                                                }
                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                throw null;
                                                                                            }
                                                                                            xl3.m8890u("sharedPrefs");
                                                                                            throw null;
                                                                                        }
                                                                                        xl3.m8890u("sharedPrefs");
                                                                                        throw null;
                                                                                    }
                                                                                    xl3.m8890u("sharedPrefs");
                                                                                    throw null;
                                                                                }
                                                                                xl3.m8890u("sharedPrefs");
                                                                                throw null;
                                                                            }
                                                                            xl3.m8890u("sharedPrefs");
                                                                            throw null;
                                                                        }
                                                                        xl3.m8890u("sharedPrefs");
                                                                        throw null;
                                                                    }
                                                                    xl3.m8890u("sharedPrefs");
                                                                    throw null;
                                                                }
                                                                xl3.m8890u("sharedPrefs");
                                                                throw null;
                                                            }
                                                            xl3.m8890u("sharedPrefs");
                                                            throw null;
                                                        }
                                                        xl3.m8890u("sharedPrefs");
                                                        throw null;
                                                    }
                                                    xl3.m8890u("sharedPrefs");
                                                    throw null;
                                                }
                                                xl3.m8890u("sharedPrefs");
                                                throw null;
                                            }
                                            xl3.m8890u("sharedPrefs");
                                            throw null;
                                        }
                                        xl3.m8890u("sharedPrefs");
                                        throw null;
                                    }
                                    xl3.m8890u("sharedPrefs");
                                    throw null;
                                }
                                xl3.m8890u("sharedPrefs");
                                throw null;
                            }
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
                xl3.m8890u("sharedPrefs");
                throw null;
            }
            xl3.m8890u("sharedPrefs");
            throw null;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: p */
    public final int m2173p() {
        int i;
        String str = this.f4130T0;
        if (xl3.m8871b(str, "left")) {
            i = 8388611;
        } else if (xl3.m8871b(str, "right")) {
            i = 8388613;
        } else {
            i = 1;
        }
        return i | 80;
    }

    /* renamed from: q */
    public final void m2174q(float f, float f2) {
        Display display;
        this.f4182r0 = System.currentTimeMillis();
        Path path = new Path();
        path.moveTo(f, f2);
        GestureDescription.Builder builder = new GestureDescription.Builder();
        if (Build.VERSION.SDK_INT >= 30 && (display = this.f4199x) != null) {
            builder.setDisplayId(display.getDisplayId());
        }
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0L, 50L));
        dispatchGesture(builder.build(), null, null);
    }

    /* renamed from: r */
    public final void m2175r(float f, float f2) {
        Display display;
        this.f4182r0 = System.currentTimeMillis();
        Path path = new Path();
        path.moveTo(f, f2);
        GestureDescription.Builder builder = new GestureDescription.Builder();
        if (Build.VERSION.SDK_INT >= 30 && (display = this.f4199x) != null) {
            builder.setDisplayId(display.getDisplayId());
        }
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0L, 50L));
        builder.addStroke(new GestureDescription.StrokeDescription(path, 150L, 50L));
        dispatchGesture(builder.build(), null, null);
    }

    /* renamed from: s */
    public final ArrayList m2176s() {
        ArrayList arrayList = new ArrayList();
        boolean z = this.f4109L0;
        EnumC0985wy enumC0985wy = EnumC0985wy.f17925n;
        if (z) {
            arrayList.add(enumC0985wy);
        }
        if (this.f4112M0) {
            arrayList.add(EnumC0985wy.f17926o);
        }
        if (this.f4115N0) {
            arrayList.add(EnumC0985wy.f17927p);
        }
        if (arrayList.isEmpty()) {
            arrayList.add(enumC0985wy);
        }
        return arrayList;
    }

    /* renamed from: t */
    public final void m2177t() {
        ArrayList m2176s = m2176s();
        if (!m2176s.isEmpty()) {
            int size = m2176s.size();
            int i = 0;
            while (i < size) {
                Object obj = m2176s.get(i);
                i++;
                if (((EnumC0985wy) obj) == this.f4106K0) {
                    return;
                }
            }
        }
        ArrayList m2176s2 = m2176s();
        if (!m2176s2.isEmpty()) {
            this.f4106K0 = (EnumC0985wy) m2176s2.get(0);
            this.f4103J0.f17376a = 0;
            C1059yy c1059yy = this.f4088E0;
            if (c1059yy != null) {
                c1059yy.setAccentPending(0);
                return;
            }
            return;
        }
        throw new NoSuchElementException("List is empty.");
    }

    /* renamed from: u */
    public final void m2178u() {
        try {
            if (this.f4195v1 == null) {
                this.f4195v1 = new SoundPool.Builder().setMaxStreams(2).setAudioAttributes(new AudioAttributes.Builder().setUsage(1).setContentType(4).build()).build();
            }
            if (this.f4198w1 == 0) {
                File file = new File(getCacheDir(), "kb_move_tick_v1.wav");
                byte[] m2118e = m2118e();
                FileOutputStream fileOutputStream = new FileOutputStream(file);
                try {
                    fileOutputStream.write(m2118e);
                    fileOutputStream.close();
                    SoundPool soundPool = this.f4195v1;
                    soundPool.getClass();
                    this.f4198w1 = soundPool.load(file.getAbsolutePath(), 1);
                } finally {
                }
            }
        } catch (Exception e) {
            Log.w("MouseService", "Move tick init failed: " + e.getMessage());
            SoundPool soundPool2 = this.f4195v1;
            if (soundPool2 != null) {
                soundPool2.release();
            }
            this.f4195v1 = null;
            this.f4198w1 = 0;
        }
    }

    /* JADX WARN: Removed duplicated region for block: B:133:0x0350  */
    /* JADX WARN: Removed duplicated region for block: B:137:0x0356 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* renamed from: v */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public final void m2179v(String str, boolean z) {
        Display display;
        Object next;
        int displayId;
        boolean m2408b = db0.m2408b();
        Log.i("MouseService", "executeMappedAction(" + str + "). isPro: " + m2408b);
        if (!m2408b) {
            Log.w("MouseService", "Action blocked: Pro status required");
            return;
        }
        long currentTimeMillis = System.currentTimeMillis();
        long j = currentTimeMillis - this.f4187t;
        if (j < 300) {
            Log.v("MouseService", "Action debounced: " + j + "ms since last");
            return;
        }
        this.f4187t = currentTimeMillis;
        SharedPreferences sharedPreferences = this.f4111M;
        Integer num = null;
        if (sharedPreferences != null) {
            String string = sharedPreferences.getString("pref_mapping_x_" + str + "_type", "none");
            SharedPreferences sharedPreferences2 = this.f4111M;
            if (sharedPreferences2 != null) {
                String string2 = sharedPreferences2.getString("pref_mapping_x_" + str + "_value", RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED);
                StringBuilder m6827q = AbstractC0783rh.m6827q("Executing mapped action for key '", str, "': type=", string, ", value=");
                m6827q.append(string2);
                Log.i("MouseService", m6827q.toString());
                if (z && xl3.m8871b(string, "click_location_repeat")) {
                    Log.d("MouseService", "Auto-repeat event ignored for toggle mapping '" + str + "'");
                    return;
                }
                if (!xl3.m8871b(string, "none")) {
                    SharedPreferences sharedPreferences3 = this.f4111M;
                    if (sharedPreferences3 != null) {
                        if (sharedPreferences3.getBoolean("pref_haptic_feedback", true)) {
                            m2171n0(50L);
                        }
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
                if (string != null) {
                    int i = 0;
                    switch (string.hashCode()) {
                        case -2072607382:
                            if (string.equals("media_forward")) {
                                m2175r(this.f4081C * 0.8f, this.f4078B);
                                return;
                            }
                            return;
                        case -1890344818:
                            if (string.equals("vol_down")) {
                                Object systemService = getSystemService("audio");
                                systemService.getClass();
                                ((AudioManager) systemService).adjustStreamVolume(3, -1, 1);
                                return;
                            }
                            return;
                        case -1395688761:
                            if (string.equals("bright_down")) {
                                m2147a(-25);
                                return;
                            }
                            return;
                        case -925180581:
                            if (string.equals("rotate")) {
                                try {
                                    if (!Settings.System.canWrite(this)) {
                                        Log.w("MouseService", "Cannot toggle rotation: WRITE_SETTINGS permission not granted");
                                    } else {
                                        ContentResolver contentResolver = getContentResolver();
                                        Settings.System.putInt(contentResolver, "accelerometer_rotation", 0);
                                        if (Settings.System.getInt(contentResolver, "user_rotation", 0) == 0) {
                                            i = 1;
                                        }
                                        Settings.System.putInt(contentResolver, "user_rotation", i);
                                        Log.i("MouseService", "Screen rotation toggled to: " + i);
                                    }
                                    return;
                                } catch (Exception e) {
                                    Log.e("MouseService", "Failed to toggle rotation: " + e.getMessage());
                                    return;
                                }
                            }
                            return;
                        case -810904185:
                            if (string.equals("vol_up")) {
                                Object systemService2 = getSystemService("audio");
                                systemService2.getClass();
                                ((AudioManager) systemService2).adjustStreamVolume(3, 1, 1);
                                return;
                            }
                            return;
                        case -416447130:
                            if (string.equals("screenshot")) {
                                int i2 = Build.VERSION.SDK_INT;
                                if (i2 >= 34) {
                                    Display display2 = this.f4199x;
                                    if (display2 == null) {
                                        DisplayManager displayManager = this.f4196w;
                                        if (displayManager != null) {
                                            display2 = displayManager.getDisplay(0);
                                        } else {
                                            display = null;
                                            if (display != null) {
                                                i = display.getDisplayId();
                                            }
                                            if (i != 0) {
                                                try {
                                                    List<AccessibilityWindowInfo> windows = getWindows();
                                                    if (windows != null) {
                                                        ArrayList arrayList = new ArrayList();
                                                        for (Object obj : windows) {
                                                            AccessibilityWindowInfo accessibilityWindowInfo = (AccessibilityWindowInfo) obj;
                                                            displayId = accessibilityWindowInfo.getDisplayId();
                                                            if (displayId == i && accessibilityWindowInfo.getType() == 1) {
                                                                arrayList.add(obj);
                                                            }
                                                        }
                                                        Iterator it = arrayList.iterator();
                                                        if (!it.hasNext()) {
                                                            next = null;
                                                        } else {
                                                            next = it.next();
                                                            if (it.hasNext()) {
                                                                int layer = ((AccessibilityWindowInfo) next).getLayer();
                                                                do {
                                                                    Object next2 = it.next();
                                                                    int layer2 = ((AccessibilityWindowInfo) next2).getLayer();
                                                                    if (layer < layer2) {
                                                                        next = next2;
                                                                        layer = layer2;
                                                                    }
                                                                } while (it.hasNext());
                                                            }
                                                        }
                                                        AccessibilityWindowInfo accessibilityWindowInfo2 = (AccessibilityWindowInfo) next;
                                                        if (accessibilityWindowInfo2 != null) {
                                                            num = Integer.valueOf(accessibilityWindowInfo2.getId());
                                                        }
                                                    }
                                                } catch (Exception e2) {
                                                    Log.w("MouseService", "Failed to enumerate windows: " + e2.getMessage());
                                                }
                                                if (num != null) {
                                                    Log.i("MouseService", "Screenshot stage=window displayId=" + i + " windowId=" + num);
                                                    try {
                                                        takeScreenshotOfWindow(num.intValue(), this.f4104J1, new x60(this, display));
                                                        return;
                                                    } catch (Exception e3) {
                                                        Log.w("MouseService", "Window screenshot call failed: " + e3.getMessage() + ", trying display capture");
                                                    }
                                                } else {
                                                    Log.w("MouseService", "No app window found on displayId=" + i + ", trying display capture");
                                                }
                                            }
                                            m2156f0(display, "display");
                                            return;
                                        }
                                    }
                                    display = display2;
                                    if (display != null) {
                                    }
                                    if (i != 0) {
                                    }
                                    m2156f0(display, "display");
                                    return;
                                }
                                if (i2 >= 28) {
                                    performGlobalAction(9);
                                    return;
                                } else {
                                    Log.w("MouseService", "Screenshot action requires Android 9 (API 28) or higher");
                                    return;
                                }
                            }
                            return;
                        case 96801:
                            if (string.equals("app") && string2 != null && string2.length() != 0) {
                                try {
                                    Intent launchIntentForPackage = getPackageManager().getLaunchIntentForPackage(string2);
                                    if (launchIntentForPackage != null) {
                                        launchIntentForPackage.addFlags(268435456);
                                        startActivity(launchIntentForPackage);
                                        return;
                                    }
                                    return;
                                } catch (Exception e4) {
                                    Log.e("MouseService", "Failed to launch app " + string2 + ": " + e4.getMessage());
                                    return;
                                }
                            }
                            return;
                        case 3208415:
                            if (string.equals("home")) {
                                m2135L(2);
                                return;
                            }
                            return;
                        case 3363353:
                            if (string.equals("mute")) {
                                Object systemService3 = getSystemService("audio");
                                systemService3.getClass();
                                ((AudioManager) systemService3).adjustStreamVolume(3, 101, 1);
                                return;
                            }
                            return;
                        case 129044854:
                            if (string.equals("media_rewind")) {
                                m2175r(this.f4081C * 0.2f, this.f4078B);
                                return;
                            }
                            return;
                        case 1082295672:
                            if (string.equals("recents")) {
                                m2135L(3);
                                return;
                            }
                            return;
                        case 1170261132:
                            if (string.equals("click_location")) {
                                if (string2 != null && string2.length() != 0) {
                                    ma0 m2144W = m2144W(str);
                                    if (m2144W != null) {
                                        m2174q(((Number) m2144W.f9986n).floatValue(), ((Number) m2144W.f9987o).floatValue());
                                        return;
                                    } else {
                                        Log.e("MouseService", "Failed to parse click_location value: ".concat(string2));
                                        return;
                                    }
                                }
                                if (!this.f4145b0) {
                                    m2146Z(m2126B(R.string.toast_turn_on_mouse_to_capture, new Object[0]));
                                    return;
                                }
                                String format = String.format(Locale.US, "%.1f,%.1f", Arrays.copyOf(new Object[]{Float.valueOf(this.f4075A), Float.valueOf(this.f4078B)}, 2));
                                SharedPreferences sharedPreferences4 = this.f4111M;
                                if (sharedPreferences4 != null) {
                                    sharedPreferences4.edit().putString("pref_mapping_x_" + str + "_value", format).apply();
                                    m2146Z(m2126B(R.string.toast_location_captured, new Object[0]));
                                    return;
                                }
                                xl3.m8890u("sharedPrefs");
                                throw null;
                            }
                            return;
                        case 1635479726:
                            if (string.equals("click_location_repeat")) {
                                if (xl3.m8871b(this.f4190u, str)) {
                                    Log.i("MouseService", "Repeat click stopped by combo '" + str + "'");
                                    m2154d0(Integer.valueOf(R.string.toast_repeat_stopped));
                                    return;
                                }
                                String str2 = this.f4190u;
                                if (str2 != null) {
                                    Log.i("MouseService", AbstractC0783rh.m6823m("Replacing repeat click from '", str2, "' with '", str, "'"));
                                    m2154d0(null);
                                    m2146Z(m2126B(R.string.toast_repeat_replaced, new Object[0]));
                                }
                                if (string2 != null && string2.length() != 0) {
                                    this.f4190u = str;
                                    this.f4193v = m2140R(str);
                                    Handler handler = this.f4096H;
                                    s60 s60Var = this.f4110L1;
                                    handler.removeCallbacks(s60Var);
                                    Log.i("MouseService", "Repeat click started for '" + str + "' every " + this.f4193v + "ms");
                                    m2146Z(m2126B(R.string.toast_repeat_started_format, m2126B(R.string.repeat_interval_format, Double.valueOf(((double) this.f4193v) / 1000.0d))));
                                    handler.post(s60Var);
                                    return;
                                }
                                if (!this.f4145b0) {
                                    m2146Z(m2126B(R.string.toast_turn_on_mouse_to_capture, new Object[0]));
                                    return;
                                }
                                String format2 = String.format(Locale.US, "%.1f,%.1f", Arrays.copyOf(new Object[]{Float.valueOf(this.f4075A), Float.valueOf(this.f4078B)}, 2));
                                SharedPreferences sharedPreferences5 = this.f4111M;
                                if (sharedPreferences5 != null) {
                                    sharedPreferences5.edit().putString("pref_mapping_x_" + str + "_value", format2).apply();
                                    m2146Z(m2126B(R.string.toast_repeat_location_captured, new Object[0]));
                                    return;
                                }
                                xl3.m8890u("sharedPrefs");
                                throw null;
                            }
                            return;
                        case 1822009856:
                            if (string.equals("bright_up")) {
                                m2147a(25);
                                return;
                            }
                            return;
                        default:
                            return;
                    }
                }
                return;
            }
            xl3.m8890u("sharedPrefs");
            throw null;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: y */
    public final AccessibilityNodeInfo m2180y(float f, float f2, float f3) {
        int i;
        AccessibilityNodeInfo root;
        SparseArray windowsOnAllDisplays;
        Display display = this.f4199x;
        if (display != null) {
            i = display.getDisplayId();
        } else {
            i = 0;
        }
        ArrayList arrayList = new ArrayList();
        if (Build.VERSION.SDK_INT >= 30) {
            windowsOnAllDisplays = getWindowsOnAllDisplays();
            List list = (List) windowsOnAllDisplays.get(i);
            if (list != null) {
                arrayList.addAll(list);
            }
        } else {
            List<AccessibilityWindowInfo> windows = getWindows();
            if (windows != null) {
                arrayList.addAll(windows);
            }
        }
        int size = arrayList.size();
        for (int i2 = 0; i2 < size; i2++) {
            AccessibilityWindowInfo accessibilityWindowInfo = (AccessibilityWindowInfo) arrayList.get(i2);
            if (accessibilityWindowInfo.getType() == 1 && (root = accessibilityWindowInfo.getRoot()) != null) {
                AccessibilityNodeInfo m2124z = m2124z(root, f, f2, f3);
                if (m2124z != null) {
                    return m2124z;
                }
                root.recycle();
            }
        }
        return null;
    }

    @Override // android.accessibilityservice.AccessibilityService
    public final void onInterrupt() {
    }

    @Override // android.accessibilityservice.AccessibilityService
    public final void onAccessibilityEvent(AccessibilityEvent accessibilityEvent) {
    }
}
