
print("AppDelegate has loaded!")

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