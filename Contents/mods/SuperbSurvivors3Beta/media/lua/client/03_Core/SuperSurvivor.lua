require "03_Core/SuperSurvivorNames";
require "04_DataManagementt.SuperSurvivorManager";      -- Cows: TODO: Remove all dependencies on SSM.
require "04_DataManagementt.SuperSurvivorGroupManager"; -- Cows: TODO: Remove all dependencies on SSGM.
-- Cows: TODO: Remove and rework the TaskManager.
-- Cows: TODO: A ton of the "NPC_<action>" is... actually also like a task... basically needs an overhaul.

local isLocalLoggingEnabled = false;
survivorStuckCheck = true

SuperSurvivor = {}
SuperSurvivor.__index = SuperSurvivor

--- Cows: The SuperSurvivor:newSurvivor(), :newLoad(), newSet() shared about 50 identical properties... there was no reason to duplicate all that.
---@return table
function SuperSurvivor:CreateBaseSurvivorObject()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:CreateBaseSurvivorObject() called");
	local survivorObject = {};
	setmetatable(survivorObject, self)
	self.__index = self;

	survivorObject.SwipeStateTicks = 0 -- used to check if survivor stuck in the same animation frame
	survivorObject.AttackRange = 0.5;
	survivorObject.UsingFullAuto = false;
	survivorObject.UpdateDelayTicks = globalPanicUpdateDelayTicks; 
	survivorObject.NumberOfBuildingsLooted = 0;
	survivorObject.GroupBraveryBonus = 0;     -- Cows: I can't find any references using GroupBraveryBonus...
	survivorObject.GroupBraveryUpdatedTicks = 0; -- Cows: I can't find any references using GroupBraveryUpdatedTicks...
	survivorObject.WaitTicks = 0;
	survivorObject.TriggerHeldDown = false;
	survivorObject.isAttacking = false; -- Determines whether user is currently attacking and whether they can start another attack


	survivorObject.AmmoTypes = {};
	survivorObject.AmmoBoxTypes = {};
	survivorObject.LastGunUsed = nil;
	survivorObject.LastMeleeUsed = nil;
	survivorObject.roundChambered = nil;
	survivorObject.TicksSinceSpoke = 0;
	survivorObject.JustSpoke = false;
	survivorObject.SayLine1 = "";

	survivorObject.LastSurvivorSeen = nil;
	survivorObject.LastMemberSeen = nil; -- Cows: I can't find any references using LastMemberSeen...
	survivorObject.TicksAtLastDetectNoFood = 0;
	survivorObject.NoFoodNear = false;
	survivorObject.TicksAtLastDetectNoWater = 0;
	survivorObject.NoWaterNear = false;
	survivorObject.GroupRole = "";
	survivorObject.seenCount = 0;
	survivorObject.dangerSeenCount = 0;
	survivorObject.LastEnemySeen = false;
	survivorObject.LastEnemySeenDistance = math.huge -- Number or nil
	survivorObject.LastEnemySeenSquare = nil

	survivorObject.distanceToPlayer0 = math.huge

	survivorObject.escapeVector = {x = 0, y = 0}
	survivorObject.Reducer = ZombRand(1, 100); -- Reducer is a counter which is used to prevent update functions from being called too often to save performance 
	survivorObject.Container = false;
	survivorObject.Room = false;            -- Cows: I can't find any references using Room...
	survivorObject.Building = false;
	survivorObject.WalkingPermitted = true;
	survivorObject.TargetBuilding = nil;
	survivorObject.TargetSquare = nil;
	survivorObject.Tree = false;
	survivorObject.LastSquare = nil;
	survivorObject.TicksSinceSquareChanged = 0;
	survivorObject.StuckDoorTicks = 0;
	survivorObject.StuckCount = 0;
	survivorObject.EnemiesOnMe = 0;
	survivorObject.BaseBuilding = nil; -- Cows: It's set, and gets... but no other functions are referencing it...

	survivorObject.GoFindThisCounter = 0;
	survivorObject.PathingCounter = 0; -- Cows: I can't find any references using PathingCounter...
	survivorObject.SpokeToRecently = {};
	survivorObject.SquareWalkToAttempts = {};
	survivorObject.SquaresExplored = {};
	survivorObject.SquareContainerSquareLooteds = {};

	return survivorObject;
end

---comment
---@param square any
---@param isFemale any
---@return unknown
function SuperSurvivor:spawnPlayer(square, isFemale)
	local isLocalFunctionLoggingEnabled = false;
	CreateLogLine("SuperSurvivor", isLocalFunctionLoggingEnabled, "SuperSurvivor:spawnPlayer() called");
	local BuddyDesc;

	CreateLogLine("SuperSurvivor", isLocalFunctionLoggingEnabled, "isFemale? " .. tostring(isFemale));
	-- Cows: Added a random roll for gender when "isFemale" is nil.
	if (isFemale == nil) then
		local rngGender = ZombRand(1, 3);
		CreateLogLine("SuperSurvivor", isLocalFunctionLoggingEnabled, "rngGender: " .. tostring(rngGender));
		if (rngGender == 1) then
			CreateLogLine("SuperSurvivor", isLocalFunctionLoggingEnabled, "spawning female npc");
			BuddyDesc = SurvivorFactory.CreateSurvivor(nil, true);
		else
			CreateLogLine("SuperSurvivor", isLocalFunctionLoggingEnabled, "spawning male npc");
			BuddyDesc = SurvivorFactory.CreateSurvivor(nil, false);
		end
	else
		BuddyDesc = SurvivorFactory.CreateSurvivor(nil, isFemale);
	end

	SurvivorFactory.randomName(BuddyDesc);

	local Z = 0;

	if (square:isSolidFloor()) then
		Z = square:getZ();
	end

	local Buddy = IsoPlayer.new(getWorld():getCell(), BuddyDesc, square:getX(), square:getY(), Z)

	Buddy:setSceneCulled(false);
	Buddy:setBlockMovement(true);
	Buddy:setNPC(true);

	-- Set the skill level of all NPCs to 10,Of course, it also includes invaders. (Evil grin). 设置所有npc的技能等级为10级,侵略者也是如此。
	if Perk_Level == true then
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Aiming", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Axe", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Combat", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "SmallBlade", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "LongBlade", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "SmallBlunt", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Blunt", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Maintenance", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Spear", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Doctor", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Farming", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Firearm", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Reloading", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Fitness", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Lightfoot", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Nimble", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "PlantScavenging", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Sneak", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Strength", 10)
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Survivalist", 10)
	else
	-- required perks ------------
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Strength", 4);
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Sneak", 2);
		Buddy = Add_SS_NpcPerkLevel(Buddy, "Lightfoot", 3);
	end

	-- random perks -------------------
	-- Cows: WIP - What is this random perks about? Maxing a random survivor's perk?
	local level = ZombRand(9, 14);
	local count = 0;

	while (count < level) do
		local aperk = Perks.FromString(GetAPerk())
		if (aperk ~= nil) and (tostring(aperk) ~= "MAX") then
			Buddy:LevelPerk(aperk);
		end
		count = count + 1;
	end

	Buddy:getTraits():add("Inconspicuous");
	Buddy:getTraits():add("Outdoorsman");
	Buddy:getTraits():add("LightEater");
	Buddy:getTraits():add("LowThirst");
	Buddy:getTraits():add("FastHealer");
	Buddy:getTraits():add("Graceful");
	Buddy:getTraits():add("IronGut");
	Buddy:getTraits():add("Lucky");
	Buddy:getTraits():add("KeenHearing");

	Buddy:getModData().bWalking = false;
	Buddy:getModData().isHostile = false;
	Buddy:getModData().RWP = SurvivorFriendliness;
	Buddy:getModData().AIMode = "Random Solo"; -- Cows: Need to evaluate the AI code when possible...

	ISTimedActionQueue.clear(Buddy);

	local nameToSet = "";

	if (Buddy:getModData().Name == nil) then
		if Buddy:isFemale() then
			nameToSet = GetRandomName("GirlNames");
		else
			nameToSet = GetRandomName("BoyNames");
		end
	else
		nameToSet = Buddy:getModData().Name;
	end

	Buddy:setForname(nameToSet);
	Buddy:setDisplayName(nameToSet);

	Buddy:getStats():setHunger((ZombRand(10) / 100));
	Buddy:getStats():setThirst((ZombRand(10) / 100));

	Buddy:getModData().Name = nameToSet;
	Buddy:getModData().NameRaw = nameToSet;

	local desc = Buddy:getDescriptor();
	desc:setForename(nameToSet);
	desc:setSurname("");

	return Buddy;
end

---comment
---@param isFemale any
---@param square any
---@return table
function SuperSurvivor:newSurvivor(isFemale, square)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:newSurvivor() called");
	local survivorObject = SuperSurvivor:CreateBaseSurvivorObject();
	setmetatable(survivorObject, self)
	self.__index = self;

	survivorObject.BravePoints = 0;
	survivorObject.Shirt = nil;
	survivorObject.Pants = nil;
	survivorObject.WasOnScreen = false;

	survivorObject.NoResultActions = {};
	survivorObject.YesResultActions = {};
	survivorObject.ContinueResultActions = {};
	survivorObject.TriggerName = "";

	survivorObject.player = survivorObject:spawnPlayer(square, isFemale);
	survivorObject.userName = TextDrawObject.new();
	survivorObject.userName:setAllowAnyImage(true);
	survivorObject.userName:setDefaultFont(UIFont.Small);
	survivorObject.userName:setDefaultColors(255, 255, 255, 255);
	survivorObject.userName:ReadString(survivorObject.player:getForname());

	survivorObject.MyTaskManager = TaskManager:new(survivorObject);

	for i = 1, #LootTypes do
		survivorObject.SquareContainerSquareLooteds[LootTypes[i]] = {};
	end

	survivorObject:setBravePoints(SurvivorBravery);
	local Dress = "RandomBasic";

	-- Dress according to the Aiming skill level
	if (survivorObject.player:getPerkLevel(Perks.FromString("Aiming")) >= 3) then
		local mapKey = ZombRand(1, 6);
		Dress = SetSurvivorDress(mapKey);
		survivorObject:giveWeapon(SetSurvivorWeapon(mapKey));
		-- else assumes "Aiming" is less than 3
	elseif (survivorObject.player:getPerkLevel(Perks.FromString("Doctor")) >= 3) then
		Dress = "Preset_Doctor";
		survivorObject:giveWeapon(SetSurvivorWeapon(4))
	elseif (survivorObject.player:getPerkLevel(Perks.FromString("Cooking")) >= 3) then
		Dress = "Preset_Chef";
		survivorObject:giveWeapon(SetSurvivorWeapon(4));
	elseif (survivorObject.player:getPerkLevel(Perks.FromString("Farming")) >= 3) then
		Dress = "Preset_Farmer";
		survivorObject:giveWeapon(SetSurvivorWeapon(4));
	end

	survivorObject:SuitUp(Dress);

	return survivorObject;
end

---comment
---@param square any
---@param ID any
---@return any
function SuperSurvivor:loadPlayer(ID, square)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:loadPlayer() called");
	-- load from file if save file exists
	if (ID ~= nil) and (checkSaveFileExists("Survivor" .. tostring(ID))) then
		local BuddyDesc = SurvivorFactory.CreateSurvivor();
		local Buddy = IsoPlayer.new(getWorld():getCell(), BuddyDesc, square:getX(), square:getY(), square:getZ());
		local filename = GetModSaveDir() .. "Survivor" .. tostring(ID);

		Buddy:getInventory():emptyIt();
		Buddy:load(filename);
		Buddy:setX(square:getX());
		Buddy:setY(square:getY());
		Buddy:setZ(square:getZ());
		Buddy:getModData().ID = ID;
		Buddy:setNPC(true);
		Buddy:setBlockMovement(true);
		Buddy:setSceneCulled(false);

		return Buddy;
	end
end

---comment
---@param ID any
---@param square any
---@return table
function SuperSurvivor:newLoad(ID, square)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:newLoad() called");
	local survivorObject = SuperSurvivor:CreateBaseSurvivorObject();
	setmetatable(survivorObject, self);
	self.__index = self;

	survivorObject.BravePoints = 0;
	survivorObject.Shirt = nil;
	survivorObject.Pants = nil;
	survivorObject.WasOnScreen = false;

	survivorObject.NoResultActions = {};
	survivorObject.YesResultActions = {};
	survivorObject.ContinueResultActions = {};
	survivorObject.TriggerName = "";

	survivorObject.player = survivorObject:loadPlayer(ID, square);
	survivorObject.userName = TextDrawObject.new();
	survivorObject.userName:setAllowAnyImage(true);
	survivorObject.userName:setDefaultFont(UIFont.Small);
	survivorObject.userName:setDefaultColors(255, 255, 255, 255);
	survivorObject.userName:ReadString(survivorObject.player:getForname());

	survivorObject.MyTaskManager = TaskManager:new(survivorObject);

	for i = 1, #LootTypes do
		survivorObject.SquareContainerSquareLooteds[LootTypes[i]] = {};
	end

	survivorObject:setBravePoints(SurvivorBravery);

	return survivorObject;
end

---comment
---@param player any
---@return table
function SuperSurvivor:newSet(player)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:newSet() called");
	local survivorObject = SuperSurvivor:CreateBaseSurvivorObject();
	setmetatable(survivorObject, self);
	self.__index = self;

	survivorObject.player = player;
	survivorObject.MyTaskManager = TaskManager:new(survivorObject);

	for i = 1, #LootTypes do
		survivorObject.SquareContainerSquareLooteds[LootTypes[i]] = {};
	end

	survivorObject:setBravePoints(SurvivorBravery);

	return survivorObject;
end

-- Batmane: Think of Wait as to skip the next n ticks. ie. Wait(3) means skip the processing of next 3 ticks. This can be used to save performance
function SuperSurvivor:Wait(ticks)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Wait() called");
	self.WaitTicks = ticks
end

function SuperSurvivor:isInBase()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:is InBase() called");
	if (self:getGroupID() == nil) then
		return false
	else
		local group = SSGM:GetGroupById(self:getGroupID())
		if (group) then
			return group:IsInBounds(self:Get())
		end
	end
	return false
end

function SuperSurvivor:getBaseCenter()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBaseCenter() called");
	if (self:getGroupID() == nil) then
		return false
	else
		local group = SSGM:GetGroupById(self:getGroupID())
		if (group) then
			return group:getBaseCenter()
		end
	end
	return nil
end

function SuperSurvivor:isInGroup(thisGuy)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInGroup() called");
	if (self:getGroupID() == nil) then
		return false
	elseif (thisGuy:getModData().Group == nil) then
		return false
	elseif (thisGuy:getModData().Group == self:getGroupID()) then
		return true
	else
		return false
	end
end

function SuperSurvivor:getX()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getX() called");
	return self.player:getX()
end

function SuperSurvivor:getY()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getY() called");
	return self.player:getY()
end

function SuperSurvivor:getZ()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getZ() called");
	return self.player:getZ()
end

function SuperSurvivor:getCurrentSquare()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getCurrentSquare() called");
	return self.player:getCurrentSquare()
end

function SuperSurvivor:getModData()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getModData() called");
	return self.player:getModData()
end

function SuperSurvivor:getName()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getName() called");
	return self.player:getModData().Name
end

function SuperSurvivor:refreshName()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:refreshName() called");
	if (self.player:getModData().Name ~= nil) then self:setName(self.player:getModData().Name) end
end

function SuperSurvivor:setName(nameToSet)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setName() called");
	local desc = self.player:getDescriptor()
	desc:setForename(nameToSet)
	desc:setSurname("")
	self.player:setForname(nameToSet);
	self.player:setDisplayName(nameToSet);
	if (self.userName) then self.userName:ReadString(nameToSet) end
	self.player:getModData().Name = nameToSet
	self.player:getModData().NameRaw = nameToSet
end

function SuperSurvivor:renderName() -- To do: Make an in game option to hide rendered names. It was requested.
	CreateLogLine("Render Name", isLocalLoggingEnabled, "SuperSurvivor:render Name() called");

	if not self.userName
		or not self:isInCell()
		or self:Get():getAlpha() ~= 1.0
		or not getSpecificPlayer(0)
		or not getSpecificPlayer(0):CanSee(self.player)
	then
		return false
	end

	if self.JustSpoke == true 
		and self.TicksSinceSpoke == 0 
	then
		self.TicksSinceSpoke = 2 * globalBaseUpdateDelayTicks

		if (not IsDisplayingNpcName) then
			self.userName:ReadString(tostring(self.SayLine1))
		elseif (IsDisplayingNpcName) then
			self.userName:ReadString(self.player:getForname() .. "\n" .. tostring(self.SayLine1))
		end
	elseif self.TicksSinceSpoke > 0 then
		self.TicksSinceSpoke = self.TicksSinceSpoke - 1
		if self.TicksSinceSpoke == 0 then
			if (not IsDisplayingNpcName) then
				self.userName:ReadString("");
			elseif (IsDisplayingNpcName) then
				self.userName:ReadString(self.player:getForname());
			end
			self.JustSpoke = false
			self.SayLine1 = ""
		end
	end

	local sx = IsoUtils.XToScreen(self:Get():getX(), self:Get():getY(), self:Get():getZ(), 0);
	local sy = IsoUtils.YToScreen(self:Get():getX(), self:Get():getY(), self:Get():getZ(), 0);
	sx = sx - IsoCamera.getOffX() - self:Get():getOffsetX();
	sy = sy - IsoCamera.getOffY() - self:Get():getOffsetY();

	sy = sy - 128

	sx = sx / getCore():getZoom(0)
	sy = sy / getCore():getZoom(0)

	sy = sy - self.userName:getHeight()

	self.userName:AddBatchedDraw(sx, sy, true)
end

function SuperSurvivor:setHostile(toValue) -- Moved up, to find easier
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setHostile() called");
	if (IsDisplayingHostileColor) then
		if (toValue) then
			self.userName:setDefaultColors(128, 128, 128, 255);
			self.userName:setOutlineColors(180, 0, 0, 255);
		else
			self.userName:setDefaultColors(255, 255, 255, 255);
			self.userName:setOutlineColors(0, 0, 0, 255);
		end
	end

	self.player:getModData().isHostile = toValue

	if (ZombRand(2) == 1) then
		self.player:getModData().isRobber = true
	end
end

function SuperSurvivor:SpokeTo(playerID)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:SpokeTo() called");
	self.SpokeToRecently[playerID] = true
end

function SuperSurvivor:getSpokeTo(playerID)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getSpokeTo() called");
	if (self.SpokeToRecently[playerID] ~= nil) then
		return true
	else
		return false
	end
end

function SuperSurvivor:WearThis(ClothingItemName) -- should already be in inventory
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:WearThis() called");
	local ClothingItem
	if (instanceof(ClothingItemName, "InventoryItem")) then
		ClothingItem = ClothingItemName
	else
		ClothingItem = instanceItem(ClothingItemName)
	end

	if not ClothingItem then return false end
	self.player:getInventory():AddItem(ClothingItem)

	if instanceof(ClothingItem, "InventoryContainer") and ClothingItem:canBeEquipped() ~= "" then
		self.player:setClothingItem_Back(ClothingItem)
		getSpecificPlayer(self.player:getPlayerNum()).playerInventory:refreshBackpacks()
	elseif ClothingItem:getCategory() == "Clothing" then
		if ClothingItem:getBodyLocation() ~= "" then
			self.player:setWornItem(ClothingItem:getBodyLocation(), nil);
			self.player:setWornItem(ClothingItem:getBodyLocation(), ClothingItem)
		end
	else
		return false
	end

	self.player:initSpritePartsEmpty();
	triggerEvent("OnClothingUpdated", self.player)
end

function SuperSurvivor:setBravePoints(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setBravePoints() called");
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "BravePoints set to: " .. tostring(toValue));
	self.player:getModData().BravePoints = toValue
end

function SuperSurvivor:getBravePoints()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBravePoints() called");
	if (self.player:getModData().BravePoints ~= nil) then
		return self.player:getModData().BravePoints
	else
		return 0
	end
end

function SuperSurvivor:setGroupRole(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setGroupRole() called");
	self.player:getModData().GroupRole = toValue
end

function SuperSurvivor:getGroupRole()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getGroupRole() called");
	return self.player:getModData().GroupRole
end

function SuperSurvivor:setNeedAmmo(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setNeedAmmo() called");
	self.player:getModData().NeedAmmo = toValue
end

function SuperSurvivor:getNeedAmmo()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getNeedAmmo() called");
	if self.player:getModData().NeedAmmo ~= nil then
		return self.player:getModData().NeedAmmo
	end

	return false
end

function SuperSurvivor:setAIMode(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setAIMode() called");
	self.player:getModData().AIMode = toValue
end

function SuperSurvivor:getAIMode()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getAIMode() called");
	return self.player:getModData().AIMode
end

function SuperSurvivor:setGroupID(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setGroupID() called");
	self.player:getModData().Group = toValue
end

function SuperSurvivor:getGroupID()
	-- CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getGroupID() called");
	-- CreateLogLine("SuperSurvivor", true, "SuperSurvivor:getGroupID() = " .. tostring(self.player:getModData().Group));
	return self.player:getModData().Group
end

function SuperSurvivor:setRunning(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setRunning() called");
	if (not self.player or not self.player.NPCGetRunning) then
		return false;
	end

	if self.player:NPCGetRunning() ~= toValue then
		if toValue == false then
			self.player:NPCSetRunning(false);
			self.player:NPCSetJustMoved(false);
		else
			local distanceToPlayer0 = self.distanceToPlayer0
			if not distanceToPlayer0 then 
				distanceToPlayer0 = GetXYDistanceBetween(self.player, getSpecificPlayer(0))
			end
			if distanceToPlayer0 <= tooCloseToPlayerToRun and getSpecificPlayer(0):getZ() == self.player:getZ()  then 
				return
			end
			self.player:NPCSetRunning(true);
			self.player:NPCSetJustMoved(true);
		end
	end
end

function SuperSurvivor:getRunning()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:get Running() called");
	return self.player:getModData().Running;
end

function SuperSurvivor:setSneaking(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:set Sneaking() called");
	if self.player ~= nil then
		self.player:setSneaking(toValue);
	end
end

-- Wip to get player to sit on ground - This doesnt make them sit FYI
function SuperSurvivor:setSitOnGround(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:set SitOnGround() called");
	if self.player ~= nil then
		-- CreateLogLine("FollowTaskSit", true, " NPC now sitting on ground = " .. tostring(toValue));
		-- self.player:NPCSetAiming(toValue)

		-- CreateLogLine("FollowTaskSit", true, " Function = " .. tostring(self.player.setSitOnGround));


		self.player:setSitOnGround(toValue);
	end
end

-- Not Used?
-- function SuperSurvivor:getSneaking()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getSneaking() called");
-- 	return self.player:getModData().Sneaking;
-- end

function SuperSurvivor:getGroup()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getGroup() called");
	local gid = self:getGroupID();

	if (gid ~= nil) then
		return SSGM:GetGroupById(gid);
	end
	return nil;
end

-- WIP - Cows: GET() - is also spammed frequently, need to investigate why it is being called so often.
function SuperSurvivor:Get()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Get() called");
	return self.player;
end

function SuperSurvivor:getCurrentTask()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getCurrentTask() called");
	return self:getTaskManager():getCurrentTask();
end

function SuperSurvivor:usingGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:usingGun() called");
	local handItem = self.player:getPrimaryHandItem();

	if handItem ~= nil and instanceof(handItem, "HandWeapon") then
		return self.player:getPrimaryHandItem():isAimedFirearm();
	end

	return false;
end

function SuperSurvivor:isWalkingPermitted()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isWalkingPermitted() called");
	return self.WalkingPermitted;
end

function SuperSurvivor:setWalkingPermitted(toValue)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setWalkingPermitted() called");
	self.WalkingPermitted = toValue;
end

function SuperSurvivor:resetAllTables()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:resetAllTables() called");
	self.SpokeToRecently = {};
	self.SquareWalkToAttempts = {};
	self.SquaresExplored = {};
	self.SquareContainerSquareLooteds = {};

	for i = 1, #LootTypes do
		self.SquareContainerSquareLooteds[LootTypes[i]] = {};
	end
end

function SuperSurvivor:resetContainerSquaresLooted()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:resetContainerSquaresLooted() called");
	for i = 1, #LootTypes do
		self.SquareContainerSquareLooteds[LootTypes[i]] = {};
	end
end

function SuperSurvivor:resetWalkToAttempts()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:resetWalkToAttempts() called");
	self.SquareWalkToAttempts = {};
end

function SuperSurvivor:BuildingLooted()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:BuildingLooted() called");
	self.NumberOfBuildingsLooted = self.NumberOfBuildingsLooted + 1;
end

function SuperSurvivor:getBuildingsLooted()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBuildingsLooted() called");
	return self.NumberOfBuildingsLooted;
end

function SuperSurvivor:setBaseBuilding(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setBaseBuilding() called");
	self.BaseBuilding = building;
end

function SuperSurvivor:getBaseBuilding()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBaseBuilding() called");
	return self.BaseBuilding;
end

--get the super survivor object of the character Im following (if any)
function SuperSurvivor:getFollowChar()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getFollowChar() called");
	return SSM:Get(self.player:getModData().FollowCharID);
end

-- If there is no follow task in the list at all, then you dont need to follow
-- Otherwise, if there is one in the list, is it complete and are the passive conditions to trigger it met? Then yeah, you do need to follow.
function SuperSurvivor:needToFollow()
	local Task = self:getTaskManager():getTaskFromName("Follow")
	-- CreateLogLine('NPC Follow', true, tostring(self:getName()) .. " getting task from list = " .. tostring(Task))
	if not Task then return false end
	-- CreateLogLine('NPC Follow', true, tostring(self:getName()) .. " has a Follow Task")
	if not Task:isComplete() and Task:needToFollow()
	then
		return true;
	end
	return false;
end

function SuperSurvivor:getNoFoodNearBy()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getNoFoodNearBy() called");
	if (self.NoFoodNear == true) then
		if (self.TicksAtLastDetectNoFood ~= nil) and ((self.Reducer - self.TicksAtLastDetectNoFood) > 12000) then
			self.NoFoodNear = false;
		end
	end

	return self.NoFoodNear;
end

function SuperSurvivor:setNoFoodNearBy(toThis)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setNoFoodNearBy() called");
	if (toThis == true) then
		self.TicksAtLastDetectNoFood = self.Reducer;
	end
	self.NoFoodNear = toThis;
end

function SuperSurvivor:getNoWaterNearBy()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getNoWaterNearBy() called");
	if self.NoWaterNear == true 
		and self.TicksAtLastDetectNoWater ~= nil
		and (self.Reducer < self.TicksAtLastDetectNoWater or self.Reducer - self.TicksAtLastDetectNoWater > 12900)
	then
		self.NoWaterNear = false;
	end
	return self.NoWaterNear;
end

function SuperSurvivor:setNoWaterNearBy(toThis)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setNoWaterNearBy() called");
	if (toThis == true) then
		self.TicksAtLastDetectNoWater = self.Reducer;
	end

	self.NoWaterNear = toThis;
end

function SuperSurvivor:isHungry()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isHungry() called");
	return (self.player:getStats():getHunger() > 0.15);
end

function SuperSurvivor:isVHungry()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isVHungry() called");
	return (self.player:getStats():getHunger() > 0.40);
end

function SuperSurvivor:isStarving()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isStarving() called");
	return (self.player:getStats():getHunger() > 0.75);
end

function SuperSurvivor:isThirsty()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isThirsty() called");
	return (self.player:getStats():getThirst() > 0.15);
end

function SuperSurvivor:isVThirsty()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isVThirsty() called");
	return (self.player:getStats():getThirst() > 0.40);
end

function SuperSurvivor:isDyingOfThirst()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isDyingOfThirst() called");
	return (self.player:getStats():getThirst() > 0.75);
end

function SuperSurvivor:isDead()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isDead() called");
	return (self.player:isDead());
end

function SuperSurvivor:saveFileExists()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:saveFileExists() called");
	return (checkSaveFileExists("Survivor" .. tostring(self:getID())));
end

function SuperSurvivor:getRelationshipWP()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getRelationshipWP() called");
	if (self.player:getModData().RWP == nil) then
		return 0;
	else
		return self.player:getModData().RWP;
	end
end

function SuperSurvivor:PlusRelationshipWP(thisAmount)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:PlusRelationshipWP() called");
	if (self.player:getModData().RWP == nil) then
		self.player:getModData().RWP = 0;
	end

	self.player:getModData().RWP = self.player:getModData().RWP + thisAmount;
	return self.player:getModData().RWP;
end

function SuperSurvivor:hasFood()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasFood() called");
	local inv = self.player:getInventory();
	local bag = self:getBag();

	if FindAndReturnFood(inv) ~= nil then
		return true;
	elseif (inv ~= bag) and (FindAndReturnFood(bag) ~= nil) then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:getFood()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getFood() called");
	local inv = self.player:getInventory();
	local bag = self:getBag();

	if FindAndReturnFood(inv) ~= nil then
		return FindAndReturnBestFood(inv, nil);
	elseif (inv ~= bag) and (FindAndReturnFood(bag) ~= nil) then
		return FindAndReturnBestFood(bag, nil);
	else
		return nil;
	end
end

function SuperSurvivor:hasWater()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasWater() called");
	local inv = self.player:getInventory();
	local bag = self:getBag();

	if FindAndReturnWater(inv) ~= nil then
		return true;
	elseif (inv ~= bag) and (FindAndReturnWater(bag) ~= nil) then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:getWater()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getWater() called");
	local inv = self.player:getInventory();
	local bag = self:getBag();

	if FindAndReturnWater(inv) ~= nil then
		return FindAndReturnWater(inv);
	elseif (inv ~= bag) and (FindAndReturnWater(bag) ~= nil) then
		return FindAndReturnWater(bag);
	else
		return nil;
	end
end

function SuperSurvivor:getFacingSquare()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getFacingSquare() called");
	local square = self.player:getCurrentSquare();
	local fsquare = square:getTileInDirection(self.player:getDir());
	if (fsquare) then
		return fsquare;
	else
		return square;
	end
end

function SuperSurvivor:isTargetBuildingClaimed(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isTargetBuildingClaimed() called");
	if (IsPlayerBaseSafe) then -- if safe base mode on survivors consider other claimed buildings already explored
		local tempsquare = GetRandomBuildingSquare(building);

		if (tempsquare ~= nil) then
			local tempgroup = SSGM:GetGroupIdFromSquare(tempsquare);

			CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "groupId: " .. tostring(tempgroup));
			if (tempgroup ~= -1 and tempgroup ~= self:getGroupID()) then
				return true;
			end
		end
	end

	return false;
end

function SuperSurvivor:MarkBuildingExplored(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:MarkBuildingExplored() called");
	if (not building) then
		return false;
	end

	self:resetBuildingWalkToAttempts(building);
	local bdef = building:getDef();

	for x = bdef:getX() - 1, (bdef:getX() + bdef:getW() + 1) do
		--
		for y = bdef:getY() - 1, (bdef:getY() + bdef:getH() + 1) do
			local sq = getCell():getGridSquare(x, y, self.player:getZ());

			if (sq) then
				self:Explore(sq);
			end
		end
	end
end

function SuperSurvivor:getBuildingExplored(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBuildingExplored() called");
	if self:isTargetBuildingClaimed(building) then
		return true;
	end

	local sq = GetRandomBuildingSquare(building);

	if (sq) then
		if (self:getExplore(sq) > 0) then
			return true;
		end
	end

	return false;
end

--[[
	WIP - isSpeaking() is spammed very frequently... about 19000 times in less than a minute
	Cows suspect the function is being called even then the speaker is not visible and perhaps in a tick-based frequency.
	Perhaps it is best to limit the calls to within visible range (no off-screen calls) and set a call frequency limit.
--]]
function SuperSurvivor:isSpeaking()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isSpeaking() called");
	if (self.JustSpoke) or (self.player:isSpeaking()) then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Speak(text)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Speak() called");
	if (IsSpeakEnabled) then
		self.SayLine1 = text;
		self.JustSpoke = true;
		self.TicksSinceSpoke = 0;
	end
end

function SuperSurvivor:RoleplaySpeak(text)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:RoleplaySpeak() called");
	if (IsRoleplayEnabled) then
		if (text:match('^\\*(.*)\\*$')) then -- checks if the string already have '*' (some localizations have it)
			self.SayLine1 = text;
		else
			self.SayLine1 = "*" .. text .. "*";
		end

		self.JustSpoke = true;
		self.TicksSinceSpoke = 0;
	end
end

function SuperSurvivor:MarkAttemptedBuildingExplored(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:MarkAttemptedBuildingExplored() called");
	if (building == nil) then
		return false;
	end
	local bdef = building:getDef();
	--
	for x = bdef:getX(), (bdef:getX() + bdef:getW()) do
		--
		for y = bdef:getY(), (bdef:getY() + bdef:getH()) do
			local sq = getCell():getGridSquare(x, y, self.player:getZ());
			--
			if (sq) then
				self:setWalkToAttempt(sq, 8);
			end
		end
	end
end

function SuperSurvivor:resetBuildingWalkToAttempts(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:resetBuildingWalkToAttempts() called");
	if (building == nil) then
		return false;
	end
	local bdef = building:getDef();
	--
	for x = bdef:getX(), (bdef:getX() + bdef:getW()) do
		--
		for y = bdef:getY(), (bdef:getY() + bdef:getH()) do
			local sq = getCell():getGridSquare(x, y, self.player:getZ());
			if (sq) then
				self:setWalkToAttempt(sq, 0);
			end
		end
	end
end

function SuperSurvivor:Explore(sq)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Explore() called");
	if (sq) then
		local key = tostring(sq:getX()) .. "/" .. tostring(sq:getY())
		if (self.SquaresExplored[key] == nil) then
			self.SquaresExplored[key] = 1;
		else
			self.SquaresExplored[key] = self.SquaresExplored[key] + 1;
		end
	end
end

function SuperSurvivor:getExplore(sq)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getExplore() called");
	if (sq) then
		local key = tostring(sq:getX()) .. "/" .. tostring(sq:getY());
		--
		if (self.SquaresExplored[key] == nil) then
			return 0;
		else
			return self.SquaresExplored[key];
		end
	end
	return 0;
end

function SuperSurvivor:ContainerSquareLooted(sq, Category)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:ContainerSquareLooted() called");
	if (sq) then
		local key = sq:getX() .. sq:getY();
		if (self.SquareContainerSquareLooteds[Category][key] == nil) then
			self.SquareContainerSquareLooteds[Category][key] = 1;
		else
			self.SquareContainerSquareLooteds[Category][key] = self.SquareContainerSquareLooteds[Category][key] + 1;
		end
	end
end

function SuperSurvivor:getContainerSquareLooted(sq, Category)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getContainerSquareLooted() called");
	if (sq) then
		local key = sq:getX() .. sq:getY();
		--
		if (self.SquareContainerSquareLooteds[Category][key] == nil) then
			return 0;
		else
			return self.SquareContainerSquareLooteds[Category][key]
		end
	end
	return 0;
end

function SuperSurvivor:TrackWalkToAttempt(sq)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:TrackWalk ToAttempt() called");
	if (sq) then
		local key = sq:getX() .. sq:getY()
		if (self.SquareWalkToAttempts[key] == nil) then
			self.SquareWalkToAttempts[key] = 1;
		else
			self.SquareWalkToAttempts[key] = self.SquareWalkToAttempts[key] + 1;
		end
	end
end

function SuperSurvivor:setWalkToAttempt(sq, toThis)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setWalkToAttempt() called");
	if (sq) then
		local key = sq:getX() .. sq:getY()
		self.SquareWalkToAttempts[key] = toThis
	end
end

function SuperSurvivor:getWalkToAttempt(sq)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getWalkToAttempt() called");
	if (sq) then
		local key = sq:getX() .. sq:getY();
		--
		if (self.SquareWalkToAttempts[key] == nil) then
			return 0;
		else
			return self.SquareWalkToAttempts[key];
		end
	end

	return 0;
end

function SuperSurvivor:inUnLootedBuilding()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inUnLootedBuilding() called");
	if (self.player:isOutside()) then
		return false;
	end

	local sq = self.player:getCurrentSquare()

	if (sq) then
		local room = sq:getRoom();

		if (room) then
			local building = room:getBuilding();

			if (building) and (self:getBuildingExplored(building) == false) then
				return true;
			end
		end
	end

	return false;
end

function SuperSurvivor:getBuilding()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBuilding() called");
	if (self.player == nil) then
		return nil;
	end

	local sq = self.player:getCurrentSquare();

	if (sq) then
		local room = sq:getRoom();

		if (room) then
			local building = room:getBuilding();

			if (building) then
				return building;
			end
		end
	end

	return nil;
end

function SuperSurvivor:isInBuilding(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInBuilding() called");
	if (building == self:getBuilding()) then
		return true
	else
		return false
	end
end

function SuperSurvivor:AttemptedLootBuilding(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:AttemptedLootBuilding() called");
	if (not building) then
		return false;
	end

	local buildingSquareRoom = building:getRandomRoom();

	if not buildingSquareRoom then
		return false;
	end

	local buildingSquare = buildingSquareRoom:getRandomFreeSquare();

	if not buildingSquare then
		return false;
	end

	if (self:getWalkToAttempt(buildingSquare) == 0) then
		return false;
	elseif (self:getWalkToAttempt(buildingSquare) >= 8) then
		return true;
	else
		return false;
	end
end

-- WIP - Cows: NEED TO REWORK THE NESTED LOOP CALLS
function SuperSurvivor:getUnBarricadedWindow(building)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getUnBarricadedWindow() called");
	local WindowOut = nil
	local closestSoFar = 100
	local bdef = building:getDef()
	--
	for x = bdef:getX() - 1, (bdef:getX() + bdef:getW() + 1) do
		--
		for y = bdef:getY() - 1, (bdef:getY() + bdef:getH() + 1) do
			local sq = getCell():getGridSquare(x, y, self.player:getZ())
			--
			if (sq) then
				local Objs = sq:getObjects();
				CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "Objects size: " .. tostring(Objs:size() - 1));
				--
				for j = 0, Objs:size() - 1 do
					local Object = Objs:get(j);
					local objectSquare = Object:getSquare();
					local distance = GetDistanceBetween(objectSquare, self.player); -- WIP - literally spammed inside the nested for loops...

					if (instanceof(Object, "IsoWindow"))
						and (self:getWalkToAttempt(objectSquare) < 8)
						and distance < closestSoFar
					then
						local barricade = Object:getBarricadeForCharacter(self.player)

						if barricade == nil or (barricade:canAddPlank()) then
							closestSoFar = distance;
							WindowOut = Object;
							break; -- this should stop further runs of this call and improve performance...
						end
					end
				end
			end
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:getUnBarricadedWindow() END ---");

	return WindowOut;
end

function SuperSurvivor:isEnemy(character)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:is Enemy() called");

	if character:isZombie() then
		return true;
	elseif self:isInGroup(character) then
		return false;
	elseif self.player:getModData().isHostile ~= true and self.player:getModData().surender == true then
		return false -- so other npcs dont attack anyone surendering
	elseif self.player:getModData().hitByCharacter == true and character:getModData().semiHostile == true then
		return true;
	elseif character:getModData().isHostile ~= self.player:getModData().isHostile then
		return true;
	else
		return false;
	end

	local group = self:getGroup();
	if group then return group:isEnemy(self, character) end
	return false
end

function SuperSurvivor:hasWeapon()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasWeapon() called");
	local handItem = self.player:getPrimaryHandItem()
	if not handItem then return false end
	if instanceof(handItem, "HandWeapon") then
		if handItem:isBroken() then return false end
		return handItem;
	end
	return false;
end

function SuperSurvivor:hasGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasGun() called");
	local handItem = self.player:getPrimaryHandItem()
	if not handItem then return false end
	if instanceof(handItem, "HandWeapon") and handItem:isAimedFirearm() then
		return true;
	end
	return false;
end

function SuperSurvivor:getBag()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getBag() called");
	if (self.player:getClothingItem_Back() ~= nil) and (instanceof(self.player:getClothingItem_Back(), "InventoryContainer")) then
		return self.player:getClothingItem_Back():getItemContainer();
	end

	if (self.player:getSecondaryHandItem() ~= nil) and (instanceof(self.player:getSecondaryHandItem(), "InventoryContainer")) then
		return self.player:getSecondaryHandItem():getItemContainer();
	end

	if (self.player:getPrimaryHandItem() ~= nil) and (instanceof(self.player:getPrimaryHandItem(), "InventoryContainer")) then
		return self.player:getPrimaryHandItem():getItemContainer();
	end

	return self.player:getInventory();
end

function SuperSurvivor:getWeapon()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getWeapon() called");
	if self.player:getInventory() ~= nil 
		and self.player:getInventory():FindAndReturnCategory("Weapon") 
	then
		return self.player:getInventory():FindAndReturnCategory("Weapon");
	end

	if self.player:getClothingItem_Back() ~= nil 
		and instanceof(self.player:getClothingItem_Back(), "InventoryContainer") 
		and self.player:getClothingItem_Back():getItemContainer():FindAndReturnCategory("Weapon") 
	then
		return self.player:getClothingItem_Back():getItemContainer():FindAndReturnCategory("Weapon");
	end

	if self.player:getSecondaryHandItem() ~= nil 
		and instanceof(self.player:getSecondaryHandItem(), "InventoryContainer") 
		and self.player:getSecondaryHandItem():getItemContainer():FindAndReturnCategory("Weapon") 
	then
		return self.player:getSecondaryHandItem():getItemContainer():FindAndReturnCategory("Weapon");
	end

	return nil;
end

function SuperSurvivor:hasRoomInBag()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasRoomInBag() called");
	local playerBag = self:getBag();

	if (playerBag:getCapacityWeight() >= (playerBag:getMaxWeight() * 0.9)) then
		return false;
	else
		return true;
	end
end

function SuperSurvivor:hasRoomInBagFor(item)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:hasRoomInBagFor() called");
	local playerBag = self:getBag();

	if (playerBag:getCapacityWeight() + item:getWeight() >= (playerBag:getMaxWeight() * 0.9)) then
		return false;
	else
		return true;
	end
end

function SuperSurvivor:getSeenCount()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getSeenCount() called");
	return self.seenCount;
end

function SuperSurvivor:getDangerSeenCount()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getDangerSeenCount() called");
	return self.dangerSeenCount;
end

function SuperSurvivor:getEnemiesOnMe()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getEnemiesOnMe() called");
	return self.EnemiesOnMe;
end


function SuperSurvivor:isInSameRoom(movingObj)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInSameRoom() called");
	if not movingObj then return false end
	local objSquare = movingObj:getCurrentSquare();
	if (not objSquare) then return false end
	local selfSquare = self.player:getCurrentSquare();
	if (not selfSquare) then return false end
	if (selfSquare:getRoom() == objSquare:getRoom()) then return true end
	return false;
end

function SuperSurvivor:isInSameBuilding(movingObj)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInSameBuilding() called");
	if not movingObj then
		return false;
	end
	local objSquare = movingObj:getCurrentSquare();

	if (not objSquare) then
		return false;
	end
	local selfSquare = self.player:getCurrentSquare();

	if (not selfSquare) then
		return false;
	end

	if (selfSquare:getRoom() ~= nil and objSquare:getRoom() ~= nil) then
		return (selfSquare:getRoom():getBuilding() == objSquare:getRoom():getBuilding());
	end

	if (selfSquare:getRoom() == objSquare:getRoom()) then
		return true;
	end

	return false;
end

-- An easiser function to make InBuildingWithEntity returns
function SuperSurvivor:isInSameBuildingWithEnemyAlt()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInSameBuildingWithEnemyAlt() called");
	if (self.LastEnemySeen ~= nil) then
		if (self:isInSameBuilding(self.LastEnemySeen)) then
			return true;
		else
			return false;
		end
	end
end

function SuperSurvivor:getAttackRange()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getAttackRange() called");
	return self.AttackRange;
end

function SuperSurvivor:RealCanSee(character)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:RealCanSee() called");
	if self.player:isGodMod() then
		character:setAlpha(1.0);
		character:setTarAlphaAlpha(1.0);
		return true;
	end

	if character:isZombie() then
		return self.player:CanSee(character) -- normal vision for zombies (they are not quiet or sneaky)
		-- return true -- Survivor always sees the zombie
	end 

	local visioncone = 0.90;
	if character:isSneaking() then
		visioncone = visioncone - 0.15
	end
	return self.player:CanSee(character) and (self.player:getDotWithForwardDirection(character:getX(), character:getY()) + visioncone) >= 1.0
end

--This method allows other mods to adapt to Superb Survivors continued
--I let it as a method on purpose for other mods to use self if they dare (better not using it -or carefully- though for compatibility over time)
--target is an IsoMovingObject
--survivor is an IsoPlayer
function SuperSurvivor:isAThreat(target, survivor)
	return (target ~= nil) and (survivor ~= nil) and (target ~= survivor)
		and (instanceof(target, "IsoZombie") or instanceof(target, "IsoPlayer"))
		and (target:isDead() == false)
end


-- Config
-- Batmane note - These params are tuned according to using 'cheap distance'. The actual threshold is slightly greater than this
startingDangerRange = 8 -- dangerRange is typically used as the range at which NPC will engage targets
surveyRange = 18; -- Range in which the npc will start surveying the object(s) in its vision. - -- Cut off range where objects arent even processed by ai
maxProcessingRange = 25
criticalDangerRange = 3 -- dangerRange where NPC typically needs to run so 2 here is actually more like a distance of 3
local minSightDistance = 3 -- Range in which NPC will detect regardless of vision cone
groupCohesion = 0.3 -- Constant that determines how strongly a character is drawn towards their group when fleeing -- value of 1 causes ai freezing in group center despite 1 zombie being there 

function SuperSurvivor:DoVisionV3()
	local isFunctionLoggingEnabled = false;
	CreateLogLine("SuperSurvivor", isFunctionLoggingEnabled,
		"Character: " .. tostring(self:getName()) .. " | SuperSurvivor:Do VisionV3() called"
	);

	-- Outputs
	self.seenCount = 0;
	self.dangerSeenCount = 0;
	self.EnemiesOnMe = 0;

	-- if self.LastEnemySeen then CreateLogLine("Last Seen", true, tostring(self:getName()) .. " Last Seen Target = " .. tostring(self.LastEnemySeen:getName())) end 
	-- if self.LastEnemySeenDistance then CreateLogLine("Last Seen", true, tostring(self:getName()) .. " Last Seen Distance = " .. tostring(self.LastEnemySeenDistance)) end 

	self.LastEnemySeen = nil
	self.LastEnemySeenDistance = math.huge -- Number or nil
	self.LastEnemySeenSquare = nil

	self.distanceToPlayer0 = math.huge

	self.TriggerHeldDown = false

	self.escapeVector = { x = 0, y = 0 }
	local newEscapeVector = { x = 0, y = 0 }


	self.LastSurvivorSeen = nil;
	local dangerRange = math.max(self.AttackRange, startingDangerRange)
	
	local closestDistanceSoFar = math.huge;
	local closestCharIdx = nil;
	local closestSurvivorIdx = nil
	local closestZombieIdx = nil
				

	-- SPOTTING --
	-- local spottedList = self.player:getCell():getObjectList(); -- Old List for processing -- Better for multiplayer if we ever get there because its absolute
	-- Batmane try smaller spotted list built in function -- Take advantage of sight already handled by game
	-- Problem is that this causes issues if AI loses sight of player, they forget them
	local spottedList = self.player:getLastSpotted()  -- This function doesnt include the main player -- Not ideal...
	local distanceToPlayer = GetXYDistanceBetween(self.player, getSpecificPlayer(0))
	if distanceToPlayer <= maxProcessingRange then 
		-- table.insert(spottedList, getSpecificPlayer(0)) -- Doesnt work
		spottedList:push(getSpecificPlayer(0)) -- Works 

		self.distanceToPlayer0 = GetXYDistanceBetween(self.player, getSpecificPlayer(0))
	end
	-- 

	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " getSpecificPlayer(0): " ..tostring(getSpecificPlayer(0)));
	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " self.player: " ..tostring(self.player));
	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " spottedList: " ..tostring(spottedList));
	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " has spottedList BEFORE: " ..tostring(spottedList:size()));
	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " has spottedList AFTER: " ..tostring(spottedList:size()));
	-- CreateLogLine("Last Seen", true, tostring(self:getName()) .. " has spottedList: " ..tostring(spottedList));

	if not spottedList or spottedList:size() == 0 then return end

	CreateLogLine("SuperSurvivor", isFunctionLoggingEnabled,
		"Character - " .. tostring(self:getName()) .. " spotted: " .. tostring(spottedList:size()) .. " objects..."
	);

	for i = 0, spottedList:size() - 1 do
		local character = spottedList:get(i);

		repeat
			if self:isAThreat(character, self.player) then
				-- Testing Distance - This function can see pretty far - up to 65m or more but it only processes minimal items
				-- local testDistance = GetCheapXYDistanceBetween(character, self.player);
				-- CreateLogLine("Distance Log", true,
				-- 	"Character - " .. tostring(self:getName()) .. " is this far  " .. tostring(testDistance) .. " from this thing"
				-- );
				-- 
			
				-- Batmane - Distance Capping Function to eliminate excessive calculation - No Longer needed with built in spotting
				if isBeyondMaxDistance(character, self.player, surveyRange) then
					break 
				end
				

				-- This causes issues on stairs
				-- if character:getZ() ~= self.player:getZ() and instanceof(character, "IsoZombie") then 
				-- 	break 
				-- end

				local currentDistance = GetCheap3DDistanceBetween(character, self.player);

				if self:isEnemy(character)
				then
					-- Handle Number of zombies in critical range - for running
					if currentDistance < criticalDangerRange
						-- and character:getZ() == self.player:getZ() -- Need to find better system to handle stairs and slight elevation diff
					then
						self.EnemiesOnMe = self.EnemiesOnMe + 1;
					end
					--
					-- Handle Number of zombies in danger range (like initiator for attack range)
					if currentDistance < dangerRange
						-- and character:getZ() == self.player:getZ() -- Need to find better system to handle stairs and slight elevation diff
					then
						-- Get escape vector from all enemies in danger zone
						local tempVector = getVector(character, self.player)
						if not newEscapeVector then 
							newEscapeVector = tempVector
						else
							local combinedVector = addVectors(newEscapeVector, tempVector)
							newEscapeVector = {
								x = combinedVector.x / currentDistance,
								y = combinedVector.y / currentDistance
							}
						end

						self.dangerSeenCount = self.dangerSeenCount + 1;
					end
					--
					-- Handle identify closest threat
					local CanSee = self:RealCanSee(character);
					if CanSee then
						self.seenCount = self.seenCount + 1;
					end
					--
					if (CanSee or currentDistance < minSightDistance) 
						and currentDistance < closestDistanceSoFar 
					then
						closestDistanceSoFar = currentDistance;
						-- self.player:getModData().seenZombie = true; -- Batmane: Completely useless param
						closestCharIdx = i;
						if instanceof(character, "IsoPlayer") then 
							closestSurvivorIdx = i
						elseif instanceof(character, "IsoZombie") then
							closestZombieIdx = i
						end
					end
				end
			end
			break
		until true
	end

	CreateLogLine("SuperSurvivor", isFunctionLoggingEnabled, "spottedList end...");

	-- if enemies are near, increase the player update function refresh time for better fighting.
	-- Lower = more frequent processing
	-- How to calculate processing
	-- If updateDelay ticks = 60, then this update runs once per second at 60 fps
	-- However updateTicks will not run when WaitTicks is non zero. 
	-- WaitTicks ticks down once for every time updateDelayTicks passes
	-- So if you update 1 per second :Wait(3) means wait 3 seconds
	-- Funny enough, this logic here makes characters do everything faster when under pressure

	if self.EnemiesOnMe > 0 then
		self.UpdateDelayTicks = globalPanicUpdateDelayTicks; -- only do it when fighting so they dont follow or flee slowly when not fighting
	elseif self.dangerSeenCount > 0 then
		self.UpdateDelayTicks = globalFightingUpdateDelayTicks
	else
		self.UpdateDelayTicks = globalBaseUpdateDelayTicks;
	end

	if closestSurvivorIdx ~= nil and spottedList ~= nil then
		self.LastSurvivorSeen = spottedList:get(closestSurvivorIdx);
	end

	-- 
	-- CreateLogLine("Vision", isLocalLoggingEnabled, tostring(self:getName()) .. " has Enemies on me Count: " ..tostring(self.EnemiesOnMe));
	-- CreateLogLine("Vision", true, tostring(self:getName()) .. " has Danger Seen Count: " ..tostring(self.dangerSeenCount));
	-- CreateLogLine("Vision", isLocalLoggingEnabled, tostring(self:getName()) .. " has seenCount: " ..tostring(self.seenCount));
	-- CreateLogLine("Vision", isLocalLoggingEnabled, tostring(self:getName()) .. " has seen Last SurvivorSeen : " ..tostring(self.LastSurvivorSeen));
	-- CreateLogLine("Vision", isFunctionLoggingEnabled, tostring(self:getName()) .. " has self.player:getModData().seenZombie: " ..tostring(self.player:getModData().seenZombie));
	-- CreateLogLine("Vision", isLocalLoggingEnabled, tostring(self:getName()) .. " has closestCharIdx: " ..tostring(closestCharIdx));
	-- 

	if self.dangerSeenCount > 0 then
		local currentCharGroup = self:getGroup()
		if currentCharGroup and currentCharGroup.AverageLocation then 
			local tempVector = getVector(self.player, currentCharGroup.AverageLocation)
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has vector x to group center: " ..tostring(tempVector.x));
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has vector y to group center: " ..tostring(tempVector.y));

			tempVector = {
				x = tempVector.x * groupCohesion,
				y = tempVector.y * groupCohesion
			}
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has vector x to group center after applied cohesion: " ..tostring(tempVector.x));
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has vector y to group center after applied cohesion: " ..tostring(tempVector.y));

			newEscapeVector = addVectors(newEscapeVector, tempVector)
			
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has newEscapeVector x: " ..tostring(newEscapeVector.x));
			-- CreateLogLine("Group Manager Vision", true, tostring(self:getName()) .. " has newEscapeVector y: " ..tostring(newEscapeVector.y));
		end
		-- 
		self.escapeVector = newEscapeVector
	end

	-- Need something here to keep track of main player. Adjust the escape vector if player is in the path
	-- Perhaps we need to store the escape square here at all times so we dont have to recalculate it up to 2 or 3 times per second

	-- When all characters have been considered, pick the closest one and save information about it
	if closestCharIdx ~= nil and spottedList ~= nil 
	then
		if not self.LastEnemySeen or self.LastEnemySeen:getID() ~= spottedList:get(closestCharIdx):getID() then
			self.LastEnemySeen = spottedList:get(closestCharIdx);
			self.LastEnemySeenDistance = closestDistanceSoFar
			self.LastEnemySeenSquare = self.LastEnemySeen:getCurrentSquare()
			-- self.escapeVector = getXYUnitVector(self.LastEnemySeen, self.player) -- Old vector based on one enemy

			-- -----------------------------
			-- Debug Player Targetting
			-- if self.LastEnemySeen == getSpecificPlayer(0) then
			-- 	CreateLogLine("VISION PLAYER", true,
			-- 		"Character - " .. tostring(self:getName()) .. " targetting player! "
			-- 	);
			-- else
			-- 	CreateLogLine("VISION PLAYER", true,
			-- 		"Character - " .. tostring(self:getName()) .. " NOT"
			-- 	);
			-- end
			-- if self.player:getModData().isHostile then
			-- 	CreateLogLine("VISION PLAYER", true,
			-- 		"Character - " .. tostring(self:getName()) .. " is hostile: " .. tostring(self.player:getModData().isHostile)
			-- 	);
			-- end
			-- -----------------------------

			-- Debug New Functions
			-- local testdir = self.LastEnemySeen:getDir()
			-- local testcs = self.LastEnemySeen:getCurrentSquare()
			-- local testfs = testcs:getTileInDirection(self.LastEnemySeen:getDir())

			-- CreateLogLine("Test new funct", true, "testdir = " .. tostring(testdir)); // Iso Grid Square
			-- CreateLogLine("Test new funct", true, "testcs = " .. tostring(testcs)); // NW, NE, N, etc
			-- CreateLogLine("Test new funct", true, "testfs = " .. tostring(testfs)); // Iso Grid Square
			-- 


			CreateLogLine("Vision", isLocalLoggingEnabled, "self.LastEnemySeen = " .. tostring(self.LastEnemySeen));
			CreateLogLine("Vision", isLocalLoggingEnabled, "self.escapeVector = " .. tostring(self.escapeVector));
			CreateLogLine("Vision", isLocalLoggingEnabled, "self.LastEnemySeenDistance = " .. tostring(self.LastEnemySeenDistance));
			CreateLogLine("Vision", isLocalLoggingEnabled, "self.LastEnemySeenSquare = " .. tostring(self.LastEnemySeenSquare));
		end
		CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:Do VisionV3() END ---");
		return self.LastEnemySeen;
	end
end



function SuperSurvivor:isInCell()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInCell() called");
	if not self.player
		or not self.player:getCurrentSquare()
		or self:isDead()
	then
		return false;
	else
		return true;
	end
end

function SuperSurvivor:isOnScreen()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isOnScreen() called");
	if (self.player:getCurrentSquare() ~= nil) and (self.player:getCurrentSquare():IsOnScreen()) then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:isInAction()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isInAction() called");
	if self.player:getModData().bWalking == true and 
		self.TicksSinceSquareChanged <= 10 
	then
		return true
	end

	local queue = ISTimedActionQueue.queues[self.player]

	-- if queue then 
	-- 	CreateLogLine("isInAction", true, tostring(self:getName()) .. " Survivor has Number of TimedActionQueue" .. tostring(#queue.queue));
	-- end

	if queue == nil then return false end

	for k = 1, #queue.queue do
		local v = queue.queue[k]
		if v then
			return true
		end
	end

	return false;
end

-- Never Used
-- function SuperSurvivor:isWalking()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isWalking() called");
-- 	local queue = ISTimedActionQueue.queues[self.player]
-- 	if queue == nil then return false end
-- 	--for k,v in ipairs(queue.queue) do
-- 	for k = 1, #queue.queue do
-- 		local v = queue.queue[k]
-- 		if v then return true end
-- 	end
-- 	return false;
-- end

-- This activitely manages AI walking. 
-- Tracks AI target building, Manages ai door management (locked, barricaded, etc.)

function SuperSurvivor:walkTo(square)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:walkTo() called");

	if not square then 
		CreateLogLine("Walk to", true, tostring(self:getName()) .. " Error: square does not exist ...");
		return false 
	end

	local parent
	if instanceof(square, "IsoObject") then
		CreateLogLine("Walk to", true, tostring(self:getName()) .. " has target walk Square is an object ...");

		parent = square:getSquare()
	else
		parent = square
	end

	self.TargetSquare = square

	-- Track target building
	local squareRoom = square:getRoom()
	-- if squareRoom and square:getRoom():getBuilding() then -- Make efficient
	if squareRoom then
		self.TargetBuilding = squareRoom:getBuilding()
	end

	local adjacent = AdjacentFreeTileFinder.Find(parent, self.player);
	if instanceof(square, "IsoWindow") or instanceof(square, "IsoDoor") then
		adjacent = AdjacentFreeTileFinder.FindWindowOrDoor(parent, square, self.player);
	end

	if adjacent then
		local door = self:inFrontOfDoor()
		if door and (door:isLocked() or door:isLockedByKey() or door:isBarricaded()) and not door:isDestroyed() then
			CreateLogLine("Walk to", true, tostring(self:getName()) .. " is managing a locked door ...");

			-- local building = door:getOppositeSquare():getBuilding() -- Never gets used
			self:NPC_ManageLockedDoors() -- This function will be sure ^ doesn't make the npc stuck in these cases
		end
		if (self.StuckDoorTicks < 7) then
			self:TrackWalkToAttempt(square)
			self:WalkToPoint(adjacent:getX(), adjacent:getY(), adjacent:getZ())
			return
		end
		CreateLogLine("Walk to", true, tostring(self:getName()) .. " Error: could not walkToPoint ...");
	end
	--]]
end

function SuperSurvivor:walkTowards(x, y, z)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:walkTowards() called");
	local towardsSquare = GetTowardsSquare(self:Get(), x, y, z)
	if (towardsSquare == nil) then return false end

	self:WalkToPoint(towardsSquare:getX(), towardsSquare:getY(), towardsSquare:getZ())
end

function SuperSurvivor:walkToDirect(square)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:walkToDirect() called");
	if (square == nil) then return false end

	self:NPC_ManageLockedDoors() -- If things get too weird with npc pathing at doors, remove this line

	self:TrackWalkToAttempt(square)
	self:WalkToPoint(square:getX(), square:getY(), square:getZ())
end

function SuperSurvivor:WalkToPoint(tx, ty, tz)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:WalkToPoint() called");
	if (not self.player:getPathFindBehavior2():isTargetLocation(tx, ty, tz)) then
		self.player:getModData().bWalking = true

		self.player:setPath2(nil);
		self.player:getPathFindBehavior2():pathToLocation(tx, ty, tz);
	end
end

function SuperSurvivor:NPC_TargetIsOutside() -- The LastEnemySeen kind of target the npc is witnessing
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_TargetIsOutside() called");
	if self.LastEnemySeen ~= nil then
		if self.LastEnemySeen:isOutside() == true then
			return true
		else
			return false
		end
	end
end

function SuperSurvivor:NPC_IsOutside()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_IsOutside() called");
	if self.player:isOutside() then
		return true
	else
		return false
	end
end

function SuperSurvivor:inFrontOfDoor()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfDoor() called");
	local cs = self.player:getCurrentSquare()
	local osquare = GetAdjSquare(cs, "N")
	if cs and osquare and cs:getDoorTo(osquare) then return cs:getDoorTo(osquare) end

	osquare = GetAdjSquare(cs, "E")
	if cs and osquare and cs:getDoorTo(osquare) then return cs:getDoorTo(osquare) end

	osquare = GetAdjSquare(cs, "S")
	if cs and osquare and cs:getDoorTo(osquare) then return cs:getDoorTo(osquare) end

	osquare = GetAdjSquare(cs, "W")
	if cs and osquare and cs:getDoorTo(osquare) then return cs:getDoorTo(osquare) end

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "-- SuperSurvivor:inFrontOfDoor() End ---");
	return nil
end

function SuperSurvivor:inFrontOfLockedDoor()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfLockedDoor() called");
	local door = self:inFrontOfDoor()

	if (door ~= nil) and (door:isLocked() or door:isLockedByKey() or door:isBarricaded()) and (not door:isDestroyed()) then
		return true
	else
		return false
	end
end

function SuperSurvivor:inFrontOfLockedDoorAndIsOutside()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfLockedDoorAndIsOutside() called");
	local door = self:inFrontOfDoor()

	if (door ~= nil) and (door:isLocked() or door:isLockedByKey() or door:isBarricaded()) and (self.player:isOutside()) then
		return true
	else
		return false
	end
end

function SuperSurvivor:NPC_IFOD_BarricadedInside() -- IFOD stands for In front of door
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_IFOD_BarricadedInside() called");
	local door = self:inFrontOfDoor()

	if (door ~= nil) and ((door:isBarricaded()) and (not self.player:isOutside())) then
		return true
	else
		return false
	end
end

function SuperSurvivor:inFrontOfWindow()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfWindow() called");
	local cs = self.player:getCurrentSquare()
	local fsquare = cs:getTileInDirection(self.player:getDir());
	if cs and fsquare then
		return cs:getWindowTo(fsquare)
	else
		return nil
	end
end

-- since inFrontOfWindow (not alt) doesn't have this function's code
function SuperSurvivor:inFrontOfWindowAlt()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfWindowAlt() called");
	local cs = self.player:getCurrentSquare()
	local osquare = GetAdjSquare(cs, "N")
	if cs and osquare and cs:getWindowTo(osquare) then return cs:getWindowTo(osquare) end

	osquare = GetAdjSquare(cs, "E")
	if cs and osquare and cs:getWindowTo(osquare) then return cs:getWindowTo(osquare) end

	osquare = GetAdjSquare(cs, "S")
	if cs and osquare and cs:getWindowTo(osquare) then return cs:getWindowTo(osquare) end

	osquare = GetAdjSquare(cs, "W")
	if cs and osquare and cs:getWindowTo(osquare) then return cs:getWindowTo(osquare) end

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "-- SuperSurvivor:inFrontOfWindowAlt() End ---");
	return nil
end

function SuperSurvivor:inFrontOfBarricadedWindowAlt()
	-- Used door locked code for this, added 'alt' to function name just to be safe for naming
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:inFrontOfBarricadedWindowAlt() called");
	local window = self:inFrontOfWindowAlt()

	if (window ~= nil) and (window:isBarricaded()) then
		return true
	else
		return false
	end
end

function SuperSurvivor:NPC_inFrontOfUnBarricadedWindowOutside()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_inFrontOfUnBarricadedWindowOutside() called");
	-- Is the NPC front of an UNbarricaded window AND is the NPC outside?
	local window = self:inFrontOfWindowAlt();

	if (window ~= nil) and (not window:isBarricaded()) and (self.player:isOutside()) then
		return true;
	else
		return false;
	end
end


-- This was built for getting away from zeds
-- This needed 'not a companion' check to keep the NPC in question not to run away when they're following main player.

-- 

-- Batmane Rewritten
-- All this does is it checks if the conditons are good to ready your weapon
-- It will execute a flee if not
-- return false if you cannot ready the weapon
-- return true if you can

-- 'Cannot ready weapon' Cases:
-- You do not have a gun or are not using it
-- You need to run away from a zombie or person very close to you
-- You do not need to reload and do not need to ready the weapon
-- You do not 

-- return true if free to reload
function SuperSurvivor:NPC_CheckIfCanReadyGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC _FleeWhileReadyingGun() called");

	-- Handle has and is using gun
	if not self:hasGun() then return false end
	if not self:usingGun() then return false end

	local npcWeapon = self.player:getPrimaryHandItem();

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC _FleeWhileReadyingGun() END ---");

	-- Basically if Inf ammo not enabled and you do not have ammo for any gun type, you do not need to ready Gun Hit Chance: 
	-- Need to handle switching to melee
	if not IsInfiniteAmmoEnabled and not self:hasAmmoForPrevGun()
		then return false end

	if self:needToReload() then return true end

	if self:needToReadyGun(npcWeapon) then return true end

	-- Otherwise you need to ready the weapon
	return false;
end

-- Function List for checking specific scenarios of NPC tasks
-- This one is for if the NPC is trying to get out or inside a building but can not
-- This **should** be the complete list of tasks that would get an npc stuck
function SuperSurvivor:NPC_TaskCheck_EnterLeaveBuilding()
	if
		(self:getTaskManager():getCurrentTask() ~= "Enter New Building") and -- AttemptEntryIntoBuildingTask
		(
			(self:getTaskManager():getCurrentTask() == "Find New Building") or -- FindUnlootedBuildingTask
			(self:getTaskManager():getCurrentTask() == "Wander In Area") or
			(self:getTaskManager():getCurrentTask() == "Wander In Base") or
			(self:getTaskManager():getCurrentTask() == "Loot Category") or
			(self:getTaskManager():getCurrentTask() == "Find Building") or
			(self:getTaskManager():getCurrentTask() == "Threaten") or
			(self:getTaskManager():getCurrentTask() == "Attack") or
			(self:getTaskManager():getCurrentTask() == "Pursue") or
			(self:getTaskManager():getCurrentTask() == "Flee")
		)
	then
		return true;
	else
		return false;
	end
end

-- Individual task checklist. This list is used to help for AI-manager lua to not be a clutter
function SuperSurvivor:Task_IsAttack()
	if (self:getTaskManager():getCurrentTask() == "Attack") then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Task_IsThreaten()
	if (self:getTaskManager():getCurrentTask() == "Threaten") then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Task_IsSurender()
	if (self:getTaskManager():getCurrentTask() == "Surender") then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Task_IsDoctor()
	if (self:getTaskManager():getCurrentTask() == "Doctor") then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Task_IsWander()
	if (self:getTaskManager():getCurrentTask() == "Wander") then
		return true;
	else
		return false;
	end
end

function SuperSurvivor:Task_IsPursue()
	if (self:getTaskManager():getCurrentTask() == "Pursue") then
		return true;
	else
		return false;
	end
end

-- Not Gates, these are better to use
function SuperSurvivor:Task_IsNotAttack()
	if (self:getTaskManager():getCurrentTask() ~= "Attack") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotThreaten()
	if (self:getTaskManager():getCurrentTask() ~= "Threaten") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotSurender()
	if (self:getTaskManager():getCurrentTask() ~= "Surender") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotDoctor()
	if (self:getTaskManager():getCurrentTask() ~= "Doctor") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotWander()
	if (self:getTaskManager():getCurrentTask() ~= "Wander") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotPursue()
	if self:getTaskManager():getCurrentTask() ~= "Pursue" then
		return true;
	end
end

function SuperSurvivor:Task_IsNotAttemptEntryIntoBuilding()
	if (self:getTaskManager():getCurrentTask() ~= "Enter New Building") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotFlee()
	if (self:getTaskManager():getCurrentTask() ~= "Flee") then
		return true;
	end
end

function SuperSurvivor:Task_IsNotFleeFromSpot()
	if (self:getTaskManager():getCurrentTask() ~= "Flee From Spot") then
		return true;
	end
end

-- function SuperSurvivor:Task_IsNotFleeOrFleeFromSpot()
-- 	if (not (self:getTaskManager():getCurrentTask() == "Flee")) 
-- 		and (not (self:getTaskManager():getCurrentTask() == "Flee From Spot")) then
-- 		return true;
-- 	end
-- end

-- Super Function: Pursue_SC - Point system for the NPC to pursue a target.
-- Pursue, as far as I've seen, is used any time the NPC needs to reach their target, either it be zombie or human.
-- Todo: add self:RealCanSee(self.LastEnemySeen) senses
npcPursueScoreThresholdDefault = 2
function SuperSurvivor:NPC_CheckPursueScore()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_CheckPursueScore() called");
	local zRangeToPursue = npcPursueScoreThresholdDefault
	if self.LastEnemySeen ~= nil then
		-- ------------------------------------  --
		-- Keep pursue from happening when 	
		-- lots of enemies the npc sees --		
		-- ------------------------------------  --		
		if not self:getGroupRole() == "Companion"
			and self:getSeenCount() > 4 
			and self:isEnemyInRange()
		then
			zRangeToPursue = 0;
			return zRangeToPursue;
		end

		if self.LastEnemySeen == nil 
			and self.player == nil 
		then
			zRangeToPursue = 0;
			return zRangeToPursue;
		end

		if self:getTaskManager():getCurrentTask() == "Enter New Building"
			and not self:RealCanSee(self.LastEnemySeen)
		then
			zRangeToPursue = 0;
			return zRangeToPursue;
		end

		local Distance_AnyEnemy = GetXYDistanceBetween(self.LastEnemySeen, self.player)

		-- To make enemies stop chasing after their target cause too far away.
		-- Unless you have a real reason, you wouldn't pursue a target forever.
		if Distance_AnyEnemy > 10 
			and self:RealCanSee(self.LastEnemySeen) 
		then
			zRangeToPursue = 0;
			return zRangeToPursue;
		end

		-- -------------------------------------- --
		--  Companion: They should always be cautious of their surroundings
		-- -------------------------------------- --
		if self:getGroupRole() == "Companion" 
			and self:isEnemyInRange(self.LastEnemySeen) 
		then
			if GetXYDistanceBetween(getSpecificPlayer(0), self.player) < 10 then
				zRangeToPursue = 5
				return zRangeToPursue
			end

			if GetXYDistanceBetween(getSpecificPlayer(0), self.player) >= 10 then
				zRangeToPursue = 0
				return zRangeToPursue
			end
		end

		-- ------------------------ --
		-- Locked door checker 		--
		-- IFOD 'In front of door' 	--
		-- ------------------------ --
		if (self:NPC_TargetIsOutside() == true) and (self:NPC_IsOutside() == true) then -- NPC's Target AND the NPC itself are Both OUT-SIDE
			zRangeToPursue = 6
			return zRangeToPursue
		end
		if (self:NPC_TargetIsOutside() == false) and (self:NPC_IsOutside() == false) then -- NPC's Target AND the NPC itself are Both INSIDE
			zRangeToPursue = 3
			return zRangeToPursue
		end
		if ((self:NPC_TargetIsOutside() == false) and (self:NPC_IsOutside() == true)) then -- NPC's Target Is Inside | NPC itself Is OUTSIDE		
			zRangeToPursue = 0
			return zRangeToPursue
		end
		if (self:NPC_TargetIsOutside() == true) and (self:NPC_IsOutside() == false) then -- NPC's Target Is OUTSIDE | NPC itself Is Inside	
			zRangeToPursue = 1
			return zRangeToPursue
		end

		-- -------------------------------------- --
		-- Gun Checker
		-- Don't add 'force reload' AI manager does this already
		-- -------------------------------------- --
		if (self:hasGun() == true) then
			if (self:WeaponReady() == true) then
				zRangeToPursue = 6
				return zRangeToPursue
			end
		end

		-- -------------------------------------- --
		-- Check if target is too far away 		
		-- We don't want the NPCs to spam this function if too far away,
		-- so yes, we're double checking range.
		-- IDEA: How ab out making this line option an in game option!
		-- -------------------------------------- --
		if (Distance_AnyEnemy >= 10) then
			zRangeToPursue = 0
			return zRangeToPursue
		end

		if (self:HasMultipleInjury()) and not (self:getGroupRole() == "Companion") then -- Make the NPC not persist pursing until injuries are fixed
			zRangeToPursue = 0
			return zRangeToPursue
		end
	end

	-- This should keep the NPC from returning 0 when the local variable at top is 0
	if (self.LastEnemySeen ~= nil) and (self.player ~= nil) and (zRangeToPursue == 0) then
		self.LastEnemySeen = nil -- To force npc to stop pursuing the first target to re-scan
		return zRangeToPursue
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC_CheckPursueScore() END --- ");
end

-- ----------------------------- --
-- 	The Pursue Task itself 		 --
-- ----------------------------- --
-- Should I pursue the target? true or false
-- Batmane: Never Used after AI Manager Essential Simplification
-- function SuperSurvivor:Task_IsPursue_SC()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Task _IsPursue_SC() called");
-- 	if not self.LastEnemySeen then return false end
-- 	if not self.player then return false end

-- 	local Distance_AnyEnemy = GetXYDistanceBetween(self.LastEnemySeen, self.player)
-- 	-- Add Height difference to pursuit
-- 	if self.LastEnemySeen:getZ() ~= self.player:getZ() then Distance_AnyEnemy = Distance_AnyEnemy + self.LastEnemySeen:getZ() - self.player:getZ() end	
-- 	if self:NPC_CheckPursueScore() > Distance_AnyEnemy  -- Task priority checker -- Will not pursue if enemy is very far away too be bothered
-- 		-- and (Distance_AnyEnemy <= 9) -- This is not needed because pursue score checker handles distance
-- 		and self:hasWeapon()
-- 		and self:Task_IsNotThreaten()
-- 		-- and self:isEnemyInRange(self.LastEnemySeen) -- This seems misleading - Enemy should not need to be in range to pursue
-- 		and self:Task_IsNotPursue()
-- 		and self:Task_IsNotSurender()
-- 		and self:Task_IsNotFlee()
-- 		and self:isWalkingPermitted()
-- 	then
-- 		return true
-- 	end

-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:Task _IsPursue_SC() end --- ");
-- 	return false;
-- end

function SuperSurvivor:NPCTask_DoWander()
	if (self:getTaskManager():getCurrentTask() ~= "Wander") then
		self:getTaskManager():AddToTop(WanderTask:new(self))
	end
end

function SuperSurvivor:NPCTask_DoAttemptEntryIntoBuilding()
	self:NPC_ForceFindNearestBuilding()

	if (self.TargetSquare ~= nil) then
		if (self:NPC_IsOutside() == true) then
			self:getTaskManager():AddToTop(AttemptEntryIntoBuildingTask:new(self, self.TargetBuilding))
		end
	end
end

-- Batmane: So basically, this function runs in a check of an if statement. It counts every single frame and saves the current lifetime of the npc.
-- We take the remainder of the lifetime divided by the updateDelay in order to force the algorithm not to run the full NPC routine update very single frame.
-- This is probably inefficient if there is some other listener that checks 1 or twice per second
-- Config
-- BE CAREFUL Each of these delay tick confis were carefully picked and all execute at the same time after a certain amount of ticks. Keep the base at multiples of 60
globalBaseUpdateDelayTicks = 60 -- Runs once per s at 60 fps
-- globalFightingUpdateDelayTicks = math.ceil(globalBaseUpdateDelayTicks * 1/2)  -- Runs twice per s at 60 fps
globalFightingUpdateDelayTicks = math.ceil(globalBaseUpdateDelayTicks * 1/2)  -- Runs twice per s at 60 fps
-- globalPanicUpdateDelayTicks = math.ceil(globalBaseUpdateDelayTicks * 1/3) -- Runs 3 times per s at 60 fps
globalPanicUpdateDelayTicks = math.ceil(globalBaseUpdateDelayTicks * 1/2) -- Runs 3 times per s at 60 fps

globalSecondsFactor60FPSBase = 60 / globalBaseUpdateDelayTicks  -- Fraction to convert wait into seconds delay
globalSecondsFactor60FPSFighting = 60 / globalFightingUpdateDelayTicks  -- Fraction to convert wait into seconds delay
globalSecondsFactor60FPSPanic = 60 / globalPanicUpdateDelayTicks  -- Fraction to convert wait into seconds delay


-- 2 Wait ticks = 1 real time second where the update Routine does not run
function SuperSurvivor:updateTime()
	self:renderName();
	self.Reducer = self.Reducer + 1;

	CreateLogLine("Update Time", isLocalLoggingEnabled, "SuperSurvivor:updateTime() called");

	-- the lower the value the more frequent survivor:update () gets called, means faster reactions but worse performance
	-- Does not run when waiting is active
	if self.Reducer % self.UpdateDelayTicks == 0 then 
		-- self.Reducer = 0 ; -- Batmane - Testing if we can reset reducer back to 0 to prevent accumulating large numbers -- We cant do this because it is also how AI keeps track of time

		if self.WaitTicks == 0 then
			return true
		else
			self.WaitTicks = self.WaitTicks - 1
			return false
		end
	else
		return false
	end
end

function SuperSurvivor:NPCcalcFractureInjurySpeed(bodypart)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCcalcFractureInjurySpeed() called");
	local b = 0.4;

	if (bodypart:getFractureTime() > 10.0) then
		b = 0.7;
	end

	if (bodypart:getFractureTime() > 20.0) then
		b = 1.0;
	end

	if (bodypart:getSplintFactor() > 0.0) then
		b = b - 0.2 - math.min(bodypart:getSplintFactor() / 10.0, 0.8);
	end
	return math.max(0.0, b);
end

function SuperSurvivor:NPCcalculateInjurySpeed(bodypart, b)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCcalculateInjurySpeed() called");
	local scratchSpeedModifier = bodypart:getScratchSpeedModifier();
	local cutSpeedModifier = bodypart:getCutSpeedModifier();
	local burnSpeedModifier = bodypart:getBurnSpeedModifier();
	local deepWoundSpeedModifier = bodypart:getDeepWoundSpeedModifier();
	local n = 0.0;

	if ((bodypart:getType() == "Foot_L" or bodypart:getType() == "Foot_R") and (bodypart:getBurnTime() > 5.0 or bodypart:getBiteTime() > 0.0 or bodypart:deepWounded() or bodypart:isSplint() or bodypart:getFractureTime() > 0.0 or bodypart:haveGlass())) then
		n = 1.0
		if (bodypart:bandaged()) then
			n = 0.7;
		end

		if (bodypart:getFractureTime() > 0.0) then
			n = self:NPCcalcFractureInjurySpeed(bodypart);
		end
	end

	if (bodypart:haveBullet()) then
		return 1.0;
	end

	if (bodypart:getScratchTime() > 2.0 or bodypart:getCutTime() > 5.0 or bodypart:getBurnTime() > 0.0 or bodypart:getDeepWoundTime() > 0.0 or bodypart:isSplint() or bodypart:getFractureTime() > 0.0 or bodypart:getBiteTime() > 0.0) then
		n = n +
			(bodypart:getScratchTime() / scratchSpeedModifier + bodypart:getCutTime() / cutSpeedModifier + bodypart:getBurnTime() / burnSpeedModifier + bodypart:getDeepWoundTime() / deepWoundSpeedModifier) +
			bodypart:getBiteTime() / 20.0;
		if (bodypart:bandaged()) then
			n = n / 2.0;
		end

		if (bodypart:getFractureTime() > 0.0) then
			n = self:NPCcalcFractureInjurySpeed(bodypart);
		end
	end

	if (b and bodypart:getPain() > 20.0) then
		n = n + bodypart:getPain() / 10.0;
	end
	return n;
end

-- Return slowed speed if legs damage
function SuperSurvivor:NPCgetFootInjurySpeedModifier()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCgetFootInjurySpeedModifier() called");
	local b = true;
	local n = 0.0;
	local n2 = 0.0;

	for i = BodyPartType.UpperLeg_L:index(), (BodyPartType.MAX:index() - 1) do
		local bodydamage = self.player:getBodyDamage()
		local bodypart = bodydamage:getBodyPart(BodyPartType.FromIndex(i));
		local calculateInjurySpeed = self:NPCcalculateInjurySpeed(bodypart, false);

		if (b) then
			n = n + calculateInjurySpeed;
			b = false
		else
			n2 = n2 + calculateInjurySpeed;
			b = true
		end
	end

	if (n > n2) then
		return -(n + n2);
	else
		return n + n2;
	end
end

function SuperSurvivor:NPCgetrunSpeedModifier()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCgetrunSpeedModifier() called");
	local NPCrunSpeedModifier = 1.0;
	local items = self.player:getWornItems()

	for i = 0, items:size() - 1 do
		local item = items:getItemByIndex(i)

		if item ~= nil and (item:getCategory() == "Clothing") then
			NPCrunSpeedModifier = NPCrunSpeedModifier + (item:getRunSpeedModifier() - 1.0);
		end
	end
	local shoeitem = items:getItem("Shoes");

	if not (shoeitem) or (shoeitem:getCondition() == 0) then
		NPCrunSpeedModifier = NPCrunSpeedModifier * 0.85;
	end

	return NPCrunSpeedModifier
end

function SuperSurvivor:NPCgetwalkSpeedModifier()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCgetwalkSpeedModifier() called");
	local NPCwalkSpeedModifier = 1.0;
	local items = self.player:getWornItems()
	local shoeitem = items:getItem("Shoes");

	if not (shoeitem) or (shoeitem:getCondition() == 0) then
		NPCwalkSpeedModifier = NPCwalkSpeedModifier * 0.85;
	end

	return NPCwalkSpeedModifier
end

function SuperSurvivor:NPCcalcRunSpeedModByBag(bag)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCcalcRunSpeedModByBag() called");
	return (bag:getScriptItem().runSpeedModifier - 1.0) *
		(1.0 + bag:getContentsWeight() / bag:getEffectiveCapacity(self.player) / 2.0);
end

-- Calculate speed based on carried item
function SuperSurvivor:NPCgetfullSpeedMod()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCgetfullSpeedMod() called");
	local NPCfullSpeedMod
	local NPCbagRunSpeedModifier = 0

	if (self.player:getClothingItem_Back() ~= nil) and (instanceof(self.player:getClothingItem_Back(), "InventoryContainer")) then
		NPCbagRunSpeedModifier = NPCbagRunSpeedModifier +
			self:NPCcalcRunSpeedModByBag(self.player:getClothingItem_Back():getItemContainer())
	end

	if (self.player:getSecondaryHandItem() ~= nil) and (instanceof(self.player:getSecondaryHandItem(), "InventoryContainer")) then
		NPCbagRunSpeedModifier = NPCbagRunSpeedModifier +
			self:NPCcalcRunSpeedModByBag(self.player:getSecondaryHandItem():getItemContainer());
	end

	if (self.player:getPrimaryHandItem() ~= nil) and (instanceof(self.player:getPrimaryHandItem(), "InventoryContainer")) then
		NPCbagRunSpeedModifier = NPCbagRunSpeedModifier +
			self:NPCcalcRunSpeedModByBag(self.player:getPrimaryHandItem():getItemContainer());
	end
	NPCfullSpeedMod = self:NPCgetrunSpeedModifier() + (NPCbagRunSpeedModifier - 1.0);
	return NPCfullSpeedMod
end

-- Determines Speed based on running, injury, walking
function SuperSurvivor:NPCcalculateWalkSpeed()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPCcalculateW alkSpeed() called");
	local NPCfootInjurySpeedModifier = self:NPCgetFootInjurySpeedModifier();
	self.player:setVariable("WalkInjury", NPCfootInjurySpeedModifier);
	local NPCcalculateBaseSpeed = self.player:calculateBaseSpeed();
	local wmax;

	if self:getRunning() == true then
		-- If Running then calculate run speed with full speed skill and foot injury in mind
		wmax = ((NPCcalculateBaseSpeed - 0.15) * self:NPCgetfullSpeedMod() + self.player:getPerkLevel(Perks.FromString("Sprinting")) / 20.0 - AbsoluteValue(NPCfootInjurySpeedModifier / 1.5));
	else
		wmax = NPCcalculateBaseSpeed * self:NPCgetwalkSpeedModifier();
	end

	-- IsoPlayer functions
	-- Why not just use this: getRunSpeedModifier
	-- Why not just use this: getSpeedMod
	-- updateSpeedModifiers
	-- calculateBaseSpeed

	-- Apply some sort of slow factor? - Is this built in? Why not just use this?
	if (self.player:getSlowFactor() > 0.0) then
		wmax = wmax * 0.05;
	end

	-- Further apply temp movement modifier
	local wmin = math.min(1.0, wmax);
	local bodydamage = self.player:getBodyDamage()
	if (bodydamage) then
		local thermo = bodydamage:getThermoregulator()

		if (thermo) then
			wmin = wmin * thermo:getMovementModifier();
		end
	end

	if self.player:isAiming() then
		self.player:setVariable("StrafeSpeed",
			math.max(
				math.min(0.9 + self.player:getPerkLevel(Perks.FromString("Nimble")) / 10.0, 1.5) *
				math.min(wmin * 2.5, 1.0),
				0.6) * 0.8);
	end

	if self.player:isInTreesNoBush() then
		local cs = self.player:getCurrentSquare()
		if cs and cs:HasTree() then
			local tree = cs:getTree();

			if tree then
				wmin = wmin * tree:getSlowFactor(self.player);
			end
		end
	end
	self.player:setVariable("WalkSpeed", wmin * 0.8);
end

local thresholdMinorStuck = 8
local thresholdMildStuck = 100
local thresholdVeryBadStuck = 250

function SuperSurvivor:CheckForIfStuck() -- This code was taken out of update () and put into a function, to reduce how big the code looked
	-- CreateLogLine("SuperSurvivorStuck", survivorStuckCheck, tostring(self:getName()) .. "SuperSurvivor:CheckFor IfStuck() called");
	-- Counter to determine if NPC has been stuck in the same square
	local cs = self.player:getCurrentSquare()
	if cs then
		if not self.LastSquare or self.LastSquare ~= cs then
			self.TicksSinceSquareChanged = 0
			self.LastSquare = cs
		elseif self.LastSquare == cs then
			self.TicksSinceSquareChanged = self.TicksSinceSquareChanged + 1
		end
	end

	if self:inFrontOfLockedDoor() or self:inFrontOfWindow() -- this may need to be changed to the Xor blocked door?
		and self:getTaskManager():getCurrentTask() ~= "Enter New Building"
		and self.TargetBuilding
		and ((
				self.TicksSinceSquareChanged > 3
				and self:isInAction() == false
				and (
					self:getCurrentTask() == "None"
					or self:getCurrentTask() == "Find This"
					or self:getCurrentTask() == "Find New Building"
				)
			)
			or self:getCurrentTask() == "Pursue")
	then
		self:getTaskManager():AddToTop(AttemptEntryIntoBuildingTask:new(self, self.TargetBuilding))
		self.TicksSinceSquareChanged = 0
	end

	if self.TicksSinceSquareChanged > thresholdMinorStuck 
		and self:isInAction() == false 
		and self:inFrontOfWindow() 
		and self:getCurrentTask() ~= "Enter New Building" 
	then
		self.player:climbThroughWindow(self:inFrontOfWindow())
		self.TicksSinceSquareChanged = 0
	end

	if (self.TicksSinceSquareChanged > thresholdMinorStuck and self:Get():getModData().bWalking == true) or 
		self.TicksSinceSquareChanged > thresholdVeryBadStuck 
	then
		self.StuckCount = self.StuckCount + 1
		CreateLogLine("SuperSurvivorStuck", survivorStuckCheck, tostring(self:getName()) .. " has been in same square for ticks: " ..tostring(thresholdMinorStuck));

		if (self.StuckCount > thresholdMildStuck) and (self.TicksSinceSquareChanged > thresholdVeryBadStuck) then
			CreateLogLine("SuperSurvivorStuck", survivorStuckCheck, tostring(self:getName()) .. " has been stuck for ticks: " ..tostring(thresholdMildStuck) .. ". Gonna give them a push.");
			self.StuckCount = 0
			ISTimedActionQueue.add(ISGetHitFromBehindAction:new(self.player, getSpecificPlayer(0)))
		else
			local xoff = self.player:getX() + ZombRand(-3, 3)
			local yoff = self.player:getY() + ZombRand(-3, 3)
			self:StopWalk()
			self:WalkToPoint(xoff, yoff, self.player:getZ())
			self:Wait(1)
			CreateLogLine("SuperSurvivorStuck", survivorStuckCheck, tostring(self:getName()) .. " has been forced (to unstack) to move around ");
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:CheckFor IfStuck() END ---");
end

-- Start of Survivor Routine Update Functions
-- Batmane: This function will run at least once per second or 3 times per second when in combat
-- TODO: Need to trim down number of executions in this function
---@return boolean
function SuperSurvivor:updateSurvivorStatus()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:updateSurvivor Status() called");
	-- Bail out early for dead survivors because we do not need to process them
	if self:isDead() then
		return false;
	end

	-- Everything in here runs 1 per second if FPS is 60 no matter if UpdateTicksDelay has been intensified
	if self.Reducer % (globalBaseUpdateDelayTicks) 
	then 
		-- Handle Vision, Enemy Counting, Remembering Enemy Target, etc.
		self:DoVisionV3() -- Only allow Vision to run once per second at 60 fps
		-- 
	end

	-- Only runs once every 2 seconds at 60 FPS no matter if UpdateTicksDelay has been intensified
	if self.Reducer % (2 * globalBaseUpdateDelayTicks)
	then
		-- Fire Immunity - This can run every few seconds or so
		-- Disable this because it protects raiders from molotov
		-- if self.player:isOnFire() then
		-- 	self.player:getBodyDamage():RestoreToFullHealth() -- temporarily give some fireproofing as they walk right through fire via pathfinding
		-- 	self.player:setFireSpreadProbability(0);    -- give some fireproofing as they walk right through fire via pathfinding	
		-- end
		-- 

		-- Handle Whether NPC can run, walk, limp
		-- So upon testing, if you disable this, the npc will just walk same speed everywhere
		-- Determines walk speed based on injury and stuff - Works but doesn't need to be calculated more than once or twice per second
		-- Wont matter if theres like a slight delay before limping
		self:NPCcalculateWalkSpeed()
		-- 


		-- Batmane TODO - Try disabling this and seeing if still stuck.
		-- From Cows: Stuck Melee Animation Fix
		if self:isInAction() == false and -- no current timedaction in Q, nor have we set bWalking true so AI is not trying to move character
			self:Get():IsInMeleeAttack() == true
		then                              -- isinmeleeattack means, is any swipe attack state true
			self.SwipeStateTicks = self.SwipeStateTicks + 1

			if self.SwipeStateTicks > 3 then -- if npc has been in 6 seconds (because this function runs once every 2 seconds)  update loops and has been in swipe attack state entire time, assume they are stuck in animation
				CreateLogLine("Stuck Survivor", true, tostring(self:getName()) .. "attemping to unstuck...");
				self:UnStuckFrozenAnim() -- Batmane - trying to phase this out
				self.SwipeStateTicks = 0;
			end
		else
			self.SwipeStateTicks = 0;
		end
		-- 

		-- Batmane - I dont even know what this does - Maybe just try running it every like second?
		self.player:setBlockMovement(true);

		-- Seems to handle path finding but with high game speed? - Maybe run this once per few seconds
		if self.TargetSquare and self.TargetSquare:getZ() ~= self.player:getZ() and getGameSpeed() > 2 then
			self.TargetSquare = nil
			self:StopWalk()
			self:Wait(2) -- from 10 wait at most 4 seconds
		end

		-- Batmane - This can just be run like every 10 minutes or so 
		-- Todo: Currently this checks every 20 s - lets see if the there are issues
		-- self:CheckForIfStuck() -- New function to cleanup the update () function
	end


	-- Batmane TODO - Most of the task manager does not need to update 1-3 times every second unless the ai is attacking.
	-- WIP - Cows: Check if player(0) exists, because during respawn after death, player actually does not exist!
	if 
		-- getSpecificPlayer(0) and
		-- not getSpecificPlayer(0):isAsleep() and
		self:getGroupRole() ~= "Random Solo" -- WIP - Cows: ... "Random Solo" apparently doesn't get tasks updates...
		-- and getSpecificPlayer(0):isAlive() -- WIP - Cows: Added a check isPlayerAlive, otherwise errors will be thrown here.
	then
		-- WIP - Cows: There is actually an error here, and it will run often if the player dies.
		-- CreateLogLine("SuperSurvivorBatmane", true, tostring(self:getName()) .. " group role is " ..tostring(self:getGroupRole()));
		self.MyTaskManager:update()
	end

	-- Batmane: This runs every 8 seconds at 60 fps
	-- This seems like its for tasks that do not need to be updated 1-3 times per second
	-- if self.Reducer % (6 * globalBaseUpdateDelayTicks) == 0 then
	-- 	self:setSneaking(false)
	-- end

	if self.GoFindThisCounter > 0 then self.GoFindThisCounter = self.GoFindThisCounter - 1 end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:updateSurvivor Status() end ---");
end


function SuperSurvivor:updateSurvivorDailyStatus()
	-- Batmane TODO: Undo logging here
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:updateSurvivorDailyStatus() called");
	if self:isDead() then
		return false;
	end


	--control of unmanaged stats
	self.player:getNutrition():setWeight(85);
	self.player:getBodyDamage():setSneezeCoughActive(0);
	self.player:getBodyDamage():setFoodSicknessLevel(0);
	self.player:getBodyDamage():setPoisonLevel(0);
	self.player:getBodyDamage():setUnhappynessLevel(0);
	self.player:getBodyDamage():setHasACold(false);

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:updateSurvivorDailyStatus() end ---");
end

function SuperSurvivor:updateSurvivorHourlyStatus()
	-- Batmane TODO: Undo logging here
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:updateSurvivorHourlyStatus() called");
	if self:isDead() then
		return false;
	end

	-- Emergency save
	self:SaveSurvivor();


	if not SurvivorNeedsFoodWater then
		-- CreateLogLine("Food and Hunger", true, tostring(self:getName()) .. " setting hunger/thirst to zero");
		self.player:getStats():setThirst(0.0);
		self.player:getStats():setHunger(0.0);
	end

	--control of unmanaged stats
	self.player:getStats():setFatigue(0.0);
	self.player:getStats():setIdleboredom(0.0);
	self.player:getStats():setMorale(0.5);
	self.player:getStats():setStress(0.0);
	self.player:getStats():setSanity(1);

	if not SurvivorCanFindWork then
		self.player:getStats():setBoredom(0.0);
	end

	if getSpecificPlayer(0):isAsleep() then
        SSM:AsleepHealAll()
    end


	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:updateSurvivorHourlyStatus() end ---");
end

function SuperSurvivor:updateSurvivor10MinStatus()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:updateSurvivor10MinStatus() called");
	if (self:isDead()) then
		return false;
	end

	-- Batmane: Just scanned the whole project, this only applies if UsingFullAuto is true but UsingFullAuto NEVER gets set to true anywhere. 
	-- TODO: Disable this attribute entirely so we dont waste comp power setting it over and over again
	-- Reenable this if UsingFullAuto is actually properly implemented but its kind of pointless anyways
	self.TriggerHeldDown = false; 


	-- Batmane: Seems weird to me that healing would instantly restore them to full health. Seems kinda unfair to the player.
	-- Batmane: Also This is a generic execution. So every second, if the npc is a distance of 15m away from the player, a random chance of 1/5, and is not onscreen, they heal fully instantly?
	-- Batmane: This essentially is just offscreen healing whenever the player is far away (1/10 random chance to fully heal fully when offscreen)
	if GetDistanceBetween(getSpecificPlayer(0), self.player) > 15
		and ZombRand(10) == 0
		and self:isOnScreen() == false  -- don't wanna be seen healing -- Batamane: This can sort of backfire if for any reason the ai stays close and just never heals
	then
		self.player:getBodyDamage():RestoreToFullHealth() -- to prevent a 'bleed' stutter bug
	end


	if (not RainManager.isRaining()) or (not self.player:isOutside()) then
		self.player:getBodyDamage():setWetness(self.player:getBodyDamage():getWetness() - 0.3);
	end

	self.player:setNPC(true);

	local group = self:getGroup()
	if (group) then group:checkMember(self:getID()) end

	-- Batmane: This manageXP function doesnt seem to ever work for me. I have never seen an ai level up
	-- self:ManageXP()

	self.player:getModData().hitByCharacter = false
	self.player:getModData().semiHostile = false
	self.player:getModData().felldown = nil

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:updateSurvivor10MinStatus() end ---");
end


-- End of Survivor Routine Update Functions



-- A bit on how this function works
-- This function was made because I noticed there's alot of cases the NPCs will just stand in front of a door and loop between tasks or refuses to add a task, or just gets stuck, period.
-- So as a result, this function can be inserted in movement codes, to watch out for doors.
-- Don't add more tasks to this function, Wander task is the only one that turns the NPC around and walks away.
-- If you see 'ManageOutdoorStuck' and 'ManageIndoorStuck', that was my older version attempts at the final result of this function.
function SuperSurvivor:NPC_ManageLockedDoors()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_Manage LockedDoors() called");
	-- Prevent your follers from listening to this rule. Temp solution for now.
	if self:getGroupRole() == "Companion" then 
		self.StuckDoorTicks = 0 
		return
	end

	if self:inFrontOfLockedDoorAndIsOutside() == true or 
		self:NPC_IFOD_BarricadedInside() == true or 
		self:inFrontOfBarricadedWindowAlt() 
	then
		self.StuckDoorTicks = self.StuckDoorTicks + 1

		if self.StuckDoorTicks < 5 then return end
		self:getTaskManager():clear() -- Experiment Batmane
		self:getTaskManager():AddToTop(WanderTask:new(self))
		-- Double failsafe - For being outside, npc should try to go inside
		if self:NPC_IsOutside() == true then
			self:NPC_ForceFindNearestBuilding()
			self:getTaskManager():AddToTop(AttemptEntryIntoBuildingTask:new(self, self.TargetBuilding))
		end

		if self.StuckDoorTicks < 11 then return end

		-- timer will continue going up within an emergency

		if self:getGroupRole() == "Random Solo" then -- Not a player's base allie
			self:getTaskManager():clear()
			self:getTaskManager():AddToTop(WanderTask:new(self))
			self:getTaskManager():AddToTop(FindUnlootedBuildingTask:new(self))
			self:getTaskManager():AddToTop(WanderTask:new(self))
		end

		if self.StuckDoorTicks < 15 then return end

		self:getTaskManager():clear();
		if self.player:getModData().isHostile == false then -- Not a player's base allie
			-- self.lastenemyseen = nil; -- This references nothing - Batmane
			self:getTaskManager():AddToTop(WanderTask:new(self))
		end
		self.StuckDoorTicks = 0;
	else
		self.StuckDoorTicks = 0 -- This will set to 0 if not near the door in general
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC_Manage LockedDoors() end ---");
end

-- Older attempts at ^. the one above does better
-- Unused
-- function SuperSurvivor:ManageOutdoorStuck()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:ManageOutdoorStuck() called");
-- 	-- Todo : remove these lines to test
-- 	if (self:NPC_TaskCheck_EnterLeaveBuilding()) and (self:inFrontOfLockedDoor()) and (self:NPC_IsOutside() == true) and (self:getTaskManager():getCurrentTask() ~= "Wander") then
-- 		self.TicksSinceSquareChanged = self.TicksSinceSquareChanged + 1

-- 		if (self.TicksSinceSquareChanged > 10) then
-- 			self:getTaskManager():AddToTop(WanderTask:new(self))
-- 			self.TicksSinceSquareChanged = 0
-- 		end
-- 	else
-- 		self.TicksSinceSquareChanged = 0
-- 	end
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:ManageOutdoorStuck() end ---");
-- end

-- Unused
-- function SuperSurvivor:ManageIndoorStuck()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:ManageIndoorStuck() called");
-- 	if (self:inFrontOfLockedDoor()) and (self:NPC_IsOutside() == false) and (self:getTaskManager():getCurrentTask() ~= "Wander") then
-- 		self.TicksSinceSquareChanged = self.TicksSinceSquareChanged + 1

-- 		if (self.TicksSinceSquareChanged > 10) then
-- 			self:StopWalk();
-- 			self:getTaskManager():clear();
-- 			self:getTaskManager():AddToTop(WanderTask:new(self));
-- 			self.TicksSinceSquareChanged = 0;
-- 		end
-- 	else
-- 		self.TicksSinceSquareChanged = 0
-- 	end
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:ManageIndoorStuck() end ---");
-- end

function SuperSurvivor:OnDeath()
	CreateLogLine("OnDeath", isLocalLoggingEnabled, "SuperSurvivor:On Death() called");
	CreateLogLine("OnDeath", true, tostring(self:getName()) .. " has died");

	-- CreateLogLine("Test On Death", true, "SS is also handling dead player");

	local ID = self:getID()
	SSM:OnDeath(ID) -- Batmane TODO - Need to remove member from group if they died -- Seems to cause some error in some places

	SurvivorLocX[ID] = nil
	SurvivorLocY[ID] = nil
	SurvivorLocZ[ID] = nil
	if (self.player:getModData().LastSquareSaveX ~= nil) then
		local lastkey = self.player:getModData().LastSquareSaveX ..
			self.player:getModData().LastSquareSaveY .. self.player:getModData().LastSquareSaveZ
		if (lastkey) and (SurvivorMap[lastkey] ~= nil) then
			table.remove(SurvivorMap[lastkey], ID)
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:On Death() end ---");
end

-- Seens to be attached to a listener that gets called a 17 ish times per second - Another source of lag
function SuperSurvivor:PlayerUpdate()
	-- CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, tostring(self:getName()) .. " SuperSurvivor:PlayerUpdate() called at self.Reducer = " .. tostring(self.Reducer));
	if not self.player:isLocalPlayer() then
		-- Seems to handle opening door when player is walking -- Move this to the Main func, have this run like once per second. Why need to update 15 times per second?
		-- Doesnt seem to work when moved to routine
		if (self.player:getLastSquare() ~= nil) then
			local cs = self.player:getCurrentSquare()
			local ls = self.player:getLastSquare()
			local tempdoor = ls:getDoorTo(cs);

			if (tempdoor ~= nil and tempdoor:IsOpen()) then
				tempdoor:ToggleDoor(self.player);
			end
		end

		self:WalkToUpdate(); -- This is needed otherwise AI cant path at all. They just run off whichever way they face
		-- Why cant we do this like every second? Lets try it - May 19- Batmane -- Seems like they dont walk
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:PlayerUpdate() end ---");
end

-- Handle path finding attached to event listener that updates multiple times per second
function SuperSurvivor:WalkToUpdate()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:WalkToUpdate() called");
	if self.player:getModData().bWalking then
		local myBehaviorResult = self.player:getPathFindBehavior2():update()

		if myBehaviorResult == BehaviorResult.Failed or myBehaviorResult == BehaviorResult.Succeeded then
			self:StopWalk()
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:WalkToUpdate() end ---");
end

-- Batmane Just Stop Walking Nothing Else -- Doesnt work that well, ai seems to run in the spot
function SuperSurvivor:StopWalkOnly()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:StopWalk Only() called");
	-- ISTimedActionQueue.clear(self.player)
	-- self.player:StopAllActionQueue()
	self.player:setPath2(nil)
	self.player:getModData().bWalking = false
	self.player:getModData().Running = false
	self:setRunning(false)
	-- self.player:setSneaking(false)


	
	self.player:NPCSetJustMoved(false)
	-- self.player:NPCSetAttack(false)
	-- self.player:NPCSetMelee(false)
	-- self.player:NPCSetAiming(false)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:StopWalk Only() end ---");
end


function SuperSurvivor:StopWalk()
	CreateLogLine("StopWalk", isLocalLoggingEnabled, tostring(self:getName()) .. " SuperSurvivor:StopWalk() called");
	ISTimedActionQueue.clear(self.player)
	self.player:StopAllActionQueue()
	self.player:setPath2(nil)
	self.player:getModData().bWalking = false
	self.player:getModData().Running = false
	self:setRunning(false)
	self.player:setSneaking(false)
	self.player:NPCSetJustMoved(false)

	-- self.player:NPCSetAttack(false) -- Batmane, I dont think we need this. It just freezes animation whenever it gets called when AI is in the middle of an attack
	-- self.player:NPCSetMelee(false)  -- Batmane, I dont think we need this. It just freezes animation whenever it gets called when AI is in the middle of an attack
	
	self.player:NPCSetAiming(false)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:StopWalk() end ---");
end

function SuperSurvivor:ManageXP()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:ManageXP() called");
	local currentLevel
	local currentXP, XPforNextLevel
	local ThePerk
	for i = 1, #SurvivorPerks do
		ThePerk = Perks.FromString(SurvivorPerks[i])
		if (ThePerk) then
			currentLevel = self.player:getPerkLevel(ThePerk)
			currentXP = self.player:getXp():getXP(ThePerk)
			XPforNextLevel = self.player:getXpForLevel(currentLevel + 1)

			local display_perk = PerkFactory.getPerkName(Perks.FromString(SurvivorPerks[i]))

			if (currentXP >= XPforNextLevel) and (currentLevel < 10) then
				self.player:LevelPerk(ThePerk)


				if (string.match(SurvivorPerks[i], "Blade")) or (SurvivorPerks[i] == "Axe") then
					display_perk = getText("IGUI_perks_Blade") .. " " .. display_perk
				elseif (string.match(SurvivorPerks[i], "Blunt")) then
					display_perk = getText("IGUI_perks_Blunt") .. " " .. display_perk
				end

				self:RoleplaySpeak(Get_SS_UIActionText("PerkLeveledUp_Before") ..
					tostring(display_perk) .. Get_SS_UIActionText("PerkLeveledUp_After"))
			end
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:ManageXP() end ---");
end

function SuperSurvivor:getTaskManager()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getTaskManager() called");
	return self.MyTaskManager
end

function SuperSurvivor:HasMultipleInjury()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:HasMultipleInjury() called");
	local bodyparts = self.player:getBodyDamage():getBodyParts()
	local total = 0
	for i = 0, bodyparts:size() - 1 do
		local bp = bodyparts:get(i)
		if (bp:HasInjury()) and (bp:bandaged() == false) then
			total = total + 1
			if (total > 1) then break end
		end
	end

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:HasMultipleInjury() end ---");
	return (total > 1)
end

function SuperSurvivor:HasInjury()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:HasInjury() called");
	local bodyparts = self.player:getBodyDamage():getBodyParts()

	for i = 0, bodyparts:size() - 1 do
		local bp = bodyparts:get(i)
		if (bp:HasInjury()) and (bp:bandaged() == false) then
			return true
		end
	end

	return false
end

function SuperSurvivor:getID()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getID() called");
	if (instanceof(self.player, "IsoPlayer")) then
		return self.player:getModData().ID
	else
		return 0
	end
end

function SuperSurvivor:setID(id)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setID() called");
	self.player:getModData().ID = id;
end

function SuperSurvivor:deleteSurvivor()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:deleteSurvivor() called");

	CreateLogLine("NPC Load Survivor Management", true, "Calling delete survivor");

	self.player:getInventory():emptyIt();
	self.player:setPrimaryHandItem(nil);
	self.player:setSecondaryHandItem(nil);
	self.player:getModData().ID = 0;
	local filename = GetModSaveDir() .. "SurvivorTemp"; -- Whats the point of saving this if it is never used.
	self.player:save(filename);
	self.player:removeFromWorld()
	self.player:removeFromSquare()
	self.player = nil;

	self = nil
end

function SuperSurvivor:SaveSurvivorOnMap()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Save SurvivorOnMap() called");
	if self.player:getModData().RealPlayer == true then return false end
	local ID = self.player:getModData().ID;

	if (ID ~= nil) then
		local x = math.floor(self.player:getX())
		local y = math.floor(self.player:getY())
		local z = math.floor(self.player:getZ())
		local key = x .. y .. z

		if (not SurvivorMap[key]) then SurvivorMap[key] = {} end

		SurvivorLocX[ID] = x
		SurvivorLocY[ID] = y
		SurvivorLocZ[ID] = z

		if (CheckIfTableHasValue(SurvivorMap[key], ID) == false) then
			local removeFailed = false;
			if (self.player:getModData().LastSquareSaveX ~= nil) then
				local lastkey = self.player:getModData().LastSquareSaveX ..
					self.player:getModData().LastSquareSaveY .. self.player:getModData().LastSquareSaveZ
				if (lastkey) and (SurvivorMap[lastkey] ~= nil) then
					table.remove(SurvivorMap[lastkey], ID);
				else
					removeFailed = true;
				end
			end

			if (removeFailed == false) then
				table.insert(SurvivorMap[key], ID);
				self.player:getModData().LastSquareSaveX = x;
				self.player:getModData().LastSquareSaveY = y;
				self.player:getModData().LastSquareSaveZ = z;
			end
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:Save SurvivorOnMap() end ---");
end

function SuperSurvivor:SaveSurvivor()
	CreateLogLine("Saving", true, "Saving Survivor");

	if self.player:getModData().RealPlayer == true then return false end

	local ID = self.player:getModData().ID;

	if (ID ~= nil) then
		local filename = GetModSaveDir() .. "Survivor" .. tostring(ID);
		self.player:save(filename);

		if (self.player ~= nil and self.player:isDead() == false) then
			self:SaveSurvivorOnMap()
		else
			local group = self:getGroup()
			if (group) then
				group:removeMember(self)
			end
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:Save Survivor() end ---");
end

function SuperSurvivor:FindClosestOutsideSquare(thisBuildingSquare)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:FindClosestOutsideSquare() called");
	if (thisBuildingSquare == nil) then return nil end

	local bx = thisBuildingSquare:getX()
	local by = thisBuildingSquare:getY()
	local px = self.player:getX()
	local py = self.player:getY()
	local xdiff = AbsoluteValue(bx - px)
	local ydiff = AbsoluteValue(by - py)

	if (xdiff > ydiff) then
		if (px > bx) then
			for i = 1, 20 do
				local sq = getCell():getGridSquare(bx + i, by, 0)
				if (sq ~= nil and sq:isOutside()) then return sq end
			end
		else
			for i = 1, 20 do
				local sq = getCell():getGridSquare(bx - i, by, 0)
				if (sq ~= nil and sq:isOutside()) then return sq end
			end
		end
	else
		if (py > by) then
			for i = 1, 20 do
				local sq = getCell():getGridSquare(bx, by + i, 0)
				if (sq ~= nil and sq:isOutside()) then return sq end
			end
		else
			for i = 1, 20 do
				local sq = getCell():getGridSquare(bx, by - i, 0)
				if (sq ~= nil and sq:isOutside()) then return sq end
			end
		end
	end

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:FindClosestOutsideSquare() end ---");
	return thisBuildingSquare
end


-- Easy Spare Magazie Reload
-- Copied from ISUI/ISFirearmRadialMenu
local function predicateNotFullMagazine(item, magazineType)
	return (item:getType() == magazineType or item:getFullType() == magazineType) and item:getCurrentAmmoCount() < item:getMaxAmmo()
end

-- Copied from ISUI/ISFirearmRadialMenu
local function predicateFullestMagazine(item1, item2)
	return item1:getCurrentAmmoCount() - item2:getCurrentAmmoCount()
end

-- Copied from ESMR
function SuperSurvivor:LoadBulletsSpareMag()
	-- CreateLogLine("LoadBulletsSpareMag", true, tostring(self:getName()) .. " is reloading best spare mag");

	local player = self.player;
	if player == nil then return end

	local weapon = player:getPrimaryHandItem()
	if not weapon then return end
	if not instanceof(weapon, "HandWeapon") then return end
	if not weapon:isRanged() then return end
	
	if not weapon:getMagazineType() then return end
	
	local inventory = player:getInventory()
	local magazine = inventory:getBestEvalArgRecurse(predicateNotFullMagazine, predicateFullestMagazine, weapon:getMagazineType())
	if not magazine then return end
	
	ISInventoryPaneContextMenu.transferIfNeeded(player, magazine)

	if not (inventory:getCountTypeRecurse(magazine:getAmmoType()) > 0) then return end

	local ammoCount = ISInventoryPaneContextMenu.transferBullets(player, magazine:getAmmoType(), magazine:getCurrentAmmoCount(), magazine:getMaxAmmo())
	if ammoCount == 0 then return end

	-- Animation
	if ZombRand(0, 3) == 0 then 
		self:setSneaking(true)
	end
	
	-- CreateLogLine("LoadBulletsSpareMag", true, tostring(self:getName()) .. " is loading bullets into spare mag");
	ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(player, magazine, ammoCount))
end
-- 

local numAddMagsInfAmmo = 3

--- Cows: Need to rewrite this function...
-- Batmane This is still used as a boolean in Attack Task to switch them to melee when this returns false
-- Returns true if failed to ready gun but can still proceed to ready it
-- Returns filse if cannot continue to ready gun
function SuperSurvivor:ReadyGun(weapon)
	CreateLogLine("Ready Weapon", isLocalLoggingEnabled, tostring(self:getName()) .. " is readying their gun");

	if weapon:isJammed() then
		-- CreateLogLine("Ready Weapon", true, tostring(self:getName()) .. " has a gun jam");
		ISReloadWeaponAction.OnPressRackButton(self.player, weapon) -- Rack weapon to clear jam - Batmane
		weapon:setJammed(false);
		-- self:Wait(1); -- Cows: Wait 1 ticks to clear the Jam. -- Batmane - we dont want to wait because this skips processing that might get them killed
		self:Speak("Damn my gun is jammed!");
		return true -- Return early if weapon is jammed - we handle it just here
	end

	if weapon:haveChamber() and not weapon:isRoundChambered() then
		if ISReloadWeaponAction.canRack(weapon) then
			-- CreateLogLine("Ready Weapon", true, tostring(self:getName()) .. " is racking weapon");
			ISReloadWeaponAction.OnPressRackButton(self.player, weapon)
			return true
		end
	end

	local inventoryAmmoCount = self:gunAmmoInInvCount(weapon)
	local weaponAmmoCount = weapon:getCurrentAmmoCount()

	-- Handle All Guns WITH Magazine
	if weapon:getMagazineType() then
		-- Search for a magazine
		local magazine = weapon:getBestMagazine(self.player)
		if not magazine then magazine = self.player:getInventory():getFirstTypeRecurse(weapon:getMagazineType()) end

		-- Inf Ammo: Handle Adding Magazine
		if IsInfiniteAmmoEnabled and not magazine then
			for i = 1, numAddMagsInfAmmo do
				magazine = self.player:getInventory():AddItem(weapon:getMagazineType());
			end
		end

		-- Weapon DOES NOT contains loaded magazine/clip inside the gun
		if weapon:isContainsClip() == false then
			CreateLogLine("Ready Weapon", isLocalLoggingEnabled, tostring(self:getName()) .. " is handling gun WITHOUT clip");
			if not magazine then return false end -- Case: No Clip inserted but no magazine found

			-- Inf Ammo: Fill the magazine -- This doesnt ever fire and I never felt we needed it. -- Todo Delete this
			-- local ammotype = magazine:getAmmoType();
			-- if 
			-- 	IsInfiniteAmmoEnabled and 
			-- 	not self.player:getInventory():containsWithModule(ammotype) and 
			-- 	magazine:getCurrentAmmoCount() == 0
			-- then
			-- 	CreateLogLine("Inf Ammo", true, tostring(self:getName()) .. " is setting ammo to max");
			-- 	magazine:setCurrentAmmoCount(magazine:getMaxAmmo())
			-- end
			-- 

			-- Load Magazine if you Can
			ISInventoryPaneContextMenu.transferIfNeeded(self.player, magazine) -- Transfer magazine from bag?
			ISTimedActionQueue.add(ISInsertMagazine:new(self.player, weapon, magazine))
			ISReloadWeaponAction.ReloadBestMagazine(self.player, weapon)

			return true
		-- Weapon DOES contains loaded magazine/clip inside the gun
		else
			CreateLogLine("Ready Weapon", isLocalLoggingEnabled, tostring(self:getName()) .. " is handling gun with clip");
			if inventoryAmmoCount <= 0 then
				if IsInfiniteAmmoEnabled then 
					CreateLogLine("Inf Ammo", isLocalLoggingEnabled, tostring(self:getName()) .. " is adding loose bullets");

					local maxammo = magazine:getMaxAmmo() * numAddMagsInfAmmo
					local amtype = magazine:getAmmoType()
	
					-- Add Ammo
					for i = 0, maxammo do
						local am = instanceItem(amtype)
						self.player:getInventory():AddItem(am)
					end
				else
					-- Open a box for ammo
					local ammo = self:openBoxForGun()

					-- If no boxes, ammo in gun, ammo in mags, cannot ready gun
					-- Batmane - Testing logic to check best magazine has no ammo
					if not ammo and weaponAmmoCount <= 0 and magazine:getCurrentAmmoCount() <= 0 then return false end
				end
				-- Batmane - Why can you only open a box if you have weapon contains clip and not when it doesnt contain clip
			end

			-- Eject Magazine and reload next
			if 
				(self.EnemiesOnMe <= 0 
				and weaponAmmoCount < weapon:getMaxAmmo()) -- no more enemies around to fight 
				or weaponAmmoCount == 0 -- Ran out of ammo
			then
				CreateLogLine("Eject Mag", isLocalLoggingEnabled, tostring(self:getName()) .. " is ejecting magazine");
				-- Eject magazine
				ISTimedActionQueue.add(ISEjectMagazine:new(self.player, weapon))

				-- Reload best magazine into gun immediately after ejecting magazine
				ISTimedActionQueue.queueActions(self.player, ISReloadWeaponAction.ReloadBestMagazine, weapon)
				return true
			end

			return true
		end
	-- Handle All Guns with No Magazine
	else
		-- CreateLogLine("Ready Weapon", true, tostring(self:getName()) .. " is reloading gun with no magazine");
		local maxammo = weapon:getMaxAmmo();
		local ammotype = weapon:getAmmoType();

		if IsInfiniteAmmoEnabled and self:gunAmmoInInvCount(weapon) <= 0 then
			CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, self:getName() .. " needs to spawn ammo type:" .. tostring(ammotype));
			for i = 0, maxammo do
				local am = instanceItem(ammotype)
				self.player:getInventory():AddItem(am)
			end
		end

		-- if can't have more bullets, we don't do anything, this doesn't apply for magazine-type guns (you'll still remove the current clip)
		if weaponAmmoCount >= maxammo then
			return true
		end

		--  Open box to get more bullets for your gun 
		local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.player, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
		if ammoCount <= 0 then
			local ammo = self:openBoxForGun()
			if not ammo and weaponAmmoCount <= 0 then
				return false
			end
		end
			
		-- Reload Rounds if no enemies on you and ammo less than max or ammo is 0
		if 
			(self.EnemiesOnMe <= 0 
			and weapon:getCurrentAmmoCount() < weapon:getMaxAmmo()
			and not self:isReloading() )
			or weaponAmmoCount == 0
		then
			ISTimedActionQueue.add(ISReloadWeaponAction:new(self.player, weapon))
		end

		-- if there's bullets in the gun and we're in danger, just keep shooting
		if weaponAmmoCount > 0 and self.EnemiesOnMe > 0 then
			return true
		end

		return true
	end

	-- Final Determination - Can you shoot?
	if not ISReloadWeaponAction.canShoot(weapon) then
		return false
	else
		return true
	end
end

-- Batmane - This function doesnt seem to account for bolt action weapons as those weapons can be fired automatically
function SuperSurvivor:needToReadyGun(weapon)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:needToReadyGun() called");
	if not weapon then return false end
	if not self:usingGun() then return false end
	if not ISReloadWeaponAction.canShoot(weapon) 
	then
		return true
	end
	return false
end

function SuperSurvivor:gunAmmoInInvCount(gun)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:gunAmmoInInvCount() called");
	local ammoType = gun:getAmmoType()
	if ammoType then
		local ammoCount = self.player:getInventory():getItemCountRecurse(ammoType)
		return ammoCount
	end
	return 0
end

function SuperSurvivor:needToReload()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:need ToReload() called");
	if not self:usingGun() then return false end
	local weapon = self.player:getPrimaryHandItem()
	if (not weapon) then return false end
	if (not self:isReloading() and weapon:getAmmoType() and (weapon:getCurrentAmmoCount() < weapon:getMaxAmmo())) then
		self:Speak("I need to reload!")
		return true
	end
	return false

end

function SuperSurvivor:isReloading()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:isReloading() called");
	return self.player:getVariableBoolean("isLoading")
end

function SuperSurvivor:giveWeapon(weaponType, equipIt)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:giveWeapon() called");

	--  Batmane Reenable assault rifles
	-- if weaponType == "AssaultRifle" 
	-- 	or weaponType == "AssaultRifle2" 
	-- then 
	-- 	weaponType = "VarmintRifle" end -- temporarily disable assult rifles

	local weapon = self.player:getInventory():AddItem(weaponType);
	if weapon == nil then return false end

	if weapon:isAimedFirearm() then
		self:setGunWep(weapon)
	else
		self:setMeleeWep(weapon)
	end

	if weapon:getMagazineType() ~= nil then
		self.player:getInventory():AddItem(weapon:getMagazineType());
	end

	if equipIt then
		self.player:setPrimaryHandItem(weapon)
		if (weapon:isRequiresEquippedBothHands() or weapon:isTwoHandWeapon()) then
			self.player:setSecondaryHandItem(
				weapon)
		end
	end

	local ammotypes = GetAmmoBullets(weapon);
	if ammotypes then
		local bwep = self.player:getInventory():AddItem(SS_MeleeWeapons[ZombRand(1, #SS_MeleeWeapons)]) -- give a beackup melee wepaon if using ammo gun
		
		if bwep then
			self.player:getModData().weaponmelee = bwep:getType()
			self:setMeleeWep(bwep)
		end

		local ammo = ammotypes[1]
		if (ammo) then
			local ammobox = GetAmmoBox(ammo)
			if (ammobox ~= nil) then
				local randomammo = ZombRand(1, 4);

				for i = 0, randomammo do
					self.player:getInventory():AddItem(ammobox);
				end
			end
		end
		ammotypes = GetAmmoBullets(weapon);
		---@diagnostic disable-next-line: need-check-nil
		self.player:getModData().ammoCount = self:FindAndReturnCount(ammotypes[1])
	else
		CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "no ammo types for weapon:" .. tostring(weapon:getType()));
	end
end

function SuperSurvivor:FindAndReturn(thisType)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:FindAndReturn() called");
	local item
	item = self.player:getInventory():FindAndReturn(thisType);

	if (not item) and (self.player:getSecondaryHandItem() ~= nil) and (self.player:getSecondaryHandItem():getCategory() == "Container") then
		item = self.player:getSecondaryHandItem():getItemContainer():FindAndReturn(thisType);
	end

	if (not item) and (self.player:getClothingItem_Back() ~= nil) then
		item = self.player:getClothingItem_Back():getItemContainer():FindAndReturn(thisType);
	end

	return item
end

function SuperSurvivor:FindAndReturnCount(thisType)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:FindAndReturnCount() called");
	if (thisType == nil) then return 0 end

	local count = 0
	count = count + self.player:getInventory():getItemsFromType(thisType):size()

	if (self.player:getSecondaryHandItem() ~= nil) and (self.player:getSecondaryHandItem():getCategory() == "Container") then
		count =
			count + self.player:getSecondaryHandItem():getItemContainer():getItemsFromType(thisType):size()
	end

	if (self.player:getClothingItem_Back() ~= nil) then
		count = count +
			self.player:getClothingItem_Back():getItemContainer():getItemsFromType(thisType):size()
	end

	return count
end

function SuperSurvivor:WeaponReady()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:WeaponReady() called");
	local primary = self.player:getPrimaryHandItem()

	if (primary ~= nil) and (self.player ~= nil) and (instanceof(primary, "HandWeapon")) and (primary:isAimedFirearm()) then
		primary:setCondition(primary:getConditionMax())
		primary:setJammed(false);
		primary:getModData().isJammed = nil

		local ammo, ammoBox, result;

		local bulletcount = 0
		for i = 1, #self.AmmoTypes do
			bulletcount = bulletcount + self:FindAndReturnCount(self.AmmoTypes[i])
		end

		self.player:getModData().ammoCount = bulletcount

		for i = 1, #self.AmmoTypes do
			ammo = self:FindAndReturn(self.AmmoTypes[i])
			if (ammo) then break end
		end
		if (not ammo) and (IsInfiniteAmmoEnabled) then
			ammo = self.player:getInventory():AddItem(self.AmmoTypes[1])
		end

		if (not ammo) then
			self.TriggerHeldDown = false
			ammo = self:openBoxForGun()
		end

		if (not ISReloadWeaponAction.canShoot(primary)) then
			return self:ReadyGun(primary)
		else
			return true
		end
	end

	return true
end

function SuperSurvivor:openBoxForGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:openBoxForGun() called");
	local index = 0
	local ammoBox = nil

	for i = 1, #self.AmmoBoxTypes do
		index = i
		ammoBox = self:FindAndReturn(self.AmmoBoxTypes[i])
		if ammoBox then break end
	end

	if ammoBox then
		local ammotype = self.AmmoTypes[index]
		local inv = self.player:getInventory()

		local modl = ammoBox:getModule() .. "."

		local tempBullet = instanceItem(modl .. ammotype)
		local bulletCount = tempBullet:getCount()
		local count = 0

		count = (GetBoxCount(ammoBox:getType()) / bulletCount)

		for i = 1, count do
			inv:AddItem(modl .. ammotype)
		end

		self:RoleplaySpeak(Get_SS_UIActionText("Opens_Before") ..
			ammoBox:getDisplayName() .. Get_SS_UIActionText("Opens_After"))
		ammoBox:getContainer():Remove(ammoBox)
		return self.player:getInventory():FindAndReturn(ammotype);
	end
end

-- Seems to look for ammo of some type that they have
function SuperSurvivor:hasAmmoForPrevGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:has AmmoForPrevGun() called");
	if self.AmmoTypes ~= nil and #self.AmmoTypes > 0 then
		local ammoRound
		for i = 1, #self.AmmoTypes do
			ammoRound = self:FindAndReturn(self.AmmoTypes[i])
			if ammoRound then break end
		end

		if ammoRound ~= nil then
			return true
		end

		local ammoBox
		for i = 1, #self.AmmoBoxTypes do
			ammoBox = self:FindAndReturn(self.AmmoBoxTypes[i])
			if ammoBox then break end
		end

		if ammoBox ~= nil then
			return true
		end
	end

	return false
end

-- Seems to get survivor to rerequip some past gun that that had under LastGunUsed
-- This do this if 
function SuperSurvivor:reEquipGun()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:re EquipGun() called");	
	if self.LastGunUsed == nil then return false end

	-- If weapon is 2 handed then do not have anything in 2nd hand
	if self.player:getPrimaryHandItem() ~= nil and self.player:getPrimaryHandItem():isTwoHandWeapon() then
		self.player:setSecondaryHandItem(nil)
	end

	-- Equip last gun
	self.player:setPrimaryHandItem(self.LastGunUsed)

	-- Player uses last gun with both hands
	if self.LastGunUsed:isTwoHandWeapon() then
		self.player:setSecondaryHandItem(self.LastGunUsed)
	end
	return true

end

function SuperSurvivor:reEquipMelee()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:reEquipMelee() called");
	if self.LastMeleeUsed == nil then return false end

	if self.player:getPrimaryHandItem() ~= nil and self.player:getPrimaryHandItem():isTwoHandWeapon() then
		self.player:setSecondaryHandItem(nil)
	end

	self.player:setPrimaryHandItem(self.LastMeleeUsed)

	if self.LastMeleeUsed:isTwoHandWeapon() then
		self.player:setSecondaryHandItem(self.LastMeleeUsed)
	end

	return true
end

function SuperSurvivor:setLastWeapon()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:setLastWeapon() called");
	if (self:usingGun()) then
		self.player:getModData().lastWepWasGun = true
	else
		self.player:getModData().lastWepWasGun = false
	end

	return true
end

function SuperSurvivor:reEquipLastWeapon()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:reEquipLastWeapon() called");

	if self.player:getModData().lastWepWasGun then
		self:reEquipGun()
	else
		self:reEquipMelee()
	end

	return true
end

function SuperSurvivor:setMeleeWep(handWeapon)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:set MeleeWep() called");
	self:Get():getModData().meleeWeapon = handWeapon:getType()
	self.LastMeleeUsed = handWeapon
end

function SuperSurvivor:setGunWep(handWeapon)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:set GunWep() called");
	self:Get():getModData().gunWeapon = handWeapon:getType()
	self.LastGunUsed = handWeapon
end

local defaultMinRange = 0.5
local defaultMaxRange = 0.75
function SuperSurvivor:getMinWeaponRange()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getMinWeaponRange() called");
	local out = defaultMinRange

	if self.player:getPrimaryHandItem() ~= nil 
		and instanceof(self.player:getPrimaryHandItem(), "HandWeapon")
	then
		return self.player:getPrimaryHandItem():getMinRange()
	end

	return out
end


function SuperSurvivor:getMaxWeaponRange()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getMinWeaponRange() called");
	local out = defaultMaxRange

	if self.player:getPrimaryHandItem() ~= nil 
		and instanceof(self.player:getPrimaryHandItem(), "HandWeapon")
	then
		return self.player:getPrimaryHandItem():getMaxRange()
	end

	return out
end

-- This function watches over if they're too close to a target or the main player and forces walk if they are.
-- That way they don't trip over each other (and more importantly the main player)
-- This function is used mainly in the combat related tasks, but could be used elsewhere if the npc is running over the main player often.
-- 6/21/2022: If I set 'setruning' to true , then else false? NPCs will run into each other! But if it looks like what it is now, it works fine!
-- 		This literally implies it will check top to bottom priority. I'm writing this to remind myself for the future.
--	instanceof(self.player:getCell():getObjectList(),"IsoPlayer") < - hold this for now
function SuperSurvivor:NPC_ShouldRunOrWalk()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_Should RunOrWalk() called");
	if self.LastEnemySeen ~= nil then
		local distance = self.LastEnemySeenDistance
		if not distance then 
			distance = GetXYDistanceBetween(self.parent.LastEnemySeen, self.parent.player)
		end

		local distanceToPlayer = self.distanceToPlayer0 -- To prevent running into the player
		if not distanceToPlayer then 
			distanceToPlayer = GetCheap3DDistanceBetween(self.player, getSpecificPlayer(0)) 
		end

		if not distance or not distanceToPlayer then return end

		if 
			-- (self:Task_IsNotFlee() and self:Task_IsNotFleeFromSpot())
			distanceToPlayer <= 2 
			or distance <= 15 -- Lets just say they should walk if enemy exists and distance is less than 15 otherwise run
			-- or self:Task_IsAttack() 
			-- or self:Task_IsThreaten() 
			-- or self:Task_IsPursue() 
		then
			self:setRunning(false)
		else
			self:setRunning(true)
		end
	else
		self:setRunning(false)
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC_Should RunOrWalk() end ---");
end

tooCloseToPlayerToRun = 2
function SuperSurvivor:NPC_EnforceWalkNearMainPlayer()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_ EnforceWalkNearMainPlayer() called");
	-- Emergency failsafe to prevent NPCs from running into player

	local distanceToPlayer0 = self.distanceToPlayer0
	if not distanceToPlayer0 then 
		distanceToPlayer0 = GetXYDistanceBetween(self.player, getSpecificPlayer(0))
	end
	if distanceToPlayer0 <= tooCloseToPlayerToRun and getSpecificPlayer(0):getZ() == self.player:getZ() then
		self:setRunning(false)
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC_ EnforceWalkNearMainPlayer() end ---");
end

-- ERW stands for 'EnforceRunWalk'
-- No longer used
-- function SuperSurvivor:NPC_ERW_AroundMainPlayer(VarDist)
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC_ERW_ AroundMainPlayer() called");
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:GetDistanceBetween() called");

-- 	local distanceToPlayer0 = self.distanceToPlayer0
-- 	if not distanceToPlayer0 then 
-- 		distanceToPlayer0 = GetXYDistanceBetween(self.player, getSpecificPlayer(0))
-- 	end

-- 	if distanceToPlayer0 > VarDist and getSpecificPlayer(0):getZ() == self.player:getZ()
-- 	then
-- 		if self:isInAction() == true then
-- 			self:setRunning(true)
-- 		end
-- 	else
-- 		if self:isInAction() == false then
-- 			self:setRunning(false)
-- 		end
-- 	end
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC_ERW_ AroundMainPlayer() end ---");
-- end


-- Manages movement and movement speed
-- Walks to target
-- Does not handle kiting
function SuperSurvivor:NPC_MovementManagement_Guns()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC _MovementManagement_Guns() called");

	if not self:isWalkingPermitted() then return end

	local cs = self.LastEnemySeenSquare
	if not cs then 
		cs = self.LastEnemySeen:getCurrentSquare()
	end
	if not cs then return end

	local distance = self.LastEnemySeenDistance
	if not distance then 
		distance = GetCheap3DDistanceBetween(self.player, self.LastEnemySeen)
	end
	if not distance then return end
	local minrange = self:getMinWeaponRange() + 0.1

	local zNPC_AttackRange = self:isEnemyInRange(self.LastEnemySeen)

	-- if zNPC_AttackRange then self:StopWalk() end -- Not sure if this needs to be handled here
	if not zNPC_AttackRange then
		-- The actual walking itself
		if instanceof(self.LastEnemySeen, "IsoPlayer") then
			self:walkToDirect(cs)
		else
			local fs = cs:getTileInDirection(self.LastEnemySeen:getDir())
			if (fs) and (fs:isFree(true)) then
				self:walkToDirect(fs)
			else
				self:walkToDirect(cs)
			end
		end
	elseif self.EnemiesOnMe >= 2 and distance < minrange + 2 then
		CreateLogLine("Kiting with gun", true, tostring(self:getName()) .. " is kiting");

		-- WIP
		local targetSquareToTravelTo = getXYSq2FromSq1ToVector(self.player, convertToUnitVector(self.escapeVector), 3)
		if not targetSquareToTravelTo or
			not targetSquareToTravelTo.x or
			not targetSquareToTravelTo.y
		then
			CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot calculate a target to travel to')
			self.Complete = true
			return
		end
		local targetSquareObj = self.player:getCell():getGridSquare(targetSquareToTravelTo.x, targetSquareToTravelTo.y, self.player:getZ())
		self:walkTo(targetSquareObj)
		-- WIP

	end

	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC _MovementManagement_Guns() end ---");
end



-- Manages movement and movement for AttackTask.
function SuperSurvivor:NPC_MovementManagement_Melee()
	CreateLogLine("Batmane NPC_MovementManagement_Melee", isLocalLoggingEnabled, "Ran NPC_MovementManagement _Melee");

	if not self:isWalkingPermitted() then return end -- Not permitted to move
	if not self.LastEnemySeen then return end -- No Enemy to walk to

	local cs = self.LastEnemySeenSquare
	if not cs then 
		cs = self.LastEnemySeen:getCurrentSquare()
	end
	if not cs then return end

	local distance = self.LastEnemySeenDistance
	if not distance then 
		distance = GetCheap3DDistanceBetween(self.player, self.LastEnemySeen)
	end
	if not distance then return end

	local walkRange = self:getMaxWeaponRange() - 0.1
	local minRange = self:getMinWeaponRange() + 0.1

	-- CreateLogLine("Batmane NPC_MovementManagement_Melee", true, tostring(self:getName()) .. " has walk range of " .. tostring(walkRange));
	-- CreateLogLine("Batmane NPC_MovementManagement_Melee", true, tostring(self:getName()) .. " has minRange of " .. tostring(minRange));

	local fs = cs:getTileInDirection(self.LastEnemySeen:getDir())
	if distance < walkRange then 
		-- if distance < minRange then 
		-- 	-- CreateLogLine("Batmane NPC_MovementManagement_Melee", true, tostring(self:getName()) .. " needs to back up");
		-- 	-- Kiting Function doesnt work
		-- 	-- if fs and fs:isFree(true) then
		-- 	-- 	CreateLogLine("Batmane NPC_MovementManagement_Melee", true, tostring(self:getName()) .. " is kiting to fs of  " .. tostring(fs));
		-- 	-- 	self:walkToDirect(fs)
		-- 	-- 	self.player:faceThisObject(self.LastEnemySeen)
		-- 	-- 	-- self:setRunning(true)
		-- 	-- end
		-- 	-- self:StopWalk() -- Not sure if this needs to be handled here
		-- -- else
		-- -- 	CreateLogLine("Batmane NPC_MovementManagement_Melee", true, tostring(self:getName()) .. " reached target and is just right distance");
		-- -- 	-- self:StopWalk() -- Not sure if this needs to be handled here
		-- end
		self:StopWalk()
		return 
	end

	if instanceof(self.LastEnemySeen, "IsoPlayer") then
		self:walkToDirect(cs)
		self:setRunning(true)
	else
		if fs and fs:isFree(true) then
			self:walkToDirect(fs)
		else
			self:walkToDirect(cs)
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC _MovementManagement() end ---");
end

-- Batmane Never Used
-- Used in 'if the npc has swiped their weapon'.
-- function SuperSurvivor:HasSwipedState()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:HasSwipedState() called");
-- 	if self.player:getCurrentState() == SwipeStatePlayer.instance() then
-- 		return true
-- 	else
-- 		return false
-- 	end
-- end

-- Never Used
-- function SuperSurvivor:HasFellDown()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:HasFellDown() called");
-- 	if self.player:getModData().felldown then
-- 		return true
-- 	else
-- 		return false
-- 	end
-- end


-- Never Used
-- function SuperSurvivor:CanAttack()
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:CanAttack() called");
-- 	if
-- 		self.player:getCurrentState() == SwipeStatePlayer.instance() -- Is in the middle of an attack | WAS AN 'or' statement
-- 		or self.player:getModData().felldown                   -- Has fallen on the ground
-- 	then
-- 		return false                                             -- Because NPC shouldn't be able to attack when already hitting, has fallen, or hit by something
-- 	else
-- 		return true
-- 	end
-- end

-- Never Used
--- gets the weapon damager based on a rng and distance from the target
---@param weapon any
---@param distance number
---@return number represents the damage that the weapon will give if hits
-- function SuperSurvivor:getWeaponDamage(weapon, distance)
-- 	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:getWeaponDamage() called");

-- 	if weapon == nil then
-- 		CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "no weapon found...");
-- 		return 0
-- 	end

-- 	local damage = 0
-- 	damage = (weapon:getMaxDamage() * ZombRand(10))
-- 	damage = damage - (damage * (distance * 0.1))

-- 	return damage
-- end

-- Batmane - I think I managed to fix the frozen melee animation by not setting melee or attack to false when attack task was complete
function SuperSurvivor:UnStuckFrozenAnim()
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:UnStuck FrozenAnim() called");
	self.player:setNPC(false)
	self.player:setBlockMovement(false)
	self.player:update()
	self.player:setNPC(true)
	self.player:setBlockMovement(true)
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(self.player, getSpecificPlayer(0)))


	local xoff = self.player:getX() + ZombRand(-3, 3)
	local yoff = self.player:getY() + ZombRand(-3, 3)
	self:StopWalk()
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(self.player, getSpecificPlayer(0)))
	self:WalkToPoint(xoff, yoff, self.player:getZ())
	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(self.player, getSpecificPlayer(0)))

	self.player:setPerformingAnAction(true)
	self.player:setVariable("bPathfind", true)
	self.player:setVariable("bKnockedDown", true)
	self.player:setVariable("AttackAnim", true)
	self.player:setVariable("BumpFall", true)

	ISTimedActionQueue.add(ISGetHitFromBehindAction:new(self.player, getSpecificPlayer(0)))
end



function SuperSurvivor:faceThisObjectSS(object) 
	self.player:faceThisObject(object);
	-- If not facing the target then return
	local dot = self.player:getDotWithForwardDirection(object:getX(), object:getY());
	-- CreateLogLine('Survivor Aiming', true, 'dot = ' .. tostring(dot))
	if dot < 0 then return false end -- target is behind shooter
end

function SuperSurvivor:doShove(victim, weapon)
	if self.player:isDoShove() then return end
	self:Speak("Get off of me!")
	self.player:setForceShove(true)
	victim:Hit(weapon, self.player, 1, true, 1.0, false)
	if not instanceof(victim, "IsoZombie") then return end

	-- Need to implement knock down direction
	if ZombRand(4) == 0 then 
		victim:knockDown(false) 
	else
		-- if not victim:isStaggerBack() then 
			victim:setStaggerBack(true)
		-- end
	end
end



--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- HANDLE MELEE
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

function SuperSurvivor:AttackWithMelee(victim) -- New Function
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:NPC _Attack() called");

	if self.player:getModData().felldown then return false end -- cant attack if they have fallen down

	-- Make sure the entity the NPC is hitting exists
	if not (instanceof(victim, "IsoPlayer") or instanceof(victim, "IsoZombie")) then
		return false;
	end

	-- Turn ON PVP Mode for Player automatically
	-- Does not prevent NPC from attacking player
	if instanceof(victim, "IsoPlayer") and IsoPlayer.getCoopPVP() == false then
		ForcePVPOn = true;
		SurvivorTogglePVP();
	end

	if self.player:getModData().felldown then return false end -- cant attack if stunned by an attack -- From other function

	self.SwipeStateTicks = 0; -- this value is tracked to see if player stuck in attack state/animation. so reset to 0 if we are TRYING/WANTING to attack

	local RealDistance = GetXYDistanceBetween(self.player, victim) 
	if not RealDistance then 
		RealDistance = GetXYDistanceBetween(self.player, victim) 
		CreateLogLine("Batmane NPC _Attack Error Distance", true, tostring(self:getName()) .. "has no saved distance to enemy ");
	end

	local minrange = self:getMinWeaponRange() + 0.2;
	local maxrange = self:getMaxWeaponRange() - 0.1;

	local zNPC_AttackRange = self:isEnemyInRange(self.LastEnemySeen);

	-- Makes sure if the weapon exists
	-- Get Weapon Damage
	local weapon = self.player:getPrimaryHandItem();
	local damage = 1;
	if weapon and instanceof(victim, "HandWeapon") then
		damage = weapon:getMaxDamage();
	end

	local weaponWeight = weapon:getWeight()
    local swingDelay = weaponWeight * globalBaseUpdateDelayTicks - 20
    if swingDelay < globalBaseUpdateDelayTicks then swingDelay = globalBaseUpdateDelayTicks end

	-- Makes sure if the npc has their weapon out first, aimed, facing target, attack animation
	-- Inflict Damage

	if self.player:NPCGetRunning() == true then return end
	
	if (RealDistance <= maxrange) or zNPC_AttackRange
	then
		self:StopWalk()
		if self:faceThisObjectSS(victim) == false then return end

		-- Shove Attack
		if RealDistance <= minrange then 
			self:doShove(victim, weapon)
		elseif self:WeaponReady() then
			self.player:NPCSetAttack(true);
			self.player:NPCSetMelee(true);
			self.player:AttemptAttack(swingDelay + 120)
			
			setTimeout(
				function() 
					victim:Hit(weapon, self.player, damage, false, 1.0, false)
					victim:setAttackedBy(self.player)
				end, 
				swingDelay - 30
			)
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:NPC _Attack() end ---");
end


--- OnHitZombie event 
---@param zombie IsoZombie Zombie that gets hit.
---@param character IsoPlayer Attacking Character.
---@param bodyPartType string Hit body part.
---@param handWeapon HandWeapon handWeapon of character.
local function OnHitZombie(zombie, character, bodyPartType, handWeapon) return character:playSound(handWeapon:getZombieHitSound()) end

Events.OnHitZombie.Add(OnHitZombie)


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- HANDLE GUNS
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------


--- Gets the change of a shoot based on aiming skill, weapon, victim's distance
--- Cows: I've updated it with all the weird cover-based and distance modifier removed.
---@param weapon any
---@param victim any
---@return number represents the chance of a hit
function SuperSurvivor:getGunHitChance(weapon, victim)
	local aimingLevel = self.player:getPerkLevel(Perks.FromString("Aiming"));
	local aimingPerkModifier = weapon:getAimingPerkHitChanceModifier();
	local weaponHitChance = weapon:getHitChance();
	local hitChance = weaponHitChance + (aimingPerkModifier * aimingLevel);

	CreateLogLine("SuperSurvivor", false, "Gun Hit Chance: " .. tostring(hitChance));
	return hitChance;
end

function SuperSurvivor:fireOneBullet(weapon, victim)
	local damage = weapon:getMaxDamage();

	self.player:NPCSetAttack(true)
	self.player:AttemptAttack(10.0); -- Try to animate gun fire

	local hitChance = self:getGunHitChance(weapon, victim);
	local dice = ZombRand(0, 100);

	-- Added RealCanSee to see if it works | and (damage > 0)
	if hitChance >= dice and damage > 0 and self:RealCanSee(victim) then
		victim:Hit(weapon, self.player, damage, false, 1.0, false);
	end
end


-- Batmane TODO - Remove attack ticks for gun function and see if anything breaks -- Seems like it doesnt need it
-- Used only for Guns
function SuperSurvivor:AttackWithGun(victim)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:Attack WithGun () called");
	if not self:hasGun() then return false end

	--if(self.player:getCurrentState() == SwipeStatePlayer.instance()) then return false end -- already attacking wait

	if self.player:getModData().felldown then return false end -- cant attack if they have fallen down

	self.SwipeStateTicks = 0;  -- this value is tracked to see if player stuck in attack state/animation. so reset to 0 if we are TRYING/WANTING to attack

	if not (instanceof(victim, "IsoPlayer") or instanceof(victim, "IsoZombie")) then
		return false;
	end

	local weapon = self.player:getPrimaryHandItem();
	if self:needToReadyGun(weapon) then		
		self:ReadyGun(weapon);
		return
	end

	if self:WeaponReady() then
		if instanceof(victim, "IsoPlayer") and IsoPlayer.getCoopPVP() == false then
			ForcePVPOn = true;
			SurvivorTogglePVP();
		end
		self:StopWalk()

		-- Animations
		if self:faceThisObjectSS(victim) == false then return end
		self.player:NPCSetAiming(true)

		if self.UsingFullAuto then
			self.TriggerHeldDown = true;
		end
		CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:GetDistanceBetween() called");

		-- Hit registration
		-- Shove attack
		local minrange = self:getMinWeaponRange() + 0.1
		local distance = GetXYDistanceBetween(self.player, victim) 
		if distance < minrange
		then
			self:doShove(victim, weapon)
		-- Actual attack
		else
			if not self.player:IsAiming() then return end
			self:fireOneBullet(weapon, victim)
			-- Code for bursts
			-- if ZombRand(4) == 0 then 
			-- 	setTimeout(
			-- 		function() 
			-- 			self:fireOneBullet(weapon, victim)
			-- 		end, 
			-- 		globalBaseUpdateDelayTicks / 4
			-- 	)
			-- end
		end
	else
		local pwep = self.player:getPrimaryHandItem()
		local pwepContainer = pwep:getContainer()
		if pwepContainer then pwepContainer:Remove(pwep) end -- remove temporarily so FindAndReturn("weapon") does not find this ammoless gun

		self:Speak(Get_SS_DialogueSpeech("OutOfAmmo"));

		for i = 1, #self.AmmoBoxTypes do
			self:getTaskManager():AddToTop(FindThisTask:new(self, self.AmmoBoxTypes[i], "Type", 1))
		end

		for i = 1, #self.AmmoTypes do
			self:getTaskManager():AddToTop(FindThisTask:new(self, self.AmmoTypes[i], "Type", 20))
		end
		self:setNeedAmmo(true)

		local melee = self:FindAndReturn(self.player:getModData().weaponmelee);
		if melee then
			self.player:setPrimaryHandItem(melee)
			if melee:isTwoHandWeapon() then self.player:setSecondaryHandItem(melee) end
		else
			local bwep = self.player:getInventory():getBestWeapon();

			if bwep and bwep ~= pwep then
				self.player:setPrimaryHandItem(bwep);
				if bwep:isTwoHandWeapon() then self.player:setSecondaryHandItem(bwep) end
			else
				bwep = self:getWeapon()
				if bwep then
					self.player:setPrimaryHandItem(bwep);
					if bwep:isTwoHandWeapon() then self.player:setSecondaryHandItem(bwep) end
				else
					self.player:setPrimaryHandItem(nil)
					self:getTaskManager():AddToTop(FindThisTask:new(self, "Weapon", "Category", 1))
				end
			end
		end

		if pwepContainer and not pwepContainer:contains(pwep) then pwepContainer:AddItem(pwep) end -- re add the former wepon that we temp removed
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:Attack WithGun () end ---");
end

function SuperSurvivor:DrinkFromObject(waterObject)
	local playerObj = self.player
	self:Speak(Get_SS_UIActionText("Drinking"));
	--
	if not waterObject:getSquare() or not luautils.walkAdj(playerObj, waterObject:getSquare()) then
		return;
	end
	local waterAvailable = waterObject:getWaterAmount()
	local waterNeeded = math.min(math.ceil(playerObj:getStats():getThirst() * 10), 10)
	local waterConsumed = math.min(waterNeeded, waterAvailable)
	ISTimedActionQueue.add(ISTakeWaterAction:new(playerObj, nil, waterConsumed, waterObject, (waterConsumed * 10) + 15));
end

-- WIP - Cows: NEED TO REWORK THE NESTED LOOP CALLS
function SuperSurvivor:findNearestSheetRopeSquare(down)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:findNearestSheetRopeSquare() called");
	local sq, CloseSquareSoFar;
	local range = 20
	local minx = math.floor(self.player:getX() - range);
	local maxx = math.floor(self.player:getX() + range);
	local miny = math.floor(self.player:getY() - range);
	local maxy = math.floor(self.player:getY() + range);
	local closestSoFar = 999;

	for x = minx, maxx do
		for y = miny, maxy do
			sq = getCell():getGridSquare(x, y, self.player:getZ());
			if (sq ~= nil) then
				CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:GetDistanceBetween() called");
				local distance = GetDistanceBetween(sq, self.player) -- WIP - literally spammed inside the nested for loops...

				if down and (distance < closestSoFar) and self.player:canClimbDownSheetRope(sq) then
					closestSoFar = distance
					CloseSquareSoFar = sq
				elseif not down and (distance < closestSoFar) and self.player:canClimbSheetRope(sq) then
					closestSoFar = distance
					CloseSquareSoFar = sq
				end
			end
		end
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:findNearestSheetRopeSquare() END ---");

	return CloseSquareSoFar
end

function SuperSurvivor:isAmmoForMe(itemType)
	if (self.AmmoTypes) and (#self.AmmoTypes > 0) then
		for i = 1, #self.AmmoTypes do
			if (itemType == self.AmmoTypes[i]) then return true end
		end
	end

	if (self.AmmoBoxTypes) and (#self.AmmoBoxTypes > 0) then
		for i = 1, #self.AmmoBoxTypes do
			if (itemType == self.AmmoBoxTypes[i]) then return true end
		end
	end
	return false
end

function SuperSurvivor:FindThisNearBy(itemType, TypeOrCategory)
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "SuperSurvivor:FindThisNearBy() called");
	if (self.GoFindThisCounter > 0) then return nil end

	self.GoFindThisCounter = 10;
	local sq, itemtoReturn;
	local range = 30;
	local closestSoFar = 999;
	local zhigh = 0;

	if (self.player:getZ() > 0) or (getCell():getGridSquare(self.player:getX(), self.player:getY(), self.player:getZ() + 1) ~= nil) then
		zhigh = self.player:getZ() + 1;
	end

	for z = 0, zhigh do
		local spiral = SpiralSearch:new(self.player:getX(), self.player:getY(), range)
		local x, y

		for i = spiral:forMax(), 0, -1 do
			x = spiral:getX()
			y = spiral:getY()
			sq = getCell():getGridSquare(x, y, z);

			if (sq ~= nil) then
				local tempDistance = 0 --GetDistanceBetween(sq,self.player)
				if (self.player:getZ() ~= z) then tempDistance = tempDistance + 10 end
				local items = sq:getObjects()
				-- check containers in square
				for j = 0, items:size() - 1 do
					if (items:get(j):getContainer() ~= nil) then
						local container = items:get(j):getContainer()

						if (sq:getZ() ~= self.player:getZ()) then tempDistance = tempDistance + 13 end

						local FindCatResult
						FindCatResult = FindItemByCategory(container, itemType, self)

						if (tempDistance < closestSoFar) and ((TypeOrCategory == "Category") and (FindCatResult ~= nil)) or
							((TypeOrCategory == "Type") and (container:FindAndReturn(itemType)) ~= nil) then
							if (TypeOrCategory == "Category") then
								itemtoReturn = FindCatResult
							else
								itemtoReturn = container:FindAndReturn(itemType)
							end

							if itemtoReturn:isBroken() then
								itemtoReturn = nil
							else
								closestSoFar = tempDistance
							end
						end
					elseif (itemType == "Water") and (items:get(j):hasWater()) and (tempDistance < closestSoFar) then
						itemtoReturn = items:get(j)
						closestSoFar = tempDistance
					elseif (itemType == "WashWater")
						and (items:get(j):hasWater())
						and (items:get(j):getWaterAmount() > 5000 or items:get(j):isTaintedWater())
						and (tempDistance < closestSoFar) then
						itemtoReturn = items:get(j)
						closestSoFar = tempDistance
					end
				end

				-- check floor
				if itemtoReturn ~= nil then
					self.TargetSquare = sq
				else
					if (itemType == "Food") then
						local item = FindAndReturnBestFoodOnFloor(sq, self)

						if (item ~= nil) then
							itemtoReturn = item
							closestSoFar = tempDistance
							self.TargetSquare = sq
						end
					else
						items = sq:getWorldObjects()

						for j = 0, items:size() - 1 do
							if (items:get(j):getItem()) then
								local item = items:get(j):getItem()

								if (tempDistance < closestSoFar)
									and (item ~= nil)
									and (not item:isBroken())
									and (((TypeOrCategory == "Category")
											and (HasCategory(item, itemType))) or
										((TypeOrCategory == "Type")
											and (tostring(item:getType()) == itemType
												or tostring(item:getName()) == itemType)))
								then
									itemtoReturn = item
									closestSoFar = tempDistance
									self.TargetSquare = sq
								end
							end
						end
					end
				end
			end

			if (self.TargetSquare ~= nil and itemtoReturn ~= nil) then
				break
			end

			spiral:next()
		end

		if (self.TargetSquare ~= nil and itemtoReturn ~= nil) then
			break
		end
	end

	if (self.TargetSquare ~= nil and itemtoReturn ~= nil) and (self.TargetSquare:getRoom()) and (self.TargetSquare:getRoom():getBuilding()) then
		self.TargetBuilding = self.TargetSquare:getRoom():getBuilding()
	end
	CreateLogLine("SuperSurvivor", isLocalLoggingEnabled, "--- SuperSurvivor:FindThisNearBy() end ---");
	return itemtoReturn
end

function SuperSurvivor:ensureInInv(item)
	if (self:getBag():contains(item)) then
		self:getBag():Remove(item)
	end

	if (item:getWorldItem() ~= nil) then
		item:getWorldItem():removeFromSquare()
		item:setWorldItem(nil)
	end

	if (not self:Get():getInventory():contains(item)) then
		self:Get():getInventory():AddItem(item)
	end

	return item
end

------------------armor mod functions-------------------
function SuperSurvivor:getUnEquipedArmors()
	local armors = {}
	local inv = self.player:getInventory()
	local items = inv:getItems()

	for i = 1, items:size() - 1 do
		local item = items:get(i)

		if item ~= nil
			and ((item:getCategory() == "Clothing") or (item:getCategory() == "Container" and item:getWeight() > 0))
			and item:isEquipped() == false
		then
			table.insert(armors, item)
		end
	end

	return armors
end

function SuperSurvivor:SuitUp(SuitName)
	self.player:clearWornItems();
	self.player:getInventory():clear();

	self.player:setWornItem("Jacket", nil);

	if SuitName:contains("Preset_") then
		SetRandomSurvivorSuit(self, "Preset", SuitName)
		-- Do the normal outfit selection otherwise
	else
		GetRandomSurvivorSuit(self)

		local hoursSurvived = math.min(math.floor(getGameTime():getWorldAgeHours() / 24.0), 28)
		local result = ZombRand(1, 72) + hoursSurvived

		-- Define the items with their respective thresholds in ascending order
		local bags = {
			{threshold = 36, item = "Base.Bag_Satchel"},         -- 12%
			{threshold = 48, item = "Base.Bag_Schoolbag"},       -- 12%
			{threshold = 60, item = "Base.Bag_DuffelBag"},       -- 20%
			{threshold = 80, item = "Base.Bag_NormalHikingBag"}, -- 12%
			{threshold = 92, item = "Base.Bag_BigHikingBag"},    -- 4%
			{threshold = 96, item = "Base.Bag_ALICEpack"},       -- 2%
			{threshold = 98, item = "Base.Bag_SurvivorBag"}      -- 2%
		}

		-- Use the binary search function to find the appropriate bag
		local bagItem = binarySearch(bags, result)
		if bagItem then
			self.player:setClothingItem_Back(self.player:getInventory():AddItem(bagItem))
		end
	end
end

function SuperSurvivor:getFilth()
	local filth = 0.0

	for i = 0, BloodBodyPartType.MAX:index() - 1 do
		filth = filth + self.player:getVisual():getBlood(BloodBodyPartType.FromIndex(i));
	end

	local inv = self.player:getInventory()
	local items = inv:getItems();

	if (items) then
		for i = 1, items:size() - 1 do
			local item = items:get(i)
			local bloodAmount = 0
			local dirtAmount = 0

			if instanceof(item, "Clothing") then
				if BloodClothingType.getCoveredParts(item:getBloodClothingType()) then
					local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())

					for j = 0, coveredParts:size() - 1 do
						local thisPart = coveredParts:get(j)
						bloodAmount = bloodAmount + item:getBlood(thisPart)
					end
				end

				dirtAmount = dirtAmount + item:getDirtyness()
			elseif instanceof(item, "Weapon") then
				bloodAmount = bloodAmount + item:getBloodLevel()
			end

			filth = filth + bloodAmount + dirtAmount
		end
	end

	return filth
end

function SuperSurvivor:CleanUp(percent)
	for i = 0, BloodBodyPartType.MAX:index() - 1 do
		local currentblood = self.player:getVisual():getBlood(BloodBodyPartType.FromIndex(i));
		self.player:getVisual():setBlood(BloodBodyPartType.FromIndex(i), (currentblood * percent)); -- always cut 10% off current amount
	end

	local washList = {}
	if (self.player:getClothingItem_Feet() ~= nil) then
		table.insert(washList, self.player:getClothingItem_Feet())
	end

	if (self.player:getClothingItem_Hands() ~= nil) then
		table.insert(washList, self.player:getClothingItem_Hands())
	end

	if (self.player:getClothingItem_Head() ~= nil) then
		table.insert(washList, self.player:getClothingItem_Head())
	end
	if (self.player:getClothingItem_Legs() ~= nil) then
		table.insert(washList, self.player:getClothingItem_Legs())
	end

	if (self.player:getClothingItem_Torso() ~= nil) then
		table.insert(washList, self.player:getClothingItem_Torso())
	end

	if (self.player:getWornItem("Jacket") ~= nil) then
		table.insert(washList, self.player:getWornItem("Jacket"))
	end

	for i = 1, #washList do
		local item = washList[i]

		local blood

		if instanceof(item, "Clothing") then
			if BloodClothingType.getCoveredParts(item:getBloodClothingType()) then
				local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())

				if (coveredParts ~= nil) then
					for j = 0, coveredParts:size() - 1 do
						local part = coveredParts:get(j)

						if (part ~= nil) then
							blood = item:getBlood(part);
							item:setBlood(part, (blood * percent))
						end
					end
				end

				local dirty = item:getDirtyness();
				item:setDirtyness(dirty * percent);

				if (blood) then
					if (blood < 0.1) then
						item:setBloodLevel(0)
					else
						item:setBloodLevel(blood * percent)
					end
				end
			end
		end
	end

	self.player:resetModel();
end

function SuperSurvivor:isEnemyInRange(enemy)
	if not enemy then
		return false
	end
	return self.player:IsAttackRange(enemy:getX(), enemy:getY(), enemy:getZ())
end


function SuperSurvivor:NPC_ForceFindNearestBuilding()
	if (self.TargetSquare ~= nil) and (self.TargetSquare:getRoom()) and (self.TargetSquare:getRoom():getBuilding()) then
		self.TargetBuilding = self.TargetSquare:getRoom():getBuilding()
	end
end
