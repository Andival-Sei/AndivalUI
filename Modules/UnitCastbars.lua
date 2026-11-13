local ADDON, ns = ...
local M = { bars = {} }
ns.UnitCastbars = M
ns.RegisterModule("UnitCastbars", M)
local L, ru = ns.CastbarLogic, GetLocale()=="ruRU"
local ready, preview = false, false
local nativeOwners = {}
local previewStart=0
local units = {"target", "targettarget", "focus"}
local snapshots,lastSnapshot={},-1
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function Label(unit)
    if unit=="focus" then return ru and "Фокус" or "Focus" end
    return unit=="target" and (ru and "Цель" or "Target") or (ru and "Цель цели" or "Target of target")
end
local function Native(unit,hidden)
    local f = unit=="target" and _G.TargetFrameSpellBar or (unit=="focus" and _G.FocusFrameSpellBar)
    if not f then return end
    if hidden then
        if nativeOwners[unit]==nil then nativeOwners[unit]=Safe(f:GetAlpha()) or 1 end
        f:SetAlpha(0)
    elseif nativeOwners[unit]~=nil then
        -- Another addon may have taken ownership since our last draw.
        if Safe(f:GetAlpha())==0 then f:SetAlpha(nativeOwners[unit]) end
        nativeOwners[unit]=nil
    end
end
local function QuartzUnit(unit)
    if unit=="targettarget" then return false end
    local ace = LibStub and LibStub("AceAddon-3.0",true)
    local q = ace and ace:GetAddon("Quartz3",true)
    local m = q and q:GetModule(unit=="focus" and "Focus" or "Target",true)
    return m and m:IsEnabled() or false
end
local function Read(unit)
    if not Safe(UnitExists(unit)) then return nil end
    local name,_,icon,startMS,endMS,_,castGUID,blocked,spellID = UnitCastingInfo(unit)
    local channel=false
    local secretName=issecretvalue and issecretvalue(name)
    if not secretName and not name then
        name,_,icon,startMS,endMS,_,blocked,spellID = UnitChannelInfo(unit)
        castGUID=nil;channel=true
        secretName=issecretvalue and issecretvalue(name)
    end
    if not secretName and type(name)~="string" then return nil end
    startMS,endMS,blocked=Safe(startMS),Safe(endMS),Safe(blocked)
    local c={name=name,secretName=secretName,icon=icon,channel=channel,blocked=blocked,
        interruptKnown=type(blocked)=="boolean",unitGUID=Safe(UnitGUID and UnitGUID(unit)),castGUID=Safe(castGUID),spellID=Safe(spellID)}
    if type(startMS)=="number" and type(endMS)=="number" and endMS>startMS then
        c.startTime=startMS/1000;c.endTime=endMS/1000
    else
        c.duration=ns.CastbarDuration.Read(unit,channel)
        if not c.duration then return nil end
    end
    return c
end
local function Mask(parent,texture,anchor)
    local m=parent:CreateMaskTexture(nil,"ARTWORK")
    m:SetTexture("Interface\\AddOns\\"..ADDON.."\\Media\\RoundedMask.tga","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(anchor or texture); texture:AddMaskTexture(m); return m
end
local function Create(unit)
    local f=CreateFrame("Frame",unit=="target" and "AndivalUITargetCastbar" or (unit=="focus" and "AndivalUIFocusCastbar" or "AndivalUITargetTargetCastbar"),UIParent)
    f:SetFrameStrata("MEDIUM");f:SetMovable(true);f:SetClampedToScreen(true)
    local b=CreateFrame("StatusBar",nil,f);b:SetAllPoints();b:SetMinMaxValues(0,1);b:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAtlas("ui-castingbar-background",false)
    bg:SetPoint("TOPLEFT",b,"TOPLEFT",-3,3);bg:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",3,-3)
    f.fillMask=Mask(b,b:GetStatusBarTexture(),b);f.outerMask=Mask(b,bg)
    local text=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");text:SetPoint("BOTTOMLEFT",b,"TOPLEFT",0,4);text:SetJustifyH("LEFT");text:SetWordWrap(false)
    local timer=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");timer:SetPoint("BOTTOMRIGHT",b,"TOPRIGHT",0,4)
    local delay=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    delay:SetPoint("TOPRIGHT",b,"BOTTOMRIGHT",0,-3);delay:SetTextColor(1,.62,.32);f.delay=delay
    local shield=f:CreateTexture(nil,"ARTWORK",nil,-1)
    shield:SetAtlas("ui-castingbar-shield",false)
    shield:SetSize(29,33)
    shield:Hide()
    local icon=f:CreateTexture(nil,"ARTWORK");icon:SetPoint("RIGHT",b,"LEFT",-7,0);icon:SetSize(20,20);icon:SetTexCoord(.08,.92,.08,.92)
    f.iconFrame=ns.CreateIconFrame(f,icon,20)
    -- Native metal rim with artwork inset along its silhouette, not a square sticker.
    local shieldIcon=f:CreateTexture(nil,"ARTWORK")
    shieldIcon:SetAllPoints(shield);shieldIcon:SetTexCoord(.08,.92,.08,.92);shieldIcon:Hide()
    local shieldMask=f:CreateMaskTexture()
    shieldMask:SetTexture("Interface\\AddOns\\AndivalUI\\Media\\ShieldInsetMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    shieldMask:SetAllPoints(shield);shieldIcon:AddMaskTexture(shieldMask)
    f.shieldIcon,f.shieldMask=shieldIcon,shieldMask
    for _,font in ipairs({text,timer}) do font:SetShadowColor(0,0,0,1);font:SetShadowOffset(1,-1) end
    f.bar,f.text,f.timer,f.shield,f.icon=b,text,timer,shield,icon
    f:SetScript("OnMouseDown",function(self,button) if preview and button=="LeftButton" and not InCombatLockdown() then self:StartMoving() end end)
    f:SetScript("OnMouseUp",function(self)
        self:StopMovingOrSizing()
        if preview then local x,y=self:GetCenter();local cx,cy=UIParent:GetCenter();local scale=self:GetScale();local d=AndivalUIDB.unitcastbars[unit];d.x=x*scale-cx;d.y=y*scale-cy end
    end)
    f:Hide();return f
end
function M.Layout()
    if not ready then return end
    for _,unit in ipairs(units) do
        local d=ns.GetCastbarSettings(unit)
        local f=M.bars[unit];local pos=AndivalUIDB.unitcastbars[unit]
        for _,font in ipairs({f.text,f.timer,f.delay}) do ns.CastbarAppearance.ApplyFont(font,d) end
        f:SetScale(d.scale);f:SetSize(d.width,d.height);f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",pos.x/d.scale,pos.y/d.scale)
        local timerWidth,nameWidth=ns.CastbarAppearance.TextWidths(d)
        f.timer:SetWidth(math.max(1,timerWidth));f.timer:SetWordWrap(false);f.timer:SetJustifyH("RIGHT");f.text:SetWidth(math.max(1,nameWidth));f.text:SetShown(nameWidth>0);f.icon:SetShown(d.icon and not f.protected);f.iconFrame:SetShown(d.icon and not f.protected)
        f.shield:ClearAllPoints();f.shield:SetPoint("CENTER",f.icon,"CENTER",0,-2.5)
    end
end
function M.Refresh(force)
    if not ready then return end
    local now=GetTime()
    local sample=force~=false or now-lastSnapshot>=.05
    if sample then lastSnapshot=now end
    for _,unit in ipairs(units) do
        local f=M.bars[unit];local d=ns.GetCastbarSettings(unit)
        local enabled=d.enabled
        if sample then
            local previous=snapshots[unit]
            local current=enabled and Read(unit) or nil
            if previous and current and not previous.duration and not current.duration and not previous.secretName and not current.secretName and current.unitGUID and previous.unitGUID==current.unitGUID and previous.name==current.name and previous.spellID==current.spellID and ((current.castGUID and previous.castGUID==current.castGUID) or previous.startTime==current.startTime) then L.Retime(previous,current,now) end
            snapshots[unit]=current
        end
        local c=enabled and snapshots[unit] or nil
        local demoResult
        if preview and enabled then
            local mode=ns.Castbar.previewMode or "sequence"
            c,demoResult=L.PreviewCast(mode,now,previewStart,unit,ru)
        end
        if QuartzUnit(unit) and not preview then c=nil end
        if c and c.duration and not ns.CastbarDuration.Supported(f.bar) then c=nil end
        if c and (c.duration or preview or now<=c.endTime) then
            local progress=not c.duration and L.DisplayProgress(c,now,d.reducedMotion)
            local delay,alpha=L.DelayLabel(c,now,ru);f.delay:SetText(delay);f.delay:SetAlpha(alpha)
            f:SetAlpha(1);f.bar:SetStatusBarColor(1,1,1)
            ns.CastbarAppearance.ApplyFill(f.bar,d,c.channel and "channel" or "cast")
            if c.duration then
                f.durationFailed=not ns.CastbarDuration.Apply(f.bar,c.duration,c.channel)
            else
                ns.CastbarDuration.Clear(f.bar);f.durationFailed=false
                f.bar:SetValue(progress)
            end
            if c and c.secretName then f.text:SetText(c.name);f.displayText=nil
            elseif c then
                local text=Label(unit).." · "..c.name
                if f.displayText~=text then f.text:SetText(text);f.displayText=text end
            end
            local timer=c and (c.duration and ns.CastbarDuration.TimerText(c.duration,ru,d) or ns.CastbarAppearance.TimerText(c.startTime,c.endTime,now,ru,d)) or ""
            if f.displayTimer~=timer then f.timer:SetText(timer);f.displayTimer=timer end
            local icon=Safe(c.icon)
            if not icon or f.displayIcon~=icon then f.icon:SetTexture(c.icon);f.shieldIcon:SetTexture(c.icon);f.displayIcon=icon end
            -- No shield is not a promise of interruptibility: unknown stays neutral.
            local protected=c.interruptKnown and c.blocked==true
            f.protected=protected
            f.shield:SetShown(protected)
            f.shieldIcon:SetShown(protected)
            f.icon:SetShown(d.icon and not protected)
            f.iconFrame:SetShown(d.icon and not protected)
            if demoResult then
                ns.CastbarAppearance.ApplyFill(f.bar,d,demoResult.success and "success" or "interrupted")
                if demoResult.success then f.bar:SetValue(1) else f.bar:SetValue(2/3) end
                f.timer:SetText(demoResult.success and "" or (ru and "Прервано" or "Interrupted"));f.displayTimer=nil
                f.delay:SetText("");f:SetAlpha(d.reducedMotion and 1 or demoResult.remaining)
            end
            f:SetShown(not f.durationFailed)
        else f.protected=false;ns.CastbarDuration.Clear(f.bar);f:Hide() end
        Native(unit,f:IsShown() and not preview)
    end
end
function M.Preview(on)
    preview=on and true or false;previewStart=GetTime()
    for _,f in pairs(M.bars) do if not preview then f:StopMovingOrSizing() end;f:EnableMouse(preview) end
    M.Refresh()
end
M.Test={Read=Read}
local driver=CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED");driver:RegisterEvent("PLAYER_TARGET_CHANGED");driver:RegisterEvent("PLAYER_FOCUS_CHANGED");driver:RegisterEvent("UNIT_TARGET")
driver:SetScript("OnEvent",function(_,event,name)
    if event=="UNIT_TARGET" and Safe(name)~="target" then return end
    if event=="ADDON_LOADED" then
        if name~=ADDON then return end
        AndivalUIDB.unitcastbars=AndivalUIDB.unitcastbars or {}
        for i,unit in ipairs(units) do
            local p=AndivalUIDB.unitcastbars[unit]
            if type(p)~="table" then p={} end
            p.x=type(p.x)=="number" and p.x or 0;p.y=type(p.y)=="number" and p.y or (i==1 and -65 or (i==2 and -115 or -240))
            AndivalUIDB.unitcastbars[unit]=p;M.bars[unit]=Create(unit)
        end
        ns.InitCastbarSettings();ready=true;M.Layout()
    end
    if event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_FOCUS_CHANGED" or event=="UNIT_TARGET" then snapshots={} end
    M.Refresh()
end)
-- targettarget often has no dedicated cast events. Re-read unit identity and casts;
-- never carry old target state across a target switch or guess restricted timing.
driver:SetScript("OnUpdate",function() M.Refresh(false) end)
