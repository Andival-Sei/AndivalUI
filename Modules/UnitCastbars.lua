local ADDON, ns = ...
local M = { bars = {} }
ns.UnitCastbars = M
ns.RegisterModule("UnitCastbars", M)
local L, ru = ns.CastbarLogic, GetLocale()=="ruRU"
local ready, preview, owned = false, false, false
local nativeAlpha=1
local units = {"target", "targettarget"}
local snapshots,lastSnapshot={},-1
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function Label(unit) return unit=="target" and (ru and "Цель" or "Target") or (ru and "Цель цели" or "Target of target") end
local function Native(hidden)
    local f = _G.TargetFrameSpellBar
    if not f then return end
    if hidden then
        if not owned then nativeAlpha=Safe(f:GetAlpha()) or 1 end
        owned=true; f:SetAlpha(0)
    elseif owned then
        owned=false
        f:SetAlpha(nativeAlpha)
    end
end
local function QuartzTarget()
    local ace = LibStub and LibStub("AceAddon-3.0",true)
    local q = ace and ace:GetAddon("Quartz3",true)
    local m = q and q:GetModule("Target",true)
    return m and m:IsEnabled() or false
end
local function Read(unit)
    if not Safe(UnitExists(unit)) then return nil end
    local name,_,icon,startMS,endMS,_,_,blocked = UnitCastingInfo(unit)
    local channel=false
    if not Safe(name) then
        name,_,icon,startMS,endMS,_,blocked = UnitChannelInfo(unit)
        channel=true
    end
    name,startMS,endMS,blocked=Safe(name),Safe(startMS),Safe(endMS),Safe(blocked)
    if type(name)~="string" or type(startMS)~="number" or type(endMS)~="number" or endMS<=startMS then return nil end
    return {name=name,icon=icon,startTime=startMS/1000,endTime=endMS/1000,channel=channel,blocked=blocked,
        interruptKnown=type(blocked)=="boolean"}
end
local function Mask(parent,texture,anchor)
    local m=parent:CreateMaskTexture(nil,"ARTWORK")
    m:SetTexture("Interface\\AddOns\\"..ADDON.."\\Media\\RoundedMask.tga","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(anchor or texture); texture:AddMaskTexture(m); return m
end
local function Create(unit)
    local f=CreateFrame("Frame",unit=="target" and "AndivalUITargetCastbar" or "AndivalUITargetTargetCastbar",UIParent)
    f:SetFrameStrata("MEDIUM");f:SetMovable(true);f:SetClampedToScreen(true)
    local b=CreateFrame("StatusBar",nil,f);b:SetAllPoints();b:SetMinMaxValues(0,1);b:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAtlas("ui-castingbar-background",false)
    bg:SetPoint("TOPLEFT",b,"TOPLEFT",-3,3);bg:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",3,-3)
    f.fillMask=Mask(b,b:GetStatusBarTexture(),b);f.outerMask=Mask(b,bg)
    local text=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");text:SetPoint("BOTTOMLEFT",b,"TOPLEFT",0,4);text:SetJustifyH("LEFT");text:SetWordWrap(false)
    local timer=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");timer:SetPoint("BOTTOMRIGHT",b,"TOPRIGHT",0,4)
    local shield=f:CreateTexture(nil,"OVERLAY")
    shield:SetAtlas("ui-castingbar-shield",false)
    shield:SetSize(20,23)
    shield:SetPoint("RIGHT",b,"LEFT",-7,0);shield:Hide()
    local icon=f:CreateTexture(nil,"ARTWORK");icon:SetPoint("RIGHT",b,"LEFT",-7,0);icon:SetSize(20,20);icon:SetTexCoord(.08,.92,.08,.92)
    f.iconFrame=ns.CreateIconFrame(f,icon,20)
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
    local d=AndivalUIDB.castbar
    for _,unit in ipairs(units) do
        local f=M.bars[unit];local pos=AndivalUIDB.unitcastbars[unit]
        f:SetScale(d.scale);f:SetSize(d.width*.85,14);f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",pos.x/d.scale,pos.y/d.scale)
        f.text:SetWidth(d.width*.85-40);f.icon:SetShown(d.icon);f.iconFrame:SetShown(d.icon)
        f.shield:ClearAllPoints();f.shield:SetPoint("RIGHT",d.icon and f.icon or f.bar,"LEFT",d.icon and -10 or -7,0)
    end
end
function M.Refresh(force)
    if not ready then return end
    local d=AndivalUIDB.castbar;local now=GetTime()
    local sample=force~=false or now-lastSnapshot>=.05
    if sample then lastSnapshot=now end
    for _,unit in ipairs(units) do
        local f=M.bars[unit]
        local enabled=d.enabled and (unit=="target" and d.target or unit=="targettarget" and d.targettarget)
        if sample then snapshots[unit]=enabled and Read(unit) or nil end
        local c=enabled and snapshots[unit] or nil
        if preview and enabled then
            local channel=unit=="targettarget"
            c={name=channel and (ru and "Поток энергии" or "Energy channel") or (ru and "Огненный шар" or "Fireball"),icon=channel and 136048 or 135812,
                startTime=now-(now%3),endTime=now-(now%3)+3,channel=channel,blocked=channel,interruptKnown=true}
        end
        if unit=="target" and QuartzTarget() and not preview then c=nil end
        if c and now<=c.endTime then
            local progress,remaining=L.Progress(c.startTime,c.endTime,now,c.channel)
            f.bar:GetStatusBarTexture():SetAtlas(c.channel and "ui-castingbar-filling-channel" or "ui-castingbar-filling-standard",false)
            f.bar:SetValue(progress);f.text:SetText(Label(unit).." · "..c.name);f.timer:SetFormattedText("%.1f",remaining);f.icon:SetTexture(c.icon)
            -- No shield is not a promise of interruptibility: unknown stays neutral.
            f.shield:SetShown(c.interruptKnown and c.blocked==true)
            f:Show()
        else f:Hide() end
        if unit=="target" then Native(f:IsShown() and not preview) end
    end
end
function M.Preview(on)
    preview=on and true or false
    for _,f in pairs(M.bars) do f:EnableMouse(preview) end
    M.Refresh()
end
M.Test={Read=Read}
local driver=CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED");driver:RegisterEvent("PLAYER_TARGET_CHANGED");driver:RegisterEvent("UNIT_TARGET")
driver:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=ADDON then return end
        AndivalUIDB.unitcastbars=AndivalUIDB.unitcastbars or {}
        for i,unit in ipairs(units) do
            local p=AndivalUIDB.unitcastbars[unit]
            if type(p)~="table" then p={} end
            p.x=type(p.x)=="number" and p.x or 0;p.y=type(p.y)=="number" and p.y or (i==1 and -65 or -115)
            AndivalUIDB.unitcastbars[unit]=p;M.bars[unit]=Create(unit)
        end
        ready=true;M.Layout()
    end
    M.Refresh()
end)
-- targettarget often has no dedicated cast events. Re-read unit identity and casts;
-- never carry old target state across a target switch or guess restricted timing.
local elapsed=0
driver:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt;if elapsed<.016 then return end;elapsed=0;M.Refresh(false) end)
