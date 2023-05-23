local wezterm = require("wezterm")
local launcher = require("launch_menu")
local _deepcopy = require("lua/utils").deepcopy

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

launcher.apply(config)
config.inactive_pane_hsb = {
	-- hue = .2,
	saturation = 0.9,
	brightness = 0.7,
}
config.macos_window_background_blur = 15
config.window_background_opacity = 0.95
wezterm.on("print-cfg", function(window, _pane)
	local cfg = window:get_config()
	local overrides = window:get_config_overrides()
	local cfg_str = wezterm.config_to_str(cfg, overrides)
	print(cfg_str)
end)

config.disable_default_key_bindings = true
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 3000 }

config = (function(cfg)
	local key_maps = require("keys")
	for key_map_title, map in pairs(key_maps) do
		if cfg[key_map_title] == nil then
			cfg[key_map_title] = map
		else
			for _, binding in ipairs(map) do
				table.insert(cfg[key_map_title], binding)
			end
		end
	end
	return cfg
end)(config)

config.window_decorations = "INTEGRATED_BUTTONS"

config.font = wezterm.font_with_fallback({
	{ family = "MonoLisa 230504", weight = "Regular", stretch = "Normal", style = "Normal" },
	{ family = "MonoLisaOne Nerd Font", weight = "Regular", style = "Normal" },
	{ family = "SF Compact Text", weight = "Regular", style = "Normal" },
})
config.font_rules = {
	-- For Bold-but-not-italic
	{
		intensity = "Bold",
		italic = false,
		font = wezterm.font({
			family = "MonoLisa 230504",
			weight = "Bold",
			style = "Normal",
		}),
	},

	-- Bold-and-italic
	{
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = "MonoLisa 230504",
			weight = "Bold",
			style = "Italic",
		}),
	},

	-- normal-intensity-and-italic
	{
		intensity = "Normal",
		italic = true,
		font = wezterm.font({
			family = "MonoLisa 230504",
			weight = "Light",
			style = "Italic",
		}),
	},

	-- half-intensity-and-italic (half-bright or dim); use a lighter weight font
	{
		intensity = "Half",
		italic = true,
		font = wezterm.font({
			family = "MonoLisa 230504",
			weight = "Thin",
			style = "Italic",
		}),
	},

	-- half-intensity-and-not-italic
	{
		intensity = "Half",
		italic = false,
		font = wezterm.font({
			family = "MonoLisa 230504",
			weight = "ExtraLight",
			style = "Normal",
		}),
	},
}
config.font_size = 12.0
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"sh",
	"zsh",
	"tmux",
	"ssh",
	"wezterm",
	"Python",
	"volta-shim",
}
config.initial_cols = 120
config.initial_rows = 60
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.text_blink_ease_in = "Ease"
config.text_blink_ease_out = "Ease"

config.color_scheme = "tokyonight_night"
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
local bg_0 = wezterm.color.parse(scheme["background"])

config.command_palette_bg_color = scheme.background
config.command_palette_fg_color = scheme.ansi[8]
config.command_palette_font_size = 11.0

config.window_frame = {
	font = wezterm.font({ family = "SF Compact Text" }),
	font_size = 10,
	active_titlebar_bg = bg_0,
	inactive_titlebar_bg = bg_0,
}

config.colors = {}
config.colors.tab_bar = _deepcopy(scheme.tab_bar)
config.colors.tab_bar.inactive_tab.italic = true
config.term = "wezterm"
config.unix_domains = {
	{
		name = "unix",
	},
}
config.ssh_domains = {
	{
		name = "ec2.dev.box",
		remote_address = "127.0.0.1:2222",
		username = "ec2-user",
	},
	{
		name = "imac",
		remote_address = "192.168.1.124",
		local_echo_threshold_ms = 10,
		username = "al",
	},
	{
		name = "imac.remote",
		-- remote_address = "ilseman.bouncme.net:2222",
		remote_address = "24.148.85.146:2222",
		username = "al",
		local_echo_threshold_ms = 10,
	},
}
config.underline_thickness = "1pt"
config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "1.75cell",
	bottom = "0.5cell",
}

config.webgpu_preferred_adapter = wezterm.gui.enumerate_gpus()[1]

config.front_end = "WebGpu"

config.default_workspace = "default"
config.default_domain = "local"

config.default_gui_startup_args = { "connect", "unix" }
config.tab_max_width = 8

require("event_handlers")(config)
return config

-- TODO:
-- 1. Fix tab titles
--   - for neovim
--     - nvim + wezterm.lua
--   - for zsh
--     - zsh://~/s/f/c/dirname
--   - for ssh
--      - ssh://hostname
--   - Limit to 18-24 chars
--   - Add indices back
-- 2. Drop right-status cwd
--   - Or shorten it, keep it, and move domain to left-status
--   - That way left status refers to terminal information and the right is shell information
--     - Or should the left be window level information and the right pane level?
--   - Or just drop it, it's not that useful
-- 3. Create basic pomodoro timer using (plugin)
--   - update-status
--   - update-status-interval
--   - update-title?
--   - wezterm.time.call_after(interval_seconds, callback)
--   - prompt user for line
--   - where the first space separated arg is the number of minutes and the rest is a title/description
-- 4. Write a plugin manager
--   - It seems plain as day, but you've seen absolutely no mention of it anywhere
--   - Maybe @Wez will think I'm cool
-- 5. Add error handling, logging, and null checks to my config
