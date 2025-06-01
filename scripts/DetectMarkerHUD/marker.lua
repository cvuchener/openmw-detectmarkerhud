local camera = require('openmw.camera')
local ui = require('openmw.ui')
local util = require('openmw.util')

local NPC = require('openmw.types').NPC

local D = require('scripts.DetectMarkerHUD.defs')
local settings = require('scripts.DetectMarkerHUD.settings').display;

local GenericMarker = ui.texture { path = 'textures/DetectMarkerHUD/marker.dds' }
local Icons = {
	[D.Detect.KEY] = ui.texture { path = 'textures/DetectMarkerHUD/key.dds' },
	[D.Detect.ENCHANTMENT] = ui.texture { path = 'textures/DetectMarkerHUD/enchantment.dds' },
	[D.Detect.ANIMAL] = ui.texture { path = 'textures/DetectMarkerHUD/animal.dds' },
}
local UpArrow = ui.texture { path = 'textures/DetectMarkerHUD/up_arrow.dds' }
local DownArrow = ui.texture { path = 'textures/DetectMarkerHUD/down_arrow.dds' }
local LeftArrow = ui.texture { path = 'textures/DetectMarkerHUD/left_arrow.dds' }
local RightArrow = ui.texture { path = 'textures/DetectMarkerHUD/right_arrow.dds' }

local ColorKeys = {
	[D.Detect.KEY] = "KeyMarkerColor",
	[D.Detect.ENCHANTMENT] = "EnchantmentMarkerColor",
	[D.Detect.ANIMAL] = "AnimalMarkerColor",
}

local Marker = {}
Marker.__index = Marker

function Marker:new(object, detect_type)
	local position_offset = util.vector3(0, 0, 0)
	if NPC.objectIsInstance(object) then
		local npc = NPC.record(object)
		local race = NPC.races.record(npc.race)
		local base_offset = settings:get('NPCHeightOffset')
		if npc.isMale then
			position_offset = util.vector3(0, 0, base_offset * race.height.male)
		else
			position_offset = util.vector3(0, 0, base_offset * race.height.female)
		end
	end
	return setmetatable({
		object = object,
		type = detect_type,
		icon = ui.create {
			layer = 'HUD',
			type = ui.TYPE.Image,
			props = {},
		},
		position_offset = position_offset,
	}, self)
end

function Marker:update()
	local screen = ui.screenSize()
	local screen_ratio = screen.x / screen.y
	local screen_center = screen/2

	local world_pos = self.object.position + self.position_offset

	local vp_pos = camera.worldToViewportVector(world_pos)
	local pos = util.vector2(vp_pos.x, vp_pos.y) - screen_center
	local pos_ratio = math.abs(pos.x) / math.abs(pos.y)

	local icon_size = settings:get('IconSize')
	local margin = settings:get('Margin') + icon_size/2

	local ui_pos = screen_center + pos
	local arrow = nil
	if camera.getViewTransform():apply(world_pos).z > 0 then
		-- object is behind the camera
		if pos_ratio >= screen_ratio then -- project on sides
			ui_pos = screen_center - pos * (screen.x/2 - margin) / math.abs(pos.x)
			arrow = pos.x > 0 and LeftArrow or RightArrow
		else -- project on top/bottom
			ui_pos = screen_center - pos * (screen.y/2 - margin) / math.abs(pos.y)
			arrow = pos.y > 0 and UpArrow or DownArrow
		end
	else -- object is in front of the camera
		if pos_ratio >= screen_ratio then
			if math.abs(pos.x) >= screen.x/2 - margin then -- project on sides
				ui_pos = screen_center + pos * (screen.x/2 - margin) / math.abs(pos.x)
				arrow = pos.x > 0 and RightArrow or LeftArrow
			end
		else
			if math.abs(pos.y) >= screen.y/2 - margin then -- project on top/bottom
				ui_pos = screen_center + pos * (screen.y/2 - margin) / math.abs(pos.y)
				arrow = pos.y > 0 and DownArrow or UpArrow
			end
		end
	end
	if arrow == nil then
		if settings:get('UseGenericIcon') then
			self.icon.layout.props.resource = GenericMarker
		else
			self.icon.layout.props.resource = Icons[self.type]
		end
	else
		self.icon.layout.props.resource = arrow
	end
	self.icon.layout.props.size = util.vector2(icon_size, icon_size)
	self.icon.layout.props.color = settings:get(ColorKeys[self.type])
	self.icon.layout.props.position = ui_pos - util.vector2(icon_size/2, icon_size/2)
	self.icon:update()
end

function Marker:destroy()
	self.icon:destroy()
end

return Marker
