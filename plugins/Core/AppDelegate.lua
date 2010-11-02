
print("Core has loaded!")

-- now we have access to the Controller class! WOOHOOOO!
local delegate = NSApplication:sharedApplication():delegate()
self = delegate;

-- example of calling a function w/in Controller
local result = self:isWoWOpen()
if ( result ) then
	print("WoW is open!")
else
	print("WoW is not open!")
end

local botController = self:botController()

RegisterEvent("E_PLAYER_DIED", "PlayerDied")

--botController:startBot(nil)

last_processed=0
function tick(elapsed)
	print("tick" .. elapsed)
	
	-- only proceed if we've waited 300+ milliseconds!
	if (elapsed-last_processed > 300) then
		print("do work")
		last_processed=elapsed
	end
end


function PlayerDied(name)

	print("Player died, name: " .. name)
end