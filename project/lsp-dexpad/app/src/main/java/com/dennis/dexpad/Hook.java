package com.dennis.dexpad;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.lang.reflect.Proxy;
import java.util.List;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * Adds a "手柄映射" row to Samsung's DeX settings page.
 *
 * The page is {@code com.samsung.android.settings.desktop.DexModeSettingsFragment};
 * it builds an androidx PreferenceScreen from XML and then appends a
 * {@code SecButtonPreference} for the wireless-connect button. A row can simply be
 * added to that same screen, which keeps the row inside the native list (native
 * card background, native ripples, scroll position, ...).
 *
 * Clicking the row opens the module's own settings-style mapping page.
 */
public class Hook implements IXposedHookLoadPackage {

    private static final String TAG = "[dexpad] ";
    private static final String SETTINGS = "com.android.settings";
    private static final String FRAGMENT =
            "com.samsung.android.settings.desktop.DexModeSettingsFragment";
    private static final String PREF_KEY = "key_dexpad_mapping";
    private static final String CONFIG_ACTIVITY = "com.dennis.dexpad.ConfigActivity";

    @Override
    public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam lp) {
        if (!SETTINGS.equals(lp.packageName)) return;
        XposedBridge.log(TAG + "loaded in " + lp.packageName + " (" + lp.processName + ")");
        try {
            Class<?> fragment = XposedHelpers.findClass(FRAGMENT, lp.classLoader);
            XposedBridge.hookAllMethods(fragment, "onCreate", new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) {
                    try {
                        inject(param.thisObject, lp.classLoader);
                    } catch (Throwable t) {
                        log("inject failed: " + Log.getStackTraceString(t));
                    }
                }
            });
            XposedBridge.log(TAG + "hooked " + FRAGMENT + "#onCreate");
        } catch (Throwable t) {
            log("fragment class missing: " + t);
        }
    }

    @SuppressWarnings("unchecked")
    private static void inject(Object fragment, ClassLoader cl) {
        Object screen = XposedHelpers.callMethod(fragment, "getPreferenceScreen");
        if (screen == null) {
            log("preference screen is null");
            return;
        }
        try {
            if (XposedHelpers.callMethod(screen, "findPreference", PREF_KEY) != null) return;
        } catch (Throwable ignored) {
        }

        Context ctx = null;
        try {
            ctx = (Context) XposedHelpers.callMethod(fragment, "getContext");
        } catch (Throwable ignored) {
        }
        if (ctx == null) {
            log("fragment context is null");
            return;
        }

        Object pref = newPreference(ctx, cl);
        if (pref == null) return;

        XposedHelpers.callMethod(pref, "setKey", PREF_KEY);
        XposedHelpers.callMethod(pref, "setTitle", "手柄映射");
        XposedHelpers.callMethod(pref, "setSummary", "用手柄控制手机的鼠标指针、左右键和滚轮");

        final Context appCtx = ctx;
        try {
            Class<?> listener = XposedHelpers.findClass(
                    "androidx.preference.Preference$OnPreferenceClickListener", cl);
            Object proxy = Proxy.newProxyInstance(cl, new Class<?>[]{listener},
                    (p, method, args) -> {
                        openConfig(appCtx);
                        return true;
                    });
            XposedHelpers.callMethod(pref, "setOnPreferenceClickListener", proxy);
        } catch (Throwable t) {
            log("click listener failed: " + t);
        }

        boolean inserted = false;
        Object group = screen;
        try {
            Object anchor = XposedHelpers.callMethod(screen, "findPreference",
                    "key_mouse_and_trackpad");
            if (anchor == null) {
                log("anchor key not found on screen, trying fragment");
                try {
                    anchor = XposedHelpers.callMethod(fragment, "findPreference",
                            "key_mouse_and_trackpad");
                } catch (Throwable ignored) {
                }
            }
            if (anchor != null) {
                Object parent = XposedHelpers.callMethod(anchor, "getParent");
                log("anchor " + anchor.getClass().getSimpleName() + " parent="
                        + (parent == null ? "null" : parent.getClass().getSimpleName()));
                if (parent != null) group = parent;
            }
            List<Object> list = (List<Object>) XposedHelpers.getObjectField(group, "mPreferences");
            StringBuilder sb = new StringBuilder();
            for (Object o : list) {
                try {
                    Object key = XposedHelpers.callMethod(o, "getKey");
                    Object title = XposedHelpers.callMethod(o, "getTitle");
                    sb.append(key).append('/').append(title).append(" | ");
                } catch (Throwable ignored) {
                    sb.append("? | ");
                }
            }
            log("group has " + list.size() + " prefs: " + sb);
            XposedHelpers.callMethod(group, "addPreference", pref);
            inserted = true;
        } catch (Throwable t) {
            log("group insert failed: " + t);
        }
        if (!inserted) {
            try {
                XposedHelpers.callMethod(screen, "addPreference", pref);
            } catch (Throwable t) {
                log("append failed: " + t);
                return;
            }
        }
        try {
            XposedHelpers.callMethod(screen, "notifyChanged");
        } catch (Throwable ignored) {
        }
        if (group != screen) {
            try {
                XposedHelpers.callMethod(group, "notifyChanged");
            } catch (Throwable ignored) {
            }
        }
        log("mapping row inserted into " + (group == screen ? "screen" : "nested group"));
    }

    private static Object newPreference(Context ctx, ClassLoader cl) {
        String[] classes = {
                "androidx.preference.SecPreference",
                "androidx.preference.Preference",
        };
        for (String name : classes) {
            try {
                Class<?> cls = XposedHelpers.findClass(name, cl);
                Object pref = instantiate(cls, ctx);
                if (pref != null) {
                    log("created " + name + " with " + pref.getClass().getSimpleName());
                    return pref;
                }
            } catch (Throwable t) {
                log("cannot create " + name + ": " + t);
            }
        }
        return null;
    }

    private static Object instantiate(Class<?> cls, Context ctx) {
        try {
            return cls.getConstructor(Context.class).newInstance(ctx);
        } catch (Throwable ignored) {
        }
        try {
            return cls.getConstructor(Context.class, android.util.AttributeSet.class)
                    .newInstance(ctx, null);
        } catch (Throwable ignored) {
        }
        try {
            return cls.getConstructor(Context.class, android.util.AttributeSet.class, int.class)
                    .newInstance(ctx, null, 0);
        } catch (Throwable ignored) {
        }
        return null;
    }

    private static void openConfig(Context ctx) {
        try {
            Intent i = new Intent();
            i.setClassName("com.dennis.dexpad", CONFIG_ACTIVITY);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            // the mapping page belongs on the display the settings page lives on
            // (the phone screen); without an explicit launch display Android may
            // pick the focused display (the DeX monitor) instead
            int displayId = -1;
            try {
                android.view.Display d = ctx.getDisplay();
                if (d != null) displayId = d.getDisplayId();
            } catch (Throwable ignored) {
            }
            if (displayId >= 0) {
                android.app.ActivityOptions opts = android.app.ActivityOptions.makeBasic();
                opts.setLaunchDisplayId(displayId);
                ctx.startActivity(i, opts.toBundle());
            } else {
                ctx.startActivity(i);
            }
        } catch (Throwable t) {
            log("start config page failed: " + t);
        }
    }

    private static void log(String msg) {
        XposedBridge.log(TAG + msg);
        Log.i("DexPadHook", msg);
    }
}
