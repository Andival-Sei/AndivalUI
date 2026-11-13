local _,ns=...
local L=ns.CastbarLogic
-- Animate only an authoritative timing correction; ordinary progress stays exact.
function L.Retime(old,c,now)
    if not old or not c or old.channel~=c.channel then return c end
    local delta=c.endTime-old.endTime
    c.delay=old.delay;c.delayAt=old.delayAt
    if math.abs(delta)>.005 then
        local before=L.DisplayProgress(old,now,false)
        local after=L.Progress(c.startTime,c.endTime,now,c.channel)
        c.correction=before-after;c.correctedAt=now
        c.delay=(old.delay or 0)+delta;c.delayAt=now
    else c.correction=old.correction;c.correctedAt=old.correctedAt end
    return c
end
function L.DisplayProgress(c,now,reduced)
    local p=L.Progress(c.startTime,c.endTime,now,c.channel)
    if not reduced and c.correction and c.correctedAt then
        local t=L.Clamp((now-c.correctedAt)/.18,0,1)
        p=p+c.correction*(1-t)*(1-t)
    end
    return L.Clamp(p,0,1)
end
function L.DelayLabel(c,now,ru)
    if not c.delayAt or now-c.delayAt>1.8 or math.abs(c.delay or 0)<.05 then return '',0 end
    local text=string.format('%+.1f',c.delay)
    if ru then text=text:gsub('%.',',') end
    return text,L.Clamp((1.8-(now-c.delayAt))/.4,0,1)
end
function L.PreviewCast(mode,now,origin,unit,ru)
    if mode=="sequence" then
        local modes={"cast","channel","delayed","success","interrupted","protected","esi"}
        local step=math.floor((now-origin)/4)
        mode=modes[step%#modes+1];origin=origin+step*4
    end
    local age=(now-origin)%4
    local channel=mode=='channel' or (mode=='sequence' and unit=='targettarget')
    local c={name=channel and (ru and 'Поток энергии' or 'Energy channel') or (ru and 'Свет небес' or 'Holy Light'),icon=channel and 136048 or 135920,
        startTime=now-age,endTime=now-age+3,channel=channel,latency=.12,blocked=mode=='protected',interruptKnown=true}
    if mode=='delayed' and age>=1 then
        local old={startTime=c.startTime,endTime=c.endTime,channel=false}
        c.endTime=c.endTime+.3;L.Retime(old,c,c.startTime+1)
    end
    if mode=='esi' then return nil end
    if mode=='success' or mode=='interrupted' then
        if age>=2 then return c,{success=mode=='success',remaining=L.Clamp((2.55-age)/.55,0,1)} end
    end
    if age>3.6 then return nil end
    return c
end
