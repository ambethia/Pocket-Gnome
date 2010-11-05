luaConsoleGlobal = { backLog = {}}

local oldputs = puts
function puts(s)
	oldputs(s)
	if(luaConsoleGlobal.instance ~= nil) then
		luaConsoleGlobal.instance.log(luaConsoleGlobal.instance, s)
	else
		luaConsoleGlobal.backLog[#luaConsoleGlobal.backLog+1] = s
	end
end
  
local oldprint = print
function print(s)
	oldprint(s)
	if(luaConsoleGlobal.instance ~= nil) then
		luaConsoleGlobal.instance.log(luaConsoleGlobal.instance, s)
	else
		luaConsoleGlobal.backLog[#luaConsoleGlobal.backLog+1] = s
	end
end 

waxClass{"LuaConsole", Plugin, outlets={"window", "textView", "scrollView"}, protocols = {"NSTextFieldDelegate"}}

function initWithPath(self, path)
	self.super:initWithPath(path)
	luaConsoleGlobal.instance = self
	
	return self
end

function pluginLoaded(self)
	self:loadNib("LuaConsole.nib")

	for i,s in ipairs(luaConsoleGlobal.backLog) do 
		self:log(s) 
	end

 
end

function log(self, s)
	if(self.textView == nil) then
		luaConsoleGlobal.backLog[#luaConsoleGlobal.backLog+1] = s
	else
		s = s .. "\n"
		self.textView:textStorage():appendAttributedString(NSAttributedString:alloc():initWithString(s))
		self.textView:scrollRangeToVisible(NSRange(0, self.textView:textStorage():length()))
	end
end

function control_textShouldEndEditing(self, control, field)
	if(field:string() == "") then
		return true
	end
	
	local okay, ret1 = pcall(function() 
		local func = assert(loadstring("return "..field:string()))
		local res = func()
		return res
	end)
	if(okay) then
		self:log(field:string() .. " : " .. print_r(ret1))
	else
		self:log(field:string() .. " caused the error: " .. ret1)
	end
	field:setString("");
end

function print_r ( t ) 
 	local print_r_cache={}
	local res = ""
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			res = res .. indent.."*"..tostring(t)
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						res = res ..  indent.."["..pos.."] => "..tostring(t).." {"
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						res = res .. indent..string.rep(" ",string.len(pos)+6).."}"
					else
						res = res .. indent.."["..pos.."] => "..tostring(val)
					end
				end
			else
				res = res .. indent..tostring(t)
			end
		end
	end
	sub_print_r(t,"  ")
	
	return res
end