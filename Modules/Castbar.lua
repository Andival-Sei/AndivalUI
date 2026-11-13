local ADDON, ns = ...
local L = ns.CastbarLogic
local M = {}
ns.Castbar = M
local ru = GetLocale() == "ruRU"
ns.ru = ru
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local defaults = { width = 280, height = 16, scale = 1, x = 0, y = -170, latency = true, icon = false, reducedMotion = false, enabled = true, target = true, targettarget = true }
local cast, outcome, preview, installed, driver, ui
local nativeOwned = false
local warnedQuartz = false
M.version = "0.5.3"
local function Say(s) print("|cffe1bd78Andival UI:|r " .. s) end
M.Say = Say
local function ESIVisible() return ns.Integrations.ESI.IsVisible() end
local function QuartzActive()
    if not LibStub then return false end
    local ace = LibStub("AceAddon-3.0", true)
    local q = ace and ace:GetAddon("Quartz3", true)
    local p = q and q:GetModule("Player", true)
    return p and p:IsEnabled() or false
end
-- We change alpha only, never unregister native events or overwrite scripts.
local function Native(hidden)
    local f = _G.PlayerCastingBarFrame
    if not f then return end
    if hidden then
        nativeOwned = true
        if Safe(f:GetAlpha()) ~= 0 then f:SetAlpha(0) end
    elseif nativeOwned then
        nativeOwned = false
        -- Finished native bars can freeze if restored after their fade. Only restore a live cast.
        if not ESIVisible() and (Safe(f.casting) or Safe(f.channeling)) then f:SetAlpha(1) end
    end
end
local function ReadCast()
    local name, text, icon, startMS, endMS, trade, guid, uninterruptible, spellID = UnitCastingInfo("player")
    local channel = false
    if not Safe(name) then
        name, text, icon, startMS, endMS, trade, uninterruptible, spellID = UnitChannelInfo("player")
        channel, guid = true, nil
    end
    name, startMS, endMS, guid = Safe(name), Safe(startMS), Safe(endMS), Safe(guid)
    -- Restricted data is left to Blizzard, not guessed or compared.
    if not name or type(startMS) ~= "number" or type(endMS) ~= "number" or endMS <= startMS then return nil end
    local _, _, home, world = GetNetStats()
    return { name = name, icon = icon, startTime = startMS / 1000, endTime = endMS / 1000,
        guid = guid, channel = channel, latency = math.max(Safe(home) or 0, Safe(world) or 0) / 1000 }
end
local function Texture(parent, layer, color)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(unpack(color))
    return t
end
local function RoundedMask(parent, target, anchor)
    local mask = parent:CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundedMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(anchor or target)
    target:AddMaskTexture(mask)
    return mask
end
local function CreateUI()
    local f = CreateFrame("Frame", "AndivalUICastbarFrame", UIParent)
    f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:SetMovable(true)
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetMinMaxValues(0, 1)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    -- Blizzard's native castbar artwork, not a hand-drawn rectangular border.
    local backing = bar:CreateTexture(nil, "BACKGROUND")
    backing:SetAtlas("ui-castingbar-background", false)
    backing:SetPoint("TOPLEFT", bar, "TOPLEFT", -3, 3)
    backing:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 3, -3)
    local outerMask = RoundedMask(bar, backing)
    local fillMask = RoundedMask(bar, bar:GetStatusBarTexture(), bar)
    local finishGlow = bar:CreateTexture(nil, "OVERLAY")
    finishGlow:SetAtlas("cast_standard_pipglow", false)
    finishGlow:SetPoint("CENTER", bar, "CENTER", 0, 0); finishGlow:AddMaskTexture(fillMask); finishGlow:SetBlendMode("ADD"); finishGlow:Hide()
    local name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 4); name:SetJustifyH("LEFT"); name:SetWordWrap(false); name:SetShadowColor(0,0,0,1); name:SetShadowOffset(1,-1)
    local timer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timer:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 4); timer:SetJustifyH("RIGHT"); timer:SetWidth(80); timer:SetWordWrap(false); timer:SetShadowColor(0,0,0,1); timer:SetShadowOffset(1,-1)
    timer:SetTextColor(0.94, 0.87, 0.71)
    local icon = f:CreateTexture(nil, "ARTWORK"); icon:SetPoint("RIGHT", bar, "LEFT", -7, 3); icon:SetTexCoord(.08,.92,.08,.92)
    local iconFrame = ns.CreateIconFrame(f,icon,22)
    f.iconFrame=iconFrame
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetAtlas("ui-castingbar-pip"); spark:SetSize(8, 22)
    local latency = Texture(bar, "OVERLAY", {.8,.22,.16,.27}); latency:SetPoint("TOPRIGHT"); latency:SetPoint("BOTTOMRIGHT")
    latency:AddMaskTexture(fillMask)
    -- Soft moving illumination is clipped to both the rounded outline and current fill.
    local flow = bar:CreateTexture(nil, "OVERLAY")
    flow:SetAtlas("cast_standard_pipglow", false); flow:SetBlendMode("ADD")
    local progressMask = bar:CreateMaskTexture(nil, "ARTWORK")
    progressMask:SetTexture("Interface\\Buttons\\WHITE8X8")
    progressMask:SetAllPoints(bar:GetStatusBarTexture())
    flow:AddMaskTexture(fillMask); flow:AddMaskTexture(progressMask)
    local previewLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    previewLabel:SetPoint("TOP", bar, "BOTTOM", 0, -7)
    previewLabel:SetText(ru and "ПРЕДПРОСМОТР · перетащи полосу" or "PREVIEW · drag to position")
    f.flow, f.progressMask = flow, progressMask
    f.fillMask, f.outerMask = fillMask, outerMask
    f.bar, f.name, f.timer, f.icon, f.finishGlow, f.spark, f.latency, f.previewLabel = bar, name, timer, icon, finishGlow, spark, latency, previewLabel
    f:SetScript("OnMouseDown", function(self, button) if preview and button == "LeftButton" and not InCombatLockdown() then self:StartMoving() end end)
    f:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        if preview then
            local x,y = self:GetCenter(); local cx,cy = UIParent:GetCenter()
            local s = self:GetScale()
            AndivalUIDB.castbar.x, AndivalUIDB.castbar.y = x*s-cx, y*s-cy
        end
    end)
    f:Hide()
    return f
end
function M.Layout()
    if not ui then return end
    local d = AndivalUIDB.castbar
    ui:SetScale(d.scale); ui:SetSize(d.width, d.height + 25)
    ui:ClearAllPoints(); ui:SetPoint("CENTER", UIParent, "CENTER", d.x/d.scale, d.y/d.scale)
    ui.bar:SetHeight(d.height); ui.name:SetWidth(d.width - 90)
    ui.icon:SetSize(22, 22)
    ui.finishGlow:SetSize(36, 36)
    ui.icon:SetShown(d.icon); ui.iconFrame:SetShown(d.icon)
    if ns.UnitCastbars then ns.UnitCastbars.Layout() end
end
local function SetFillAtlas(atlas)
    local texture = ui.bar:GetStatusBarTexture()
    if texture:GetAtlas() ~= atlas then texture:SetAtlas(atlas, false) end
end
local function Paint(c, now)
    ui.finishGlow:Hide()
    local progress, remaining = L.Progress(c.startTime, c.endTime, now, c.channel)
    SetFillAtlas(c.channel and "ui-castingbar-filling-channel" or "ui-castingbar-filling-standard")
    ui.bar:SetStatusBarColor(1,1,1); ui.bar:SetValue(progress)
    ui.name:SetText(c.name); ui.icon:SetTexture(c.icon); ui.timer:SetText(L.TimerText(c.startTime,c.endTime,now,ru))
    local moving = not AndivalUIDB.castbar.reducedMotion
    ui.flow:SetShown(moving)
    if moving then
        local phase = ((now-c.startTime)*.45) % 1
        ui.flow:SetSize(58,AndivalUIDB.castbar.height*2.5)
        ui.flow:ClearAllPoints(); ui.flow:SetPoint("CENTER",ui.bar,"LEFT",AndivalUIDB.castbar.width*progress*phase,0)
        ui.flow:SetAlpha(.12 + .035*math.sin((now-c.startTime)*3))
    end
    ui.spark:ClearAllPoints(); ui.spark:SetPoint("CENTER", ui.bar, "LEFT", AndivalUIDB.castbar.width * progress, 0)
    ui.spark:SetShown(not AndivalUIDB.castbar.reducedMotion)
    local ratio = L.Clamp((c.latency or 0)/(c.endTime-c.startTime),0,.3)
    ui.latency:SetWidth(math.max(1,AndivalUIDB.castbar.width*ratio))
    ui.latency:SetShown(AndivalUIDB.castbar.latency and not c.channel and ratio > 0)
end
local function PaintOutcome(success, remaining)
    local reduced = AndivalUIDB.castbar.reducedMotion
    SetFillAtlas(success and "ui-castingbar-full-standard" or "ui-castingbar-interrupted")
    ui.spark:Hide(); ui.latency:Hide(); ui.flow:Hide()
    ui.timer:SetText(success and "" or (ru and "Прервано" or "Interrupted"))
    if success then ui.bar:SetValue(1) end
    local t = L.Clamp(remaining,0,1)
    ui.finishGlow:SetShown(success and not reduced)
    if success then
        ui.bar:SetStatusBarColor(1,1,1)
        ui.finishGlow:ClearAllPoints(); ui.finishGlow:SetPoint("CENTER",ui.bar,"CENTER",0,0)
        ui.finishGlow:SetSize(AndivalUIDB.castbar.width,AndivalUIDB.castbar.height)
        ui.finishGlow:SetAlpha(.23*math.sin(math.pi*(1-t)))
    else
        -- The interrupted energy darkens in place rather than snapping to a full red bar.
        local light = reduced and 1 or (.25+.75*t)
        ui.bar:SetStatusBarColor(light,light,light)
    end
    ui:SetAlpha(reduced and 1 or (success and math.min(1,t*1.65) or t*t))
end
local function Refresh(deferClaim)
    if not installed then return end
    if not AndivalUIDB.castbar.enabled or QuartzActive() then
        if not preview then ui:Hide(); Native(false); return end
    end
    local now = GetTime()
    if preview then
        local elapsed = (now-preview) % 7
        local second = elapsed >= 4
        local age = second and elapsed-4 or elapsed
        local demo = {name = ru and "Свет небес" or "Holy Light", icon=135920,
            startTime=now-age,endTime=now-age+3,channel=false,latency=.12}
        Paint(demo,now)
        if not second and age>=3 then
            if age>=3.5 then ui:Hide(); return end
            PaintOutcome(true,(3.5-age)/.5)
        elseif second and age>=2 then
            if age>=2.55 then ui:Hide(); return end
            -- Freeze the interrupted cast at two thirds while it extinguishes.
            ui.bar:SetValue(2/3); PaintOutcome(false,(2.55-age)/.55)
        else ui:SetAlpha(1) end
        ui:Show(); return
    end
    if cast and (now > cast.endTime + .3 or (cast.stopAt and now > cast.stopAt)) then cast = nil end
    local yield = L.ShouldYield(ESIVisible(), cast)
    if cast then
        cast.yielded = yield
        if not deferClaim then cast.esiClaimed = cast.esiClaimed or yield end
        if yield then ui:Hide(); Native(false); return end
        outcome = nil; Paint(cast,now); ui:SetAlpha(1); ui:Show(); Native(true)
    elseif outcome and now < outcome.untilTime then
        local t = (outcome.untilTime-now)/outcome.duration
        PaintOutcome(outcome.success,t); ui:Show(); Native(true)
    else
        outcome = nil; ui:Hide(); Native(false)
    end
end
local function EndCast(event, guid)
    if not cast or not L.AcceptEnd(cast.guid,Safe(guid)) then return end
    if cast.channel and event == "UNIT_SPELLCAST_SUCCEEDED" then return end
    if event == "UNIT_SPELLCAST_STOP" and not cast.channel then
        cast.stopAt = GetTime() + .08 -- allow result events arriving after STOP
        return
    end
    local previous = cast
    cast = nil
    if previous.esiClaimed or ESIVisible() then outcome = nil; Refresh(); return end
    local failure = event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED"
    local success = event == "UNIT_SPELLCAST_SUCCEEDED" or (previous.channel and GetTime() >= previous.endTime - .1)
    if failure or success then
        local duration = failure and .55 or .5
        outcome = {untilTime=GetTime()+duration,duration=duration,success=success}
    end
    Refresh()
end
function M.Preview(on)
    if ns.UnitCastbars then ns.UnitCastbars.Preview(on) end
    Native(false)
    preview = on and GetTime() or nil
    if ui then ui:EnableMouse(on); ui.previewLabel:SetShown(on) end
    outcome = nil; cast = ReadCast(); Refresh()
end
function M.Reset()
    for k,v in pairs(defaults) do AndivalUIDB.castbar[k] = v end
    M.Layout(); Refresh()
end
function M.Status()
    Say((ru and "ESI: " or "ESI: ") .. (_G.EnhancedSoftInteractHUD and "detected" or "not loaded") .. "; Quartz Player: " .. tostring(QuartzActive()))
end
M.Refresh = Refresh
local events = {"UNIT_SPELLCAST_START","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_FAILED_QUIET","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"}
driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED"); driver:RegisterEvent("PLAYER_ENTERING_WORLD"); driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:SetScript("OnEvent",function(_,event,unit,guid)
    if event == "ADDON_LOADED" then
        if unit ~= ADDON then return end
        AndivalUIDB = type(AndivalUIDB)=="table" and AndivalUIDB or {schema=1}
        AndivalUIDB.castbar = type(AndivalUIDB.castbar)=="table" and AndivalUIDB.castbar or {}
        for k,v in pairs(defaults) do if type(AndivalUIDB.castbar[k])~=type(v) then AndivalUIDB.castbar[k]=v end end
        AndivalUIDB.castbar.width=L.Clamp(AndivalUIDB.castbar.width,180,500); AndivalUIDB.castbar.height=L.Clamp(AndivalUIDB.castbar.height,10,32); AndivalUIDB.castbar.scale=L.Clamp(AndivalUIDB.castbar.scale,.6,1.6)
        ui=CreateUI(); installed=true; M.Layout()
        for _,e in ipairs(events) do driver:RegisterUnitEvent(e,"player") end
        if ns.CreateSettings then ns.CreateSettings() end
        return
    end
    if not installed then return end
    if event == "PLAYER_REGEN_DISABLED" then
        if _G.AndivalUISettings then _G.AndivalUISettings:Hide() end
        M.Preview(false); return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        cast=ReadCast(); outcome=nil
        if QuartzActive() and not warnedQuartz then
            Say(ru and "Полоса Quartz Player активна. Andival UI ждёт её отключения; /acast для предпросмотра." or "Quartz Player is active. Disable that module to use Andival UI; /acast opens preview.")
            warnedQuartz=true
        end
    elseif Safe(unit)=="player" then
        if event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" or event=="UNIT_SPELLCAST_DELAYED" or event=="UNIT_SPELLCAST_CHANNEL_UPDATE" then
            local previous = cast
            cast=ReadCast(); outcome=nil
            if cast then
                cast.guid = cast.guid or Safe(guid)
                if (event=="UNIT_SPELLCAST_DELAYED" or event=="UNIT_SPELLCAST_CHANNEL_UPDATE") and previous and previous.channel==cast.channel and L.AcceptEnd(previous.guid,cast.guid) then
                    cast.esiClaimed = previous.esiClaimed
                end
            end
            Refresh(true); return
        else EndCast(event,guid) end
    end
    Refresh()
end)
-- A short visibility check also handles ESI settings, HUD fades and late object association.
local elapsed=0
driver:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed < .016 then return end
    elapsed=0
    Refresh()
end)
M.Test = { ReadCast=ReadCast, EndCast=EndCast, ESIVisible=ESIVisible, QuartzActive=QuartzActive }

M.name = 'Castbar'
ns.RegisterModule('Castbar', M)
