
print("Combat has loaded!")

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

botController:test(nil)

last_processed=0
function tick2(elapsed)
	print("tick")
	
	-- only proceed if we've waited 300+ milliseconds!
	if (elapsed-last_processed > 300) then
		print("do work")
		last_processed=elapsed
	end
end