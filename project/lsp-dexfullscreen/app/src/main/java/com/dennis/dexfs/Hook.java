package com.dennis.dexfs;

import android.view.View;

import java.lang.reflect.Method;
import java.util.List;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * DeX fullscreen helper.
 *
 * The DeX caption ("Caption of Task=N") is a WM Shell window. Its "fullscreen"
 * button asks DesktopImmersiveController to put the task into immersive mode, but
 * on this build that transition aborts ("missing immersive change"). The task
 * bounds already cover the whole display after "am task resize", so hiding the
 * caption view is enough to get a real fullscreen.
 *
 * The module first *discovers* what exists in the current One UI build and logs
 * it, then installs whatever hooks it found.
 */
public class Hook implements IXposedHookLoadPackage {

    private static final String TAG = "[dexfs] ";
    private static boolean done = false;

    private static final String[] DECOR_CLASSES = {
            "com.android.wm.shell.windowdecor.WindowDecoration",
            "com.android.wm.shell.windowdecor.DesktopModeWindowDecorViewModel",
            "com.android.wm.shell.windowdecor.WindowDecorView",
            "com.android.wm.shell.windowdecor.DesktopModeWindowDecorView",
    };

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lp) {
        if (done) return;
        // WM Shell (windowdecor / desktopmode) lives inside SystemUI on Android 12+
        String pkg = lp.packageName;
        if (!"android".equals(pkg) && !"com.android.systemui".equals(pkg)) return;
        done = true;
        XposedBridge.log(TAG + "loaded in " + lp.packageName);

        for (String name : DECOR_CLASSES) {
            Class<?> c = null;
            try {
                c = XposedHelpers.findClass(name, lp.classLoader);
            } catch (Throwable ignored) {
            }
            if (c == null) {
                XposedBridge.log(TAG + "missing class " + name);
                continue;
            }
            XposedBridge.log(TAG + "found " + name);
            for (Method m : c.getDeclaredMethods()) {
                String mn = m.getName().toLowerCase();
                if (mn.contains("caption") || mn.contains("immersive") || mn.contains("decor")) {
                    XposedBridge.log(TAG + "  method " + m.getName() + "(" + m.getParameterCount() + " args)");
                }
            }
            hookCaptionMethods(c, name);
            hideExistingInstances(c);
        }
    }

    /** hide the caption bar whenever the decoration updates itself */
    private static void hookCaptionMethods(Class<?> c, String className) {
        for (Method m : c.getDeclaredMethods()) {
            String mn = m.getName().toLowerCase();
            if (!(mn.contains("caption") || mn.contains("immersive"))) continue;
            final String name = m.getName();
            try {
                XposedBridge.hookMethod(m, new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        // a maximized window needs no caption: force it hidden
                        if ("setcaptionvisibility".equals(name.toLowerCase())) {
                            boolean max = isMaximized(param.thisObject);
                            XposedBridge.log(TAG + "setCaptionVisibility task-max=" + max);
                            if (max && param.args.length > 0) {
                                param.args[0] = false;
                            }
                        }
                    }

                    @Override
                    protected void afterHookedMethod(MethodHookParam param) {
                        if (isMaximized(param.thisObject)) hideCaption(param.thisObject);
                    }
                });
                XposedBridge.log(TAG + "hooked " + className + "#" + name);
            } catch (Throwable t) {
                XposedBridge.log(TAG + "hook failed " + className + "#" + name + " " + t);
            }
        }
    }

    /** true when the decorated task fills the (DeX) display */
    private static boolean isMaximized(Object decoration) {
        try {
            Object ti = XposedHelpers.getObjectField(decoration, "mTaskInfo");
            Object bounds = XposedHelpers.getObjectField(ti, "bounds");
            if (bounds instanceof android.graphics.Rect) {
                android.graphics.Rect r = (android.graphics.Rect) bounds;
                return r.width() >= 2000 && r.height() >= 1400;
            }
        } catch (Throwable ignored) {
        }
        try {
            Object b = XposedHelpers.getObjectField(decoration, "mWindowBounds");
            if (b instanceof android.graphics.Rect) {
                android.graphics.Rect r = (android.graphics.Rect) b;
                return r.width() >= 2000 && r.height() >= 1400;
            }
        } catch (Throwable ignored) {
        }
        return false;
    }

    private static void hideExistingInstances(Class<?> c) {
        // nothing to iterate here: instances are hidden as soon as they update
    }

    private static void hideCaption(Object decoration) {
        if (decoration == null) return;
        for (String field : new String[]{"mCaptionView", "mCaption", "mWindowDecorView", "mDecorView"}) {
            Object v = null;
            try {
                v = XposedHelpers.getObjectField(decoration, field);
            } catch (Throwable ignored) {
            }
            if (v instanceof View) {
                try {
                    ((View) v).setVisibility(View.INVISIBLE);
                    XposedBridge.log(TAG + "hid " + field + " of " + decoration.getClass().getSimpleName());
                } catch (Throwable ignored) {
                }
            }
        }
        // also try the view tree: the caption row is a clickable strip at the top
        Object root = null;
        try {
            root = XposedHelpers.getObjectField(decoration, "mWindowDecorView");
        } catch (Throwable ignored) {
        }
        if (root instanceof View) {
            hideTopStrip((View) root);
        }
    }

    private static void hideTopStrip(View v) {
        try {
            if (v instanceof android.view.ViewGroup) {
                android.view.ViewGroup g = (android.view.ViewGroup) v;
                for (int i = 0; i < g.getChildCount(); i++) {
                    View child = g.getChildAt(i);
                    if (child != null && child.getClass().getName().toLowerCase().contains("caption")) {
                        child.setVisibility(View.INVISIBLE);
                        XposedBridge.log(TAG + "hid caption child " + child.getClass().getName());
                    }
                }
            }
        } catch (Throwable ignored) {
        }
    }
}
