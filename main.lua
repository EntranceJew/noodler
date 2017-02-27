local nk    = require "nuklear"
local cpml  = require "cpml"
local graph = require "graph"
local utils = require "utils"
local lume  = require "lume"
local grid  = require "editgrid"

function love.load()
	local bg = cpml.color.linear_to_gamma { 40, 40, 40, 255 }
	love.graphics.setBackgroundColor(bg)
end

local nodes = {
	note = require("nodes.note").new,
	value = require("nodes.input-number").new,
	mix = require("nodes.math-mix").new,
	number_view = require("nodes.view-number").new
}
local node_combo = {
	value = 1,
	items = {
	},
}

local function reload_nodes_for_combo()
	local files = love.filesystem.getDirectoryItems("src/nodes")
	local fname = ""
	for _, file in ipairs(files) do
		local req = nil
		fname = file:match("(.+)%..+")
		req = require("nodes."..fname)
		if req.new ~= nil then
			nodes[fname] = req.new
			table.insert(node_combo.items, fname)
		else
			print("WARNING: node '"..fname.."' has no new method or is empty.")
		end
	end
end

reload_nodes_for_combo()

local tree = graph()
tree.debug = true

local a = nodes.value(tree, cpml.vec2(-400, -250))
a.values[1] = 0.0

local b = nodes.value(tree, cpml.vec2(-400, 50))
b.values[1] = 1.0

local m = nodes.mix(tree, cpml.vec2(-100, -100))
local o = nodes.number_view(tree, cpml.vec2(200, -100))

local wire1 = tree:connect(a.outputs[1], m.inputs[2])
local wire2 = tree:connect(b.outputs[1], m.inputs[3])
local wire3 = tree:connect(m.outputs[1], o.inputs[1])

--[[
local function dump_wire(wire, tag)
	if not wire then
		print(string.format(
			"BAD WIRE: %s", tag
		))
		return
	end
	print(string.format(
		"\n%s\nFROM\t%s\nTO\t%s\nAS\t%s\n",
		tag,
		wire.input,
		wire.output,
		wire.input.type
	))
end

if tree.debug then
	dump_wire(wire1, "a->m")
	dump_wire(wire2, "b->m")
	dump_wire(wire3, "m->o")
end
--]]

-- tree:compile()
-- tree:execute()

local nk = require "nuklear"
nk.init()

local combo = {
	value = 1,
	items = { 'A', 'B', 'C' }
}

local function draw_noodle(first, last, color)
	-- 1-2 is mega-curvy, 0 is straight, >2 is a gentle curve.
	-- How the hell am I even supposed to name that?
	local curviness = 3
	local bezier
	if curviness == 0 then
		bezier = love.math.newBezierCurve(first.x, first.y, last.x, last.y)
	else
		bezier = love.math.newBezierCurve(
			first.x, first.y,
			first.x + (last.x - first.x) / curviness, first.y,
			last.x - (last.x - first.x) / curviness, last.y,
			last.x, last.y
		)
	end

	if color then
		love.graphics.setColor(color)
	end

	local px = love.window.toPixels
	love.graphics.circle("fill", first.x, first.y, px(5))

	-- Arrows
	local arrow_width, arrow_length = px(5), px(10)
	love.graphics.push()
	love.graphics.translate(last.x, last.y)

	local len = first:dist(last)
	local pos = cpml.utils.clamp((len - arrow_length * 1.5) / len, 0, 1)
	--love.graphics.rotate(last:angle_to(cpml.vec2(bezier:evaluate(pos)))-math.pi/2)

	love.graphics.polygon("fill", -arrow_width, -arrow_length, arrow_width, -arrow_length, 0, 0)
	love.graphics.pop()

	-- No need for subdivisions if it's straight.
	love.graphics.line(bezier:render(curviness == 0 and 1 or 4))
end

local default_font = love.graphics.newFont("assets/NotoSans-Regular.ttf", love.window.toPixels(12))
local styles = {
	line_height = 1.35,
	button_width = love.window.toPixels(20),
	node = {
		font = default_font,
		text = {
			["color"] = "#000000ff",
		},
		window = {
			["padding"]          = { x = love.window.toPixels(2), y = love.window.toPixels(2) },
			["background"]       = "#ddddddff",
			["fixed background"] = "#ddddddff",
			["scaler"]           = "#222222ff"
		},
		label = {
			["padding"]      = { x = 0, y = 0 }
		},
		button = {
			["padding"]      = { x = 0, y = 0 },
			["rounding"]     = 0,
			["normal"]       = "#00000000",
			["border color"] = "#00000000",
			["hover"]        = "#55555555",
			["active"]       = "#00000055",
		}
	}
}

local wire_colors = {
	default = { 255, 255, 255 },
	number  = {   0, 120, 255 },
	vec3    = { 255, 120,   0 },
	quat    = {   0, 255, 120 }
}

local new_wire = false
local positions = {}
local function draw_nodes(offset)
	positions = {}
	local dirty = false
	local removed = {}

	nk.stylePush(styles.node)
	for i, n in ipairs(tree) do
		local position = tree.positions[n.uuid]

		local px = love.window.toPixels
		local x, y = px(position.x) + offset.x, px(position.y) + offset.y
		local w, h = px(250), px(200)

		local flags = { "title", "movable"}

		if nk.windowIsActive(n.uuid) then
			table.insert(flags, "closable")
		end

		if nk.windowBegin(n.uuid, n.name, x, y, w, h, unpack(flags)) then
			local ww, wh = nk.windowGetSize()
			nk.windowSetSize(math.max(ww, px(150)), math.max(wh, px(150)))

			local bw = styles.button_width
			local lw = select(3, nk.windowGetContentRegion()) / 2 - bw - px(8)
			local height = styles.node.font:getHeight() * styles.line_height
			nk.layoutRow("static", height, { bw, lw, lw, bw })
			for i = 1, math.max(#n.inputs, #n.outputs) do
				local input = n.inputs[i] or false
				if input then
					local connected = tree.connections[input]
					if nk.button("", connected and "circle solid" or "circle outline") then
						if connected then
							tree.connections[connected.input] = nil
							tree.connections[connected.output] = nil
							connected = false
						elseif new_wire then
							connected = tree:connect(new_wire.plug, input)
							new_wire = false
							if connected then
								dirty = true
							end
						end
					end
					if connected then
						local x, y = nk.widgetPosition()
						positions[input] = {
							cpml.vec2(x - styles.button_width + px(5), y + height / 2),
							connected = connected and true or false
						}

						nk.label(input.name, "left")
					else
						local t = {
							value = tostring(n.values[i]),
							convert = tonumber
						}
						local state, changed = nk.edit("field", t)
						-- todo: store temp, use committed state
						if changed then
							n.values[i] = t.convert(t.value) or 0.0
							dirty = true
						end
					end
				else
					nk.spacing(2)
				end

				local output = n.outputs[i] or false
				if output then
					nk.label(output.name, "right")
					local connected = tree.connections[output]
					if nk.button("", connected and "circle solid" or "circle outline") then
						local x, y = nk.widgetPosition()
						new_wire = {
							plug     = output,
							position = cpml.vec2(x + px(1), y - height / 2 - px(4))
						}
					end
					local x, y = nk.widgetPosition()
					positions[output] = {
						cpml.vec2(x + px(1), y - height / 2 - px(4)),
						connected = connected and true or false
					}
				else
					nk.spacing(2)
				end
			end
			nk.layoutRow("dynamic", 30, 1)
			if n.display then
				if n:display(nk) then
					dirty = true
				end
			end
		else
			table.insert(removed, { index = i, node = n })
		end
		nk.windowEnd()
	end
	nk.stylePop()

	for i=#removed, 1, -1 do
		local n = removed[i].node
		for _, input in ipairs(n.inputs) do
			tree.connections[input] = nil
			positions[input] = nil
		end
		for _, output in ipairs(n.outputs) do
			tree.connections[output] = nil
			positions[output] = nil
		end
		table.remove(tree, removed[i].index)
	end

	return dirty
end

local grid_position = cpml.vec2(0, 0)
function love.update(dt)
	nk.frameBegin()

	local size = cpml.vec2(love.graphics.getDimensions())
	local offset = size / 2 + grid_position
	local dirty = draw_nodes(offset)

	if nk.windowBegin("toolbar", 0, 0, size.x, 40) then
		nk.layoutRow("dynamic", 30, 3)
		if nk.combobox(node_combo, node_combo.items) then
			nodes[node_combo.items[node_combo.value]](tree, cpml.vec2())
		end
		nk.spacing(1)
		if nk.button("Build & Run") then
			dirty = true
		end
	end
	nk.windowEnd()

	if dirty then
		tree:compile()
		tree:execute()
	end

	nk.frameEnd()
end

function love.draw()
	-- no super thin lines on retina displays
	love.graphics.setLineWidth(love.window.getPixelScale())

	-- background (don't just draw on backbuffer, screws with blending)
	love.graphics.setColor(80, 80, 80, 255)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

	local w, h = love.graphics.getDimensions()
	local zoom = 1
	grid.draw({
		x  = (-grid_position.x) * (1/zoom),
		y  = (-grid_position.y) * (1/zoom),
		zoom = zoom,
		sw = w,
		sh = h
	}, {
		size = 50,
		subdivisions = 5,
		color = { 45, 45, 45 },
		xColor = { 255, 0, 0 },
		yColor = { 0, 255, 0 },
		fadeFactor = 1.5,
		textFadeFactor = 0.75,
	})

	-- foreground windows...
	love.graphics.setColor(255, 255, 255, 255)
	nk.draw()

	-- draw the connecting wires
	local wires = {}
	for _, v in pairs(tree.connections) do
		table.insert(wires, v)
	end
	wires = lume.set(wires)

	for _, v in ipairs(wires) do
		if positions[v.output] and positions[v.input] and positions[v.input].connected then
			draw_noodle(positions[v.input][1], positions[v.output][1], wire_colors[v.input.type] or wire_colors.default)
		end
	end

	-- if you're dragging out a node, show it in yellow
	if new_wire then
		draw_noodle(new_wire.position, cpml.vec2(love.mouse.getPosition()), { 255, 255, 0 })
	end
end

function love.keypressed(key, scancode, isrepeat)
	nk.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	nk.keyreleased(key, scancode)
end

local move = false
function love.mousepressed(x, y, button, istouch)
	if nk.mousepressed(x, y, button, istouch) then
		return
	end

	if new_wire then
		new_wire = false
	end

	if not move then
		-- move = cpml.vec2(x, y)
		-- love.mouse.setRelativeMode(true)
	end
end

function love.mousereleased(x, y, button, istouch)
	if nk.mousereleased(x, y, button, istouch) then
		return
	end

	if move then
		love.mouse.setRelativeMode(false)
		love.mouse.setPosition(move.x, move.y)
		move = false
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	if move then
		love.mouse.setPosition(0, 0)
		grid_position = grid_position + cpml.vec2(dx, dy)
		return
	end

	if nk.mousemoved(x, y, dx, dy, istouch) then
		return
	end
end

function love.textinput(text)
	nk.textinput(text)
end

function love.wheelmoved(x, y)
	nk.wheelmoved(x, y)
end
