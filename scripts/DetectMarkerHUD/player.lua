local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')

local Actor = types.Actor
local Creature = types.Creature
local Container = types.Container
local NPC = types.NPC

local Marker = require('scripts.DetectMarkerHUD.marker')
local D = require('scripts.DetectMarkerHUD.defs')
local Performance = require('scripts.DetectMarkerHUD.settings').performance

-- Constants
local UnitsPerFeet = 22

-- Object tests
local isEnchanted = {
	types = { types.Armor, types.Clothing, types.Weapon, types.Book },
	call = function (type, object)
		local record = type.record(object)
		return record.enchant ~= nil
	end,
}

local isKey = {
	types = { types.Miscellaneous },
	call = function (type, object)
		local record = type.record(object)
		return record.isKey
	end,
}

local function checkItem(test, object)
	for _, type in ipairs(test.types) do
		if type.objectIsInstance(object) then
			return test.call(type, object)
		end
	end
	return false
end

local function checkInventory(test, inventory)
	if not inventory:isResolved() then
		return false
	end
	for _, type in ipairs(test.types) do
		for _, item in ipairs(inventory:getAll(type)) do
			if test.call(type, item) then
				return true
			end
		end
	end
	return false
end

local function isAnimal(actor)
	if Actor.isDead(actor) then
		return false
	end
	if NPC.isWerewolf(self) then
		return NPC.objectIsInstance(actor)
	else
		return Creature.objectIsInstance(actor)
	end
end

-- Previously detected objects
local current_markers = {}

-- Add new detected object
local function detected(object, detect_type)
	if current_markers[object.id] == nil then
		current_markers[object.id] = Marker:new(object, detect_type)
	end
end

local function testItem(item, max_dist2)
	local distance2 = (self.position - item.position):length2()
	if distance2 <= max_dist2[D.Detect.ENCHANTMENT]
			and checkItem(isEnchanted, item)
	then
		detected(item, D.Detect.ENCHANTMENT)
	end
	if distance2 <= max_dist2[D.Detect.KEY]
			and checkItem(isKey, item)
	then
		detected(item, D.Detect.KEY)
	end
end

local function testActor(actor, max_dist2)
	if actor.id ~= self.id then
		local distance2 = (self.position - actor.position):length2()
		if distance2 <= max_dist2[D.Detect.ENCHANTMENT]
				and checkInventory(isEnchanted, Actor.inventory(actor))
		then
			detected(actor, D.Detect.ENCHANTMENT)
		end
		if distance2 <= max_dist2[D.Detect.KEY]
				and checkInventory(isKey, Actor.inventory(actor))
		then
			detected(actor, D.Detect.KEY)
		end
		if distance2 <= max_dist2[D.Detect.ANIMAL]
				and isAnimal(actor)
		then
			detected(actor, D.Detect.ANIMAL)
		end
	end
end

local function testContainer(container, max_dist2)
	local distance2 = (self.position - container.position):length2()
	if distance2 <= max_dist2[D.Detect.ENCHANTMENT]
			and checkInventory(isEnchanted, Container.content(container))
	then
		detected(container, D.Detect.ENCHANTMENT)
	end
	if distance2 <= max_dist2[D.Detect.KEY]
			and checkInventory(isKey, Container.content(container))
	then
		detected(container, D.Detect.KEY)
	end
end

local frame_counter = 0
local function onUpdate(dt)
	local effects = Actor.activeEffects(self)
	local enchant_mag = effects:getEffect(core.magic.EFFECT_TYPE.DetectEnchantment).magnitude
	local key_mag = effects:getEffect(core.magic.EFFECT_TYPE.DetectKey).magnitude
	local animal_mag = effects:getEffect(core.magic.EFFECT_TYPE.DetectAnimal).magnitude
	local max_dist2 = {
		[D.Detect.ENCHANTMENT] = enchant_mag * enchant_mag * UnitsPerFeet * UnitsPerFeet,
		[D.Detect.KEY] = key_mag * key_mag * UnitsPerFeet * UnitsPerFeet,
		[D.Detect.ANIMAL] = animal_mag * animal_mag * UnitsPerFeet * UnitsPerFeet,
	}

	local detect_items = enchant_mag > 0 or key_mag > 0
	local detect_actors = enchant_mag > 0 or key_mag > 0 or animal_mag > 0
	
	-- Check nearby object
	if detect_items or detect_actors then
		local max_object_test = Performance:get('MaxObjectTest')
		local total_test = 0
		if detect_items then
			total_test = total_test + #nearby.items + #nearby.containers
		end
		if detect_actors then
			total_test = total_test + #nearby.actors
		end

		local frames_for_all_test = math.ceil(total_test/max_object_test)
		if frame_counter >= frames_for_all_test then
			frame_counter = 0
		end
		local start_index = 1 + frame_counter * max_object_test
		local end_index = start_index + max_object_test - 1
		--print('Check '..start_index..' - '..end_index)
		frame_counter = frame_counter + 1

		local function testList(list, test)
			if start_index <= #list and end_index >= 1 then
				--print(test, start_index, math.min(#list, end_index))
				for i = start_index, math.min(#list, end_index), 1 do
					test(list[i], max_dist2)
				end
				start_index = 1
			else
				start_index = start_index - #list
			end
			end_index = end_index - #list
		end

		-- Items
		if detect_items then
			testList(nearby.items, testItem)
		end
		-- Actors
		if detect_actors then
			testList(nearby.actors, testActor)
		end
		-- Containers
		if detect_items then
			testList(nearby.containers, testContainer)
		end
	end

	-- Update markers
	for id, marker in pairs(current_markers) do
		if marker.object:isValid()
				and marker.object.cell ~= nil and marker.object.cell:isInSameSpace(self)
				and (self.position - marker.object.position):length2() <= max_dist2[marker.type]
				and not (marker.type == D.Detect.ANIMAL and Actor.isDead(marker.object))
		then
			marker:update()
		else
			marker:destroy()
			current_markers[id] = nil
		end
	end
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
	}
}
