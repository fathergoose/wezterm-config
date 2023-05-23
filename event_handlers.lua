local wezterm = require("wezterm")
local act = wezterm.action
local io = require("io")
local os = require("os")
local icons = require("icons")
local emspace = "\u{2003}"
local enspace = "\u{2002}"

local guard_user_variables = function(vars)
	local defaults = {
		WEZTERM_HOST = "als-imac.lan",
		WEZTERM_IN_TMUX = "0",
		WEZTERM_PROG = "unknown_program",
		WEZTERM_USER = "al",
	}
	local parsed = {}
	for k, v in pairs(defaults) do
		parsed[k] = vars[k] or v
	end
	return parsed
end

local M = function(config)
	local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
	local bg_0 = wezterm.color.parse(scheme["background"])
	local bg_1 = bg_0:lighten(0.1):saturate(0.1)
	local bg_2 = bg_1:lighten(0.1)
	local bg_3 = bg_2:lighten(0.1)
	local bg_4 = bg_3:lighten(0.1)
	local text_fg = scheme.foreground
	local colors = {
		bg_0,
		bg_1,
		bg_2,
		bg_3,
		bg_4,
	}

	wezterm.on("trigger-vim-with-visible-text", function(window, pane)
		-- Retrieve the current viewport's text.
		--
		-- Note: You could also pass an optional number of lines (eg: 2000) to
		-- retrieve that number of lines starting from the bottom of the viewport.
		local viewport_text = pane:get_lines_as_text()

		-- Create a temporary file to pass to vim
		local name = os.tmpname()
		local f = io.open(name, "w+")
		f:write(viewport_text)
		f:flush()
		f:close()

		-- Open a new window running vim and tell it to open the file
		window:perform_action(
			act.SpawnCommandInNewWindow({
				args = { "zsh", "nvim", name },
			}),
			pane
		)

		-- Wait "enough" time for vim to read the file before we remove it.
		-- The window creation and process spawn are asynchronous wrt. running
		-- this script and are not awaitable, so we just pick a number.
		--
		-- Note: We don't strictly need to remove this file, but it is nice
		-- to avoid cluttering up the temporary directory.
		wezterm.sleep_ms(1000)
		os.remove(name)
	end)

	wezterm.on("toggle-opacity", function(window, _pane)
		local override = window:get_config_overrides() or {}
		local ON = 1.0
		if override.window_background_opacity == ON then
			override.window_background_opacity = config.window_background_opacity
		else
			override.window_background_opacity = ON
		end
		wezterm.log_info("toggle-opacity: %s", override.window_background_opacity)
		window:set_config_overrides(override)
	end)
	wezterm.on("increment-opacity", function(window, _pane)
		local override = window:get_config_overrides() or {}
		local opacity = override.window_background_opacity or config.window_background_opacity
		local ON = 1.0
		if opacity == ON then
			return
		elseif opacity + 0.02 > ON then
			override.window_background_opacity = ON
		else
			override.window_background_opacity = opacity + 0.02
		end
		window:set_config_overrides(override)
	end)
	wezterm.on("decrement-opacity", function(window, _pane)
		local override = window:get_config_overrides() or {}
		local opacity = override.window_background_opacity or config.window_background_opacity
		local OFF = 0.0
		if opacity == OFF then
			return
		elseif opacity - 0.02 < OFF then
			override.window_background_opacity = OFF
		else
			override.window_background_opacity = opacity - 0.02
		end
		window:set_config_overrides(override)
	end)
	wezterm.on("set-opacity", function()
		wezterm.action.PromptInputLine({
			description = "Opacity (0.0 - 1.0)",
			action = wezterm.action_callback(function(window, _p, opacity)
				local override = window:get_config_overrides() or {}
				override.window_background_opacity = opacity
				window:set_config_overrides(override)
			end),
		})
	end)
	wezterm.on("update-status", function(window, pane)
		local cells = {}
		local uvars = {}
		local status, retval = pcall(pane.get_user_vars, pane)
		if status then
			uvars = retval
		end

		local vars = guard_user_variables(uvars)
		local hostname = vars["WEZTERM_HOST"]
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		table.insert(cells, "")
		table.insert(cells, " \u{f048b} " .. vars["WEZTERM_USER"] .. "@" .. hostname .. " ")
		table.insert(cells, " 󱘖 " .. (pane:get_domain_name() or "domain unknown") .. " ")

		local datetime = wezterm.strftime("%a %b %-d\u{2002}\u{f017}\u{2000}%H:%M ")
		table.insert(cells, "\u{f00ed}\u{2000}" .. datetime)

		local getBatteryIdicator = function(charge)
			if charge == nil then
				return
			end
			local tenths_of_a_charge = math.floor(charge / 10)
			print("tenths")
			print(tenths_of_a_charge)

			local full = 0xf0079
			local ten_percent = 0xf007a
			local alert = 0xf0083
			local icon_index = tenths_of_a_charge > 0 and (full + tenths_of_a_charge) or alert
			print("icon_index")
			print(string.format("%x", icon_index))
			return utf8.char(icon_index)
		end
		local batteries = wezterm.battery_info()
		for _, bat in ipairs(batteries) do
			local percent_charged = bat.state_of_charge * 100
			local indicator = getBatteryIdicator(percent_charged)
			table.insert(cells, math.floor(percent_charged) .. "%\u{2000}\u{f140b}" .. indicator .. "\u{2002}")
		end

		local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

		local elements = {}
		local num_cells = 0

		local function push(text, is_last)
			local cell_no = num_cells + 1
			table.insert(elements, "ResetAttributes")
			table.insert(elements, { Foreground = { Color = text_fg } })
			table.insert(elements, { Background = { Color = colors[cell_no] } })
			table.insert(elements, { Text = " " .. text .. " " })
			if not is_last then
				table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
				table.insert(elements, { Text = SOLID_LEFT_ARROW })
			end
			table.insert(elements, "ResetAttributes")

			num_cells = num_cells + 1
		end

		while #cells > 0 do
			local cell = table.remove(cells, 1)
			push(cell, #cells == 0)
		end

		window:set_right_status(wezterm.format(elements))

		local left_format_string = " 󱘖 "
			.. (pane:get_domain_name() or "domain unknown")
			.. " "
			.. utf8.char(0xf4b3)
			.. enspace
			.. window:active_workspace()

		window:set_left_status(wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = text_fg } },
			{ Background = { Color = bg_0 } },
			{
				Text = left_format_string,
			},
			"ResetAttributes",
		}))
	end)
	-- 
	local function expandTilde(path)
		local home = os.getenv("HOME")
		if path:sub(1, 1) == "~" then
			return home .. path:sub(2)
		end
		return path
	end

	--  ;
	wezterm.on("format-tab-title", function(tab_info)
		return icons.get_number_icon(tab_info.tab_index + 1)
			.. "   "
			.. (function(ti)
				local title = ti.tab_title
				if title and #title > 0 then
					return title
				end
				title = ti.active_pane.title:gsub("%b() %-", "")
				if title == "~" then
					return expandTilde(title)
				end
				local fg_proc = ti.active_pane.foreground_process_name
				if fg_proc and fg_proc == "zsh" then
					return "zsh:/" .. ti.active_pane.title:gsub("%b() %-", "")
				end
				return title
			end)(tab_info)
	end)

	wezterm.on("augment-command-palette", function(window)
		return {
			{
				brief = "Rename tab",
				icon = "mdi_rename_box",
				action = wezterm.action.PromptInputLine({
					description = "Enter new name for tab",
					action = wezterm.action_callback(function(_window, _pane, line)
						if line then
							window:active_tab():set_title(line)
						end
					end),
				}),
			},
		}
	end)
end

return M
