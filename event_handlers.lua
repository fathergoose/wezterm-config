local wezterm = require("wezterm")
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
		local cwd_uri = pane:get_current_working_dir()
		local hostname = os.getenv("HOSTNAME")
		if cwd_uri then
			cwd_uri = cwd_uri:sub(8)
			local slash = cwd_uri:find("/")
			local user = os.getenv("USER")
			if slash then
				hostname = cwd_uri:sub(1, slash - 1)
				local dot = hostname:find("[.]")
				if dot then
					hostname = hostname:sub(1, dot - 1)
				end
				table.insert(cells, "")
				table.insert(cells, "力 " .. user .. "@" .. hostname)
				table.insert(cells, "󱘖 " .. pane:get_domain_name())
			end
		end

		local date = wezterm.strftime("%a %b %-d %H:%M")
		table.insert(cells, " " .. date)

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

		window:set_left_status(wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = text_fg } },
			{ Background = { Color = bg_0 } },
			{ Text = "  " .. window:active_workspace() .. " (" .. hostname .. ", " .. pane:get_domain_name() .. "): " },
			"ResetAttributes",
		}))
	end)

	--  ;
	wezterm.on("format-tab-title", function(tab_info)
		local title = tab_info.tab_title
		if title and #title > 0 then
			return title
		end
		return tab_info.active_pane.title:gsub("%b() %-", "")
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
