local node = require "node"
local plug = require "plug"

return {
	name     = "Compare",
	category = "Math",
	new      = function(tree, position)
		return tree:add(
			node {
				name = "Compare",
				inputs  = {
					plug("Number 1", "number", 1),
					plug("Number 2", "number", 2)
				},
				outputs = {
					plug("==", "boolean", 1),
					plug("~=", "boolean", 2),
					plug(">", "boolean", 3),
					plug(">=", "boolean", 4),
					plug("<", "boolean", 5),
					plug("<=", "boolean", 6)
				},
				values = {
					false,
					false,
					false,
					false,
					false,
					false
				},
				evaluate = function(self)
					self.computed[1] = self.values[1] == self.values[2]
					self.computed[2] = self.values[1] ~= self.values[2]
					self.computed[3] = self.values[1] >  self.values[2]
					self.computed[4] = self.values[1] >= self.values[2]
					self.computed[5] = self.values[1] <  self.values[2]
					self.computed[6] = self.values[1] <= self.values[2]
				end
			},
			position
		)
	end
}