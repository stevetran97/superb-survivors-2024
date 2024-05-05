-- this file has methods related to world context
--- SQUARES ---

local isLocalLoggingEnabled = false;
enableLogErrors = true

---@alias direction
---| '"N"' # North
---| '"S"' # South
---| '"E"' # East
---| '"W"' # West

---Get an adjacent square based on a direction
---@param square any
---@param dir direction
---@return any the adjacent square
function GetAdjSquare(square, dir)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetAdjSquare() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"square: " .. tostring(square) ..
		" | dir: " .. tostring(dir));

	if (dir == 'N') then
		return getCell():getGridSquare(square:getX(), square:getY() - 1, square:getZ());
	elseif (dir == 'E') then
		return getCell():getGridSquare(square:getX() + 1, square:getY(), square:getZ());
	elseif (dir == 'S') then
		return getCell():getGridSquare(square:getX(), square:getY() + 1, square:getZ());
	else
		return getCell():getGridSquare(square:getX() - 1, square:getY(), square:getZ());
	end
end

function GetOutsideSquare(square, building)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetOutsideSquare() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"square: " .. tostring(square) ..
		" | building: " .. tostring(building));
	if (not building) or (not square) then
		return nil
	end

	local windowsquare = getCell():getGridSquare(square:getX(), square:getY(), square:getZ());
	if windowsquare ~= nil and windowsquare:isOutside() then
		return windowsquare
	end

	local N = GetAdjSquare(square, "N")
	local E = GetAdjSquare(square, "E")
	local S = GetAdjSquare(square, "S")
	local W = GetAdjSquare(square, "W")

	if N and N:isOutside() then
		return N
	elseif E and E:isOutside() then
		return E
	elseif S and S:isOutside() then
		return S
	elseif W and W:isOutside() then
		return W
	else
		return square
	end
end

---@param fleeGuy any
---@param attackGuy any
---@param distanceToFlee number distance that the flee guy will search for
---@return any returns a random square in a distance away from attackGuy
function GetFleeSquare(fleeGuy, attackGuy, distanceToFlee)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetFleeSquare() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		" | fleeGuy: " .. tostring(fleeGuy) ..
		" | attackGuy: " .. tostring(attackGuy) ..
		" | distanceToFlee: " .. tostring(distanceToFlee));
	local distance = 7;
	local tempx = (fleeGuy:getX() - attackGuy:getX());
	local tempy = (fleeGuy:getY() - attackGuy:getY());

	if (distanceToFlee) then
		distance = distanceToFlee;
	end

	if (tempx < 0) then
		tempx = -distance;
	else
		tempx = distance;
	end
	if (tempy < 0) then
		tempy = -distance
	else
		tempy = distance
	end

	local fleeTargetRange = math.floor(distanceToFlee/2)

	local fleex = fleeGuy:getX() + tempx 
		+ ZombRand(-fleeTargetRange, fleeTargetRange)
	local fleey = fleeGuy:getY() + tempy
		+ ZombRand(-fleeTargetRange, fleeTargetRange)

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		" | fleeGuy: " .. tostring(fleeGuy) ..
		" | Flee X: " .. tostring(fleex) ..
		" | Flee Y: " .. tostring(fleey));

	return fleeGuy:getCell():getGridSquare(fleex, fleey, fleeGuy:getZ());
end

--- gets a square torwards a direction in a fixed distance (15)
---@param moveguy any
---@param x number
---@param y number
---@param z number
function GetTowardsSquare(moveguy, x, y, z)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetTowardsSquare() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"moveGuy: " .. tostring(moveguy) ..
		" | x: " .. tostring(x) ..
		" | y: " .. tostring(y) ..
		" | z: " .. tostring(z)
	);
	local distance = 15
	local tempx = (moveguy:getX() - x);
	local tempy = (moveguy:getY() - y);

	if (tempx > 0) and (tempx >= distance) then
		tempx = -distance;
	elseif (tempx < -distance) then
		tempx = distance
	else
		tempx = -tempx
	end

	if (tempy > 0) and (tempy >= distance) then
		tempy = -distance
	elseif (tempy < -distance) then
		tempy = distance;
	else
		tempy = -tempy
	end

	local movex = moveguy:getX() + tempx + ZombRand(-2, 2)
	local movey = moveguy:getY() + tempy + ZombRand(-2, 2)

	return moveguy:getCell():getGridSquare(movex, movey, moveguy:getZ());
end

--- END SQUARES ---

--- COORDINATES ---
--- gets the coordinate from a npc survivor
---@param id any if of the npc survivor
---@return any
function GetCoordsFromID(id)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetCoordsFromID() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "id: " .. tostring(id));

	for k, v in pairs(SurvivorMap) do
		for i = 1, #v do
			if (v[i] == id) then
				CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "SurvivorMap: " ..
					"id: " .. tostring(id) ..
					" | value: " .. tostring(v) ..
					" | index: " .. tostring(i)
				);
				return k;
			end
		end
	end

	return 0
end

-- Moves along the perimeter of a square
-- sq - something that you can getX() and getY() from
-- Depth: integer from positive 1 to however much
-- callback: a function to be run at the square

function scanAroundSquare(sq, depth, callback)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: scan AroundSquare() called");
	if not sq then return false end
	local squareX = sq:getX()
	local squareY = sq:getY()

	-- CreateLogLine("DebugScanAroundSquare", true, "Scanning Depth of " .. tostring(depth));
	-- CreateLogLine("DebugScanAroundSquare", true, "STARTING Square xInc " .. tostring(squareX));
	-- CreateLogLine("DebugScanAroundSquare", true, "STARTING Square yInc " .. tostring(squareY));

	if depth == 0 
	then
		return callback(squareX, squareY)
	end

	-- Start at top left corner but 1 off to right of x
	local xInc = squareX - depth + 1
	local yInc = squareX - depth
	-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 1 ");

	local endBoundary = xInc + depth
	while true do
		callback(xInc, yInc)
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "x Inc = " .. tostring(xInc));
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "y Inc = " .. tostring(yInc));
		-- CreateLogLine("DebugScanAroundSquare", true, "Square xInc " .. tostring(xInc));
		-- CreateLogLine("DebugScanAroundSquare", true, "Square yInc " .. tostring(yInc));
		-- CreateLogLine("DebugScanAroundSquare", true, "endBoundary " .. tostring(endBoundary));

		-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 1.1 ");
		
		if (xInc == endBoundary) then break end
		xInc = xInc + 1
	end
	-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 2 ");

	-- Move y down to next square
	xInc = xInc + depth
	yInc = yInc + 1		
	endBoundary = yInc + depth

	while true do
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "x Inc = " .. tostring(xInc));
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "y Inc = " .. tostring(yInc));

		callback(xInc, yInc)

		if (yInc == endBoundary) then break end
		yInc = yInc + 1
		-- if (yInc == yInc + depth) then break end
	end

	-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 3 ");
	-- Move y left to next square
	xInc = xInc - 1	
	yInc = yInc + depth
	endBoundary = xInc - depth

	while true do
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "x Inc = " .. tostring(xInc));
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "y Inc = " .. tostring(yInc));

		callback(xInc, yInc)
		-- if (xInc ~= xInc - depth) then 
		if (xInc == endBoundary) then break end
		xInc = xInc - 1 
		-- end	
		-- if (xInc == xInc - depth) then break end
	end

	xInc = xInc - depth
	yInc = yInc - 1	
	endBoundary = yInc - depth

	-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 4 ");

	while true do
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "x Inc = " .. tostring(xInc));
		-- CreateLogLine("DebugScanAroundSquare", isLocalLoggingEnabled, "y Inc = " .. tostring(yInc));

		callback(xInc, yInc)
		-- if (yInc ~= yInc - depth) then 
		if (yInc == endBoundary) then break end
		yInc = yInc - 1 
		-- end
		-- if (yInc == yInc - depth) then break end
	end

	-- CreateLogLine("DebugScanAroundSquare", true, "Checkpoint 5 ");

end


-- Batmane: Early return distance capping function for computational efficiency
function isBeyondMaxDistance(z1, z2, maxDistance) 
	CreateLogLine("SuperSurvivorContextUtilitiesBatmane", isLocalLoggingEnabled, "function: isBeyondMaxDistance() called");
	CreateLogLine("SuperSurvivorContextUtilitiesBatmane", isLocalLoggingEnabled,
		"z1: " .. tostring(z1) ..
		" | z2: " .. tostring(z2)
	);

    if not z1 or not z2 or not maxDistance then
        return false
    end

    -- Check X distance
    local dx = math.abs(z1:getX() - z2:getX())
    if dx > maxDistance then
		-- CreateLogLine("SuperSurvivorContextUtilitiesBatmane", true, "DelX of Thing is beyond max distance");
        return true
    end
    
    -- Check Y distance
    local dy = math.abs(z1:getY() - z2:getY())
    if dy > maxDistance then
		-- CreateLogLine("SuperSurvivorContextUtilitiesBatmane", true, "DelY of Thing is beyond max distance");
        return true
    end

    -- Check Z distance
    local dz = math.abs(z1:getZ() - z2:getZ())
    if dz > maxDistance then
		-- CreateLogLine("SuperSurvivorContextUtilitiesBatmane", true, "DelZ of Thing is beyond max distance");
        return true
    end
	-- CreateLogLine("SuperSurvivorContextUtilitiesBatmane", true, "Thing is not beyond max distance");
	return false
end

-- Batmane TODO: Need to find a better method for distance measurement. 
-- Perhaps reduce distance to care more about 2D distance since that generally matters more 
-- than if a zombie is on level 2 above you

-- WIP - Cows: this function is literally spammed between all active instances, slowing down the game performance drastically.
-- WIP - Cows: in about 30 seconds, this function was called over 11,000 times.
--- gets the distance between 2 things (objects, zombies, npcs or players)
---@param z1 any instance one
---@param z2 any instance two
---@return number the distance between the 2 instances
function GetDistanceBetween(z1, z2)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetDistanceBetween() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"z1: " .. tostring(z1) ..
		" | z2: " .. tostring(z2)
	);
	if (z1 == nil) or (z2 == nil) then
		return 1;
	end

	local z1x = z1:getX()
	local z1y = z1:getY()
	local z1z = z1:getZ()

	local z2x = z2:getX()
	local z2y = z2:getY()
	local z2z = z2:getZ()

	local dx = z1x - z2x
	local dy = z1y - z2y
	local dz = z1z - z2z

	local distance = math.sqrt(dx * dx + dy * dy + (dz * dz * 2));
	--
	if (distance ~= nil) then
		return distance;
	end

	return 1;
end

-- This is not a real distance but it can act as a warning parameter
-- The theorem is that the minimum distance of the hypotenose is at least larger than the largest of the 2 sides of a right angle triangle
-- So if the target is closer than the largest x or y, that large number can be used as a minimum estimation of the distance
-- This will always under predict
function GetCheapXYDistanceBetween(z1, z2)
	if not z1 or not z2 then
		return 1;
	end

	local z1x = z1:getX()
	local z1y = z1:getY()

	local z2x = z2:getX()
	local z2y = z2:getY()

    -- Get X distance
    local dx = math.abs(z1:getX() - z2:getX())
    
    -- Get Y distance
    local dy = math.abs(z1:getY() - z2:getY())

	return math.max(dx, dy)
end

--- gets the XY Plane distance between 2 things (objects, zombies, npcs or players)
---@param z1 any instance one
---@param z2 any instance two
---@return number the distance between the 2 instances
function GetXYDistanceBetween(z1, z2)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetXYDistanceBetween() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"z1: " .. tostring(z1) ..
		" | z2: " .. tostring(z2)
	);
	if (z1 == nil) or (z2 == nil) then
		return 1;
	end

	local z1x = z1:getX()
	local z1y = z1:getY()

	local z2x = z2:getX()
	local z2y = z2:getY()

	local dx = z1x - z2x
	local dy = z1y - z2y


	local distance = math.sqrt(dx * dx + dy * dy);
	--

	if (distance ~= nil) then
		return distance;
	end

	return 1;
end

-- Use this is the Z distance matters but you dont want to do expensive pythag theorem
local zDistanceFactor = 6
function GetCheap3DDistanceBetween(z1, z2)
	if (z1 == nil) or (z2 == nil) then
		return 1;
	end

	local distanceXY = GetXYDistanceBetween(z1, z2)
	distanceXY = distanceXY + zDistanceFactor * (z2:getZ() - z1:getZ())
	return distanceXY
end


function getVector(sq1, sq2) 
	if not sq1 or not sq2 or not sq1:getX() or not sq2:getX() or not sq1:getY() or not sq2:getY() then
		CreateLogLine('BatmaneErrors', enableLogErrors, 'getXYUnitVector: Cannot get vector due to not being able to getX or getY')
	end

	local newVector = {
		x = sq2:getX() - sq1:getX(),
		y = sq2:getY() - sq1:getY()
	}
	
	return newVector
end

function addVectors(v1, v2) 
	if not v1 or not v2 or not v1.x or not v1.y or not v2.x or not v2.y then
		CreateLogLine('BatmaneErrors', enableLogErrors, 'addVectors: Cannot add vector due to not being able to dimensions')
	end

	local newVector = {
		x = v1.x + v2.x,
		y = v1.y + v2.y
	}

	return newVector
end


function convertToUnitVector(v) 
	if not v or not v.x or not v.y then
		CreateLogLine('BatmaneErrors', enableLogErrors, 'convertToUnitVector: Cannot convert vector due to not being able to dimensions')
	end

	local length = math.sqrt(v.x * v.x + v.y * v.y)

	local newVector = {
		x = v.x / length,
		y = v.y / length
	}
	
	return newVector
end

--- gets an XY plane vector from 2 things with x adn y coordinates
--- ex. like rope squares or squares characters are standing on
function getXYUnitVector(sq1, sq2) 
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: getXYUnitVector() called");

	if not sq1 or not sq2 or not sq1:getX() or not sq2:getX() or not sq1:getY() or not sq2:getY() then
		CreateLogLine('BatmaneErrors', enableLogErrors, 'getXYUnitVector: Cannot get vector due to not being able to getX or getY')
	end

	local newVector = getVector(sq1, sq2)

	local length = math.sqrt(newVector.x * newVector.x + newVector.y * newVector.y)

	local unitVector = {
		x = newVector.x / length,
		y = newVector.y / length
	}

	local unitlength = math.sqrt(unitVector.x * unitVector.x + unitVector.y * unitVector.y)

	return unitVector
end

-- Using current sq1 location, get location 2 using a vector (unit vector of length 1)
function getXYSq2FromSq1ToVector(sq1, vector, distanceToGo)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: getXYSq2FromSq1ToVector() called");
	if (not sq1) or (not sq1:getX()) or (not sq1:getY()) then
		CreateLogLine('Errors', enableLogErrors, 'getSq2FromSq1ToVector: Cannot get sq2 due to invalid sq1')
	end
	if (not vector.x) or (not vector.y) then
		CreateLogLine('Errors', enableLogErrors, 'getSq2FromSq1ToVector: Cannot get sq2 due to invalid vector')
	end

	-- Debug
	-- local testLength = math.sqrt(vector.x * vector.x + vector.y * vector.y)
	-- CreateLogLine('GraceErrors', true, 'vector length = ' .. tostring(testLength))
	-- if testLength > 1 then
	-- 	CreateLogLine('GraceErrors', true, 'Vector is not a unit vector. Length = ' .. tostring(testLength))
	-- end
	-- 

	if (not distanceToGo) then
		distanceToGo = 7
	end

	local newSquare = {
		x = math.floor(sq1:getX() + vector.x * distanceToGo),
		y = math.floor(sq1:getY() + vector.y * distanceToGo)
	}

	return newSquare
end

--- Batmane: This does not get exact distance. 
-- This just gets the largest non-hypotenose side of the right angle triangle
-- The real distance is larger than whatever this returns
---@param z1 any instance one
---@param z2 any instance two
---@return number the rough distance between the 2 instances
function GetisWithinRoughXYDistance(z1, z2)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetXYDistanceBetween() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"z1: " .. tostring(z1) ..
		" | z2: " .. tostring(z2)
	);
	if (z1 == nil) or (z2 == nil) then
		return math.huge;
	end

	local distanceUpperBound = math.max(math.abs(z2:getX() - z1:getX()), math.abs(z2:getY() - z1:getY()))
	CreateLogLine("SuperSurvivorContextUtilitiesBatmane", true, "distanceUpperBound: " .. tostring(distanceUpperBound));

	return distanceUpperBound
end


--- gets the distance between 2 coordinates
---@param Ax number
---@param Ay number
---@param Bx number
---@param By number
---@return number the distance between the 2 points
function GetDistanceBetweenPoints(Ax, Ay, Bx, By)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetDistanceBetweenPoints() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"Ax: " .. tostring(Ax) ..
		"| Ay: " .. tostring(Ay) ..
		"| Bx: " .. tostring(Bx) ..
		"| By: " .. tostring(By)
	);
	if (Ax == nil) or (Bx == nil) then
		return -1
	end

	local dx = Ax - Bx
	local dy = Ay - By

	return math.sqrt(dx * dx + dy * dy)
end

--- END COORDINATES ---

--- AREAS ----

--- checks if the square is inside of the area 'area'
---@param sq any
---@param area table a table with 4 positions representing a square of points(number)
function IsSquareInArea(sq, area)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: IsSquareInArea() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"sq: " .. tostring(sq) ..
		" | area: " .. tostring(area)
	);
	local x1 = area[1]
	local x2 = area[2]
	local y1 = area[3]
	local y2 = area[4]

	if (sq:getX() > x1) and (sq:getX() <= x2) and (sq:getY() > y1) and (sq:getY() <= y2) and (sq:getZ() == area[5]) then
		return true
	else
		return false
	end
end

--- gets the center square of an area
---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@param z  number
---@return any the center square given the coordinates
function GetCenterSquareFromArea(x1, x2, y1, y2, z)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetCenterSquareFromArea() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"x1: " .. tostring(x1) ..
		" | x2: " .. tostring(x2) ..
		" | y1: " .. tostring(y1) ..
		" | y2: " .. tostring(y2) ..
		" | z: " .. tostring(z)
	);
	local xdiff = x2 - x1
	local ydiff = y2 - y1

	local result = getCell():getGridSquare(x1 + math.floor(xdiff / 2), y1 + math.floor(ydiff / 2), z)

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"--- function: GetCenterSquareFromArea() End ---");
	return result
end

--- gets a random square inside of an area
---@param area any
function GetRandomAreaSquare(area)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetRandomAreaSquare() called");
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"area: " .. tostring(area)
	);
	local x1 = area[1]
	local x2 = area[2]
	local y1 = area[3]
	local y2 = area[4]
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"x1: " .. tostring(x1) ..
		" | x2: " .. tostring(x2) ..
		" | y1: " .. tostring(y1) ..
		" | y2: " .. tostring(y2)
	);
	if (x1 ~= nil) then
		local xrand = ZombRand(x1, x2)
		local yrand = ZombRand(y1, y2)
		local result = getCell():getGridSquare(xrand, yrand, area[5])

		return result
	end
end

--- END AREAS ----

--- OBJECTS ---

--- WINDOWS ----

--- gets a window square
---@param cs any a square
---@return any the window object if found or nil
function getSquaresWindow(cs)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: getSquaresWindow() called");
	if not cs then
		return nil
	end

	local objs = cs:getObjects()
	for i = 0, objs:size() - 1 do
		local obj = objs:get(i)
		if (instanceof(obj, "IsoWindow")) then
			return obj
		end
	end


	return nil
end

-- Batmane Get Hoppable
function getHoppable(cs)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: getHoppable() called");
	if not cs then
		return nil
	end

	local objs = cs:getObjects()
	for i = 0, objs:size() - 1 do
		local obj = objs:get(i)
		if (obj) then 
			-- CreateLogLine("SuperSurvivorContextUtilities", true, "obj:isHoppable(): " .. tostring(obj:isHoppable()));
			-- CreateLogLine("SuperSurvivorContextUtilities", true, "obj:haveSheetRope(): " .. tostring(obj:haveSheetRope()));
			if (obj:isHoppable() and obj:haveSheetRope()) then
				return obj
			end
		end
	end

	return nil
end

-- WIP - Cows: GetSquaresNearWindow() is the second most frequently called function after GetDistanceBetween().
--- gets the nearest adjacent window square of 'cs'
---@param cs any a square
---@return any the adjacent square next to window if found or nil
-- function GetSquaresNearWindow(cs)
-- 	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetSquaresNearWindow() called");
-- 	local directions = { "N", "E", "S", "W" }

-- 	for k, dir in ipairs(directions) do
-- 		local square = GetAdjSquare(cs, dir)
-- 		local res = getSquaresWindow(square)

-- 		if cs and square and res then
-- 			return res
-- 		end
-- 	end

-- 	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "--- function: GetSquaresNearWindow() END ---");
-- 	return nil
-- end

-- Batmane Apr 24 2024 - Replacement for Above
-- findResource: (square: grid square) => object -- square is the grid square or rope square in alot of cases.
function GetResourceFromSquaresAroundAccessPoint(cs, findResource)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetResource FromSquaresAroundAccessPoint() called");
	local directions = { "N", "E", "S", "W" }

	-- Check square that you are standing on
	local resMainSq = findResource(cs)
	if not cs then return nil end
	if resMainSq then
		return resMainSq
	end

	-- Check square in all other directions
	for k, dir in ipairs(directions) do
		local square = GetAdjSquare(cs, dir)
		local res = findResource(square)

		if square and res then
			return res
		end
	end

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "--- function: GetResource FromSquaresAroundAccessPoint() END ---");
	return nil
end

--- END WINDOWS ----

--- DOORS ----

--- gets the inside square of a door
---@param door any
---@param player any
---@return any returns the inside square of a door or nil if not found
function GetDoorsInsideSquare(door, player)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetDoorsInsideSquare() called");
	if (player == nil) or not (instanceof(door, "IsoDoor")) then
		return nil
	end

	local sq1 = door:getOppositeSquare()
	local sq2 = door:getSquare()
	local sq3 = door:getOtherSideOfDoor(player)

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "--- function: GetDoorsInsideSquare() END ---");
	if (not sq1:isOutside()) then
		return sq1
	elseif (not sq2:isOutside()) then
		return sq2
	elseif (not sq3:isOutside()) then
		return sq3
	else
		return nil
	end
end

--- gets the outside square of a door
---@param door any
---@param player any
---@return any returns the inside outside of a door or nil if not found
function GetDoorsOutsideSquare(door, player)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetDoorsOutsideSquare() called");
	if (player == nil) or not (instanceof(door, "IsoDoor")) then
		return nil
	end

	local sq1 = door:getOppositeSquare()
	local sq2 = door:getSquare()
	local sq3 = door:getOtherSideOfDoor(player)

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "--- function: GetDoorsOutsideSquare() END ---");
	if (sq1 and sq1:isOutside()) then
		return sq1
	elseif (sq2 and sq2:isOutside()) then
		return sq2
	elseif (sq3 and sq3:isOutside()) then
		return sq3
	else
		return nil
	end
end

-- WIP - Cows: NEED TO REWORK THE NESTED LOOP CALLS
--- gets the closest unlocked door
---@param building any
---@param character any
---@return any returns the closest exterior unlocked door or nil if not found
function GetUnlockedDoor(building, character)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetUnlockedDoor() called");
	local DoorOut = nil
	local closestSoFar = 100
	local bdef = building:getDef()

	for x = bdef:getX() - 1, (bdef:getX() + bdef:getW() + 1) do
		for y = bdef:getY() - 1, (bdef:getY() + bdef:getH() + 1) do
			local sq = getCell():getGridSquare(x, y, character:getZ())

			if (sq) then
				local Objs = sq:getObjects();
				local distance = GetDistanceBetween(sq, character) -- WIP - literally spammed inside the nested for loops...
				CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
					"Objects size: " .. tostring(Objs:size() - 1));

				for j = 0, Objs:size() - 1 do
					local Object = Objs:get(j)

					if (Object ~= nil) then
						if (instanceof(Object, "IsoDoor"))
							and (Object:isExteriorDoor(character))
							and (distance < closestSoFar) then
							if (not Object:isLocked()) then
								closestSoFar = distance;
								DoorOut = Object;
							end
						end
					end
				end
			end
		end
	end

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "--- function: GetUnlockedDoor() END ---");
	return DoorOut
end

--- END DOORS ----

--- BUILDINGS ---

--- gets the amount of zombies inside and around a building
---@param building any
---@return integer returns the amount of zombies found in the building
function NumberOfZombiesInOrAroundBuilding(building)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"function: NumberOfZombiesInOrAroundBuilding() called");
	local count = 0
	local padding = 10
	local bdef = building:getDef()

	local bdefX = bdef:getX()
	local bdefY = bdef:getY()

	local bdWidth = bdefX + bdef:getW() + padding
	local bdHeight = bdefY + bdef:getH() + padding

	for x = (bdefX - padding), bdWidth do
		for y = (bdefY - padding), bdHeight do
			local sq = getCell():getGridSquare(x, y, 0)
			if (sq) then
				local Objs = sq:getMovingObjects();
				for j = 0, Objs:size() - 1 do
					local Object = Objs:get(j)
					if (Object ~= nil) and (instanceof(Object, "IsoZombie")) then
						count = count + 1
					end
				end
			end
		end
	end

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"--- function: NumberOfZombiesInOrAroundBuilding() END ---");
	return count
end

--- gets a random square inside of a building
---@param building any
---@return any returns a random square inside of the building
function GetRandomBuildingSquare(building)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled, "function: GetRandomBuildingSquare() called");
	local bdef = building:getDef()
	local x = ZombRand(bdef:getX(), (bdef:getX() + bdef:getW()))
	local y = ZombRand(bdef:getY(), (bdef:getY() + bdef:getH()))

	local sq = getCell():getGridSquare(x, y, 0)
	if (sq) then
		return sq
	end

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"--- function: GetRandomBuildingSquare() END ---");
	return nil
end

--- gets a random and free square inside of a building (it tries 100 of times until it finds so be careful using it)
--- WIP - Cows: There must be a better way to handle it rather than try-spamming multiple times...
---@param building any
---@return any returns a random square inside of the building
function GetRandomFreeBuildingSquare(building)
	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"function: GetRandomFreeBuildingSquare() called");
	if (building == nil) then
		return nil
	end

	local bdef = building:getDef()

	for i = 0, 100 do
		local x = ZombRand(bdef:getX(), (bdef:getX() + bdef:getW()))
		local y = ZombRand(bdef:getY(), (bdef:getY() + bdef:getH()))

		local sq = getCell():getGridSquare(x, y, 0)
		if (sq) and sq:isFree(false) and (sq:getRoom() ~= nil) and (sq:getRoom():getBuilding() == building) then
			return sq
		end
	end

	CreateLogLine("SuperSurvivorContextUtilities", isLocalLoggingEnabled,
		"--- function: GetRandomFreeBuildingSquare() END ---");
	return nil
end

--- END BUILDINGS ---
