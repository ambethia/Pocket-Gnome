waxClass{"PGCoreFAIL", Plugin}

function ePluginLoaded(self)
  self.trends = {}
  
  puts("Hello from PGCore")
  
end

function ePlayerFound(self, player)
	print("Found a player! Yay!")
	
	if ( player ) then
		print("Argument is of type: " .. type(player))
		
		print("Class is " .. player:className())
		
		puts(wax.instance.methods(player))
		
		print("Player name: " .. tostring(player:name()))
	end
end

function ePlayerDied(self)

end

function eBotStart(self)

	-- prints everything in the global table
	--for k,v in pairs(_G) do print(k) end

	print("Do we want the bot to start? FUCK NO!")
	
	--DisplayError("No", "I don't want you to start!")
	
	DisplayError("No")

	return NO;

end