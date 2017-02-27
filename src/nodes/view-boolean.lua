local node = require "node"
local plug = require "plug"

return {
	name     = "Boolean",
	category = "View",
	new      = function(tree, position)
		return tree:add(
			node {
				name = "Boolean View",
				inputs = {
					plug("Value", "boolean", 1)
				},
				values = {
					false
				},
				display = function(self, ui)
					ui:label(string.format("%s", tostring(self.values[1])))
				end
			},
			position
		)
	end
}
