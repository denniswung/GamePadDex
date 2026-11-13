package com.samsung.android.settings.desktop;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.hardware.display.DisplayManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.RemoteException;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.WindowManagerGlobal;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertController;
import androidx.appcompat.app.AlertDialog;
import androidx.preference.Preference;
import androidx.preference.PreferenceCategory;
import androidx.preference.SecPreference;
import androidx.preference.SecPreferenceUtils;
import com.android.settings.SettingsPreferenceFragment;
import com.android.settings.Utils;
import com.android.settings.accessibility.AccessibilitySettings$$ExternalSyntheticOutline0;
import com.android.settings.search.BaseSearchIndexProvider;
import com.android.settingslib.widget.LayoutPreference;
import com.samsung.android.settings.Rune;
import com.samsung.android.settings.desktop.DisplayListenerManager;
import com.samsung.android.settings.display.SecDisplayUtils;
import com.samsung.android.settings.widget.SecButtonPreference;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/* compiled from: qb/110957944 d218b81248a8bcc842f94f3afaef3669f313020a9b644eaa312da01481f15540 */
/* loaded from: classes4.dex */
public class DexModeSettingsFragment extends SettingsPreferenceFragment implements DisplayListenerManager.DisplayUpdateListener {
    public static final BaseSearchIndexProvider SEARCH_INDEX_DATA_PROVIDER = new BaseSearchIndexProvider(2132214266);
    public PreferenceCategory mBlankPrefCategory3;
    public SecButtonPreference mConnectWirelesslyButtonPref;
    public DexSettingsCustomSwitchPreference mDefaultAudioOutputPref;
    public SecPreference mExternalDisplayPref;
    public SecPreference mKeyboardSettingsPref;
    public SecPreference mMouseTrackpadPref;
    public SecPreference mSpenInputModePref;

    /* compiled from: qb/110957944 d218b81248a8bcc842f94f3afaef3669f313020a9b644eaa312da01481f15540 */
    /* renamed from: com.samsung.android.settings.desktop.DexModeSettingsFragment$2, reason: invalid class name */
    /* loaded from: classes4.dex */
    public final class AnonymousClass2 extends BaseSearchIndexProvider {
        @Override // com.android.settings.search.BaseSearchIndexProvider, com.android.settingslib.search.Indexable$SearchIndexProvider
        public final List getNonIndexableKeys(Context context) {
            List nonIndexableKeys = super.getNonIndexableKeys(context);
            String str = SecDisplayUtils.mProductName;
            if (ExternalDisplayUtils.isDexConnected(context)) {
                if (!Rune.isSupportSpen()) {
                    ((ArrayList) nonIndexableKeys).add("key_dex_mode_spen_input");
                }
                ((ArrayList) nonIndexableKeys).add("key_dex_mode_screen");
                return nonIndexableKeys;
            }
            ArrayList arrayList = (ArrayList) nonIndexableKeys;
            AccessibilitySettings$$ExternalSyntheticOutline0.m(arrayList, "key_dex_mode_spen_input", "key_set_default_audio_output", "key_mouse_and_trackpad", "key_external_display");
            arrayList.add("key_dex_mode_screen");
            return nonIndexableKeys;
        }
    }

    public final Intent getConnectivityActivityIntent() {
        boolean booleanExtra = getIntent().getBooleanExtra("fromTile", false);
        Log.d("DexModeSettingsFragment", "getConnectivityActivityIntent: fromTile" + booleanExtra);
        Intent intent = new Intent("android.intent.action.MAIN");
        intent.putExtra("fromTile", booleanExtra);
        intent.setClassName("com.sec.android.app.launcher", "com.sec.android.desktopmode.activity.connectivity.ConnectivityActivity");
        return intent;
    }

    @Override // com.android.settingslib.core.instrumentation.Instrumentable
    public final int getMetricsCategory() {
        return 7601;
    }

    @Override // com.android.settings.SettingsPreferenceFragment, com.android.settings.core.InstrumentedPreferenceFragment, com.android.settings.core.ObservablePreferenceFragment, com.android.settingslib.preference.PreferenceFragment, androidx.preference.PreferenceFragmentCompat, androidx.fragment.app.Fragment
    public final void onCreate(Bundle bundle) {
        String string;
        LinearLayout linearLayout;
        int i;
        if (getContext() == null) {
            Log.i("DexModeSettingsFragment", "onCreate: context is null");
            return;
        }
        super.onCreate(bundle);
        addPreferencesFromResource(2132214266);
        this.mExternalDisplayPref = (SecPreference) findPreference("key_external_display");
        this.mSpenInputModePref = (SecPreference) findPreference("key_dex_mode_spen_input");
        this.mKeyboardSettingsPref = (SecPreference) findPreference("key_dex_keyboard");
        if (!Rune.isSupportSpen()) {
            removePreference("key_dex_mode_spen_input");
        }
        this.mDefaultAudioOutputPref = (DexSettingsCustomSwitchPreference) findPreference("key_set_default_audio_output");
        this.mMouseTrackpadPref = (SecPreference) findPreference("key_mouse_and_trackpad");
        this.mBlankPrefCategory3 = (PreferenceCategory) findPreference("blank_pref_category_3");
        SecButtonPreference secButtonPreference = new SecButtonPreference(getContext());
        this.mConnectWirelesslyButtonPref = secButtonPreference;
        Context context = secButtonPreference.getContext();
        secButtonPreference.mButtonBackGroundRes = 2131233668;
        secButtonPreference.mButtonTextColor = context.getColor(2131101572);
        secButtonPreference.notifyChanged();
        SecButtonPreference secButtonPreference2 = this.mConnectWirelesslyButtonPref;
        if (Utils.isDesktopWindowing(getContext())) {
            string = getResources().getString(2132020682);
        } else {
            string = getResources().getString(2132019907);
        }
        secButtonPreference2.setButtonText$1(string);
        this.mConnectWirelesslyButtonPref.mOnClickListener = new View.OnClickListener() { // from class: com.samsung.android.settings.desktop.DexModeSettingsFragment.1
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                boolean z;
                boolean z2;
                if (!Utils.isDesktopWindowing(DexModeSettingsFragment.this.getContext())) {
                    BaseSearchIndexProvider baseSearchIndexProvider = DexModeSettingsFragment.SEARCH_INDEX_DATA_PROVIDER;
                    try {
                        z = WindowManagerGlobal.getWindowManagerService().isSafeModeEnabled();
                    } catch (RemoteException unused) {
                        Log.i("DexModeSettingsFragment", "windowManager API exception!!!");
                        z = false;
                    }
                    if (z) {
                        Toast.makeText(DexModeSettingsFragment.this.getContext(), DexModeSettingsFragment.this.getResources().getString(2132029947), 0).show();
                        return;
                    }
                    if (Settings.Global.getInt(DexModeSettingsFragment.this.getContentResolver(), "wifi_on", 0) != 0) {
                        z2 = true;
                    } else {
                        z2 = false;
                    }
                    if (!z2) {
                        final DexModeSettingsFragment dexModeSettingsFragment = DexModeSettingsFragment.this;
                        final AtomicBoolean atomicBoolean = new AtomicBoolean(false);
                        AlertDialog.Builder builder = new AlertDialog.Builder(dexModeSettingsFragment.getActivity());
                        builder.setMessage(2132029953);
                        AlertController.AlertParams alertParams = builder.P;
                        alertParams.mCancelable = true;
                        alertParams.mOnDismissListener = new DialogInterface.OnDismissListener() { // from class: com.samsung.android.settings.desktop.DexModeSettingsFragment$$ExternalSyntheticLambda2
                            @Override // android.content.DialogInterface.OnDismissListener
                            public final void onDismiss(DialogInterface dialogInterface) {
                                AtomicBoolean atomicBoolean2 = atomicBoolean;
                                BaseSearchIndexProvider baseSearchIndexProvider2 = DexModeSettingsFragment.SEARCH_INDEX_DATA_PROVIDER;
                                if (!atomicBoolean2.get()) {
                                    dialogInterface.dismiss();
                                }
                            }
                        };
                        builder.setPositiveButton(2132031775, new DialogInterface.OnClickListener() { // from class: com.samsung.android.settings.desktop.DexModeSettingsFragment$$ExternalSyntheticLambda3
                            @Override // android.content.DialogInterface.OnClickListener
                            public final void onClick(DialogInterface dialogInterface, int i2) {
                                DexModeSettingsFragment dexModeSettingsFragment2 = DexModeSettingsFragment.this;
                                AtomicBoolean atomicBoolean2 = atomicBoolean;
                                BaseSearchIndexProvider baseSearchIndexProvider2 = DexModeSettingsFragment.SEARCH_INDEX_DATA_PROVIDER;
                                atomicBoolean2.set(true);
                                try {
                                    dexModeSettingsFragment2.getContext().startActivity(dexModeSettingsFragment2.getConnectivityActivityIntent());
                                } catch (ActivityNotFoundException e) {
                                    e.printStackTrace();
                                }
                            }
                        });
                        AlertDialog create = builder.create();
                        create.setCanceledOnTouchOutside(true);
                        create.show();
                        return;
                    }
                    DexModeSettingsFragment dexModeSettingsFragment2 = DexModeSettingsFragment.this;
                    try {
                        dexModeSettingsFragment2.getContext().startActivity(dexModeSettingsFragment2.getConnectivityActivityIntent());
                        return;
                    } catch (ActivityNotFoundException e) {
                        e.printStackTrace();
                        return;
                    }
                }
                ((DisplayManager) DexModeSettingsFragment.this.getContext().getSystemService("display")).semDisconnectDevice();
            }
        };
        getPreferenceScreen().addPreference(this.mConnectWirelesslyButtonPref);
        updateAudioOutputPreference();
        this.mDefaultAudioOutputPref.setOnPreferenceChangeListener(new Preference.OnPreferenceChangeListener() { // from class: com.samsung.android.settings.desktop.DexModeSettingsFragment$$ExternalSyntheticLambda0
            @Override // androidx.preference.Preference.OnPreferenceChangeListener
            public final boolean onPreferenceChange(Preference preference, Object obj) {
                BaseSearchIndexProvider baseSearchIndexProvider = DexModeSettingsFragment.SEARCH_INDEX_DATA_PROVIDER;
                DexModeSettingsFragment dexModeSettingsFragment = DexModeSettingsFragment.this;
                if (!ExternalDisplayUtils.isDisplayAudioSupported(dexModeSettingsFragment.getContext())) {
                    dexModeSettingsFragment.mDefaultAudioOutputPref.setChecked(false);
                    return false;
                }
                Settings.Global.putInt(dexModeSettingsFragment.getContentResolver(), "external_display_audio_output", ((Boolean) obj).booleanValue() ? 1 : 0);
                return true;
            }
        });
        updatePreferencesVisibility();
        LayoutPreference layoutPreference = (LayoutPreference) findPreference("dex_help_preview");
        if (layoutPreference != null && (linearLayout = (LinearLayout) layoutPreference.mRootView.findViewById(2131363111)) != null) {
            TextView textView = (TextView) linearLayout.findViewById(2131363112);
            if (Utils.isTablet()) {
                i = 2132020565;
            } else {
                i = 2132020564;
            }
            if (textView != null) {
                textView.setText(getResources().getString(i));
            }
        }
        DisplayListenerManager.getInstance().registerDisplayListener(getContext());
        DisplayListenerManager.getInstance().addListener(this);
    }

    @Override // com.android.settings.SettingsPreferenceFragment, com.android.settings.core.ObservablePreferenceFragment, com.android.settingslib.preference.PreferenceFragment, androidx.fragment.app.Fragment
    public final void onDestroy() {
        super.onDestroy();
        DisplayListenerManager.getInstance().removeListener(this);
        DisplayListenerManager.getInstance().unRegisterDisplayListener();
    }

    @Override // com.samsung.android.settings.desktop.DisplayListenerManager.DisplayUpdateListener
    public final void onDisplayUpdate() {
        new Handler().postDelayed(new Runnable() { // from class: com.samsung.android.settings.desktop.DexModeSettingsFragment$$ExternalSyntheticLambda1
            @Override // java.lang.Runnable
            public final void run() {
                DexModeSettingsFragment dexModeSettingsFragment = DexModeSettingsFragment.this;
                BaseSearchIndexProvider baseSearchIndexProvider = DexModeSettingsFragment.SEARCH_INDEX_DATA_PROVIDER;
                dexModeSettingsFragment.updatePreferencesVisibility();
                dexModeSettingsFragment.updateAudioOutputPreference();
            }
        }, 400L);
    }

    @Override // com.android.settings.SettingsPreferenceFragment, com.android.settings.core.InstrumentedPreferenceFragment, com.android.settings.core.ObservablePreferenceFragment, com.android.settingslib.preference.PreferenceFragment, androidx.fragment.app.Fragment
    public final void onResume() {
        super.onResume();
        updatePreferencesVisibility();
        updateAudioOutputPreference();
    }

    public final void updateAudioOutputPreference() {
        boolean z = false;
        if (!ExternalDisplayUtils.isDisplayAudioSupported(getContext())) {
            this.mDefaultAudioOutputPref.setChecked(false);
            return;
        }
        DexSettingsCustomSwitchPreference dexSettingsCustomSwitchPreference = this.mDefaultAudioOutputPref;
        dexSettingsCustomSwitchPreference.mIsEnabled = true;
        dexSettingsCustomSwitchPreference.notifyChanged();
        DexSettingsCustomSwitchPreference dexSettingsCustomSwitchPreference2 = this.mDefaultAudioOutputPref;
        if (Settings.Global.getInt(getContentResolver(), "external_display_audio_output", 0) == 1) {
            z = true;
        }
        dexSettingsCustomSwitchPreference2.setChecked(z);
    }

    public final void updatePreferencesVisibility() {
        int i;
        boolean z;
        String string;
        if (getContext() != null) {
            boolean isDexConnected = ExternalDisplayUtils.isDexConnected(getContext());
            this.mSpenInputModePref.setEnabled(isDexConnected);
            if (Settings.Global.getInt(getContentResolver(), "SPEN_INPUT_MODE_DEX", 1) == 0) {
                i = 2132024669;
            } else {
                i = 2132023732;
            }
            this.mSpenInputModePref.setSummary(getString(i));
            SecPreferenceUtils.applySummaryColor(this.mSpenInputModePref, true);
            PreferenceCategory preferenceCategory = this.mBlankPrefCategory3;
            if (isDexConnected && ExternalDisplayUtils.isHdmiConnected(getContext())) {
                z = true;
            } else {
                z = false;
            }
            preferenceCategory.setVisible(z);
            this.mExternalDisplayPref.setEnabled(isDexConnected);
            this.mMouseTrackpadPref.setEnabled(isDexConnected);
            SecButtonPreference secButtonPreference = this.mConnectWirelesslyButtonPref;
            if (Utils.isDesktopWindowing(getContext())) {
                string = getResources().getString(2132020682);
            } else {
                string = getResources().getString(2132019907);
            }
            secButtonPreference.setButtonText$1(string);
            this.mConnectWirelesslyButtonPref.setVisible(!ExternalDisplayUtils.isHdmiConnected(getContext()));
            this.mKeyboardSettingsPref.setEnabled(isDexConnected);
            if (isDexConnected && ExternalDisplayUtils.isHdmiConnected(getContext())) {
                this.mDefaultAudioOutputPref.setVisible(true);
                DexSettingsCustomSwitchPreference dexSettingsCustomSwitchPreference = this.mDefaultAudioOutputPref;
                dexSettingsCustomSwitchPreference.mIsEnabled = true;
                dexSettingsCustomSwitchPreference.notifyChanged();
                if (!ExternalDisplayUtils.isDisplayAudioSupported(getContext())) {
                    this.mDefaultAudioOutputPref.mMsg = getResources().getString(2132024190);
                    DexSettingsCustomSwitchPreference dexSettingsCustomSwitchPreference2 = this.mDefaultAudioOutputPref;
                    dexSettingsCustomSwitchPreference2.mIsEnabled = false;
                    dexSettingsCustomSwitchPreference2.notifyChanged();
                    return;
                }
                return;
            }
            this.mDefaultAudioOutputPref.setVisible(false);
        }
    }
}
