import io, os

root = r"E:\Dennis\GamePadDex复刻\project\lsp-dexfullscreen"
os.makedirs(os.path.join(root, "src", "main", "java", "com", "dennis", "dexfs"), exist_ok=True)
os.makedirs(os.path.join(root, "src", "main", "assets"), exist_ok=True)

GRADLE = """plugins {
    id("com.android.application")
}

android {
    namespace = "com.dennis.dexfs"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.dennis.dexfs"
        minSdk = 32
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    compileOnly("de.robv.android.xposed:api:82")
    compileOnly("de.robv.android.xposed:api:82:sources")
}
"""

SETTINGS = """pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://api.xposed.info/") }
    }
}
rootProject.name = "lsp-dexfullscreen"
include(":app")
"""

# The module lives in app/ so the above settings + an app/build.gradle are used
os.makedirs(os.path.join(root, "app", "src", "main", "java", "com", "dennis", "dexfs"), exist_ok=True)
os.makedirs(os.path.join(root, "app", "src", "main", "assets"), exist_ok=True)

MANIFEST = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="false"
        android:label="DeX Fullscreen"
        android:supportsRtl="true">

        <meta-data
            android:name="xposedmodule"
            android:value="true" />
        <meta-data
            android:name="xposeddescription"
            android:value="Hide the DeX window caption (title bar) so the app really fills the screen" />
        <meta-data
            android:name="xposedminversion"
            android:value="93" />
        <meta-data
            android:name="xposedscope"
            android:resource="@array/xposed_scope" />
    </application>

</manifest>
"""

STRINGS = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="xposed_scope">
        <item>com.android.systemui</item>
        <item>com.example.piliplus</item>
    </string-array>
</resources>
"""

XPOSED_INIT = """com.dennis.dexfs.Hook
"""

HOOK = """package com.dennis.dexfs;

import android.view.View;
import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * The DeX caption ("Caption of Task=N") is a WM Shell window. Its "fullscreen"
 * button normally switches the task into immersive mode, but on this build the
 * transition aborts with "missing immersive change". Since the task bounds are
 * already the whole display, hiding the caption view gives a real fullscreen
 * without touching the window transaction pipeline.
 *
 * Hook points (WM Shell, inside the system_server process):
 *   com.android.wm.shell.windowdecor.WindowDecoration#addCaption / setCaptionVisible
 *   com.android.wm.shell.windowdecor.DesktopModeWindowDecorViewModel#onDisplayChange
 * We search the decor view tree for the caption buttons and hide the parent bar.
 */
public class Hook implements IXposedHookLoadPackage {

    private static final String WM_SHELL = "com.android.wm.shell";
    private static boolean installed = false;

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lp) {
        String pkg = lp.packageName;
        // WM Shell is not a package: it loads inside system_server ("android")
        if (!"android".equals(pkg) && !WM_SHELL.equals(pkg)) return;
        if (installed) return;
        installed = true;
        XposedBridge.log("[dexfs] loading in " + pkg);

        // 1) after a caption view is attached, walk it and hide the title bar row
        try {
            XposedHelpers.findAndHookMethod(
                    "com.android.wm.shell.windowdecor.WindowDecoration",
                    lp.classLoader, "onContextualEntryChanged",
                    new XC_MethodHook() {
                        @Override
                        protected void afterHookedMethod(MethodHookParam param) {
                            hideCaption(param.thisObject);
                        }
                    });
        } catch (Throwable t) {
            XposedBridge.log("[dexfs] WindowDecoration hook failed: " + t);
        }

        // 2) the decor view model drives caption visibility on task changes
        try {
            XposedHelpers.findAndHookMethod(
                    "com.android.wm.shell.windowdecor.DesktopModeWindowDecorViewModel",
                    lp.classLoader, "onTaskInfoChanged",
                    "android.app.TaskInfo",
                    new XC_MethodHook() {
                        @Override
                        protected void afterHookedMethod(MethodHookParam param) {
                            Object model = param.thisObject;
                            XposedBridge.log("[dexfs] onTaskInfoChanged " + param.args[0]);
                            hideAllCaptions(model);
                        }
                    });
        } catch (Throwable t) {
            XposedBridge.log("[dexfs] DesktopModeWindowDecorViewModel hook failed: " + t);
        }
    }

    private static void hideAllCaptions(Object model) {
        try {
            Object decor = XposedHelpers.getObjectField(model, "mWindowDecorByTaskId");
            if (!(decor instanceof java.util.Map)) return;
            for (Object v : ((java.util.Map<?, ?>) decor).values()) {
                hideCaption(v);
            }
        } catch (Throwable ignored) {
        }
    }

    private static void hideCaption(Object decoration) {
        try {
            Object view = XposedHelpers.getObjectField(decoration, "mDecorView");
            if (view instanceof View) {
                View v = (View) view;
                // the caption bar is the first child of the decor container
                Object caption = XposedHelpers.getObjectField(decoration, "mCaptionView");
                if (caption instanceof View) {
                    ((View) caption).setVisibility(View.INVISIBLE);
                    XposedBridge.log("[dexfs] caption hidden");
                }
            }
        } catch (Throwable ignored) {
        }
    }
}
"""

files = {
    os.path.join(root, "settings.gradle.kts"): SETTINGS,
    os.path.join(root, "build.gradle.kts"): """plugins {
    id("com.android.application") version "9.3.1" apply false
}
""",
    os.path.join(root, "app", "build.gradle.kts"): GRADLE,
    os.path.join(root, "app", "src", "main", "AndroidManifest.xml"): MANIFEST,
    os.path.join(root, "app", "src", "main", "res", "values", "strings.xml"): STRINGS,
    os.path.join(root, "app", "src", "main", "assets", "xposed_init"): XPOSED_INIT,
    os.path.join(root, "app", "src", "main", "java", "com", "dennis", "dexfs", "Hook.java"): HOOK,
}
os.makedirs(os.path.join(root, "app", "src", "main", "res", "values"), exist_ok=True)
for p, c in files.items():
    io.open(p, "w", encoding="utf-8", newline="\n").write(c)
print("module skeleton written to", root)
