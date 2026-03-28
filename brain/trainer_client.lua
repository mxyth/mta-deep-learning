-- ------------------------------------------------
-- training manager
-- pure neural net control, no autopilot, no heading signals
-- bots learn to drive entirely from raycasts + speed
-- fitness = total distance traveled without crashing
-- ------------------------------------------------

local TOPOLOGY    = { 10, 4, 2 }
local GEN_TIME    = 20
local TRAIN_SPEED = 5
local STALE_LIMIT = 5

local MIN_CRASH_FORCE = 10
local MAX_GROUND_NZ   = 0.5

local GOAL        = { x = 3628, y = -2204 }
local GOAL_RADIUS = 8
local goalMarker  = nil

-- ------------------------------------------------
-- state
-- ------------------------------------------------

g_TrainState  = "IDLE"
g_Generation  = 0
g_BestFit     = 0
g_AvgFit      = 0
g_AliveCount  = 0

local agents    = {}
local genTimer  = 0
local training  = false
local prevBest  = 0
local staleGens = 0
local vehToBotIdx = {}

-- ------------------------------------------------

local function dist(x1, y1, x2, y2)
    return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

local function findLeadBot()
    local bestIdx, bestScore = 1, -1
    for i = 1, #agents do
        if agents[i].alive and agents[i].fitness > bestScore then
            bestScore = agents[i].fitness
            bestIdx = i
        end
    end
    return bestIdx
end

-- ------------------------------------------------
-- agent lifecycle
-- ------------------------------------------------

local function initAgents(nets)
    agents = {}
    vehToBotIdx = {}
    g_AliveCount = getNumBots()
    for i = 1, getNumBots() do
        agents[i] = {
            net = nets[i], fitness = 0, bestFitness = 0,
            alive = true, stuckTimer = 0,
            lastX = 0, lastY = 0,
        }
        local b = bots[i]
        if b and isElement(b.veh) then
            vehToBotIdx[b.veh] = i
            agents[i].lastX, agents[i].lastY = getElementPosition(b.veh)
        end
    end
end

local function respawnAgent(idx)
    local a, b = agents[idx], bots[idx]
    if not a or not b then return end
    a.bestFitness = math.max(a.bestFitness, a.fitness)
    a.fitness, a.stuckTimer = 0, 0
    a.alive = true
    g_AliveCount = g_AliveCount + 1
    if isElement(b.veh) then
        setElementFrozen(b.veh, false)
        setElementPosition(b.veh, getSpawnPos())
        setElementRotation(b.veh, 0, 0, 180)
        setElementVelocity(b.veh, 0, 0, 0)
        setElementAngularVelocity(b.veh, 0, 0, 0)
        fixVehicle(b.veh)
    end
    if isElement(b.ped) then
        setElementHealth(b.ped, 100)
        removePedFromVehicle(b.ped)
        warpPedIntoVehicle(b.ped, b.veh)
    end
end

local function killAgent(idx)
    local a = agents[idx]
    if not a or not a.alive then return end
    a.alive = false
    g_AliveCount = g_AliveCount - 1
    local b = bots[idx]
    if b and isElement(b.ped) then clearControls(b.ped) end
    if b and isElement(b.veh) then setElementFrozen(b.veh, true) end
    setTimer(function()
        if training then
            respawnAgent(idx)
            setTimer(killBotCollisions, 200, 1)
        end
    end, 400, 1)
end

local function onVehicleCollision(_, force, _, _, _, _, _, _, nz)
    if not training then return end
    local idx = vehToBotIdx[source]
    if not idx then return end
    if math.abs(nz) > MAX_GROUND_NZ then return end
    if force < MIN_CRASH_FORCE then return end
    killAgent(idx)
end

-- ------------------------------------------------
-- fitness = distance traveled without crashing
-- ------------------------------------------------

local function updateFitness(i, dt)
    local a = agents[i]
    if not a or not a.alive then return end
    local b = bots[i]
    if not b or not isElement(b.veh) then return end
    local x, y = getElementPosition(b.veh)

    if dist(x, y, GOAL.x, GOAL.y) < GOAL_RADIUS then
        outputChatBox(("#00FF00[DL] #FFFFFFBot-%d finished the track! Gen %d"):format(
            i, g_Generation), 255, 255, 255, true)
        outputChatBox("#00FF00[DL] #FFFFFFTraining complete.", 255, 255, 255, true)
        stopTraining()
        return
    end

    local moved = dist(x, y, a.lastX, a.lastY)
    a.fitness = a.fitness + moved
    a.lastX, a.lastY = x, y

    if moved < 0.15 * dt then
        a.stuckTimer = a.stuckTimer + dt
        if a.stuckTimer > 3.0 then killAgent(i) end
    else
        a.stuckTimer = 0
    end
end

-- ------------------------------------------------
-- brain tick
-- ------------------------------------------------

local function tickAgent(i)
    local a = agents[i]
    if not a or not a.alive then return end
    local b = bots[i]
    if not b or not isElement(b.veh) or not isElement(b.ped) then return end

    local readings = castSensors(b.veh)
    if not readings then return end

    local output = a.net:forward(readings)
    applyControls(b.ped, output)
end

-- ------------------------------------------------
-- generation lifecycle
-- ------------------------------------------------

local function startGeneration(nets)
    g_Generation = g_Generation + 1
    g_TrainState = "RUNNING"
    genTimer = 0
    agents = {}
    respawnAll()
    setTimer(killBotCollisions, 500, 1)
    setTimer(function() initAgents(nets) end, 600, 1)
end

local function endGeneration()
    g_TrainState = "EVOLVING"
    for i = 1, getNumBots() do
        local b = bots[i]
        if b then
            if isElement(b.ped) then clearControls(b.ped) end
            if isElement(b.veh) then setElementFrozen(b.veh, false) end
        end
    end

    local pop = {}
    local totalFit, best = 0, 0
    for i = 1, #agents do
        local fit = math.max(agents[i].bestFitness, agents[i].fitness)
        pop[i] = { net = agents[i].net, fitness = fit }
        totalFit = totalFit + fit
        if fit > best then best = fit end
    end
    g_BestFit = best
    g_AvgFit  = totalFit / #agents

    if best > prevBest + 0.5 then staleGens = 0; prevBest = best
    else staleGens = staleGens + 1 end

    local boost = staleGens >= STALE_LIMIT and 2.0 or 1.0
    outputChatBox(("#00FF00[DL] #FFFFFFGen %d | best: %.0f | avg: %.0f%s"):format(
        g_Generation, g_BestFit, g_AvgFit,
        boost > 1 and " #FF6600(BOOSTED)" or ""), 255, 255, 255, true)

    startGeneration(Genetic.evolve(pop, TOPOLOGY, boost))
end

local function onFrame(dt)
    if not training or #agents == 0 then return end
    genTimer = genTimer + dt / 1000
    for i = 1, #agents do
        tickAgent(i)
        updateFitness(i, dt / 1000)
    end
    g_Selected = findLeadBot()
    if genTimer >= GEN_TIME then endGeneration() end
end

-- ------------------------------------------------
-- start / stop
-- ------------------------------------------------

function startTraining()
    if training then return end
    training = true
    g_Generation, g_BestFit, g_AvgFit, prevBest, staleGens = 0, 0, 0, 0, 0
    setGameSpeed(TRAIN_SPEED)

    goalMarker = createMarker(GOAL.x, GOAL.y, 54.5, "cylinder", GOAL_RADIUS * 2, 0, 255, 100, 120)

    local nets = {}
    for i = 1, getNumBots() do nets[i] = NeuralNet.new(TOPOLOGY) end
    addEventHandler("onClientPreRender", root, onFrame)
    addEventHandler("onClientVehicleCollision", root, onVehicleCollision)
    startGeneration(nets)

    outputChatBox(("#00FF00[DL] #FFFFFFTraining started. %d bots, speed %.0fx"):format(
        getNumBots(), TRAIN_SPEED), 255, 255, 255, true)
end

function stopTraining()
    if not training then return end
    training = false
    g_TrainState = "IDLE"
    g_AliveCount = 0
    setGameSpeed(1.0)

    if isElement(goalMarker) then destroyElement(goalMarker) end
    goalMarker = nil

    removeEventHandler("onClientPreRender", root, onFrame)
    removeEventHandler("onClientVehicleCollision", root, onVehicleCollision)
    for i = 1, getNumBots() do
        local b = bots[i]
        if b then
            if isElement(b.ped) then clearControls(b.ped) end
            if isElement(b.veh) then setElementFrozen(b.veh, false) end
        end
    end
    outputChatBox("#00FF00[DL] #FFFFFFTraining stopped.", 255, 255, 255, true)
end

function isTraining() return training end

addCommandHandler("mltrain", function()
    if training then stopTraining() else startTraining() end
end)
