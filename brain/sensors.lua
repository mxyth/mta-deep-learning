-- ------------------------------------------------
-- raycast sensors
--
-- MTA rotation is counter-clockwise from north:
--   0 = north, 90 = WEST (not east), 180 = south, 270 = east
-- forward vector = (-sin(rz), cos(rz))
-- ------------------------------------------------

local NUM_RAYS   = 9
local RAY_LENGTH = 70

local RAY_ANGLES = { 0, -15, 15, -35, 35, -55, 55, -90, 90 }

-- returns 10 values: 9 ray distances + speed
-- no heading signals, no checkpoint info. the net figures it out from walls alone.
function castSensors(veh)
    if not isElement(veh) then return nil end

    local px, py, pz = getElementPosition(veh)
    pz = pz + 1.0
    local _, _, rz = getElementRotation(veh)

    local readings = {}
    for i = 1, NUM_RAYS do
        local angle = math.rad(rz + RAY_ANGLES[i])
        local dx = -math.sin(angle) * RAY_LENGTH
        local dy =  math.cos(angle) * RAY_LENGTH

        local hit, hitX, hitY, hitZ = processLineOfSight(
            px, py, pz, px + dx, py + dy, pz,
            true, false, false, true, false, false, false, false
        )

        if hit then
            local dist = math.sqrt((hitX-px)^2 + (hitY-py)^2 + (hitZ-pz)^2)
            readings[i] = dist / RAY_LENGTH
        else
            readings[i] = 1.0
        end
    end

    local vx, vy, vz = getElementVelocity(veh)
    readings[NUM_RAYS + 1] = math.min(math.sqrt(vx*vx + vy*vy + vz*vz) * 180 / 180, 1.0)

    return readings
end

function getNumSensors() return NUM_RAYS + 1 end
function getRayLength() return RAY_LENGTH end
function getRayAngles() return RAY_ANGLES end

-- ------------------------------------------------
-- debug visualization
-- ------------------------------------------------

function drawSensorRays(veh)
    if not isElement(veh) then return end

    local px, py, pz = getElementPosition(veh)
    local z = pz + 1.0
    local _, _, rz = getElementRotation(veh)

    for i = 1, NUM_RAYS do
        local angle = math.rad(rz + RAY_ANGLES[i])
        local dx = -math.sin(angle) * RAY_LENGTH
        local dy =  math.cos(angle) * RAY_LENGTH

        local hit, hitX, hitY, hitZ = processLineOfSight(
            px, py, z, px+dx, py+dy, z,
            true, false, false, true, false, false, false, false
        )

        if hit then
            local t = math.sqrt((hitX-px)^2 + (hitY-py)^2 + (hitZ-z)^2) / RAY_LENGTH
            dxDrawLine3D(px, py, z, hitX, hitY, hitZ,
                tocolor(math.floor(255*(1-t)), math.floor(255*t), 0, 200), 2)
            dxDrawLine3D(hitX, hitY, hitZ-0.3, hitX, hitY, hitZ+0.3, tocolor(255,0,0,255), 3)
        else
            dxDrawLine3D(px, py, z, px+dx, py+dy, z, tocolor(0,255,0,60), 1)
        end
    end
end
