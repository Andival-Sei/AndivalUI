local ns = {}
local frames = {}
local Frame = {}
local function noop() end
function Frame:StopMovingOrSizing() self.stoppedMoving=true end
function Frame:SetSize(w,h) self.width=w;self.height=h end
function Frame:SetWidth(v) self.width=v end
function Frame:SetHeight(v) self.height=v end
function Frame:GetWidth() return self.width or 1920 end
function Frame:GetHeight() return self.height or 1080 end
function Frame:SetParent(v) self.parent=v end
function Frame:GetParent() return self.parent end
function Frame:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Frame:EnableMouse(v) self.mouseEnabled=v end
function Frame:IsMouseEnabled() return self.mouseEnabled end
function Frame:SetEnabled(v) self.enabled=v end
function Frame:IsEnabled() return self.enabled~=false end
function Frame:GetFrameLevel() return self.frameLevel or 1 end
function Frame:SetFrameLevel(v) self.frameLevel=v end
function Frame:GetPoint() return table.unpack(self.point or {}) end

local function new(parent)
  local f = {parent=parent,shown=true,alpha=1,scripts={},events={}}
  return setmetatable(f,{__index=function(t,k) return Frame[k] or (k:match("^[A-Z]") and noop or nil) end})
end
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:GetScript(k) return self.scripts[k] end
function Frame:RegisterEvent(e) self.events[e]=true end
function Frame:RegisterUnitEvent(e) self.events[e]=true end
function Frame:UnregisterEvent(e) self.events[e]=nil end
function Frame:Show() local changed=not self.shown; self.shown=true; if changed and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:Hide() local changed=self.shown; self.shown=false; if changed and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Frame:SetShown(v) if v then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:GetAlpha() return self.alpha end
function Frame:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function Frame:GetMinMaxValues() return self.minimum or 0,self.maximum or 1 end
function Frame:GetValue() return self.value or 0 end
function Frame:GetEffectiveAlpha() return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1) end
function Frame:SetAlpha(v) self.alpha=v end
function Frame:SetStatusBarTexture(path)
  assert(path:match("^Interface"), "statusbar must start with a real texture path")
  self.statusbarTexture = new(self)
end
function Frame:GetStatusBarTexture() return self.statusbarTexture end
function Frame:SetAtlas(atlas) self.atlas = atlas end
function Frame:GetAtlas() return self.atlas end
function Frame:SetTexture(path) self.texturePath=path;self.atlas=nil end
function Frame:SetStatusBarColor(r,g,b) self.color={r,g,b} end
function Frame:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function Frame:SetText(v) self.textValue=v end
function Frame:GetText() return self.textValue or '' end
function Frame:SetTitle(v) if self.TitleText then self.TitleText:SetText(v) end end
function Frame:SetVerticalScroll(v) self.verticalScroll=v end
function Frame:GetVerticalScroll() return self.verticalScroll or 0 end
function Frame:SetupMenu(fn) self.menuGenerator=fn end
function Frame:GenerateMenu()
  if not self.menuGenerator then return end
  local root={entries={}}
  function root:CreateRadio(label,selected,callback,value) local item={label=label,selected=selected,callback=callback,value=value};function item:AddInitializer(fn) self.initializer=fn end;self.entries[#self.entries+1]=item;return item end
  function root:SetScrollMode() end
  self.menuGenerator(self,root);self.menuItems=root.entries
end
function Frame:SetFormattedText(f,v) self.textValue=string.format(f,v) end
function Frame:CreateMaskTexture() return new(self) end
function Frame:AddMaskTexture(mask) self.mask=mask end
function Frame:CreateTexture() return new(self) end
function Frame:CreateFontString() return new(self) end
function Frame:SetPoint(...) self.point={...} end
function Frame:SetScale(v) self.scale=v end
function Frame:GetScale() return self.scale or 1 end
function Frame:GetCenter() return 960,540 end
function Frame:SetChecked(v) self.checked=v end
function Frame:GetChecked() return self.checked end
function CreateFrame(kind,name,parent,template)
  local f=new(parent); frames[#frames+1]=f
  if name then _G[name]=f end
  if template=='BasicFrameTemplateWithInset' or template=='PortraitFrameTemplate' then f.TitleText=new(f) end
  if template=='UICheckButtonTemplate' then f.text=new(f) end
  if template=='InsetFrameTemplate' then f.Bg=new(f) end
  if template=='OptionsSliderTemplate' then f.Text=new(f);f.Low=new(f);f.High=new(f) end
  return f
end
UIParent=new(); UISpecialFrames={}; SlashCmdList={}; unpack=table.unpack
PlayerCastingBarFrame=new(UIParent)
local unitCasts,unitChannels={},{}
function UnitExists(unit) return unit=="player" or unitCasts[unit]~=nil or unitChannels[unit]~=nil end
local time=100; local current; local channel; local restricted={}
function GetTime() return time end
local characterName='TestPlayer'
function UnitName() return characterName end
function GetRealmName() return 'TestRealm' end
function GetLocale() return os.getenv('TEST_LOCALE') or 'ruRU' end
function GetNetStats() return 0,0,50,100 end
function InCombatLockdown() return false end
function issecretvalue(v) return v==restricted end
local castReads=0
function UnitCastingInfo(unit) castReads=castReads+1;local c=unit=='player' and current or unitCasts[unit];if c then return c.name,'',135920,c.start,c.finish,false,c.guid,c.blocked,1 end end
function UnitChannelInfo(unit) local c=unit=='player' and channel or unitChannels[unit];if c then return c.name,'',135920,c.start,c.finish,false,c.blocked,1 end end
local function fire(e,...)
  PlayerCastingBarFrame.casting=current~=nil;PlayerCastingBarFrame.channeling=channel~=nil
  for _,f in ipairs(frames) do if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f,e,...) end end
end
local function tick(t) time=t; for _,f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,.02) end end end
local function load(path) assert(loadfile(path))('AndivalUI',ns) end
load('Core.lua'); load('Modules/CastbarLogic.lua');load('Modules/CastbarMotion.lua');load('Modules/CastbarAppearance.lua');load('Modules/CastbarDuration.lua');load('Modules/CastbarCrafting.lua'); load('Integrations/EnhancedSoftInteract.lua'); load('Modules/Castbar.lua');load('Modules/UnitCastbars.lua');load('Settings.lua')
fire('ADDON_LOADED','AndivalUI')
local count=0
local function ok(value,label) assert(value,label); count=count+1; print('PASS '..label) end
ok(ns.modules.Castbar ~= nil,'registered castbar module')
ok(AndivalUIDB.schema==1 and AndivalUIDB.castbar.width==280,'isolated default settings')
current={name='Holy Light',start=100000,finish=103000,guid='a'}; PlayerCastingBarFrame.casting=true
fire('UNIT_SPELLCAST_START','player','a'); tick(101)
ok(AndivalUICastbarFrame:IsShown(),'spell is displayed')
ok(AndivalUICastbarFrame.bar:GetStatusBarTexture().mask==AndivalUICastbarFrame.fillMask,'rounded fill mask attached')
ok(AndivalUICastbarFrame.latency.mask==AndivalUICastbarFrame.fillMask,'latency follows same rounded silhouette')
ok(AndivalUICastbarFrame.finishGlow.mask==AndivalUICastbarFrame.fillMask,'success bloom clipped to rounded silhouette')
ok(AndivalUICastbarFrame.bar.color[2]==.78,'clean classic fill retains warm cast color')
ok(PlayerCastingBarFrame:GetAlpha()==0,'native duplicate hidden')
local p=AndivalUICastbarFrame.bar.value; ok(p>.32 and p<.34,'accurate cast progress')
fire('UNIT_SPELLCAST_STOP','player','old'); ok(AndivalUICastbarFrame:IsShown(),'stale stop ignored')
EnhancedSoftInteractDB={enabled=true,castBarEnabled=true}; EnhancedSoftInteractHUD=new(UIParent);EnhancedSoftInteractHUD.castBar=new(EnhancedSoftInteractHUD)
tick(101.1);ok(not AndivalUICastbarFrame:IsShown(),'visible ESI owns interaction')
EnhancedSoftInteractHUD:Hide();tick(101.2);ok(AndivalUICastbarFrame:IsShown(),'hidden ESI restores fallback')
EnhancedSoftInteractHUD:Show();EnhancedSoftInteractHUD.inEditMode=true;tick(101.3);ok(AndivalUICastbarFrame:IsShown(),'ESI preview never suppresses spell')
EnhancedSoftInteractHUD.inEditMode=nil;EnhancedSoftInteractHUD.castBar:SetAlpha(0);tick(101.4);ok(AndivalUICastbarFrame:IsShown(),'transparent ESI does not eat cast')
EnhancedSoftInteractHUD.castBar:SetAlpha(1);tick(101.5);current=nil;fire('UNIT_SPELLCAST_SUCCEEDED','player','a');ok(not AndivalUICastbarFrame:IsShown(),'ESI completion does not duplicate outcome')
EnhancedSoftInteractHUD.castBar:Hide();EnhancedSoftInteractHUD.castFinish=new(EnhancedSoftInteractHUD)
current={name='Holy Light',start=102000,finish=105000,guid='b'};time=102;fire('UNIT_SPELLCAST_START','player','b');ok(AndivalUICastbarFrame:IsShown(),'new spell not hidden by old ESI finish')
current=nil;fire('UNIT_SPELLCAST_INTERRUPTED','player','b');ok(AndivalUICastbarFrame.timer.textValue==(GetLocale()=='ruRU' and 'Прервано' or 'Interrupted'),'interrupt feedback');tick(103);ok(not AndivalUICastbarFrame:IsShown(),'interrupt fades out')
channel={name='Channel',start=103000,finish=107000};fire('UNIT_SPELLCAST_CHANNEL_START','player');fire('UNIT_SPELLCAST_SUCCEEDED','player');tick(104);ok(AndivalUICastbarFrame.bar.value==.75,'channel drains correctly');channel=nil;fire('UNIT_SPELLCAST_CHANNEL_STOP','player');tick(105)
current={name='Secret',start=restricted,finish=restricted,guid='s'};fire('UNIT_SPELLCAST_START','player','s');ok(not AndivalUICastbarFrame:IsShown(),'restricted timing falls back safely')
current=nil;SlashCmdList.ANDIVALUI('');ok(AndivalUISettings:IsShown() and AndivalUICastbarFrame:IsShown(),'settings live preview');AndivalUISettings:Hide();ok(not AndivalUICastbarFrame:IsShown(),'closing preview leaves no phantom bar')
AndivalUIDB.castbar.enabled=false;current={name='Disabled',start=105000,finish=108000,guid='c'};fire('UNIT_SPELLCAST_START','player','c');ok(not AndivalUICastbarFrame:IsShown(),'disabled module stays hidden')
AndivalUIDB.castbar.enabled=true
LibStub=function() return {GetAddon=function() return {GetModule=function() return {IsEnabled=function() return true end} end} end} end
tick(105.1);ok(not AndivalUICastbarFrame:IsShown(),'active Quartz Player remains sole owner')
LibStub=nil;tick(105.2);ok(AndivalUICastbarFrame:IsShown(),'disabled Quartz restores our castbar')
-- Delayed casts retain ESI ownership even after its HUD has disappeared.
current={name='Gather',start=106000,finish=109000,guid='g'};time=106
EnhancedSoftInteractHUD.castBar:Show();fire('UNIT_SPELLCAST_START','player','g');tick(106.1)
EnhancedSoftInteractHUD.castBar:Hide();fire('UNIT_SPELLCAST_DELAYED','player','g');current=nil
fire('UNIT_SPELLCAST_SUCCEEDED','player','g');ok(not AndivalUICastbarFrame:IsShown(),'delayed cast retains ESI completion ownership')
current={name='Spell',start=107000,finish=110000,guid='h'};time=107;fire('UNIT_SPELLCAST_START','player','h');tick(108)
fire('UNIT_SPELLCAST_STOP','player','h');current=nil;fire('UNIT_SPELLCAST_SUCCEEDED','player','h')
ok(AndivalUICastbarFrame.bar.color[2]==.86,'STOP before success still renders completion')
channel={name='Channel',start=109000,finish=113000};time=109;fire('UNIT_SPELLCAST_CHANNEL_START','player','chan')
fire('UNIT_SPELLCAST_INTERRUPTED','player','h');tick(110)
ok(AndivalUICastbarFrame.bar.value==.75,'old spell event cannot end new channel')
channel=nil;fire('UNIT_SPELLCAST_CHANNEL_STOP','player','chan');tick(114)
current={name='Preview overlap',start=114000,finish=117000,guid='preview'};time=114;fire('UNIT_SPELLCAST_START','player','preview')
SlashCmdList.ANDIVALUI('');ok(PlayerCastingBarFrame:GetAlpha()==1,'preview releases native castbar ownership')
fire('PLAYER_REGEN_DISABLED');ok(not AndivalUISettings:IsShown(),'combat closes settings and preview')
time=120;current={name='Animated',start=120000,finish=123000,guid='motion'};fire('UNIT_SPELLCAST_START','player','motion');tick(120.5)
local glowAlpha=AndivalUICastbarFrame.flow:GetAlpha()
ok(AndivalUICastbarFrame.flow:IsShown(),'subtle internal light enabled')
tick(121);ok(AndivalUICastbarFrame.flow:GetAlpha()~=glowAlpha,'internal illumination evolves with time')
AndivalUIDB.castbar.reducedMotion=true;tick(121.1);ok(not AndivalUICastbarFrame.flow:IsShown(),'reduced motion disables internal animation')
AndivalUIDB.castbar.reducedMotion=false;current=nil;fire('UNIT_SPELLCAST_SUCCEEDED','player','motion');tick(121.3)
ok(AndivalUICastbarFrame.finishGlow:IsShown() and AndivalUICastbarFrame.finishGlow:GetAlpha()>0,'success blooms gently before fading')
current={name='Interrupted',start=122000,finish=125000,guid='extinguish'};time=122;fire('UNIT_SPELLCAST_START','player','extinguish');tick(123);current=nil;fire('UNIT_SPELLCAST_INTERRUPTED','player','extinguish');tick(123.25)
ok(not AndivalUICastbarFrame.finishGlow:IsShown() and not AndivalUICastbarFrame.flow:IsShown(),'interruption extinguishes all light')
ok(AndivalUICastbarFrame:GetAlpha()>.6 and AndivalUICastbarFrame:GetAlpha()<.9,'interruption fades gently without full-bar success')
time=130;current=nil;channel=nil
unitCasts.target={name='Fireball',start=130000,finish=133000,blocked=false};fire('PLAYER_TARGET_CHANGED');ns.UnitCastbars.Refresh()
ok(AndivalUITargetCastbar:IsShown(),'target cast displayed')
ok(not AndivalUITargetCastbar.shield:IsShown(),'interruptible cast has no shield')
unitCasts.target.blocked=true;ns.UnitCastbars.Refresh();ok(AndivalUITargetCastbar.shield:IsShown(),'confirmed protected spell shows shield')
unitCasts.target.blocked=restricted;ns.UnitCastbars.Refresh();ok(not AndivalUITargetCastbar.shield:IsShown(),'secret interruptibility never produces shield')
unitCasts.target.start=restricted;ns.UnitCastbars.Refresh();ok(not AndivalUITargetCastbar:IsShown(),'restricted target timing hides custom bar')
unitCasts.target=nil;unitChannels.targettarget={name='Beam',start=130000,finish=134000,blocked=false};time=131;ns.UnitCastbars.Refresh()
ok(AndivalUITargetTargetCastbar.bar.value==.75,'target-of-target channel drains')
ok(AndivalUITargetTargetCastbar.bar.color[2]==.88,'channel uses distinct green color')
unitChannels.targettarget=nil;fire('UNIT_TARGET','target');ok(not AndivalUITargetTargetCastbar:IsShown(),'target-of-target change clears stale bar')
AndivalUIDB.unitcastbars.target.enabled=false;unitCasts.target={name='Disabled',start=131000,finish=134000};ns.UnitCastbars.Refresh();ok(not AndivalUITargetCastbar:IsShown(),'target toggle respected')
AndivalUIDB.unitcastbars.target.enabled=true;ns.UnitCastbars.Preview(true);ok(AndivalUITargetCastbar:IsShown() and AndivalUITargetTargetCastbar:IsShown(),'unit previews display both bars');ns.UnitCastbars.Preview(false)
TargetFrameSpellBar=new(UIParent);TargetFrameSpellBar:SetAlpha(.8)
ns.UnitCastbars.Refresh();ok(TargetFrameSpellBar:GetAlpha()==0,'owns native target alpha only while custom target shown')
unitCasts.target.start=restricted;ns.UnitCastbars.Refresh();ok(TargetFrameSpellBar:GetAlpha()==.8,'restricted target fallback restores previous native alpha')
unitCasts.target.start=131000
LibStub=function() return {GetAddon=function() return {GetModule=function(_,name) return {IsEnabled=function() return name=='Target' end} end} end} end
ns.UnitCastbars.Refresh();ok(not AndivalUITargetCastbar:IsShown(),'Quartz Target owner is respected')
LibStub=nil;ns.UnitCastbars.Refresh();ok(AndivalUITargetCastbar:IsShown(),'target resumes when competing owner disabled')
AndivalUIDB.castbar.icon=true;AndivalUIDB.unitcastbars.target.icon=true;AndivalUIDB.unitcastbars.targettarget.icon=true;ns.Castbar.Layout()
ok(AndivalUICastbarFrame.iconFrame:IsShown() and AndivalUITargetCastbar.iconFrame:IsShown() and AndivalUITargetTargetCastbar.iconFrame:IsShown(),'native icon frames follow enabled icons across all bars')
ok(AndivalUITargetCastbar.shield.point[1]=='CENTER' and AndivalUITargetCastbar.shield.point[2]==AndivalUITargetCastbar.icon,'shield surrounds spell icon rather than separate badge')
AndivalUIDB.castbar.icon=false;AndivalUIDB.unitcastbars.target.icon=false;AndivalUIDB.unitcastbars.targettarget.icon=false;ns.Castbar.Layout()
ok(not AndivalUICastbarFrame.iconFrame:IsShown() and not AndivalUITargetCastbar.iconFrame:IsShown() and not AndivalUITargetTargetCastbar.iconFrame:IsShown(),'icon toggle hides all corresponding frames')
ok(AndivalUITargetCastbar.shield.point[2]==AndivalUITargetCastbar.icon,'shield stays anchored around icon regardless of toggle')
ok(AndivalUITargetCastbar.shield:GetAtlas()=='ui-castingbar-shield','uses modern native filled shield atlas')
unitCasts.target.blocked=true;ns.UnitCastbars.Refresh()
ok(AndivalUITargetCastbar.shield:IsShown() and AndivalUITargetCastbar.shieldIcon:IsShown() and not AndivalUITargetCastbar.icon:IsShown() and not AndivalUITargetCastbar.iconFrame:IsShown(),'protected cast keeps icon inside shield and removes duplicate square rim')
ok(AndivalUITargetCastbar.shieldIcon.mask==AndivalUITargetCastbar.shieldMask,'protected art clips to shield contour')
unitCasts.target.blocked=false;ns.UnitCastbars.Refresh()
ok(AndivalUITargetCastbar.icon.width==20,'ordinary icon size restored after protected cast')
ok(not AndivalUITargetCastbar.shieldIcon:IsShown(),'shield artwork disappears for interruptible spell')
ok(ns.CastbarLogic.TimerText(10,15,11.2,false)=='1.2 / 5.0','timer reports elapsed over total')
ok(ns.CastbarLogic.TimerText(10,15,11.2,true)=='1,2 / 5,0','Russian decimal commas')
ok(ns.CastbarLogic.TimerText(10,15,9,false)=='0.0 / 5.0','timer clamps before start')
ok(ns.CastbarLogic.TimerText(10,15,16,false)=='5.0 / 5.0','timer clamps after finish')
ns.Castbar.Preview(true);ns.UnitCastbars.Preview(true)
ok(AndivalUICastbarFrame.timer.textValue:find(' / ',1,true)~=nil,'player preview uses elapsed total timer')
ok(AndivalUITargetCastbar.timer.textValue==AndivalUITargetTargetCastbar.timer.textValue,'cast and channel elapsed timers share direction')
local L=ns.CastbarLogic
local before={startTime=10,endTime=15,channel=false}
local after={startTime=10,endTime=15.3,channel=false}
L.Retime(before,after,12)
ok(math.abs(L.DisplayProgress(after,12,false)-.4)<.0001,'delay correction starts without visual jump')
ok(math.abs(L.DisplayProgress(after,12.2,false)-L.Progress(10,15.3,12.2,false))<.0001,'delay smoothing converges to authoritative timing')
ok(L.DelayLabel(after,12,true)=='+0,3','confirmed pushback label uses signed localized seconds')
ok(L.DelayLabel(after,14,true)=='','delay indicator expires')
ok(L.DisplayProgress(after,12,true)==L.Progress(10,15.3,12,false),'reduced motion shows exact correction immediately')
local oldChannel={startTime=10,endTime=15,channel=true}
local cutChannel={startTime=10,endTime=14.7,channel=true}
L.Retime(oldChannel,cutChannel,12)
ok(L.DelayLabel(cutChannel,12,false)=='-0.3','channel shortening is not mislabeled added latency')
local target=ns.GetCastbarSettings('target');local player=ns.GetCastbarSettings('player')
local oldWidth=target.width;player.width=350;ns.InitCastbarSettings()
ok(target.width==oldWidth,'migration never reapplies inherited player width')
target.enabled=false;target.x=31;target.y=-91
ok(ns.CopyCastbarSettings('player','target'),'copy profile succeeds')
ok(target.width==350 and target.enabled==false and target.x==31 and target.y==-91,'copy preserves destination position and enabled state')
target.width=250;ok(player.width==350,'copied profile is independent')
ns.ResetCastbarSettings('target');ok(target.x==31 and not target.enabled,'appearance reset preserves position and enable')
for _,mode in ipairs({'cast','channel','success','interrupted','delayed','protected'}) do
 ns.Castbar.SetPreviewMode(mode);ns.Castbar.Preview(true)
 ok(AndivalUICastbarFrame:IsShown(),'preview state '..mode)
end
ns.Castbar.SetPreviewMode('esi');ok(not AndivalUICastbarFrame:IsShown(),'ESI demo suppresses only our test bar')
ns.Castbar.Preview(false);ns.Castbar.SetPreviewMode('sequence')
ns.Castbar.SetPreviewMode('interrupted');ns.Castbar.Preview(true);time=time+2.3;ns.Castbar.Refresh()
ok(AndivalUICastbarFrame.bar.value==2/3,'explicit interruption preview freezes fill')
ns.Castbar.Preview(false);ns.Castbar.SetPreviewMode('sequence')
local rus=GetLocale()=='ruRU'
ok(AndivalUISettings.TitleText.textValue==(rus and 'Andival UI - Полосы заклинаний' or 'Andival UI - Castbars'),'settings title follows client locale')
local expected=rus and {cast='Обычный каст',channel='Ченнелинг',delayed='Задержка',success='Завершение',interrupted='Прерывание',protected='Со щитом',esi='Передача ESI',sequence='Все по кругу'} or {cast='Cast',channel='Channel',delayed='Delay',success='Success',interrupted='Interrupted',protected='Protected',esi='ESI handoff',sequence='Cycle all'}
for mode,text in pairs(expected) do ok(AndivalUISettings.modeButtons[mode].textValue==text,'localized mode '..mode) end
local P=ns.Profiles
ok(P.Current()=='Default','legacy settings migrate into Default')
local originalWidth=AndivalUIDB.castbar.width
ok(P.Copy('Default','Рейд'),'named profile accepts Cyrillic')
ok(P.Switch('Рейд'),'named profile switches')
AndivalUIDB.castbar.width=421
ok(P.Switch('Default') and AndivalUIDB.castbar.width==originalWidth,'named profile settings are independent')
ok(P.Switch('Рейд') and AndivalUIDB.castbar.width==421,'named settings persist across switches')
characterName='SecondPlayer';P.Init();ns.InitCastbarSettings()
ok(P.Current()=='Default','new character defaults independently')
characterName='TestPlayer';P.Init();ns.InitCastbarSettings()
ok(P.Current()=='Рейд','character remembers its selected profile')
ok(P.Rename('Рейд','Raid') and P.Current()=='Raid','rename retains active profile')
ok(not P.Copy('Raid','Raid'),'existing profile cannot be overwritten')
ok(not P.Create('bad|name'),'unsafe profile name rejected')
ok(not P.Delete('Default',true) and not P.Rename('Default','Other'),'default is protected')
ok(not P.Delete('Raid',false),'profile deletion needs confirmation')
ok(P.Delete('Raid',true) and P.Current()=='Default' and AndivalUIDB.castbar.width==originalWidth,'delete active profile safely falls back to Default')
ok(AndivalUIDB.characterProfiles['TestPlayer - TestRealm']=='Default','delete repairs character selection')
ok(P.Create('Temporary'),'create spare profile for guarded transitions')
characterName=nil;P.Init();local switched,why=P.Switch('Temporary')
ok(not switched and why=='notready','missing character identity cannot persist a guessed selection')
characterName='TestPlayer';P.Init()
local normalCombat=InCombatLockdown;InCombatLockdown=function()return true end
ok(not P.Switch('Temporary') and not P.Delete('Temporary',true) and not P.Create('Combat'),'named profile mutations blocked in combat')
InCombatLockdown=normalCombat;P.Delete('Temporary',true)
ok(not P.Create('По умолчанию'),'localized Default name is reserved')
local sample=ns.CastbarLogic.PreviewCast('sequence',5,0,'player',false)
ok(sample.channel,'Cycle all actually includes channel state')
ok(ns.CastbarLogic.PreviewCast('sequence',25,0,'player',false)==nil,'Cycle all includes safe ESI handoff demonstration')
AndivalUIDB.profiles.Broken={castbar={},unitcastbars={}}
ok(P.Switch('Broken'),'incomplete stored profile can activate')
ok(AndivalUIDB.castbar.x==0 and AndivalUIDB.castbar.y==-170 and AndivalUIDB.castbar.enabled and AndivalUIDB.castbar.latency,'full defaults normalized on every bind')
AndivalUIDB.castbar.x=0/0;AndivalUIDB.castbar.scale=math.huge;AndivalUIDB.unitcastbars.target.y=-math.huge;AndivalUIDB.unitcastbars.target.enabled='false'
ns.InitCastbarSettings();ns.Castbar.Layout()
ok(AndivalUIDB.castbar.x==0 and AndivalUIDB.castbar.scale==1 and AndivalUIDB.unitcastbars.target.y==-65 and type(AndivalUIDB.unitcastbars.target.enabled)=='boolean','nonfinite coordinates and malformed booleans repaired')
P.Switch('Default');P.Delete('Broken',true)
ns.Castbar.Preview(false);current=nil;channel=nil;PlayerCastingBarFrame:Hide();ns.Castbar.Refresh();PlayerCastingBarFrame:Show()
PlayerCastingBarFrame:SetAlpha(.4);GamepadPlayerCastingBarFrame=new(UIParent);GamepadPlayerCastingBarFrame:SetAlpha(.35);GamepadPlayerCastingBarFrame.casting=true
current={name='Ownership',start=300000,finish=305000,guid='own'};time=300;fire('UNIT_SPELLCAST_START','player','own')
ok(PlayerCastingBarFrame:GetAlpha()==0 and GamepadPlayerCastingBarFrame:GetAlpha()==0,'both native input layouts suppressed')
ns.Castbar.Preview(true)
ok(PlayerCastingBarFrame:GetAlpha()==.4 and GamepadPlayerCastingBarFrame:GetAlpha()==.35,'preview restores exact preexisting native alpha')
ns.Castbar.Preview(false)
fire('UNIT_SPELLCAST_INTERRUPTED','player',nil)
ok(AndivalUICastbarFrame:IsShown() and AndivalUICastbarFrame.bar.color[2]==.78,'unidentified terminal cannot end live spell')
local oldProgress=AndivalUICastbarFrame.bar.value;time=300.004
for _,frame in ipairs(frames) do if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,.004) end end
ok(AndivalUICastbarFrame.bar.value>oldProgress,'presentation updates on a 240Hz frame')
current=nil;channel={name='Late interrupt',start=310000,finish=313000};time=310;fire('UNIT_SPELLCAST_CHANNEL_START','player','late');time=312.95;channel=nil;fire('UNIT_SPELLCAST_INTERRUPTED','player','late')
ok(AndivalUICastbarFrame.bar.color[2]==.24,'near-end channel interruption never becomes success')
channel={name='Stop order',start=320000,finish=323000};time=320;fire('UNIT_SPELLCAST_CHANNEL_START','player','stoporder');time=322.95;channel=nil;fire('UNIT_SPELLCAST_CHANNEL_STOP','player','stoporder');fire('UNIT_SPELLCAST_FAILED','player','stoporder')
ok(AndivalUICastbarFrame.bar.color[2]==.24,'channel STOP before explicit failure is reconciled')
channel={name='Natural',start=330000,finish=333000};time=330;fire('UNIT_SPELLCAST_CHANNEL_START','player','natural');time=333;channel=nil;fire('UNIT_SPELLCAST_CHANNEL_STOP','player','natural');tick(333.09)
ok(AndivalUICastbarFrame.bar.color[2]==.86,'natural channel stop completes after reconciliation')
current={name='Quiet',start=340000,finish=343000,guid='quiet'};time=340;fire('UNIT_SPELLCAST_START','player','quiet');current=nil;fire('UNIT_SPELLCAST_FAILED_QUIET','player','quiet')
ok(AndivalUICastbarFrame.bar.color[2]==.24,'quiet failure is still a failure')
ns.Castbar.Preview(true);AndivalUICastbarFrame.stoppedMoving=false;AndivalUITargetCastbar.stoppedMoving=false;ns.Castbar.Preview(false)
ok(AndivalUICastbarFrame.stoppedMoving and AndivalUITargetCastbar.stoppedMoving,'closing preview always stops dragging')
local readsBefore=castReads;fire('UNIT_TARGET','raid1')
ok(castReads==readsBefore,'unrelated raid target events do not reread selected casts')
current={name='Fade ownership',start=360000,finish=363000,guid='fade'};time=360;fire('UNIT_SPELLCAST_START','player','fade')
current=nil;fire('UNIT_SPELLCAST_SUCCEEDED','player','fade');ns.Castbar.Preview(true)
PlayerCastingBarFrame:Hide();tick(360.1)
ok(PlayerCastingBarFrame:GetAlpha()==.4,'preview retries pending native restoration after fade hides')
ns.Castbar.Preview(false)
-- 0.8: focus, public/secret native duration and conservative fallbacks.
ns.Castbar.Preview(false);unitCasts={};unitChannels={};current=nil;channel=nil
local focus=ns.GetCastbarSettings('focus')
ok(focus.enabled==false and focus.y==-240,'focus is migrated disabled with independent position')
focus.enabled=true;unitCasts.focus={name='Focus spell',start=400000,finish=405000,guid='focus'};time=401
FocusFrameSpellBar=new(UIParent);FocusFrameSpellBar:SetAlpha(.7)
fire('PLAYER_FOCUS_CHANGED')
ok(AndivalUIFocusCastbar:IsShown() and AndivalUIFocusCastbar.bar.value==.2,'focus uses authoritative casting information')
ok(FocusFrameSpellBar:GetAlpha()==0,'focus native duplicate hidden only while custom shown')
unitCasts.focus=nil;fire('PLAYER_FOCUS_CHANGED')
ok(not AndivalUIFocusCastbar:IsShown() and FocusFrameSpellBar:GetAlpha()==.7,'focus clear restores exact native alpha')
Enum={StatusBarInterpolation={Immediate=0},StatusBarTimerDirection={ElapsedTime=1,RemainingTime=2}}
function Frame:SetTimerDuration(object,interpolation,direction) self.nativeObject=object;self.nativeDirection=direction end
local duration={GetElapsedDuration=function()return restricted end,GetTotalDuration=function()return restricted end}
UnitCastingDuration=function()return duration end
UnitChannelDuration=function()return duration end
unitCasts.focus={name='Hidden timing',start=restricted,finish=restricted,guid='secret-focus'}
fire('PLAYER_FOCUS_CHANGED')
ok(AndivalUIFocusCastbar:IsShown() and AndivalUIFocusCastbar.bar.nativeObject==duration,'native duration animates focus without Lua timing arithmetic')
ok(AndivalUIFocusCastbar.timer.textValue=='','secret duration never invents numeric timer')
unitCasts.focus=nil;unitChannels.focus={name='Hidden channel',start=restricted,finish=restricted};fire('PLAYER_FOCUS_CHANGED')
ok(AndivalUIFocusCastbar.bar.nativeDirection==2,'native secret channel uses remaining-time direction')
duration.GetElapsedDuration=function()return 1.2 end;duration.GetTotalDuration=function()return 5 end
ns.UnitCastbars.Refresh()
ok(AndivalUIFocusCastbar.timer.textValue==(rus and '1,2 / 5,0' or '1.2 / 5.0'),'native public durations honor elapsed-total format')
unitChannels.focus=nil;unitCasts.focus={name='Public again',start=400000,finish=405000,guid='public'};ns.UnitCastbars.Refresh()
ok(AndivalUIFocusCastbar.bar.andivalDuration==nil and AndivalUIFocusCastbar.bar.value==.2,'ordinary cast clears native timer ownership')
UnitCastingDuration=function()error('unavailable')end
unitCasts.focus={name='No duration',start=restricted,finish=restricted,guid='none'};ns.UnitCastbars.Refresh()
ok(not AndivalUIFocusCastbar:IsShown() and FocusFrameSpellBar:GetAlpha()==.7,'failed duration getter restores native fallback')
UnitCastingDuration=nil;UnitChannelDuration=nil;unitCasts.focus=nil;focus.enabled=false

local A=ns.CastbarAppearance
ok(A.FormatDuration(1.2,5,false,{timeFormat='remaining'})=='3.8','remaining timer format')
ok(A.FormatDuration(1.2,5,true,{timeFormat='elapsed'})=='1,2','elapsed timer localized')
ok(A.FormatDuration(1.2,5,true,{timeFormat='hidden'})=='','hidden timer format')
ok(A.FormatDuration(restricted,5,false,{timeFormat='remaining'})=='','appearance formatter rejects secret elapsed')
local pstyle=ns.GetCastbarSettings('player');local fstyle=ns.GetCastbarSettings('focus')
pstyle.texture='smooth';pstyle.castColor='blue';pstyle.channelColor='violet';pstyle.font='chat';pstyle.fontSize=14;pstyle.timeFormat='remaining'
ns.CopyCastbarSettings('player','focus')
ok(fstyle.texture=='smooth' and fstyle.castColor=='blue' and fstyle.timeFormat=='remaining' and not fstyle.enabled,'appearance copy includes styles but preserves disabled focus')
pstyle.castColor='teal';ok(fstyle.castColor=='blue','appearance copies remain independent')
P.Copy('Default','Style');P.Switch('Style');ns.GetCastbarSettings('focus').timeFormat='hidden';P.Switch('Default')
ok(ns.GetCastbarSettings('focus').timeFormat=='remaining','named profiles preserve independent appearance')
P.Delete('Style',true);ns.ResetCastbarSettings('player');ns.ResetCastbarSettings('focus')
current={name='Native player',start=restricted,finish=restricted,guid='native-player'};time=500
UnitCastingDuration=function()return duration end
fire('UNIT_SPELLCAST_START','player','native-player')
ok(AndivalUICastbarFrame:IsShown() and AndivalUICastbarFrame.bar.andivalDuration==duration,'player supports native secret timing')
ok(not AndivalUICastbarFrame.latency:IsShown() and not AndivalUICastbarFrame.spark:IsShown(),'secret timing hides guessed latency and spark')
EnhancedSoftInteractHUD.inEditMode=nil;EnhancedSoftInteractHUD:Show();EnhancedSoftInteractHUD.castBar:Show();tick(500.1)
ok(not AndivalUICastbarFrame:IsShown(),'ESI retains ownership with secret duration')
EnhancedSoftInteractHUD:Hide();current=nil;fire('UNIT_SPELLCAST_STOP','player','native-player');tick(500.3)
ok(not AndivalUICastbarFrame:IsShown(),'secret cast stop cannot create invented completion')
UnitCastingDuration=nil

local tw,nw=A.TextWidths({width=140,fontSize=18,timeFormat='elapsed_total'});ok(tw==140 and nw==0,'large timer takes priority over narrow spell title')
local ht,hn=A.TextWidths({width=140,timeFormat='hidden'});ok(ht==0 and hn==140,'hidden timer returns full title width')
-- Categorized settings: temporary preview placement must never become saved layout.
local settings=AndivalUISettings
local pos={};for _,unit in ipairs({'player','target','targettarget','focus'})do local d=ns.GetCastbarSettings(unit);pos[unit]={x=d.x,y=d.y,scale=d.scale}end
settings:Show();settings.SelectUnit('player');settings.SetTestMode('cast')
ok(settings:GetPreviewState().docked and AndivalUICastbarFrame:GetParent()==AndivalUIPreviewDock,'selected actual preview is docked in settings')
ok(not AndivalUITargetCastbar:GetParent():IsShown() and not AndivalUICastbarFrame:IsMouseEnabled(),'other preview bars staged hidden and dock cannot drag')
ns.GetCastbarSettings('target').enabled=true;settings.SelectUnit('target');settings.SelectTab('appearance')
ok(AndivalUITargetCastbar:GetParent()==AndivalUIPreviewDock and not settings.controls.latency.control:IsEnabled(),'unit switch docks selected bar and disables player-only latency')
local colorDrop=AndivalUIAppearance.controls.castColor.button;colorDrop:GenerateMenu()
local selectedBlue=false;for _,item in ipairs(colorDrop.menuItems or {})do if item.value=='blue'then item.callback(item.value);selectedBlue=true end end
ok(selectedBlue and ns.GetCastbarSettings('target').castColor=='blue' and ns.GetCastbarSettings('player').castColor~='blue','native choice menu writes only selected unit')
settings:Hide()
ok(AndivalUICastbarFrame:GetParent()==UIParent and AndivalUITargetCastbar:GetParent()==UIParent and not settings:GetPreviewState().docked,'closing settings restores runtime parents')
local preserved=true;for _,unit in ipairs({'player','target','targettarget','focus'})do local d=ns.GetCastbarSettings(unit);preserved=preserved and d.x==pos[unit].x and d.y==pos[unit].y and d.scale==pos[unit].scale end
ok(preserved,'docking and choices preserve saved positions and scale')
settings:Show();settings.SetPreviewVisible(false)
ok(not settings:GetPreviewState().docked and AndivalUITargetCastbar:GetParent()==UIParent,'disabling preview restores runtime placement')
settings.SetPreviewVisible(true);settings.ShowProfiles()
ok(not settings:GetPreviewState().docked and AndivalUICastbarFrame:GetParent()==UIParent,'profiles page has no hidden docked castbars')
local function Press(parent,label)
 for _,f in ipairs(frames)do if f.parent==parent and f.textValue==label and f.scripts.OnClick then f.scripts.OnClick(f);return true end end
 return false
end
AndivalUIProfiles.nameBox:SetText('UI test')
ok(Press(AndivalUIProfiles,rus and 'Создать из базового' or 'New from default') and ns.Profiles.Current()=='UI test','integrated profile creation selects new profile')
ok(not settings:GetPreviewState().docked and not AndivalUICastbarFrame:IsMouseEnabled(),'profile change does not restart hidden preview')
ns.Profiles.Switch('Default');ns.Profiles.Delete('UI test',true);settings.SelectUnit('player');settings.SetPreviewVisible(true)
settings.BeginPositioning()
ok(not settings:IsShown() and settings:GetPreviewState().positioning and AndivalUIPositionToolbar:IsShown() and AndivalUICastbarFrame:GetParent()==UIParent and AndivalUICastbarFrame:IsMouseEnabled(),'explicit positioning restores game anchors and drag')
settings.EndPositioning(true)
ok(settings:IsShown() and not settings:GetPreviewState().positioning and settings:GetPreviewState().docked,'finishing positioning returns to dock')
settings.BeginPositioning();AndivalUIPositionToolbar:Hide()
ok(not settings:GetPreviewState().positioning and not settings:IsShown() and not AndivalUICastbarFrame:IsMouseEnabled(),'Escape from positioning exits preview safely')
settings:Show();UIParent:SetSize(800,600);fire('DISPLAY_SIZE_CHANGED')
ok(settings:GetScale()*900<=776.01 and settings:GetScale()*650<=576.01,'settings scales within smaller logical screen')
UIParent:SetSize(1920,1080);fire('DISPLAY_SIZE_CHANGED');settings.BeginPositioning()
InCombatLockdown=function()return true end;fire('PLAYER_REGEN_DISABLED')
ok(not settings:IsShown() and not AndivalUIPositionToolbar:IsShown() and not settings:GetPreviewState().docked and AndivalUICastbarFrame:GetParent()==UIParent and not AndivalUICastbarFrame:IsMouseEnabled(),'combat closes dock and positioning without hiding runtime frames')
InCombatLockdown=normalCombat

settings:Show();settings.BeginPositioning();SlashCmdList.ANDIVALUI('')
ok(settings:IsShown() and not settings:GetPreviewState().positioning and not AndivalUIPositionToolbar:IsShown() and settings:GetPreviewState().docked,'slash reopening position mode restores a single docked settings mode')
settings.stoppedMoving=false;settings:Hide();ok(settings.stoppedMoving,'closing settings stops titlebar drag')
local nav=settings.navigation.player;nav:SetPoint('TOPLEFT',UIParent,'TOPLEFT',0,0);settings:Show();settings.SelectPage('player')
local _,_,_,_,navY=nav:GetPoint();ok(navY==-124,'page layout restores sidebar coordinates after external repositioning')
ok(AndivalUICastbarFrame.flow.texturePath:find('SoftGlow.tga',1,true) and AndivalUICastbarFrame.spark.texturePath:find('SoftGlow.tga',1,true),'moving glow and primary spark use edge-free original texture')
settings:Hide()
-- Neutral/confirmed fades are cosmetic and never retain a changed unit.
settings:Hide();ns.Castbar.Preview(false);current=nil;channel=nil;unitCasts={};unitChannels={}
local identities={target='unit-A',targettarget='unit-B',focus='unit-C'}
local oldUnitExists=UnitExists
UnitExists=function(unit)return unit=='player' or identities[unit]~=nil end
UnitGUID=function(unit)return identities[unit]end
for _,unit in ipairs({'target','targettarget','focus'})do ns.GetCastbarSettings(unit).enabled=true;ns.GetCastbarSettings(unit).reducedMotion=false;ns.GetCastbarSettings(unit).castColor='native';ns.GetCastbarSettings(unit).channelColor='native' end
unitCasts.target={name='Fading target',start=700000,finish=703000,guid='fade-target'};time=700;fire('PLAYER_TARGET_CHANGED');tick(701)
local held=AndivalUITargetCastbar.bar.value;unitCasts.target=nil;tick(701.1);tick(701.5)
ok(AndivalUITargetCastbar:IsShown() and AndivalUITargetCastbar:GetAlpha()>.45 and AndivalUITargetCastbar:GetAlpha()<.55,'unknown target disappearance gets gentle neutral fade')
ok(AndivalUITargetCastbar.bar.value==held and AndivalUITargetCastbar.timer.textValue=='' and AndivalUITargetCastbar.bar.color[2]==.78,'unknown target ending preserves fill and never invents success')
unitCasts.target={name='Replacement',start=701500,finish=704500,guid='new-target'};time=701.55;fire('UNIT_SPELLCAST_START','target','new-target')
ok(AndivalUITargetCastbar:GetAlpha()==1 and AndivalUITargetCastbar.text.textValue:find('Replacement',1,true),'new target cast immediately replaces fade')
unitCasts.target=nil;fire('UNIT_SPELLCAST_INTERRUPTED','target','fade-target');tick(701.6)
ok(AndivalUITargetCastbar.timer.textValue=='','stale failure cannot label replacement cast interrupted')
identities.target='different-target';fire('PLAYER_TARGET_CHANGED')
ok(not AndivalUITargetCastbar:IsShown(),'target identity change immediately discards old fade')
unitCasts.targettarget={name='ToT',start=710000,finish=713000,guid='tot'};time=710;fire('UNIT_TARGET','target');tick(711);unitCasts.targettarget=nil;tick(711.1);tick(711.4)
ok(AndivalUITargetTargetCastbar:IsShown() and AndivalUITargetTargetCastbar:GetAlpha()<1,'target-of-target supports neutral fade')
identities.targettarget=nil;tick(711.5);ok(not AndivalUITargetTargetCastbar:IsShown(),'lost target-of-target never leaves stale fade')
unitCasts.focus={name='Focus interrupt',start=720000,finish=723000,guid='focus-fail'};time=720;fire('PLAYER_FOCUS_CHANGED');tick(721);unitCasts.focus=nil;fire('UNIT_SPELLCAST_INTERRUPTED','focus','focus-fail')
ok(AndivalUIFocusCastbar.timer.textValue==(rus and 'Прервано' or 'Interrupted') and AndivalUIFocusCastbar.bar.color[2]==.24,'matching focus interruption gets confirmed red fade')
tick(721.81);ok(not AndivalUIFocusCastbar:IsShown(),'unit fade ends after eight tenths')
unitCasts.target={name='Success',start=730000,finish=733000,guid='target-success'};time=730;fire('PLAYER_TARGET_CHANGED');tick(732);unitCasts.target=nil;fire('UNIT_SPELLCAST_SUCCEEDED','target','target-success')
ok(AndivalUITargetCastbar.bar.value==1 and AndivalUITargetCastbar.bar.color[2]==.86,'matching success is distinct from neutral disappearance')
ns.GetCastbarSettings('target').reducedMotion=true;tick(732.1);ok(not AndivalUITargetCastbar:IsShown(),'reduced motion skips unit fade')
ns.GetCastbarSettings('target').reducedMotion=false
current={name='Cancelled player',start=740000,finish=743000,guid='cancel-player'};time=740;fire('UNIT_SPELLCAST_START','player','cancel-player');tick(741);local playerHeld=AndivalUICastbarFrame.bar.value;current=nil;fire('UNIT_SPELLCAST_STOP','player','cancel-player');tick(741.09);tick(741.4)
ok(AndivalUICastbarFrame:IsShown() and AndivalUICastbarFrame:GetAlpha()>.5 and AndivalUICastbarFrame.bar.value==playerHeld and AndivalUICastbarFrame.timer.textValue=='','plain player cancellation fades neutrally without forcing completion')
current={name='Immediate new',start=741400,finish=744400,guid='immediate'};fire('UNIT_SPELLCAST_START','player','immediate')
ok(AndivalUICastbarFrame:GetAlpha()==1 and AndivalUICastbarFrame.name.textValue=='Immediate new','new player spell never waits for cancellation fade')
current=nil;fire('UNIT_SPELLCAST_INTERRUPTED','player','immediate');tick(742.3)
ok(not AndivalUICastbarFrame:IsShown(),'player fade expires after eight tenths')
UnitExists=oldUnitExists;UnitGUID=nil

settings:Show();settings.contentScroll:SetHeight(200);settings.SetContentScroll(999)
ok(settings.contentScroll:GetVerticalScroll()==210,'real content scrolling is clamped to visible range')
settings.SetContentScroll(-9);ok(settings.contentScroll:GetVerticalScroll()==0,'scroll cannot move before content start');settings:Hide()
local nativeFreeze=CreateFrame('StatusBar');nativeFreeze.andivalDuration={};nativeFreeze:SetMinMaxValues(0,5);nativeFreeze:SetValue(2)
ok(ns.CastbarDuration.Freeze(nativeFreeze) and nativeFreeze.maximum==5 and nativeFreeze.value==2,'native fade preserves original range instead of clamping to full')
ns.CastbarDuration.Clear(nativeFreeze);ok(nativeFreeze.maximum==1 and nativeFreeze.value==0,'next ordinary cast resets frozen native range')
print(string.format('%d tests passed',count))
