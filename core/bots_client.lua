local NUM_BOTS = 80
local VEH_ID   = 522  -- NRG-500
local SKIN     = 285
local SPAWN    = { x = 3646.7, y = -1831.2, z = 54.1, rot = 180 }

bots = {}

function createBot(i)
    local veh = createVehicle(VEH_ID, SPAWN.x, SPAWN.y, SPAWN.z, 0, 0, SPAWN.rot)
    local ped = createPed(SKIN, SPAWN.x, SPAWN.y, SPAWN.z + 1)
    warpPedIntoVehicle(ped, veh)
    bots[i] = { ped = ped, veh = veh }
end

function respawnBot(i)
    local b = bots[i]
    if not b then return end

    if not isElement(b.veh) or not isElement(b.ped) then
        if isElement(b.veh) then destroyElement(b.veh) end
        if isElement(b.ped) then destroyElement(b.ped) end
        bots[i] = nil
        createBot(i)
        return
    end

    removePedFromVehicle(b.ped)
    setElementPosition(b.veh, SPAWN.x, SPAWN.y, SPAWN.z)
    setElementRotation(b.veh, 0, 0, SPAWN.rot)
    setElementVelocity(b.veh, 0, 0, 0)
    setElementAngularVelocity(b.veh, 0, 0, 0)
    fixVehicle(b.veh)
    setElementHealth(b.ped, 100)
    warpPedIntoVehicle(b.ped, b.veh)
end

function respawnAll()
    for i = 1, NUM_BOTS do respawnBot(i) end
end

function getNumBots() return NUM_BOTS end
function getSpawnPos() return SPAWN.x, SPAWN.y, SPAWN.z end

-- no bot-on-bot collisions, they still hit track objects though
function killBotCollisions()
    local vehs = {}
    for i = 1, NUM_BOTS do
        local b = bots[i]
        if b and isElement(b.veh) then vehs[#vehs+1] = b.veh end
    end
    for i = 1, #vehs do
        for j = i+1, #vehs do
            setElementCollidableWith(vehs[i], vehs[j], false)
        end
    end
end

-- ------------------------------------------------

addEventHandler("onClientResourceStart", resourceRoot, function()
    setTime(22, 0)
    setMinuteDuration(2147483647)
    setWeather(11)

    for i = 1, NUM_BOTS do createBot(i) end
    setTimer(killBotCollisions, 1000, 1)

    outputChatBox("#00FF00[DL] #FFFFFF" .. NUM_BOTS .. " bots on the track.", 255, 255, 255, true)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    for i = 1, NUM_BOTS do
        local b = bots[i]
        if b then
            if isElement(b.veh) then destroyElement(b.veh) end
            if isElement(b.ped) then destroyElement(b.ped) end
        end
    end
    bots = {}
    setMinuteDuration(1000)
end)

addCommandHandler("mlreset", function()
    respawnAll()
    setTimer(killBotCollisions, 500, 1)
    outputChatBox("#00FF00[DL] #FFFFFFReset.", 255, 255, 255, true)
end)
