package com.pkyul13.gamepadmouse;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.ViewConfiguration;
import androidx.appcompat.widget.AppCompatSeekBar;

/* compiled from: r8-map-id-8c60900aeda595a73b778d06a0c2b0d30b6fd2caefbddc6926c14247c48afd52 */
/* loaded from: classes.dex */
public final class VerticalFriendlySeekBar extends AppCompatSeekBar {

    /* renamed from: o */
    public final int f4208o;

    /* renamed from: p */
    public float f4209p;

    /* renamed from: q */
    public float f4210q;

    /* renamed from: r */
    public boolean f4211r;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public VerticalFriendlySeekBar(Context context) {
        super(context);
        context.getClass();
        this.f4208o = ViewConfiguration.get(getContext()).getScaledTouchSlop();
    }

    /* JADX WARN: Code restructure failed: missing block: B:8:0x0011, code lost:
    
        if (r0 != 3) goto L28;
     */
    @Override // android.widget.AbsSeekBar, android.view.View
    /*
        Code decompiled incorrectly, please refer to instructions dump.
    */
    public final boolean onTouchEvent(MotionEvent motionEvent) {
        motionEvent.getClass();
        int actionMasked = motionEvent.getActionMasked();
        boolean z = false;
        if (actionMasked != 0) {
            if (actionMasked != 1) {
                if (actionMasked == 2) {
                    float abs = Math.abs(motionEvent.getX() - this.f4209p);
                    float abs2 = Math.abs(motionEvent.getY() - this.f4210q);
                    boolean z2 = this.f4211r;
                    if (!z2) {
                        int i = this.f4208o;
                        if (abs > i || abs2 > i) {
                            if (abs <= abs2 * 1.5f) {
                                z = true;
                            }
                            this.f4211r = z;
                            z2 = z;
                        }
                    }
                    if (z2) {
                        return true;
                    }
                }
            }
            if (this.f4211r) {
                this.f4211r = false;
                return true;
            }
        } else {
            this.f4209p = motionEvent.getX();
            this.f4210q = motionEvent.getY();
            this.f4211r = false;
        }
        return super.onTouchEvent(motionEvent);
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public VerticalFriendlySeekBar(Context context, AttributeSet attributeSet) {
        super(context, attributeSet);
        context.getClass();
        this.f4208o = ViewConfiguration.get(getContext()).getScaledTouchSlop();
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public VerticalFriendlySeekBar(Context context, AttributeSet attributeSet, int i) {
        super(context, attributeSet, i);
        context.getClass();
        this.f4208o = ViewConfiguration.get(getContext()).getScaledTouchSlop();
    }
}
