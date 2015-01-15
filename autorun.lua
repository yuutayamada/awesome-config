run_once("nm-applet") -- networking
run_once(os.getenv("HOME") .. "/.dropbox-dist/dropboxd") -- Dropbox
run_once("xsetroot", "-cursor_name left_ptr")  -- sets the cursor icon
run_once("redshift", "-o -l 0:0 -b 0.8 -t 6500:6500") -- brightness
run_once("ibus-daemon", "--xim") -- ibus
