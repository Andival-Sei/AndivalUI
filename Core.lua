local ADDON, ns = ...
ns.name = ADDON
ns.modules = {}
ns.Integrations = {}
function ns.RegisterModule(id, module)
    assert(type(id)=="string" and not ns.modules[id], "Duplicate module")
    ns.modules[id] = module
end
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(_, event, name)    if event=="PLAYER_LOGIN" then
        ns.Profiles.Init();ns.InitCastbarSettings()
        for _,module in pairs(ns.modules) do if module.Layout then module.Layout() end;if module.Refresh then module.Refresh() end end
        init:UnregisterEvent("PLAYER_LOGIN");return
    end
    if name ~= ADDON then return end
    AndivalUIDB = type(AndivalUIDB)=="table" and AndivalUIDB or {}
    AndivalUIDB.schema = 1
    ns.Profiles.Init()
    init:UnregisterEvent("ADDON_LOADED")
end)

-- Original shared layout using Blizzard's native action-button rim artwork.
function ns.CreateIconFrame(parent, icon, size)
    local rim=parent:CreateTexture(nil,"OVERLAY")
    rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    rim:SetPoint("CENTER",icon,"CENTER",0,0)
    rim:SetSize(size*64/36,size*64/36)
    return rim
end

-- Profile migration is additive: keep old positions and migrate inherited visuals once.
local profileUnits={player=true,target=true,targettarget=true}
local appearanceKeys={"width","height","scale","icon","reducedMotion"}
local appearanceDefaults={width=280,height=16,scale=1,icon=false,reducedMotion=false}
local function NumberOr(value,fallback,lo,hi)
    if type(value)~="number" or value~=value then return fallback end
    return math.max(lo,math.min(hi,value))
end
function ns.InitCastbarSettings()
    AndivalUIDB=type(AndivalUIDB)=="table" and AndivalUIDB or {}
    if ns.Profiles then ns.Profiles.Init() end
    local db=AndivalUIDB
    db.castbar=type(db.castbar)=="table" and db.castbar or {}
    local player=db.castbar
    for k,v in pairs(appearanceDefaults) do if player[k]==nil then player[k]=v end end
    player.width=NumberOr(player.width,280,140,500)
    player.height=NumberOr(player.height,16,10,32)
    player.scale=NumberOr(player.scale,1,.6,1.6)
    db.unitcastbars=type(db.unitcastbars)=="table" and db.unitcastbars or {}
    for i,unit in ipairs({"target","targettarget"}) do
        local d=type(db.unitcastbars[unit])=="table" and db.unitcastbars[unit] or {}
        -- Missing fields alone are migrated; subsequent player changes are independent.
        if d.width==nil then d.width=player.width*.85 end
        if d.height==nil then d.height=14 end
        if d.scale==nil then d.scale=player.scale end
        if d.icon==nil then d.icon=player.icon end
        if d.reducedMotion==nil then d.reducedMotion=player.reducedMotion end
        if d.enabled==nil then d.enabled=player.enabled~=false and player[unit]~=false end
        d.width=NumberOr(d.width,238,140,500)
        d.height=NumberOr(d.height,14,10,32)
        d.scale=NumberOr(d.scale,1,.6,1.6)
        d.x=type(d.x)=="number" and d.x or 0
        d.y=type(d.y)=="number" and d.y or (i==1 and -65 or -115)
        db.unitcastbars[unit]=d
    end
    db.castbarProfileVersion=1
end
function ns.GetCastbarSettings(unit)
    assert(profileUnits[unit],"Unknown castbar profile")
    if unit=="player" then return AndivalUIDB.castbar end
    return AndivalUIDB.unitcastbars[unit]
end
function ns.CopyCastbarSettings(from,to)
    if InCombatLockdown() then return false end
    if not profileUnits[from] or not profileUnits[to] or from==to then return false end
    local source,destination=ns.GetCastbarSettings(from),ns.GetCastbarSettings(to)
    for _,key in ipairs(appearanceKeys) do destination[key]=source[key] end
    return true
end
function ns.ResetCastbarSettings(unit)
    if InCombatLockdown() or not profileUnits[unit] then return false end
    local d=ns.GetCastbarSettings(unit)
    for _,key in ipairs(appearanceKeys) do d[key]=appearanceDefaults[key] end
    if unit~="player" then d.width=238;d.height=14 end
    return true
end

-- Named profiles own the data; legacy fields remain aliases for existing modules.
local Profiles={}
ns.Profiles=Profiles
local activeName,activeCharacter
local function DeepCopy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local out={};seen[value]=out
    for k,v in pairs(value) do out[DeepCopy(k,seen)]=DeepCopy(v,seen) end
    return out
end
local function CharacterKey()
    local name=UnitName and UnitName("player")
    local realm=GetRealmName and GetRealmName()
    if (issecretvalue and (issecretvalue(name) or issecretvalue(realm))) then return nil end
    if type(name)~="string" or name=="" or type(realm)~="string" or realm=="" then return nil end
    return name.." - "..realm
end
local function ValidateName(name)
    if type(name)~="string" then return nil,"invalid" end
    name=name:match("^%s*(.-)%s*$")
    local _,characters=name:gsub("[^\128-\191]","")
    if name=="" or characters>32 or name:find("[%z\1-\31\127|]") then return nil,"invalid" end
    if (name:lower()=="default" and name~="Default") or name=="По умолчанию" then return nil,"reserved" end
    return name
end
local function Bind(name)
    local db=AndivalUIDB;local p=db.profiles[name]
    p.castbar=type(p.castbar)=="table" and p.castbar or {}
    p.unitcastbars=type(p.unitcastbars)=="table" and p.unitcastbars or {}
    db.castbar,db.unitcastbars=p.castbar,p.unitcastbars
    activeName=name
end
function Profiles.Init()
    local db=AndivalUIDB
    db.profiles=type(db.profiles)=="table" and db.profiles or {}
    db.characterProfiles=type(db.characterProfiles)=="table" and db.characterProfiles or {}
    -- Default is populated from the pre-profile configuration exactly once.
    if type(db.profiles.Default)~="table" then
        db.profiles.Default={castbar=DeepCopy(db.castbar or {}),unitcastbars=DeepCopy(db.unitcastbars or {})}
    end
    local key=CharacterKey()
    local chosen=key and db.characterProfiles[key] or "Default"
    if type(chosen)~="string" or type(db.profiles[chosen])~="table" then chosen="Default" end
    if not activeName or activeCharacter~=key or db.castbar~=db.profiles[chosen].castbar then Bind(chosen) end
    activeCharacter=key
    if key then db.characterProfiles[key]=activeName end
    db.namedProfileVersion=1
end
function Profiles.Current() return activeName or "Default" end
function Profiles.List()
    local list={"Default"}
    for name,p in pairs(AndivalUIDB.profiles) do if name~="Default" and type(name)=="string" and type(p)=="table" then list[#list+1]=name end end
    table.sort(list,function(a,b) if a=="Default" then return b~="Default" end;if b=="Default" then return false end;return a<b end)
    return list
end
function Profiles.Switch(name)
    if InCombatLockdown() then return false,"combat" end
    if type(AndivalUIDB.profiles[name])~="table" then return false,"missing" end
    local key=CharacterKey();if not key then return false,"notready" end
    Bind(name);activeCharacter=key
    if activeCharacter then AndivalUIDB.characterProfiles[activeCharacter]=name end
    ns.InitCastbarSettings()
    return true
end
function Profiles.Copy(from,name)
    if InCombatLockdown() then return false,"combat" end
    local clean,err=ValidateName(name);if not clean then return false,err end
    if AndivalUIDB.profiles[clean]~=nil then return false,"exists" end
    local source=AndivalUIDB.profiles[from]
    if type(source)~="table" then return false,"missing" end
    AndivalUIDB.profiles[clean]=DeepCopy(source)
    return true,clean
end
function Profiles.Create(name) return Profiles.Copy("Default",name) end
function Profiles.Rename(old,name)
    if InCombatLockdown() then return false,"combat" end
    if old=="Default" then return false,"protected" end
    local clean,err=ValidateName(name);if not clean then return false,err end
    if type(AndivalUIDB.profiles[old])~="table" then return false,"missing" end
    if clean==old then return true,old end
    if AndivalUIDB.profiles[clean]~=nil then return false,"exists" end
    AndivalUIDB.profiles[clean]=AndivalUIDB.profiles[old];AndivalUIDB.profiles[old]=nil
    for key,value in pairs(AndivalUIDB.characterProfiles) do if value==old then AndivalUIDB.characterProfiles[key]=clean end end
    if activeName==old then activeName=clean end
    return true,clean
end
function Profiles.Delete(name,confirmed)
    if InCombatLockdown() then return false,"combat" end
    if name=="Default" then return false,"protected" end
    if type(AndivalUIDB.profiles[name])~="table" then return false,"missing" end
    if confirmed~=true then return false,"confirm" end
    local wasActive=activeName==name
    for key,value in pairs(AndivalUIDB.characterProfiles) do if value==name then AndivalUIDB.characterProfiles[key]="Default" end end
    if wasActive then Bind("Default") end
    AndivalUIDB.profiles[name]=nil
    if wasActive then ns.InitCastbarSettings() end
    return true
end
