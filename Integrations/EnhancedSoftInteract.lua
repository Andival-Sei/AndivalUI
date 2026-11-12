local _, ns = ...
-- Read-only adapter for Enhanced Soft Interact 0.5.8. No code or artwork is bundled.
ns.Integrations.ESI = {}
function ns.Integrations.ESI.IsVisible()
    return ns.CastbarLogic.ESIVisible(_G.EnhancedSoftInteractHUD, _G.EnhancedSoftInteractDB)
end
