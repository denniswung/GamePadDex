import io
p = r"E:\Dennis\GamePadDex复刻\project\tools\injector\ScrollInject.java"
s = io.open(p, encoding="utf-8").read()
if "private static void click(" not in s:
    s = s.replace("    private static void keyCombo(", '''    /** mouse click at (x,y) on a display */
    private static void click(int displayId, float x, float y, int button) {
        long now = SystemClock.uptimeMillis();
        for (int action : new int[]{MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP}) {
            MotionEvent.PointerProperties props = new MotionEvent.PointerProperties();
            props.id = 0;
            props.toolType = MotionEvent.TOOL_TYPE_MOUSE;
            MotionEvent.PointerCoords coords = new MotionEvent.PointerCoords();
            coords.x = x;
            coords.y = y;
            MotionEvent ev = MotionEvent.obtain(now, now, action, 1,
                    new MotionEvent.PointerProperties[]{props},
                    new MotionEvent.PointerCoords[]{coords},
                    button, 0, 1.0f, 1.0f, 0, 0, InputDevice.SOURCE_MOUSE, 0);
            try {
                MotionEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
            } catch (Throwable ignored) {}
            try {
                inject.invoke(im, ev, 1);
                System.err.println("click " + x + "," + y + " disp=" + displayId + " action=" + action);
            } catch (Throwable t) {
                System.err.println("click inject failed: " + t);
            } finally {
                ev.recycle();
            }
        }
    }

    private static void keyCombo(''', 1)
    s = s.replace('''            if (line.startsWith("c ")) {''', '''            if (line.startsWith("m ")) {
                // m <displayId> <x> <y> [button]
                String[] mp = line.split("\\\\s+");
                if (mp.length >= 4) click(Integer.parseInt(mp[1]), Float.parseFloat(mp[2]),
                        Float.parseFloat(mp[3]), mp.length > 4 ? Integer.parseInt(mp[4]) : 1);
                continue;
            }
            if (line.startsWith("c ")) {''', 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("injector click command added")