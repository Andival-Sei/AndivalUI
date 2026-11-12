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
