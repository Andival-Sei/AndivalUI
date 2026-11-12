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
