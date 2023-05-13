local wezterm = require 'wezterm';
local module = {}

module.launch_menu_config = {
	{
        label = "Htop",
		args = { "/usr/local/bin/htop" },
	},
	{
		label = "Bash",
		args = { "bash", "-l" },

	},
}

function module.apply(config)
	config.launch_menu = module.launch_menu_config
end

return module
