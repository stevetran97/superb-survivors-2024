-- Had to rename action with a 2 because ISBarricadeAction is taken and this wasnt getting called

--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISBarricadeAction2 = ISBaseTimedAction:derive("ISBarricadeAction2");

function ISBarricadeAction2:isValid()
	if not instanceof(self.item, "BarricadeAble") or self.item:getObjectIndex() == -1 then
		return false
	end
	local barricade = self.item:getBarricadeForCharacter(self.character)
	if self.isMetal then
		if barricade then
			return false
		end
		if not self.character:hasEquipped("BlowTorch") or not self.character:hasEquipped("SheetMetal") then
			return false
        end
    elseif self.isMetalBar then
        if barricade then
            return false
        end
        if not self.character:hasEquipped("BlowTorch") or not self.character:hasEquipped("MetalBar") then
            return false
        end
		if self.character:getInventory():getItemCount("Base.MetalBar", true) < 3 then
			return false
		end
	else
		if barricade and not barricade:canAddPlank() then
			return false
		end
		if not self.character:hasEquipped("Hammer") and not self.character:hasEquipped("HammerStone") then
			return false
		end
		if not self.character:hasEquipped("Plank") then
			return false
		end
		if not self.character:getInventory():contains("Nails", true) then
			return false
		end
	end
	if self.isStarted then
		if instanceof(self.item, "IsoDoor") or (instanceof(self.item, "IsoThumpable") and self.item:isDoor()) then
			if self.item:IsOpen() then
				return false
			end
		end
	end
	return true
end

function ISBarricadeAction2:waitToStart()
	self.character:faceThisObject(self.item)
	return self.character:shouldBeTurning()
end

function ISBarricadeAction2:update()
	CreateLogLine("Barricade BuildingTask", true, " update barricading action ");

	-- This updates dozens of times per second - consider reducing load here

	-- self.character:faceThisObject(self.item) -- Forget reorienting towards it - Performance
    -- self.character:setMetabolicTarget(Metabolics.LightWork); -- This doesnt matter because AI does not get tired yet

end

function ISBarricadeAction2:start()
	CreateLogLine("Barricade BuildingTask", true, " start barricading action ");


    if self.character:hasEquipped("BlowTorch") then
        self:setActionAnim("BlowTorch")
        self:setOverrideHandModels(self.character:getPrimaryHandItem(), nil)
        self.sound = self.character:getEmitter():playSound("BlowTorch")
        local radius = 20 * self.character:getWeldingSoundMod()
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), radius, radius)
    else
        self:setActionAnim("Build")
        self.sound = self.character:getEmitter():playSound("Hammering")
        local radius = 20 * self.character:getHammerSoundMod()
        addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), radius, radius)
    end
    if instanceof(self.item, "IsoDoor") or (instanceof(self.item, "IsoThumpable") and self.item:isDoor()) then
        if self.item:IsOpen() then
            self.item:ToggleDoor(self.character)
        end
        self.isStarted = true
    end
end

function ISBarricadeAction2:stop()
	if self.sound then
		self.character:getEmitter():stopSound(self.sound)
		self.sound = nil
	end
    ISBaseTimedAction.stop(self);
end

-- This only occurs like once every once and a while (like when it finishes)
function ISBarricadeAction2:perform()
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
	CreateLogLine("Barricade BuildingTask", true, " System performing barricade ");


	local material = self.character:getSecondaryHandItem()
	if not instanceof(material, "InventoryItem") then return end
	if isClient() then
		local obj = self.item
		local index = obj:getObjectIndex()
		local args = { x=obj:getX(), y=obj:getY(), z=obj:getZ(), index=index, isMetal=self.isMetal, isMetalBar=self.isMetalBar, itemID=material:getID(), condition=material:getCondition() }
		sendClientCommand(self.character, 'object', 'barricade', args)
	else
		CreateLogLine("Barricade BuildingTask", true, " System adding barricade to window ");

		local barricade = IsoBarricade.AddBarricadeToObject(self.item, self.character)

		CreateLogLine("Barricade BuildingTask", true, " barricade to add to object " .. tostring(barricade));


		if barricade then
			if self.isMetal then
				barricade:addMetal(self.character, material)
                self.character:getXp():AddXPNoMultiplier(Perks.MetalWelding, 6)
            elseif self.isMetalBar then
                barricade:addMetalBar(self.character, material)
                self.character:getXp():AddXPNoMultiplier(Perks.MetalWelding, 6)
			else
				CreateLogLine("Barricade BuildingTask", true, " System adding plank across window ");

				barricade:addPlank(self.character, material)
				self.character:getInventory():RemoveOneOf("Nails")
                self.character:getInventory():RemoveOneOf("Nails")
				self.character:getXp():AddXPNoMultiplier(Perks.Woodwork, 3)
			end
			self.character:getInventory():Remove(material)
            if self.isMetalBar then
                local bars = self.character:getInventory():getItemsFromFullType("Base.MetalBar", true);
                for i=0,1 do
                    if bars:get(i) then
                        local bar = bars:get(i);
                        bar:getContainer():Remove(bar);
                    end
                end
            end

            if self.isMetalBar or self.isMetal then
                self.character:getPrimaryHandItem():Use();
                self.character:getPrimaryHandItem():Use();
                self.character:getPrimaryHandItem():Use();
            end
			if self.character:getSecondaryHandItem() == material then
				self.character:setSecondaryHandItem(nil)
			end
		end
	end
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISBarricadeAction2:new(character, item, isMetal, isMetalBar, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = item;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	o.isMetal = isMetal;
    o.isMetalBar = isMetalBar;
	if character:HasTrait("Handy") then
		o.maxTime = time - 20;
    end
    if character:isTimedActionInstant() then
        o.maxTime = 1;
    end
    o.caloriesModifier = 8;



	return o;
end
