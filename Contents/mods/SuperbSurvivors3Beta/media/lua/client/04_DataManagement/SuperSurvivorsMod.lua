-- Check if SSM is loaded and game speed isn't on pause before updating the Survivors routines.
-- Batmane: Survivor OnTick Routines
function SuperSurvivorsOnTick()
	if SSM ~= nil and getGameSpeed() ~= 0 then
		SSM:UpdateSurvivorsRoutine();
	end
end

-- Batmane: Survivor EveryDay, EveryHour, Every10min Routines - Breakup tick based routines into other listeners to save computation
function SuperSurvivorsOnEveryDay()
	if SSM ~= nil and getGameSpeed() ~= 0 then
		SSM:UpdateSurvivorsDailyRoutine();
	end
end

function SuperSurvivorsOnEveryHour()
	if SSM ~= nil and getGameSpeed() ~= 0 then
		SSM:UpdateSurvivorsHourlyRoutine();
	end
end

function SuperSurvivorsOnEvery10min()
	if SSM ~= nil and getGameSpeed() ~= 0 then
		SSM:UpdateSurvivors10MinRoutine();
	end
end

function SuperSurvivorGroupsOnEveryMin()
	if SSGM ~= nil and getGameSpeed() ~= 0 then
		SSGM:UpdateSurvivorGroups1MinRoutine();
	end
end

-- Batmane: By far this has to be the most performance consuming function because s number of survivor routines are updated every single tick (every time display is rendered) (60 fps = 60 per second)
-- Maybe survivor routines should be updated once per second or so and not once every single frame? How would a human make so many decisions?
	-- EveryDays
	-- EveryHours
	-- EveryOneMinute - Every 2 seconds in real world
	-- EveryTenMinutes - Every 20 Seconds
Events.OnRenderTick.Add(SuperSurvivorsOnTick);
Events.EveryDays.Add(SuperSurvivorsOnEveryDay);
Events.EveryHours.Add(SuperSurvivorsOnEveryHour);
Events.EveryTenMinutes.Add(SuperSurvivorsOnEvery10min);

Events.EveryOneMinute.Add(SuperSurvivorGroupsOnEveryMin);





--- WIP - Cows: Saves all the relevant mod data... it works, but I think it can be better.
function SuperSurvivorsSaveData()
	local isSaveFunctionLoggingEnabled = false;
	CreateLogLine("SuperSurvivorsMod", isSaveFunctionLoggingEnabled, "function: SuperSurvivorsSaveData() called");
	SSM:SaveAll();
	SSGM:Save();
	SaveSurvivorMap();
	CreateLogLine("SuperSurvivorsMod", isSaveFunctionLoggingEnabled, "--- SuperSurvivorsSaveData() end ---");
end

Events.OnPostSave.Add(SuperSurvivorsSaveData);

-- WIP - Cows: Need to rework the spawning functions and logic...
-- Batmane Notes:
-- Purpose of this function: Event Listener. Upon loading any grid square, Check to see if save file survivors need to be loaded in that square
-- This function instantiates SurvivorMap ONCE if it does not exist, initializes SSM, SSGM.
-- The following occurs whenever a grid square is loaded, get x,y,z coordinates, turn it into a string
-- index the survivor map for the xyz coordinates - if it exists, load all survivors in the map

function SuperSurvivorsLoadGridsquare(square)
	if (square ~= nil) then
		local x = square:getX()
		local y = square:getY()
		local z = square:getZ()
		local key = x .. y .. z

		if (SurvivorMap == nil) then
			SSM:init();
			SSGM:Load(); -- Load in survivor groups as you load the square

			if (DoesFileExist("SurvivorLocX")) then
				SurvivorMap = LoadSurvivorMap() -- matrix grid containing info on location of all survivors for re-spawning purposes
			else
				SurvivorMap = {};
				SurvivorLocX = {};
				SurvivorLocY = {};
				SurvivorLocZ = {};
			end
		end

		if key and SurvivorMap[key] ~= nil and #SurvivorMap[key] > 0 then
			local i = 1;

			while SurvivorMap[key][i] ~= nil do
				SSM:LoadSurvivor(SurvivorMap[key][i], square);  -- Load in survivors as you load the square
				i = i + 1;
			end
			i = 1;
			SurvivorMap[key] = {} -- i think this is faster
		end
	end
end

Events.LoadGridsquare.Add(SuperSurvivorsLoadGridsquare); --- This is a potential performance killer... because it scans through all the known map squares.
-- Batmane Note response - This should be a problem whenever Player 1 is moving since it only runs whenever squares are being rerendered

function SuperSurvivorsOnSwing(player, weapon)
	local ID = player:getModData().ID
	if (ID ~= nil) then
		local SS = SSM:Get(ID)
		if (SS) and not player:isLocalPlayer() then
			if weapon:isRanged() then
				if weapon:haveChamber() then
					weapon:setRoundChambered(false);
				end
				-- remove ammo, add one to chamber if we still have some
				if weapon:getCurrentAmmoCount() >= weapon:getAmmoPerShoot() then
					if weapon:haveChamber() then
						weapon:setRoundChambered(true);
					end
					weapon:setCurrentAmmoCount(weapon:getCurrentAmmoCount() - weapon:getAmmoPerShoot())
				end
				if weapon:isRackAfterShoot() then -- shotgun need to be rack after each shot to rechamber round
					player:setVariable("RackWeapon", weapon:getWeaponReloadType());
				end
			end

			local range = weapon:getSoundRadius()
			local volume = weapon:getSoundVolume()
			if weapon:isAimedFirearm() then 
				if weapon:isRoundChambered() then
					addSound(player, player:getX(), player:getY(), player:getZ(), range, volume)
					getSoundManager():PlayWorldSound(weapon:getSwingSound(), player:getCurrentSquare(), 0.5, range, 1.0, false)
				end
			else
				addSound(player, player:getX(), player:getY(), player:getZ(), range, volume)
				getSoundManager():PlayWorldSound(weapon:getSwingSound(), player:getCurrentSquare(), 0.5, range, 1.0, false)
			end

			player:NPCSetAttack(false)
			player:NPCSetMelee(false)
		elseif player:isLocalPlayer() and weapon:isRanged() then
			SSM:GunShotHandle(SS)
		end
	end
end

Events.OnWeaponSwing.Add(SuperSurvivorsOnSwing)

--- Cows: "SurvivorOrder" was cut-pasted here from "SuperSurvivorsContextMenu.lua" to address a load order issue...
--- Cows: This also seems to be redundant ... given the player can also order their group members from the SuperSurvivorWindow much faster and simpler.
---@param test any -- Cows: Even if it is unused this is apparently required for the function to work... otherwise the function simply returns nil.
---@param player any
---@param order any
---@param orderParam any
function SurvivorOrder(test, player, order, orderParam)
	local isLoggingSurvivorOrder = false;
	CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "function: SurvivorOrder() called");
	CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "player: " .. tostring(player));
	CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "order: " .. tostring(order));
	CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "orderParam: " .. tostring(orderParam));
	if player then
		local ASuperSurvivor = SSM:Get(player:getModData().ID)
		local TaskMangerIn = ASuperSurvivor:getTaskManager()
		ASuperSurvivor:setAIMode(order)
		TaskMangerIn:setTaskUpdateLimit(0)

		ASuperSurvivor:setWalkingPermitted(true)
		TaskMangerIn:clear();

		local orderActions = {
			["Loot Room"] = function()
				if orderParam ~= nil then
					TaskMangerIn:AddToTop(LootCategoryTask:new(ASuperSurvivor, ASuperSurvivor:getBuilding(), orderParam, 0))
				end
			end,
			["Follow"] = function()
				ASuperSurvivor:setAIMode("Follow")
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Companion"))
				TaskMangerIn:AddToTop(FollowTask:new(ASuperSurvivor, getSpecificPlayer(0)))
			end,
			["Pile Corpses"] = function()
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Dustman"))
				local dropSquare = getSpecificPlayer(0):getCurrentSquare()
				local storagearea = ASuperSurvivor:getGroup():getGroupArea("CorpseStorageArea")
				if (storagearea[1] ~= 0) then
					dropSquare = GetCenterSquareFromArea(storagearea[1], storagearea[2], storagearea[3], storagearea[4], storagearea[5])
				end
				TaskMangerIn:AddToTop(PileCorpsesTask:new(ASuperSurvivor, dropSquare))
			end,
			["Guard"] = function()
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Guard"))
				local area = ASuperSurvivor:getGroup():getGroupArea("GuardArea")
				if area then
					ASuperSurvivor:Speak(Get_SS_ContextMenuText("IGoGuard"))
					TaskMangerIn:AddToTop(WanderInAreaTask:new(ASuperSurvivor, area))
					TaskMangerIn:setTaskUpdateLimit(300)
					TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor, GetRandomAreaSquare(area)))
					ASuperSurvivor:Speak("And Where are you wanting me to guard at again? Show me an area to guard at.")
				else
					ASuperSurvivor:Speak("Ok, I will stay right here and guard")
					TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor, getSpecificPlayer(0):getCurrentSquare()))
				end
			end,
			["Patrol"] = function()
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Sheriff"))
				TaskMangerIn:AddToTop(PatrolTask:new(ASuperSurvivor, getSpecificPlayer(0):getCurrentSquare(), ASuperSurvivor:Get():getCurrentSquare()))
			end,
			["Return To Base"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				TaskMangerIn:AddToTop(ReturnToBaseTask:new(ASuperSurvivor))
			end,
			["Explore"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				TaskMangerIn:AddToTop(WanderTask:new(ASuperSurvivor))
			end,
			["Stop"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
			end,
			["Relax"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				if ASuperSurvivor:getBuilding() ~= nil then
					TaskMangerIn:AddToTop(WanderInBuildingTask:new(ASuperSurvivor, ASuperSurvivor:getBuilding()))
				else
					TaskMangerIn:AddToTop(WanderInBuildingTask:new(ASuperSurvivor, nil))
					TaskMangerIn:AddToTop(FindBuildingTask:new(ASuperSurvivor))
				end
			end,
			["Barricade"] = function()
				TaskMangerIn:AddToTop(BarricadeBuildingTask:new(ASuperSurvivor))
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
			end,
			["Stand Ground"] = function()
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Guard"))
				ASuperSurvivor:Speak("I will stand my ground here and guard this area")
				TaskMangerIn:AddToTop(GuardTask:new(ASuperSurvivor, getSpecificPlayer(0):getCurrentSquare()))
				ASuperSurvivor:setWalkingPermitted(false)
			end,
			["Forage"] = function()
				TaskMangerIn:AddToTop(ForageTask:new(ASuperSurvivor))
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Junkman"))
			end,
			["Farming"] = function()
				TaskMangerIn:AddToTop(FarmingTask:new(ASuperSurvivor))
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Farmer"))
			end,
			["Chop Wood"] = function()
				TaskMangerIn:AddToTop(ChopWoodTask:new(ASuperSurvivor))
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Timberjack"))
			end,
			["Gather Wood"] = function()
				ASuperSurvivor:setGroupRole(Get_SS_JobText("Hauler"))
				local dropSquare = getSpecificPlayer(0):getCurrentSquare()
				local woodstoragearea = ASuperSurvivor:getGroup():getGroupArea("WoodStorageArea")
				if (woodstoragearea[1] ~= 0) then
					dropSquare = GetCenterSquareFromArea(woodstoragearea[1], woodstoragearea[2], woodstoragearea[3], woodstoragearea[4], woodstoragearea[5])
				end
				TaskMangerIn:AddToTop(GatherWoodTask:new(ASuperSurvivor, dropSquare))
			end,
			["Lock Doors"] = function()
				TaskMangerIn:AddToTop(LockDoorsTask:new(ASuperSurvivor, true))
			end,
			["Sort Loot Into Base"] = function()
				TaskMangerIn:AddToTop(SortLootTask:new(ASuperSurvivor, false))
			end,
			["Dismiss"] = function()
				ASuperSurvivor:setAIMode("Random Solo")
				local group = SSGM:GetGroupById(ASuperSurvivor:getGroupID())
				if (group) then
					group:removeMember(ASuperSurvivor:getID())
				end
				ASuperSurvivor:getTaskManager():clear()
				if (ZombRand(3) == 0) then
					ASuperSurvivor:setHostile(true)
					ASuperSurvivor:Speak(Get_SS_DialogueSpeech("HowDareYou"))
				else
					ASuperSurvivor:Speak(Get_SS_DialogueSpeech("IfYouThinkSo"))
				end
			end,
			["Go Find Food"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor, "Food", "Category", 1))
			end,
			["Go Find Weapon"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor, "Weapon", "Category", 1))
			end,
			["Go Find Water"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				TaskMangerIn:AddToTop(FindThisTask:new(ASuperSurvivor, "Water", "Category", 1))
			end,
			["Clean Up Inventory"] = function()
				if ASuperSurvivor:getGroupRole() == "Companion" then
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
				end
				local group = ASuperSurvivor:getGroup()
				if (group) then
					local containerobj = group:getGroupAreaContainer("FoodStorageArea")
					TaskMangerIn:AddToTop(CleanInvTask:new(ASuperSurvivor, containerobj, false))
				end
			end,
			["Doctor"] = function()
				if (ASuperSurvivor:Get():getPerkLevel(Perks.FromString("Doctor")) >= 1
					or ASuperSurvivor:Get():getPerkLevel(Perks.FromString("First Aid")) >= 1)
				then
					TaskMangerIn:AddToTop(DoctorTask:new(ASuperSurvivor))
					ASuperSurvivor:setGroupRole(Get_SS_JobText("Doctor"))
				else
					ASuperSurvivor:Speak(Get_SS_DialogueSpeech("IDontKnowHowDoctor"))
				end
			end
		}

		ASuperSurvivor:Speak(Get_SS_DialogueSpeech("Roger"))
		CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "Order Name: " .. tostring(OrderDisplayName[order]));
		getSpecificPlayer(0):Say(
			tostring(ASuperSurvivor:getName()) ..
			", " .. OrderDisplayName[order]
		);

		-- Execute the action based on the order
		if orderActions[order] then
			orderActions[order]()
		end
	end
end

---comment
---@param player any
---@param weapon any
---@return boolean
function SuperSurvivorsOnEquipPrimary(player, weapon)
	if (player:isLocalPlayer() == false) then
		local ID = player:getModData().ID
		local SS = SSM:Get(ID)
		if (SS == nil) then return false end
		SS.UsingFullAuto = false

		if weapon and instanceof(weapon, "HandWeapon") then
			SS.AttackRange = player:getPrimaryHandItem():getMaxRange() + player:getPrimaryHandItem():getMinRange();
			-- Allow Capping of Max Attack Range
			SS.AttackRange = math.min(SS.AttackRange, ConfigMaxAIAttackRange)
			

			if (weapon:isAimedFirearm()) then
				local ammotypes = GetAmmoBullets(weapon);

				if (ammotypes ~= nil) and (ID ~= nil) then
					SS.AmmoTypes = ammotypes
					player:getModData().ammotype = ""
					player:getModData().ammoBoxtype = ""
					for i = 1, #SS.AmmoTypes do
						SS.AmmoBoxTypes[i] = GetAmmoBox(SS.AmmoTypes[i])
						player:getModData().ammotype = player:getModData().ammotype .. " " .. SS.AmmoTypes[i]
						player:getModData().ammoBoxtype = player:getModData().ammoBoxtype .. " " .. SS.AmmoBoxTypes[i]
					end

					SS.LastGunUsed = weapon;
				end
			end
		end
	end
end

Events.OnEquipPrimary.Add(SuperSurvivorsOnEquipPrimary);

