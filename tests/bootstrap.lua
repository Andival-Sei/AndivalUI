for _,path in ipairs({'tests/run.lua','tests/crafting.lua'}) do
    local ok,err=pcall(dofile,path)
    if not ok then io.stderr:write(tostring(err)..'\n');os.exit(1) end
end
