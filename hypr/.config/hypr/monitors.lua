return function(hl)
	-- Notebook display
	hl.monitor({
	    output   = "eDP-1",
	    mode     = "preferred",
	    position = "auto",
	    scale    = "1",
	})

  -- Old config
	-- hl.monitor({
	-- 	output = "eDP-1",
	-- 	mode = "1920x1080@60",
	-- 	position = "0x0",
	-- 	scale = "1",
	-- })

	-- Rovesly monitor
	hl.monitor({
	    output   = "HDMI-A-1",
	    mode     = "preferred",
	    position = "auto",
	    scale    = "auto",
	})

  -- Old Config
	-- hl.monitor({
	-- 	output = "HDMI-A-1",
	-- 	mode = "3440x1440@100",
	-- 	position = "auto",
	-- 	scale = "1",
	-- })
end
