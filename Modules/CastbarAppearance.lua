local _,ns=...
local A={}
ns.CastbarAppearance=A
local colors={amber={1,.70,.28},blue={.42,.75,1},teal={.30,.86,.72},violet={.76,.57,1},white={.88,.91,.95}}
local applied=setmetatable({}, {__mode="k"})
local baseColors={cast={1,.78,.25},channel={.36,.88,.55},success={1,.86,.40},interrupted={1,.24,.18}}
local function PublicNumber(v)
    if issecretvalue and issecretvalue(v) then return nil end
    if type(v)~="number" or v~=v or v==math.huge or v==-math.huge then return nil end
    return v
end
-- Resolve localized Blizzard font objects rather than hardcoded Latin-only font paths.
function A.ApplyFont(fontString,d)
    if not fontString or not fontString.SetFont then return false end
    d=d or {}
    local source=d.font=="chat" and _G.ChatFontNormal or _G.GameFontHighlightSmall
    local path,size,flags
    if source and source.GetFont then path,size,flags=source:GetFont() end
    if not path and fontString.GetFont then path,size,flags=fontString:GetFont() end
    path=path or _G.STANDARD_TEXT_FONT
    if not path then return false end
    local custom=PublicNumber(d.fontSize)
    if custom and custom~=0 then size=math.max(10,math.min(18,custom)) end
    return fontString:SetFont(path,size or 12,flags or "")
end
function A.ApplyFill(bar,d,state)
    d=d or {};state=baseColors[state] and state or "cast"
    local texture=bar:GetStatusBarTexture()
    local cached=applied[bar]
    if not cached or cached.texture~=texture then cached={texture=texture};applied[bar]=cached end
    -- Classic client gradient avoids the diagonal white pattern in modern fill art.
    -- Mutate the existing texture so the rounded mask stays attached.
    local asset=d.texture=="smooth" and "Interface\\Buttons\\WHITE8X8" or "Interface\\TargetingFrame\\UI-StatusBar"
    if cached.asset~=asset then
        texture:SetTexture(asset);texture:SetTexCoord(0,1,0,1)
        if texture.SetDesaturated then texture:SetDesaturated(false) end
        cached.asset=asset
    end
    local preset=state=="channel" and d.channelColor or d.castColor
    local tint=state=="interrupted" and baseColors.interrupted or colors[preset] or baseColors[state]
    local r,g,b=tint[1],tint[2],tint[3]
    bar:SetStatusBarColor(r,g,b)
    return r,g,b
end
-- Never turn opaque duration values into invented numerical timers.
function A.FormatDuration(elapsed,total,ru,d)
    elapsed,total=PublicNumber(elapsed),PublicNumber(total)
    if not elapsed or not total or total<0 then return "" end
    elapsed=math.max(0,math.min(total,elapsed))
    local format=d and d.timeFormat or "elapsed_total"
    if format=="hidden" then return "" end
    local text
    if format=="remaining" then text=string.format("%.1f",math.max(0,total-elapsed))
    elseif format=="elapsed" then text=string.format("%.1f",elapsed)
    else text=string.format("%.1f / %.1f",elapsed,total) end
    if ru then text=text:gsub("%.",",") end
    return text
end
function A.TimerText(startTime,endTime,now,ru,d)
    startTime,endTime,now=PublicNumber(startTime),PublicNumber(endTime),PublicNumber(now)
    if not startTime or not endTime or not now or endTime<startTime then return "" end
    return A.FormatDuration(now-startTime,endTime-startTime,ru,d)
end

-- Reserve the timer first: large fonts/narrow bars sacrifice the spell name.
-- This is conservative layout budgeting, not a claim about arbitrary-length timers.
function A.TextWidths(d)
    d=d or {}
    local width=math.max(0,PublicNumber(d.width) or 280)
    if d.timeFormat=="hidden" then return 0,width end
    local size=PublicNumber(d.fontSize)
    if not size or size==0 then
        local source=d.font=="chat" and _G.ChatFontNormal or _G.GameFontHighlightSmall
        if source and source.GetFont then local _,nativeSize=source:GetFont();size=PublicNumber(nativeSize) end
        size=size or 12
    else size=math.max(10,math.min(18,size)) end
    local single=d.timeFormat=="remaining" or d.timeFormat=="elapsed"
    local timer=math.min(width,math.ceil(size*(single and 4.5 or 7.5)+8))
    local name=math.max(0,width-timer-8)
    return timer,name
end
