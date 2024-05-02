SuperSurvivorManager = {}
SuperSurvivorManager.__index = SuperSurvivorManager

local isLocalLoggingEnabled = false;

function SuperSurvivorManager:new()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.SuperSurvivors = {}
	-- o.SurvivorCount = 3
	o.MainPlayer = 0

	return o
end

function SuperSurvivorManager:getRealPlayerID()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:getRealPlayerID() called");
	return self.MainPlayer
end

function SuperSurvivorManager:init()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:init() called");
	self.SuperSurvivors[0] = SuperSurvivor:newSet(getSpecificPlayer(0))
	self.SuperSurvivors[0]:setID(0)
end

function SuperSurvivorManager:setPlayer(player, ID)
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:setPlayer() called");
	self.SuperSurvivors[ID] = SuperSurvivor:newSet(player)
	self.SuperSurvivors[0]:setID(ID)
	self.SuperSurvivors[0]:setName("Player " .. tostring(ID))

	return self.SuperSurvivors[ID];
end

-- Load survivors when the grid square they are in becomes loaded by the player
function SuperSurvivorManager:LoadSurvivor(ID, square)
	CreateLogLine("LoadSurvivor", true, "SuperSurvivorManager:Load Survivor() called");
	-- Batmane - Each survivor in your game is a seperate saved file in the save game folder
	if not checkSaveFileExists("Survivor" .. tostring(ID)) then 
		return false 
	end

	if ID ~= nil and square ~= nil then --
		if self.SuperSurvivors[ID] ~= nil and self.SuperSurvivors[ID].player ~= nil then

			-- Do not load survivor if they are already in a cell and the survivor object exists
			if self.SuperSurvivors[ID]:isInCell() then
				return false -- Batmane - Why do I return false if loading survivor and they are in a cell?
			else
				-- Batmane - Seems to delete survivor if they are not in a cell, have non nil survivor object, and non nil player
				CreateLogLine("NPC Load Survivor Management", true, "About to be Deleted survivor Name " .. tostring(self.SuperSurvivors[ID]:getName()));

				-- Batmane Attempt to make it so that same group survivors do not get deleted
				local currentGroupID = self.SuperSurvivors[ID]:getGroupID();
				local playersGroupID = self:Get(0):getGroupID()
				CreateLogLine("NPC Load Survivor Management", true, "To BE Deleted survivors group ID " .. tostring(currentGroupID));
				CreateLogLine("NPC Load Survivor Management", true, "Players Group ID " .. tostring(playersGroupID));

				-- If currentGroupID is not the playerGroups ID so as long as the player is in a group
				-- The thing is survivors often get deleted and then reloaded -- Not sure why it is done this way?
				if playersGroupID and currentGroupID == playersGroupID then
					CreateLogLine("NPC Load Survivor Management", true, " DELETE PROTECTION: Didnt delete survivor because they are in the same group as player: " .. tostring(self.SuperSurvivors[ID]));
				else
					self.SuperSurvivors[ID]:deleteSurvivor()
					CreateLogLine("NPC Load Survivor Management", true, "Deleted survivor ID " .. tostring(self.SuperSurvivors[ID]));
					self.SuperSurvivors[ID] = nil -- Batmane: If you delete the survivor then delete it from the list of alive survivors
					CreateLogLine("NPC Load Survivor Management", true, "Deleted survivor idx final = " .. tostring(self.SuperSurvivors[ID]));
				end
				-- 
			end
		end

		CreateLogLine("NPC Load Survivor Management", true, "Passed first check block ");

		self.SuperSurvivors[ID] = SuperSurvivor:newLoad(ID, square)

		if (self.SuperSurvivors[ID]:Get():getPrimaryHandItem() == nil) and (self.SuperSurvivors[ID]:getWeapon() ~= nil) then
			self.SuperSurvivors[ID]:Get():setPrimaryHandItem(self.SuperSurvivors[ID]:getWeapon())
		end

		self.SuperSurvivors[ID]:refreshName()

		if (self.SuperSurvivors[ID]:Get():getModData().isHostile == true) then
			self.SuperSurvivors[ID]:setHostile(true)
		end

		-- Old Logic to count number of survivors - No longer needed - it was phased out
		-- if (self.SurvivorCount == nil) then
		-- 	self.SurvivorCount = 1
		-- end

		-- if (ID > self.SurvivorCount) then
		-- 	self.SurvivorCount = ID;
		-- end
		-- 

		self.SuperSurvivors[ID].player:getModData().LastSquareSaveX = nil
		self.SuperSurvivors[ID]:SaveSurvivor()

		local meleewep = self.SuperSurvivors[ID].player:getModData().meleeWeapon
		local gunwep = self.SuperSurvivors[ID].player:getModData().gunWeapon

		if meleewep ~= nil then
			self.SuperSurvivors[ID].LastMeleeUsed = self.SuperSurvivors[ID].player:getInventory():FindAndReturn(meleewep)
			if not self.SuperSurvivors[ID].LastMeleeUsed then
				self.SuperSurvivors[ID].LastMeleeUsed = self.SuperSurvivors[ID]:getBag():FindAndReturn(meleewep)
			end
		end

		if gunwep ~= nil then
			self.SuperSurvivors[ID].LastGunUsed = self.SuperSurvivors[ID].player:getInventory():FindAndReturn(gunwep)
			if not self.SuperSurvivors[ID].LastGunUsed then
				self.SuperSurvivors[ID].LastGunUsed = self.SuperSurvivors[ID]:getBag():FindAndReturn(gunwep)
			end
		end

		if (self.SuperSurvivors[ID]:getAIMode() == "Follow") then
			self.SuperSurvivors[ID]:getTaskManager():AddToTop(FollowTask:new(self.SuperSurvivors[ID], nil))
		elseif (self.SuperSurvivors[ID]:getAIMode() == "Guard") then
			if self.SuperSurvivors[ID]:getGroup() ~= nil then
				local area = self.SuperSurvivors[ID]:getGroup():getGroupArea("GuardArea")
				if (area) then
					self.SuperSurvivors[ID]:getTaskManager():AddToTop(WanderInAreaTask:new(self.SuperSurvivors[ID], area))
					self.SuperSurvivors[ID]:getTaskManager():setTaskUpdateLimit(10)
				else
					self.SuperSurvivors[ID]:getTaskManager():AddToTop(GuardTask:new(self.SuperSurvivors[ID],
						self.SuperSurvivors[ID].player:getCurrentSquare()))
				end
			end
		elseif (self.SuperSurvivors[ID]:getAIMode() == "Patrol") then
			self.SuperSurvivors[ID]:getTaskManager():AddToTop(PatrolTask:new(self.SuperSurvivors[ID], nil, nil))
		elseif (self.SuperSurvivors[ID]:getAIMode() == "Wander") then
			self.SuperSurvivors[ID]:getTaskManager():AddToTop(WanderTask:new(self.SuperSurvivors[ID]))
		elseif self.SuperSurvivors[ID]:getAIMode() == "Stand Ground" then
			ASuperSurvivor:Speak("I will stand my ground here and guard")
			self.SuperSurvivors[ID]:getTaskManager():AddToTop(GuardTask:new(self.SuperSurvivors[ID],
				self.SuperSurvivors[ID].player:getCurrentSquare()))
			self.SuperSurvivors[ID]:setWalkingPermitted(false)
		elseif (self.SuperSurvivors[ID]:getAIMode() == "Doctor") then
			self.SuperSurvivors[ID]:getTaskManager():AddToTop(DoctorTask:new(self.SuperSurvivors[ID]))
		end


		local phi = self.SuperSurvivors[ID]:Get():getPrimaryHandItem() -- to trigger onEquipPrimary
		self.SuperSurvivors[ID]:Get():setPrimaryHandItem(nil)
		self.SuperSurvivors[ID]:Get():setPrimaryHandItem(phi)

		CreateLogLine("NPC Load Survivor Management", true, "Reloaded Survivor survivor Name " .. tostring(self.SuperSurvivors[ID]:getName()));
	end
end

function SuperSurvivorManager:spawnSurvivor(isFemale, square)
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:spawn Survivor() called");
	if square ~= nil then
		local newSurvivor = SuperSurvivor:newSurvivor(isFemale, square)
		if not newSurvivor then return nil end

		-- Replaced Iteration
		for idx = 1, Limit_Npcs_Spawn + 10, 1 do
			CreateLogLine("Spawn Survivor", true, "Looping to find idx to spawn surivor " .. tostring(idx));
			if not self.SuperSurvivors[idx] then
				CreateLogLine("Spawn Survivor", true, "Found empty idx at " .. tostring(idx));
				self.SuperSurvivors[idx] = newSurvivor
				self.SuperSurvivors[idx]:setID(idx)
				CreateLogLine("Spawn Survivor", true, "New Survivor " .. tostring(self.SuperSurvivors[idx]));
				return self.SuperSurvivors[idx]
			end
		end
		-- 
		CreateLogLine("Error", true, "Error spawning New Survivor: could not find empty idx to spawn survivor... ");

		-- Old Assignment or survivor to survivor list -- 
		-- self.SuperSurvivors[self.SurvivorCount + 1] = newSurvivor
		-- self.SurvivorCount = self.SurvivorCount + 1;
		-- self.SuperSurvivors[self.SurvivorCount]:setID(self.SurvivorCount)
		-- 
		-- return self.SuperSurvivors[self.SurvivorCount]
	end
end

function SuperSurvivorManager:Get(thisID)
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:Get() called");
	if not self.SuperSurvivors[thisID] then
		return nil
	else
		return self.SuperSurvivors[thisID]
	end
end

function SuperSurvivorManager:OnDeath(ID)
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:On Death() called");

	if not self.SuperSurvivors[ID] then return end
	-- CreateLogLine("Test On Death", true, "SSM is handling dead player.");
	
	if not self.SuperSurvivors[ID].player:shouldBecomeZombieAfterDeath() then 
		CreateLogLine("OnDeath", true, tostring(self.SuperSurvivors[ID]:getName()) .. ' is becoming a corpse');
		self.SuperSurvivors[ID].player:becomeCorpse() 
	end-- Batmane Test - Turn Dead NPC into corpse -- Not activated yet

	CreateLogLine("OnDeath", true, tostring(self.SuperSurvivors[ID]:getName()) .. ' is becoming getting nilled');
	self.SuperSurvivors[ID] = nil
end

-- Continuous Status Updation Functions
function SuperSurvivorManager:UpdateSurvivorsRoutine()
	-- for i = 1, self.SurvivorCount + 1 do -- Old function - Batmane: Im shocked that this is coded this way. Each ai that lived in the survivor adds one more instance to this routine check that has to run
	-- Batmane Should skip i == 0 because thats player 1
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and self.MainPlayer ~= i then
			if SuperSurvivorObj:updateTime()
				and not SuperSurvivorObj.player:isAsleep()
				and SuperSurvivorObj:isInCell()
			then
				SuperSurvivorObj:updateSurvivorStatus();

				-- Batmane - Guys are standing around and doing nothing. Need to spam this as a fix for now - Runs every 2s when FPS = 60
				-- Cows: Have the npcs wander if there are no tasks, otherwise they are stuck in place...
				if SuperSurvivorObj:getCurrentTask() == "None"
					and SurvivorRoles[SuperSurvivorObj:getGroupRole()] == nil -- Cows: This check is to ensure actual assigned roles do not wander off to die.
				then
					SuperSurvivorObj:NPCTask_DoWander();
				end
				-- 
			end
		end
	end
end

function SuperSurvivorManager:UpdateSurvivorsDailyRoutine()
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and self.MainPlayer ~= i then
			if not SuperSurvivorObj.player:isAsleep()
				and SuperSurvivorObj:isInCell()
			then
				SuperSurvivorObj:updateSurvivorDailyStatus();
			end
		end
	end
end

function SuperSurvivorManager:UpdateSurvivorsHourlyRoutine()
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and self.MainPlayer ~= i then
			if not SuperSurvivorObj.player:isAsleep()
				and SuperSurvivorObj:isInCell()
			then
				SuperSurvivorObj:updateSurvivorHourlyStatus();
			end
		end
	end
end

function SuperSurvivorManager:UpdateSurvivors10MinRoutine()
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and self.MainPlayer ~= i then
			if not SuperSurvivorObj.player:isAsleep()
				and SuperSurvivorObj:isInCell()
			then
				SuperSurvivorObj:updateSurvivor10MinStatus();
			end
		end
	end
end


---comment
function SuperSurvivorManager:AsleepHealAll()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:AsleepHealAll() called");
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and self.MainPlayer ~= i and SuperSurvivorObj.player then
			SuperSurvivorObj.player:getBodyDamage():AddGeneralHealth(SleepGeneralHealRate);
		end
	end
end

function SuperSurvivorManager:PublicExecution(SSW, SSV)
	CreateLogLine("SuperSurvivorManager", isFleeCallLogged, "function: PublicExecution() called");
	local maxdistance = 20

	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and SuperSurvivorObj:isInCell() then
			local distance = GetXYDistanceBetween(SuperSurvivorObj:Get(), getSpecificPlayer(0))
			if (distance < maxdistance) and (SuperSurvivorObj:Get():CanSee(SSV:Get())) then
				if (not SuperSurvivorObj:isInGroup(SSW:Get()) and not SuperSurvivorObj:isInGroup(SSV:Get())) then
					if (SuperSurvivorObj:usingGun()) and (ZombRand(2) == 1) then
						--chance to attack with gun if see someone near by get executed
						SuperSurvivorObj:Get():getModData().hitByCharacter = true
					else
						-- flee from the crazy murderer						
						SuperSurvivorObj:getTaskManager():AddToTop(FleeFromHereTask:new(SuperSurvivorObj,
							SSW:Get():getCurrentSquare()))
					end
					SuperSurvivorObj:SpokeTo(SSW:Get():getModData().ID)
					SuperSurvivorObj:SpokeTo(SSV:Get():getModData().ID)
				end
			end
		end
	end
end

function SuperSurvivorManager:GunShotHandle(SSW)
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:GunShotHandle() called");
	local maxdistance = 20
	local weapon = getSpecificPlayer(0):getPrimaryHandItem()

	if not weapon then return false end

	local range = weapon:getSoundRadius();
	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and SuperSurvivorObj:isInCell() then
			local distance = GetDistanceBetween(SuperSurvivorObj:Get(), getSpecificPlayer(0))

			if (SuperSurvivorObj.player:getModData().surender)
				and (distance < maxdistance)
				and SuperSurvivorObj:Get():CanSee(SSW:Get())
				and SuperSurvivorObj.player:CanSee(getSpecificPlayer(0))
			then
				SuperSurvivorObj:getTaskManager():AddToTop(FleeFromHereTask:new(SuperSurvivorObj,
					SSW:Get():getCurrentSquare()))
				SuperSurvivorObj:SpokeTo(SSW:Get():getModData().ID)
			end

			if (SuperSurvivorObj.player:getModData().isHostile
					or SuperSurvivorObj:getCurrentTask() == "Guard"
					or SuperSurvivorObj:getCurrentTask() == "Patrol")
				and SuperSurvivorObj:getTaskManager():getCurrentTask() ~= "Surender"
				and not SuperSurvivorObj.player:isDead()
				and not SuperSurvivorObj:RealCanSee(getSpecificPlayer(0))
				and (GetDistanceBetween(getSpecificPlayer(0), SuperSurvivorObj.player) <= range)
			then
				SuperSurvivorObj:getTaskManager():AddToTop(GoCheckItOutTask:new(SuperSurvivorObj,
					getSpecificPlayer(0):getCurrentSquare()))
			end
		end
	end
end

function SuperSurvivorManager:GetClosest()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:GetClosest() called");
	local closestSoFar = 20
	local closestID = 0

	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and SuperSurvivorObj:isInCell() then
			local distance = GetDistanceBetween(SuperSurvivorObj:Get(), getSpecificPlayer(0))
			if (distance < closestSoFar) then
				closestID = i
				closestSoFar = distance
			end
		end
	end

	if (closestID ~= 0) then
		return self.SuperSurvivors[closestID]
	else
		return nil
	end
end

function SuperSurvivorManager:GetClosestNonParty()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:GetClosestNonParty() called");
	local closestSoFar = 20;
	local closestID = 0;

	for i, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if i ~= 0 and SuperSurvivorObj ~= nil and SuperSurvivorObj:isInCell() then
			local distance = GetDistanceBetween(SuperSurvivorObj:Get(), getSpecificPlayer(0));
			if (distance < closestSoFar) and (SuperSurvivorObj:getGroupID() == nil) then
				closestID = i;
				closestSoFar = distance;
			end
		end
	end

	if (closestID ~= 0) then
		return self.SuperSurvivors[closestID];
	else
		return nil;
	end
end

function SuperSurvivorManager:SaveAll()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:SaveAll() called");

	-- Need to experiment to see if I can get away with just counting survivors using: #self.SuperSurvivors
	for key, SuperSurvivorObj in pairs(self.SuperSurvivors) do
		if key ~= 0 then  -- 0 might be player 1
			if SuperSurvivorObj and SuperSurvivorObj:isInCell() then SuperSurvivorObj:SaveSurvivor() end
		end
	end

	-- Batmane - the old dev followed a self counting system. The number of all survivors are kept and grow this array forever. This is another memory leak
	-- Replace this function with above so we dont infinitely loop over larger and larger functions
	-- for i = 0, self.SurvivorCount + 1 do
	-- 	if SuperSurvivorObj ~= nil and SuperSurvivorObj:isInCell() then
	-- 		SuperSurvivorObj:SaveSurvivor()
	-- 	end
	-- end
end

SSM = SuperSurvivorManager:new()

function LoadSurvivorMap()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:LoadSurvivorMap() called");
	local tempTable = {}
	tempTable = table.load("SurvivorManagerInfo");

	if (tempTable) and (tempTable[1]) then
		SSM.SurvivorCount = tonumber(tempTable[1]);
		-- SSM.SurvivorCount = #SSM.SuperSurvivors
	else
		CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "LoadSurvivorMap Failed, possibly corrupted");
	end

	SurvivorLocX = KVTableLoad("SurvivorLocX")
	SurvivorLocY = KVTableLoad("SurvivorLocY")
	SurvivorLocZ = KVTableLoad("SurvivorLocZ")

	local fileTable = {}

	for k, v in pairs(SurvivorLocX) do --- trying new way of saving & loading survivor map
		local key = SurvivorLocX[k] .. SurvivorLocY[k] .. SurvivorLocZ[k]

		if (not fileTable[key]) then
			fileTable[key] = {}
		end

		table.insert(fileTable[key], tonumber(k))
	end

	return fileTable
end

function SaveSurvivorMap()
	CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:SaveSurvivorMap() called");
	local tempTable = {}
	tempTable[1] = SSM.SurvivorCount
	table.save(tempTable, "SurvivorManagerInfo");

	if not SurvivorMap then return false end

	KVTablesave(SurvivorLocX, "SurvivorLocX");
	KVTablesave(SurvivorLocY, "SurvivorLocY");
	KVTablesave(SurvivorLocZ, "SurvivorLocZ");
end
