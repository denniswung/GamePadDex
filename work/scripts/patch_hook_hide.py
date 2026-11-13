import io
p = r"E:\Dennis\GamePadDex复刻\project\lsp-dexfullscreen\app\src\main\java\com\dennis\dexfs\Hook.java"
s = io.open(p, encoding="utf-8").read()

old = """    /** hide the caption bar whenever the decoration updates itself */
    private static void hookCaptionMethods(Class<?> c, String className) {
        for (Method m : c.getDeclaredMethods()) {
            String mn = m.getName().toLowerCase();
            if (!(mn.contains("caption") || mn.contains("immersive"))) continue;
            try {
                XposedBridge.hookMethod(m, new XC_MethodHook() {
                    @Override
                    protected void afterHookedMethod(MethodHookParam param) {
                        hideCaption(param.thisObject);
                    }
                });
                XposedBridge.log(TAG + "hooked " + className + "#" + m.getName());
            } catch (Throwable t) {
                XposedBridge.log(TAG + "hook failed " + className + "#" + m.getName() + " " + t);
            }
        }
    }"""
assert old in s, "hook block not found"
new = """    /** hide the caption bar whenever the decoration updates itself */
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
    }"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("caption hide forced for maximized tasks")