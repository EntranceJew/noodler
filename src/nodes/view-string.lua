local node = require "node"
local plug = require "plug"

return {
	name     = "String",
	category = "View",
	new      = function(tree, position)
		return tree:add(
			node {
				name    = "String View",
				inputs  = {
					plug("Value", "string", 1)
				},
				values = {
					""
				},
				display = function(self, ui)
					ui:label(string.format("%s", self.values[1]))
				end
			},
			position
		)
	end
}
