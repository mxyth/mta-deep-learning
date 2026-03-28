-- ------------------------------------------------
-- maps neural net output to MTA vehicle controls
-- output[1] = steering: -1 hard left, +1 hard right
-- output[2] = power:    -1 full brake, +1 full gas
-- ------------------------------------------------

local STEER_DEADZONE = 0.05

function applyControls(ped, output)
    if not isElement(ped) then return end

    local steer = output[1]
    local power = output[2]

    setPedAnalogControlState(ped, "vehicle_left", 0)
    setPedAnalogControlState(ped, "vehicle_right", 0)
    setPedAnalogControlState(ped, "accelerate", 0)
    setPedAnalogControlState(ped, "brake_reverse", 0)

    if steer < -STEER_DEADZONE then
        setPedAnalogControlState(ped, "vehicle_left", math.abs(steer))
    elseif steer > STEER_DEADZONE then
        setPedAnalogControlState(ped, "vehicle_right", steer)
    end

    if power > 0 then
        setPedAnalogControlState(ped, "accelerate", power)
    else
        setPedAnalogControlState(ped, "brake_reverse", math.abs(power))
    end
end

function clearControls(ped)
    if not isElement(ped) then return end
    setPedAnalogControlState(ped, "vehicle_left", 0)
    setPedAnalogControlState(ped, "vehicle_right", 0)
    setPedAnalogControlState(ped, "accelerate", 0)
    setPedAnalogControlState(ped, "brake_reverse", 0)
end
