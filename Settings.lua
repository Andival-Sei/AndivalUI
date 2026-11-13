local _, ns = ...
local ru, M = ns.ru, ns.Castbar
local panel
local function T(a,b) return ru and a or b end
local function Decimal(v) local s=tostring(v);return ru and (s:gsub("%.",",")) or s end
local units={"player","target","targettarget"}
local names={player=T("Игрок","Player"),target=T("Цель","Target"),targettarget=T("Цель цели","Target of target")}
function ns.CreateSettings()
    panel=CreateFrame("Frame","AndivalUISettings",UIParent,"BasicFrameTemplateWithInset")
    panel:SetSize(580,570);panel:SetPoint("CENTER");panel:SetFrameStrata("DIALOG")
    panel.TitleText:SetText("Andival UI · "..T("Полосы заклинаний","Castbars"))
    panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
    panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
    local selected,source,loading,previewOn,previewMode="player","target",false,true,"sequence"
    local controls,tabs,modeButtons={},{},{}
    panel.controls=controls;panel.modeButtons=modeButtons
    local RefreshControls,RefreshCopy
    local function CanEdit() if InCombatLockdown() then panel:Hide();return false end return true end
    local function Apply()
        M.Layout();M.Refresh()
        if ns.UnitCastbars then ns.UnitCastbars.Layout();ns.UnitCastbars.Refresh() end
    end
    local function Label(text,x,y,width,template)
        local t=panel:CreateFontString(nil,"OVERLAY",template or "GameFontHighlightSmall")
        t:SetPoint("TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetText(text);return t
    end
    local function Button(text,x,y,w,click)
        local b=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
        b:SetSize(w,26);b:SetPoint("TOPLEFT",x,y);b:SetText(text)
        b:SetScript("OnClick",function() if CanEdit() then click() end end);return b
    end
    Label(T("Настройки независимы. Перетаскивай полосы в режиме теста.","Independent profiles. Drag bars while testing to position them."),20,-38,540)
    for i,unit in ipairs(units) do
        tabs[unit]=Button(names[unit],20+(i-1)*180,-64,174,function()
            selected=unit;if source==selected then source=selected=="player" and "target" or "player" end
            RefreshControls()
        end)
    end
    Label(T("ВНЕШНИЙ ВИД","APPEARANCE"),25,-110,240,"GameFontNormalSmall")
    Label(T("ТЕСТ СОСТОЯНИЙ","STATE PREVIEW"),310,-110,245,"GameFontNormalSmall")
    local function Check(key,label,y)
        local c=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
        c:SetPoint("TOPLEFT",20,y)
        local caption=c:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        caption:SetPoint("LEFT",c,"RIGHT",2,0);caption:SetWidth(220);caption:SetJustifyH("LEFT");caption:SetText(label)
        c:SetScript("OnClick",function(self)
            if not CanEdit() then return end
            ns.GetCastbarSettings(selected)[key]=self:GetChecked() and true or false;Apply()
        end)
        controls[key]={control=c,caption=caption};return c
    end
    Check("enabled",T("Включить полосу","Enable bar"),-132)
    Check("icon",T("Иконка заклинания","Spell icon"),-162)
    Check("reducedMotion",T("Уменьшить анимацию","Reduced motion"),-192)
    Check("latency",T("Зона сетевой задержки","Network latency zone"),-222)
    local function Slider(key,label,min,max,step,y)
        local c=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
        c:SetPoint("TOPLEFT",34,y);c:SetSize(230,17);c:SetMinMaxValues(min,max);c:SetValueStep(step);c:SetObeyStepOnDrag(true)
        c.Low:SetText(Decimal(min));c.High:SetText(Decimal(max))
        -- Some client/template variants retain additional default Low/High labels.
        if c.GetRegions then
            for _,region in ipairs({c:GetRegions()}) do
                if region~=c.Text and region~=c.Low and region~=c.High and region.GetObjectType and region:GetObjectType()=="FontString" then region:Hide() end
            end
        end
        c:SetScript("OnValueChanged",function(self,value)
            value=math.floor(value/step+.5)*step
            self.Text:SetText(label..": "..Decimal(string.format(step<1 and "%.2f" or "%d",value)))
            if loading or not CanEdit() then return end
            ns.GetCastbarSettings(selected)[key]=value;Apply()
        end)
        controls[key]={control=c,slider=true}
    end
    Slider("width",T("Ширина","Width"),140,500,1,-282)
    Slider("height",T("Высота","Height"),10,32,1,-334)
    Slider("scale",T("Масштаб","Scale"),.6,1.6,.05,-386)
    local testToggle=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
    testToggle:SetPoint("TOPLEFT",304,-132)
    local testCaption=testToggle:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    testCaption:SetPoint("LEFT",testToggle,"RIGHT",2,0);testCaption:SetText(T("Показывать тест","Show preview"))
    local status=Label("",310,-316,240)
    local function StartMode(mode)
        previewMode=mode;previewOn=true;testToggle:SetChecked(true)
        if M.SetPreviewMode then M.SetPreviewMode(mode) end
        M.Preview(true)
        for id,b in pairs(modeButtons) do b:SetEnabled(id~=mode) end
        status:SetText(mode=="esi" and T("Тест скрывает нашу полосу, не меняя ESI. Это имитация передачи взаимодействия.","Simulates hiding our bar without changing ESI. No actual interaction is triggered.") or mode=="protected" and T("Щит показан на полосах цели и цели цели. Это демонстрационные данные.","The shield is shown on target and target-of-target bars. Uses sample data.") or T("Демонстрационные данные, не реальный каст. Тики не имитируются.","Sample data, not a live cast. Tick timing is not fabricated."))
    end
    testToggle:SetScript("OnClick",function(self)
        if not CanEdit() then return end
        previewOn=self:GetChecked() and true or false
        M.Preview(previewOn)
    end)
    local modes={
        {"sequence",T("Все по кругу","Cycle all")},{"cast",T("Обычный каст","Cast")},
        {"channel",T("Ченнелинг","Channel")},{"delayed",T("Задержка","Delay")},
        {"success",T("Завершение","Success")},{"interrupted",T("Прерывание","Interrupted")},
        {"protected",T("Со щитом","Protected")},{"esi",T("Передача ESI","ESI handoff")},
    }
    for i,entry in ipairs(modes) do
        local id=entry[1]
        modeButtons[id]=Button(entry[2],310+((i-1)%2)*124,-176-math.floor((i-1)/2)*32,118,function() StartMode(id) end)
    end
    Label(T("Копируются только оформление и анимация. Положение и включение сохраняются.","Copies appearance and motion only. Position and enabled state stay unchanged."),310,-365,240)
    local sourceButton=Button("",310,-412,242,function()
        for i,unit in ipairs(units) do if unit==source then
            repeat i=i%#units+1 until units[i]~=selected
            source=units[i];break
        end end
        RefreshCopy()
    end)
    local copyButton=Button("",310,-443,242,function()
        ns.CopyCastbarSettings(source,selected);Apply();RefreshControls()
    end)
    RefreshCopy=function()
        sourceButton:SetText(T("Источник: ","From: ")..names[source])
        copyButton:SetText(T("Копировать → ","Copy to: ")..names[selected])
    end
    Button(T("Сбросить вид","Reset appearance"),25,-443,240,function()
        ns.ResetCastbarSettings(selected);Apply();RefreshControls()
    end)
    Label(T("ESI управляет взаимодействиями. Каждая полоса включается независимо.","ESI owns interactions. Each castbar is enabled independently."),25,-490,530)
    Button(T("Готово","Done"),420,-525,132,function() panel:Hide() end)
    RefreshControls=function()
        loading=true;panel.selectedUnit=selected
        for unit,b in pairs(tabs) do b:SetEnabled(unit~=selected) end
        local d=ns.GetCastbarSettings(selected)
        for key,v in pairs(controls) do
            if v.slider then v.control:SetValue(d[key]) else v.control:SetChecked(d[key] and true or false) end
        end
        controls.enabled.caption:SetText(T("Включить полосу","Enable bar"))
        controls.latency.control:SetEnabled(selected=="player")
        controls.latency.caption:SetTextColor(selected=="player" and 1 or .45,selected=="player" and 1 or .45,selected=="player" and 1 or .45)
        loading=false;RefreshCopy()
    end
    panel.SelectUnit=function(unit)
        if not CanEdit() or not names[unit] then return end
        selected=unit;if source==selected then source=selected=="player" and "target" or "player" end;RefreshControls()
    end
    panel.SetTestMode=function(mode) if CanEdit() and modeButtons[mode] then StartMode(mode) end end
    panel.RefreshControls=RefreshControls
    -- Named profile manager is a separate dialog so the castbar controls stay uncluttered.
    local manager=CreateFrame("Frame","AndivalUIProfiles",panel,"BasicFrameTemplateWithInset")
    manager:SetSize(530,500);manager:SetPoint("CENTER");manager:SetFrameStrata("FULLSCREEN_DIALOG");manager:EnableMouse(true)
    manager.TitleText:SetText(T("Профили Andival UI","Andival UI profiles"))
    local chosen,page,pendingDelete="Default",1,nil
    local function ProfileName(name) return name=="Default" and T("По умолчанию","Default") or name end
    local profileRows={}
    local UpdateProfiles
    local function ProfileLabel(text,x,y,w)
        local f=manager:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        f:SetPoint("TOPLEFT",x,y);f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(text);return f
    end
    local function ProfileButton(text,x,y,w,fn)
        local b=CreateFrame("Button",nil,manager,"UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT",x,y);b:SetSize(w,26);b:SetText(text)
        b:SetScript("OnClick",function() if CanEdit() then fn() end end);return b
    end
    local currentLabel=ProfileLabel("",20,-40,490)
    local profileStatus=ProfileLabel("",20,-450,490)
    local errors={
        invalid=T("Имя: 1–32 символа, без управляющих знаков и |.","Use 1–32 characters, without control characters or |."),
        reserved=T("Это имя зарезервировано.","That name is reserved."),
        exists=T("Такой профиль уже существует.","A profile with that name already exists."),
        missing=T("Профиль не найден.","Profile not found."),
        protected=T("«По умолчанию» нельзя удалить или переименовать.","Default cannot be deleted or renamed."),
        notready=T("Дождись загрузки персонажа и попробуй снова.","Wait for your character to finish loading and try again."),
        combat=T("Профили можно менять только вне боя.","Profiles can be changed only out of combat."),
        confirm=T("Подтверди удаление ниже.","Confirm deletion below."),
    }
    local function Result(ok,err)
        profileStatus:SetText(ok and T("Сохранено.","Saved.") or (errors[err] or T("Не удалось выполнить действие.","The action could not be completed.")))
        return ok
    end
    local function RefreshActive()
        M.Preview(false);Apply();RefreshControls()
        if previewOn then if M.SetPreviewMode then M.SetPreviewMode(previewMode) end;M.Preview(true) end
    end
    ProfileLabel(T("Сохранённые профили","Saved profiles"),20,-68,210)
    for i=1,5 do
        local row=ProfileButton("",20,-92-(i-1)*31,210,function()
            local list=ns.Profiles.List();chosen=list[(page-1)*5+i] or "Default";pendingDelete=nil;UpdateProfiles()
        end)
        profileRows[i]=row
    end
    ProfileButton("<",20,-252,45,function()page=math.max(1,page-1);UpdateProfiles()end)
    ProfileButton(">",185,-252,45,function()page=math.min(math.max(1,math.ceil(#ns.Profiles.List()/5)),page+1);UpdateProfiles()end)
    local pageLabel=ProfileLabel("",77,-260,100)
    ProfileButton(T("Использовать","Use selected"),20,-288,210,function()
        if Result(ns.Profiles.Switch(chosen)) then RefreshActive();UpdateProfiles() end
    end)
    ProfileLabel(T("Новое имя","New name"),250,-68,250)
    local nameBox=CreateFrame("EditBox","AndivalUIProfileName",manager,"InputBoxTemplate")
    nameBox:SetSize(240,26);nameBox:SetPoint("TOPLEFT",255,-91);nameBox:SetAutoFocus(false);nameBox:SetMaxLetters(32)
    nameBox:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    nameBox:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    ProfileButton(T("Из «По умолчанию»","New from Default"),250,-130,250,function()
        local ok,name=ns.Profiles.Create(nameBox:GetText())
        if Result(ok,name) then chosen=name;pendingDelete=nil;local switched,why=ns.Profiles.Switch(name);if switched then RefreshActive() else Result(false,why) end;nameBox:SetText("");UpdateProfiles() end
    end)
    ProfileButton(T("Копия выбранного","Duplicate selected"),250,-164,250,function()
        local ok,name=ns.Profiles.Copy(chosen,nameBox:GetText())
        if Result(ok,name) then chosen=name;pendingDelete=nil;local switched,why=ns.Profiles.Switch(name);if switched then RefreshActive() else Result(false,why) end;nameBox:SetText("");UpdateProfiles() end
    end)
    local rename=ProfileButton(T("Переименовать","Rename selected"),250,-198,250,function()
        local ok,name=ns.Profiles.Rename(chosen,nameBox:GetText())
        if Result(ok,name) then chosen=name;pendingDelete=nil;nameBox:SetText("");UpdateProfiles() end
    end)
    local delete=ProfileButton(T("Удалить выбранный…","Delete selected…"),250,-232,250,function()
        pendingDelete=chosen;UpdateProfiles()
    end)
    ProfileLabel(T("Создание и копирование сразу включают новый профиль для этого персонажа. Изменения сохраняются автоматически.","Create and duplicate immediately select the new profile for this character. Changes are saved automatically."),250,-279,250)
    local confirmation=ProfileLabel("",20,-340,490)
    local yes=ProfileButton(T("Да, удалить","Yes, delete"),20,-391,210,function()
        if not pendingDelete then return end
        local ok,err=ns.Profiles.Delete(pendingDelete,true)
        pendingDelete=nil
        if Result(ok,err) then chosen=ns.Profiles.Current();RefreshActive() end
        UpdateProfiles()
    end)
    local no=ProfileButton(T("Отмена","Cancel"),250,-391,250,function()pendingDelete=nil;UpdateProfiles()end)
    UpdateProfiles=function()
        local list=ns.Profiles.List();page=math.min(page,math.max(1,math.ceil(#list/5)))
        currentLabel:SetText(T("Текущий профиль: ","Current profile: ")..ProfileName(ns.Profiles.Current()))
        for i,row in ipairs(profileRows) do
            local name=list[(page-1)*5+i]
            row:SetShown(name~=nil);row:SetText(name and ProfileName(name) or "");row:SetEnabled(name~=chosen)
        end
        pageLabel:SetText(page.." / "..math.max(1,math.ceil(#list/5)))
        rename:SetEnabled(chosen~="Default");delete:SetEnabled(chosen~="Default")
        confirmation:SetText(pendingDelete and (T("Удалить «","Delete “")..ProfileName(pendingDelete)..T("»? Персонажи с этим профилем перейдут на «По умолчанию».","”? Characters using it will switch to Default.")) or "")
        yes:SetShown(pendingDelete~=nil);no:SetShown(pendingDelete~=nil)
    end
    manager:SetScript("OnShow",function()
        if not CanEdit() then return end
        chosen=ns.Profiles.Current();pendingDelete=nil;page=1;profileStatus:SetText("");UpdateProfiles()
    end)
    manager:SetScript("OnHide",function()pendingDelete=nil;nameBox:ClearFocus()end)
    manager:Hide();table.insert(UISpecialFrames,"AndivalUIProfiles")
    manager.Refresh=UpdateProfiles;manager.nameBox=nameBox;manager.rows=profileRows
    Button(T("Профили…","Profiles…"),25,-525,170,function()manager:Show()end)
    panel.ShowProfiles=function()if CanEdit() then manager:Show()end end
    panel:SetScript("OnShow",function()
        if not CanEdit() then return end
        ns.InitCastbarSettings();RefreshControls();StartMode(previewMode)
    end)
    panel:SetScript("OnHide",function() manager:Hide();M.Preview(false) end)
    panel:RegisterEvent("PLAYER_REGEN_DISABLED")
    panel:SetScript("OnEvent",function() panel:Hide() end)
    panel:Hide();table.insert(UISpecialFrames,"AndivalUISettings")
end
SLASH_ANDIVALUI1="/aui"
SLASH_ANDIVALUI2="/acast"
SlashCmdList.ANDIVALUI=function(message)
    if message=="status" then M.Status();return end
    if InCombatLockdown() then M.Say(T("Открой настройки вне боя.","Open settings out of combat."));return end
    if panel then panel:SetShown(not panel:IsShown()) end
end
