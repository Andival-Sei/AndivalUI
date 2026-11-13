local _,ns=...
-- Observe explicit crafting requests only. Never invoke crafting APIs or count item yields.
local M={}
ns.CastbarCrafting=M
local batch,recentStart
local hooked={}
local function Safe(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function ID(v)
    v=Safe(v)
    return type(v)=="number" and v>0 and v<math.huge and v==math.floor(v) and v or nil
end
local function GUID(v) v=Safe(v);return type(v)=="string" and v~="" and v or nil end
local function Reset() batch=nil;recentStart=nil end
local function Expire(now)
    if batch and ((batch.stopDeadline and now>batch.stopDeadline) or (not batch.active and now>batch.deadline)) then batch=nil end
end
local function Request(spellID,count)
    local now=GetTime();spellID,count=ID(spellID),ID(count)
    -- A repeated request without a new START cannot redefine an in-flight batch.
    if batch and batch.active and recentStart and recentStart.guid==batch.active then return end
    batch=nil
    -- Missing/secret counts, single crafts, and implausible totals have no series label.
    if not spellID or not count or count<2 or count>10000 then return end
    batch={spellID=spellID,total=count,completed=0,seen={},deadline=now+5}
    -- START may fire synchronously inside the function, before its secure post-hook.
    if recentStart and recentStart.spellID==spellID and now-recentStart.at<=.5 then batch.active=recentStart.guid end
end
local function Event(event,unit,guid,spellID)
    if event=="TRADE_SKILL_CLOSE" or event=="PLAYER_ENTERING_WORLD" then Reset();return end
    if Safe(unit)~="player" then return end
    guid,spellID=GUID(guid),ID(spellID)
    local now=GetTime();Expire(now)
    if event=="UNIT_SPELLCAST_START" then
        recentStart=guid and spellID and {guid=guid,spellID=spellID,at=now} or nil
        if batch then
            if not guid or spellID~=batch.spellID or batch.seen[guid] then batch=nil
            else batch.active=guid;batch.stopDeadline=nil end
        end
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        if recentStart and recentStart.guid==guid then recentStart=nil end
        if batch and guid and spellID==batch.spellID and guid==batch.active and not batch.seen[guid] then
            batch.seen[guid]=true;batch.completed=batch.completed+1
            batch.active=nil;batch.stopDeadline=nil;batch.deadline=now+2
            if batch.completed>=batch.total then batch=nil end
        end
    elseif event=="UNIT_SPELLCAST_STOP" then
        if recentStart and recentStart.guid==guid then recentStart=nil end
        if batch and guid and guid==batch.active then batch.stopDeadline=now+.3 end
    else -- Failed/interrupted casts abort the observed series, never count as successes.
        if recentStart and recentStart.guid==guid then recentStart=nil end
        if batch and guid and guid==batch.active then batch=nil end
    end
end
function M.Label(spellID,castGUID,isTradeSkill)
    Expire(GetTime())
    if Safe(isTradeSkill)~=true then return nil end
    spellID,castGUID=ID(spellID),GUID(castGUID)
    if batch and spellID==batch.spellID and castGUID and castGUID==batch.active then
        return string.format("%d / %d",batch.completed+1,batch.total)
    end
end
local function Install()
    if type(hooksecurefunc)~="function" then return end
    if type(C_TradeSkillUI)=="table" then
        for _,name in ipairs({"CraftRecipe","CraftEnchant"}) do
            if not hooked[name] and type(C_TradeSkillUI[name])=="function" then
                hooked[name]=pcall(hooksecurefunc,C_TradeSkillUI,name,Request)
            end
        end
    end
    if not hooked.stop and type(SpellStopCasting)=="function" then hooked.stop=pcall(hooksecurefunc,"SpellStopCasting",Reset) end
end
local driver=CreateFrame("Frame")
for _,event in ipairs({"UNIT_SPELLCAST_START","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_FAILED_QUIET","UNIT_SPELLCAST_INTERRUPTED"}) do driver:RegisterUnitEvent(event,"player") end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","TRADE_SKILL_CLOSE","PLAYER_ENTERING_WORLD"}) do driver:RegisterEvent(event) end
driver:SetScript("OnEvent",function(_,event,...)
    if event=="ADDON_LOADED" or event=="PLAYER_LOGIN" then Install() else Event(event,...) end
end)
M.Test={Request=Request,Event=Event,Reset=Reset}
