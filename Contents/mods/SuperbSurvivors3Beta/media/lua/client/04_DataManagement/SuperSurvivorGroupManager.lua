SuperSurvivorGroupManager = {}
SuperSurvivorGroupManager.__index = SuperSurvivorGroupManager

local isLocalLoggingEnabled = true

function SuperSurvivorGroupManager:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.Groups = {}
	o.GroupCount = 0

	return o
end

function SuperSurvivorGroupManager:GetGroupById(thisID)
	return self.Groups[thisID]
end

-- Batmane TODO: Replace self.Group Count
-- Batmane Note: Group count is completely wack, it gets instantiated at 0 and then created as needed but never gets deleted. 
function SuperSurvivorGroupManager:GetGroupIdFromSquare(square)
	-- for i = 0, self.GroupCount do
	for i, Group in pairs(self.Groups) do
		if self.Groups[i] and self.Groups[i]:IsInBounds(square) then
			return self.Groups[i]:getID()
		end
	end
	return -1
end

function SuperSurvivorGroupManager:getCount()
	return self.GroupCount
	-- return #self.Groups
end

-- Batmane how does this even work
-- Lets say groupCount = 2
-- You loop from 0 to 2
-- if a group exists at idx 0, youll get to 0 and the group wont exist
-- Loop ends, 
-- You create a group with an id of 0 - I confirmed this in testing - the first group is 0
-- group Count is now 1
-- Return that group
-- The next time you do this you loop from 0 to 1, 
-- 0 gets skipped because 0 is not >= 1
-- Then when i == 1, loop ends and you get final groupID of 2 because you add 1 to the group id

-- Here is the problem: 
-- CreateLogLine("Group Debugging", true, "Creating new Group of id " .. tostring(groupID));
-- CreateLogLine("Group Debugging", true, "Group count is now  " .. tostring(self.GroupCount));
-- CreateLogLine("Group Debugging", true, "#self.Groups =  " .. tostring(#self.Groups));

-- 2024-05-01 05:59:51 : Creating new Group of id 0
-- 2024-05-01 05:59:51 : Group count is now  1
-- 2024-05-01 05:59:51 : #self.Groups =  0


function SuperSurvivorGroupManager:newGroup()
	-- local groupID = self.GroupCount
	-- -- local groupID = #self.Groups

	-- -- This old code is kinda busted
	-- for i = 0, self.GroupCount do
	-- -- for i, Group in pairs(self.Groups) do
	-- 	if self.Groups[i] and self.Groups[i]:getID() >= groupID then
	-- 		groupID = self.Groups[i]:getID() + 1
	-- 	end
	-- end

	-- self.Groups[groupID] = SuperSurvivorGroup:new(groupID)
	-- self.GroupCount = groupID + 1
	-- CreateLogLine("Group Debugging", true, "Creating new Group of id " .. tostring(groupID));
	-- CreateLogLine("Group Debugging", true, "Group count is now  " .. tostring(self.GroupCount));
	-- CreateLogLine("Group Debugging", true, "#self.Groups =  " .. tostring(#self.Groups));

	-- CreateLogLine("Create Group ", true, "Batmane create group of  = " .. tostring(self.Groups[groupID]) .. " at idx " .. tostring(groupID));
	-- return self.Groups[groupID]

	-- Batmane
	for i = 0, (Limit_Npc_Groups + 1 + 5) do
		if not self.Groups[i] then 
			self.Groups[i] = SuperSurvivorGroup:new(i)
			-- self.GroupCount = self.GroupCount + 1
			self.GroupCount = self:countGroups()

			-- CreateLogLine("Create Group ", true, "Batmane create group of  = " .. tostring(self.Groups[i]) .. " at idx " .. tostring(i));
			return self.Groups[i]
		end
	end
end

function SuperSurvivorGroupManager:countGroups() 
	local newCount = 0
	for i, group in pairs(self.Groups) do
		newCount = newCount + 1 -- Exclude player group
	end
	return newCount
end


-- This function doesnt seem to work well -- Batmane
function SuperSurvivorGroupManager:newGroupWithID(ID)
	if not ID then 
		CreateLogLine("Error", true, "SuperSurvivorGroupManager:new GroupWithID cannot create group without ID");
		return
	end

	local groupID = ID
	self.Groups[groupID] = SuperSurvivorGroup:new(groupID)
	self.GroupCount = self:countGroups()
	return self.Groups[groupID]
end




function SuperSurvivorGroupManager:Save()
	-- for i = 0, self.GroupCount do
	for i, Group in pairs(self.Groups) do
		CreateLogLine("Saving Groups ", true, "Saving this group " .. tostring(i));

		if self.Groups[i] then
			self.Groups[i]:Save() -- WIP - console.txt logged an error tracing to this line
		end
	end
end

function SuperSurvivorGroupManager:Load()
	if DoesFileExist("SurvivorGroup0.lua") then -- only load if any groups detected at all -- Batmane Why only load if this file exists?
		local timeoutCounter = 0

		self.GroupCount = 0 -- This relies on GroupCount because each time, you do new group, it increments by 1
		
		while DoesFileExist("SurvivorGroup" .. tostring(self.GroupCount) .. ".lua") do -- While this file exists, create new group?
		-- while DoesFileExist("SurvivorGroup" .. tostring(#self.Groups) .. ".lua") do
			local newGroup = self:newGroup()
			newGroup:Load()

			-- Timeout Bailout for error in loading
			timeoutCounter = timeoutCounter + 1
			if timeoutCounter > 1000 then 
				CreateLogLine("Errors", true, "Error loading group because it timed out loading " .. tostring(self.GroupCount));
				return 
			end
		end

	end

end

function SuperSurvivorGroupManager:UpdateSurvivorGroups1MinRoutine()
	-- CreateLogLine("Group Manager Routine", true, " Tracking Groups Function");

	-- Keep Track of Group Locations
	for i, Group in pairs(self.Groups) do
		if Group.Members then 
			local GroupMemberCount = 0
			local totalX = 0
			local totalY = 0
			local totalZ = 0
			-- Loop over group members
			for i, MemberId in pairs(Group.Members) do 
				if MemberId then 
					local Member = SSM:Get(MemberId)
					if Member and Member:isInCell() then
						totalX = totalX + Member:getX()
						totalY = totalY + Member:getY()
						totalZ = totalZ + Member:getZ()
						GroupMemberCount = GroupMemberCount + 1
					end
					-- Rough Clean up members object memory leak
					if not Member then 
						table.remove(Group.Members, i)
					end
				end
			end
			Group.AverageLocation = getCell():getGridSquare(totalX / GroupMemberCount, totalY / GroupMemberCount, totalZ / GroupMemberCount);
			-- CreateLogLine("Group Manager Routine", true, " final Group.AverageLocation " .. tostring(Group.AverageLocation));
		end
	end
end


SSGM = SuperSurvivorGroupManager:new()
