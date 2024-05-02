-- Batmane Notes
-- Definition of an attack
-- Completed - Means NPC is within a certain distance 


AttackTask = {}
AttackTask.__index = AttackTask

local isLocalLoggingEnabled = false;

isAttackLoggingEnabled = false

function AttackTask:new(superSurvivor)
	local o = {};
	setmetatable(o, self);
	self.__index = self;

	o.parent = superSurvivor;
	o.Name = "Attack";

	o.OnGoing = false;
	o.parent:Speak("Starting Attack");

	return o;
end

function AttackTask:isComplete()
	if 
		-- not self.parent:needToFollow() and  -- Cant continue task if need ToFollow
		(
			self.parent:getDangerSeenCount() > 0 or -- Number of killable enemies in range is greater than 0
			(self.parent:isEnemyInRange(self.parent.LastEnemySeen) -- In attack range of my weapon
				and self.parent:hasWeapon()) -- In attack range of my weapon
		)
		and self.parent.LastEnemySeen
		and not self.parent.LastEnemySeen:isDead()
		-- and self.parent:HasInjury() == false -- No longer need to handle this because first aid already prioritized
	then
		return false;
	else
		local theDistance = GetXYDistanceBetween(self.Target, self.parent.player)
		if theDistance < 1 and self.Target:getZ() == self.parent.player:getZ() then
			self.parent:StopWalk()
		end

		-- CreateLogLine("AttackTask", true, tostring(self.parent:getName()) .. " has completed attack ");
		return true;
	end
end

function AttackTask:isValid()
	if not self.parent
		or not self.parent.LastEnemySeen
		or not self.parent:isInSameRoom(self.parent.LastEnemySeen)
		or self.parent.LastEnemySeen:isDead()
	then
		return false;
	else
		return true;
	end
end

function AttackTask:update()
	CreateLogLine("AttackTask", isLocalLoggingEnabled, "function: AttackTask:update() called");
	-- CreateLogLine("AttackTask", true, tostring(self.parent:getName()) .. " has attack task");

	if not self:isValid() or self:isComplete() then return false end

	local weapon = self.parent.player:getPrimaryHandItem(); -- WIP - Cows: This is a test assignment...

	if self.parent:isWalkingPermitted() then
		self.parent:NPC_MovementManagement() -- For melee movement management

		-- Controls the Range of how far / close the NPC should be
		if self.parent:hasGun() then 			
			-- WIP - When and where was "weapon" assigned a value? This is still unassigned...
			if self.parent:needToReadyGun(weapon) then -- Despite the name, it means 'has gun in the npc's hand'
				self.parent:ReadyGun(weapon);
				return -- Batmane - Maybe this should return here if the NPC needs to ready their gun, Its not like they can actually attack
			else
				self.parent:NPC_MovementManagement_Guns() -- To move around, it checks for in attack range too
			end
		end
	end

	local theDistance = GetXYDistanceBetween(self.parent.LastEnemySeen, self.parent.player)
	local NPC_AttackRange = self.parent:isEnemyInRange(self.parent.LastEnemySeen)

	-- Controls if the NPC is litreally running or walking state.
	self.parent:NPC_ShouldRunOrWalk();

	if NPC_AttackRange or (theDistance < 0.65
		and self.parent.LastEnemySeen:getZ() == self.parent.player:getZ()) 
	then
		local weapon = self.parent.player:getPrimaryHandItem()
		if 
			-- not weapon or-- Batmane - Why????
			not self.parent:usingGun() -- Using Melee
			or ISReloadWeaponAction.canShoot(weapon) -- Using Gun
		then
			if self.parent:hasGun() then -- Gun related conditions
				if self.parent:needToReadyGun(weapon) then		
					self.parent:ReadyGun(weapon);
				else
					self.parent:AttackWithGun(self.parent.LastEnemySeen);
				end
			-- Trigger Melee Preparation followed by Melee Attack
			else
				self.parent:AttackWithMelee(self.parent.LastEnemySeen);
			end

			-- Batmane this probably also breaks the ai
			if instanceof(self.parent.LastEnemySeen, "IsoPlayer") then
				self.parent:Wait(1); -- Change from 5
			end
		-- Using gun but cannot ready weapon so equip melee
		elseif self.parent:usingGun() then
			if self.parent:ReadyGun(weapon) == false 
		then 
			self.parent:reEquipMelee() 
		end
			self.parent:Wait(1);
		end
	elseif self.parent:isWalkingPermitted() then
		self.parent:NPC_ManageLockedDoors(); -- To prevent getting stuck in doors
	else
		CreateLogLine("AttackTask", true, "AttackTask:update() - something is wrong");
	end
	return true;
end
