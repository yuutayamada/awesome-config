-- {{{ License
--
-- Awesome configuration, using awesome 3.4.10 -> 3.5.x on Ubuntu 11.10->14.10
--   * Tony N <tony@git-pull.com>
--
-- This work is licensed under the Creative Commons Attribution-Share
-- Alike License: http://creativecommons.org/licenses/by-sa/3.0/
-- based off Adrian C. <anrxc@sysphere.org>'s rc.lua
-- }}}

-- {{{ Libraries
awful = require("awful")
awful.rules = require("awful.rules")
awful.autofocus = require("awful.autofocus")
naughty = require("naughty")
beautiful = require("beautiful")
wibox = require("wibox")

-- User libraries
local vicious = require("vicious") -- ./vicious
local helpers = require("helpers") -- helpers.lua
-- }}}

-- {{{ Default configuration
altkey = "Mod1"
modkey = "Mod4" -- your windows/apple key

terminal = whereis_app('lilyterm') and 'lilyterm' or 'x-terminal-emulator' -- also accepts full path
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

wallpaper_app = "feh" -- if you want to check for app before trying
wallpaper_dir = os.getenv("HOME") .. "/media/pictures/wallpaper" -- wallpaper dir

-- -- taglist numerals
-- --- arabic, chinese, {east|persian}_arabic, roman, thai, random
-- taglist_numbers = "chinese" -- we support arabic (1,2,3...),

cpugraph_enable = true -- Show CPU graph
cputext_format = " $1%" -- %1 average cpu, %[2..] every other thread individually

membar_enable = true -- Show memory bar
memtext_format = " $1%" -- %1 percentage, %2 used %3 total %4 free

date_format = "%a %m/%d/%Y %l:%M%p" -- refer to http://en.wikipedia.org/wiki/Date_(Unix) specifiers

networks = {'eth0'} -- add your devices network interface here netwidget, only shows first one thats up.

-----------------------
-- load personal.lua --
-----------------------
require_safe('personal')

-- Create personal.lua in this same directory to override these defaults


-- }}}

-- {{{ Variable definitions
local wallpaper_cmd = "find " .. wallpaper_dir ..
  " -type f \\( -name '*.jpg' -o -name '*.png' \\) -print0 | " ..
  "shuf -n1 -z | xargs -0 feh --bg-scale --no-fehbg"

local home   = os.getenv("HOME")
local exec   = awful.util.spawn
local sexec  = awful.util.spawn_with_shell

-- Beautiful theme
beautiful.init(awful.util.getdir("config") .. "/themes/zhongguo/zhongguo.lua")

-- Window management layouts
layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  awful.layout.suit.fair,  -- default comment out
  awful.layout.suit.max,
  awful.layout.suit.magnifier,
  awful.layout.suit.floating -- default comment out
}
-- }}}

-- -- {{{ Tags
-- ----------
-- -- Tags --
-- ----------
tags = {
  names  = { "☆", "✍", "☁", "✐", "♪", '✆', '✇', '☺', '✉' },
  layout = { layouts[5], layouts[5], layouts[5], layouts[4], layouts[5],
             layouts[6], layouts[7], layouts[6], layouts[5]
}}

for s = 1, screen.count() do
  -- Each screen has its own tag table.
  tags[s] = awful.tag(tags.names, s, tags.layout)
end

-- {{{ Wibox
--
-- {{{ Widgets configuration
--
-- {{{ Reusable separator
separator = wibox.widget.imagebox()
separator:set_image(beautiful.widget_sep)

spacer = wibox.widget.textbox()
spacer.width = 3
-- }}}

-- {{{ CPU usage

-- cpu icon
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.widget_cpu)

-- check for cpugraph_enable == true in config
if cpugraph_enable then
	-- Initialize widget
	cpugraph  = awful.widget.graph()

	-- Graph properties
	cpugraph:set_width(40):set_height(16)
	cpugraph:set_background_color(beautiful.fg_off_widget)
	cpugraph:set_color({
          type= "linear", from = { 0, 0 }, to = { 0, 20 }, stops = {
            { 0, beautiful.fg_end_widget },
            { 0.5, beautiful.fg_center_widget },
            { 1, beautiful.fg_widget}
         }
	})

	-- Register graph widget
	vicious.register(cpugraph,  vicious.widgets.cpu,      "$1")
end

-- cpu text widget
cpuwidget = wibox.widget.textbox() -- initialize
vicious.register(cpuwidget, vicious.widgets.cpu, cputext_format, 3) -- register

-- temperature
tzswidget = wibox.widget.textbox()
vicious.register(tzswidget, vicious.widgets.thermal,
	function (widget, args)
		if args[1] > 0 then
			tzfound = true
			return " " .. args[1] .. "C°"
		else return ""
		end
	end
	, 19, "thermal_zone0")

-- }}}


-- {{{ Battery state

-- Initialize widget
batwidget = wibox.widget.textbox()
baticon = wibox.widget.imagebox()

-- Register widget
vicious.register(batwidget, vicious.widgets.bat,
	function (widget, args)
		if args[2] == 0 then return ""
		else
			baticon:set_image(beautiful.widget_bat)
			return "<span color='white'>".. args[2] .. "%</span>"
		end
	end, 61, "BAT0"
)
-- }}}


-- {{{ Memory usage

-- icon
memicon = wibox.widget.imagebox()
memicon:set_image(beautiful.widget_mem)

if membar_enable then
	-- Initialize widget
	membar = awful.widget.progressbar()
	-- Pogressbar properties
	membar:set_vertical(true):set_ticks(true)
	membar:set_height(16):set_width(8):set_ticks_size(2)
	membar:set_background_color(beautiful.fg_off_widget)
	membar:set_color({
          type = "linear", from = {0,0}, to= {0, 20},
          stops= {
            { 0, beautiful.fg_widget },
            { 0.5, beautiful.fg_center_widget },
            { 1, beautiful.fg_end_widget }
          }
	}) -- Register widget
	vicious.register(membar, vicious.widgets.mem, "$1", 13)
end

-- mem text output
memtext = wibox.widget.textbox()
vicious.register(memtext, vicious.widgets.mem, memtext_format, 13)
-- }}}

-- {{{ File system usage
fsicon = wibox.widget.imagebox()
fsicon:set_image(beautiful.widget_fs)
-- Initialize widgets
fs = {
  r = awful.widget.progressbar(), s = awful.widget.progressbar()
}
-- Progressbar properties
for _, w in pairs(fs) do
  w:set_vertical(true):set_ticks(true)
  w:set_height(16):set_width(5):set_ticks_size(2)
  w:set_border_color(beautiful.border_widget)
  w:set_background_color(beautiful.fg_off_widget)
  w:set_color({
    type = "linear", from = {0,0}, to= {0, 20},
    stops= {
      { 0, beautiful.fg_widget },
      { 0.5, beautiful.fg_center_widget },
      { 1, beautiful.fg_end_widget }
    }
  }) -- Register buttons
  w:buttons(awful.util.table.join(
    awful.button({ }, 1, function () exec("dolphin", false) end)
  ))
end -- Enable caching
vicious.cache(vicious.widgets.fs)
-- Register widgets
vicious.register(fs.r, vicious.widgets.fs, "${/ used_p}",            599)
vicious.register(fs.s, vicious.widgets.fs, "${/media/files used_p}", 599)
-- }}}

-- {{{ Network usage
function print_net(name, down, up)
  return '<span color="'
    .. beautiful.fg_netdn_widget ..'">' .. down .. '</span> <span color="'
    .. beautiful.fg_netup_widget ..'">' .. up  .. '</span>'
end

dnicon = wibox.widget.imagebox()
upicon = wibox.widget.imagebox()

-- Initialize widget
netwidget = wibox.widget.textbox()
-- Register widget
vicious.register(netwidget, vicious.widgets.net,
                 function (widget, args)
                   for _, device in pairs(networks) do
                     local n = tonumber(args["{".. device .." carrier}"])
                     if n ~= nil and n > 0 then
                       netwidget.found = true
                       dnicon:set_image(beautiful.widget_net)
                       upicon:set_image(beautiful.widget_netup)
                       return print_net(device,
                                        args["{"..device.." down_kb}"],
                                        args["{"..device.." up_kb}"])
                     end
                   end
                 end, 3)
-- }}}

-- {{{ Volume level
volicon = wibox.widget.imagebox()
volicon:set_image(beautiful.widget_vol)
-- Initialize widgets
volbar    = awful.widget.progressbar()
volwidget = wibox.widget.textbox()
-- Progressbar properties
volbar:set_vertical(true):set_ticks(true)
volbar:set_height(16):set_width(8):set_ticks_size(2)
volbar:set_background_color(beautiful.fg_off_widget)
volbar:set_color({
  type= "linear", from = { 0, 0 }, to = { 0, 20 }, stops = {
    { 0, beautiful.fg_end_widget },
    { 0.5, beautiful.fg_center_widget },
    { 1, beautiful.fg_widget}
  }
}) -- Enable caching

vicious.cache(vicious.widgets.volume)
-- Register widgets
vicious.register(volbar,    vicious.widgets.volume,  "$1",  2, "PCM")
vicious.register(volwidget, vicious.widgets.volume, " $1%", 2, "PCM")
-- Register buttons
volbar:buttons(awful.util.table.join(
   awful.button({ }, 1, function () exec("kmix") end),
   awful.button({ }, 4, function () exec("amixer -q set PCM 2dB+", false) vicious.force({volbar, volwidget}) end),
   awful.button({ }, 5, function () exec("amixer -q set PCM 2dB-", false) vicious.force({volbar, volwidget}) end)
)) -- Register assigned buttons
volwidget:buttons(volbar:buttons())
-- }}}

-- {{{ Date and time
dateicon = wibox.widget.imagebox()
dateicon:set_image(beautiful.widget_date)
-- Initialize widget
datewidget = wibox.widget.textbox()
-- Register widget
vicious.register(datewidget, vicious.widgets.date, date_format, 61)
-- }}}

-- {{{ mpd
mpdwidget = wibox.widget.textbox()
if whereis_app('curl') and whereis_app('mpd') then
	vicious.register(mpdwidget, vicious.widgets.mpd,
		function (widget, args)
			if args["{state}"] == "Stop" or args["{state}"] == "Pause" or args["{state}"] == "N/A"
      or (args["{Artist}"] == "N/A" and args["{Title}"] == "N/A") then return ""
			else return '<span color="white">музыка:</span> '..
          args["{Artist}"]..' - '.. args["{Title}"]
			end
		end
	)
end

-- }}}


-- {{{ System tray
systray = wibox.widget.systray()
-- }}}
-- }}}

-- {{{ Wibox initialisation
mywibox     = {}
mypromptbox = {}
layoutbox = {}
taglist   = {}
taglist.buttons = awful.util.table.join(
    awful.button({ },        1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ },        3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ },        4, awful.tag.viewnext),
    awful.button({ },        5, awful.tag.viewprev
))


for s = 1, screen.count() do
    -- Create a promptbox
    mypromptbox[s] = awful.widget.prompt()
    -- Create a layoutbox
    layoutbox[s] = awful.widget.layoutbox(s)
    layoutbox[s]:buttons(awful.util.table.join(
        awful.button({ }, 1, function () awful.layout.inc(layouts,  1) end),
        awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function () awful.layout.inc(layouts,  1) end),
        awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
    ))

    -- Create the taglist
    taglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist.buttons)
    -- Create the wibox
    mywibox[s] = awful.wibox({      screen = s,
        fg = beautiful.fg_normal, height = 16,
        bg = beautiful.bg_normal, position = "top",
        border_color = beautiful.border_normal,
        border_width = beautiful.border_width
    })
    -- Add widgets to the wibox
    mywibox[s].widgets = {
        {   taglist[s], layoutbox[s], separator,
            mpdwidget and spacer, mpdwidget or nil,
        },
        --s == screen.count() and systray or nil, -- show tray on last screen
        s == 1 and systray or nil, -- only show tray on first screen
        s == 1 and separator or nil, -- only show on first screen
        datewidget, dateicon,
        baticon.image and separator, batwidget, baticon or nil,
        separator, volwidget,  volbar.widget, volicon,
        dnicon.image and separator, upicon, netwidget, dnicon or nil,
        separator, fs.r.widget, fs.s.widget, fsicon,
        separator, memtext, membar_enable and membar.widget or nil, memicon,
        separator, tzfound and tzswidget or nil,
        cpugraph_enable and cpugraph.widget or nil, cpuwidget, cpuicon,
    }



  local left_layout = wibox.layout.fixed.horizontal()
  left_layout:fill_space(true)
  left_layout:add(taglist[s])
  left_layout:add(mypromptbox[s])

  local middle_layout = wibox.layout.fixed.horizontal()
  middle_layout:add(mpdwidget and spacer, mpdwidget or nil)


  local right_layout = wibox.layout.fixed.horizontal()

  if cpugraph_enable and cpugraph then
    if separator then right_layout:add(separator) end
    right_layout:add(cpuicon)
    right_layout:add(cpuwidget)
    right_layout:add(cpugraph)
  end

  if tzfound and tzwidth then
    if separator then right_layout:add(separator) end
    right_layout:add(tzfound)
    right_layout:add(tzswidget)
  end


  if membar_enable and memtext and membar then
    if separator then right_layout:add(separator) end
    right_layout:add(memicon)
    right_layout:add(memtext)
    right_layout:add(membar)
  end


  if fs.r and fs.s and fsicon then
    if separator then right_layout:add(separator) end
    right_layout:add(fsicon)
    right_layout:add(fs.r)
    right_layout:add(fs.s)
  end


  if dnicon and upicon and netwidget then
    if separator then right_layout:add(separator) end
    right_layout:add(dnicon)
    right_layout:add(netwidget)
    right_layout:add(upicon)
  end


  if volwidget and volbar then
    if separator then right_layout:add(separator) end
    right_layout:add(volicon)
    right_layout:add(volbar)
    right_layout:add(volwidget)
  end


  if baticon and batwidget then
    if separator then right_layout:add(separator) end
    right_layout:add(baticon)
    right_layout:add(batwidget)
  end

  if separator then right_layout:add(separator) end
  right_layout:add(dateicon)
  right_layout:add(datewidget)

  if s == 1 then
    if separator then right_layout:add(separator) end
    right_layout:add(s == 1 and systray or nil)
  end


  local layout = wibox.layout.align.horizontal()
  layout:set_left(left_layout)
  layout:set_middle(middle_layout)
  layout:set_right(right_layout)
  mywibox[s]:set_widget(layout)



end
-- }}}
-- }}}


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- Client bindings
clientbuttons = awful.util.table.join(
    awful.button({ },        1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
-- }}}


-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j", function ()
        awful.client.focus.byidx( 1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "k", function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "w", function ()
        mymainmenu:show({keygrabber=true})
    end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function ()
        awful.client.swap.byidx(  1)
    end),
    awful.key({ modkey, "Shift"   }, "k", function ()
        awful.client.swap.byidx( -1)
    end),
    awful.key({ modkey, "Control" }, "j", function ()
        awful.screen.focus_relative( 1)
    end),
    awful.key({ modkey, "Control" }, "k", function ()
        awful.screen.focus_relative(-1)
    end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab", function ()
        awful.client.focus.history.previous()
        if client.focus then
          client.focus:raise()
        end
    end),

    -- Standard program
    awful.key({ modkey, "Shift"   }, "Return", function ()
        awful.util.spawn(terminal)
    end),
    awful.key({ modkey, "Control"   }, "t", function ()
        awful.util.spawn(terminal)
    end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey,           }, ",",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey,           }, ".",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey }, "b", function ()
         wibox[mouse.screen].visible = not wibox[mouse.screen].visible
    end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "t",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Shift" }, "t", function (c)
        if   c.titlebar then awful.titlebar.remove(c)
           else awful.titlebar.add(c, { modkey = modkey }) end
    end),
    awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}


-- {{{ Rules
awful.rules.rules = {
    { rule = { }, properties = {
      focus = true,      size_hints_honor = false,
      keys = clientkeys, buttons = clientbuttons,
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal }
    },
    { rule = { class = "Emacs" },
    properties = { tag = tags[1][2], opacity = 0.7 } },
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][3], opacity = 0.8 } },
    { rule = { class = "Gimp" },
      properties = { tag = tags[1][4], floating = true} },
    { rule = { class = "Mplayer" },
      properties = { tag = tags[1][5], floating = true} },
    { rule = { class = "Skype" },
      properties = { tag = tags[1][6], floating = true, opacity = 0.7 } },
    { rule = { class = "ROX-Filer" },   properties = { floating = true } },
    { rule = { class = "Chromium-browser" },   properties = { floating = false } },
    { rule = { class = "Google-chrome" },   properties = { floating = false } },
}
-- }}}


-- {{{ Signals
--
-- {{{ Manage signal handler
client.connect_signal("manage", function (c, startup)
    -- Add titlebar to floaters, but remove those from rule callback
    if awful.client.floating.get(c)
    or awful.layout.get(c.screen) == awful.layout.suit.floating then
        if   c.titlebar then awful.titlebar.remove(c)
        else awful.titlebar.add(c, {modkey = modkey}) end
    end

    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function (c)
        if  awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    -- Client placement
    if not startup then
        awful.client.setslave(c)

        if  not c.size_hints.program_position
        and not c.size_hints.user_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)
-- }}}

-- {{{ Focus signal handlers
client.connect_signal("focus",   function (c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function (c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
    local clients = awful.client.visible(s)
    local layout = awful.layout.getname(awful.layout.get(s))

    for _, c in pairs(clients) do -- Floaters are always on top
        if   awful.client.floating.get(c) or layout == "floating"
        then if not c.fullscreen then c.above       =  true  end
        else                          c.above       =  false end
    end
  end)
end
-- }}}
-- }}}

-----------------------
-- change background --
-----------------------
if whereis_app('feh') then
  mytimer = timer { timeout = 0 }
  mytimer:connect_signal("timeout",
                         function()
                           -- tell awsetbg to randomly choose a wallpaper from your wallpaper directory
                           if file_exists(wallpaper_dir) then
                             os.execute(wallpaper_cmd)
                           end
                           -- stop the timer (we don't need multiple instances running at the same time)
                           mytimer:stop()
                           -- define the interval in which the next wallpaper change should occur in seconds
                           -- (in this case anytime between 10 and 20 minutes)
                           x = math.random(600, 1200)
                           --restart the timer
                           mytimer.timeout = x
                           mytimer:start()
                         end)
  -- initial start when rc.lua is first run
  mytimer:start()
end

require_safe('autorun')
