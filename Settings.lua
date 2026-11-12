local _, ns = ...
local ru = ns.ru
local M = ns.Castbar
local panel
local function T(a,b) return ru and a or b end
function ns.CreateSettings()
    panel=CreateFrame("Frame","AndivalUISettings",UIParent,"BasicFrameTemplateWithInset")
    panel:SetSize(390,370); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG")
    panel.TitleText:SetText("Andival UI · Castbar")
    panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",panel.StartMoving); panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
    local intro=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT",20,-38); intro:SetWidth(350); intro:SetJustifyH("LEFT")
    intro:SetText(T("Первый модуль: заклинания. Взаимодействия остаются у Enhanced Soft Interact.","First module: spells. Enhanced Soft Interact keeps object interactions."))
    local controls={}
    local function Check(key,label,y)
        local c=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
        c:SetPoint("TOPLEFT",18,y)
        local caption=c:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        caption:SetPoint("LEFT",c,"RIGHT",2,0); caption:SetText(label)
        c:SetScript("OnClick",function(self) AndivalUIDB.castbar[key]=self:GetChecked(); M.Layout(); M.Refresh() end)
        controls[#controls+1]={control=c,key=key}
    end
    Check("enabled",T("Включить модуль","Enable module"),-70)
    Check("icon",T("Иконка заклинания","Spell icon"),-100)
    Check("latency",T("Зона сетевой задержки","Network latency zone"),-130)
    Check("reducedMotion",T("Уменьшить анимацию","Reduced motion"),-160)
    local function Slider(key,label,min,max,step,y)
        local c=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
        c:SetPoint("TOPLEFT",32,y); c:SetSize(320,17); c:SetMinMaxValues(min,max); c:SetValueStep(step); c:SetObeyStepOnDrag(true)
        c.Low:SetText(tostring(min)); c.High:SetText(tostring(max))
        c:SetScript("OnValueChanged",function(self,value)
            value=math.floor(value/step+.5)*step
            AndivalUIDB.castbar[key]=value; self.Text:SetText(label .. ": " .. string.format(step<1 and "%.2f" or "%d",value)); M.Layout()
        end)
        controls[#controls+1]={control=c,key=key,slider=true}
    end
    Slider("width",T("Ширина","Width"),180,500,10,-217)
    Slider("scale",T("Масштаб","Scale"),.6,1.6,.05,-267)
    local reset=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    reset:SetSize(130,24); reset:SetPoint("BOTTOMLEFT",20,18); reset:SetText(T("Сбросить модуль","Reset module"))
    reset:SetScript("OnClick",function() M.Reset(); panel:GetScript("OnShow")() end)
    local done=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    done:SetSize(130,24); done:SetPoint("BOTTOMRIGHT",-20,18); done:SetText(T("Готово","Done")); done:SetScript("OnClick",function() panel:Hide() end)
    panel:SetScript("OnShow",function()
        for _,v in ipairs(controls) do if v.slider then v.control:SetValue(AndivalUIDB.castbar[v.key]) else v.control:SetChecked(AndivalUIDB.castbar[v.key]) end end
        M.Preview(true)
    end)
    panel:SetScript("OnHide",function() M.Preview(false) end)
    panel:Hide()
    table.insert(UISpecialFrames,"AndivalUISettings")
end
SLASH_ANDIVALUI1="/aui"
SLASH_ANDIVALUI2="/acast"
SlashCmdList.ANDIVALUI=function(message)
    if message=="status" then M.Status(); return end
    if InCombatLockdown() then M.Say(T("Открой настройки вне боя.","Open settings out of combat.")); return end
    if panel then panel:SetShown(not panel:IsShown()) end
end
