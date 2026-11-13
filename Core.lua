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
local profileUnits={player=true,target=true,targettarget=true,focus=true}
local appearanceKeys={"width","height","scale","icon","reducedMotion","font","fontSize","texture","castColor","channelColor","timeFormat"}
local appearanceDefaults={width=280,height=16,scale=1,icon=false,reducedMotion=false,font="native",fontSize=0,texture="native",castColor="native",channelColor="native",timeFormat="elapsed_total"}
local function NumberOr(value,fallback,lo,hi)
    if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then return fallback end
    if lo then return math.max(lo,math.min(hi,value)) end
    return value
end
local function BooleanOr(value,fallback)
    if type(value)=="boolean" then return value end
    return fallback
end
local function NormalizeAppearance(d)
    local allowed={font={native=true,chat=true},texture={native=true,smooth=true},
        castColor={native=true,amber=true,blue=true,teal=true,violet=true,white=true},
        channelColor={native=true,amber=true,blue=true,teal=true,violet=true,white=true},
        timeFormat={elapsed_total=true,remaining=true,elapsed=true,hidden=true}}
    for key,values in pairs(allowed) do
        if type(d[key])~="string" or not values[d[key]] then d[key]=appearanceDefaults[key] end
    end
    d.fontSize=NumberOr(d.fontSize,0)
    if d.fontSize~=0 then d.fontSize=math.floor(NumberOr(d.fontSize,12,10,18)+.5) end
end
local function NormalizeCastbarProfile(profile,previousVersion)
    profile.castbar=type(profile.castbar)=="table" and profile.castbar or {}
    profile.unitcastbars=type(profile.unitcastbars)=="table" and profile.unitcastbars or {}
    local player=profile.castbar
    local legacy=(profile.castbarProfileVersion or previousVersion)~=1
    player.width=NumberOr(player.width,280,140,500)
    player.height=NumberOr(player.height,16,10,32)
    player.scale=NumberOr(player.scale,1,.6,1.6)
    player.x=NumberOr(player.x,0)
    player.y=NumberOr(player.y,-170)
    player.enabled=BooleanOr(player.enabled,true)
    player.latency=BooleanOr(player.latency,true)
    player.icon=BooleanOr(player.icon,false)
    player.reducedMotion=BooleanOr(player.reducedMotion,false)
    player.target=BooleanOr(player.target,true)
    player.targettarget=BooleanOr(player.targettarget,true)
    NormalizeAppearance(player)
    for i,unit in ipairs({"target","targettarget","focus"}) do
        local d=type(profile.unitcastbars[unit])=="table" and profile.unitcastbars[unit] or {}
        -- Inherit only missing legacy fields, never malformed fields or later edits.
        if legacy and unit~="focus" then
            if d.width==nil then d.width=player.width*.85 end
            if d.scale==nil then d.scale=player.scale end
            if d.icon==nil then d.icon=player.icon end
            if d.reducedMotion==nil then d.reducedMotion=player.reducedMotion end
            if d.enabled==nil then d.enabled=player.enabled and player[unit] end
        end
        d.width=NumberOr(d.width,238,140,500)
        d.height=NumberOr(d.height,14,10,32)
        d.scale=NumberOr(d.scale,1,.6,1.6)
        d.x=NumberOr(d.x,0)
        d.y=NumberOr(d.y,i==1 and -65 or (i==2 and -115 or -240))
        d.enabled=BooleanOr(d.enabled,unit~="focus")
        d.icon=BooleanOr(d.icon,false)
        d.reducedMotion=BooleanOr(d.reducedMotion,false)
        NormalizeAppearance(d)
        profile.unitcastbars[unit]=d
    end
    profile.castbarProfileVersion=1
end
function ns.InitCastbarSettings()
    AndivalUIDB=type(AndivalUIDB)=="table" and AndivalUIDB or {}
    -- Profiles.Init normalizes the canonical profile before binding legacy aliases.
    ns.Profiles.Init()
    AndivalUIDB.castbarProfileVersion=1
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
    NormalizeCastbarProfile(p,db.castbarProfileVersion)
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
    NormalizeCastbarProfile(db.profiles[chosen],db.castbarProfileVersion)
    if not activeName or activeCharacter~=key or db.castbar~=db.profiles[chosen].castbar or db.unitcastbars~=db.profiles[chosen].unitcastbars then Bind(chosen) end
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
