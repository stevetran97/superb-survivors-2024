require "00_SuperbSurviorModVariables/SuperSurvivorsSuitsList"
-- this file has the functions for survivor's suits

local isLocalLoggingEnabled = false;

--- Gets a random outfit for a survivor
---@param SS any survivor that will wear the outfit
function GetRandomSurvivorSuit(SS)
	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "GetRandomSurvivor Suit() called");

	local roll = ZombRand(0, 101)
	local tempTable = nil
	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "rolled: " .. tostring(roll));

	-- if (roll == 1) then -- choose legendary suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "Legendary suit");
	-- 	tempTable = SurvivorRandomSuits["Legendary"]
	-- elseif (roll <= 5) then -- choose veryrare suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "VeryRare suit");
	-- 	tempTable = SurvivorRandomSuits["VeryRare"]
	-- elseif (roll <= 15) then -- choose rare suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "Rare suit");
	-- 	tempTable = SurvivorRandomSuits["Rare"]
	-- elseif (roll <= 25) then -- chose normal suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "Normal suit");
	-- 	tempTable = SurvivorRandomSuits["Normal"]
	-- elseif (roll <= 40) then -- chose uncommon suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "Uncommon suit");
	-- 	tempTable = SurvivorRandomSuits["Uncommon"]
	-- else -- chose common suit
	-- 	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Got: " .. "Common suit");
	-- 	tempTable = SurvivorRandomSuits["Common"]
	-- end

	local suits = {
		{threshold = 0, item = "Common"},
		{threshold = 1, item = "Legendary"},
		{threshold = 5, item = "VeryRare"},
		{threshold = 15, item = "Rare"},
		{threshold = 25, item = "Normal"},
		{threshold = 40, item = "Uncommon"}
	}
	local suitCategory = binarySearch(suits, roll)
	tempTable = SurvivorRandomSuits[suitCategory]

	local result = table.randFrom(tempTable)

	-- What does this even do?
	while (string.sub(result, -1) == "F"
			and not SS.player:isFemale())
		or (string.sub(result, -1) == "M"
			and SS.player:isFemale()) 
	do
		CreateLogLine("SuperSurvivorSuitsUtilities", true, "While loop run... " .. tostring(result));
		result = table.randFrom(tempTable)
	end

	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Random suit result: " .. tostring(result));

	local suitTable = tempTable[result];
	putOnAllClothingItems(SS, suitTable)

	CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "--- GetRandomSurvivor Suit() end ---");
end

---@alias rarity
---| "Common"
---| "Uncommon"
---| "Normal"
---| "Rare"
---| "VeryRare"
---| "Legendary"
---| "Preset"

--- sets an outfit for a survivor given if table and outfit found
---@param SS any
---@param tbl rarity table name to be searched
---@param name string outfit name
function SetRandomSurvivorSuit(SS, tbl, name)
	local suitTable = SurvivorRandomSuits[tbl][name]
	if suitTable then
		putOnAllClothingItems(SS, suitTable)
	end
end


function putOnAllClothingItems(SS, clothesTable) 
	for i = 1, #clothesTable do
		if clothesTable[i] then
			SS:WearThis(clothesTable[i])
		end
	end
end