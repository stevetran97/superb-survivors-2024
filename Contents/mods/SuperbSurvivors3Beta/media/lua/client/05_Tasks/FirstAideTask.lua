FirstAideTask = {}
FirstAideTask.__index = FirstAideTask

local isLocalLoggingEnabled = false;

function FirstAideTask:new(superSurvivor)
	CreateLogLine("FirstAideTask", isLocalLoggingEnabled, "function: FirstAideTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "First Aide"
	o.OnGoing = false
	o.parent:StopWalk()
	o.myTimedAction = nil
	o.Ticks = 0
	o.WorkingBP = nil
	o.WorkingItem = nil
	return o
end

function FirstAideTask:isComplete()
	if self.parent:HasInjury() then
		return false
	else
		return true
	end
end

function FirstAideTask:isValid()
	CreateLogLine("FirstAideTask", isLocalLoggingEnabled, "function: FirstAideTask:isValid() called");
	if not self.parent:HasInjury() then
		CreateLogLine("FirstAideTask", isLocalLoggingEnabled, self.parent:getName() .. ": First aide task not valid");
		return false
	else
		return true
	end
end

function FirstAideTask:update()
	CreateLogLine("FirstAideTask", isLocalLoggingEnabled, "function: FirstAideTask:update() called");
	if not self:isValid() then return false end
	if not self.parent:isInAction() == false then return false end

	local bodyparts = self.parent.player:getBodyDamage():getBodyParts()

	for i = 0, bodyparts:size() - 1 do
		local bp = bodyparts:get(i)
		if bp:HasInjury() and bp:bandaged() == false then
			self.WorkingBP = bp
			self.parent:RoleplaySpeak(Get_SS_UIActionText("BandageBP_Before") ..
				tostring(BodyPartType.getDisplayName(bp:getType())) .. Get_SS_UIActionText("BandageBP_After"))
			local item
			item = self.parent.player:getInventory():getItemFromType("RippedSheets")
			if item == nil then item = self.parent.player:getInventory():AddItem("Base.RippedSheets") end
			self.WorkingItem = item;
			self.parent:StopWalk()
			self.myTimedAction = ISApplyBandage:new(self.parent.player, self.parent.player, item, bp, true)
			ISTimedActionQueue.add(self.myTimedAction)
			break
		end
	end

	if (self.Ticks == nil) then self.Ticks = 0 end -- hack job fix to overcome characters freezing and not performing timed actions
	self.Ticks = self.Ticks + 1
	if (self.Ticks == 10) then
		local playerObj = self.parent:Get()
		if (playerObj.setAnimVariable ~= nil) then
			playerObj:setAnimVariable("BandageType", "UpperBody")
			playerObj:setOverrideHandModels(nil, nil);
		end
	elseif (self.Ticks > 20) then
		self.parent:Get():getBodyDamage():SetBandaged(self.WorkingBP:getIndex(), true, 50, self.WorkingItem:isAlcoholic(),
			self.WorkingItem:getModule() .. "." .. self.WorkingItem:getType());
		self.parent:Get():getInventory():Remove(self.item)
		self.Ticks = 0
	end
end
