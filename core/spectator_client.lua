-- ------------------------------------------------
-- camera + bot selection
-- purely a viewing thing, the brain doesnt care about any of this
-- ------------------------------------------------

local screenW, screenH = guiGetScreenSize()
g_Scale = screenH / 1080

g_Selected = 1
g_CamOn    = false
g_HudOn    = true

local cam = { x = 0, y = 0, z = 0 }
local camH = 40
local CAM_SPEED = 8

function cameraZoomIn()  camH = math.max(camH - 5, 15) end
function cameraZoomOut() camH = math.min(camH + 5, 120) end

addEventHandler("onClientPreRender", root, function(dt)
    if not g_CamOn then return end
    local b = bots[g_Selected]
    if not b or not isElement(b.veh) then return end

    local x, y, z = getElementPosition(b.veh)
    local f = 1 - math.exp(-CAM_SPEED * dt / 1000)
    cam.x = cam.x + (x - cam.x) * f
    cam.y = cam.y + (y - cam.y) * f
    cam.z = z

    setCameraMatrix(cam.x, cam.y, cam.z + camH, cam.x, cam.y, cam.z)
end)

local function nextBot()
    local n = getNumBots()
    if n == 0 then return end
    g_Selected = (g_Selected % n) + 1
end

local function prevBot()
    local n = getNumBots()
    if n == 0 then return end
    g_Selected = ((g_Selected - 2) % n) + 1
end

local function doRespawn()
    respawnAll()
    setTimer(killBotCollisions, 500, 1)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    g_CamOn = true
    local sx, sy, sz = getSpawnPos()
    cam.x, cam.y, cam.z = sx, sy, sz
    setCameraMatrix(cam.x, cam.y, cam.z + camH, cam.x, cam.y, cam.z)

    bindKey("arrow_l", "down", prevBot)
    bindKey("arrow_r", "down", nextBot)
    bindKey("arrow_u", "down", cameraZoomOut)
    bindKey("arrow_d", "down", cameraZoomIn)
    bindKey("h", "down", function() g_HudOn = not g_HudOn end)
    bindKey("r", "down", doRespawn)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    g_CamOn = false
    setCameraTarget(localPlayer)
    unbindKey("arrow_l", "down", prevBot)
    unbindKey("arrow_r", "down", nextBot)
    unbindKey("arrow_u", "down", cameraZoomOut)
    unbindKey("arrow_d", "down", cameraZoomIn)
    unbindKey("r", "down", doRespawn)
end)
