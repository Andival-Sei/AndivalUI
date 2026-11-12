local ok, err = pcall(dofile, 'tests/run.lua')
if not ok then io.stderr:write(tostring(err)..'\n'); os.exit(1) end
