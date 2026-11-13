local ADDON, ns = ...
local L = ns.CastbarLogic
local D = ns.CastbarDuration
local A = ns.CastbarAppearance
local M = {}
ns.Castbar = M
local ru = GetLocale() == "ruRU"
ns.ru = ru
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local defaults = { width = 280, height = 16, scale = 1, x = 0, y = -170, latency = true, icon = false, reducedMotion = false, enabled = true, target = true, targettarget = true }
local cast, outcome, preview, installed, driver, ui
local nativeOwners = {}
local warnedQuartz = false
M.version = "0.9.2"
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
    if hidden then
        for _,name in ipairs({"PlayerCastingBarFrame","GamepadPlayerCastingBarFrame"}) do
            local f=_G[name]
            if f then
                if not nativeOwners[f] then nativeOwners[f]={alpha=Safe(f:GetAlpha()) or 1} end
                if Safe(f:GetAlpha())~=0 then f:SetAlpha(0) end
            end
        end
    else
        for f,owner in pairs(nativeOwners) do
            local alpha=Safe(f:GetAlpha())
            if ESIVisible() then
                -- Preserve our original alpha while ESI temporarily owns visibility.
            elseif alpha and alpha~=0 then
                nativeOwners[f]=nil -- another owner controls it now
            elseif Safe(f.casting) or Safe(f.channeling) or Safe(f:IsShown())==false then
                f:SetAlpha(owner.alpha);nativeOwners[f]=nil
            end
            -- A finished native bar still fading must not be resurrected. Keep
            -- checking until it hides or starts its next genuine cast.
        end
    end
end
local function ReadCast()
    local name, text, icon, startMS, endMS, trade, guid, uninterruptible, spellID = UnitCastingInfo("player")
    local channel = false
    if not (issecretvalue and issecretvalue(name)) and not name then
        name, text, icon, startMS, endMS, trade, uninterruptible, spellID = UnitChannelInfo("player")
        channel, guid = true, nil
    end
    local publicName=Safe(name)
    startMS, endMS, guid = Safe(startMS), Safe(endMS), Safe(guid)
    if not publicName and not (issecretvalue and issecretvalue(name)) then return nil end
    if type(startMS)~="number" or type(endMS)~="number" or endMS<=startMS then
        local duration=D and D.Read("player",channel)
        if not duration or not ui or not D.Supported(ui.bar) then return nil end
        return {name=name,icon=icon,guid=guid,channel=channel,duration=duration,spellID=Safe(spellID),trade=Safe(trade)}
    end
    local _, _, home, world = GetNetStats()
    return { name = name, icon = icon, startTime = startMS / 1000, endTime = endMS / 1000,
        guid = guid, channel = channel, spellID=Safe(spellID),trade=Safe(trade), latency = math.max(Safe(home) or 0, Safe(world) or 0) / 1000 }
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
    local delay=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    delay:SetPoint("TOPRIGHT",bar,"BOTTOMRIGHT",0,-3);delay:SetTextColor(1,.62,.32)
    f.delay=delay
    local crafting=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    crafting:SetPoint("TOPLEFT",bar,"BOTTOMLEFT",0,-3);crafting:SetTextColor(.94,.87,.71)
    f.crafting=crafting
    local icon = f:CreateTexture(nil, "ARTWORK"); icon:SetPoint("RIGHT", bar, "LEFT", -7, 3); icon:SetTexCoord(.08,.92,.08,.92)
    local iconFrame = ns.CreateIconFrame(f,icon,22)
    f.iconFrame=iconFrame
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetAtlas("ui-castingbar-pip"); spark:SetSize(8, 22)
    local latency = Texture(bar, "OVERLAY", {.8,.22,.16,.27}); latency:SetPoint("TOPRIGHT"); latency:SetPoint("BOTTOMRIGHT")
    latency:AddMaskTexture(fillMask)
    -- Soft moving illumination is clipped to both the rounded outline and current fill.
    local flow = bar:CreateTexture(nil, "OVERLAY")
    flow:SetTexture("Interface\\AddOns\\"..ADDON.."\\Media\\SoftGlow.tga");flow:SetBlendMode("ADD")
    local progressMask = bar:CreateMaskTexture(nil, "ARTWORK")
    progressMask:SetTexture("Interface\\Buttons\\WHITE8X8")
    progressMask:SetAllPoints(bar:GetStatusBarTexture())
    flow:AddMaskTexture(fillMask); flow:AddMaskTexture(progressMask)
    local previewLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    previewLabel:SetPoint("TOP", bar, "BOTTOM", 0, -7)
    previewLabel:SetText(ru and "ПРЕДПРОСМОТР - перетащи полосу" or "PREVIEW - drag to position")
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
    if A then for _,font in ipairs({ui.name,ui.timer,ui.delay,ui.crafting}) do A.ApplyFont(font,d) end end
    ui:SetScale(d.scale); ui:SetSize(d.width, d.height + 25)
    ui:ClearAllPoints(); ui:SetPoint("CENTER", UIParent, "CENTER", d.x/d.scale, d.y/d.scale)
    local timerWidth,nameWidth=A.TextWidths(d)
    ui.bar:SetHeight(d.height);ui.timer:SetWidth(math.max(1,timerWidth));ui.name:SetWidth(math.max(1,nameWidth));ui.name:SetShown(nameWidth>0)
    ui.spark:SetHeight(d.height+6)
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
    local crafting=ns.CastbarCrafting and ns.CastbarCrafting.Label(c.spellID,c.guid,c.trade)
    ui.crafting:SetText(crafting or "")
    if c.duration then
        if not D.Apply(ui.bar,c.duration,c.channel) then return false end
        if not A then SetFillAtlas(c.channel and "ui-castingbar-filling-channel" or "ui-castingbar-filling-standard") end
        if A then A.ApplyFill(ui.bar,AndivalUIDB.castbar,c.channel and "channel" or "cast") else ui.bar:SetStatusBarColor(1,1,1) end
        ui.name:SetText(c.name);ui.displayName=nil
        ui.icon:SetTexture(c.icon);ui.displayIcon=nil
        ui.timer:SetText(D.TimerText(c.duration,ru,AndivalUIDB.castbar));ui.displayTimer=nil
        ui.delay:SetText("");ui.spark:Hide();ui.flow:Hide();ui.latency:Hide()
        return true
    end
    if D then D.Clear(ui.bar) end
    local progress = L.DisplayProgress(c,now,AndivalUIDB.castbar.reducedMotion)
    if not A then SetFillAtlas(c.channel and "ui-castingbar-filling-channel" or "ui-castingbar-filling-standard") end
    if A then A.ApplyFill(ui.bar,AndivalUIDB.castbar,c.channel and "channel" or "cast") else ui.bar:SetStatusBarColor(1,1,1) end
    ui.bar:SetValue(progress)
    local delay,alpha=L.DelayLabel(c,now,ru);ui.delay:SetText(delay);ui.delay:SetAlpha(alpha)
    local publicName=Safe(c.name)
    if not publicName or ui.displayName~=publicName then ui.name:SetText(c.name);ui.displayName=publicName end
    local icon=Safe(c.icon)
    if not icon or ui.displayIcon~=icon then ui.icon:SetTexture(c.icon);ui.displayIcon=icon end
    local timer=A and A.TimerText(c.startTime,c.endTime,now,ru,AndivalUIDB.castbar) or L.TimerText(c.startTime,c.endTime,now,ru)
    if ui.displayTimer~=timer then ui.timer:SetText(timer);ui.displayTimer=timer end
    local moving = not AndivalUIDB.castbar.reducedMotion
    ui.flow:SetShown(moving)
    if moving then
        local phase = ((now-c.startTime)*.45) % 1
        ui.flow:SetSize(74,AndivalUIDB.castbar.height*2)
        ui.flow:ClearAllPoints(); ui.flow:SetPoint("CENTER",ui.bar,"LEFT",AndivalUIDB.castbar.width*progress*phase,0)
        ui.flow:SetAlpha((.12 + .035*math.sin((now-c.startTime)*3))*math.sin(math.pi*phase)^2)
    end
    ui.spark:ClearAllPoints(); ui.spark:SetPoint("CENTER", ui.bar, "LEFT", AndivalUIDB.castbar.width * progress, 0)
    ui.spark:SetShown(not AndivalUIDB.castbar.reducedMotion)
    local ratio = L.Clamp((c.latency or 0)/(c.endTime-c.startTime),0,.3)
    ui.latency:SetWidth(math.max(1,AndivalUIDB.castbar.width*ratio))
    ui.latency:SetShown(AndivalUIDB.castbar.latency and not c.channel and ratio > 0)
    return true
end
local function PaintOutcome(success, remaining, channel)
    local reduced = AndivalUIDB.castbar.reducedMotion
    local r,g,b=1,1,1
    local state=success==nil and (channel and "channel" or "cast") or (success and "success" or "interrupted")
    if A then r,g,b=A.ApplyFill(ui.bar,AndivalUIDB.castbar,state)
    else SetFillAtlas(state=="cast" and "ui-castingbar-filling-standard" or state=="channel" and "ui-castingbar-filling-channel" or success and "ui-castingbar-full-standard" or "ui-castingbar-interrupted") end
    ui.spark:Hide(); ui.latency:Hide(); ui.flow:Hide();ui.delay:SetText("");ui.crafting:SetText("")
    ui.timer:SetText(success~=false and "" or (ru and "Прервано" or "Interrupted"));ui.displayTimer=nil
    if success then ui.bar:SetValue(1) end
    local t = L.Clamp(remaining,0,1)
    ui.finishGlow:SetShown(success and not reduced)
    if success then
        ui.bar:SetStatusBarColor(r,g,b)
        ui.finishGlow:ClearAllPoints(); ui.finishGlow:SetPoint("CENTER",ui.bar,"CENTER",0,0)
        ui.finishGlow:SetSize(AndivalUIDB.castbar.width,AndivalUIDB.castbar.height)
        ui.finishGlow:SetAlpha(.23*math.sin(math.pi*(1-t)))
    else
        -- Smoothstep keeps the initial loss of opacity gentle, without a second
        -- rapid luminosity drop multiplying it into an abrupt disappearance.
        local light = reduced and 1 or (.9+.1*t*t*(3-2*t))
        ui.bar:SetStatusBarColor(r*light,g*light,b*light)
    end
    ui:SetAlpha(reduced and 1 or (success and math.min(1,t*1.65) or t*t*(3-2*t)))
end
local function BeginOutcome(previous, success, now)
    if previous.esiClaimed or ESIVisible() then outcome=nil;return end
    -- Keep the native range as well as its value: native timer bars are not
    -- necessarily normalized. If the UI sinks reject freezing, hide instead
    -- of displaying a guessed or accidentally full progress bar.
    if previous.duration and (not D or not D.Freeze(ui.bar)) then outcome=nil;return end
    local duration=success and .5 or .8
    outcome={untilTime=now+duration,duration=duration,success=success,channel=previous.channel}
end
local function Refresh(deferClaim)
    if not installed then return end
    if not AndivalUIDB.castbar.enabled or QuartzActive() then
        if not preview then
            local now=GetTime()
            if cast and (cast.duration or now>cast.endTime+.3) then cast=nil end
            if outcome and now>=outcome.untilTime then outcome=nil end
            ui:Hide(); Native(false); return
        end
    end
    local now = GetTime()
    if preview then
        Native(false)
        local c,result=L.PreviewCast(M.previewMode or "sequence",now,preview,"player",ru)
        if not c then ui:Hide();return end
        Paint(c,now);ui:SetAlpha(1)
        if result then if not result.success then ui.bar:SetValue(2/3) end;PaintOutcome(result.success,result.remaining) end
        ui:Show();return
    end
    if cast and cast.duration and not cast.stopAt and (not cast.lastCheck or now-cast.lastCheck>=.1) then
        cast.lastCheck=now
        local liveName
        if cast.channel then liveName=UnitChannelInfo("player") else liveName=UnitCastingInfo("player") end
        if not (issecretvalue and issecretvalue(liveName)) and not liveName then cast.stopAt=now+.08;cast.stopRequestedAt=now end
    end
    if cast and cast.stopAt and now>cast.stopAt then
        local previous=cast;cast=nil
        local success
        if previous.channel and not previous.duration and previous.stopRequestedAt>=previous.endTime-.1 then success=true end
        BeginOutcome(previous,success,now)
    elseif cast and not cast.duration and now>cast.endTime+.3 then
        local previous=cast;cast=nil;BeginOutcome(previous,nil,now)
    end
    local yield = L.ShouldYield(ESIVisible(), cast)
    if cast then
        cast.yielded = yield
        if not deferClaim then cast.esiClaimed = cast.esiClaimed or yield end
        if yield then ui:Hide(); Native(false); return end
        outcome = nil
        if Paint(cast,cast.stopRequestedAt or now)==false then
            cast=nil;ui:Hide();Native(false);return
        end
        ui:SetAlpha(1); ui:Show(); Native(true)
    elseif outcome and now < outcome.untilTime then
        local t = (outcome.untilTime-now)/outcome.duration
        PaintOutcome(outcome.success,t,outcome.channel); ui:Show(); Native(true)
    else
        outcome = nil; ui:Hide(); Native(false)
    end
end
local function EndCast(event, guid)
    if not cast then return end
    local eventGUID=Safe(guid)
    if not cast.guid or not eventGUID then
        -- An unidentified terminal event must not kill a still-live spell.
        if ReadCast() then return end
    elseif not L.AcceptEnd(cast.guid,eventGUID) then return end
    if cast.channel and event == "UNIT_SPELLCAST_SUCCEEDED" then return end
    if (event=="UNIT_SPELLCAST_STOP" and not cast.channel) or (event=="UNIT_SPELLCAST_CHANNEL_STOP" and cast.channel) then
        cast.stopAt=GetTime()+.08 -- reconcile a following explicit result before choosing an outcome
        cast.stopRequestedAt=GetTime()
        return
    end
    local previous = cast
    cast = nil
    if previous.esiClaimed or ESIVisible() then outcome = nil; Refresh(); return end
    local failure = event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET"
    local success = not failure and (event == "UNIT_SPELLCAST_SUCCEEDED" or (previous.channel and not previous.duration and GetTime() >= previous.endTime - .1))
    -- Restricted snapshots receive no inferred completion. Explicit failure is
    -- still meaningful, but never turn opaque timing into a full success fill.
    if previous.duration and not failure then success=nil end
    if failure then BeginOutcome(previous,false,GetTime())
    elseif success then BeginOutcome(previous,true,GetTime())
    else BeginOutcome(previous,nil,GetTime()) end
    Refresh()
end
function M.Preview(on)
    if ns.UnitCastbars then ns.UnitCastbars.Preview(on) end
    Native(false)
    preview = on and GetTime() or nil
    if ui then if not on then ui:StopMovingOrSizing() end;ui:EnableMouse(on); ui.previewLabel:SetShown(on) end
    outcome = nil; cast = ReadCast(); Refresh()
end
function M.SetPreviewMode(mode)
    M.previewMode=mode
    if preview then M.Preview(true) end
end
function M.Reset()
    for k,v in pairs(defaults) do AndivalUIDB.castbar[k] = v end
    M.Layout(); Refresh()
end
function M.Status()
    Say("ESI: " .. (_G.EnhancedSoftInteractHUD and (ru and "обнаружен" or "detected") or (ru and "не загружен" or "not loaded")) .. "; Quartz Player: " .. (QuartzActive() and (ru and "включён" or "enabled") or (ru and "выключен" or "disabled")))
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
        AndivalUIDB.castbar.width=L.Clamp(AndivalUIDB.castbar.width,140,500); AndivalUIDB.castbar.height=L.Clamp(AndivalUIDB.castbar.height,10,32); AndivalUIDB.castbar.scale=L.Clamp(AndivalUIDB.castbar.scale,.6,1.6)
        ns.InitCastbarSettings(); ui=CreateUI(); installed=true; M.Layout()
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
                    if not previous.duration and not cast.duration then L.Retime(previous,cast,GetTime()) end
                end
            end
            Refresh(true); return
        else EndCast(event,guid) end
    end
    Refresh()
end)
-- A short visibility check also handles ESI settings, HUD fades and late object association.
driver:SetScript("OnUpdate",function()
    if cast or outcome or preview or next(nativeOwners) then Refresh() end
end)
M.Test = { ReadCast=ReadCast, EndCast=EndCast, ESIVisible=ESIVisible, QuartzActive=QuartzActive }

M.name = 'Castbar'
ns.RegisterModule('Castbar', M)
