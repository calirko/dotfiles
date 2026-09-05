-- vars

local f = io.open("/etc/hostname", "r")
local hostname = f:read("*a"):gsub("%s+", "")
f:close()

local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "wofi --style ~/.config/wofi/style.css --allow-images --show drun"
local browser     = "zen-browser"
local ide         = "zeditor"
local kbLayout    = hostname == "shark" and "br" or "us"

-- functions

-- actual code

if hostname == "raccoon" then
    hl.monitor({
        output   = "desc:Samsung Electric Company LF24T35 HX5X803123",
        mode     = "1920x1080@74.97",
        position = "0x0",
        scale    = "1",
    })

    hl.monitor({
        output    = "desc:Samsung Electric Company LF24T35 HX5X802342",
        mode      = "1920x1080@74.97",
        position  = "1920x-180",
        scale     = "1",
        transform = 3,
    })

    hl.monitor({
        output   = "desc:BOE 0x0A2A",
        mode     = "1920x1200@60",
        position = "-1920x0",
        scale    = "1.2",
    })

    -- Lid switch handling, native (no polling daemon).
    --
    -- Plugged in + external monitor : lid close disables eDP-1, lid open re-enables it
    -- Plugged in + no external      : lid close suspends
    -- On battery (any)              : lid close suspends; timeout suspend is handled by hypridle
    --
    -- This runs synchronously as part of config evaluation, right after the
    -- monitor specs above, so a boot-with-lid-closed never lets eDP-1 come up
    -- enabled and grab the default workspace before we get a chance to turn
    -- it off -- that race is what used to strand the session behind a closed
    -- lid with no way to reach the other monitors. Switch bindings below
    -- handle the same logic on live lid events.
    local EDP_NAME  = "eDP-1"
    local EDP_MODE  = "1920x1200@60"
    local EDP_POS   = "-1920x0"
    local EDP_SCALE = "1.2"

    local function read_file(path)
        local fh = io.open(path, "r")
        if not fh then return nil end
        local content = fh:read("*a")
        fh:close()
        return content
    end

    local function lid_closed()
        for _, path in ipairs({
            "/proc/acpi/button/lid/LID0/state",
            "/proc/acpi/button/lid/LID1/state",
            "/proc/acpi/button/lid/LID/state",
        }) do
            local content = read_file(path)
            if content then return content:find("closed") ~= nil end
        end
        return false
    end

    local function on_ac()
        for _, path in ipairs({
            "/sys/class/power_supply/AC/online",
            "/sys/class/power_supply/AC0/online",
            "/sys/class/power_supply/ADP0/online",
            "/sys/class/power_supply/ADP1/online",
        }) do
            local content = read_file(path)
            if content then return content:find("1") ~= nil end
        end
        return false
    end

    local function external_monitor_connected()
        for _, m in ipairs(hl.get_monitors()) do
            if m.name ~= EDP_NAME then return true end
        end
        return false
    end

    local function reopen_bar()
        hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/bar.sh"))
    end

    local function handle_lid_close()
        if on_ac() and external_monitor_connected() then
            hl.monitor({ output = EDP_NAME, disabled = true })
            reopen_bar()
        else
            hl.dispatch(hl.dsp.exec_cmd("systemctl suspend"))
        end
    end

    local function handle_lid_open()
        hl.monitor({
            output   = EDP_NAME,
            disabled = false,
            mode     = EDP_MODE,
            position = EDP_POS,
            scale    = EDP_SCALE,
        })
        reopen_bar()
    end

    -- Apply current lid state immediately (handles boot-with-lid-closed).
    if lid_closed() then
        handle_lid_close()
    end

    hl.bind("switch:on:Lid Switch", handle_lid_close, { locked = true })
    hl.bind("switch:off:Lid Switch", handle_lid_open, { locked = true })

    -- Workspaces 1-8 are statically bound to the external monitors. That
    -- binding holds even while those monitors are disconnected, so on a
    -- laptop-only boot (no DP-1/HDMI-A-1) Hyprland can't place anything on
    -- 1-8 and falls through to the next free id (observed: workspace 9).
    -- Give eDP-1 its own bound range only when no external monitor is
    -- present, so a laptop-only session starts on workspace 1 instead.
    if external_monitor_connected() then
        hl.workspace_rule({ monitor = "DP-1", workspace = "1", default = true })
        hl.workspace_rule({ monitor = "DP-1", workspace = "2" })
        hl.workspace_rule({ monitor = "DP-1", workspace = "3" })
        hl.workspace_rule({ monitor = "DP-1", workspace = "4" })
        hl.workspace_rule({ monitor = "HDMI-A-1", workspace = "5", default = true })
        hl.workspace_rule({ monitor = "HDMI-A-1", workspace = "6" })
        hl.workspace_rule({ monitor = "HDMI-A-1", workspace = "7" })
        hl.workspace_rule({ monitor = "HDMI-A-1", workspace = "8" })
    else
        hl.workspace_rule({ monitor = "eDP-1", workspace = "1", default = true })
        hl.workspace_rule({ monitor = "eDP-1", workspace = "2" })
        hl.workspace_rule({ monitor = "eDP-1", workspace = "3" })
        hl.workspace_rule({ monitor = "eDP-1", workspace = "4" })
    end


    hl.config({
        input = {
            touchpad = {
                natural_scroll = false,
                tap_to_click = true,
            },
        },
    })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace",
    })

    hl.gesture({
        fingers = 4,
        direction = "down",
        action = function()
            hl.dispatch(hl.dsp.exec_cmd(terminal))
        end,
    })

    hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/kbd-backlight-notify.sh up"),
        { repeating = true })
    hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/kbd-backlight-notify.sh down"),
        { repeating = true })
    hl.on("hyprland.start", function()
        hl.dispatch(hl.dsp.exec_cmd("nmcli connection up peer_dragon_1"))
    end)
    hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")
elseif hostname == "shark" then
    hl.monitor({
        output   = "desc:AOC 22B1WG5 AUWMAXA004846",
        mode     = "1920x1080@75",
        position = "0x0",
        scale    = "1",
    })

    hl.workspace_rule({
        monitor = "HDMI-A-1",
        workspace = "1",
        default = true,
    })

    hl.workspace_rule({
        monitor = "HDMI-A-1",
        workspace = "2",
    })

    hl.config({
        input = {
            numlock_by_default = true,
        },
    })
end


-- Reopen the bar whenever a monitor is physically connected or disconnected.
-- Lid-close/open (software disable) is handled by the native switch bindings
-- in the raccoon block above.
hl.on("monitor.added", function()
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/bar.sh"))
end)

hl.on("monitor.removed", function()
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/bar.sh"))
end)

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'Geist Font Mono 11'"))
    hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Geist Font 11'"))
    hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"))
    hl.dispatch(hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'"))
    hl.dispatch(hl.dsp.exec_cmd("gnome-keyring-daemon --start --components=secrets"))
    hl.dispatch(hl.dsp.exec_cmd("systemctl --user start hyprpolkitagent"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/wallpaper-default.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/bar.sh"))
    hl.dispatch(hl.dsp.exec_cmd("hypridle"))
    hl.dispatch(hl.dsp.exec_cmd("easyeffects --gapplication-service"))
    hl.dispatch(hl.dsp.exec_cmd("wl-paste --type text --watch cliphist store"))
    hl.dispatch(hl.dsp.exec_cmd("wl-paste --type image --watch cliphist store"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/network-notify.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/vpn-notify.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/bluetooth-notify.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/power-tweaks.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/scripts/battery-notify.sh"))
    hl.dispatch(hl.dsp.exec_cmd("/home/calirko/.config/hypr/media-rpc"))
end)


hl.env("GNOME_KEYRING_CONTROL", "/run/user/1000/keyring")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland")
hl.env("ADW_DISABLE_PORTAL", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("HYPRSHOT_DIR", "/home/calirko/Pictures/Screenshots")
hl.env("GTK_FONT_NAME", "Geist Font 11")
hl.env("GTK_THEME", "adw-gtk3-dark")


hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 6,
        border_size = 0,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",

    },

    decoration = {
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = true,
        },
        inactive_opacity = 0.95,
        dim_inactive = true,
        dim_strength = 0.1,
        rounding = 8,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        font_family = "Geist Font",
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },

    input = {
        kb_layout = kbLayout,
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = 0,
    },
})


hl.curve("snappy", { type = "bezier", points = { { 0.18, 1 }, { 0.18, 1 } } })
hl.curve("instant", { type = "bezier", points = { { 0.1, 0.9 }, { 0.1, 1 } } })
hl.curve("slide", { type = "bezier", points = { { 0.25, 1 }, { 0.25, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.2, bezier = "snappy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.2, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "instant", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "instant" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "instant" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "instant" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "instant" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "snappy" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "instant", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.5, bezier = "instant" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "instant" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "slide", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.5, bezier = "slide", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, bezier = "instant", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "snappy" })

local mainMod = "SUPER"

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(ide))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/show-desktop.sh"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock >/dev/null || hyprlock"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pgrep -x wofi > /dev/null || " .. menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("~/.config/eww/scripts/kb-layout-toggle.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-select.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("~/.config/eww/scripts/toggle-menu.sh"))
hl.bind("escape", hl.dsp.exec_cmd("~/.config/eww/scripts/close-menu.sh"), { non_consuming = true })

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh down"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-notify.sh mute"), { repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh up"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-notify.sh down"),
    { repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


hl.layer_rule({
    match = { namespace = "eww-menu" },
    animation = "slide right",
})

hl.window_rule({
    name = "discord-float-center",
    match = { class = "discord" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "nautilus-float",
    match = { class = "org.gnome.Nautilus" },
    float = true,
})

hl.window_rule({
    name = "prism-launcher-float",
    match = { class = "org.prismlauncher.PrismLauncher" },
    float = true,
})

hl.window_rule({
    name = "blueman-float",
    match = { class = "blueman-manager" },
    float = true,
})

hl.window_rule({
    name = "xdg-desktop-portal-gtk",
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
})

hl.window_rule({
    name = "loupe-float",
    match = { class = "org.gnome.Loupe" },
    float = true,
})

hl.window_rule({
    name = "bitwarden-extension-float",
    match = { title = "Extension: (Bitwarden Password Manager) - Bitwarden — Zen Browser" },
    float = true,
})

hl.window_rule({
    name = "Calculator",
    match = { class = "gnome-calculator" },
    float = true,
})

hl.window_rule({
    name = "shimeji",
    match = { class = "com-group_finity-mascot-Main" },
    float = true,
    no_blur = true,
    no_focus = true,
    no_shadow = true,
    border_size = 0,
})

hl.window_rule({
    name = "bitwarden",
    match = { class = "Bitwarden" },
    float = true,
})
