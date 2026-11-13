local ADDON, ns = ...
local D = {}
ns.CastbarDuration = D
local function Safe(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
local function Finite(value)
    value=Safe(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge and value or nil
end
function D.Read(unit, channel)
    local getter
    if channel then getter=UnitChannelDuration else getter=UnitCastingDuration end
    if type(getter)~="function" then return nil end
    local ok,object=pcall(getter,unit)
    if not ok then return nil end
    return Safe(object)
end
function D.Supported(bar)
    return bar and type(bar.SetTimerDuration)=="function" and Enum and Enum.StatusBarInterpolation and Enum.StatusBarTimerDirection
end
function D.Apply(bar, object, channel)
    if not object or not D.Supported(bar) then return false end
    if bar.andivalDuration==object and bar.andivalDurationChannel==channel then return true end
    local direction=channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
    local ok=pcall(bar.SetTimerDuration,bar,object,Enum.StatusBarInterpolation.Immediate,direction)
    if not ok then D.Clear(bar);return false end
    bar.andivalDuration,bar.andivalDurationChannel=object,channel
    return true
end
function D.Clear(bar)
    if bar.andivalDuration then
        bar.andivalDuration,bar.andivalDurationChannel=nil,nil
        bar:SetMinMaxValues(0,1)
        bar:SetValue(0)
    end
end
function D.TimerText(object, ru, settings)
    if not object or not object.GetElapsedDuration or not object.GetTotalDuration then return "" end
    local okElapsed,elapsed=pcall(object.GetElapsedDuration,object)
    local okTotal,total=pcall(object.GetTotalDuration,object)
    if not okElapsed or not okTotal then return "" end
    elapsed,total=Finite(elapsed),Finite(total)
    -- Native animation can consume secrets; Lua must never derive or invent numbers.
    if not elapsed or not total or total<=0 then return "" end
    if ns.CastbarAppearance then return ns.CastbarAppearance.FormatDuration(elapsed,total,ru,settings) end
    local text=string.format("%.1f / %.1f",math.max(0,math.min(elapsed,total)),total)
    if ru then text=text:gsub("%.",",") end
    return text
end
