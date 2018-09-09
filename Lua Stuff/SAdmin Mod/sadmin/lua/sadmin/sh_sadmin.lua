sa.Commands = sa.Commands or {}

function sa.IncludeFolder(path)
	local files = file.Find("sadmin/"..path.."/*", "LUA")

	for i = 1, #files do
		if string.StartWith(files[i], "sh_") then
			if SERVER then
				AddCSLuaFile("sadmin/"..path.."/"..files[i])
			end
			include("sadmin/"..path.."/"..files[i])
		end	

		if SERVER and string.StartWith(files[i], "sv_") then
			include("sadmin/"..path.."/"..files[i])
		end

		if string.StartWith(files[i], "cl_") then
			if SERVER then
				AddCSLuaFile("sadmin/"..path.."/"..files[i])
			else
				include("sadmin/"..path.."/"..files[i])
			end
		end	
	end
end

sa.IncludeFolder("libs")
sa.IncludeFolder("commands")