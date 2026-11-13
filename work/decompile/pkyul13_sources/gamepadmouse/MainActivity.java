package com.pkyul13.gamepadmouse;

import android.R;
import android.app.Dialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.view.ContextThemeWrapper;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.Window;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.widget.SwitchCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.work.impl.Scheduler;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.navigation.NavigationView;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.pkyul13.gamepadmouse.MainActivity;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import p000.AbstractActivityC0439i4;
import p000.AbstractC0446ib;
import p000.AbstractC0449ie;
import p000.AbstractC0484je;
import p000.AbstractC0509k2;
import p000.AbstractC0521ke;
import p000.AbstractC0783rh;
import p000.C0150b1;
import p000.C0159ba;
import p000.C0296eb;
import p000.C0360g;
import p000.C0472j2;
import p000.C0714pm;
import p000.C0879u2;
import p000.C0903uq;
import p000.C1027y2;
import p000.InterfaceC0002a1;
import p000.RunnableC0151b2;
import p000.ViewOnClickListenerC0837sy;
import p000.c20;
import p000.cc3;
import p000.db0;
import p000.e20;
import p000.ek0;
import p000.j20;
import p000.jo0;
import p000.kq0;
import p000.lo0;
import p000.ma0;
import p000.qj2;
import p000.qk2;
import p000.r20;
import p000.s20;
import p000.t10;
import p000.tq0;
import p000.u10;
import p000.v20;
import p000.w10;
import p000.x10;
import p000.x20;
import p000.xl3;
import p000.y10;
import p000.z20;

/* compiled from: r8-map-id-8c60900aeda595a73b778d06a0c2b0d30b6fd2caefbddc6926c14247c48afd52 */
/* loaded from: classes.dex */
public final class MainActivity extends AbstractActivityC0439i4 {

    /* renamed from: M */
    public static final /* synthetic */ int f4054M = 0;

    /* renamed from: A */
    public NavigationView f4055A;

    /* renamed from: B */
    public MaterialToolbar f4056B;

    /* renamed from: C */
    public int f4057C;

    /* renamed from: D */
    public boolean f4058D;

    /* renamed from: E */
    public PopupWindow f4059E;

    /* renamed from: H */
    public final AbstractC0509k2 f4062H;

    /* renamed from: I */
    public final j20 f4063I;

    /* renamed from: J */
    public final List f4064J;

    /* renamed from: K */
    public final Map f4065K;

    /* renamed from: L */
    public final List f4066L;

    /* renamed from: t */
    public SharedPreferences f4067t;

    /* renamed from: u */
    public FirebaseAnalytics f4068u;

    /* renamed from: w */
    public AdView f4070w;

    /* renamed from: x */
    public FrameLayout f4071x;

    /* renamed from: y */
    public w10 f4072y;

    /* renamed from: z */
    public x10 f4073z;

    /* renamed from: v */
    public float f4069v = 0.15f;

    /* renamed from: F */
    public final C0360g f4060F = new C0360g(1, this);

    /* renamed from: G */
    public final int f4061G = AdRequest.MAX_CONTENT_URL_LENGTH;

    public MainActivity() {
        int i = 0;
        AbstractC0509k2 registerForActivityResult = registerForActivityResult(new C0472j2(i), new C0296eb(5, this));
        registerForActivityResult.getClass();
        this.f4062H = registerForActivityResult;
        this.f4063I = new j20(this, i);
        this.f4064J = AbstractC0484je.m4409W(100, Integer.valueOf(Scheduler.MAX_GREEDY_SCHEDULER_LIMIT), 500, 1000, 2000, 3000);
        this.f4065K = x20.m8738Z(new ma0("orange", "#FFA000"), new ma0("blue", "#2196F3"), new ma0("green", "#4CAF50"), new ma0("red", "#F44336"), new ma0("black", "#212121"), new ma0("white", "#FFFFFF"), new ma0("purple", "#9C27B0"), new ma0("cyan", "#00BCD4"), new ma0("pink", "#E91E63"), new ma0("yellow", "#FFEB3B"));
        this.f4066L = AbstractC0484je.m4409W("#F44336", "#E53935", "#B71C1C", "#FF8A80", "#8E0E4F", "#E91E63", "#F06292", "#F48FB1", "#9C27B0", "#CE93D8", "#4A148C", "#3F51B5", "#2196F3", "#1976D2", "#82B1FF", "#00BCD4", "#4DD0E1", "#006064", "#4CAF50", "#2E7D32", "#A5D6A7", "#00C853", "#FFEB3B", "#FBC02D", "#FFF176", "#F57F17", "#FFA000", "#FB8C00", "#FFB74D", "#E65100", "#795548", "#BCAAA4", "#FFFFFF", "#212121", "#9E9E9E", "#616161");
    }

    /* renamed from: n */
    public static String m2095n(int i) {
        return String.format(Locale.US, "%.2f", Arrays.copyOf(new Object[]{Float.valueOf(i / 1000.0f)}, 1));
    }

    /* renamed from: q */
    public static String m2096q(String str) {
        String str2;
        cc3 cc3Var;
        Pattern compile = Pattern.compile("^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$");
        compile.getClass();
        if (str == null || (str2 = ek0.m2915Y(str).toString()) == null) {
            str2 = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
        }
        Matcher matcher = compile.matcher(str2);
        matcher.getClass();
        if (!matcher.find(0)) {
            cc3Var = null;
        } else {
            cc3Var = new cc3(matcher, str2);
        }
        if (cc3Var == null) {
            return null;
        }
        z20 z20Var = (z20) cc3Var.f2354p;
        if (z20Var == null) {
            z20Var = new z20(cc3Var);
            cc3Var.f2354p = z20Var;
        }
        String str3 = (String) z20Var.get(1);
        if (str3.length() == 3) {
            ArrayList arrayList = new ArrayList(str3.length());
            for (int i = 0; i < str3.length(); i++) {
                char charAt = str3.charAt(i);
                StringBuilder sb = new StringBuilder();
                sb.append(charAt);
                sb.append(charAt);
                arrayList.add(sb.toString());
            }
            str3 = AbstractC0449ie.m4162b0(arrayList, RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED, null, 62);
        }
        String upperCase = str3.toUpperCase(Locale.ROOT);
        upperCase.getClass();
        return "#".concat(upperCase);
    }

    /* renamed from: r */
    public static final void m2097r(MainActivity mainActivity, CheckBox checkBox, CheckBox checkBox2, CheckBox checkBox3, String str) {
        mainActivity.f4058D = true;
        checkBox.setChecked(str.equals("left"));
        checkBox2.setChecked(str.equals("center"));
        checkBox3.setChecked(str.equals("right"));
        mainActivity.f4058D = false;
        SharedPreferences sharedPreferences = mainActivity.f4067t;
        if (sharedPreferences != null) {
            sharedPreferences.edit().putString("pref_kb_dex_pos", str).apply();
        } else {
            xl3.m8890u("sharedPrefs");
            throw null;
        }
    }

    /* renamed from: s */
    public static final void m2098s(NavigationView navigationView, MainActivity mainActivity, List list, MaterialToolbar materialToolbar, Intent intent) {
        String str;
        if (intent != null) {
            str = intent.getStringExtra("open_page");
        } else {
            str = null;
        }
        if (str != null && str.hashCode() == 263712123 && str.equals("keyboard_settings")) {
            navigationView.setCheckedItem(R.id.nav_keyboard_settings);
            m2099t(mainActivity, list, materialToolbar, R.id.layout_settings_keyboard);
        }
        if (intent != null) {
            intent.removeExtra("open_page");
        }
    }

    /* renamed from: t */
    public static final void m2099t(MainActivity mainActivity, List list, MaterialToolbar materialToolbar, int i) {
        String string;
        int i2;
        mainActivity.f4057C = i;
        Iterator it = list.iterator();
        while (it.hasNext()) {
            int intValue = ((Number) it.next()).intValue();
            View findViewById = mainActivity.findViewById(intValue);
            if (intValue == i) {
                i2 = 0;
            } else {
                i2 = 8;
            }
            findViewById.setVisibility(i2);
        }
        if (i == R.id.layout_settings_general) {
            string = mainActivity.getString(R.string.general_settings);
        } else if (i == R.id.layout_settings_pointer) {
            string = mainActivity.getString(R.string.pointer_sensitivity);
        } else if (i == R.id.layout_settings_keyboard) {
            string = mainActivity.getString(R.string.keyboard_settings);
        } else if (i == R.id.layout_initial_setup) {
            string = mainActivity.getString(R.string.page_initial_setup);
        } else if (i == R.id.layout_how_to_use) {
            string = mainActivity.getString(R.string.how_to_use);
        } else if (i == R.id.layout_pro_tab) {
            string = mainActivity.m2110v();
        } else {
            string = mainActivity.getString(R.string.app_name);
        }
        materialToolbar.setTitle(string);
    }

    /* renamed from: u */
    public static final void m2100u(TextView textView, MainActivity mainActivity, Button button, TextView textView2) {
        float f;
        float f2;
        MaterialToolbar materialToolbar;
        Menu menu;
        MenuItem findItem;
        boolean m2408b = db0.m2408b();
        if (m2408b) {
            textView.setText(mainActivity.getString(R.string.pro_version_active));
            textView.setTextColor(mainActivity.getColor(R.color.holo_green_dark));
            button.setVisibility(8);
            textView2.setVisibility(8);
            mainActivity.findViewById(R.id.layout_pro_r3_desc).setVisibility(0);
        } else {
            textView.setText(mainActivity.getString(R.string.pro_version_inactive));
            textView.setTextColor(mainActivity.getColor(R.color.text_primary));
            button.setVisibility(0);
            textView2.setVisibility(0);
            mainActivity.findViewById(R.id.layout_pro_r3_desc).setVisibility(8);
        }
        SwitchCompat switchCompat = (SwitchCompat) mainActivity.findViewById(R.id.switch_haptic_feedback);
        if (!m2408b) {
            switchCompat.setChecked(false);
        }
        switchCompat.setEnabled(m2408b);
        SwitchCompat switchCompat2 = (SwitchCompat) mainActivity.findViewById(R.id.switch_dex_lockscreen);
        if (!m2408b) {
            switchCompat2.setChecked(false);
        }
        switchCompat2.setEnabled(m2408b);
        TextView textView3 = (TextView) mainActivity.findViewById(R.id.tv_dex_lockscreen_desc);
        textView3.setEnabled(m2408b);
        float f3 = 0.5f;
        if (m2408b) {
            f = 1.0f;
        } else {
            f = 0.5f;
        }
        textView3.setAlpha(f);
        SwitchCompat switchCompat3 = (SwitchCompat) mainActivity.findViewById(R.id.switch_keyboard_input);
        if (!m2408b) {
            switchCompat3.setChecked(false);
        }
        switchCompat3.setEnabled(m2408b);
        TextView textView4 = (TextView) mainActivity.findViewById(R.id.tv_keyboard_input_desc);
        textView4.setEnabled(m2408b);
        if (m2408b) {
            f2 = 1.0f;
        } else {
            f2 = 0.5f;
        }
        textView4.setAlpha(f2);
        ((SeekBar) mainActivity.findViewById(R.id.seekbar_vibration_intensity)).setEnabled(m2408b);
        ((SeekBar) mainActivity.findViewById(R.id.seekbar_dex_speed)).setEnabled(m2408b);
        View findViewById = mainActivity.findViewById(R.id.cb_kb_lang_en);
        findViewById.getClass();
        View findViewById2 = mainActivity.findViewById(R.id.cb_kb_lang_ko);
        findViewById2.getClass();
        View findViewById3 = mainActivity.findViewById(R.id.cb_kb_lang_es);
        findViewById3.getClass();
        View findViewById4 = mainActivity.findViewById(R.id.seekbar_kb_repeat);
        findViewById4.getClass();
        View findViewById5 = mainActivity.findViewById(R.id.seekbar_kb_delay);
        findViewById5.getClass();
        View findViewById6 = mainActivity.findViewById(R.id.switch_kb_move_sound);
        findViewById6.getClass();
        View findViewById7 = mainActivity.findViewById(R.id.seekbar_kb_dex_width);
        findViewById7.getClass();
        View findViewById8 = mainActivity.findViewById(R.id.seekbar_kb_dex_height);
        findViewById8.getClass();
        View findViewById9 = mainActivity.findViewById(R.id.cb_kb_dex_pos_left);
        findViewById9.getClass();
        View findViewById10 = mainActivity.findViewById(R.id.cb_kb_dex_pos_center);
        findViewById10.getClass();
        View findViewById11 = mainActivity.findViewById(R.id.cb_kb_dex_pos_right);
        findViewById11.getClass();
        View findViewById12 = mainActivity.findViewById(R.id.edittext_kb_test);
        findViewById12.getClass();
        Iterator it = AbstractC0484je.m4409W(findViewById, findViewById2, findViewById3, findViewById4, findViewById5, findViewById6, findViewById7, findViewById8, findViewById9, findViewById10, findViewById11, findViewById12).iterator();
        while (it.hasNext()) {
            ((View) it.next()).setEnabled(m2408b);
        }
        View findViewById13 = mainActivity.findViewById(R.id.layout_settings_keyboard);
        if (m2408b) {
            f3 = 1.0f;
        }
        findViewById13.setAlpha(f3);
        NavigationView navigationView = mainActivity.f4055A;
        if (navigationView != null && (menu = navigationView.getMenu()) != null && (findItem = menu.findItem(R.id.nav_pro)) != null) {
            findItem.setTitle(mainActivity.m2110v());
        }
        if (mainActivity.f4057C == R.id.layout_pro_tab && (materialToolbar = mainActivity.f4056B) != null) {
            materialToolbar.setTitle(mainActivity.m2110v());
        }
    }

    /* JADX WARN: Type inference failed for: r1v1, types: [java.lang.Object, sd0] */
    /* JADX WARN: Type inference failed for: r2v0, types: [java.lang.Object, sd0] */
    /* renamed from: w */
    public static void m2101w(View view) {
        if ((view instanceof SwitchCompat) || (view instanceof CheckBox)) {
            final float f = ((CompoundButton) view).getResources().getDisplayMetrics().density * 8.0f;
            final ?? obj = new Object();
            final ?? obj2 = new Object();
            view.setOnTouchListener(new View.OnTouchListener() { // from class: g20
                @Override // android.view.View.OnTouchListener
                public final boolean onTouch(View view2, MotionEvent motionEvent) {
                    ViewParent parent;
                    int i = MainActivity.f4054M;
                    int actionMasked = motionEvent.getActionMasked();
                    sd0 sd0Var = sd0.this;
                    sd0 sd0Var2 = obj2;
                    if (actionMasked != 0) {
                        if (actionMasked == 2) {
                            float abs = Math.abs(motionEvent.getX() - sd0Var.f13997n);
                            float abs2 = Math.abs(motionEvent.getY() - sd0Var2.f13997n);
                            if (abs > f && abs > abs2 * 1.5f && (parent = view2.getParent()) != null) {
                                parent.requestDisallowInterceptTouchEvent(true);
                                return false;
                            }
                            return false;
                        }
                        return false;
                    }
                    sd0Var.f13997n = motionEvent.getX();
                    sd0Var2.f13997n = motionEvent.getY();
                    return false;
                }
            });
        }
        if (view instanceof ViewGroup) {
            ViewGroup viewGroup = (ViewGroup) view;
            int childCount = viewGroup.getChildCount();
            for (int i = 0; i < childCount; i++) {
                View childAt = viewGroup.getChildAt(i);
                childAt.getClass();
                m2101w(childAt);
            }
        }
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    /* JADX WARN: Failed to find 'out' block for switch in B:16:0x00e8. Please report as an issue. */
    /* renamed from: A */
    public final void m2102A() {
        String string;
        if (this.f4067t != null) {
            for (ma0 ma0Var : AbstractC0484je.m4409W(new ma0(Integer.valueOf(R.id.tv_map_x_lb_val), "lb"), new ma0(Integer.valueOf(R.id.tv_map_x_rb_val), "rb"), new ma0(Integer.valueOf(R.id.tv_map_x_lt_val), "lt"), new ma0(Integer.valueOf(R.id.tv_map_x_rt_val), "rt"), new ma0(Integer.valueOf(R.id.tv_map_x_up_val), "up"), new ma0(Integer.valueOf(R.id.tv_map_x_down_val), "down"), new ma0(Integer.valueOf(R.id.tv_map_x_left_val), "left"), new ma0(Integer.valueOf(R.id.tv_map_x_right_val), "right"))) {
                int intValue = ((Number) ma0Var.f9986n).intValue();
                String str = (String) ma0Var.f9987o;
                TextView textView = (TextView) findViewById(intValue);
                if (textView != null) {
                    SharedPreferences sharedPreferences = this.f4067t;
                    if (sharedPreferences != null) {
                        String string2 = sharedPreferences.getString("pref_mapping_x_" + str + "_type", "none");
                        SharedPreferences sharedPreferences2 = this.f4067t;
                        if (sharedPreferences2 != null) {
                            String string3 = sharedPreferences2.getString("pref_mapping_x_" + str + "_value", RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED);
                            if (string2 != null) {
                                switch (string2.hashCode()) {
                                    case -2072607382:
                                        if (string2.equals("media_forward")) {
                                            string = getString(R.string.action_media_forward);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case -1890344818:
                                        if (string2.equals("vol_down")) {
                                            string = getString(R.string.action_vol_down);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case -1395688761:
                                        if (string2.equals("bright_down")) {
                                            string = getString(R.string.action_bright_down);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case -925180581:
                                        if (string2.equals("rotate")) {
                                            string = getString(R.string.action_rotate);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case -810904185:
                                        if (string2.equals("vol_up")) {
                                            string = getString(R.string.action_vol_up);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case -416447130:
                                        if (string2.equals("screenshot")) {
                                            string = getString(R.string.action_screenshot);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 96801:
                                        if (string2.equals("app")) {
                                            PackageManager packageManager = getPackageManager();
                                            try {
                                                string3.getClass();
                                                ApplicationInfo applicationInfo = packageManager.getApplicationInfo(string3, 0);
                                                applicationInfo.getClass();
                                                string = packageManager.getApplicationLabel(applicationInfo).toString();
                                            } catch (Exception unused) {
                                                string = getString(R.string.app_not_found);
                                                string.getClass();
                                            }
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 3208415:
                                        if (string2.equals("home")) {
                                            string = getString(R.string.action_home);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 3363353:
                                        if (string2.equals("mute")) {
                                            string = getString(R.string.action_mute);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 129044854:
                                        if (string2.equals("media_rewind")) {
                                            string = getString(R.string.action_media_rewind);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 1082295672:
                                        if (string2.equals("recents")) {
                                            string = getString(R.string.action_recents);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 1170261132:
                                        if (string2.equals("click_location")) {
                                            if (string3 != null && string3.length() != 0) {
                                                string = getString(R.string.action_click_location) + " (" + string3 + ")";
                                            } else {
                                                string = getString(R.string.action_click_location);
                                            }
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                    case 1635479726:
                                        if (string2.equals("click_location_repeat")) {
                                            if (this.f4067t != null) {
                                                String string4 = getString(R.string.repeat_interval_format, Double.valueOf(r3.getInt("pref_mapping_x_" + str + "_interval", 500) / 1000.0d));
                                                string4.getClass();
                                                string = getString(R.string.action_click_location_repeat) + " · " + string4;
                                                if (string3 != null && string3.length() != 0) {
                                                    string = AbstractC0783rh.m6822l(string, " (", string3, ")");
                                                }
                                                textView.setText(string);
                                                break;
                                            } else {
                                                xl3.m8890u("sharedPrefs");
                                                throw null;
                                            }
                                        }
                                        break;
                                    case 1822009856:
                                        if (string2.equals("bright_up")) {
                                            string = getString(R.string.action_bright_up);
                                            string.getClass();
                                            textView.setText(string);
                                            break;
                                        }
                                        break;
                                }
                            }
                            string = getString(R.string.action_none);
                            string.getClass();
                            textView.setText(string);
                        } else {
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
            }
        }
    }

    /* renamed from: B */
    public final void m2103B(boolean z) {
        try {
            Log.i("AdMob", "updateBannerAdVisibility: isPro=" + z);
            FrameLayout frameLayout = this.f4071x;
            if (z) {
                if (frameLayout != null) {
                    frameLayout.setVisibility(8);
                }
                FrameLayout frameLayout2 = this.f4071x;
                if (frameLayout2 != null) {
                    frameLayout2.removeAllViews();
                }
                try {
                    AdView adView = this.f4070w;
                    if (adView != null) {
                        adView.pause();
                        return;
                    }
                    return;
                } catch (Throwable unused) {
                    return;
                }
            }
            if (frameLayout != null) {
                frameLayout.setVisibility(0);
            }
            if (this.f4070w == null) {
                AdView adView2 = new AdView(this);
                adView2.setAdSize(AdSize.BANNER);
                adView2.setAdUnitId(getString(R.string.admob_banner_id));
                adView2.setAdListener(new v20(this));
                this.f4070w = adView2;
                FrameLayout frameLayout3 = this.f4071x;
                if (frameLayout3 != null) {
                    frameLayout3.removeAllViews();
                }
                FrameLayout frameLayout4 = this.f4071x;
                if (frameLayout4 != null) {
                    frameLayout4.addView(adView2);
                }
            }
            AdRequest build = new AdRequest.Builder().build();
            build.getClass();
            AdView adView3 = this.f4070w;
            if (adView3 != null) {
                adView3.loadAd(build);
            }
        } catch (Throwable th) {
            Log.e("AdMob", "updateBannerAdVisibility error: " + th.getMessage(), th);
        }
    }

    /* JADX WARN: Code restructure failed: missing block: B:20:0x0077, code lost:
    
        if (r10.outHeight > 0) goto L30;
     */
    /* renamed from: C */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public final void m2104C() {
        String string;
        TextView textView = (TextView) findViewById(R.id.tv_current_cursor_style);
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            String str = "orange";
            String string2 = sharedPreferences.getString("pref_cursor_style", "orange");
            String str2 = (String) this.f4065K.get(string2);
            if (str2 != null) {
                SharedPreferences sharedPreferences2 = this.f4067t;
                if (sharedPreferences2 != null) {
                    sharedPreferences2.edit().putString("pref_cursor_style", "custom_color").putString("pref_cursor_color", str2).apply();
                    string2 = "custom_color";
                } else {
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            }
            if (xl3.m8871b(string2, "custom")) {
                File file = new File(getFilesDir(), "custom_cursor.png");
                if (file.exists() && file.length() > 0) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    BitmapFactory.decodeFile(file.getAbsolutePath(), options);
                    if (options.outWidth > 0) {
                    }
                }
                SharedPreferences sharedPreferences3 = this.f4067t;
                if (sharedPreferences3 != null) {
                    sharedPreferences3.edit().putString("pref_cursor_style", "orange").apply();
                    if (file.exists()) {
                        file.delete();
                    }
                    string2 = "orange";
                } else {
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            }
            if (xl3.m8871b(string2, "custom_color")) {
                SharedPreferences sharedPreferences4 = this.f4067t;
                if (sharedPreferences4 != null) {
                    String str3 = "#FFA000";
                    String string3 = sharedPreferences4.getString("pref_cursor_color", "#FFA000");
                    if (string3 != null) {
                        str3 = string3;
                    }
                    String m2096q = m2096q(str3);
                    if (m2096q == null) {
                        SharedPreferences sharedPreferences5 = this.f4067t;
                        if (sharedPreferences5 != null) {
                            sharedPreferences5.edit().putString("pref_cursor_style", "orange").apply();
                        } else {
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                    } else {
                        if (textView != null) {
                            textView.setText(getString(R.string.cursor_custom_color) + " (" + m2096q + ")");
                            return;
                        }
                        return;
                    }
                } else {
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            } else {
                str = string2;
            }
            if (textView != null) {
                if (xl3.m8871b(str, "custom")) {
                    string = getString(R.string.cursor_custom_png);
                } else {
                    string = getString(R.string.cursor_color_orange);
                }
                textView.setText(string);
                return;
            }
            return;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: D */
    public final void m2105D() {
        TextView textView = (TextView) findViewById(R.id.tv_kb_guide);
        if (textView == null) {
            return;
        }
        String string = getString(R.string.kb_guide_body);
        string.getClass();
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            if (sharedPreferences.getBoolean("pref_kb_lang_es", false)) {
                string = AbstractC0783rh.m6821k(string, "\n", getString(R.string.kb_guide_es_line));
            }
            textView.setText(string);
            return;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: E */
    public final void m2106E() {
        String str;
        TextView textView = (TextView) findViewById(R.id.tv_current_toggle_key);
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            int i = sharedPreferences.getInt("pref_toggle_keycode", 106);
            if (textView != null) {
                switch (i) {
                    case 96:
                        str = "Button A";
                        break;
                    case 97:
                        str = "Button B";
                        break;
                    case 98:
                    case 101:
                    default:
                        String keyCodeToString = KeyEvent.keyCodeToString(i);
                        keyCodeToString.getClass();
                        str = ek0.m2913W(ek0.m2913W(keyCodeToString, "KEYCODE_BUTTON_", RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED), "KEYCODE_", RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED);
                        break;
                    case 99:
                        str = "Button X";
                        break;
                    case 100:
                        str = "Button Y";
                        break;
                    case 102:
                        str = "L1 (LB)";
                        break;
                    case 103:
                        str = "R1 (RB)";
                        break;
                    case 104:
                        str = "L2 (LT)";
                        break;
                    case 105:
                        str = "R2 (RT)";
                        break;
                    case 106:
                        str = "L3";
                        break;
                    case 107:
                        str = "R3";
                        break;
                    case 108:
                        str = "Start";
                        break;
                    case 109:
                        str = "Select";
                        break;
                    case 110:
                        str = "Mode (Xbox)";
                        break;
                }
                textView.setText(str);
                return;
            }
            return;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    @Override // p000.AbstractActivityC0439i4, android.app.Activity, android.view.ContextThemeWrapper, android.content.ContextWrapper
    public final void attachBaseContext(Context context) {
        context.getClass();
        SharedPreferences sharedPreferences = context.getSharedPreferences("GamepadMousePrefs", 0);
        String language = Locale.getDefault().getLanguage();
        if (!xl3.m8871b(language, "ko") && !xl3.m8871b(language, "es")) {
            language = "en";
        }
        String string = sharedPreferences.getString("pref_language", language);
        if (string != null) {
            language = string;
        }
        Locale forLanguageTag = Locale.forLanguageTag(language);
        Locale.setDefault(forLanguageTag);
        Configuration configuration = new Configuration(context.getResources().getConfiguration());
        configuration.setLocale(forLanguageTag);
        super.attachBaseContext(context.createConfigurationContext(configuration));
    }

    /* renamed from: m */
    public final void m2107m() {
        if (!Settings.System.canWrite(this)) {
            C1027y2 c1027y2 = new C1027y2(this);
            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
            c0879u2.f15166d = getString(R.string.permission_required);
            c0879u2.f15168f = getString(R.string.brightness_permission_msg);
            c1027y2.m9010f(getString(R.string.open_settings), new c20(this, 6));
            c0879u2.f15171i = getString(R.string.cancel);
            c1027y2.m9011g();
        }
    }

    /* renamed from: o */
    public final String m2108o(int i) {
        if (i == 0) {
            String string = getString(R.string.long_press_instant);
            string.getClass();
            return string;
        }
        return AbstractC0783rh.m6820j(String.format(Locale.US, "%.1f", Arrays.copyOf(new Object[]{Float.valueOf(i / 10.0f)}, 1)), getString(R.string.seconds_unit));
    }

    /* JADX WARN: Type inference failed for: r0v236, types: [com.google.android.gms.ads.initialization.OnInitializationCompleteListener, java.lang.Object] */
    @Override // p000.AbstractActivityC0439i4, androidx.activity.ComponentActivity, p000.AbstractActivityC0596mf, android.app.Activity
    public final void onCreate(Bundle bundle) {
        boolean z;
        boolean z2;
        int i;
        String str;
        int i2;
        String str2;
        PackageInfo packageInfo;
        PackageManager.PackageInfoFlags of;
        boolean z3;
        String string;
        super.onCreate(bundle);
        setContentView(R.layout.activity_main);
        setTitle(R.string.app_name);
        DrawerLayout drawerLayout = (DrawerLayout) findViewById(R.id.main);
        View findViewById = findViewById(R.id.main_content);
        C0159ba c0159ba = new C0159ba(25);
        WeakHashMap weakHashMap = tq0.f14791a;
        kq0.m4775l(findViewById, c0159ba);
        kq0.m4775l(findViewById(R.id.drawer_container), new C0159ba(24));
        MaterialToolbar materialToolbar = (MaterialToolbar) findViewById(R.id.main_toolbar);
        this.f4056B = materialToolbar;
        C0150b1 c0150b1 = new C0150b1(this, drawerLayout, materialToolbar);
        drawerLayout.m610a(c0150b1);
        DrawerLayout drawerLayout2 = c0150b1.f1552b;
        View m614e = drawerLayout2.m614e(8388611);
        final int i3 = 0;
        if (m614e != null) {
            z = DrawerLayout.m607l(m614e);
        } else {
            z = false;
        }
        if (z) {
            c0150b1.m1003d(1.0f);
        } else {
            c0150b1.m1003d(0.0f);
        }
        C0714pm c0714pm = c0150b1.f1553c;
        View m614e2 = drawerLayout2.m614e(8388611);
        if (m614e2 != null) {
            z2 = DrawerLayout.m607l(m614e2);
        } else {
            z2 = false;
        }
        if (z2) {
            i = c0150b1.f1555e;
        } else {
            i = c0150b1.f1554d;
        }
        InterfaceC0002a1 interfaceC0002a1 = c0150b1.f1551a;
        final int i4 = 1;
        if (!c0150b1.f1556f && !interfaceC0002a1.mo22b()) {
            Log.w("ActionBarDrawerToggle", "DrawerToggle may not show up because NavigationIcon is not visible. You may need to call actionbar.setDisplayHomeAsUpEnabled(true);");
            c0150b1.f1556f = true;
        }
        interfaceC0002a1.mo26n(c0714pm, i);
        m2101w(drawerLayout);
        if (AbstractC0446ib.f7649a == null) {
            synchronized (AbstractC0446ib.f7650b) {
                if (AbstractC0446ib.f7649a == null) {
                    C0903uq m8143b = C0903uq.m8143b();
                    m8143b.m8146a();
                    AbstractC0446ib.f7649a = FirebaseAnalytics.getInstance(m8143b.f15598a);
                }
            }
        }
        FirebaseAnalytics firebaseAnalytics = AbstractC0446ib.f7649a;
        firebaseAnalytics.getClass();
        this.f4068u = firebaseAnalytics;
        if (db0.m2408b()) {
            str = "pro_user";
        } else {
            str = "free_user";
        }
        String str3 = str;
        FirebaseAnalytics firebaseAnalytics2 = this.f4068u;
        if (firebaseAnalytics2 != null) {
            qj2 qj2Var = firebaseAnalytics2.f4047a;
            qj2Var.getClass();
            qj2Var.m6543g(new qk2(qj2Var, null, "user_type", str3, false, 0));
            db0.m2407a(this);
            C0360g c0360g = this.f4060F;
            c0360g.getClass();
            CopyOnWriteArrayList copyOnWriteArrayList = db0.f4582f;
            if (!copyOnWriteArrayList.contains(c0360g)) {
                copyOnWriteArrayList.add(c0360g);
            }
            try {
                MobileAds.initialize(this, new Object());
                m2112y();
            } catch (Throwable th) {
                Log.e("AdMob", "Safe initialization failure: " + th.getMessage(), th);
            }
            SharedPreferences sharedPreferences = getSharedPreferences("GamepadMousePrefs", 0);
            sharedPreferences.getClass();
            this.f4067t = sharedPreferences;
            if (!sharedPreferences.contains("pref_mapping_x_up_type")) {
                SharedPreferences sharedPreferences2 = this.f4067t;
                if (sharedPreferences2 != null) {
                    sharedPreferences2.edit().putString("pref_mapping_x_up_type", "vol_up").apply();
                } else {
                    xl3.m8890u("sharedPrefs");
                    throw null;
                }
            }
            SharedPreferences sharedPreferences3 = this.f4067t;
            if (sharedPreferences3 != null) {
                if (!sharedPreferences3.contains("pref_mapping_x_down_type")) {
                    SharedPreferences sharedPreferences4 = this.f4067t;
                    if (sharedPreferences4 != null) {
                        sharedPreferences4.edit().putString("pref_mapping_x_down_type", "vol_down").apply();
                    } else {
                        xl3.m8890u("sharedPrefs");
                        throw null;
                    }
                }
                SharedPreferences sharedPreferences5 = this.f4067t;
                if (sharedPreferences5 != null) {
                    if (!sharedPreferences5.contains("pref_mapping_x_lb_type")) {
                        SharedPreferences sharedPreferences6 = this.f4067t;
                        if (sharedPreferences6 != null) {
                            sharedPreferences6.edit().putString("pref_mapping_x_lb_type", "mute").apply();
                        } else {
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                    }
                    SharedPreferences sharedPreferences7 = this.f4067t;
                    if (sharedPreferences7 != null) {
                        if (!sharedPreferences7.contains("pref_mapping_x_left_type")) {
                            SharedPreferences sharedPreferences8 = this.f4067t;
                            if (sharedPreferences8 != null) {
                                sharedPreferences8.edit().putString("pref_mapping_x_left_type", "media_rewind").apply();
                            } else {
                                xl3.m8890u("sharedPrefs");
                                throw null;
                            }
                        }
                        SharedPreferences sharedPreferences9 = this.f4067t;
                        if (sharedPreferences9 != null) {
                            if (!sharedPreferences9.contains("pref_mapping_x_right_type")) {
                                SharedPreferences sharedPreferences10 = this.f4067t;
                                if (sharedPreferences10 != null) {
                                    sharedPreferences10.edit().putString("pref_mapping_x_right_type", "media_forward").apply();
                                } else {
                                    xl3.m8890u("sharedPrefs");
                                    throw null;
                                }
                            }
                            SharedPreferences sharedPreferences11 = this.f4067t;
                            if (sharedPreferences11 != null) {
                                if (!sharedPreferences11.contains("pref_mapping_x_rt_type")) {
                                    SharedPreferences sharedPreferences12 = this.f4067t;
                                    if (sharedPreferences12 != null) {
                                        sharedPreferences12.edit().putString("pref_mapping_x_rt_type", "screenshot").apply();
                                    } else {
                                        xl3.m8890u("sharedPrefs");
                                        throw null;
                                    }
                                }
                                SharedPreferences sharedPreferences13 = this.f4067t;
                                if (sharedPreferences13 != null) {
                                    if (!sharedPreferences13.contains("pref_mapping_x_rb_type")) {
                                        SharedPreferences sharedPreferences14 = this.f4067t;
                                        if (sharedPreferences14 != null) {
                                            sharedPreferences14.edit().putString("pref_mapping_x_rb_type", "none").apply();
                                        } else {
                                            xl3.m8890u("sharedPrefs");
                                            throw null;
                                        }
                                    }
                                    for (String str4 : AbstractC0484je.m4409W("lb", "rb", "lt", "rt", "up", "down", "left", "right")) {
                                        SharedPreferences sharedPreferences15 = this.f4067t;
                                        if (sharedPreferences15 != null) {
                                            if (xl3.m8871b(sharedPreferences15.getString("pref_mapping_x_" + str4 + "_type", "none"), "back")) {
                                                SharedPreferences sharedPreferences16 = this.f4067t;
                                                if (sharedPreferences16 != null) {
                                                    sharedPreferences16.edit().putString("pref_mapping_x_" + str4 + "_type", "none").remove("pref_mapping_x_" + str4 + "_value").apply();
                                                } else {
                                                    xl3.m8890u("sharedPrefs");
                                                    throw null;
                                                }
                                            }
                                        } else {
                                            xl3.m8890u("sharedPrefs");
                                            throw null;
                                        }
                                    }
                                    View findViewById2 = findViewById(R.id.btn_select_language);
                                    TextView textView = (TextView) findViewById(R.id.tv_current_language);
                                    SharedPreferences sharedPreferences17 = this.f4067t;
                                    if (sharedPreferences17 != null) {
                                        if (!sharedPreferences17.contains("pref_language")) {
                                            String language = Locale.getDefault().getLanguage();
                                            if (!xl3.m8871b(language, "ko") && !xl3.m8871b(language, "es")) {
                                                language = "en";
                                            }
                                            SharedPreferences sharedPreferences18 = this.f4067t;
                                            if (sharedPreferences18 != null) {
                                                sharedPreferences18.edit().putString("pref_language", language).apply();
                                            } else {
                                                xl3.m8890u("sharedPrefs");
                                                throw null;
                                            }
                                        }
                                        SharedPreferences sharedPreferences19 = this.f4067t;
                                        if (sharedPreferences19 != null) {
                                            String string2 = sharedPreferences19.getString("pref_language", "en");
                                            if (string2 == null) {
                                                string2 = "en";
                                            }
                                            if (textView != null) {
                                                if (string2.equals("ko")) {
                                                    string = getString(R.string.lang_ko);
                                                } else if (string2.equals("es")) {
                                                    string = getString(R.string.lang_es);
                                                } else {
                                                    string = getString(R.string.lang_en);
                                                }
                                                textView.setText(string);
                                            }
                                            final int i5 = 5;
                                            if (findViewById2 != null) {
                                                findViewById2.setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                    /* renamed from: o */
                                                    public final /* synthetic */ MainActivity f15949o;

                                                    {
                                                        this.f15949o = this;
                                                    }

                                                    @Override // android.view.View.OnClickListener
                                                    public final void onClick(View view) {
                                                        int i6 = i5;
                                                        int i7 = 2;
                                                        int i8 = 1;
                                                        final MainActivity mainActivity = this.f15949o;
                                                        switch (i6) {
                                                            case 0:
                                                                int i9 = MainActivity.f4054M;
                                                                final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                mainActivity.setRequestedOrientation(0);
                                                                Dialog dialog = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                dialog.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                ImageView imageView = (ImageView) dialog.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                imageView.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                imageView.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog));
                                                                dialog.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                    @Override // android.content.DialogInterface.OnDismissListener
                                                                    public final void onDismiss(DialogInterface dialogInterface) {
                                                                        int i10 = MainActivity.f4054M;
                                                                        MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                    }
                                                                });
                                                                dialog.show();
                                                                return;
                                                            case 1:
                                                                int i10 = MainActivity.f4054M;
                                                                Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                intent.addFlags(268435456);
                                                                mainActivity.startActivity(intent);
                                                                return;
                                                            case 2:
                                                                int i11 = MainActivity.f4054M;
                                                                Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                intent2.addFlags(268435456);
                                                                mainActivity.startActivity(intent2);
                                                                return;
                                                            case 3:
                                                                FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                if (firebaseAnalytics3 != null) {
                                                                    firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                    db0.m2411e(mainActivity);
                                                                    return;
                                                                } else {
                                                                    xl3.m8890u("firebaseAnalytics");
                                                                    throw null;
                                                                }
                                                            case 4:
                                                                int i12 = MainActivity.f4054M;
                                                                C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                String string3 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                c0879u2.f15166d = string3;
                                                                c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i8));
                                                                c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                m9008a.show();
                                                                Button button = m9008a.f19651s.f18186i;
                                                                if (button != null) {
                                                                    button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                    return;
                                                                }
                                                                return;
                                                            case 5:
                                                                int i13 = MainActivity.f4054M;
                                                                String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                String str5 = "en";
                                                                String[] strArr2 = {"en", "ko", "es"};
                                                                SharedPreferences sharedPreferences20 = mainActivity.f4067t;
                                                                if (sharedPreferences20 != null) {
                                                                    String string4 = sharedPreferences20.getString("pref_language", "en");
                                                                    if (string4 != null) {
                                                                        str5 = string4;
                                                                    }
                                                                    int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                    C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                    String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                    C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                    c0879u22.f15166d = string5;
                                                                    i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                    c0879u22.f15173k = strArr;
                                                                    c0879u22.f15175m = i20Var;
                                                                    c0879u22.f15178p = m5906o0;
                                                                    c0879u22.f15177o = true;
                                                                    c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                    c1027y22.m9011g();
                                                                    return;
                                                                }
                                                                xl3.m8890u("sharedPrefs");
                                                                throw null;
                                                            case 6:
                                                                int i14 = MainActivity.f4054M;
                                                                C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                c1027y23.m9009b(R.string.cancel);
                                                                final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                float f = mainActivity.getResources().getDisplayMetrics().density;
                                                                LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                linearLayout.setOrientation(1);
                                                                int i15 = (int) (16.0f * f);
                                                                int i16 = (int) (8.0f * f);
                                                                linearLayout.setPadding(i15, (int) (4.0f * f), i15, i16);
                                                                String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                for (final int i17 = 0; i17 < 2; i17++) {
                                                                    String str6 = strArr3[i17];
                                                                    str6.getClass();
                                                                    TextView textView2 = new TextView(mainActivity);
                                                                    textView2.setText(str6);
                                                                    textView2.setTextSize(16.0f);
                                                                    int i18 = (int) (14.0f * f);
                                                                    textView2.setPadding(i16, i18, i16, i18);
                                                                    textView2.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                        @Override // android.view.View.OnClickListener
                                                                        public final void onClick(View view2) {
                                                                            String str7;
                                                                            int i19 = MainActivity.f4054M;
                                                                            DialogC1064z2.this.dismiss();
                                                                            int i20 = i17;
                                                                            final MainActivity mainActivity2 = mainActivity;
                                                                            int i21 = 1;
                                                                            if (i20 != 0) {
                                                                                if (i20 != 1) {
                                                                                    return;
                                                                                }
                                                                                mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                return;
                                                                            }
                                                                            SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                            if (sharedPreferences21 != null) {
                                                                                String str8 = "#FFA000";
                                                                                String string6 = sharedPreferences21.getString("pref_cursor_color", "#FFA000");
                                                                                if (string6 != null) {
                                                                                    str8 = string6;
                                                                                }
                                                                                String m2096q = MainActivity.m2096q(str8);
                                                                                float f2 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                c1027y24.m9009b(R.string.cancel);
                                                                                final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                linearLayout2.setOrientation(1);
                                                                                int i22 = (int) (12.0f * f2);
                                                                                int i23 = (int) (4.0f * f2);
                                                                                linearLayout2.setPadding(i22, (int) (8.0f * f2), i22, i23);
                                                                                ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                int size = m4163c0.size();
                                                                                int i24 = size / 5;
                                                                                int i25 = 0;
                                                                                if (size % 5 == 0) {
                                                                                    i21 = 0;
                                                                                }
                                                                                ArrayList arrayList = new ArrayList(i24 + i21);
                                                                                for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                    int i27 = size - i26;
                                                                                    if (5 <= i27) {
                                                                                        i27 = 5;
                                                                                    }
                                                                                    ArrayList arrayList2 = new ArrayList(i27);
                                                                                    for (int i28 = 0; i28 < i27; i28++) {
                                                                                        arrayList2.add(m4163c0.get(i28 + i26));
                                                                                    }
                                                                                    arrayList.add(arrayList2);
                                                                                }
                                                                                int size2 = arrayList.size();
                                                                                int i29 = 0;
                                                                                while (i29 < size2) {
                                                                                    Object obj = arrayList.get(i29);
                                                                                    i29++;
                                                                                    LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                    linearLayout3.setOrientation(i25);
                                                                                    for (final String str9 : (List) obj) {
                                                                                        TextView textView3 = new TextView(mainActivity2);
                                                                                        textView3.setGravity(17);
                                                                                        textView3.setTextSize(10.0f);
                                                                                        int i30 = (int) (10.0f * f2);
                                                                                        textView3.setPadding(i23, i30, i23, i30);
                                                                                        ArrayList arrayList3 = arrayList;
                                                                                        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i25, (int) (46.0f * f2), 1.0f);
                                                                                        int i31 = (int) (3.0f * f2);
                                                                                        layoutParams.setMargins(i31, i31, i31, i31);
                                                                                        textView3.setLayoutParams(layoutParams);
                                                                                        int i32 = -16777216;
                                                                                        if (str9 != null) {
                                                                                            float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                            textView3.setBackgroundColor(Color.parseColor(str9));
                                                                                            if (blue < 140.0f) {
                                                                                                i32 = -1;
                                                                                            }
                                                                                            textView3.setTextColor(i32);
                                                                                            if (str9.equals(m2096q)) {
                                                                                                str7 = "✓ ".concat(str9);
                                                                                            } else {
                                                                                                str7 = str9;
                                                                                            }
                                                                                            textView3.setText(str7);
                                                                                            textView3.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                @Override // android.view.View.OnClickListener
                                                                                                public final void onClick(View view3) {
                                                                                                    MainActivity mainActivity3 = MainActivity.this;
                                                                                                    SharedPreferences sharedPreferences22 = mainActivity3.f4067t;
                                                                                                    if (sharedPreferences22 != null) {
                                                                                                        sharedPreferences22.edit().putString("pref_cursor_color", str9).apply();
                                                                                                        SharedPreferences sharedPreferences23 = mainActivity3.f4067t;
                                                                                                        if (sharedPreferences23 != null) {
                                                                                                            sharedPreferences23.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                            mainActivity3.m2104C();
                                                                                                            m9008a3.dismiss();
                                                                                                            return;
                                                                                                        }
                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                        throw null;
                                                                                                    }
                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                    throw null;
                                                                                                }
                                                                                            });
                                                                                        } else {
                                                                                            textView3.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                            textView3.setTextColor(-16777216);
                                                                                            textView3.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                            textView3.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                        }
                                                                                        linearLayout3.addView(textView3);
                                                                                        arrayList = arrayList3;
                                                                                        i25 = 0;
                                                                                    }
                                                                                    linearLayout2.addView(linearLayout3);
                                                                                    i25 = 0;
                                                                                }
                                                                                ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                scrollView.addView(linearLayout2);
                                                                                C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                c0990x2.f18184g = scrollView;
                                                                                c0990x2.f18185h = false;
                                                                                m9008a3.show();
                                                                                return;
                                                                            }
                                                                            xl3.m8890u("sharedPrefs");
                                                                            throw null;
                                                                        }
                                                                    });
                                                                    linearLayout.addView(textView2);
                                                                }
                                                                C0990x2 c0990x2 = m9008a2.f19651s;
                                                                c0990x2.f18184g = linearLayout;
                                                                c0990x2.f18185h = false;
                                                                m9008a2.show();
                                                                return;
                                                            default:
                                                                int i19 = MainActivity.f4054M;
                                                                C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                c20 c20Var = new c20(mainActivity, i7);
                                                                c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                c0879u23.f15170h = c20Var;
                                                                c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                    @Override // android.content.DialogInterface.OnKeyListener
                                                                    public final boolean onKey(DialogInterface dialogInterface, int i20, KeyEvent keyEvent) {
                                                                        int i21 = MainActivity.f4054M;
                                                                        if (keyEvent.getAction() == 0) {
                                                                            MainActivity mainActivity2 = MainActivity.this;
                                                                            if (i20 != 19 && i20 != 20 && i20 != 21 && i20 != 22 && i20 != 23) {
                                                                                if (i20 != 4 && i20 != 24 && i20 != 25 && i20 != 26) {
                                                                                    SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                                    if (sharedPreferences21 != null) {
                                                                                        sharedPreferences21.edit().putInt("pref_toggle_keycode", i20).apply();
                                                                                        mainActivity2.m2106E();
                                                                                        dialogInterface.dismiss();
                                                                                        return true;
                                                                                    }
                                                                                    xl3.m8890u("sharedPrefs");
                                                                                    throw null;
                                                                                }
                                                                            } else {
                                                                                Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                return true;
                                                                            }
                                                                        }
                                                                        return false;
                                                                    }
                                                                });
                                                                m9008a3.show();
                                                                return;
                                                        }
                                                    }
                                                });
                                            }
                                            View findViewById3 = findViewById(R.id.btn_select_cursor_style);
                                            final int i6 = 6;
                                            if (findViewById3 != null) {
                                                findViewById3.setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                    /* renamed from: o */
                                                    public final /* synthetic */ MainActivity f15949o;

                                                    {
                                                        this.f15949o = this;
                                                    }

                                                    @Override // android.view.View.OnClickListener
                                                    public final void onClick(View view) {
                                                        int i62 = i6;
                                                        int i7 = 2;
                                                        int i8 = 1;
                                                        final MainActivity mainActivity = this.f15949o;
                                                        switch (i62) {
                                                            case 0:
                                                                int i9 = MainActivity.f4054M;
                                                                final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                mainActivity.setRequestedOrientation(0);
                                                                Dialog dialog = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                dialog.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                ImageView imageView = (ImageView) dialog.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                imageView.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                imageView.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog));
                                                                dialog.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                    @Override // android.content.DialogInterface.OnDismissListener
                                                                    public final void onDismiss(DialogInterface dialogInterface) {
                                                                        int i10 = MainActivity.f4054M;
                                                                        MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                    }
                                                                });
                                                                dialog.show();
                                                                return;
                                                            case 1:
                                                                int i10 = MainActivity.f4054M;
                                                                Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                intent.addFlags(268435456);
                                                                mainActivity.startActivity(intent);
                                                                return;
                                                            case 2:
                                                                int i11 = MainActivity.f4054M;
                                                                Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                intent2.addFlags(268435456);
                                                                mainActivity.startActivity(intent2);
                                                                return;
                                                            case 3:
                                                                FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                if (firebaseAnalytics3 != null) {
                                                                    firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                    db0.m2411e(mainActivity);
                                                                    return;
                                                                } else {
                                                                    xl3.m8890u("firebaseAnalytics");
                                                                    throw null;
                                                                }
                                                            case 4:
                                                                int i12 = MainActivity.f4054M;
                                                                C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                String string3 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                c0879u2.f15166d = string3;
                                                                c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i8));
                                                                c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                m9008a.show();
                                                                Button button = m9008a.f19651s.f18186i;
                                                                if (button != null) {
                                                                    button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                    return;
                                                                }
                                                                return;
                                                            case 5:
                                                                int i13 = MainActivity.f4054M;
                                                                String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                String str5 = "en";
                                                                String[] strArr2 = {"en", "ko", "es"};
                                                                SharedPreferences sharedPreferences20 = mainActivity.f4067t;
                                                                if (sharedPreferences20 != null) {
                                                                    String string4 = sharedPreferences20.getString("pref_language", "en");
                                                                    if (string4 != null) {
                                                                        str5 = string4;
                                                                    }
                                                                    int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                    C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                    String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                    C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                    c0879u22.f15166d = string5;
                                                                    i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                    c0879u22.f15173k = strArr;
                                                                    c0879u22.f15175m = i20Var;
                                                                    c0879u22.f15178p = m5906o0;
                                                                    c0879u22.f15177o = true;
                                                                    c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                    c1027y22.m9011g();
                                                                    return;
                                                                }
                                                                xl3.m8890u("sharedPrefs");
                                                                throw null;
                                                            case 6:
                                                                int i14 = MainActivity.f4054M;
                                                                C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                c1027y23.m9009b(R.string.cancel);
                                                                final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                float f = mainActivity.getResources().getDisplayMetrics().density;
                                                                LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                linearLayout.setOrientation(1);
                                                                int i15 = (int) (16.0f * f);
                                                                int i16 = (int) (8.0f * f);
                                                                linearLayout.setPadding(i15, (int) (4.0f * f), i15, i16);
                                                                String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                for (final int i17 = 0; i17 < 2; i17++) {
                                                                    String str6 = strArr3[i17];
                                                                    str6.getClass();
                                                                    TextView textView2 = new TextView(mainActivity);
                                                                    textView2.setText(str6);
                                                                    textView2.setTextSize(16.0f);
                                                                    int i18 = (int) (14.0f * f);
                                                                    textView2.setPadding(i16, i18, i16, i18);
                                                                    textView2.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                        @Override // android.view.View.OnClickListener
                                                                        public final void onClick(View view2) {
                                                                            String str7;
                                                                            int i19 = MainActivity.f4054M;
                                                                            DialogC1064z2.this.dismiss();
                                                                            int i20 = i17;
                                                                            final MainActivity mainActivity2 = mainActivity;
                                                                            int i21 = 1;
                                                                            if (i20 != 0) {
                                                                                if (i20 != 1) {
                                                                                    return;
                                                                                }
                                                                                mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                return;
                                                                            }
                                                                            SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                            if (sharedPreferences21 != null) {
                                                                                String str8 = "#FFA000";
                                                                                String string6 = sharedPreferences21.getString("pref_cursor_color", "#FFA000");
                                                                                if (string6 != null) {
                                                                                    str8 = string6;
                                                                                }
                                                                                String m2096q = MainActivity.m2096q(str8);
                                                                                float f2 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                c1027y24.m9009b(R.string.cancel);
                                                                                final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                linearLayout2.setOrientation(1);
                                                                                int i22 = (int) (12.0f * f2);
                                                                                int i23 = (int) (4.0f * f2);
                                                                                linearLayout2.setPadding(i22, (int) (8.0f * f2), i22, i23);
                                                                                ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                int size = m4163c0.size();
                                                                                int i24 = size / 5;
                                                                                int i25 = 0;
                                                                                if (size % 5 == 0) {
                                                                                    i21 = 0;
                                                                                }
                                                                                ArrayList arrayList = new ArrayList(i24 + i21);
                                                                                for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                    int i27 = size - i26;
                                                                                    if (5 <= i27) {
                                                                                        i27 = 5;
                                                                                    }
                                                                                    ArrayList arrayList2 = new ArrayList(i27);
                                                                                    for (int i28 = 0; i28 < i27; i28++) {
                                                                                        arrayList2.add(m4163c0.get(i28 + i26));
                                                                                    }
                                                                                    arrayList.add(arrayList2);
                                                                                }
                                                                                int size2 = arrayList.size();
                                                                                int i29 = 0;
                                                                                while (i29 < size2) {
                                                                                    Object obj = arrayList.get(i29);
                                                                                    i29++;
                                                                                    LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                    linearLayout3.setOrientation(i25);
                                                                                    for (final String str9 : (List) obj) {
                                                                                        TextView textView3 = new TextView(mainActivity2);
                                                                                        textView3.setGravity(17);
                                                                                        textView3.setTextSize(10.0f);
                                                                                        int i30 = (int) (10.0f * f2);
                                                                                        textView3.setPadding(i23, i30, i23, i30);
                                                                                        ArrayList arrayList3 = arrayList;
                                                                                        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i25, (int) (46.0f * f2), 1.0f);
                                                                                        int i31 = (int) (3.0f * f2);
                                                                                        layoutParams.setMargins(i31, i31, i31, i31);
                                                                                        textView3.setLayoutParams(layoutParams);
                                                                                        int i32 = -16777216;
                                                                                        if (str9 != null) {
                                                                                            float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                            textView3.setBackgroundColor(Color.parseColor(str9));
                                                                                            if (blue < 140.0f) {
                                                                                                i32 = -1;
                                                                                            }
                                                                                            textView3.setTextColor(i32);
                                                                                            if (str9.equals(m2096q)) {
                                                                                                str7 = "✓ ".concat(str9);
                                                                                            } else {
                                                                                                str7 = str9;
                                                                                            }
                                                                                            textView3.setText(str7);
                                                                                            textView3.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                @Override // android.view.View.OnClickListener
                                                                                                public final void onClick(View view3) {
                                                                                                    MainActivity mainActivity3 = MainActivity.this;
                                                                                                    SharedPreferences sharedPreferences22 = mainActivity3.f4067t;
                                                                                                    if (sharedPreferences22 != null) {
                                                                                                        sharedPreferences22.edit().putString("pref_cursor_color", str9).apply();
                                                                                                        SharedPreferences sharedPreferences23 = mainActivity3.f4067t;
                                                                                                        if (sharedPreferences23 != null) {
                                                                                                            sharedPreferences23.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                            mainActivity3.m2104C();
                                                                                                            m9008a3.dismiss();
                                                                                                            return;
                                                                                                        }
                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                        throw null;
                                                                                                    }
                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                    throw null;
                                                                                                }
                                                                                            });
                                                                                        } else {
                                                                                            textView3.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                            textView3.setTextColor(-16777216);
                                                                                            textView3.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                            textView3.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                        }
                                                                                        linearLayout3.addView(textView3);
                                                                                        arrayList = arrayList3;
                                                                                        i25 = 0;
                                                                                    }
                                                                                    linearLayout2.addView(linearLayout3);
                                                                                    i25 = 0;
                                                                                }
                                                                                ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                scrollView.addView(linearLayout2);
                                                                                C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                c0990x2.f18184g = scrollView;
                                                                                c0990x2.f18185h = false;
                                                                                m9008a3.show();
                                                                                return;
                                                                            }
                                                                            xl3.m8890u("sharedPrefs");
                                                                            throw null;
                                                                        }
                                                                    });
                                                                    linearLayout.addView(textView2);
                                                                }
                                                                C0990x2 c0990x2 = m9008a2.f19651s;
                                                                c0990x2.f18184g = linearLayout;
                                                                c0990x2.f18185h = false;
                                                                m9008a2.show();
                                                                return;
                                                            default:
                                                                int i19 = MainActivity.f4054M;
                                                                C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                c20 c20Var = new c20(mainActivity, i7);
                                                                c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                c0879u23.f15170h = c20Var;
                                                                c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                    @Override // android.content.DialogInterface.OnKeyListener
                                                                    public final boolean onKey(DialogInterface dialogInterface, int i20, KeyEvent keyEvent) {
                                                                        int i21 = MainActivity.f4054M;
                                                                        if (keyEvent.getAction() == 0) {
                                                                            MainActivity mainActivity2 = MainActivity.this;
                                                                            if (i20 != 19 && i20 != 20 && i20 != 21 && i20 != 22 && i20 != 23) {
                                                                                if (i20 != 4 && i20 != 24 && i20 != 25 && i20 != 26) {
                                                                                    SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                                    if (sharedPreferences21 != null) {
                                                                                        sharedPreferences21.edit().putInt("pref_toggle_keycode", i20).apply();
                                                                                        mainActivity2.m2106E();
                                                                                        dialogInterface.dismiss();
                                                                                        return true;
                                                                                    }
                                                                                    xl3.m8890u("sharedPrefs");
                                                                                    throw null;
                                                                                }
                                                                            } else {
                                                                                Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                return true;
                                                                            }
                                                                        }
                                                                        return false;
                                                                    }
                                                                });
                                                                m9008a3.show();
                                                                return;
                                                        }
                                                    }
                                                });
                                            }
                                            m2104C();
                                            SwitchCompat switchCompat = (SwitchCompat) findViewById(R.id.switch_mouse_enabled);
                                            SharedPreferences sharedPreferences20 = this.f4067t;
                                            if (sharedPreferences20 != null) {
                                                switchCompat.setChecked(sharedPreferences20.getBoolean("pref_mouse_enabled", true));
                                                final int i7 = 2;
                                                switchCompat.setOnCheckedChangeListener(new u10(this, i7));
                                                View findViewById4 = findViewById(R.id.btn_customize_toggle_key);
                                                final int i8 = 7;
                                                if (findViewById4 != null) {
                                                    findViewById4.setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                        /* renamed from: o */
                                                        public final /* synthetic */ MainActivity f15949o;

                                                        {
                                                            this.f15949o = this;
                                                        }

                                                        @Override // android.view.View.OnClickListener
                                                        public final void onClick(View view) {
                                                            int i62 = i8;
                                                            int i72 = 2;
                                                            int i82 = 1;
                                                            final MainActivity mainActivity = this.f15949o;
                                                            switch (i62) {
                                                                case 0:
                                                                    int i9 = MainActivity.f4054M;
                                                                    final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                    mainActivity.setRequestedOrientation(0);
                                                                    Dialog dialog = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                    dialog.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                    ImageView imageView = (ImageView) dialog.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                    imageView.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                    imageView.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog));
                                                                    dialog.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                        @Override // android.content.DialogInterface.OnDismissListener
                                                                        public final void onDismiss(DialogInterface dialogInterface) {
                                                                            int i10 = MainActivity.f4054M;
                                                                            MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                        }
                                                                    });
                                                                    dialog.show();
                                                                    return;
                                                                case 1:
                                                                    int i10 = MainActivity.f4054M;
                                                                    Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                    intent.addFlags(268435456);
                                                                    mainActivity.startActivity(intent);
                                                                    return;
                                                                case 2:
                                                                    int i11 = MainActivity.f4054M;
                                                                    Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                    intent2.addFlags(268435456);
                                                                    mainActivity.startActivity(intent2);
                                                                    return;
                                                                case 3:
                                                                    FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                    if (firebaseAnalytics3 != null) {
                                                                        firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                        db0.m2411e(mainActivity);
                                                                        return;
                                                                    } else {
                                                                        xl3.m8890u("firebaseAnalytics");
                                                                        throw null;
                                                                    }
                                                                case 4:
                                                                    int i12 = MainActivity.f4054M;
                                                                    C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                    String string3 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                    C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                    c0879u2.f15166d = string3;
                                                                    c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                    c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                    c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                    DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                    m9008a.show();
                                                                    Button button = m9008a.f19651s.f18186i;
                                                                    if (button != null) {
                                                                        button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                        return;
                                                                    }
                                                                    return;
                                                                case 5:
                                                                    int i13 = MainActivity.f4054M;
                                                                    String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                    String str5 = "en";
                                                                    String[] strArr2 = {"en", "ko", "es"};
                                                                    SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                    if (sharedPreferences202 != null) {
                                                                        String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                        if (string4 != null) {
                                                                            str5 = string4;
                                                                        }
                                                                        int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                        C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                        String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                        C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                        c0879u22.f15166d = string5;
                                                                        i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                        c0879u22.f15173k = strArr;
                                                                        c0879u22.f15175m = i20Var;
                                                                        c0879u22.f15178p = m5906o0;
                                                                        c0879u22.f15177o = true;
                                                                        c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                        c1027y22.m9011g();
                                                                        return;
                                                                    }
                                                                    xl3.m8890u("sharedPrefs");
                                                                    throw null;
                                                                case 6:
                                                                    int i14 = MainActivity.f4054M;
                                                                    C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                    ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                    c1027y23.m9009b(R.string.cancel);
                                                                    final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                    float f = mainActivity.getResources().getDisplayMetrics().density;
                                                                    LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                    linearLayout.setOrientation(1);
                                                                    int i15 = (int) (16.0f * f);
                                                                    int i16 = (int) (8.0f * f);
                                                                    linearLayout.setPadding(i15, (int) (4.0f * f), i15, i16);
                                                                    String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                    for (final int i17 = 0; i17 < 2; i17++) {
                                                                        String str6 = strArr3[i17];
                                                                        str6.getClass();
                                                                        TextView textView2 = new TextView(mainActivity);
                                                                        textView2.setText(str6);
                                                                        textView2.setTextSize(16.0f);
                                                                        int i18 = (int) (14.0f * f);
                                                                        textView2.setPadding(i16, i18, i16, i18);
                                                                        textView2.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                            @Override // android.view.View.OnClickListener
                                                                            public final void onClick(View view2) {
                                                                                String str7;
                                                                                int i19 = MainActivity.f4054M;
                                                                                DialogC1064z2.this.dismiss();
                                                                                int i20 = i17;
                                                                                final MainActivity mainActivity2 = mainActivity;
                                                                                int i21 = 1;
                                                                                if (i20 != 0) {
                                                                                    if (i20 != 1) {
                                                                                        return;
                                                                                    }
                                                                                    mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                    return;
                                                                                }
                                                                                SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                                if (sharedPreferences21 != null) {
                                                                                    String str8 = "#FFA000";
                                                                                    String string6 = sharedPreferences21.getString("pref_cursor_color", "#FFA000");
                                                                                    if (string6 != null) {
                                                                                        str8 = string6;
                                                                                    }
                                                                                    String m2096q = MainActivity.m2096q(str8);
                                                                                    float f2 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                    C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                    ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                    c1027y24.m9009b(R.string.cancel);
                                                                                    final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                    LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                    linearLayout2.setOrientation(1);
                                                                                    int i22 = (int) (12.0f * f2);
                                                                                    int i23 = (int) (4.0f * f2);
                                                                                    linearLayout2.setPadding(i22, (int) (8.0f * f2), i22, i23);
                                                                                    ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                    int size = m4163c0.size();
                                                                                    int i24 = size / 5;
                                                                                    int i25 = 0;
                                                                                    if (size % 5 == 0) {
                                                                                        i21 = 0;
                                                                                    }
                                                                                    ArrayList arrayList = new ArrayList(i24 + i21);
                                                                                    for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                        int i27 = size - i26;
                                                                                        if (5 <= i27) {
                                                                                            i27 = 5;
                                                                                        }
                                                                                        ArrayList arrayList2 = new ArrayList(i27);
                                                                                        for (int i28 = 0; i28 < i27; i28++) {
                                                                                            arrayList2.add(m4163c0.get(i28 + i26));
                                                                                        }
                                                                                        arrayList.add(arrayList2);
                                                                                    }
                                                                                    int size2 = arrayList.size();
                                                                                    int i29 = 0;
                                                                                    while (i29 < size2) {
                                                                                        Object obj = arrayList.get(i29);
                                                                                        i29++;
                                                                                        LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                        linearLayout3.setOrientation(i25);
                                                                                        for (final String str9 : (List) obj) {
                                                                                            TextView textView3 = new TextView(mainActivity2);
                                                                                            textView3.setGravity(17);
                                                                                            textView3.setTextSize(10.0f);
                                                                                            int i30 = (int) (10.0f * f2);
                                                                                            textView3.setPadding(i23, i30, i23, i30);
                                                                                            ArrayList arrayList3 = arrayList;
                                                                                            LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i25, (int) (46.0f * f2), 1.0f);
                                                                                            int i31 = (int) (3.0f * f2);
                                                                                            layoutParams.setMargins(i31, i31, i31, i31);
                                                                                            textView3.setLayoutParams(layoutParams);
                                                                                            int i32 = -16777216;
                                                                                            if (str9 != null) {
                                                                                                float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                textView3.setBackgroundColor(Color.parseColor(str9));
                                                                                                if (blue < 140.0f) {
                                                                                                    i32 = -1;
                                                                                                }
                                                                                                textView3.setTextColor(i32);
                                                                                                if (str9.equals(m2096q)) {
                                                                                                    str7 = "✓ ".concat(str9);
                                                                                                } else {
                                                                                                    str7 = str9;
                                                                                                }
                                                                                                textView3.setText(str7);
                                                                                                textView3.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                    public final void onClick(View view3) {
                                                                                                        MainActivity mainActivity3 = MainActivity.this;
                                                                                                        SharedPreferences sharedPreferences22 = mainActivity3.f4067t;
                                                                                                        if (sharedPreferences22 != null) {
                                                                                                            sharedPreferences22.edit().putString("pref_cursor_color", str9).apply();
                                                                                                            SharedPreferences sharedPreferences23 = mainActivity3.f4067t;
                                                                                                            if (sharedPreferences23 != null) {
                                                                                                                sharedPreferences23.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                mainActivity3.m2104C();
                                                                                                                m9008a3.dismiss();
                                                                                                                return;
                                                                                                            }
                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                            throw null;
                                                                                                        }
                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                        throw null;
                                                                                                    }
                                                                                                });
                                                                                            } else {
                                                                                                textView3.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                textView3.setTextColor(-16777216);
                                                                                                textView3.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                textView3.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                            }
                                                                                            linearLayout3.addView(textView3);
                                                                                            arrayList = arrayList3;
                                                                                            i25 = 0;
                                                                                        }
                                                                                        linearLayout2.addView(linearLayout3);
                                                                                        i25 = 0;
                                                                                    }
                                                                                    ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                    scrollView.addView(linearLayout2);
                                                                                    C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                    c0990x2.f18184g = scrollView;
                                                                                    c0990x2.f18185h = false;
                                                                                    m9008a3.show();
                                                                                    return;
                                                                                }
                                                                                xl3.m8890u("sharedPrefs");
                                                                                throw null;
                                                                            }
                                                                        });
                                                                        linearLayout.addView(textView2);
                                                                    }
                                                                    C0990x2 c0990x2 = m9008a2.f19651s;
                                                                    c0990x2.f18184g = linearLayout;
                                                                    c0990x2.f18185h = false;
                                                                    m9008a2.show();
                                                                    return;
                                                                default:
                                                                    int i19 = MainActivity.f4054M;
                                                                    C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                    C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                    ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                    c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                    c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                    c20 c20Var = new c20(mainActivity, i72);
                                                                    c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                    c0879u23.f15170h = c20Var;
                                                                    c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                    DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                    m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                        @Override // android.content.DialogInterface.OnKeyListener
                                                                        public final boolean onKey(DialogInterface dialogInterface, int i20, KeyEvent keyEvent) {
                                                                            int i21 = MainActivity.f4054M;
                                                                            if (keyEvent.getAction() == 0) {
                                                                                MainActivity mainActivity2 = MainActivity.this;
                                                                                if (i20 != 19 && i20 != 20 && i20 != 21 && i20 != 22 && i20 != 23) {
                                                                                    if (i20 != 4 && i20 != 24 && i20 != 25 && i20 != 26) {
                                                                                        SharedPreferences sharedPreferences21 = mainActivity2.f4067t;
                                                                                        if (sharedPreferences21 != null) {
                                                                                            sharedPreferences21.edit().putInt("pref_toggle_keycode", i20).apply();
                                                                                            mainActivity2.m2106E();
                                                                                            dialogInterface.dismiss();
                                                                                            return true;
                                                                                        }
                                                                                        xl3.m8890u("sharedPrefs");
                                                                                        throw null;
                                                                                    }
                                                                                } else {
                                                                                    Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                    return true;
                                                                                }
                                                                            }
                                                                            return false;
                                                                        }
                                                                    });
                                                                    m9008a3.show();
                                                                    return;
                                                            }
                                                        }
                                                    });
                                                }
                                                m2106E();
                                                SeekBar seekBar = (SeekBar) findViewById(R.id.seekbar_l3_long_press);
                                                TextView textView2 = (TextView) findViewById(R.id.tv_l3_long_press_val);
                                                SharedPreferences sharedPreferences21 = this.f4067t;
                                                if (sharedPreferences21 != null) {
                                                    int i9 = sharedPreferences21.getInt("pref_l3_long_press_duration", 0);
                                                    seekBar.setProgress(i9);
                                                    textView2.setText(m2108o(i9));
                                                    seekBar.setOnSeekBarChangeListener(new r20(textView2, this, 11));
                                                    SwitchCompat switchCompat2 = (SwitchCompat) findViewById(R.id.switch_swap_ab_buttons);
                                                    SharedPreferences sharedPreferences22 = this.f4067t;
                                                    if (sharedPreferences22 != null) {
                                                        switchCompat2.setChecked(sharedPreferences22.getBoolean("pref_swap_ab_buttons", false));
                                                        switchCompat2.setOnCheckedChangeListener(new u10(this, 3));
                                                        final SwitchCompat switchCompat3 = (SwitchCompat) findViewById(R.id.switch_dex_lockscreen);
                                                        SharedPreferences sharedPreferences23 = this.f4067t;
                                                        if (sharedPreferences23 != null) {
                                                            switchCompat3.setChecked(sharedPreferences23.getBoolean("pref_dex_lockscreen_enabled", false));
                                                            switchCompat3.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() { // from class: a20
                                                                @Override // android.widget.CompoundButton.OnCheckedChangeListener
                                                                public final void onCheckedChanged(CompoundButton compoundButton, boolean z4) {
                                                                    int i10 = i3;
                                                                    MainActivity mainActivity = this;
                                                                    SwitchCompat switchCompat4 = switchCompat3;
                                                                    int i11 = 0;
                                                                    switch (i10) {
                                                                        case 0:
                                                                            int i12 = MainActivity.f4054M;
                                                                            compoundButton.getClass();
                                                                            if (z4 && !db0.m2408b()) {
                                                                                switchCompat4.setChecked(false);
                                                                                C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                c0879u2.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.dex_pro_msg);
                                                                                c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 3));
                                                                                c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                c1027y2.m9011g();
                                                                                return;
                                                                            }
                                                                            SharedPreferences sharedPreferences24 = mainActivity.f4067t;
                                                                            if (sharedPreferences24 != null) {
                                                                                sharedPreferences24.edit().putBoolean("pref_dex_lockscreen_enabled", z4).apply();
                                                                                return;
                                                                            } else {
                                                                                xl3.m8890u("sharedPrefs");
                                                                                throw null;
                                                                            }
                                                                        case 1:
                                                                            int i13 = MainActivity.f4054M;
                                                                            compoundButton.getClass();
                                                                            if (z4 && !db0.m2408b()) {
                                                                                switchCompat4.setChecked(false);
                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                c0879u22.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                c0879u22.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.keyboard_pro_required);
                                                                                c1027y22.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, i11));
                                                                                c0879u22.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                c1027y22.m9011g();
                                                                                return;
                                                                            }
                                                                            SharedPreferences sharedPreferences25 = mainActivity.f4067t;
                                                                            if (sharedPreferences25 != null) {
                                                                                sharedPreferences25.edit().putBoolean("pref_keyboard_enabled", z4).apply();
                                                                                return;
                                                                            } else {
                                                                                xl3.m8890u("sharedPrefs");
                                                                                throw null;
                                                                            }
                                                                        default:
                                                                            int i14 = MainActivity.f4054M;
                                                                            compoundButton.getClass();
                                                                            if (z4 && !db0.m2408b()) {
                                                                                switchCompat4.setChecked(false);
                                                                                C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                C0879u2 c0879u23 = (C0879u2) c1027y23.f18934o;
                                                                                c0879u23.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                c0879u23.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.haptic_pro_msg);
                                                                                c1027y23.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 4));
                                                                                c0879u23.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                c1027y23.m9011g();
                                                                                return;
                                                                            }
                                                                            SharedPreferences sharedPreferences26 = mainActivity.f4067t;
                                                                            if (sharedPreferences26 != null) {
                                                                                sharedPreferences26.edit().putBoolean("pref_haptic_feedback", z4).apply();
                                                                                return;
                                                                            } else {
                                                                                xl3.m8890u("sharedPrefs");
                                                                                throw null;
                                                                            }
                                                                    }
                                                                }
                                                            });
                                                            SwitchCompat switchCompat4 = (SwitchCompat) findViewById(R.id.switch_force_mirroring);
                                                            SharedPreferences sharedPreferences24 = this.f4067t;
                                                            if (sharedPreferences24 != null) {
                                                                switchCompat4.setChecked(sharedPreferences24.getBoolean("pref_force_mirroring", false));
                                                                switchCompat4.setOnCheckedChangeListener(new u10(this, 4));
                                                                final SwitchCompat switchCompat5 = (SwitchCompat) findViewById(R.id.switch_keyboard_input);
                                                                SharedPreferences sharedPreferences25 = this.f4067t;
                                                                if (sharedPreferences25 != null) {
                                                                    switchCompat5.setChecked(sharedPreferences25.getBoolean("pref_keyboard_enabled", true));
                                                                    switchCompat5.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() { // from class: a20
                                                                        @Override // android.widget.CompoundButton.OnCheckedChangeListener
                                                                        public final void onCheckedChanged(CompoundButton compoundButton, boolean z4) {
                                                                            int i10 = i4;
                                                                            MainActivity mainActivity = this;
                                                                            SwitchCompat switchCompat42 = switchCompat5;
                                                                            int i11 = 0;
                                                                            switch (i10) {
                                                                                case 0:
                                                                                    int i12 = MainActivity.f4054M;
                                                                                    compoundButton.getClass();
                                                                                    if (z4 && !db0.m2408b()) {
                                                                                        switchCompat42.setChecked(false);
                                                                                        C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                        C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                        c0879u2.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                        c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.dex_pro_msg);
                                                                                        c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 3));
                                                                                        c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                        c1027y2.m9011g();
                                                                                        return;
                                                                                    }
                                                                                    SharedPreferences sharedPreferences242 = mainActivity.f4067t;
                                                                                    if (sharedPreferences242 != null) {
                                                                                        sharedPreferences242.edit().putBoolean("pref_dex_lockscreen_enabled", z4).apply();
                                                                                        return;
                                                                                    } else {
                                                                                        xl3.m8890u("sharedPrefs");
                                                                                        throw null;
                                                                                    }
                                                                                case 1:
                                                                                    int i13 = MainActivity.f4054M;
                                                                                    compoundButton.getClass();
                                                                                    if (z4 && !db0.m2408b()) {
                                                                                        switchCompat42.setChecked(false);
                                                                                        C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                        C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                        c0879u22.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                        c0879u22.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.keyboard_pro_required);
                                                                                        c1027y22.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, i11));
                                                                                        c0879u22.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                        c1027y22.m9011g();
                                                                                        return;
                                                                                    }
                                                                                    SharedPreferences sharedPreferences252 = mainActivity.f4067t;
                                                                                    if (sharedPreferences252 != null) {
                                                                                        sharedPreferences252.edit().putBoolean("pref_keyboard_enabled", z4).apply();
                                                                                        return;
                                                                                    } else {
                                                                                        xl3.m8890u("sharedPrefs");
                                                                                        throw null;
                                                                                    }
                                                                                default:
                                                                                    int i14 = MainActivity.f4054M;
                                                                                    compoundButton.getClass();
                                                                                    if (z4 && !db0.m2408b()) {
                                                                                        switchCompat42.setChecked(false);
                                                                                        C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                        C0879u2 c0879u23 = (C0879u2) c1027y23.f18934o;
                                                                                        c0879u23.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                        c0879u23.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.haptic_pro_msg);
                                                                                        c1027y23.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 4));
                                                                                        c0879u23.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                        c1027y23.m9011g();
                                                                                        return;
                                                                                    }
                                                                                    SharedPreferences sharedPreferences26 = mainActivity.f4067t;
                                                                                    if (sharedPreferences26 != null) {
                                                                                        sharedPreferences26.edit().putBoolean("pref_haptic_feedback", z4).apply();
                                                                                        return;
                                                                                    } else {
                                                                                        xl3.m8890u("sharedPrefs");
                                                                                        throw null;
                                                                                    }
                                                                            }
                                                                        }
                                                                    });
                                                                    final SwitchCompat switchCompat6 = (SwitchCompat) findViewById(R.id.switch_haptic_feedback);
                                                                    SharedPreferences sharedPreferences26 = this.f4067t;
                                                                    if (sharedPreferences26 != null) {
                                                                        switchCompat6.setChecked(sharedPreferences26.getBoolean("pref_haptic_feedback", true));
                                                                        switchCompat6.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() { // from class: a20
                                                                            @Override // android.widget.CompoundButton.OnCheckedChangeListener
                                                                            public final void onCheckedChanged(CompoundButton compoundButton, boolean z4) {
                                                                                int i10 = i7;
                                                                                MainActivity mainActivity = this;
                                                                                SwitchCompat switchCompat42 = switchCompat6;
                                                                                int i11 = 0;
                                                                                switch (i10) {
                                                                                    case 0:
                                                                                        int i12 = MainActivity.f4054M;
                                                                                        compoundButton.getClass();
                                                                                        if (z4 && !db0.m2408b()) {
                                                                                            switchCompat42.setChecked(false);
                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                            c0879u2.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.dex_pro_msg);
                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 3));
                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                            c1027y2.m9011g();
                                                                                            return;
                                                                                        }
                                                                                        SharedPreferences sharedPreferences242 = mainActivity.f4067t;
                                                                                        if (sharedPreferences242 != null) {
                                                                                            sharedPreferences242.edit().putBoolean("pref_dex_lockscreen_enabled", z4).apply();
                                                                                            return;
                                                                                        } else {
                                                                                            xl3.m8890u("sharedPrefs");
                                                                                            throw null;
                                                                                        }
                                                                                    case 1:
                                                                                        int i13 = MainActivity.f4054M;
                                                                                        compoundButton.getClass();
                                                                                        if (z4 && !db0.m2408b()) {
                                                                                            switchCompat42.setChecked(false);
                                                                                            C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                            C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                            c0879u22.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                            c0879u22.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.keyboard_pro_required);
                                                                                            c1027y22.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, i11));
                                                                                            c0879u22.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                            c1027y22.m9011g();
                                                                                            return;
                                                                                        }
                                                                                        SharedPreferences sharedPreferences252 = mainActivity.f4067t;
                                                                                        if (sharedPreferences252 != null) {
                                                                                            sharedPreferences252.edit().putBoolean("pref_keyboard_enabled", z4).apply();
                                                                                            return;
                                                                                        } else {
                                                                                            xl3.m8890u("sharedPrefs");
                                                                                            throw null;
                                                                                        }
                                                                                    default:
                                                                                        int i14 = MainActivity.f4054M;
                                                                                        compoundButton.getClass();
                                                                                        if (z4 && !db0.m2408b()) {
                                                                                            switchCompat42.setChecked(false);
                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y23.f18934o;
                                                                                            c0879u23.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.pro_feature);
                                                                                            c0879u23.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.haptic_pro_msg);
                                                                                            c1027y23.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.upgrade), new c20(mainActivity, 4));
                                                                                            c0879u23.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                            c1027y23.m9011g();
                                                                                            return;
                                                                                        }
                                                                                        SharedPreferences sharedPreferences262 = mainActivity.f4067t;
                                                                                        if (sharedPreferences262 != null) {
                                                                                            sharedPreferences262.edit().putBoolean("pref_haptic_feedback", z4).apply();
                                                                                            return;
                                                                                        } else {
                                                                                            xl3.m8890u("sharedPrefs");
                                                                                            throw null;
                                                                                        }
                                                                                }
                                                                            }
                                                                        });
                                                                        CheckBox checkBox = (CheckBox) findViewById(R.id.cb_kb_lang_en);
                                                                        CheckBox checkBox2 = (CheckBox) findViewById(R.id.cb_kb_lang_ko);
                                                                        CheckBox checkBox3 = (CheckBox) findViewById(R.id.cb_kb_lang_es);
                                                                        SharedPreferences sharedPreferences27 = this.f4067t;
                                                                        if (sharedPreferences27 != null) {
                                                                            checkBox.setChecked(sharedPreferences27.getBoolean("pref_kb_lang_en", true));
                                                                            SharedPreferences sharedPreferences28 = this.f4067t;
                                                                            if (sharedPreferences28 != null) {
                                                                                checkBox2.setChecked(sharedPreferences28.getBoolean("pref_kb_lang_ko", true));
                                                                                SharedPreferences sharedPreferences29 = this.f4067t;
                                                                                if (sharedPreferences29 != null) {
                                                                                    checkBox3.setChecked(sharedPreferences29.getBoolean("pref_kb_lang_es", false));
                                                                                    int i10 = 3;
                                                                                    int i11 = 4;
                                                                                    checkBox.setOnCheckedChangeListener(new t10(checkBox2, checkBox3, this, checkBox, 4));
                                                                                    checkBox2.setOnCheckedChangeListener(new t10(checkBox, checkBox3, this, checkBox2, 5));
                                                                                    checkBox3.setOnCheckedChangeListener(new t10(checkBox, checkBox2, this, checkBox3, 0));
                                                                                    m2105D();
                                                                                    SeekBar seekBar2 = (SeekBar) findViewById(R.id.seekbar_kb_repeat);
                                                                                    TextView textView3 = (TextView) findViewById(R.id.tv_kb_repeat_val);
                                                                                    SharedPreferences sharedPreferences30 = this.f4067t;
                                                                                    if (sharedPreferences30 != null) {
                                                                                        int i12 = sharedPreferences30.getInt("pref_kb_nav_interval", 150);
                                                                                        seekBar2.setProgress((i12 - 50) / 10);
                                                                                        textView3.setText(m2095n(i12));
                                                                                        seekBar2.setOnSeekBarChangeListener(new r20(textView3, this, i3));
                                                                                        SeekBar seekBar3 = (SeekBar) findViewById(R.id.seekbar_kb_delay);
                                                                                        TextView textView4 = (TextView) findViewById(R.id.tv_kb_delay_val);
                                                                                        SharedPreferences sharedPreferences31 = this.f4067t;
                                                                                        if (sharedPreferences31 != null) {
                                                                                            int i13 = sharedPreferences31.getInt("pref_kb_nav_delay", 300);
                                                                                            seekBar3.setProgress((i13 - 200) / 50);
                                                                                            textView4.setText(m2095n(i13));
                                                                                            seekBar3.setOnSeekBarChangeListener(new r20(textView4, this, i4));
                                                                                            SwitchCompat switchCompat7 = (SwitchCompat) findViewById(R.id.switch_kb_move_sound);
                                                                                            SharedPreferences sharedPreferences32 = this.f4067t;
                                                                                            if (sharedPreferences32 != null) {
                                                                                                switchCompat7.setChecked(sharedPreferences32.getBoolean("pref_kb_move_sound", false));
                                                                                                switchCompat7.setOnCheckedChangeListener(new u10(this, i3));
                                                                                                SeekBar seekBar4 = (SeekBar) findViewById(R.id.seekbar_kb_dex_width);
                                                                                                TextView textView5 = (TextView) findViewById(R.id.tv_kb_dex_width_val);
                                                                                                SharedPreferences sharedPreferences33 = this.f4067t;
                                                                                                if (sharedPreferences33 != null) {
                                                                                                    int i14 = sharedPreferences33.getInt("pref_kb_dex_width", 50);
                                                                                                    seekBar4.setProgress(i14 - 20);
                                                                                                    textView5.setText(getString(R.string.kb_dex_pct_format, Integer.valueOf(i14)));
                                                                                                    seekBar4.setOnSeekBarChangeListener(new r20(textView5, this, i7));
                                                                                                    SeekBar seekBar5 = (SeekBar) findViewById(R.id.seekbar_kb_dex_height);
                                                                                                    TextView textView6 = (TextView) findViewById(R.id.tv_kb_dex_height_val);
                                                                                                    SharedPreferences sharedPreferences34 = this.f4067t;
                                                                                                    if (sharedPreferences34 != null) {
                                                                                                        int i15 = sharedPreferences34.getInt("pref_kb_dex_height", 100);
                                                                                                        seekBar5.setProgress((i15 - 40) / 5);
                                                                                                        textView6.setText(getString(R.string.kb_dex_pct_format, Integer.valueOf(i15)));
                                                                                                        seekBar5.setOnSeekBarChangeListener(new r20(textView6, this, i10));
                                                                                                        CheckBox checkBox4 = (CheckBox) findViewById(R.id.cb_kb_dex_pos_left);
                                                                                                        CheckBox checkBox5 = (CheckBox) findViewById(R.id.cb_kb_dex_pos_center);
                                                                                                        CheckBox checkBox6 = (CheckBox) findViewById(R.id.cb_kb_dex_pos_right);
                                                                                                        SharedPreferences sharedPreferences35 = this.f4067t;
                                                                                                        if (sharedPreferences35 != null) {
                                                                                                            String string3 = sharedPreferences35.getString("pref_kb_dex_pos", "center");
                                                                                                            if (string3 == null) {
                                                                                                                string3 = "center";
                                                                                                            }
                                                                                                            checkBox4.setChecked(string3.equals("left"));
                                                                                                            checkBox5.setChecked(string3.equals("center"));
                                                                                                            checkBox6.setChecked(string3.equals("right"));
                                                                                                            checkBox4.setOnCheckedChangeListener(new t10(this, checkBox4, checkBox5, checkBox6, 1));
                                                                                                            checkBox5.setOnCheckedChangeListener(new t10(this, checkBox4, checkBox5, checkBox6, 2));
                                                                                                            checkBox6.setOnCheckedChangeListener(new t10(this, checkBox4, checkBox5, checkBox6, 3));
                                                                                                            SwitchCompat switchCompat8 = (SwitchCompat) findViewById(R.id.switch_debug_pro);
                                                                                                            TextView textView7 = (TextView) findViewById(R.id.tv_debug_pro_desc);
                                                                                                            if (db0.f4578b) {
                                                                                                                switchCompat8.setVisibility(0);
                                                                                                                textView7.setVisibility(0);
                                                                                                                if (db0.f4578b && db0.f4579c) {
                                                                                                                    z3 = true;
                                                                                                                } else {
                                                                                                                    z3 = false;
                                                                                                                }
                                                                                                                switchCompat8.setChecked(z3);
                                                                                                                switchCompat8.setOnCheckedChangeListener(new u10(this, i4));
                                                                                                            } else {
                                                                                                                switchCompat8.setVisibility(8);
                                                                                                                textView7.setVisibility(8);
                                                                                                            }
                                                                                                            SeekBar seekBar6 = (SeekBar) findViewById(R.id.seekbar_vibration_intensity);
                                                                                                            TextView textView8 = (TextView) findViewById(R.id.tv_vibration_intensity_val);
                                                                                                            SharedPreferences sharedPreferences36 = this.f4067t;
                                                                                                            if (sharedPreferences36 != null) {
                                                                                                                int i16 = sharedPreferences36.getInt("pref_vibration_intensity", 255);
                                                                                                                seekBar6.setProgress(i16);
                                                                                                                textView8.setText(String.valueOf(i16));
                                                                                                                seekBar6.setOnSeekBarChangeListener(new s20(seekBar6, textView8, this));
                                                                                                                SeekBar seekBar7 = (SeekBar) findViewById(R.id.seekbar_speed);
                                                                                                                TextView textView9 = (TextView) findViewById(R.id.tv_speed_val);
                                                                                                                SharedPreferences sharedPreferences37 = this.f4067t;
                                                                                                                if (sharedPreferences37 != null) {
                                                                                                                    int i17 = sharedPreferences37.getInt("pref_mouse_speed", 50);
                                                                                                                    seekBar7.setProgress(i17);
                                                                                                                    textView9.setText(String.valueOf(i17));
                                                                                                                    seekBar7.setOnSeekBarChangeListener(new r20(textView9, this, i11));
                                                                                                                    SeekBar seekBar8 = (SeekBar) findViewById(R.id.seekbar_dex_speed);
                                                                                                                    TextView textView10 = (TextView) findViewById(R.id.tv_dex_speed_val);
                                                                                                                    SharedPreferences sharedPreferences38 = this.f4067t;
                                                                                                                    if (sharedPreferences38 != null) {
                                                                                                                        int i18 = sharedPreferences38.getInt("pref_dex_speed", 35);
                                                                                                                        seekBar8.setProgress(i18);
                                                                                                                        textView10.setText(String.valueOf(i18));
                                                                                                                        seekBar8.setOnSeekBarChangeListener(new r20(textView10, this, i5));
                                                                                                                        ImageView imageView = (ImageView) findViewById(R.id.iv_guide);
                                                                                                                        if (imageView != null) {
                                                                                                                            imageView.setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                                                                                                /* renamed from: o */
                                                                                                                                public final /* synthetic */ MainActivity f15949o;

                                                                                                                                {
                                                                                                                                    this.f15949o = this;
                                                                                                                                }

                                                                                                                                @Override // android.view.View.OnClickListener
                                                                                                                                public final void onClick(View view) {
                                                                                                                                    int i62 = i3;
                                                                                                                                    int i72 = 2;
                                                                                                                                    int i82 = 1;
                                                                                                                                    final MainActivity mainActivity = this.f15949o;
                                                                                                                                    switch (i62) {
                                                                                                                                        case 0:
                                                                                                                                            int i92 = MainActivity.f4054M;
                                                                                                                                            final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                                                                                            mainActivity.setRequestedOrientation(0);
                                                                                                                                            Dialog dialog = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                                                                                            dialog.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                                                                                            ImageView imageView2 = (ImageView) dialog.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                                                                                            imageView2.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                                                                                            imageView2.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog));
                                                                                                                                            dialog.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                                                                                                @Override // android.content.DialogInterface.OnDismissListener
                                                                                                                                                public final void onDismiss(DialogInterface dialogInterface) {
                                                                                                                                                    int i102 = MainActivity.f4054M;
                                                                                                                                                    MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            dialog.show();
                                                                                                                                            return;
                                                                                                                                        case 1:
                                                                                                                                            int i102 = MainActivity.f4054M;
                                                                                                                                            Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                                                                                            intent.addFlags(268435456);
                                                                                                                                            mainActivity.startActivity(intent);
                                                                                                                                            return;
                                                                                                                                        case 2:
                                                                                                                                            int i112 = MainActivity.f4054M;
                                                                                                                                            Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                                                                                            intent2.addFlags(268435456);
                                                                                                                                            mainActivity.startActivity(intent2);
                                                                                                                                            return;
                                                                                                                                        case 3:
                                                                                                                                            FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                                                                                            if (firebaseAnalytics3 != null) {
                                                                                                                                                firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                                                                                                db0.m2411e(mainActivity);
                                                                                                                                                return;
                                                                                                                                            } else {
                                                                                                                                                xl3.m8890u("firebaseAnalytics");
                                                                                                                                                throw null;
                                                                                                                                            }
                                                                                                                                        case 4:
                                                                                                                                            int i122 = MainActivity.f4054M;
                                                                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                                                                            String string32 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                                                                            c0879u2.f15166d = string32;
                                                                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                            DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                                                                                            m9008a.show();
                                                                                                                                            Button button = m9008a.f19651s.f18186i;
                                                                                                                                            if (button != null) {
                                                                                                                                                button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                                                                                                return;
                                                                                                                                            }
                                                                                                                                            return;
                                                                                                                                        case 5:
                                                                                                                                            int i132 = MainActivity.f4054M;
                                                                                                                                            String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                                                                                            String str5 = "en";
                                                                                                                                            String[] strArr2 = {"en", "ko", "es"};
                                                                                                                                            SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                                                                                            if (sharedPreferences202 != null) {
                                                                                                                                                String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                                                                                                if (string4 != null) {
                                                                                                                                                    str5 = string4;
                                                                                                                                                }
                                                                                                                                                int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                                                                                String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                                                                                c0879u22.f15166d = string5;
                                                                                                                                                i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                                                                                                c0879u22.f15173k = strArr;
                                                                                                                                                c0879u22.f15175m = i20Var;
                                                                                                                                                c0879u22.f15178p = m5906o0;
                                                                                                                                                c0879u22.f15177o = true;
                                                                                                                                                c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                c1027y22.m9011g();
                                                                                                                                                return;
                                                                                                                                            }
                                                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                                                            throw null;
                                                                                                                                        case 6:
                                                                                                                                            int i142 = MainActivity.f4054M;
                                                                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                                                                            ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                                                                                            c1027y23.m9009b(R.string.cancel);
                                                                                                                                            final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                                                                                            float f = mainActivity.getResources().getDisplayMetrics().density;
                                                                                                                                            LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                                                                                            linearLayout.setOrientation(1);
                                                                                                                                            int i152 = (int) (16.0f * f);
                                                                                                                                            int i162 = (int) (8.0f * f);
                                                                                                                                            linearLayout.setPadding(i152, (int) (4.0f * f), i152, i162);
                                                                                                                                            String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                                                                                            for (final int i172 = 0; i172 < 2; i172++) {
                                                                                                                                                String str6 = strArr3[i172];
                                                                                                                                                str6.getClass();
                                                                                                                                                TextView textView22 = new TextView(mainActivity);
                                                                                                                                                textView22.setText(str6);
                                                                                                                                                textView22.setTextSize(16.0f);
                                                                                                                                                int i182 = (int) (14.0f * f);
                                                                                                                                                textView22.setPadding(i162, i182, i162, i182);
                                                                                                                                                textView22.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                                                                    public final void onClick(View view2) {
                                                                                                                                                        String str7;
                                                                                                                                                        int i19 = MainActivity.f4054M;
                                                                                                                                                        DialogC1064z2.this.dismiss();
                                                                                                                                                        int i20 = i172;
                                                                                                                                                        final MainActivity mainActivity2 = mainActivity;
                                                                                                                                                        int i21 = 1;
                                                                                                                                                        if (i20 != 0) {
                                                                                                                                                            if (i20 != 1) {
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                                                                                            return;
                                                                                                                                                        }
                                                                                                                                                        SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                        if (sharedPreferences212 != null) {
                                                                                                                                                            String str8 = "#FFA000";
                                                                                                                                                            String string6 = sharedPreferences212.getString("pref_cursor_color", "#FFA000");
                                                                                                                                                            if (string6 != null) {
                                                                                                                                                                str8 = string6;
                                                                                                                                                            }
                                                                                                                                                            String m2096q = MainActivity.m2096q(str8);
                                                                                                                                                            float f2 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                                                                                            ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                                                                                            c1027y24.m9009b(R.string.cancel);
                                                                                                                                                            final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                            LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                                                                                            linearLayout2.setOrientation(1);
                                                                                                                                                            int i22 = (int) (12.0f * f2);
                                                                                                                                                            int i23 = (int) (4.0f * f2);
                                                                                                                                                            linearLayout2.setPadding(i22, (int) (8.0f * f2), i22, i23);
                                                                                                                                                            ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                                                                                            int size = m4163c0.size();
                                                                                                                                                            int i24 = size / 5;
                                                                                                                                                            int i25 = 0;
                                                                                                                                                            if (size % 5 == 0) {
                                                                                                                                                                i21 = 0;
                                                                                                                                                            }
                                                                                                                                                            ArrayList arrayList = new ArrayList(i24 + i21);
                                                                                                                                                            for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                                                                                                int i27 = size - i26;
                                                                                                                                                                if (5 <= i27) {
                                                                                                                                                                    i27 = 5;
                                                                                                                                                                }
                                                                                                                                                                ArrayList arrayList2 = new ArrayList(i27);
                                                                                                                                                                for (int i28 = 0; i28 < i27; i28++) {
                                                                                                                                                                    arrayList2.add(m4163c0.get(i28 + i26));
                                                                                                                                                                }
                                                                                                                                                                arrayList.add(arrayList2);
                                                                                                                                                            }
                                                                                                                                                            int size2 = arrayList.size();
                                                                                                                                                            int i29 = 0;
                                                                                                                                                            while (i29 < size2) {
                                                                                                                                                                Object obj = arrayList.get(i29);
                                                                                                                                                                i29++;
                                                                                                                                                                LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                                                                                                linearLayout3.setOrientation(i25);
                                                                                                                                                                for (final String str9 : (List) obj) {
                                                                                                                                                                    TextView textView32 = new TextView(mainActivity2);
                                                                                                                                                                    textView32.setGravity(17);
                                                                                                                                                                    textView32.setTextSize(10.0f);
                                                                                                                                                                    int i30 = (int) (10.0f * f2);
                                                                                                                                                                    textView32.setPadding(i23, i30, i23, i30);
                                                                                                                                                                    ArrayList arrayList3 = arrayList;
                                                                                                                                                                    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i25, (int) (46.0f * f2), 1.0f);
                                                                                                                                                                    int i31 = (int) (3.0f * f2);
                                                                                                                                                                    layoutParams.setMargins(i31, i31, i31, i31);
                                                                                                                                                                    textView32.setLayoutParams(layoutParams);
                                                                                                                                                                    int i32 = -16777216;
                                                                                                                                                                    if (str9 != null) {
                                                                                                                                                                        float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor(str9));
                                                                                                                                                                        if (blue < 140.0f) {
                                                                                                                                                                            i32 = -1;
                                                                                                                                                                        }
                                                                                                                                                                        textView32.setTextColor(i32);
                                                                                                                                                                        if (str9.equals(m2096q)) {
                                                                                                                                                                            str7 = "✓ ".concat(str9);
                                                                                                                                                                        } else {
                                                                                                                                                                            str7 = str9;
                                                                                                                                                                        }
                                                                                                                                                                        textView32.setText(str7);
                                                                                                                                                                        textView32.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                                                                                            @Override // android.view.View.OnClickListener
                                                                                                                                                                            public final void onClick(View view3) {
                                                                                                                                                                                MainActivity mainActivity3 = MainActivity.this;
                                                                                                                                                                                SharedPreferences sharedPreferences222 = mainActivity3.f4067t;
                                                                                                                                                                                if (sharedPreferences222 != null) {
                                                                                                                                                                                    sharedPreferences222.edit().putString("pref_cursor_color", str9).apply();
                                                                                                                                                                                    SharedPreferences sharedPreferences232 = mainActivity3.f4067t;
                                                                                                                                                                                    if (sharedPreferences232 != null) {
                                                                                                                                                                                        sharedPreferences232.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                                                                                        mainActivity3.m2104C();
                                                                                                                                                                                        m9008a3.dismiss();
                                                                                                                                                                                        return;
                                                                                                                                                                                    }
                                                                                                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                                                                                                    throw null;
                                                                                                                                                                                }
                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                throw null;
                                                                                                                                                                            }
                                                                                                                                                                        });
                                                                                                                                                                    } else {
                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                                                                                        textView32.setTextColor(-16777216);
                                                                                                                                                                        textView32.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                                                                                        textView32.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                                                                                                    }
                                                                                                                                                                    linearLayout3.addView(textView32);
                                                                                                                                                                    arrayList = arrayList3;
                                                                                                                                                                    i25 = 0;
                                                                                                                                                                }
                                                                                                                                                                linearLayout2.addView(linearLayout3);
                                                                                                                                                                i25 = 0;
                                                                                                                                                            }
                                                                                                                                                            ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                                                                                            scrollView.addView(linearLayout2);
                                                                                                                                                            C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                                                                                            c0990x2.f18184g = scrollView;
                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                            m9008a3.show();
                                                                                                                                                            return;
                                                                                                                                                        }
                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                        throw null;
                                                                                                                                                    }
                                                                                                                                                });
                                                                                                                                                linearLayout.addView(textView22);
                                                                                                                                            }
                                                                                                                                            C0990x2 c0990x2 = m9008a2.f19651s;
                                                                                                                                            c0990x2.f18184g = linearLayout;
                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                            m9008a2.show();
                                                                                                                                            return;
                                                                                                                                        default:
                                                                                                                                            int i19 = MainActivity.f4054M;
                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                                                                                            ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                                                                                            c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                                                                                            c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                                                                                            c20 c20Var = new c20(mainActivity, i72);
                                                                                                                                            c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                                                                                            c0879u23.f15170h = c20Var;
                                                                                                                                            c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                            DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                            m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                                                                                                @Override // android.content.DialogInterface.OnKeyListener
                                                                                                                                                public final boolean onKey(DialogInterface dialogInterface, int i20, KeyEvent keyEvent) {
                                                                                                                                                    int i21 = MainActivity.f4054M;
                                                                                                                                                    if (keyEvent.getAction() == 0) {
                                                                                                                                                        MainActivity mainActivity2 = MainActivity.this;
                                                                                                                                                        if (i20 != 19 && i20 != 20 && i20 != 21 && i20 != 22 && i20 != 23) {
                                                                                                                                                            if (i20 != 4 && i20 != 24 && i20 != 25 && i20 != 26) {
                                                                                                                                                                SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                if (sharedPreferences212 != null) {
                                                                                                                                                                    sharedPreferences212.edit().putInt("pref_toggle_keycode", i20).apply();
                                                                                                                                                                    mainActivity2.m2106E();
                                                                                                                                                                    dialogInterface.dismiss();
                                                                                                                                                                    return true;
                                                                                                                                                                }
                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                throw null;
                                                                                                                                                            }
                                                                                                                                                        } else {
                                                                                                                                                            Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                                                                                            return true;
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                    return false;
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            m9008a3.show();
                                                                                                                                            return;
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            });
                                                                                                                        }
                                                                                                                        if (!m2109p()) {
                                                                                                                            Dialog dialog = new Dialog(this);
                                                                                                                            dialog.requestWindowFeature(1);
                                                                                                                            dialog.setContentView(R.layout.dialog_initial_setup);
                                                                                                                            Window window = dialog.getWindow();
                                                                                                                            if (window != null) {
                                                                                                                                window.setBackgroundDrawable(new ColorDrawable(0));
                                                                                                                            }
                                                                                                                            dialog.setCancelable(false);
                                                                                                                            ((Button) dialog.findViewById(R.id.btn_dialog_accept)).setOnClickListener(new e20(this, dialog));
                                                                                                                            ((Button) dialog.findViewById(R.id.btn_dialog_decline)).setOnClickListener(new e20(dialog, this));
                                                                                                                            dialog.show();
                                                                                                                            int i19 = (int) (getResources().getDisplayMetrics().widthPixels * 0.9d);
                                                                                                                            Window window2 = dialog.getWindow();
                                                                                                                            if (window2 != null) {
                                                                                                                                window2.setLayout(i19, -2);
                                                                                                                            }
                                                                                                                        }
                                                                                                                        SeekBar seekBar9 = (SeekBar) findViewById(R.id.seekbar_size);
                                                                                                                        TextView textView11 = (TextView) findViewById(R.id.tv_size_val);
                                                                                                                        SharedPreferences sharedPreferences39 = this.f4067t;
                                                                                                                        if (sharedPreferences39 != null) {
                                                                                                                            int i20 = sharedPreferences39.getInt("pref_mouse_size", 100);
                                                                                                                            seekBar9.setProgress(i20);
                                                                                                                            textView11.setText(String.valueOf(i20));
                                                                                                                            seekBar9.setOnSeekBarChangeListener(new r20(textView11, this, i6));
                                                                                                                            SeekBar seekBar10 = (SeekBar) findViewById(R.id.seekbar_sensitivity);
                                                                                                                            TextView textView12 = (TextView) findViewById(R.id.tv_sensitivity_val);
                                                                                                                            SharedPreferences sharedPreferences40 = this.f4067t;
                                                                                                                            if (sharedPreferences40 != null) {
                                                                                                                                int i21 = sharedPreferences40.getInt("pref_mouse_sensitivity", 20);
                                                                                                                                seekBar10.setProgress(i21 - 10);
                                                                                                                                textView12.setText(String.format("%.1f", Arrays.copyOf(new Object[]{Float.valueOf(i21 / 10.0f)}, 1)));
                                                                                                                                seekBar10.setOnSeekBarChangeListener(new r20(textView12, this, 7));
                                                                                                                                SeekBar seekBar11 = (SeekBar) findViewById(R.id.seekbar_timeout);
                                                                                                                                TextView textView13 = (TextView) findViewById(R.id.tv_timeout_val);
                                                                                                                                SharedPreferences sharedPreferences41 = this.f4067t;
                                                                                                                                if (sharedPreferences41 != null) {
                                                                                                                                    int i22 = sharedPreferences41.getInt("pref_mouse_timeout", 0);
                                                                                                                                    if (i22 == 0) {
                                                                                                                                        i2 = 0;
                                                                                                                                    } else if (i22 < 5) {
                                                                                                                                        i2 = 1;
                                                                                                                                    } else {
                                                                                                                                        i2 = i22 - 4;
                                                                                                                                    }
                                                                                                                                    seekBar11.setProgress(i2);
                                                                                                                                    if (i22 == 0) {
                                                                                                                                        str2 = getString(R.string.never);
                                                                                                                                    } else {
                                                                                                                                        str2 = i22 + "s";
                                                                                                                                    }
                                                                                                                                    textView13.setText(str2);
                                                                                                                                    seekBar11.setOnSeekBarChangeListener(new r20(textView13, this, 8));
                                                                                                                                    SeekBar seekBar12 = (SeekBar) findViewById(R.id.seekbar_scroll_speed);
                                                                                                                                    TextView textView14 = (TextView) findViewById(R.id.tv_scroll_speed_val);
                                                                                                                                    SharedPreferences sharedPreferences42 = this.f4067t;
                                                                                                                                    if (sharedPreferences42 != null) {
                                                                                                                                        int i23 = sharedPreferences42.getInt("pref_scroll_speed", 100);
                                                                                                                                        seekBar12.setProgress(i23);
                                                                                                                                        textView14.setText(String.valueOf(i23));
                                                                                                                                        seekBar12.setOnSeekBarChangeListener(new r20(textView14, this, 9));
                                                                                                                                        SeekBar seekBar13 = (SeekBar) findViewById(R.id.seekbar_deadzone);
                                                                                                                                        TextView textView15 = (TextView) findViewById(R.id.tv_deadzone_val);
                                                                                                                                        SharedPreferences sharedPreferences43 = this.f4067t;
                                                                                                                                        if (sharedPreferences43 != null) {
                                                                                                                                            int i24 = sharedPreferences43.getInt("pref_deadzone", 15);
                                                                                                                                            if (i24 < 1) {
                                                                                                                                                i24 = 1;
                                                                                                                                            }
                                                                                                                                            float f = i24 / 100.0f;
                                                                                                                                            this.f4069v = f;
                                                                                                                                            seekBar13.setProgress(i24);
                                                                                                                                            textView15.setText(String.format("%.2f", Arrays.copyOf(new Object[]{Float.valueOf(f)}, 1)));
                                                                                                                                            seekBar13.setOnSeekBarChangeListener(new r20(this, textView15));
                                                                                                                                            ((Button) findViewById(R.id.btn_open_settings)).setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                                                                                                                /* renamed from: o */
                                                                                                                                                public final /* synthetic */ MainActivity f15949o;

                                                                                                                                                {
                                                                                                                                                    this.f15949o = this;
                                                                                                                                                }

                                                                                                                                                @Override // android.view.View.OnClickListener
                                                                                                                                                public final void onClick(View view) {
                                                                                                                                                    int i62 = i4;
                                                                                                                                                    int i72 = 2;
                                                                                                                                                    int i82 = 1;
                                                                                                                                                    final MainActivity mainActivity = this.f15949o;
                                                                                                                                                    switch (i62) {
                                                                                                                                                        case 0:
                                                                                                                                                            int i92 = MainActivity.f4054M;
                                                                                                                                                            final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                                                                                                            mainActivity.setRequestedOrientation(0);
                                                                                                                                                            Dialog dialog2 = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                                                                                                            dialog2.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                                                                                                            ImageView imageView2 = (ImageView) dialog2.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                                                                                                            imageView2.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                                                                                                            imageView2.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog2));
                                                                                                                                                            dialog2.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                                                                                                                @Override // android.content.DialogInterface.OnDismissListener
                                                                                                                                                                public final void onDismiss(DialogInterface dialogInterface) {
                                                                                                                                                                    int i102 = MainActivity.f4054M;
                                                                                                                                                                    MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            dialog2.show();
                                                                                                                                                            return;
                                                                                                                                                        case 1:
                                                                                                                                                            int i102 = MainActivity.f4054M;
                                                                                                                                                            Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                                                                                                            intent.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent);
                                                                                                                                                            return;
                                                                                                                                                        case 2:
                                                                                                                                                            int i112 = MainActivity.f4054M;
                                                                                                                                                            Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                                                                                                            intent2.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent2);
                                                                                                                                                            return;
                                                                                                                                                        case 3:
                                                                                                                                                            FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                                                                                                            if (firebaseAnalytics3 != null) {
                                                                                                                                                                firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                                                                                                                db0.m2411e(mainActivity);
                                                                                                                                                                return;
                                                                                                                                                            } else {
                                                                                                                                                                xl3.m8890u("firebaseAnalytics");
                                                                                                                                                                throw null;
                                                                                                                                                            }
                                                                                                                                                        case 4:
                                                                                                                                                            int i122 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                                                                                            String string32 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                                                                                            c0879u2.f15166d = string32;
                                                                                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                                                                                                            m9008a.show();
                                                                                                                                                            Button button = m9008a.f19651s.f18186i;
                                                                                                                                                            if (button != null) {
                                                                                                                                                                button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            return;
                                                                                                                                                        case 5:
                                                                                                                                                            int i132 = MainActivity.f4054M;
                                                                                                                                                            String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                                                                                                            String str5 = "en";
                                                                                                                                                            String[] strArr2 = {"en", "ko", "es"};
                                                                                                                                                            SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                                                                                                            if (sharedPreferences202 != null) {
                                                                                                                                                                String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                                                                                                                if (string4 != null) {
                                                                                                                                                                    str5 = string4;
                                                                                                                                                                }
                                                                                                                                                                int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                                                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                                                                                                String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                                                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                                                                                                c0879u22.f15166d = string5;
                                                                                                                                                                i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                                                                                                                c0879u22.f15173k = strArr;
                                                                                                                                                                c0879u22.f15175m = i20Var;
                                                                                                                                                                c0879u22.f15178p = m5906o0;
                                                                                                                                                                c0879u22.f15177o = true;
                                                                                                                                                                c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                                c1027y22.m9011g();
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                                                                            throw null;
                                                                                                                                                        case 6:
                                                                                                                                                            int i142 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                                                                                            ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                                                                                                            c1027y23.m9009b(R.string.cancel);
                                                                                                                                                            final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                                                                                                            float f2 = mainActivity.getResources().getDisplayMetrics().density;
                                                                                                                                                            LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                                                                                                            linearLayout.setOrientation(1);
                                                                                                                                                            int i152 = (int) (16.0f * f2);
                                                                                                                                                            int i162 = (int) (8.0f * f2);
                                                                                                                                                            linearLayout.setPadding(i152, (int) (4.0f * f2), i152, i162);
                                                                                                                                                            String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                                                                                                            for (final int i172 = 0; i172 < 2; i172++) {
                                                                                                                                                                String str6 = strArr3[i172];
                                                                                                                                                                str6.getClass();
                                                                                                                                                                TextView textView22 = new TextView(mainActivity);
                                                                                                                                                                textView22.setText(str6);
                                                                                                                                                                textView22.setTextSize(16.0f);
                                                                                                                                                                int i182 = (int) (14.0f * f2);
                                                                                                                                                                textView22.setPadding(i162, i182, i162, i182);
                                                                                                                                                                textView22.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                                                                                    public final void onClick(View view2) {
                                                                                                                                                                        String str7;
                                                                                                                                                                        int i192 = MainActivity.f4054M;
                                                                                                                                                                        DialogC1064z2.this.dismiss();
                                                                                                                                                                        int i202 = i172;
                                                                                                                                                                        final MainActivity mainActivity2 = mainActivity;
                                                                                                                                                                        int i212 = 1;
                                                                                                                                                                        if (i202 != 0) {
                                                                                                                                                                            if (i202 != 1) {
                                                                                                                                                                                return;
                                                                                                                                                                            }
                                                                                                                                                                            mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                        if (sharedPreferences212 != null) {
                                                                                                                                                                            String str8 = "#FFA000";
                                                                                                                                                                            String string6 = sharedPreferences212.getString("pref_cursor_color", "#FFA000");
                                                                                                                                                                            if (string6 != null) {
                                                                                                                                                                                str8 = string6;
                                                                                                                                                                            }
                                                                                                                                                                            String m2096q = MainActivity.m2096q(str8);
                                                                                                                                                                            float f22 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                                                                                                            ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                                                                                                            c1027y24.m9009b(R.string.cancel);
                                                                                                                                                                            final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                                            LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                                                                                                            linearLayout2.setOrientation(1);
                                                                                                                                                                            int i222 = (int) (12.0f * f22);
                                                                                                                                                                            int i232 = (int) (4.0f * f22);
                                                                                                                                                                            linearLayout2.setPadding(i222, (int) (8.0f * f22), i222, i232);
                                                                                                                                                                            ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                                                                                                            int size = m4163c0.size();
                                                                                                                                                                            int i242 = size / 5;
                                                                                                                                                                            int i25 = 0;
                                                                                                                                                                            if (size % 5 == 0) {
                                                                                                                                                                                i212 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ArrayList arrayList = new ArrayList(i242 + i212);
                                                                                                                                                                            for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                                                                                                                int i27 = size - i26;
                                                                                                                                                                                if (5 <= i27) {
                                                                                                                                                                                    i27 = 5;
                                                                                                                                                                                }
                                                                                                                                                                                ArrayList arrayList2 = new ArrayList(i27);
                                                                                                                                                                                for (int i28 = 0; i28 < i27; i28++) {
                                                                                                                                                                                    arrayList2.add(m4163c0.get(i28 + i26));
                                                                                                                                                                                }
                                                                                                                                                                                arrayList.add(arrayList2);
                                                                                                                                                                            }
                                                                                                                                                                            int size2 = arrayList.size();
                                                                                                                                                                            int i29 = 0;
                                                                                                                                                                            while (i29 < size2) {
                                                                                                                                                                                Object obj = arrayList.get(i29);
                                                                                                                                                                                i29++;
                                                                                                                                                                                LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                                                                                                                linearLayout3.setOrientation(i25);
                                                                                                                                                                                for (final String str9 : (List) obj) {
                                                                                                                                                                                    TextView textView32 = new TextView(mainActivity2);
                                                                                                                                                                                    textView32.setGravity(17);
                                                                                                                                                                                    textView32.setTextSize(10.0f);
                                                                                                                                                                                    int i30 = (int) (10.0f * f22);
                                                                                                                                                                                    textView32.setPadding(i232, i30, i232, i30);
                                                                                                                                                                                    ArrayList arrayList3 = arrayList;
                                                                                                                                                                                    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i25, (int) (46.0f * f22), 1.0f);
                                                                                                                                                                                    int i31 = (int) (3.0f * f22);
                                                                                                                                                                                    layoutParams.setMargins(i31, i31, i31, i31);
                                                                                                                                                                                    textView32.setLayoutParams(layoutParams);
                                                                                                                                                                                    int i32 = -16777216;
                                                                                                                                                                                    if (str9 != null) {
                                                                                                                                                                                        float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor(str9));
                                                                                                                                                                                        if (blue < 140.0f) {
                                                                                                                                                                                            i32 = -1;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setTextColor(i32);
                                                                                                                                                                                        if (str9.equals(m2096q)) {
                                                                                                                                                                                            str7 = "✓ ".concat(str9);
                                                                                                                                                                                        } else {
                                                                                                                                                                                            str7 = str9;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setText(str7);
                                                                                                                                                                                        textView32.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                                                                                                            @Override // android.view.View.OnClickListener
                                                                                                                                                                                            public final void onClick(View view3) {
                                                                                                                                                                                                MainActivity mainActivity3 = MainActivity.this;
                                                                                                                                                                                                SharedPreferences sharedPreferences222 = mainActivity3.f4067t;
                                                                                                                                                                                                if (sharedPreferences222 != null) {
                                                                                                                                                                                                    sharedPreferences222.edit().putString("pref_cursor_color", str9).apply();
                                                                                                                                                                                                    SharedPreferences sharedPreferences232 = mainActivity3.f4067t;
                                                                                                                                                                                                    if (sharedPreferences232 != null) {
                                                                                                                                                                                                        sharedPreferences232.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                                                                                                        mainActivity3.m2104C();
                                                                                                                                                                                                        m9008a3.dismiss();
                                                                                                                                                                                                        return;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                    throw null;
                                                                                                                                                                                                }
                                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                throw null;
                                                                                                                                                                                            }
                                                                                                                                                                                        });
                                                                                                                                                                                    } else {
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                                                                                                        textView32.setTextColor(-16777216);
                                                                                                                                                                                        textView32.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                                                                                                        textView32.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                                                                                                                    }
                                                                                                                                                                                    linearLayout3.addView(textView32);
                                                                                                                                                                                    arrayList = arrayList3;
                                                                                                                                                                                    i25 = 0;
                                                                                                                                                                                }
                                                                                                                                                                                linearLayout2.addView(linearLayout3);
                                                                                                                                                                                i25 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                                                                                                            scrollView.addView(linearLayout2);
                                                                                                                                                                            C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                                                                                                            c0990x2.f18184g = scrollView;
                                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                                            m9008a3.show();
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                                        throw null;
                                                                                                                                                                    }
                                                                                                                                                                });
                                                                                                                                                                linearLayout.addView(textView22);
                                                                                                                                                            }
                                                                                                                                                            C0990x2 c0990x2 = m9008a2.f19651s;
                                                                                                                                                            c0990x2.f18184g = linearLayout;
                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                            m9008a2.show();
                                                                                                                                                            return;
                                                                                                                                                        default:
                                                                                                                                                            int i192 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                                                                                                            ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                                                                                                            c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                                                                                                            c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                                                                                                            c20 c20Var = new c20(mainActivity, i72);
                                                                                                                                                            c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                                                                                                            c0879u23.f15170h = c20Var;
                                                                                                                                                            c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                            m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                                                                                                                @Override // android.content.DialogInterface.OnKeyListener
                                                                                                                                                                public final boolean onKey(DialogInterface dialogInterface, int i202, KeyEvent keyEvent) {
                                                                                                                                                                    int i212 = MainActivity.f4054M;
                                                                                                                                                                    if (keyEvent.getAction() == 0) {
                                                                                                                                                                        MainActivity mainActivity2 = MainActivity.this;
                                                                                                                                                                        if (i202 != 19 && i202 != 20 && i202 != 21 && i202 != 22 && i202 != 23) {
                                                                                                                                                                            if (i202 != 4 && i202 != 24 && i202 != 25 && i202 != 26) {
                                                                                                                                                                                SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                                if (sharedPreferences212 != null) {
                                                                                                                                                                                    sharedPreferences212.edit().putInt("pref_toggle_keycode", i202).apply();
                                                                                                                                                                                    mainActivity2.m2106E();
                                                                                                                                                                                    dialogInterface.dismiss();
                                                                                                                                                                                    return true;
                                                                                                                                                                                }
                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                throw null;
                                                                                                                                                                            }
                                                                                                                                                                        } else {
                                                                                                                                                                            Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                                                                                                            return true;
                                                                                                                                                                        }
                                                                                                                                                                    }
                                                                                                                                                                    return false;
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            m9008a3.show();
                                                                                                                                                            return;
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            final int i25 = 2;
                                                                                                                                            ((Button) findViewById(R.id.btn_battery_optimization)).setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                                                                                                                /* renamed from: o */
                                                                                                                                                public final /* synthetic */ MainActivity f15949o;

                                                                                                                                                {
                                                                                                                                                    this.f15949o = this;
                                                                                                                                                }

                                                                                                                                                @Override // android.view.View.OnClickListener
                                                                                                                                                public final void onClick(View view) {
                                                                                                                                                    int i62 = i25;
                                                                                                                                                    int i72 = 2;
                                                                                                                                                    int i82 = 1;
                                                                                                                                                    final MainActivity mainActivity = this.f15949o;
                                                                                                                                                    switch (i62) {
                                                                                                                                                        case 0:
                                                                                                                                                            int i92 = MainActivity.f4054M;
                                                                                                                                                            final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                                                                                                            mainActivity.setRequestedOrientation(0);
                                                                                                                                                            Dialog dialog2 = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                                                                                                            dialog2.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                                                                                                            ImageView imageView2 = (ImageView) dialog2.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                                                                                                            imageView2.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                                                                                                            imageView2.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog2));
                                                                                                                                                            dialog2.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                                                                                                                @Override // android.content.DialogInterface.OnDismissListener
                                                                                                                                                                public final void onDismiss(DialogInterface dialogInterface) {
                                                                                                                                                                    int i102 = MainActivity.f4054M;
                                                                                                                                                                    MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            dialog2.show();
                                                                                                                                                            return;
                                                                                                                                                        case 1:
                                                                                                                                                            int i102 = MainActivity.f4054M;
                                                                                                                                                            Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                                                                                                            intent.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent);
                                                                                                                                                            return;
                                                                                                                                                        case 2:
                                                                                                                                                            int i112 = MainActivity.f4054M;
                                                                                                                                                            Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                                                                                                            intent2.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent2);
                                                                                                                                                            return;
                                                                                                                                                        case 3:
                                                                                                                                                            FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                                                                                                            if (firebaseAnalytics3 != null) {
                                                                                                                                                                firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                                                                                                                db0.m2411e(mainActivity);
                                                                                                                                                                return;
                                                                                                                                                            } else {
                                                                                                                                                                xl3.m8890u("firebaseAnalytics");
                                                                                                                                                                throw null;
                                                                                                                                                            }
                                                                                                                                                        case 4:
                                                                                                                                                            int i122 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                                                                                            String string32 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                                                                                            c0879u2.f15166d = string32;
                                                                                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                                                                                                            m9008a.show();
                                                                                                                                                            Button button = m9008a.f19651s.f18186i;
                                                                                                                                                            if (button != null) {
                                                                                                                                                                button.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            return;
                                                                                                                                                        case 5:
                                                                                                                                                            int i132 = MainActivity.f4054M;
                                                                                                                                                            String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                                                                                                            String str5 = "en";
                                                                                                                                                            String[] strArr2 = {"en", "ko", "es"};
                                                                                                                                                            SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                                                                                                            if (sharedPreferences202 != null) {
                                                                                                                                                                String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                                                                                                                if (string4 != null) {
                                                                                                                                                                    str5 = string4;
                                                                                                                                                                }
                                                                                                                                                                int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                                                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                                                                                                String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                                                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                                                                                                c0879u22.f15166d = string5;
                                                                                                                                                                i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                                                                                                                c0879u22.f15173k = strArr;
                                                                                                                                                                c0879u22.f15175m = i20Var;
                                                                                                                                                                c0879u22.f15178p = m5906o0;
                                                                                                                                                                c0879u22.f15177o = true;
                                                                                                                                                                c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                                c1027y22.m9011g();
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                                                                            throw null;
                                                                                                                                                        case 6:
                                                                                                                                                            int i142 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                                                                                            ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                                                                                                            c1027y23.m9009b(R.string.cancel);
                                                                                                                                                            final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                                                                                                            float f2 = mainActivity.getResources().getDisplayMetrics().density;
                                                                                                                                                            LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                                                                                                            linearLayout.setOrientation(1);
                                                                                                                                                            int i152 = (int) (16.0f * f2);
                                                                                                                                                            int i162 = (int) (8.0f * f2);
                                                                                                                                                            linearLayout.setPadding(i152, (int) (4.0f * f2), i152, i162);
                                                                                                                                                            String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                                                                                                            for (final int i172 = 0; i172 < 2; i172++) {
                                                                                                                                                                String str6 = strArr3[i172];
                                                                                                                                                                str6.getClass();
                                                                                                                                                                TextView textView22 = new TextView(mainActivity);
                                                                                                                                                                textView22.setText(str6);
                                                                                                                                                                textView22.setTextSize(16.0f);
                                                                                                                                                                int i182 = (int) (14.0f * f2);
                                                                                                                                                                textView22.setPadding(i162, i182, i162, i182);
                                                                                                                                                                textView22.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                                                                                    public final void onClick(View view2) {
                                                                                                                                                                        String str7;
                                                                                                                                                                        int i192 = MainActivity.f4054M;
                                                                                                                                                                        DialogC1064z2.this.dismiss();
                                                                                                                                                                        int i202 = i172;
                                                                                                                                                                        final MainActivity mainActivity2 = mainActivity;
                                                                                                                                                                        int i212 = 1;
                                                                                                                                                                        if (i202 != 0) {
                                                                                                                                                                            if (i202 != 1) {
                                                                                                                                                                                return;
                                                                                                                                                                            }
                                                                                                                                                                            mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                        if (sharedPreferences212 != null) {
                                                                                                                                                                            String str8 = "#FFA000";
                                                                                                                                                                            String string6 = sharedPreferences212.getString("pref_cursor_color", "#FFA000");
                                                                                                                                                                            if (string6 != null) {
                                                                                                                                                                                str8 = string6;
                                                                                                                                                                            }
                                                                                                                                                                            String m2096q = MainActivity.m2096q(str8);
                                                                                                                                                                            float f22 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                                                                                                            ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                                                                                                            c1027y24.m9009b(R.string.cancel);
                                                                                                                                                                            final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                                            LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                                                                                                            linearLayout2.setOrientation(1);
                                                                                                                                                                            int i222 = (int) (12.0f * f22);
                                                                                                                                                                            int i232 = (int) (4.0f * f22);
                                                                                                                                                                            linearLayout2.setPadding(i222, (int) (8.0f * f22), i222, i232);
                                                                                                                                                                            ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                                                                                                            int size = m4163c0.size();
                                                                                                                                                                            int i242 = size / 5;
                                                                                                                                                                            int i252 = 0;
                                                                                                                                                                            if (size % 5 == 0) {
                                                                                                                                                                                i212 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ArrayList arrayList = new ArrayList(i242 + i212);
                                                                                                                                                                            for (int i26 = 0; i26 >= 0 && i26 < size; i26 += 5) {
                                                                                                                                                                                int i27 = size - i26;
                                                                                                                                                                                if (5 <= i27) {
                                                                                                                                                                                    i27 = 5;
                                                                                                                                                                                }
                                                                                                                                                                                ArrayList arrayList2 = new ArrayList(i27);
                                                                                                                                                                                for (int i28 = 0; i28 < i27; i28++) {
                                                                                                                                                                                    arrayList2.add(m4163c0.get(i28 + i26));
                                                                                                                                                                                }
                                                                                                                                                                                arrayList.add(arrayList2);
                                                                                                                                                                            }
                                                                                                                                                                            int size2 = arrayList.size();
                                                                                                                                                                            int i29 = 0;
                                                                                                                                                                            while (i29 < size2) {
                                                                                                                                                                                Object obj = arrayList.get(i29);
                                                                                                                                                                                i29++;
                                                                                                                                                                                LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                                                                                                                linearLayout3.setOrientation(i252);
                                                                                                                                                                                for (final String str9 : (List) obj) {
                                                                                                                                                                                    TextView textView32 = new TextView(mainActivity2);
                                                                                                                                                                                    textView32.setGravity(17);
                                                                                                                                                                                    textView32.setTextSize(10.0f);
                                                                                                                                                                                    int i30 = (int) (10.0f * f22);
                                                                                                                                                                                    textView32.setPadding(i232, i30, i232, i30);
                                                                                                                                                                                    ArrayList arrayList3 = arrayList;
                                                                                                                                                                                    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i252, (int) (46.0f * f22), 1.0f);
                                                                                                                                                                                    int i31 = (int) (3.0f * f22);
                                                                                                                                                                                    layoutParams.setMargins(i31, i31, i31, i31);
                                                                                                                                                                                    textView32.setLayoutParams(layoutParams);
                                                                                                                                                                                    int i32 = -16777216;
                                                                                                                                                                                    if (str9 != null) {
                                                                                                                                                                                        float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor(str9));
                                                                                                                                                                                        if (blue < 140.0f) {
                                                                                                                                                                                            i32 = -1;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setTextColor(i32);
                                                                                                                                                                                        if (str9.equals(m2096q)) {
                                                                                                                                                                                            str7 = "✓ ".concat(str9);
                                                                                                                                                                                        } else {
                                                                                                                                                                                            str7 = str9;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setText(str7);
                                                                                                                                                                                        textView32.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                                                                                                            @Override // android.view.View.OnClickListener
                                                                                                                                                                                            public final void onClick(View view3) {
                                                                                                                                                                                                MainActivity mainActivity3 = MainActivity.this;
                                                                                                                                                                                                SharedPreferences sharedPreferences222 = mainActivity3.f4067t;
                                                                                                                                                                                                if (sharedPreferences222 != null) {
                                                                                                                                                                                                    sharedPreferences222.edit().putString("pref_cursor_color", str9).apply();
                                                                                                                                                                                                    SharedPreferences sharedPreferences232 = mainActivity3.f4067t;
                                                                                                                                                                                                    if (sharedPreferences232 != null) {
                                                                                                                                                                                                        sharedPreferences232.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                                                                                                        mainActivity3.m2104C();
                                                                                                                                                                                                        m9008a3.dismiss();
                                                                                                                                                                                                        return;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                    throw null;
                                                                                                                                                                                                }
                                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                throw null;
                                                                                                                                                                                            }
                                                                                                                                                                                        });
                                                                                                                                                                                    } else {
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                                                                                                        textView32.setTextColor(-16777216);
                                                                                                                                                                                        textView32.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                                                                                                        textView32.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                                                                                                                    }
                                                                                                                                                                                    linearLayout3.addView(textView32);
                                                                                                                                                                                    arrayList = arrayList3;
                                                                                                                                                                                    i252 = 0;
                                                                                                                                                                                }
                                                                                                                                                                                linearLayout2.addView(linearLayout3);
                                                                                                                                                                                i252 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                                                                                                            scrollView.addView(linearLayout2);
                                                                                                                                                                            C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                                                                                                            c0990x2.f18184g = scrollView;
                                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                                            m9008a3.show();
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                                        throw null;
                                                                                                                                                                    }
                                                                                                                                                                });
                                                                                                                                                                linearLayout.addView(textView22);
                                                                                                                                                            }
                                                                                                                                                            C0990x2 c0990x2 = m9008a2.f19651s;
                                                                                                                                                            c0990x2.f18184g = linearLayout;
                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                            m9008a2.show();
                                                                                                                                                            return;
                                                                                                                                                        default:
                                                                                                                                                            int i192 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                                                                                                            ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                                                                                                            c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                                                                                                            c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                                                                                                            c20 c20Var = new c20(mainActivity, i72);
                                                                                                                                                            c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                                                                                                            c0879u23.f15170h = c20Var;
                                                                                                                                                            c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                            m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                                                                                                                @Override // android.content.DialogInterface.OnKeyListener
                                                                                                                                                                public final boolean onKey(DialogInterface dialogInterface, int i202, KeyEvent keyEvent) {
                                                                                                                                                                    int i212 = MainActivity.f4054M;
                                                                                                                                                                    if (keyEvent.getAction() == 0) {
                                                                                                                                                                        MainActivity mainActivity2 = MainActivity.this;
                                                                                                                                                                        if (i202 != 19 && i202 != 20 && i202 != 21 && i202 != 22 && i202 != 23) {
                                                                                                                                                                            if (i202 != 4 && i202 != 24 && i202 != 25 && i202 != 26) {
                                                                                                                                                                                SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                                if (sharedPreferences212 != null) {
                                                                                                                                                                                    sharedPreferences212.edit().putInt("pref_toggle_keycode", i202).apply();
                                                                                                                                                                                    mainActivity2.m2106E();
                                                                                                                                                                                    dialogInterface.dismiss();
                                                                                                                                                                                    return true;
                                                                                                                                                                                }
                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                throw null;
                                                                                                                                                                            }
                                                                                                                                                                        } else {
                                                                                                                                                                            Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                                                                                                            return true;
                                                                                                                                                                        }
                                                                                                                                                                    }
                                                                                                                                                                    return false;
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            m9008a3.show();
                                                                                                                                                            return;
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            Button button = (Button) findViewById(R.id.btn_buy_pro);
                                                                                                                                            TextView textView16 = (TextView) findViewById(R.id.tv_pro_status);
                                                                                                                                            TextView textView17 = (TextView) findViewById(R.id.tv_pro_desc);
                                                                                                                                            this.f4072y = new w10(textView16, this, button, textView17);
                                                                                                                                            m2100u(textView16, this, button, textView17);
                                                                                                                                            final int i26 = 3;
                                                                                                                                            button.setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                                                                                                                /* renamed from: o */
                                                                                                                                                public final /* synthetic */ MainActivity f15949o;

                                                                                                                                                {
                                                                                                                                                    this.f15949o = this;
                                                                                                                                                }

                                                                                                                                                @Override // android.view.View.OnClickListener
                                                                                                                                                public final void onClick(View view) {
                                                                                                                                                    int i62 = i26;
                                                                                                                                                    int i72 = 2;
                                                                                                                                                    int i82 = 1;
                                                                                                                                                    final MainActivity mainActivity = this.f15949o;
                                                                                                                                                    switch (i62) {
                                                                                                                                                        case 0:
                                                                                                                                                            int i92 = MainActivity.f4054M;
                                                                                                                                                            final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                                                                                                            mainActivity.setRequestedOrientation(0);
                                                                                                                                                            Dialog dialog2 = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                                                                                                            dialog2.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                                                                                                            ImageView imageView2 = (ImageView) dialog2.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                                                                                                            imageView2.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                                                                                                            imageView2.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog2));
                                                                                                                                                            dialog2.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                                                                                                                @Override // android.content.DialogInterface.OnDismissListener
                                                                                                                                                                public final void onDismiss(DialogInterface dialogInterface) {
                                                                                                                                                                    int i102 = MainActivity.f4054M;
                                                                                                                                                                    MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            dialog2.show();
                                                                                                                                                            return;
                                                                                                                                                        case 1:
                                                                                                                                                            int i102 = MainActivity.f4054M;
                                                                                                                                                            Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                                                                                                            intent.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent);
                                                                                                                                                            return;
                                                                                                                                                        case 2:
                                                                                                                                                            int i112 = MainActivity.f4054M;
                                                                                                                                                            Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                                                                                                            intent2.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent2);
                                                                                                                                                            return;
                                                                                                                                                        case 3:
                                                                                                                                                            FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                                                                                                            if (firebaseAnalytics3 != null) {
                                                                                                                                                                firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                                                                                                                db0.m2411e(mainActivity);
                                                                                                                                                                return;
                                                                                                                                                            } else {
                                                                                                                                                                xl3.m8890u("firebaseAnalytics");
                                                                                                                                                                throw null;
                                                                                                                                                            }
                                                                                                                                                        case 4:
                                                                                                                                                            int i122 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                                                                                            String string32 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                                                                                            c0879u2.f15166d = string32;
                                                                                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                                                                                                            m9008a.show();
                                                                                                                                                            Button button2 = m9008a.f19651s.f18186i;
                                                                                                                                                            if (button2 != null) {
                                                                                                                                                                button2.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            return;
                                                                                                                                                        case 5:
                                                                                                                                                            int i132 = MainActivity.f4054M;
                                                                                                                                                            String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                                                                                                            String str5 = "en";
                                                                                                                                                            String[] strArr2 = {"en", "ko", "es"};
                                                                                                                                                            SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                                                                                                            if (sharedPreferences202 != null) {
                                                                                                                                                                String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                                                                                                                if (string4 != null) {
                                                                                                                                                                    str5 = string4;
                                                                                                                                                                }
                                                                                                                                                                int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str5);
                                                                                                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                                                                                                String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                                                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                                                                                                c0879u22.f15166d = string5;
                                                                                                                                                                i20 i20Var = new i20(strArr2, str5, mainActivity);
                                                                                                                                                                c0879u22.f15173k = strArr;
                                                                                                                                                                c0879u22.f15175m = i20Var;
                                                                                                                                                                c0879u22.f15178p = m5906o0;
                                                                                                                                                                c0879u22.f15177o = true;
                                                                                                                                                                c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                                c1027y22.m9011g();
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                                                                            throw null;
                                                                                                                                                        case 6:
                                                                                                                                                            int i142 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                                                                                            ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                                                                                                            c1027y23.m9009b(R.string.cancel);
                                                                                                                                                            final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                                                                                                            float f2 = mainActivity.getResources().getDisplayMetrics().density;
                                                                                                                                                            LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                                                                                                            linearLayout.setOrientation(1);
                                                                                                                                                            int i152 = (int) (16.0f * f2);
                                                                                                                                                            int i162 = (int) (8.0f * f2);
                                                                                                                                                            linearLayout.setPadding(i152, (int) (4.0f * f2), i152, i162);
                                                                                                                                                            String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                                                                                                            for (final int i172 = 0; i172 < 2; i172++) {
                                                                                                                                                                String str6 = strArr3[i172];
                                                                                                                                                                str6.getClass();
                                                                                                                                                                TextView textView22 = new TextView(mainActivity);
                                                                                                                                                                textView22.setText(str6);
                                                                                                                                                                textView22.setTextSize(16.0f);
                                                                                                                                                                int i182 = (int) (14.0f * f2);
                                                                                                                                                                textView22.setPadding(i162, i182, i162, i182);
                                                                                                                                                                textView22.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                                                                                    public final void onClick(View view2) {
                                                                                                                                                                        String str7;
                                                                                                                                                                        int i192 = MainActivity.f4054M;
                                                                                                                                                                        DialogC1064z2.this.dismiss();
                                                                                                                                                                        int i202 = i172;
                                                                                                                                                                        final MainActivity mainActivity2 = mainActivity;
                                                                                                                                                                        int i212 = 1;
                                                                                                                                                                        if (i202 != 0) {
                                                                                                                                                                            if (i202 != 1) {
                                                                                                                                                                                return;
                                                                                                                                                                            }
                                                                                                                                                                            mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                        if (sharedPreferences212 != null) {
                                                                                                                                                                            String str8 = "#FFA000";
                                                                                                                                                                            String string6 = sharedPreferences212.getString("pref_cursor_color", "#FFA000");
                                                                                                                                                                            if (string6 != null) {
                                                                                                                                                                                str8 = string6;
                                                                                                                                                                            }
                                                                                                                                                                            String m2096q = MainActivity.m2096q(str8);
                                                                                                                                                                            float f22 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                                                                                                            ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                                                                                                            c1027y24.m9009b(R.string.cancel);
                                                                                                                                                                            final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                                            LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                                                                                                            linearLayout2.setOrientation(1);
                                                                                                                                                                            int i222 = (int) (12.0f * f22);
                                                                                                                                                                            int i232 = (int) (4.0f * f22);
                                                                                                                                                                            linearLayout2.setPadding(i222, (int) (8.0f * f22), i222, i232);
                                                                                                                                                                            ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                                                                                                            int size = m4163c0.size();
                                                                                                                                                                            int i242 = size / 5;
                                                                                                                                                                            int i252 = 0;
                                                                                                                                                                            if (size % 5 == 0) {
                                                                                                                                                                                i212 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ArrayList arrayList = new ArrayList(i242 + i212);
                                                                                                                                                                            for (int i262 = 0; i262 >= 0 && i262 < size; i262 += 5) {
                                                                                                                                                                                int i27 = size - i262;
                                                                                                                                                                                if (5 <= i27) {
                                                                                                                                                                                    i27 = 5;
                                                                                                                                                                                }
                                                                                                                                                                                ArrayList arrayList2 = new ArrayList(i27);
                                                                                                                                                                                for (int i28 = 0; i28 < i27; i28++) {
                                                                                                                                                                                    arrayList2.add(m4163c0.get(i28 + i262));
                                                                                                                                                                                }
                                                                                                                                                                                arrayList.add(arrayList2);
                                                                                                                                                                            }
                                                                                                                                                                            int size2 = arrayList.size();
                                                                                                                                                                            int i29 = 0;
                                                                                                                                                                            while (i29 < size2) {
                                                                                                                                                                                Object obj = arrayList.get(i29);
                                                                                                                                                                                i29++;
                                                                                                                                                                                LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                                                                                                                linearLayout3.setOrientation(i252);
                                                                                                                                                                                for (final String str9 : (List) obj) {
                                                                                                                                                                                    TextView textView32 = new TextView(mainActivity2);
                                                                                                                                                                                    textView32.setGravity(17);
                                                                                                                                                                                    textView32.setTextSize(10.0f);
                                                                                                                                                                                    int i30 = (int) (10.0f * f22);
                                                                                                                                                                                    textView32.setPadding(i232, i30, i232, i30);
                                                                                                                                                                                    ArrayList arrayList3 = arrayList;
                                                                                                                                                                                    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i252, (int) (46.0f * f22), 1.0f);
                                                                                                                                                                                    int i31 = (int) (3.0f * f22);
                                                                                                                                                                                    layoutParams.setMargins(i31, i31, i31, i31);
                                                                                                                                                                                    textView32.setLayoutParams(layoutParams);
                                                                                                                                                                                    int i32 = -16777216;
                                                                                                                                                                                    if (str9 != null) {
                                                                                                                                                                                        float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor(str9));
                                                                                                                                                                                        if (blue < 140.0f) {
                                                                                                                                                                                            i32 = -1;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setTextColor(i32);
                                                                                                                                                                                        if (str9.equals(m2096q)) {
                                                                                                                                                                                            str7 = "✓ ".concat(str9);
                                                                                                                                                                                        } else {
                                                                                                                                                                                            str7 = str9;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setText(str7);
                                                                                                                                                                                        textView32.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                                                                                                            @Override // android.view.View.OnClickListener
                                                                                                                                                                                            public final void onClick(View view3) {
                                                                                                                                                                                                MainActivity mainActivity3 = MainActivity.this;
                                                                                                                                                                                                SharedPreferences sharedPreferences222 = mainActivity3.f4067t;
                                                                                                                                                                                                if (sharedPreferences222 != null) {
                                                                                                                                                                                                    sharedPreferences222.edit().putString("pref_cursor_color", str9).apply();
                                                                                                                                                                                                    SharedPreferences sharedPreferences232 = mainActivity3.f4067t;
                                                                                                                                                                                                    if (sharedPreferences232 != null) {
                                                                                                                                                                                                        sharedPreferences232.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                                                                                                        mainActivity3.m2104C();
                                                                                                                                                                                                        m9008a3.dismiss();
                                                                                                                                                                                                        return;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                    throw null;
                                                                                                                                                                                                }
                                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                throw null;
                                                                                                                                                                                            }
                                                                                                                                                                                        });
                                                                                                                                                                                    } else {
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                                                                                                        textView32.setTextColor(-16777216);
                                                                                                                                                                                        textView32.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                                                                                                        textView32.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                                                                                                                    }
                                                                                                                                                                                    linearLayout3.addView(textView32);
                                                                                                                                                                                    arrayList = arrayList3;
                                                                                                                                                                                    i252 = 0;
                                                                                                                                                                                }
                                                                                                                                                                                linearLayout2.addView(linearLayout3);
                                                                                                                                                                                i252 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                                                                                                            scrollView.addView(linearLayout2);
                                                                                                                                                                            C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                                                                                                            c0990x2.f18184g = scrollView;
                                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                                            m9008a3.show();
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                                        throw null;
                                                                                                                                                                    }
                                                                                                                                                                });
                                                                                                                                                                linearLayout.addView(textView22);
                                                                                                                                                            }
                                                                                                                                                            C0990x2 c0990x2 = m9008a2.f19651s;
                                                                                                                                                            c0990x2.f18184g = linearLayout;
                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                            m9008a2.show();
                                                                                                                                                            return;
                                                                                                                                                        default:
                                                                                                                                                            int i192 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                                                                                                            ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                                                                                                            c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                                                                                                            c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                                                                                                            c20 c20Var = new c20(mainActivity, i72);
                                                                                                                                                            c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                                                                                                            c0879u23.f15170h = c20Var;
                                                                                                                                                            c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                            m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                                                                                                                @Override // android.content.DialogInterface.OnKeyListener
                                                                                                                                                                public final boolean onKey(DialogInterface dialogInterface, int i202, KeyEvent keyEvent) {
                                                                                                                                                                    int i212 = MainActivity.f4054M;
                                                                                                                                                                    if (keyEvent.getAction() == 0) {
                                                                                                                                                                        MainActivity mainActivity2 = MainActivity.this;
                                                                                                                                                                        if (i202 != 19 && i202 != 20 && i202 != 21 && i202 != 22 && i202 != 23) {
                                                                                                                                                                            if (i202 != 4 && i202 != 24 && i202 != 25 && i202 != 26) {
                                                                                                                                                                                SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                                if (sharedPreferences212 != null) {
                                                                                                                                                                                    sharedPreferences212.edit().putInt("pref_toggle_keycode", i202).apply();
                                                                                                                                                                                    mainActivity2.m2106E();
                                                                                                                                                                                    dialogInterface.dismiss();
                                                                                                                                                                                    return true;
                                                                                                                                                                                }
                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                throw null;
                                                                                                                                                                            }
                                                                                                                                                                        } else {
                                                                                                                                                                            Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                                                                                                            return true;
                                                                                                                                                                        }
                                                                                                                                                                    }
                                                                                                                                                                    return false;
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            m9008a3.show();
                                                                                                                                                            return;
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            for (jo0 jo0Var : AbstractC0484je.m4409W(new jo0(Integer.valueOf(R.id.btn_map_x_lb), Integer.valueOf(R.id.tv_map_x_lb_val), "lb"), new jo0(Integer.valueOf(R.id.btn_map_x_rb), Integer.valueOf(R.id.tv_map_x_rb_val), "rb"), new jo0(Integer.valueOf(R.id.btn_map_x_lt), Integer.valueOf(R.id.tv_map_x_lt_val), "lt"), new jo0(Integer.valueOf(R.id.btn_map_x_rt), Integer.valueOf(R.id.tv_map_x_rt_val), "rt"), new jo0(Integer.valueOf(R.id.btn_map_x_up), Integer.valueOf(R.id.tv_map_x_up_val), "up"), new jo0(Integer.valueOf(R.id.btn_map_x_down), Integer.valueOf(R.id.tv_map_x_down_val), "down"), new jo0(Integer.valueOf(R.id.btn_map_x_left), Integer.valueOf(R.id.tv_map_x_left_val), "left"), new jo0(Integer.valueOf(R.id.btn_map_x_right), Integer.valueOf(R.id.tv_map_x_right_val), "right"))) {
                                                                                                                                                int intValue = jo0Var.f8434n.intValue();
                                                                                                                                                final String str5 = jo0Var.f8436p;
                                                                                                                                                View findViewById5 = findViewById(intValue);
                                                                                                                                                findViewById5.setOnLongClickListener(new View.OnLongClickListener() { // from class: k20
                                                                                                                                                    @Override // android.view.View.OnLongClickListener
                                                                                                                                                    public final boolean onLongClick(View view) {
                                                                                                                                                        MainActivity mainActivity = MainActivity.this;
                                                                                                                                                        SharedPreferences sharedPreferences44 = mainActivity.f4067t;
                                                                                                                                                        if (sharedPreferences44 != null) {
                                                                                                                                                            StringBuilder sb = new StringBuilder("pref_mapping_x_");
                                                                                                                                                            String str6 = str5;
                                                                                                                                                            sb.append(str6);
                                                                                                                                                            sb.append("_type");
                                                                                                                                                            if (xl3.m8871b(sharedPreferences44.getString(sb.toString(), "none"), "click_location_repeat")) {
                                                                                                                                                                mainActivity.m2113z(str6);
                                                                                                                                                                return true;
                                                                                                                                                            }
                                                                                                                                                            return false;
                                                                                                                                                        }
                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                        throw null;
                                                                                                                                                    }
                                                                                                                                                });
                                                                                                                                                findViewById5.setOnClickListener(new ViewOnClickListenerC0837sy(this, str5, 1));
                                                                                                                                            }
                                                                                                                                            NavigationView navigationView = (NavigationView) findViewById(R.id.nav_drawer);
                                                                                                                                            this.f4055A = navigationView;
                                                                                                                                            navigationView.getMenu().findItem(R.id.nav_pro).setTitle(m2110v());
                                                                                                                                            navigationView.setItemIconTintList(null);
                                                                                                                                            List m4409W = AbstractC0484je.m4409W(Integer.valueOf(R.id.layout_settings_general), Integer.valueOf(R.id.layout_settings_pointer), Integer.valueOf(R.id.layout_settings_keyboard), Integer.valueOf(R.id.layout_pro_tab), Integer.valueOf(R.id.layout_initial_setup), Integer.valueOf(R.id.layout_how_to_use));
                                                                                                                                            this.f4073z = new x10(navigationView, this, m4409W, materialToolbar);
                                                                                                                                            navigationView.setNavigationItemSelectedListener(new y10(this, drawerLayout, m4409W, materialToolbar, textView16, button, textView17));
                                                                                                                                            navigationView.setCheckedItem(R.id.nav_general_settings);
                                                                                                                                            m2099t(this, m4409W, materialToolbar, R.id.layout_settings_general);
                                                                                                                                            m2111x();
                                                                                                                                            m2098s(navigationView, this, m4409W, materialToolbar, getIntent());
                                                                                                                                            final int i27 = 4;
                                                                                                                                            ((Button) findViewById(R.id.btn_reset_defaults)).setOnClickListener(new View.OnClickListener(this) { // from class: v10

                                                                                                                                                /* renamed from: o */
                                                                                                                                                public final /* synthetic */ MainActivity f15949o;

                                                                                                                                                {
                                                                                                                                                    this.f15949o = this;
                                                                                                                                                }

                                                                                                                                                @Override // android.view.View.OnClickListener
                                                                                                                                                public final void onClick(View view) {
                                                                                                                                                    int i62 = i27;
                                                                                                                                                    int i72 = 2;
                                                                                                                                                    int i82 = 1;
                                                                                                                                                    final MainActivity mainActivity = this.f15949o;
                                                                                                                                                    switch (i62) {
                                                                                                                                                        case 0:
                                                                                                                                                            int i92 = MainActivity.f4054M;
                                                                                                                                                            final int requestedOrientation = mainActivity.getRequestedOrientation();
                                                                                                                                                            mainActivity.setRequestedOrientation(0);
                                                                                                                                                            Dialog dialog2 = new Dialog(mainActivity, R.style.Theme.Black.NoTitleBar.Fullscreen);
                                                                                                                                                            dialog2.setContentView(com.pkyul13.gamepadmouse.R.layout.dialog_full_screen_image);
                                                                                                                                                            ImageView imageView2 = (ImageView) dialog2.findViewById(com.pkyul13.gamepadmouse.R.id.iv_full_screen);
                                                                                                                                                            imageView2.setImageResource(com.pkyul13.gamepadmouse.R.drawable.guide);
                                                                                                                                                            imageView2.setOnClickListener(new ViewOnClickListenerC0853td(3, dialog2));
                                                                                                                                                            dialog2.setOnDismissListener(new DialogInterface.OnDismissListener() { // from class: b20
                                                                                                                                                                @Override // android.content.DialogInterface.OnDismissListener
                                                                                                                                                                public final void onDismiss(DialogInterface dialogInterface) {
                                                                                                                                                                    int i102 = MainActivity.f4054M;
                                                                                                                                                                    MainActivity.this.setRequestedOrientation(requestedOrientation);
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            dialog2.show();
                                                                                                                                                            return;
                                                                                                                                                        case 1:
                                                                                                                                                            int i102 = MainActivity.f4054M;
                                                                                                                                                            Intent intent = new Intent("android.settings.ACCESSIBILITY_SETTINGS");
                                                                                                                                                            intent.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent);
                                                                                                                                                            return;
                                                                                                                                                        case 2:
                                                                                                                                                            int i112 = MainActivity.f4054M;
                                                                                                                                                            Intent intent2 = new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS");
                                                                                                                                                            intent2.addFlags(268435456);
                                                                                                                                                            mainActivity.startActivity(intent2);
                                                                                                                                                            return;
                                                                                                                                                        case 3:
                                                                                                                                                            FirebaseAnalytics firebaseAnalytics3 = mainActivity.f4068u;
                                                                                                                                                            if (firebaseAnalytics3 != null) {
                                                                                                                                                                firebaseAnalytics3.m2093a("click_upgrade_pro", null);
                                                                                                                                                                db0.m2411e(mainActivity);
                                                                                                                                                                return;
                                                                                                                                                            } else {
                                                                                                                                                                xl3.m8890u("firebaseAnalytics");
                                                                                                                                                                throw null;
                                                                                                                                                            }
                                                                                                                                                        case 4:
                                                                                                                                                            int i122 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y2 = new C1027y2(mainActivity);
                                                                                                                                                            String string32 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_all_settings);
                                                                                                                                                            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
                                                                                                                                                            c0879u2.f15166d = string32;
                                                                                                                                                            c0879u2.f15168f = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset_confirm_msg);
                                                                                                                                                            c1027y2.m9010f(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.reset), new c20(mainActivity, i82));
                                                                                                                                                            c0879u2.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a = c1027y2.m9008a();
                                                                                                                                                            m9008a.show();
                                                                                                                                                            Button button2 = m9008a.f19651s.f18186i;
                                                                                                                                                            if (button2 != null) {
                                                                                                                                                                button2.setTextColor(mainActivity.getColor(com.pkyul13.gamepadmouse.R.color.accent_red));
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            return;
                                                                                                                                                        case 5:
                                                                                                                                                            int i132 = MainActivity.f4054M;
                                                                                                                                                            String[] strArr = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_en), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_ko), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.lang_es)};
                                                                                                                                                            String str52 = "en";
                                                                                                                                                            String[] strArr2 = {"en", "ko", "es"};
                                                                                                                                                            SharedPreferences sharedPreferences202 = mainActivity.f4067t;
                                                                                                                                                            if (sharedPreferences202 != null) {
                                                                                                                                                                String string4 = sharedPreferences202.getString("pref_language", "en");
                                                                                                                                                                if (string4 != null) {
                                                                                                                                                                    str52 = string4;
                                                                                                                                                                }
                                                                                                                                                                int m5906o0 = AbstractC0662o7.m5906o0(strArr2, str52);
                                                                                                                                                                C1027y2 c1027y22 = new C1027y2(mainActivity);
                                                                                                                                                                String string5 = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.select_language);
                                                                                                                                                                C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                                                                                                                                                                c0879u22.f15166d = string5;
                                                                                                                                                                i20 i20Var = new i20(strArr2, str52, mainActivity);
                                                                                                                                                                c0879u22.f15173k = strArr;
                                                                                                                                                                c0879u22.f15175m = i20Var;
                                                                                                                                                                c0879u22.f15178p = m5906o0;
                                                                                                                                                                c0879u22.f15177o = true;
                                                                                                                                                                c1027y22.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                                c1027y22.m9011g();
                                                                                                                                                                return;
                                                                                                                                                            }
                                                                                                                                                            xl3.m8890u("sharedPrefs");
                                                                                                                                                            throw null;
                                                                                                                                                        case 6:
                                                                                                                                                            int i142 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y23 = new C1027y2(mainActivity);
                                                                                                                                                            ((C0879u2) c1027y23.f18934o).f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_style);
                                                                                                                                                            c1027y23.m9009b(R.string.cancel);
                                                                                                                                                            final DialogC1064z2 m9008a2 = c1027y23.m9008a();
                                                                                                                                                            float f2 = mainActivity.getResources().getDisplayMetrics().density;
                                                                                                                                                            LinearLayout linearLayout = new LinearLayout(mainActivity);
                                                                                                                                                            linearLayout.setOrientation(1);
                                                                                                                                                            int i152 = (int) (16.0f * f2);
                                                                                                                                                            int i162 = (int) (8.0f * f2);
                                                                                                                                                            linearLayout.setPadding(i152, (int) (4.0f * f2), i152, i162);
                                                                                                                                                            String[] strArr3 = {mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color), mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_png)};
                                                                                                                                                            for (final int i172 = 0; i172 < 2; i172++) {
                                                                                                                                                                String str6 = strArr3[i172];
                                                                                                                                                                str6.getClass();
                                                                                                                                                                TextView textView22 = new TextView(mainActivity);
                                                                                                                                                                textView22.setText(str6);
                                                                                                                                                                textView22.setTextSize(16.0f);
                                                                                                                                                                int i182 = (int) (14.0f * f2);
                                                                                                                                                                textView22.setPadding(i162, i182, i162, i182);
                                                                                                                                                                textView22.setOnClickListener(new View.OnClickListener() { // from class: f20
                                                                                                                                                                    @Override // android.view.View.OnClickListener
                                                                                                                                                                    public final void onClick(View view2) {
                                                                                                                                                                        String str7;
                                                                                                                                                                        int i192 = MainActivity.f4054M;
                                                                                                                                                                        DialogC1064z2.this.dismiss();
                                                                                                                                                                        int i202 = i172;
                                                                                                                                                                        final MainActivity mainActivity2 = mainActivity;
                                                                                                                                                                        int i212 = 1;
                                                                                                                                                                        if (i202 != 0) {
                                                                                                                                                                            if (i202 != 1) {
                                                                                                                                                                                return;
                                                                                                                                                                            }
                                                                                                                                                                            mainActivity2.f4062H.mo4620a("image/png", null);
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                        if (sharedPreferences212 != null) {
                                                                                                                                                                            String str8 = "#FFA000";
                                                                                                                                                                            String string6 = sharedPreferences212.getString("pref_cursor_color", "#FFA000");
                                                                                                                                                                            if (string6 != null) {
                                                                                                                                                                                str8 = string6;
                                                                                                                                                                            }
                                                                                                                                                                            String m2096q = MainActivity.m2096q(str8);
                                                                                                                                                                            float f22 = mainActivity2.getResources().getDisplayMetrics().density;
                                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity2);
                                                                                                                                                                            ((C0879u2) c1027y24.f18934o).f15166d = mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_custom_color);
                                                                                                                                                                            c1027y24.m9009b(R.string.cancel);
                                                                                                                                                                            final DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                                            LinearLayout linearLayout2 = new LinearLayout(mainActivity2);
                                                                                                                                                                            linearLayout2.setOrientation(1);
                                                                                                                                                                            int i222 = (int) (12.0f * f22);
                                                                                                                                                                            int i232 = (int) (4.0f * f22);
                                                                                                                                                                            linearLayout2.setPadding(i222, (int) (8.0f * f22), i222, i232);
                                                                                                                                                                            ArrayList m4163c0 = AbstractC0449ie.m4163c0(mainActivity2.f4066L, tq1.m7761r(null));
                                                                                                                                                                            int size = m4163c0.size();
                                                                                                                                                                            int i242 = size / 5;
                                                                                                                                                                            int i252 = 0;
                                                                                                                                                                            if (size % 5 == 0) {
                                                                                                                                                                                i212 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ArrayList arrayList = new ArrayList(i242 + i212);
                                                                                                                                                                            for (int i262 = 0; i262 >= 0 && i262 < size; i262 += 5) {
                                                                                                                                                                                int i272 = size - i262;
                                                                                                                                                                                if (5 <= i272) {
                                                                                                                                                                                    i272 = 5;
                                                                                                                                                                                }
                                                                                                                                                                                ArrayList arrayList2 = new ArrayList(i272);
                                                                                                                                                                                for (int i28 = 0; i28 < i272; i28++) {
                                                                                                                                                                                    arrayList2.add(m4163c0.get(i28 + i262));
                                                                                                                                                                                }
                                                                                                                                                                                arrayList.add(arrayList2);
                                                                                                                                                                            }
                                                                                                                                                                            int size2 = arrayList.size();
                                                                                                                                                                            int i29 = 0;
                                                                                                                                                                            while (i29 < size2) {
                                                                                                                                                                                Object obj = arrayList.get(i29);
                                                                                                                                                                                i29++;
                                                                                                                                                                                LinearLayout linearLayout3 = new LinearLayout(mainActivity2);
                                                                                                                                                                                linearLayout3.setOrientation(i252);
                                                                                                                                                                                for (final String str9 : (List) obj) {
                                                                                                                                                                                    TextView textView32 = new TextView(mainActivity2);
                                                                                                                                                                                    textView32.setGravity(17);
                                                                                                                                                                                    textView32.setTextSize(10.0f);
                                                                                                                                                                                    int i30 = (int) (10.0f * f22);
                                                                                                                                                                                    textView32.setPadding(i232, i30, i232, i30);
                                                                                                                                                                                    ArrayList arrayList3 = arrayList;
                                                                                                                                                                                    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(i252, (int) (46.0f * f22), 1.0f);
                                                                                                                                                                                    int i31 = (int) (3.0f * f22);
                                                                                                                                                                                    layoutParams.setMargins(i31, i31, i31, i31);
                                                                                                                                                                                    textView32.setLayoutParams(layoutParams);
                                                                                                                                                                                    int i32 = -16777216;
                                                                                                                                                                                    if (str9 != null) {
                                                                                                                                                                                        float blue = (Color.blue(r14) * 0.114f) + (Color.green(r14) * 0.587f) + (Color.red(r14) * 0.299f);
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor(str9));
                                                                                                                                                                                        if (blue < 140.0f) {
                                                                                                                                                                                            i32 = -1;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setTextColor(i32);
                                                                                                                                                                                        if (str9.equals(m2096q)) {
                                                                                                                                                                                            str7 = "✓ ".concat(str9);
                                                                                                                                                                                        } else {
                                                                                                                                                                                            str7 = str9;
                                                                                                                                                                                        }
                                                                                                                                                                                        textView32.setText(str7);
                                                                                                                                                                                        textView32.setOnClickListener(new View.OnClickListener() { // from class: m20
                                                                                                                                                                                            @Override // android.view.View.OnClickListener
                                                                                                                                                                                            public final void onClick(View view3) {
                                                                                                                                                                                                MainActivity mainActivity3 = MainActivity.this;
                                                                                                                                                                                                SharedPreferences sharedPreferences222 = mainActivity3.f4067t;
                                                                                                                                                                                                if (sharedPreferences222 != null) {
                                                                                                                                                                                                    sharedPreferences222.edit().putString("pref_cursor_color", str9).apply();
                                                                                                                                                                                                    SharedPreferences sharedPreferences232 = mainActivity3.f4067t;
                                                                                                                                                                                                    if (sharedPreferences232 != null) {
                                                                                                                                                                                                        sharedPreferences232.edit().putString("pref_cursor_style", "custom_color").apply();
                                                                                                                                                                                                        mainActivity3.m2104C();
                                                                                                                                                                                                        m9008a3.dismiss();
                                                                                                                                                                                                        return;
                                                                                                                                                                                                    }
                                                                                                                                                                                                    xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                    throw null;
                                                                                                                                                                                                }
                                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                                throw null;
                                                                                                                                                                                            }
                                                                                                                                                                                        });
                                                                                                                                                                                    } else {
                                                                                                                                                                                        textView32.setBackgroundColor(Color.parseColor("#E0E0E0"));
                                                                                                                                                                                        textView32.setTextColor(-16777216);
                                                                                                                                                                                        textView32.setText(mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.cursor_color_manual));
                                                                                                                                                                                        textView32.setOnClickListener(new ViewOnClickListenerC0837sy(m9008a3, mainActivity2, 2));
                                                                                                                                                                                    }
                                                                                                                                                                                    linearLayout3.addView(textView32);
                                                                                                                                                                                    arrayList = arrayList3;
                                                                                                                                                                                    i252 = 0;
                                                                                                                                                                                }
                                                                                                                                                                                linearLayout2.addView(linearLayout3);
                                                                                                                                                                                i252 = 0;
                                                                                                                                                                            }
                                                                                                                                                                            ScrollView scrollView = new ScrollView(mainActivity2);
                                                                                                                                                                            scrollView.addView(linearLayout2);
                                                                                                                                                                            C0990x2 c0990x2 = m9008a3.f19651s;
                                                                                                                                                                            c0990x2.f18184g = scrollView;
                                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                                            m9008a3.show();
                                                                                                                                                                            return;
                                                                                                                                                                        }
                                                                                                                                                                        xl3.m8890u("sharedPrefs");
                                                                                                                                                                        throw null;
                                                                                                                                                                    }
                                                                                                                                                                });
                                                                                                                                                                linearLayout.addView(textView22);
                                                                                                                                                            }
                                                                                                                                                            C0990x2 c0990x2 = m9008a2.f19651s;
                                                                                                                                                            c0990x2.f18184g = linearLayout;
                                                                                                                                                            c0990x2.f18185h = false;
                                                                                                                                                            m9008a2.show();
                                                                                                                                                            return;
                                                                                                                                                        default:
                                                                                                                                                            int i192 = MainActivity.f4054M;
                                                                                                                                                            C1027y2 c1027y24 = new C1027y2(mainActivity);
                                                                                                                                                            C0879u2 c0879u23 = (C0879u2) c1027y24.f18934o;
                                                                                                                                                            ContextThemeWrapper contextThemeWrapper = c0879u23.f15163a;
                                                                                                                                                            c0879u23.f15166d = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_title);
                                                                                                                                                            c0879u23.f15168f = contextThemeWrapper.getText(com.pkyul13.gamepadmouse.R.string.press_gamepad_button_msg);
                                                                                                                                                            c20 c20Var = new c20(mainActivity, i72);
                                                                                                                                                            c0879u23.f15169g = c0879u23.f15163a.getText(com.pkyul13.gamepadmouse.R.string.reset_toggle_key_default);
                                                                                                                                                            c0879u23.f15170h = c20Var;
                                                                                                                                                            c1027y24.m9009b(com.pkyul13.gamepadmouse.R.string.cancel);
                                                                                                                                                            DialogC1064z2 m9008a3 = c1027y24.m9008a();
                                                                                                                                                            m9008a3.setOnKeyListener(new DialogInterface.OnKeyListener() { // from class: d20
                                                                                                                                                                @Override // android.content.DialogInterface.OnKeyListener
                                                                                                                                                                public final boolean onKey(DialogInterface dialogInterface, int i202, KeyEvent keyEvent) {
                                                                                                                                                                    int i212 = MainActivity.f4054M;
                                                                                                                                                                    if (keyEvent.getAction() == 0) {
                                                                                                                                                                        MainActivity mainActivity2 = MainActivity.this;
                                                                                                                                                                        if (i202 != 19 && i202 != 20 && i202 != 21 && i202 != 22 && i202 != 23) {
                                                                                                                                                                            if (i202 != 4 && i202 != 24 && i202 != 25 && i202 != 26) {
                                                                                                                                                                                SharedPreferences sharedPreferences212 = mainActivity2.f4067t;
                                                                                                                                                                                if (sharedPreferences212 != null) {
                                                                                                                                                                                    sharedPreferences212.edit().putInt("pref_toggle_keycode", i202).apply();
                                                                                                                                                                                    mainActivity2.m2106E();
                                                                                                                                                                                    dialogInterface.dismiss();
                                                                                                                                                                                    return true;
                                                                                                                                                                                }
                                                                                                                                                                                xl3.m8890u("sharedPrefs");
                                                                                                                                                                                throw null;
                                                                                                                                                                            }
                                                                                                                                                                        } else {
                                                                                                                                                                            Toast.makeText(mainActivity2, mainActivity2.getString(com.pkyul13.gamepadmouse.R.string.toast_dpad_not_allowed), 0).show();
                                                                                                                                                                            return true;
                                                                                                                                                                        }
                                                                                                                                                                    }
                                                                                                                                                                    return false;
                                                                                                                                                                }
                                                                                                                                                            });
                                                                                                                                                            m9008a3.show();
                                                                                                                                                            return;
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            });
                                                                                                                                            try {
                                                                                                                                                if (Build.VERSION.SDK_INT >= 33) {
                                                                                                                                                    PackageManager packageManager = getPackageManager();
                                                                                                                                                    String packageName = getPackageName();
                                                                                                                                                    of = PackageManager.PackageInfoFlags.of(0L);
                                                                                                                                                    packageInfo = packageManager.getPackageInfo(packageName, of);
                                                                                                                                                } else {
                                                                                                                                                    packageInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
                                                                                                                                                }
                                                                                                                                                ((TextView) findViewById(R.id.tv_drawer_version)).setText(getString(R.string.app_version_format, packageInfo.versionName));
                                                                                                                                                return;
                                                                                                                                            } catch (Exception e) {
                                                                                                                                                e.printStackTrace();
                                                                                                                                                return;
                                                                                                                                            }
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
        xl3.m8890u("firebaseAnalytics");
        throw null;
    }

    @Override // p000.AbstractActivityC0439i4, android.app.Activity
    public final void onDestroy() {
        try {
            boolean z = db0.f4577a;
            C0360g c0360g = this.f4060F;
            c0360g.getClass();
            db0.f4582f.remove(c0360g);
            AdView adView = this.f4070w;
            if (adView != null) {
                adView.destroy();
            }
        } catch (Throwable unused) {
        }
        super.onDestroy();
    }

    @Override // android.app.Activity
    public final boolean onGenericMotionEvent(MotionEvent motionEvent) {
        motionEvent.getClass();
        if ((motionEvent.getSource() & 16777232) == 16777232 && motionEvent.getAction() == 2) {
            float axisValue = motionEvent.getAxisValue(0);
            float axisValue2 = motionEvent.getAxisValue(1);
            float axisValue3 = motionEvent.getAxisValue(11);
            float axisValue4 = motionEvent.getAxisValue(14);
            float hypot = (float) Math.hypot(axisValue, axisValue2);
            float hypot2 = (float) Math.hypot(axisValue3, axisValue4);
            ProgressBar progressBar = (ProgressBar) findViewById(R.id.progress_lstick_test);
            ProgressBar progressBar2 = (ProgressBar) findViewById(R.id.progress_rstick_test);
            TextView textView = (TextView) findViewById(R.id.tv_lstick_val);
            TextView textView2 = (TextView) findViewById(R.id.tv_rstick_val);
            TextView textView3 = (TextView) findViewById(R.id.tv_test_status);
            if (progressBar != null) {
                progressBar.setProgress((int) (hypot * 100.0f));
            }
            if (progressBar2 != null) {
                progressBar2.setProgress((int) (100.0f * hypot2));
            }
            if (textView != null) {
                textView.setText(String.format("%.2f", Arrays.copyOf(new Object[]{Float.valueOf(hypot)}, 1)));
            }
            if (textView2 != null) {
                textView2.setText(String.format("%.2f", Arrays.copyOf(new Object[]{Float.valueOf(hypot2)}, 1)));
            }
            int color = getColor(R.color.holo_blue_light);
            int color2 = getColor(R.color.darker_gray);
            float f = this.f4069v;
            if (hypot <= f && hypot2 <= f) {
                if (textView3 != null) {
                    textView3.setText("IDLE (Inside Deadzone)");
                }
                if (textView3 != null) {
                    textView3.setTextColor(color2);
                }
            } else {
                if (textView3 != null) {
                    textView3.setText("STICK ACTIVE (Input Recognized)");
                }
                if (textView3 != null) {
                    textView3.setTextColor(color);
                }
            }
            return true;
        }
        return super.onGenericMotionEvent(motionEvent);
    }

    @Override // p000.AbstractActivityC0439i4, androidx.activity.ComponentActivity, android.app.Activity
    public final void onNewIntent(Intent intent) {
        intent.getClass();
        super.onNewIntent(intent);
        setIntent(intent);
        x10 x10Var = this.f4073z;
        if (x10Var != null) {
            x10Var.mo3287e(intent);
        }
    }

    @Override // p000.AbstractActivityC0439i4, android.app.Activity
    public final void onPause() {
        PopupWindow popupWindow = this.f4059E;
        if (popupWindow != null) {
            popupWindow.dismiss();
        }
        try {
            AdView adView = this.f4070w;
            if (adView != null) {
                adView.pause();
            }
        } catch (Throwable unused) {
        }
        super.onPause();
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            sharedPreferences.unregisterOnSharedPreferenceChangeListener(this.f4063I);
        } else {
            xl3.m8890u("sharedPrefs");
            throw null;
        }
    }

    @Override // p000.AbstractActivityC0439i4, android.app.Activity
    public final void onResume() {
        AdView adView;
        super.onResume();
        try {
            if (!db0.m2408b() && (adView = this.f4070w) != null) {
                adView.resume();
            }
        } catch (Throwable unused) {
        }
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            sharedPreferences.registerOnSharedPreferenceChangeListener(this.f4063I);
            SwitchCompat switchCompat = (SwitchCompat) findViewById(R.id.switch_mouse_enabled);
            SharedPreferences sharedPreferences2 = this.f4067t;
            if (sharedPreferences2 != null) {
                switchCompat.setChecked(sharedPreferences2.getBoolean("pref_mouse_enabled", true));
                SharedPreferences sharedPreferences3 = this.f4067t;
                if (sharedPreferences3 != null) {
                    int i = sharedPreferences3.getInt("pref_l3_long_press_duration", 0);
                    SeekBar seekBar = (SeekBar) findViewById(R.id.seekbar_l3_long_press);
                    if (seekBar != null) {
                        seekBar.setProgress(i);
                    }
                    TextView textView = (TextView) findViewById(R.id.tv_l3_long_press_val);
                    if (textView != null) {
                        textView.setText(m2108o(i));
                    }
                    SwitchCompat switchCompat2 = (SwitchCompat) findViewById(R.id.switch_swap_ab_buttons);
                    if (switchCompat2 != null) {
                        SharedPreferences sharedPreferences4 = this.f4067t;
                        if (sharedPreferences4 != null) {
                            switchCompat2.setChecked(sharedPreferences4.getBoolean("pref_swap_ab_buttons", false));
                        } else {
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                    }
                    SwitchCompat switchCompat3 = (SwitchCompat) findViewById(R.id.switch_haptic_feedback);
                    SharedPreferences sharedPreferences5 = this.f4067t;
                    if (sharedPreferences5 != null) {
                        switchCompat3.setChecked(sharedPreferences5.getBoolean("pref_haptic_feedback", true));
                        m2102A();
                        m2111x();
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

    /* renamed from: p */
    public final boolean m2109p() {
        String flattenToString = new ComponentName(this, (Class<?>) MouseAccessibilityService.class).flattenToString();
        flattenToString.getClass();
        String string = Settings.Secure.getString(getContentResolver(), "enabled_accessibility_services");
        if (string != null && ek0.m2909S(string, flattenToString)) {
            return true;
        }
        return false;
    }

    /* renamed from: v */
    public final String m2110v() {
        int i;
        if (db0.m2408b()) {
            i = R.string.nav_pro_features;
        } else {
            i = R.string.nav_pro_buy;
        }
        String string = getString(i);
        string.getClass();
        return string;
    }

    /* renamed from: x */
    public final void m2111x() {
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            if (sharedPreferences.getBoolean("pref_drawer_hint_done", false) || !m2109p()) {
                return;
            }
            getWindow().getDecorView().postDelayed(new RunnableC0151b2(7, this), 900L);
            return;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }

    /* renamed from: y */
    public final void m2112y() {
        try {
            this.f4071x = (FrameLayout) findViewById(R.id.layout_ad_container);
            boolean z = db0.f4577a;
            C0360g c0360g = this.f4060F;
            c0360g.getClass();
            CopyOnWriteArrayList copyOnWriteArrayList = db0.f4582f;
            if (!copyOnWriteArrayList.contains(c0360g)) {
                copyOnWriteArrayList.add(c0360g);
            }
            m2103B(db0.m2408b());
        } catch (Throwable th) {
            Log.e("AdMob", "setupBannerAd error: " + th.getMessage(), th);
        }
    }

    /* renamed from: z */
    public final void m2113z(final String str) {
        SharedPreferences sharedPreferences = this.f4067t;
        if (sharedPreferences != null) {
            final int m5054i = lo0.m5054i(sharedPreferences.getInt("pref_mapping_x_" + str + "_interval", 500), 100, 3000);
            List list = this.f4064J;
            List list2 = list;
            ArrayList arrayList = new ArrayList(AbstractC0521ke.m4717Y(list2));
            Iterator it = list2.iterator();
            while (it.hasNext()) {
                String string = getString(R.string.repeat_interval_format, Double.valueOf(((Number) it.next()).intValue() / 1000.0d));
                string.getClass();
                arrayList.add(string);
            }
            String string2 = getString(R.string.repeat_interval_custom);
            ArrayList arrayList2 = new ArrayList(arrayList.size() + 1);
            arrayList2.addAll(arrayList);
            arrayList2.add(string2);
            int indexOf = list.indexOf(Integer.valueOf(m5054i));
            if (indexOf < 0) {
                indexOf = arrayList2.size() - 1;
            }
            C1027y2 c1027y2 = new C1027y2(this);
            C0879u2 c0879u2 = (C0879u2) c1027y2.f18934o;
            c0879u2.f15166d = getString(R.string.repeat_interval_title);
            CharSequence[] charSequenceArr = (CharSequence[]) arrayList2.toArray(new String[0]);
            DialogInterface.OnClickListener onClickListener = new DialogInterface.OnClickListener() { // from class: n20
                @Override // android.content.DialogInterface.OnClickListener
                public final void onClick(DialogInterface dialogInterface, int i) {
                    int i2 = MainActivity.f4054M;
                    dialogInterface.dismiss();
                    MainActivity mainActivity = MainActivity.this;
                    List list3 = mainActivity.f4064J;
                    int size = list3.size();
                    String str2 = str;
                    if (i < size) {
                        SharedPreferences sharedPreferences2 = mainActivity.f4067t;
                        if (sharedPreferences2 != null) {
                            sharedPreferences2.edit().putInt(AbstractC0783rh.m6821k("pref_mapping_x_", str2, "_interval"), ((Number) list3.get(i)).intValue()).apply();
                            mainActivity.m2102A();
                            return;
                        } else {
                            xl3.m8890u("sharedPrefs");
                            throw null;
                        }
                    }
                    final EditText editText = new EditText(mainActivity);
                    editText.setInputType(2);
                    editText.setText(String.valueOf(m5054i));
                    editText.setHint(mainActivity.getString(com.pkyul13.gamepadmouse.R.string.repeat_interval_hint));
                    editText.setSelection(editText.getText().length());
                    LinearLayout linearLayout = new LinearLayout(mainActivity);
                    linearLayout.setPadding(48, 24, 48, 0);
                    linearLayout.addView(editText);
                    C1027y2 c1027y22 = new C1027y2(mainActivity);
                    C0879u2 c0879u22 = (C0879u2) c1027y22.f18934o;
                    c0879u22.f15166d = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.repeat_interval_title);
                    c0879u22.f15176n = linearLayout;
                    c1027y22.m9010f(mainActivity.getString(R.string.ok), new i20(editText, mainActivity, str2));
                    c0879u22.f15171i = mainActivity.getString(com.pkyul13.gamepadmouse.R.string.cancel);
                    final DialogC1064z2 m9011g = c1027y22.m9011g();
                    m9011g.setOnShowListener(new DialogInterface.OnShowListener() { // from class: q20
                        @Override // android.content.DialogInterface.OnShowListener
                        public final void onShow(DialogInterface dialogInterface2) {
                            int i3 = MainActivity.f4054M;
                            editText.requestFocus();
                            Window window = m9011g.getWindow();
                            if (window != null) {
                                window.setSoftInputMode(4);
                            }
                        }
                    });
                }
            };
            c0879u2.f15173k = charSequenceArr;
            c0879u2.f15175m = onClickListener;
            c0879u2.f15178p = indexOf;
            c0879u2.f15177o = true;
            c0879u2.f15171i = getString(R.string.cancel);
            c1027y2.m9011g();
            return;
        }
        xl3.m8890u("sharedPrefs");
        throw null;
    }
}
