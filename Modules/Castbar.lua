local ADDON, ns = ...
local L = ns.CastbarLogic
local M = {}
ns.Castbar = M
local ru = GetLocale() == "ruRU"
ns.ru = ru
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local defaults = { width = 280, height = 18, scale = 1, x = 0, y = -170, latency = true, icon = true, reducedMotion = false, enabled = true }
local cast, outcome, preview, installed, driver, ui
local nativeOwned = false
local warnedQuartz = false
M.version = "0.1.0"
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
local function CreateUI()
    local f = CreateFrame("Frame", "AndivalUICastbarFrame", UIParent)
    f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:SetMovable(true)
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetMinMaxValues(0, 1)
    local backing = Texture(bar, "BACKGROUND", {0.025, 0.022, 0.016, 0.92}); backing:SetAllPoints()
    local borders = {}
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local b = Texture(bar, "BORDER", {0.52, 0.39, 0.20, 0.9})
        if edge == "TOP" or edge == "BOTTOM" then b:SetHeight(1); b:SetPoint(edge .. "LEFT"); b:SetPoint(edge .. "RIGHT")
        else b:SetWidth(1); b:SetPoint("TOP" .. edge); b:SetPoint("BOTTOM" .. edge) end
        borders[#borders + 1] = b
    end
    local name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 7); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    local timer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timer:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 7); timer:SetJustifyH("RIGHT"); timer:SetWidth(56)
    timer:SetTextColor(0.94, 0.87, 0.71)
    local icon = f:CreateTexture(nil, "ARTWORK"); icon:SetPoint("RIGHT", bar, "LEFT", -9, 7); icon:SetTexCoord(.08,.92,.08,.92)
    local iconBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1); iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }); iconBorder:SetBackdropBorderColor(.55,.42,.24,.9)
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetAtlas("ui-castingbar-pip"); spark:SetSize(12, 30)
    local latency = Texture(bar, "OVERLAY", {.8,.22,.16,.27}); latency:SetPoint("TOPRIGHT"); latency:SetPoint("BOTTOMRIGHT")
    local previewLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    previewLabel:SetPoint("TOP", bar, "BOTTOM", 0, -7)
    previewLabel:SetText(ru and "ПРЕДПРОСМОТР · перетащи полосу" or "PREVIEW · drag to position")
    f.bar, f.name, f.timer, f.icon, f.iconBorder, f.spark, f.latency, f.previewLabel = bar, name, timer, icon, iconBorder, spark, latency, previewLabel
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
    ui.bar:SetHeight(d.height); ui.name:SetWidth(d.width - 65)
    ui.icon:SetSize(d.height + 17, d.height + 17)
    ui.icon:SetShown(d.icon); ui.iconBorder:SetShown(d.icon)
end
local function Paint(c, now)
    local progress, remaining = L.Progress(c.startTime, c.endTime, now, c.channel)
    ui.bar:SetStatusBarTexture(c.channel and "ui-castingbar-filling-channel" or "ui-castingbar-filling-standard")
    ui.bar:SetStatusBarColor(1,1,1); ui.bar:SetValue(progress)
    ui.name:SetText(c.name); ui.icon:SetTexture(c.icon); ui.timer:SetFormattedText("%.1f", remaining)
    ui.spark:ClearAllPoints(); ui.spark:SetPoint("CENTER", ui.bar, "LEFT", AndivalUIDB.castbar.width * progress, 0)
    ui.spark:SetShown(not AndivalUIDB.castbar.reducedMotion)
    local ratio = L.Clamp((c.latency or 0)/(c.endTime-c.startTime),0,.3)
    ui.latency:SetWidth(math.max(1,AndivalUIDB.castbar.width*ratio))
    ui.latency:SetShown(AndivalUIDB.castbar.latency and not c.channel and ratio > 0)
end
local function Refresh()
    if not installed then return end
    if not AndivalUIDB.castbar.enabled or QuartzActive() then
        if not preview then ui:Hide(); Native(false); return end
    end
    local now = GetTime()
    if preview then
        local elapsed = (now-preview) % 7
        local demo = {name = elapsed < 3.5 and (ru and "Свет небес" or "Holy Light") or (ru and "Направляемое заклинание" or "Channeled spell"),
            icon = 135920, startTime = now - elapsed % 3.5, endTime = now - elapsed % 3.5 + 3.5, channel = elapsed >= 3.5, latency = .12}
        Paint(demo,now); ui:SetAlpha(1); ui:Show(); return
    end
    if cast and now > cast.endTime + .3 then cast = nil end
    local yield = L.ShouldYield(ESIVisible(), cast)
    if cast then
        cast.yielded = yield; cast.esiClaimed = cast.esiClaimed or yield
        if yield then ui:Hide(); Native(false); return end
        outcome = nil; Paint(cast,now); ui:SetAlpha(1); ui:Show(); Native(true)
    elseif outcome and now < outcome.untilTime then
        local t = (outcome.untilTime-now)/outcome.duration
        ui:SetAlpha(AndivalUIDB.castbar.reducedMotion and 1 or math.min(1,t*1.6)); ui:Show(); Native(true)
    else
        outcome = nil; ui:Hide(); Native(false)
    end
end
local function EndCast(event, guid)
    if not cast or not L.AcceptEnd(cast.guid,Safe(guid)) then return end
    if cast.channel and event == "UNIT_SPELLCAST_SUCCEEDED" then return end
    local previous = cast
    cast = nil
    if previous.esiClaimed or ESIVisible() then outcome = nil; Refresh(); return end
    local failure = event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED"
    local success = event == "UNIT_SPELLCAST_SUCCEEDED" or (previous.channel and GetTime() >= previous.endTime - .1)
    if failure or success then
        ui.bar:SetStatusBarTexture(failure and "ui-castingbar-interrupted" or "ui-castingbar-full-standard")
        if success then ui.bar:SetValue(1) end
        ui.timer:SetText(failure and (ru and "Прервано" or "Interrupted") or "")
        ui.spark:Hide(); ui.latency:Hide()
        local duration = failure and .65 or .25
        outcome = {untilTime=GetTime()+duration,duration=duration}
    end
    Refresh()
end
function M.Preview(on)
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
    if event == "PLAYER_REGEN_DISABLED" then M.Preview(false); return end
    if event == "PLAYER_ENTERING_WORLD" then
        cast=ReadCast(); outcome=nil
        if QuartzActive() and not warnedQuartz then
            Say(ru and "Полоса Quartz Player активна. Andival UI ждёт её отключения; /acast для предпросмотра." or "Quartz Player is active. Disable that module to use Andival UI; /acast opens preview.")
            warnedQuartz=true
        end
    elseif Safe(unit)=="player" then
        if event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" or event=="UNIT_SPELLCAST_DELAYED" or event=="UNIT_SPELLCAST_CHANNEL_UPDATE" then cast=ReadCast(); outcome=nil
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
