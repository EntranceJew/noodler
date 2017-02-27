local node = require "node"
local plug = require "plug"
local cpml = require "cpml"

return {
	name     = "Mix",
	category = "String",
	new      =  function(tree, position)
		return tree:add(
			node {
				name = "Mix",
				inputs = {
					plug("Value", "string", 1),
					plug("Value", "string", 2)
				},
				outputs = {
					plug("Value", "string", 1)
				},
				values = {
					"",
					""
				},
				evaluate = function(self)
					self.computed[1] = self.values[1] .. self.values[2]
				end
			},
			position
		)
	end
}
