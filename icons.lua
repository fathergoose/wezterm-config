local wezterm = require("wezterm")
local M = {}

M.get_number_icon = function(n)
	local icons = {
		numbers = {
			square_no_fill = {
				"\u{f03a3}", -- 0
				"\u{f03a6}", -- 1
				"\u{f03a9}", -- 2
				"\u{f03ac}", -- 3
				"\u{f03ae}", -- 4
				"\u{f03b0}", -- 5
				"\u{f03b5}", -- 6
				"\u{f03b8}", -- 7
				"\u{f03bb}", -- 8
				"\u{f03be}", -- 9
				"\u{f0f7e}", -- 10
			},
			square_solid_fill = {
				"\u{f03a1}", -- 0
				"\u{f03a4}", -- 1
				"\u{f03a7}", -- 2
				"\u{f03aa}", -- 3
				"\u{f03ad}", -- 4
				"\u{f03b1}", -- 5
				"\u{f03b3}", -- 6
				"\u{f03b6}", -- 7
				"\u{f03b9}", -- 8
				"\u{f03bc}", -- 9
				"\u{f0f7d}", -- 10
			},
			large_digitis = {
				"\u{f0b39}", -- 0
				"\u{f0b3a}", -- 1
				"\u{f0b3b}", -- 2
				"\u{f0b3c}", -- 3
				"\u{f0b3d}", -- 4
				"\u{f0b3e}", -- 5
				"\u{f0b3f}", -- 6
				"\u{f0b40}", -- 7
				"\u{f0b41}", -- 8
				"\u{f0b42}", -- 9
				"\u{f0fe9}", -- 10
			},
		},
	}

	if n < 0 or n > 9 then
		local digits = string.format("%d", n)
		local glyphs = {}
		for i = 1, #digits do
			local v = digits:sub(i, i)
			table.insert(glyphs, icons.digits.large_digitis[tonumber(v) + 1])
		end
		return table.concat(icons)
	end
	return icons.digits.large_digitis[n + 1]
end

return M
