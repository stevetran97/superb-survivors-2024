---@diagnostic disable: need-check-nil
TaskManager = {}
TaskManager.__index = TaskManager

local isLocalLoggingEnabled = false;

function TaskManager:new(superSurvivor)
	CreateLogLine("TaskManager", isLocalLoggingEnabled, "function: TaskManager:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.TaskUpdateCount = 0 -- Number of times any one task has been .update()'d. If this exceed TaskUpdateLimit, then the task is deleted 
	o.TaskUpdateLimit = 0
	o.parent = superSurvivor
	o.Tasks = {}
	o.Tasks[0] = nil -- Why does the first task need to be nil - Batmane
	o.CurrentTask = 0
	-- o.LastTask = 0
	-- o.LastLastTask = 0

	return o
end

function TaskManager:setTaskUpdateLimit(toValue)
	self.TaskUpdateLimit = toValue
	self.TaskUpdateCount = 0
end

function TaskManager:getTaskCount()
	local taskCount = #self.Tasks
	if self.Tasks[0] then taskCount = taskCount + 1 end
	return taskCount
end

function TaskManager:AddToTop(newTask)
	CreateLogLine("TaskManager", isLocalLoggingEnabled, "function: TaskManager:AddToTop() called");

	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE task list start -------- ");
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE self.Tasks = " .. tostring(self.Tasks));
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE #self.Tasks = " .. tostring(#self.Tasks));
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE self.Tasks[0] = " .. tostring(self.Tasks[0]));
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE pairs(self.Tasks) = " .. tostring(pairs(self.Tasks)));
	-- for i, Task in pairs(self.Tasks) do
	-- 	CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " has current queued task: " .. tostring(Task.Name));
	-- end
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " BEFORE task list end -------- ");

	if newTask == nil then return false end

	-- self.LastLastTask = self.LastTask -- WIP - Cows: "LastTask" is undefined...
	-- self.LastTask = self:getCurrentTask()
	self.CurrentTask = newTask.Name

	-- if self.LastTask == self.CurrentTask then
	-- 	CreateLogLine("TaskManager", isLocalLoggingEnabled, "... possibly stuck in task loop ...");
	-- end
	-- if self.LastLastTaskt == self.CurrentTask then
	-- 	CreateLogLine("TaskManager", isLocalLoggingEnabled, "... possibly stuck in task loop ...");
	-- end

	self.TaskUpdateCount = 0
	-- Old task list management system - shift task list down to add new task to front
	for i = #self.Tasks, 0, -1 do
		self.Tasks[i + 1] = self.Tasks[i]
	end


	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " AFTER task list start -------- ");
	-- for i, Task in pairs(self.Tasks) do
	-- 	CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " has current queued task: " .. tostring(Task.Name));
	-- end
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " AFTER #self.Tasks = " .. tostring(#self.Tasks));
	-- CreateLogLine("AddToTop", true, tostring(self.parent:getName()) .. " AFTER task list end -------- ");

	self.Tasks[0] = newTask
end

function TaskManager:AddToBottom(newTask)
	self.Tasks[#self.Tasks] = newTask
end

function TaskManager:Display()
	CreateLogLine("TaskManager", isLocalLoggingEnabled, "function: TaskManager:Display() called");
	for i, Task in pairs(self.Tasks) do -- Batmane: Used to display from 1 to end for some reason?
		if self.Tasks[i] ~= nil then
			CreateLogLine("TaskManager", isLocalLoggingEnabled, tostring(self.Tasks[i].Name)); 
		end
	end
end

-- Seems to force set complete all tasks 
function TaskManager:clear()
	-- Cows: Why do we need to force complete the tasks?
	-- Batmane: This was originally set to clear from index 1 to end for some reason? Doesnt clear current task at 0.
	-- If I have it clear from 0, ai just abandons your follow task
	for i = 1, #self.Tasks - 1 do -- before clearing run the force complete task of any task that has one 
		if self.Tasks[i] ~= nil and self.Tasks[i].ForceComplete ~= nil then
			return self.Tasks[i]:ForceComplete()
		end
	end

	-- if I want to clear tasks, I want to clear all tasks but I dont know the effect on the ai yet
	-- for i = 1, #self.Tasks - 1 do -- Batmane - if I want to clear tasks, I want to clear all tasks
	-- 		table.remove(self.Tasks, i)
	-- end
	table.remove(self.Tasks, 0)
end

-- Batmane - I phased out the old system of setting finished tasks to nil and moving it down the list because that was accumulating infinite tasks
-- This function basically loops over all those dead tasks and pushes task 1 to the very bottom
-- So you can imagine that if you play the game for hours and each of your survivors have finished like 1000 tasks and this keeps having to push the tasks to the bottom...
function TaskManager:moveDown()
	while not self.Tasks[0] or self.Tasks[0]:isComplete() == true do
		if self.Tasks[0]
			and self.Tasks[0].OnComplete ~= nil 
		then 
			self.Tasks[0]:OnComplete() 
		end

		if #self.Tasks <= 1 then
			self:clear()
			break
		else
			for i, Task in pairs(self.Tasks) do
				self.Tasks[i] = self.Tasks[i + 1]
			end
		end
	end

	self.TaskUpdateCount = 0
	return false
end

function TaskManager:getCurrentTask()
	if self.Tasks[0] ~= nil and self.Tasks[0].Name ~= nil then
		return self.Tasks[0].Name
	end
	return "None"
end

function TaskManager:getTask()
	if self.Tasks[0] ~= nil then
		return self.Tasks[0]
	end
	return nil
end

function TaskManager:getThisTask(index)
	if self.Tasks[index] ~= nil then
		return self.Tasks[index]
	end
	return nil
end

function TaskManager:removeTaskFromName(thisName)
	for i, Task in pairs(self.Tasks) do
		if self.Tasks[i] ~= nil 
			and self.Tasks[i].Name == thisName 
		then
			if self.Tasks[i].OnComplete then self.Tasks[i]:OnComplete() end
			self.Tasks[i] = nil;
		end
	end
	return nil
end

function TaskManager:getTaskFromName(thisName)
	-- for i, Task in pairs(self.Tasks) do
	for i, Task in pairs(self.Tasks) do
		if self.Tasks[i] ~= nil 
			and self.Tasks[i].Name == thisName 
		then
			return self.Tasks[i];
		end
	end

	return nil;
end

function TaskManager:debugTaskList() 
	-- Batmane - Useful Task logging to check for task manager memory leak
	for testLog = 1, #self.Tasks do 
		CreateLogLine("Batmane TaskManager", true,
			self.parent:getName() .. " task " .. tostring(testLog) .. " is " .. tostring(self.Tasks[testLog])
		);
		if self.Tasks[testLog] then 
			CreateLogLine("Batmane TaskManager", true,
				self.parent:getName() .. " task " .. tostring(testLog) .. " is " .. tostring(self.Tasks[testLog].Name)
			);
		end
	end
end

function TaskManager:update()
	CreateLogLine("TaskManager", isLocalLoggingEnabled, "function: TaskManager:update() called");

	if self == nil then return end
	if not self.parent.player then return end
	if not self.parent then return end

	-- Manages what tasks need to be prioritzie and added to the front
	AIManager(self)

	local currentTask = self:getCurrentTask();

	-- Task Completion updation checker
	-- This here seems to double update tasks despite the task manager already doing that
	-- Task exceeds update limit on one task (stuck)
	if self.TaskUpdateLimit ~= 0 
		and self.TaskUpdateLimit ~= nil 
		and self.TaskUpdateCount > self.TaskUpdateLimit 
	then
		CreateLogLine("Task Time out", true, tostring(self.Tasks[0].Name) .. " Task timed out for " .. tostring(self.parent:getName()));
		if self.Tasks then table.remove(self.Tasks, 0) end -- Batmane lets try just removing elements from table instead of nilling it because the keys still remain and cause mem leak
		-- self.Tasks[0] = nil -- old system - disabled by batmane
		self:moveDown();

		CreateLogLine("TaskManager", isLocalLoggingEnabled,
			self.parent:getName() .. " stopped their task due to setTaskUpdateLimit"
		);
	-- Task just not complete
	elseif self.Tasks[0]
		and self.Tasks[0]:isComplete() == false 
	then
		if 
			self.Tasks[0].parent and
			self.Tasks[0].parent.player
		then 
			self.Tasks[0]:update()
			self.TaskUpdateCount = self.TaskUpdateCount + 1
		end
	-- Other cases - Task Complete
	else
		if self.Tasks then table.remove(self.Tasks, 0) end -- Batmane lets try just removing elements from table instead of nilling it because the keys still remain and cause mem leak
		self:moveDown()
	end




	-- Batmane Debug 
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has TaskUpdateCount of " .. tostring(self.TaskUpdateCount));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has TaskUpdateLimit of " .. tostring(self.TaskUpdateLimit));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has Tasks of " .. tostring(self.Tasks));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has Tasks[0] of " .. tostring(self.Tasks[0]));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has CurrentTask of " .. tostring(self.CurrentTask));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has LastTask of " .. tostring(self.LastTask));
	-- CreateLogLine("TaskManager", true, tostring(self.parent:getName()) .. " has LastLastTask of " .. tostring(self.LastLastTask));
	-- Batmane



	-- Batmane - Useful Task logging to check for task manager memory leak
	-- CreateLogLine("Batmane TaskManager", true,
	-- 	self.parent:getName() .. " has these many tasks " .. tostring(#self.Tasks)
	-- );
	-- self:debugTaskList()
	-- for testLog = 1, #self.Tasks do 
	-- 	CreateLogLine("Batmane TaskManager", true,
	-- 		self.parent:getName() .. " task " .. tostring(testLog) .. " is " .. tostring(self.Tasks[testLog])
	-- 	);
	-- 	if self.Tasks[testLog] then 
	-- 		CreateLogLine("Batmane TaskManager", true,
	-- 			self.parent:getName() .. " task " .. tostring(testLog) .. " is " .. tostring(self.Tasks[testLog].Name)
	-- 		);
	-- 	end
	-- end

end