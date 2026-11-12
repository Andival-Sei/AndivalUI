local ns = {}
local frames = {}
local Frame = {}
local function noop() end
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
function Frame:GetEffectiveAlpha() return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1) end
function Frame:SetAlpha(v) self.alpha=v end
function Frame:SetStatusBarTexture(path)
  assert(path:match("^Interface"), "statusbar must start with a real texture path")
  self.statusbarTexture = new(self)
end
function Frame:GetStatusBarTexture() return self.statusbarTexture end
function Frame:SetAtlas(atlas) self.atlas = atlas end
function Frame:GetAtlas() return self.atlas end
function Frame:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function Frame:SetText(v) self.textValue=v end
function Frame:SetFormattedText(f,v) self.textValue=string.format(f,v) end
function Frame:CreateMaskTexture() return new(self) end
function Frame:AddMaskTexture(mask) self.mask=mask end
function Frame:CreateTexture() return new(self) end
function Frame:CreateFontString() return new(self) end
function Frame:SetScale(v) self.scale=v end
function Frame:GetScale() return self.scale or 1 end
function Frame:GetCenter() return 960,540 end
function Frame:SetChecked(v) self.checked=v end
function Frame:GetChecked() return self.checked end
function CreateFrame(kind,name,parent,template)
  local f=new(parent); frames[#frames+1]=f
  if name then _G[name]=f end
  if template=='BasicFrameTemplateWithInset' then f.TitleText=new(f) end
  if template=='UICheckButtonTemplate' then f.text=new(f) end
  if template=='OptionsSliderTemplate' then f.Text=new(f);f.Low=new(f);f.High=new(f) end
  return f
end
UIParent=new(); UISpecialFrames={}; SlashCmdList={}; unpack=table.unpack
PlayerCastingBarFrame=new(UIParent)
local time=100; local current; local channel; local restricted={}
function GetTime() return time end
function GetLocale() return 'ruRU' end
function GetNetStats() return 0,0,50,100 end
function InCombatLockdown() return false end
function issecretvalue(v) return v==restricted end
function UnitCastingInfo() if current then return current.name,'',135920,current.start,current.finish,false,current.guid,false,1 end end
function UnitChannelInfo() if channel then return channel.name,'',135920,channel.start,channel.finish,false,false,1 end end
local function fire(e,...)
  for _,f in ipairs(frames) do if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f,e,...) end end
end
local function tick(t) time=t; for _,f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,.02) end end end
local function load(path) assert(loadfile(path))('AndivalUI',ns) end
load('Core.lua'); load('Modules/CastbarLogic.lua'); load('Integrations/EnhancedSoftInteract.lua'); load('Modules/Castbar.lua');load('Settings.lua')
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
ok(AndivalUICastbarFrame.bar:GetStatusBarTexture():GetAtlas()=='ui-castingbar-filling-standard','native atlas explicitly assigned')
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
current=nil;fire('UNIT_SPELLCAST_INTERRUPTED','player','b');ok(AndivalUICastbarFrame.timer.textValue=='Прервано','interrupt feedback');tick(103);ok(not AndivalUICastbarFrame:IsShown(),'interrupt fades out')
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
ok(AndivalUICastbarFrame.bar:GetStatusBarTexture():GetAtlas()=='ui-castingbar-full-standard','STOP before success still renders completion')
channel={name='Channel',start=109000,finish=113000};time=109;fire('UNIT_SPELLCAST_CHANNEL_START','player','chan')
fire('UNIT_SPELLCAST_INTERRUPTED','player','h');tick(110)
ok(AndivalUICastbarFrame.bar.value==.75,'old spell event cannot end new channel')
channel=nil;fire('UNIT_SPELLCAST_CHANNEL_STOP','player','chan');tick(114)
current={name='Preview overlap',start=114000,finish=117000,guid='preview'};time=114;fire('UNIT_SPELLCAST_START','player','preview')
SlashCmdList.ANDIVALUI('');ok(PlayerCastingBarFrame:GetAlpha()==1,'preview releases native castbar ownership')
fire('PLAYER_REGEN_DISABLED');ok(not AndivalUISettings:IsShown(),'combat closes settings and preview')
print(string.format('%d tests passed',count))
