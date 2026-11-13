-- Standalone: fengari tests/crafting.lua (no game files or persistent settings).
local now,secret,count=0,{},0
function GetTime()return now end
function issecretvalue(v)return v==secret end
function CreateFrame()return {RegisterUnitEvent=function()end,RegisterEvent=function()end,SetScript=function()end}end
local ns={};assert(loadfile('Modules/CastbarCrafting.lua'))('AndivalUI',ns)
local M=ns.CastbarCrafting;local E,R=M.Test.Event,M.Test.Request
local function ok(v,label)assert(v,label);count=count+1;print('PASS '..label)end
R(123,3);E('UNIT_SPELLCAST_START','player','a',123)
ok(M.Label(123,'a',true)=='1 / 3','explicit requested total with matching start')
ok(M.Label(123,'a',false)==nil,'non-trade cast never gets count')
ok(M.Label(999,'a',true)==nil,'different recipe ID never mapped heuristically')
R(123,99);ok(M.Label(123,'a',true)=='1 / 3','repeated request without new cast does not redefine batch')
E('UNIT_SPELLCAST_STOP','player','a',123);now=.1;E('UNIT_SPELLCAST_SUCCEEDED','player','a',123)
E('UNIT_SPELLCAST_START','player','b',123);ok(M.Label(123,'b',true)=='2 / 3','STOP before success preserves verified operation')
E('UNIT_SPELLCAST_SUCCEEDED','player','a',123);ok(M.Label(123,'b',true)=='2 / 3','late duplicate success ignored')
E('UNIT_SPELLCAST_FAILED','player','a',123);ok(M.Label(123,'b',true)=='2 / 3','stale failure does not kill new cast')
E('UNIT_SPELLCAST_INTERRUPTED','player','b',123);ok(M.Label(123,'b',true)==nil,'interruption clears series')
E('UNIT_SPELLCAST_START','player','c',123);R(123,2);ok(M.Label(123,'c',true)=='1 / 2','synchronous START before post-hook supported')
E('UNIT_SPELLCAST_SUCCEEDED','player','c',123);E('UNIT_SPELLCAST_STOP','player','c',123);E('UNIT_SPELLCAST_START','player','d',123)
ok(M.Label(123,'d',true)=='2 / 2','success before STOP also works')
E('UNIT_SPELLCAST_SUCCEEDED','player','d',123);ok(M.Label(123,'d',true)==nil,'completed requested series clears')
R(123,secret);ok(M.Label(123,'d',true)==nil,'secret count rejected')
R(123,2);E('UNIT_SPELLCAST_START','player',secret,123);ok(M.Label(123,secret,true)==nil,'secret GUID never compared or counted')
R(123,2);E('UNIT_SPELLCAST_START','player','e',123);E('UNIT_SPELLCAST_STOP','player','e',123);now=now+.4
ok(M.Label(123,'e',true)==nil,'STOP without success expires without fabricated completion')
R(123,2);now=now+6;E('UNIT_SPELLCAST_START','player','f',123);ok(M.Label(123,'f',true)==nil,'unstarted request expires')
R(123,2);E('UNIT_SPELLCAST_START','player','g',999);ok(M.Label(999,'g',true)==nil,'unrelated cast aborts pending batch')
R(123,nil);E('UNIT_SPELLCAST_START','player','h',123);ok(M.Label(123,'h',true)==nil,'missing explicit count stays unknown')
R(123,2);E('TRADE_SKILL_CLOSE');ok(M.Label(123,'h',true)==nil,'trade skill close clears')
E('UNIT_SPELLCAST_START','player','i',123);R(123,2);E('UNIT_SPELLCAST_SUCCEEDED','target','i',123)
ok(M.Label(123,'i',true)=='1 / 2','other units cannot increment')
E('UNIT_SPELLCAST_SUCCEEDED','player','i',123);now=now+3;E('UNIT_SPELLCAST_START','player','j',123)
ok(M.Label(123,'j',true)==nil,'long gap does not attach stale series')
print(count..' crafting tests passed')
