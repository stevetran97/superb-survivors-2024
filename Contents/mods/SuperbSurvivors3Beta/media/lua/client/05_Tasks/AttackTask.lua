-- Batmane Notes
-- Definition of an attack
-- Completed - Means NPC is within a certain distance 

isAttackCallLogged = false

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
		self.parent:getDangerSeenCount() <= 0 
	then 
		return true  
	end
	CreateLogLine("Attack Task", isAttackCallLogged, tostring(self.parent:getName()) .. " has attack NOT COMPLETE ");

	return false
end

function AttackTask:isValid()
	if not self.parent.LastEnemySeen or
		self.parent.LastEnemySeen:isDead() or
		not self.parent:RealCanSee(self.parent.LastEnemySeen)
	then 
		return false 
	end
	CreateLogLine("Attack Task", isAttackCallLogged, tostring(self.parent:getName()) .. " has valid attack ");

	return true;
end

function AttackTask:update()
	CreateLogLine("AttackTask", isLocalLoggingEnabled, "function: AttackTask:update() called");
	CreateLogLine("AttackTask", isAttackCallLogged, tostring(self.parent:getName()) .. " has attack task");

	if not self:isValid() or self:isComplete() then return false end

	local weapon = self.parent.player:getPrimaryHandItem(); -- WIP - Cows: This is a test assignment...

	if not weapon then return end

	-- Handle Movement and Readying Weapon
	-- Walk to and Walk away etc.
	if self.parent:hasGun() then
		self.parent:NPC_MovementManagement_Guns() -- To move around, it checks for in attack range too

		if self.parent:needToReadyGun(weapon) and self.parent.EnemiesOnMe <= 0 then -- Despite the name, it means 'has gun in the npc's hand'
			local ableToReadyGun = self.parent:ReadyGun(weapon);
			if not ableToReadyGun then self.parent:reEquipMelee() end
			return -- Batmane - Maybe this should return here if the NPC needs to ready their gun, Its not like they can actually attack
		end
	else
		self.parent:NPC_MovementManagement_Melee() -- For melee movement management
	end

	-- Controls if the NPC is litreally running or walking state.
	self.parent:NPC_ShouldRunOrWalk();

	local NPC_AttackRange = self.parent:isEnemyInRange(self.parent.LastEnemySeen)
	local theDistance = self.parent.LastEnemySeenDistance
	if not theDistance then 
		theDistance = GetXYDistanceBetween(self.parent.LastEnemySeen, self.parent.player)
	end

	if NPC_AttackRange or
		(theDistance < 0.65
		and self.parent.LastEnemySeen:getZ() == self.parent.player:getZ()) 
	then 
		-- Gun related conditions
		if self.parent:hasGun() then
			self.parent:AttackWithGun(self.parent.LastEnemySeen);
		-- Trigger Melee Preparation followed by Melee Attack
		else
			self.parent:AttackWithMelee(self.parent.LastEnemySeen);
		end
	end


	-- if NPC_AttackRange or (theDistance < 0.65
	-- 	and self.parent.LastEnemySeen:getZ() == self.parent.player:getZ()) 
	-- then
	-- 	local weapon = self.parent.player:getPrimaryHandItem()
	-- 	if 
	-- 		-- not weapon or-- Batmane - Why????
	-- 		not self.parent:usingGun() -- Using Melee
	-- 		or ISReloadWeaponAction.canShoot(weapon) -- Using Gun
	-- 	then
	-- 		if self.parent:hasGun() then -- Gun related conditions
	-- 			if self.parent:needToReadyGun(weapon) then		
	-- 				self.parent:ReadyGun(weapon);
	-- 			else
	-- 				self.parent:AttackWithGun(self.parent.LastEnemySeen);
	-- 			end
	-- 		-- Trigger Melee Preparation followed by Melee Attack
	-- 		else
	-- 			self.parent:AttackWithMelee(self.parent.LastEnemySeen);
	-- 		end

	-- 		-- Batmane this probably also breaks the ai
	-- 		if instanceof(self.parent.LastEnemySeen, "IsoPlayer") then
	-- 			self.parent:Wait(1); -- Change from 5
	-- 		end
	-- 	-- Using gun but cannot ready weapon so equip melee
	-- 	elseif self.parent:usingGun() then
	-- 		if self.parent:ReadyGun(weapon) == false 
	-- 	then 
	-- 		self.parent:reEquipMelee() 
	-- 	end
	-- 		self.parent:Wait(1);
	-- 	end
	-- elseif self.parent:isWalkingPermitted() then
	-- 	self.parent:NPC_ManageLockedDoors(); -- To prevent getting stuck in doors
	-- else
	-- 	CreateLogLine("AttackTask", true, "AttackTask:update() - something is wrong");
	-- end
	return true;
end
