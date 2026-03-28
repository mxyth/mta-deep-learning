-- ------------------------------------------------
-- telemetry panel + sensor ray visualization
-- ------------------------------------------------

local sw, sh = guiGetScreenSize()

addEventHandler("onClientRender", root, function()
    if not g_HudOn or not g_CamOn then return end

    local b = bots[g_Selected]
    if not b or not isElement(b.veh) then
        dxDrawText("waiting for bots...",
            sw/2-100*g_Scale, sh/2, sw/2+100*g_Scale, sh/2+30*g_Scale,
            tocolor(255,255,255,200), 1.2*g_Scale, "default-bold", "center", "center")
        return
    end

    local veh = b.veh
    local x, y, z = getElementPosition(veh)
    local _, _, rz = getElementRotation(veh)
    local vx, vy, vz = getElementVelocity(veh)
    local speed = math.sqrt(vx*vx + vy*vy + vz*vz) * 180
    local hp = getElementHealth(veh)

    -- sensor rays for the spectated bot
    if g_TrainState ~= "IDLE" and drawSensorRays then
        drawSensorRays(veh)
    end

    -- panel
    local s   = g_Scale
    local pw  = 300*s
    local px  = sw - pw - 20*s
    local py  = 20*s
    local pad = 12*s
    local lh  = 26*s
    local ph  = (32 + 8 + 7*26 + 10 + 6 + 26 + 5*26 + 8 + 24 + 8) * s

    dxDrawRectangle(px, py, pw, ph, tocolor(0,0,0,170))
    dxDrawRectangle(px, py, pw, 3*s, tocolor(0,200,80,255))

    local ty = py + 8*s
    dxDrawText("DEEP LEARNING", px, ty, px+pw, ty+24*s,
        tocolor(0,200,80,255), 1.2*s, "default-bold", "center", "center")

    local sep = ty + 32*s
    dxDrawRectangle(px+pad, sep, pw-pad*2, 1, tocolor(255,255,255,40))

    local ly = sep + 8*s
    local lx = px + pad
    local rx = px + pw - pad

    local function row(label, val, col)
        col = col or tocolor(255,255,255,230)
        dxDrawText(label, lx, ly, rx, ly+lh,
            tocolor(160,160,160,200), 0.9*s, "default", "left", "center")
        dxDrawText(val, lx, ly, rx, ly+lh,
            col, 1.0*s, "default", "right", "center")
        ly = ly + lh
    end

    row("BOT",        ("Bot-%d  [%d/%d]"):format(g_Selected, g_Selected, getNumBots()))
    row("SPEED",      ("%.1f km/h"):format(speed))
    row("POS X",      ("%.1f"):format(x))
    row("POS Y",      ("%.1f"):format(y))
    row("POS Z",      ("%.1f"):format(z))
    row("HEADING",    ("%.1f\xC2\xB0"):format(rz))
    row("VEHICLE HP", ("%.0f / 1000"):format(hp))

    ly = ly + 4*s
    dxDrawRectangle(px+pad, ly, pw-pad*2, 1, tocolor(255,255,255,40))
    ly = ly + 6*s

    dxDrawText("TRAINING", lx, ly, rx, ly+lh,
        tocolor(0,200,80,180), 1.0*s, "default-bold", "left", "center")
    ly = ly + lh

    local active = g_TrainState ~= "IDLE"
    local tc = active and tocolor(255,255,255,230) or tocolor(120,120,120,160)

    row("GENERATION", active and tostring(g_Generation) or "N/A", tc)
    row("BEST FIT",   active and ("%.0f"):format(g_BestFit) or "N/A", tc)
    row("AVG FIT",    active and ("%.0f"):format(g_AvgFit) or "N/A", tc)
    row("ALIVE",      active and ("%d/%d"):format(g_AliveCount, getNumBots()) or "N/A", tc)
    row("STATE", g_TrainState, active and tocolor(0,200,80,230) or tc)

    ly = ly + 8*s
    local hh = 24*s
    dxDrawRectangle(px, ly, pw, hh, tocolor(0,0,0,100))
    dxDrawText("[< >] Bots   [Up/Dn] Zoom   [H] HUD   [R] Reset   /mltrain",
        px, ly, px+pw, ly+hh,
        tocolor(200,200,200,160), 0.8*s, "default", "center", "center")
end)
