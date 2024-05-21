EquipWeaponTask = {}
EquipWeaponTask.__index = EquipWeaponTask

local isLocalLoggingEnabled = false;

function EquipWeaponTask:new(superSurvivor)
	CreateLogLine("EquipWeaponTask", isLocalLoggingEnabled, "EquipWeapon Task:new() Called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "Equip Weapon"

	o.OnGoing = true
	o.Complete = false

	return o
end

function EquipWeaponTask:isComplete()
	return self.Complete
end

function EquipWeaponTask:isValid()
	return true
end

function EquipWeaponTask:update()
	CreateLogLine('Equip Weapon', true, tostring(self.parent:getName()) .. ' Equiping weapon task ')
	if not self:isValid() then return false end
	local currentWeapon = self.parent:Get():getPrimaryHandItem()

	if currentWeapon and
		(currentWeapon:getDisplayName() == "Corpse" or 
		currentWeapon:isBroken())
	then 
		self.parent:StopWalk()
		ISTimedActionQueue.add(ISDropItemAction:new(self.parent:Get(), currentWeapon, 30))
		self.parent:Get():setPrimaryHandItem(nil); -- This unequips the corpse
		self.parent:Get():setSecondaryHandItem(nil);

		return false
	end

	if self.parent:isInAction() == false then
		local bag = self.parent:getBag()
		local inventory = self.parent.player:getInventory()

		local weapon = inventory:getBestWeapon() or bag:getBestWeapon()

		if not weapon then 
			weapon = self.parent:getWeapon() -- This code kinda handles what is done above but can be a fallback
		end

		if weapon and weapon:getMaxDamage() > 0.1 then
			self.parent:RoleplaySpeak(Get_SS_UIActionText("EquipsArmor_Before") ..
			weapon:getDisplayName() .. Get_SS_UIActionText("EquipsArmor_After"))

			self.parent.player:setPrimaryHandItem(weapon)
			if weapon:isTwoHandWeapon() then self.parent.player:setSecondaryHandItem(weapon) end
		end

		self.Complete = true
	end
end
