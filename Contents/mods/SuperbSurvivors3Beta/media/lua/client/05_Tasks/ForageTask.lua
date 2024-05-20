ForageTask = {}
ForageTask.__index = ForageTask

local isLocalLoggingEnabled = false;

function ForageTask:new(superSurvivor)
	CreateLogLine("ForageTask", isLocalLoggingEnabled, "function: ForageTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.group = superSurvivor:getGroup()
	o.Name = "Forage"
	o.OnGoing = false
	o.Complete = false
	o.ForagedCount = 0

	return o
end

function ForageTask:isComplete()
	return self.Complete
end

function ForageTask:isValid()
	return true
end

function ForageTask:update()
	if (not self:isValid()) then return false end

	if (self.parent:isInAction() == false) then
		local player = self.parent:Get()
		if (player:getModData().Toggle == nil) then player:getModData().Toggle = false end

		if (player:getModData().Toggle) then
			if (player:getCurrentSquare():getZoneType() == "Forest") or (player:getCurrentSquare():getZoneType() == "DeepForest") then
				local options = {};
				options["Insects"] = true;
				options["Mushrooms"] = true;
				options["Berries"] = true;
				options["MedicinalPlants"] = true;
				options["ForestGoods"] = true;
				ISTimedActionQueue.add(ISNPCScavengeAction:new(player, player:getCurrentSquare():getZone(), options));
				self.parent:RoleplaySpeak(Get_SS_UIActionText("Foraging"));
			else
				self.parent:Speak(Get_SS_UIActionText("NoForagingHere") ..
				"(" .. tostring(player:getCurrentSquare():getZoneType()) .. ")");
				if (self.group ~= nil) then
					local forage = self.group:getGroupAreaCenterSquare("ForageArea")
					if (forage ~= nil) then
						self.parent:walkTo(forage)
					end
				end
			end
			self.ForagedCount = self.ForagedCount + 1
		else
			local tempx = player:getX() + ZombRand(-2, 2);
			local tempy = player:getY() + ZombRand(-2, 2);
			local sq = getCell():getGridSquare(tempx, tempy, player:getZ());
			if (sq ~= nil) then
				player:StopAllActionQueue();
				self.parent:walkTo(sq);
			end
		end

		player:getModData().Toggle = not player:getModData().Toggle;
		if (self.ForagedCount > 25) then
			self.parent:Speak(Get_SS_DialogueSpeech("Tired"))
			self.Complete = true
		end
	end
end
