local node = require "node"
local plug = require "plug"

return {
	name     = "String",
	category = "Input",
	new      = function(tree, position)
		return tree:add(
			node {
				name = "Value",
				outputs = {
					plug("Value", "string", 1)
				},
				values = {
					""
				},
				display = function(self, ui)
					local t = {
						value = tostring(self.values[1]),
						convert = tostring
					}
					local state, changed = ui:edit("field", t)
					-- todo: store temp, use state == "commited"
					if changed then
						self.values[1] = t.convert(t.value) or ""
						return true
					end
				end,
				evaluate = function(self)
					self.computed[1] = self.values[1]
				end
			},
			position
		)
	end
}
