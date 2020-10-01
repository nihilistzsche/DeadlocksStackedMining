-- safely get the value of a setting 
local function getSettingValue(optionName)
    if settings["startup"] and settings["startup"][optionName] and settings["startup"][optionName].value then
		return settings["startup"][optionName].value
    end
    return false
end

-- get the stack size from Deadlock's Stacking settings or from this mod if the option is enabled
local stackSize
if getSettingValue("kyth-overwrite-deadlock-stack-size") == "disabled" then
    stackSize =  tonumber(getSettingValue("deadlock-stack-size"))
else 
    stackSize =  tonumber(getSettingValue("kyth-overwrite-deadlock-stack-size"))
end

local compressionRate = getSettingValue("fluid-compression-rate")

---------------------------------------------------------------------------------------------------

local function isOreStacked(entity)
    -- string.find returns 1 if the name starts with "stacked-" (for position)
    return string.find(entity.name, "stacked%-") == 1
end

local function isFluidResourceCompressed(entity)
    -- string.find returns 1 if the name starts with "stacked-" (for position)
    return string.find(entity.name, "high%-pressure%-") == 1
end

local function convertEntity(entity, newName, convertToStacked)
	local newSurface = entity.surface
	local newPosition = entity.position
	local newForce = entity.force
    local newAmount = entity.amount
    -- only change the amount for non infinite resources
    if not game.entity_prototypes[entity.name].infinite_resource then
        if convertToStacked then
            newAmount = math.ceil(entity.amount/stackSize)
        else
            newAmount = math.floor(entity.amount*stackSize)
        end
    end
    -- replace the entity with a new entity
	entity.destroy()
    newSurface.create_entity(
    {
        name = newName,
        position = newPosition, 
        force = newForce, 
        amount = newAmount
	})
end

local function markOres(player, entities)
	for _, entity in pairs(entities) do
		if entity.valid then
			if entity.type == "resource" then
                if game.entity_prototypes[entity.name].resource_category == "basic-solid" or game.entity_prototypes[entity.name].resource_category == "kr-quarry" then
					if not isOreStacked(entity) then
						convertEntity(entity, "stacked-" .. entity.name, true)
                    end
                -- Support for Pressurized fluids
                elseif game.active_mods["CompressedFluids"] and (game.entity_prototypes[entity.name].resource_category == "basic-fluid" or game.entity_prototypes[entity.name].resource_category == "oil" or game.entity_prototypes[entity.name].resource_category == "angels-fissure") then
                    if not isFluidResourceCompressed(entity) then
						convertEntity(entity, "high-pressure-" .. entity.name, true)
                    end
                -- Support for Cursed Filter Mining Drill   
                elseif game.active_mods["Cursed-FMD"] and game.entity_prototypes[entity.name] and game.entity_prototypes[entity.name].mineable_properties.products[1].type == "item" and game.entity_prototypes[entity.name].resource_category == entity.name then
                    if not isOreStacked(entity) then
						convertEntity(entity, "stacked-" .. entity.name, true)
					end
                -- Support for Cursed Filter Mining Drill
                elseif game.active_mods["Cursed-FMD"] and game.active_mods["CompressedFluids"] and game.entity_prototypes[entity.name] and game.entity_prototypes[entity.name].mineable_properties.products[1].type == "fluid" and game.entity_prototypes[entity.name].resource_category == entity.name then
                    if not isFluidResourceCompressed(entity) then
						convertEntity(entity, "high-pressure-" .. entity.name, true)
                    end
                end 
			end	
		else
			player.print("Found an invalid entity!")
		end		
	end
end

local function unmarkOres(player, entities)
	for _, entity in pairs(entities) do
		if entity.valid then
			if entity.type == "resource" then
				if game.entity_prototypes[entity.name].resource_category == "basic-solid" or game.entity_prototypes[entity.name].resource_category == "kr-quarry" then
					if isOreStacked(entity) then
						convertEntity(entity, string.gsub(entity.name, "stacked%-", ""), false)
                    end
                -- Support for Pressurized fluids
				elseif game.active_mods["CompressedFluids"] and (game.entity_prototypes[entity.name].resource_category == "basic-fluid" or game.entity_prototypes[entity.name].resource_category == "oil" or game.entity_prototypes[entity.name].resource_category == "angels-fissure") then
                    if isFluidResourceCompressed(entity) then
                        convertEntity(entity, string.gsub(entity.name, "high%-pressure%-", ""), false)
                    end
                -- Support for Cursed Filter Mining Drill
                elseif game.active_mods["Cursed-FMD"] and game.entity_prototypes[entity.name] and game.entity_prototypes[entity.name].mineable_properties.products[1].type == "item" and game.entity_prototypes[entity.name].resource_category == entity.name then
                    if isOreStacked(entity) then
						convertEntity(entity, string.gsub(entity.name, "stacked%-", ""), false)
                    end
                -- Support for Cursed Filter Mining Drill
                elseif game.active_mods["Cursed-FMD"] and game.active_mods["CompressedFluids"] and game.entity_prototypes[entity.name] and game.entity_prototypes[entity.name].mineable_properties.products[1].type == "fluid" and game.entity_prototypes[entity.name].resource_category == entity.name then
                    if isFluidResourceCompressed(entity) then
                        convertEntity(entity, string.gsub(entity.name, "high%-pressure%-", ""), false)
                    end
                end 
			end	
		else
			player.print("Found an invalid entity!")
		end		
	end
end

local function remove_stacked_mining_planner_ground(event)
    local item_on_ground = event.entity
    if item_on_ground and item_on_ground.valid and item_on_ground.stack then
        local item_name = item_on_ground.stack.name
        if item_name == "stacked-mining-planner" then
            item_on_ground.destroy()
        end
    end
end

---------------------------------------------------------------------------------------------------

script.on_event(defines.events.on_player_selected_area, function(event)
	if event.item == "stacked-mining-planner" then
		local player = game.players[event.player_index]
		markOres(player, event.entities)
	end
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
	if event.item == "stacked-mining-planner" then
		local player = game.players[event.player_index]
		unmarkOres(player, event.entities)
	end
end)

script.on_event(defines.events.on_player_dropped_item, function(event)
	remove_stacked_mining_planner_ground(event)
end)

--[[
script.on_init(function(event)
	local player = game.players[event.player_index]
	player.set_shortcut_available("give-stacked-mining-planner", false)
end)


script.on_init(function()
	local player = game.players[1]
	player.set_shortcut_available("give-stacked-mining-planner", false)
end)

--]]