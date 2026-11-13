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
init:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    AndivalUIDB = type(AndivalUIDB)=="table" and AndivalUIDB or {}
    AndivalUIDB.schema = 1
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
