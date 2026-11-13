local _,ns=...
local M,ru=ns.Castbar,ns.ru
local panel
local function T(a,b)return ru and a or b end
local function Decimal(v)local s=tostring(v);return ru and (s:gsub("%.",",")) or s end
local units={"player","target","targettarget","focus"}
local names={player=T("Игрок","Player"),target=T("Цель","Target"),targettarget=T("Цель цели","Target of target"),focus=T("Фокус","Focus")}
local frameNames={player="AndivalUICastbarFrame",target="AndivalUITargetCastbar",targettarget="AndivalUITargetTargetCastbar",focus="AndivalUIFocusCastbar"}
local modes={{"sequence",T("Все по кругу","Cycle all")},{"cast",T("Обычный каст","Cast")},{"channel",T("Ченнелинг","Channel")},{"delayed",T("Задержка","Delay")},{"success",T("Завершение","Success")},{"interrupted",T("Прерывание","Interrupted")},{"protected",T("Со щитом","Protected")},{"esi",T("Передача ESI","ESI handoff")},{"cancelled",T("Отмена / неизвестно","Cancelled / unknown")}}
local function ProfileName(name)return name=="Default" and T("По умолчанию","Default") or name end
function ns.CreateSettings()
    panel=CreateFrame("Frame","AndivalUISettings",UIParent,"PortraitFrameTemplate")
    panel:SetSize(900,650);panel:SetPoint("CENTER");panel:SetFrameStrata("DIALOG");panel:SetClampedToScreen(true)
    local windowTitle="Andival UI - "..T("Полосы заклинаний","Castbars")
    if panel.SetTitle then panel:SetTitle(windowTitle)else panel.TitleText:SetText(windowTitle)end
    if panel.SetPortraitToAsset then panel:SetPortraitToAsset("Interface\\Icons\\Spell_Holy_HolyBolt")end
    panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",function(self)if not InCombatLockdown() then self:StartMoving()end end)
    panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
    local selected,category,tab,source="player","overview","general","target"
    local previewOn,mode,loading,positioning=true,"sequence",false,false
    local pages,nav,tabs,controls,dropdowns={},{},{},{},{}
    local savedParents={}
    local Refresh,Dock,Apply,RenderPage,EndPosition
    panel.controls=controls;panel.modeButtons={};panel.nav=nav;panel.navigation=nav
    local function CanEdit()if InCombatLockdown()then panel:Hide();return false end return true end
    local function Text(parent,value,x,y,w,font)
        local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
        f:SetPoint("TOPLEFT",x,y);f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(value);return f
    end
    local function Button(parent,label,x,y,w,fn)
        local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(w,26);b:SetPoint("TOPLEFT",x,y);b:SetText(label)
        b:SetScript("OnClick",function()if CanEdit()then fn()end end);return b
    end
    local function Back(parent,r,g,b,a)
        local t=parent:CreateTexture(nil,"BACKGROUND");t:SetAllPoints();t:SetColorTexture(r,g,b,a);return t
    end
    -- Opaque title backing remains below the native portrait and bronze frame.
    local titleBacking=panel:CreateTexture(nil,"BACKGROUND",nil,0)
    titleBacking:SetPoint("TOPLEFT",70,-2);titleBacking:SetPoint("TOPRIGHT",-30,-2);titleBacking:SetHeight(25)
    titleBacking:SetColorTexture(.105,.075,.045,1)
    for _,y in ipairs({-2,-26})do
        local rule=panel:CreateTexture(nil,"BACKGROUND",nil,1)
        rule:SetPoint("TOPLEFT",70,y);rule:SetPoint("TOPRIGHT",-30,y);rule:SetHeight(1)
        rule:SetColorTexture(.46,.33,.16,1)
    end
    -- All artwork is supplied by the client, not by another addon.
    local paper=panel:CreateTexture(nil,"BACKGROUND",nil,1)
    paper:SetPoint("TOPLEFT",7,-26);paper:SetPoint("BOTTOMRIGHT",-7,7)
    paper:SetAtlas("Professions-QualityWindow-Background",false)
    paper:SetVertexColor(.72,.64,.51,1)
    local sidebar=CreateFrame("Frame",nil,panel);sidebar:SetPoint("TOPLEFT",14,-34);sidebar:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",14,50);sidebar:SetWidth(188);Back(sidebar,.075,.055,.035,.82)
    Text(sidebar,"ANDIVAL UI",16,-18,160,"GameFontNormalLarge")
    Text(sidebar,T("ПОЛОСЫ ЗАКЛИНАНИЙ","CASTBARS"),16,-50,160,"GameFontDisableSmall")
    local title=Text(panel,"",224,-43,630,"GameFontNormalLarge");title:SetJustifyH("CENTER")
    local subtitle=Text(panel,"",224,-70,630)
    local inset=CreateFrame("Frame",nil,panel,"InsetFrameTemplate")
    inset:SetPoint("TOPLEFT",216,-122);inset:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-18,186)
    if inset.Bg then inset.Bg:Hide()end
    local insetPaper=inset:CreateTexture(nil,"BACKGROUND",nil,1)
    insetPaper:SetPoint("TOPLEFT",3,-3);insetPaper:SetPoint("BOTTOMRIGHT",-3,3)
    insetPaper:SetAtlas("Professions-QualityWindow-Background",false)
    insetPaper:SetVertexColor(.8,.72,.6,1)
    local scroll=CreateFrame("ScrollFrame","AndivalUISettingsScroll",panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",224,-130);scroll:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-26,194)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(650,410);scroll:SetScrollChild(content)
    panel.contentScroll=scroll
    panel.SetContentScroll=function(value)
        local height=scroll:GetHeight()or 320
        scroll:SetVerticalScroll(math.max(0,math.min(value,math.max(0,410-height))))
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(self,delta)panel.SetContentScroll((self:GetVerticalScroll()or 0)-delta*36)end)
    local function Page(id,name)
        local f=CreateFrame("Frame",name,content);f:SetPoint("TOPLEFT",content,"TOPLEFT",0,-40);f:SetSize(650,370);f:Hide();pages[id]=f;return f
    end
    local overview=Page("overview")
    local general=Page("general")
    local appearance=Page("appearance","AndivalUIAppearance")
    local previewPage=Page("preview")
    local profiles=Page("profiles","AndivalUIProfiles")
    local dock=CreateFrame("Frame","AndivalUIPreviewDock",panel);dock:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",224,59);dock:SetSize(650,116);Back(dock,.065,.045,.025,.85)
    Text(dock,T("ПРЕДПРОСМОТР","PREVIEW"),16,-12,300,"GameFontNormalSmall")
    local dockNote=Text(dock,"",16,-91,615,"GameFontDisableSmall")
    local parking=CreateFrame("Frame",nil,UIParent);parking:Hide()
    local footer=Text(panel,"",20,-617,600,"GameFontDisableSmall");footer:ClearAllPoints();footer:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",20,21)
    local function RestoreBars()
        for _,unit in ipairs(units)do
            local f=_G[frameNames[unit]];local saved=f and savedParents[f]
            if saved then f:SetParent(saved.parent);f:SetFrameStrata(saved.strata);if saved.level then f:SetFrameLevel(saved.level)end end
        end
        savedParents={}
        M.Layout();if ns.UnitCastbars then ns.UnitCastbars.Layout()end
    end
    Dock=function()
        if not panel:IsShown()or not previewOn or positioning or category=="profiles"then return end
        local chosen=selected
        for _,unit in ipairs(units)do
            local f=_G[frameNames[unit]]
            if f then
                if not savedParents[f]then savedParents[f]={parent=(f.GetParent and f:GetParent())or UIParent,strata=(f.GetFrameStrata and f:GetFrameStrata())or"MEDIUM",level=f.GetFrameLevel and f:GetFrameLevel()}end
                f:EnableMouse(false)
                if unit==chosen and ns.GetCastbarSettings(unit).enabled then
                    local d=ns.GetCastbarSettings(unit)
                    f:SetParent(dock);f:SetFrameStrata("DIALOG");f:SetFrameLevel((dock.GetFrameLevel and dock:GetFrameLevel()or 0)+3)
                    f:ClearAllPoints();f:SetPoint("CENTER",dock,"CENTER",14,-7);f:SetScale(math.min(d.scale,540/d.width))
                    if f.previewLabel then f.previewLabel:Hide()end
                else f:SetParent(parking)end
            end
        end
        dockNote:SetText(not ns.GetCastbarSettings(chosen).enabled and T("Полоса выключена. Включи её на вкладке «Основное» для теста.","This castbar is disabled. Enable it on General to preview it.") or mode=="esi" and T("Имитация передачи ESI: наша полоса скрыта. ESI не изменяется.","ESI handoff simulation: our bar is hidden. ESI is not changed.")or T("Демонстрационные данные - масштаб подогнан под область","Sample data - scaled to fit this preview area"))
    end
    Apply=function()
        M.Layout();M.Refresh();if ns.UnitCastbars then ns.UnitCastbars.Layout();ns.UnitCastbars.Refresh()end;Dock()
    end
    local function SetMode(value)
        mode=value;previewOn=true;if category=="profiles"then category=selected;tab="preview";RenderPage()end;if M.SetPreviewMode then M.SetPreviewMode(value)end;M.Preview(true);Dock()
        if Refresh then Refresh()end
    end
    -- Native radio menus show all choices at once; no click-to-cycle controls.
    local function Dropdown(parent,x,y,width,choices,get,set)
        local d=CreateFrame("DropdownButton",nil,parent,"WowStyle1DropdownTemplate");d:SetWidth(width);d:SetPoint("TOPLEFT",x,y)
        d:SetupMenu(function(_,root)
            local entries=type(choices)=="function"and choices()or choices
            for _,entry in ipairs(entries)do
                local radio=root:CreateRadio(entry[2],function(value)return get()==value end,function(value)if CanEdit()then set(value);d:GenerateMenu()end end,entry[1])
                if radio and radio.AddInitializer then
                    radio:AddInitializer(function(button)
                        if button.AttachTexture then
                            local background=button:AttachTexture()
                            background:SetColorTexture(.045,.045,.045,1)
                            background:SetAllPoints(button)
                            background:SetDrawLayer("BACKGROUND",-7)
                        end
                    end)
                end
            end
            if root.SetScrollMode then root:SetScrollMode(280)end
        end)
        d.Refresh=function()d:GenerateMenu()end;dropdowns[#dropdowns+1]=d;return d
    end
    local function Section(parent,label,y)
        local heading=Text(parent,label,0,y,630,"GameFontNormalLarge");heading:SetJustifyH("CENTER")
        local gap=math.min(450,math.max(150,#label*5))
        for _,side in ipairs({"LEFT","RIGHT"})do
            local line=parent:CreateTexture(nil,"ARTWORK");line:SetColorTexture(.58,.43,.18,.7)
            line:SetSize((630-gap)/2,1)
            line:SetPoint("TOP"..side,parent,"TOP"..side,side=="LEFT"and 0 or -20,y-10)
        end
    end
    Section(general,T("Основное","General"),32)
    Section(appearance,T("Оформление","Appearance"),32)
    Section(profiles,T("Профили","Profiles"),32)
    local function Check(key,label,description,y)
        local c=CreateFrame("CheckButton",nil,general,"UICheckButtonTemplate");c:SetPoint("TOPLEFT",0,y)
        local caption=Text(general,label,34,y-5,590,"GameFontHighlight")
        Text(general,description,34,y-24,590,"GameFontDisableSmall")
        c:SetScript("OnClick",function(self)if CanEdit()then ns.GetCastbarSettings(selected)[key]=self:GetChecked()and true or false;Apply()end end)
        controls[key]={control=c,caption=caption};return c
    end
    Check("enabled",T("Включить полосу","Enable castbar"),T("У каждой полосы собственные настройки и положение.","Each castbar has its own settings and position."),0)
    Check("icon",T("Иконка заклинания","Spell icon"),T("Щит несбиваемого заклинания сохраняется независимо от этой настройки.","A protected spell retains its shield independently of this option."),-48)
    Check("reducedMotion",T("Уменьшить анимацию","Reduced motion"),T("Без движущегося блика и плавных переходов.","Disable travelling highlights and animated transitions."),-96)
    local function Slider(key,label,min,max,step,x,y)
        Text(general,label,x,y,180,"GameFontNormalSmall")
        local valueText=Text(general,"",x+186,y,80)
        local c=CreateFrame("Slider",nil,general,"OptionsSliderTemplate");c:SetPoint("TOPLEFT",x+8,y-23);c:SetSize(260,17);c:SetMinMaxValues(min,max);c:SetValueStep(step);c:SetObeyStepOnDrag(true)
        c.Low:SetText(Decimal(min));c.High:SetText(Decimal(max));c.Text:SetText("")
        if c.GetRegions then for _,r in ipairs({c:GetRegions()})do if r~=c.Text and r~=c.Low and r~=c.High and r.GetObjectType and r:GetObjectType()=="FontString"then r:Hide()end end end
        c:SetScript("OnValueChanged",function(_,v)
            v=math.floor(v/step+.5)*step;valueText:SetText(Decimal(string.format(step<1 and"%.2f"or"%d",v)))
            if loading or not CanEdit()then return end;ns.GetCastbarSettings(selected)[key]=v;Apply()
        end);controls[key]={control=c,slider=true}
    end
    Slider("width",T("Ширина","Width"),140,500,1,0,-160)
    Slider("height",T("Высота","Height"),10,32,1,338,-160)
    Slider("scale",T("Масштаб","Scale"),.6,1.6,.05,0,-225)
    local latency=CreateFrame("CheckButton",nil,general,"UICheckButtonTemplate");latency:SetPoint("TOPLEFT",338,-227)
    local lc=Text(general,T("Зона сетевой задержки","Network latency zone"),372,-233,250)
    Text(general,T("Только для игрока.","Player only."),372,-253,250,"GameFontDisableSmall")
    latency:SetScript("OnClick",function(self)if CanEdit()and selected=="player"then ns.GetCastbarSettings(selected).latency=self:GetChecked()and true or false;Apply()end end)
    controls.latency={control=latency,caption=lc}
    local copyChoices=function()local out={};for _,u in ipairs(units)do if u~=selected then out[#out+1]={u,names[u]}end end;return out end
    Text(general,T("Взять оформление из","Copy appearance from"),0,-300,190)
    Dropdown(general,192,-295,190,copyChoices,function()return source end,function(value)source=value end)
    Button(general,T("Копировать","Copy"),392,-296,110,function()ns.CopyCastbarSettings(source,selected);Apply();Refresh()end)
    Button(general,T("Сбросить вид","Reset look"),512,-296,132,function()ns.ResetCastbarSettings(selected);Apply();Refresh()end)
    local appearanceControls={};appearance.controls=appearanceControls
    local function AppearanceRow(key,label,choices,y)
        Text(appearance,label,0,y-6,270,"GameFontHighlight")
        local d=Dropdown(appearance,288,y,350,choices,function()return ns.GetCastbarSettings(selected)[key]end,function(value)ns.GetCastbarSettings(selected)[key]=value;Apply()end)
        appearanceControls[key]={button=d,control=d,choices=choices}
    end
    AppearanceRow("font",T("Шрифт","Font"),{{"native",T("Шрифт WoW","WoW font")},{"chat",T("Шрифт чата","Chat font")}},0)
    AppearanceRow("fontSize",T("Размер текста","Text size"),{{0,T("Авто","Automatic")},{10,"10"},{11,"11"},{12,"12"},{14,"14"},{16,"16"},{18,"18"}},-44)
    AppearanceRow("texture",T("Текстура полосы","Bar texture"),{{"native",T("Классическая Blizzard","Classic Blizzard")},{"smooth",T("Ровная заливка","Smooth fill")}},-88)
    local palette={{"native",T("Родной цвет","Native color")},{"amber",T("Янтарный","Amber")},{"blue",T("Голубой","Blue")},{"teal",T("Бирюзовый","Teal")},{"violet",T("Фиолетовый","Violet")},{"white",T("Светлый металл","Pale metal")}}
    AppearanceRow("castColor",T("Цвет обычного каста","Cast color"),palette,-132)
    AppearanceRow("channelColor",T("Цвет ченнелинга","Channel color"),palette,-176)
    AppearanceRow("timeFormat",T("Формат таймера","Timer format"),{{"elapsed_total",T("Прошло / всего","Elapsed / total")},{"remaining",T("Осталось","Remaining")},{"elapsed",T("Прошло","Elapsed")},{"hidden",T("Скрыт","Hidden")}},-220)
    Text(appearance,T("Цвета декоративные, а не определение школы магии. Шрифты соответствуют языку клиента. Настройки сохраняются автоматически.","Colors are decorative, not spell-school detection. Fonts follow the client language. Changes are saved automatically."),0,-279,630,"GameFontDisableSmall")
    appearance.Refresh=function()if Refresh then Refresh()end end
    Section(previewPage,T("Проверка состояний","Test states"),0)
    Text(previewPage,T("Выбери состояние для настоящего рендера полосы в области ниже.","Choose a state to render the actual castbar in the preview below."),0,-30,630)
    Dropdown(previewPage,0,-65,340,modes,function()return mode end,SetMode)
    local previewToggle=CreateFrame("CheckButton",nil,previewPage,"UICheckButtonTemplate");previewToggle:SetPoint("TOPLEFT",370,-63)
    Text(previewPage,T("Включить тест","Enable preview"),404,-70,230)
    previewToggle:SetScript("OnClick",function(self)if CanEdit()then previewOn=self:GetChecked()and true or false;if not previewOn then RestoreBars()end;M.Preview(previewOn);Dock();Refresh()end end)
    local stateHint=Text(previewPage,"",0,-120,630)
    Text(previewPage,T("Это демонстрационные данные, не боевой тест. Тики ченнелинга не выдумываются. Тест ESI скрывает только нашу полосу, не изменяя ESI.","This uses sample data, not live combat. Channel ticks are not fabricated. The ESI test hides only our bar without changing ESI."),0,-174,630,"GameFontDisableSmall")
    for _,entry in ipairs(modes)do
        local id=entry[1];local b=CreateFrame("Button",nil,previewPage);b:SetText(entry[2]);b:SetScript("OnClick",function()if CanEdit()then SetMode(id)end end);b:Hide();panel.modeButtons[id]=b
    end
    Section(overview,T("Свой интерфейс, привычный WoW","Your layout. Familiar WoW."),0)
    Text(overview,T("Отдельные полосы игрока, цели, цели цели и фокуса. Настраивай оформление, проверяй состояния и сохраняй наборы для разных персонажей.","Independent player, target, target-of-target and focus castbars. Customize their appearance, preview states and save layouts for your characters."),0,-36,620,"GameFontHighlight")
    Section(overview,T("С чего начать","Get started"),-110)
    Text(overview,T("1. Выбери полосу слева.\n2. Настрой размер и оформление.\n3. Проверь анимации и расставь полосы в игре.","1. Select a castbar on the left.\n2. Adjust its size and appearance.\n3. Test animations and position the bars in game."),0,-145,610)
    Section(overview,T("Совместимость","Compatibility"),-234)
    Text(overview,T("Enhanced Soft Interact сохраняет взаимодействия с предметами. Если Quartz управляет той же полосой, Andival UI уступает ему. Фокус изначально выключен.","Enhanced Soft Interact keeps object interactions. If Quartz owns the same castbar, Andival UI yields to it. Focus starts disabled."),0,-266,620,"GameFontDisableSmall")
    local positionBar=CreateFrame("Frame","AndivalUIPositionToolbar",UIParent,"BasicFrameTemplateWithInset")
    positionBar:SetSize(570,92);positionBar:SetPoint("TOP",UIParent,"TOP",0,-50);positionBar:SetFrameStrata("DIALOG")
    positionBar.TitleText:SetText(T("Расположение полос","Position castbars"))
    Text(positionBar,T("Перетаскивай тестовые полосы. Положение сохраняется.","Drag the preview bars. Positions are saved."),16,-37,390)
    EndPosition=function(reopen)
        if not positioning then return end
        positioning=false;M.Preview(false);RestoreBars();positionBar:Hide()
        if reopen and not InCombatLockdown()then panel:Show()end
    end
    Button(positionBar,T("Готово","Done"),420,-36,130,function()EndPosition(true)end)
    positionBar:SetScript("OnHide",function()if positioning then EndPosition(false)end end);positionBar:Hide();table.insert(UISpecialFrames,"AndivalUIPositionToolbar")
    local function BeginPosition()
        if not CanEdit()then return end
        positioning=true;RestoreBars();panel:Hide();M.Preview(true);positionBar:Show()
    end
    Button(previewPage,T("Расставить полосы в игре","Position bars in game"),0,-267,300,BeginPosition)
    Button(dock,T("Расположение…","Position…"),477,-8,156,BeginPosition)
    -- Profiles share the same content area instead of opening another window.
    local chosen,pendingDelete="Default",nil
    local profileStatus=Text(profiles,"",0,-310,630,"GameFontHighlightSmall")
    local function Error(ok,code)
        local messages={invalid=T("Имя: 1–32 символа, без | и управляющих знаков.","Use 1–32 characters, without | or control characters."),exists=T("Такое имя уже существует.","That name already exists."),reserved=T("Это имя зарезервировано.","That name is reserved."),protected=T("Базовый профиль нельзя удалить или переименовать.","The default profile cannot be deleted or renamed."),notready=T("Дождись загрузки персонажа.","Wait for your character to load."),combat=T("Недоступно в бою.","Unavailable in combat."),missing=T("Профиль не найден.","Profile not found.")}
        profileStatus:SetText(ok and T("Сохранено.","Saved.")or messages[code]or T("Действие не выполнено.","Action could not be completed."));return ok
    end
    Text(profiles,T("Сохранённый профиль","Saved profile"),0,-6,240,"GameFontHighlight")
    local profileDrop=Dropdown(profiles,255,0,383,function()local out={};for _,name in ipairs(ns.Profiles.List())do out[#out+1]={name,ProfileName(name)}end;return out end,function()return chosen end,function(value)chosen=value;pendingDelete=nil;Refresh()end)
    Text(profiles,T("Выбор сохраняется отдельно для этого персонажа.","The selected profile is remembered for this character."),0,-45,630,"GameFontDisableSmall")
    local function RefreshActive()M.Preview(false);RestoreBars();Apply();if previewOn and category~="profiles"then M.Preview(true);Dock()end;Refresh()end
    Button(profiles,T("Использовать выбранный","Use selected profile"),0,-75,280,function()if Error(ns.Profiles.Switch(chosen))then RefreshActive()end end)
    Text(profiles,T("Новое имя","New name"),0,-125,240,"GameFontHighlight")
    local nameBox=CreateFrame("EditBox","AndivalUIProfileName",profiles,"InputBoxTemplate");nameBox:SetSize(370,26);nameBox:SetPoint("TOPLEFT",262,-119);nameBox:SetAutoFocus(false);nameBox:SetMaxLetters(32)
    nameBox:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);nameBox:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    local function CreateProfile(copy)
        local ok,name;if copy then ok,name=ns.Profiles.Copy(chosen,nameBox:GetText())else ok,name=ns.Profiles.Create(nameBox:GetText())end
        if Error(ok,name)then chosen=name;pendingDelete=nil;local switched,why=ns.Profiles.Switch(name);if switched then RefreshActive()else Error(false,why)end;nameBox:SetText("");Refresh()end
    end
    Button(profiles,T("Создать из базового","New from default"),0,-164,202,function()CreateProfile(false)end)
    Button(profiles,T("Копия выбранного","Duplicate selected"),218,-164,202,function()CreateProfile(true)end)
    local rename=Button(profiles,T("Переименовать","Rename"),436,-164,202,function()local ok,name=ns.Profiles.Rename(chosen,nameBox:GetText());if Error(ok,name)then chosen=name;pendingDelete=nil;nameBox:SetText("");Refresh()end end)
    local delete=Button(profiles,T("Удалить профиль…","Delete profile…"),0,-215,202,function()pendingDelete=chosen;Refresh()end)
    local confirmation=Text(profiles,"",0,-254,630)
    local confirm=Button(profiles,T("Да, удалить","Yes, delete"),320,-280,150,function()if pendingDelete then local ok,why=ns.Profiles.Delete(pendingDelete,true);pendingDelete=nil;if Error(ok,why)then chosen=ns.Profiles.Current();RefreshActive()end;Refresh()end end)
    local cancel=Button(profiles,T("Отмена","Cancel"),486,-280,152,function()pendingDelete=nil;Refresh()end)
    profiles.nameBox=nameBox;profiles.rows={};profiles.Refresh=function()Refresh()end
    RenderPage=function()
        for _,f in pairs(pages)do f:Hide()end
        local id=names[category]and tab or category;pages[id]:Show();scroll:SetVerticalScroll(0)
        -- Keep navigation geometry authoritative after page/layout transitions.
        for id,b in pairs(nav)do b:ClearAllPoints();b:SetPoint("TOPLEFT",sidebar,"TOPLEFT",5,b.rowY);b.active:SetShown(category==id)end
        for id,b in pairs(tabs)do b:SetShown(names[category]~=nil);b:SetEnabled(tab~=id)end
        title:SetText(category=="overview"and T("Обзор","Overview")or category=="profiles"and T("Профили","Profiles")or names[selected])
        subtitle:SetText(category=="profiles"and T("Наборы настроек для персонажей и разных задач.","Saved configurations for your characters and activities.")or category=="overview"and T("Настрой полосы так, чтобы они стали частью твоего интерфейса.","Make your castbars feel like part of your interface.")or T("Независимые настройки выбранной полосы.","Independent settings for the selected castbar."))
        dock:SetShown(category~="profiles")
        if category=="profiles"then M.Preview(false);RestoreBars()elseif previewOn then M.Preview(true);Dock()end
        Refresh()
    end
    local categories={{"overview",T("Обзор","Overview")},{"player",names.player},{"target",names.target},{"targettarget",names.targettarget},{"focus",names.focus},{"profiles",T("Профили","Profiles")}}
    local rowPositions={-82,-124,-166,-208,-250,-292}
    for i,entry in ipairs(categories)do
        local id=entry[1];local rowY=rowPositions[i];local b=CreateFrame("Button","AndivalUISettingsNav"..id,sidebar);b.rowY=rowY;b:SetSize(178,36);b:ClearAllPoints();b:SetPoint("TOPLEFT",sidebar,"TOPLEFT",5,rowY)
        local active=b:CreateTexture(nil,"BACKGROUND");active:SetAllPoints();active:SetAtlas("Options_List_Active",false);active:Hide();b.active=active
        local hover=b:CreateTexture(nil,"HIGHLIGHT");hover:SetAllPoints();hover:SetAtlas("Options_List_Hover",false)
        Text(b,entry[2],14,-10,156,"GameFontHighlight")
        b:SetScript("OnClick",function()if CanEdit()then category=id;if names[id]then selected=id;if source==selected then source=selected=="player"and"target"or"player"end end;pendingDelete=nil;RenderPage()end end);nav[id]=b
    end
    for i,entry in ipairs({{"general",T("Основное","General")},{"appearance",T("Оформление","Appearance")},{"preview",T("Тест состояний","Preview")}})do
        local id=entry[1];tabs[id]=Button(panel,entry[2],224+(i-1)*216,-92,208,function()tab=id;RenderPage()end)
    end
    local savedLabel=Text(sidebar,T("Сохраняется автоматически","Saved automatically"),16,-508,160,"GameFontDisableSmall");savedLabel:ClearAllPoints();savedLabel:SetPoint("BOTTOMLEFT",sidebar,"BOTTOMLEFT",16,36)
    local slashLabel=Text(sidebar,"/aui",16,-535,160,"GameFontNormalSmall");slashLabel:ClearAllPoints();slashLabel:SetPoint("BOTTOMLEFT",sidebar,"BOTTOMLEFT",16,13)
    Refresh=function()
        loading=true;panel.selectedUnit=selected;panel.selectedCategory=category;panel.selectedTab=tab
        local d=ns.GetCastbarSettings(selected)
        for key,row in pairs(controls)do if row.slider then row.control:SetValue(d[key])else row.control:SetChecked(d[key]and true or false)end end
        latency:SetEnabled(selected=="player");lc:SetTextColor(selected=="player"and 1 or .45,selected=="player"and 1 or .45,selected=="player"and 1 or .45)
        previewToggle:SetChecked(previewOn);for _,dropdown in ipairs(dropdowns)do dropdown:GenerateMenu()end
        stateHint:SetText(mode=="protected"and T("Щит виден на цели, цели цели и фокусе. На полосе игрока он не используется.","The shield is used on target, target-of-target and focus, not the player bar.")or mode=="delayed"and T("Тест показывает поправку времени +0,3 и плавное изменение прогресса.","The test shows a +0.3 timing correction and a smooth progress adjustment.")or T("Полоса ниже использует настоящий код отрисовки аддона.","The bar below uses the addon's actual rendering code."))
        rename:SetEnabled(chosen~="Default");delete:SetEnabled(chosen~="Default")
        confirmation:SetText(pendingDelete and(T("Удалить «","Delete “")..ProfileName(pendingDelete)..T("»? Связанные персонажи перейдут на базовый профиль.","”? Linked characters will use the default profile."))or"")
        confirm:SetShown(pendingDelete~=nil);cancel:SetShown(pendingDelete~=nil)
        footer:SetText(T("Активный профиль: ","Active profile: ")..ProfileName(ns.Profiles.Current())..T("   -   Настройки вне боя","   -   Settings are available out of combat"))
        loading=false
    end
    local doneButton=Button(panel,T("Готово","Done"),750,-608,124,function()panel:Hide()end);doneButton:ClearAllPoints();doneButton:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-26,16)
    panel.SelectUnit=function(unit)if CanEdit()and names[unit]then selected=unit;category=unit;if source==selected then source=selected=="player"and"target"or"player"end;RenderPage()end end
    panel.SelectCategory=function(id)if CanEdit()and nav[id]then category=id;if names[id]then selected=id;if source==selected then source=selected=="player"and"target"or"player"end end;RenderPage()end end
    panel.SelectTab=function(id)if CanEdit()and tabs[id]then category=selected;tab=id;RenderPage()end end
    panel.ShowAppearance=function()panel.SelectTab("appearance")end
    panel.ShowProfiles=function()if CanEdit()then category="profiles";chosen=ns.Profiles.Current();RenderPage()end end
    panel.SetTestMode=function(value)if CanEdit()and panel.modeButtons[value]then SetMode(value)end end
    panel.RefreshControls=Refresh;panel.DockPreview=Dock;panel.RestorePreview=RestoreBars
    panel.SelectPage=panel.SelectCategory
    panel.SetPreviewVisible=function(on)
        if not CanEdit()then return end
        previewOn=on and true or false
        if not previewOn then RestoreBars()end
        M.Preview(previewOn and category~="profiles");Dock();Refresh()
    end
    panel.BeginPosition=BeginPosition;panel.EndPosition=EndPosition
    panel.BeginPositioning=BeginPosition;panel.EndPositioning=EndPosition
    panel.GetPreviewState=function()return {enabled=previewOn,positioning=positioning,mode=mode,docked=next(savedParents)~=nil,unit=selected}end
    local function Fit()
        local w=UIParent.GetWidth and UIParent:GetWidth()or 1000;local h=UIParent.GetHeight and UIParent:GetHeight()or 750
        local windowHeight=math.max(500,math.min(650,h-24))
        panel:SetHeight(windowHeight)
        panel:SetScale(math.max(.1,math.min(1,(w-24)/900,(h-24)/windowHeight)))
    end
    panel:SetScript("OnShow",function()if positioning then EndPosition(false)end;if not CanEdit()then return end;ns.InitCastbarSettings();Fit();chosen=ns.Profiles.Current();pendingDelete=nil;RenderPage()end)
    panel:SetScript("OnHide",function()
        panel:StopMovingOrSizing();pendingDelete=nil;nameBox:ClearFocus();RestoreBars()
        if not positioning then M.Preview(false)end
    end)
    panel:RegisterEvent("PLAYER_REGEN_DISABLED");panel:RegisterEvent("DISPLAY_SIZE_CHANGED");panel:RegisterEvent("UI_SCALE_CHANGED")
    panel:SetScript("OnEvent",function(_,event)if event=="PLAYER_REGEN_DISABLED"then EndPosition(false);panel:Hide();RestoreBars();M.Preview(false)elseif panel:IsShown()then Fit();Dock()end end)
    panel:Hide();table.insert(UISpecialFrames,"AndivalUISettings")
end
SLASH_ANDIVALUI1="/aui";SLASH_ANDIVALUI2="/acast"
SlashCmdList.ANDIVALUI=function(message)
    if message=="status"then M.Status();return end
    if InCombatLockdown()then M.Say(T("Открой настройки вне боя.","Open settings out of combat."));return end
    if panel then panel:SetShown(not panel:IsShown())end
end
