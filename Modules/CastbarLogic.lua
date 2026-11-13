local _, ns = ...
local L = {}
ns.CastbarLogic = L
function L.Clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end
function L.Progress(startTime, endTime, now, channel)
    local duration = endTime - startTime
    if duration <= 0 then return 0, 0 end
    local p = L.Clamp((now - startTime) / duration, 0, 1)
    return channel and 1 - p or p, math.max(0, endTime - now)
end
function L.ESIVisible(hud, db)
    if not hud or not db or db.enabled == false or db.castBarEnabled == false then return false end
    if hud.inEditMode or hud.sampleName then return false end
    local bar = hud.castBar
    return bar and bar:IsVisible() and bar:GetEffectiveAlpha() > 0.01 or false
end
-- Suppression is never inferred from a spell ID. An invisible ESI HUD must not eat a cast.
function L.ShouldYield(esiVisible, cast) return cast ~= nil and not cast.channel and esiVisible end
function L.AcceptEnd(activeGUID, eventGUID)
    return activeGUID == nil or eventGUID == nil or activeGUID == eventGUID
end
-- Inputs have already passed the module's secret-value guards.
function L.TimerText(startTime,endTime,now,ru)
    local duration=math.max(0,endTime-startTime)
    local text=string.format("%.1f / %.1f",L.Clamp(now-startTime,0,duration),duration)
    if ru then text=text:gsub("%.",",") end
    return text
end
