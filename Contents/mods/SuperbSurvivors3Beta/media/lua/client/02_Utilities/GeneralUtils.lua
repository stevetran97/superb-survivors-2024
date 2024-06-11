setTimeout = function(callback, delay)
    delay = delay or 1
    local ticks = 0
    local canceled = false
    local tickRate = globalBaseUpdateDelayTicks
    local lastTickTime = os.time()

    local function onTick()
        local currentTime = os.time()
        local deltaT = currentTime - lastTickTime
        lastTickTime = currentTime

        ticks = ticks + deltaT * tickRate

        if not canceled and ticks >= delay then
            ticks = 0
            Events.OnTick.Remove(onTick)
            if not canceled then callback() end
        end
    end

    Events.OnTick.Add(onTick)

    return function()
        canceled = true
    end
end
