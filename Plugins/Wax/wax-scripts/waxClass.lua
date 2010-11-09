function waxClass(options)
  local className = options[1]
  local superclassName = options[2]
  local class = wax.class(className, superclassName)
  class.name = className
  
  if options.protocols then
    if type(options.protocols) ~= "table" then options.protocols = {options.protocols} end
    if #options.protocols == 0 then error("\nEmpty protocol table for class " .. className .. ".\n Make sure you are defining your protocols with a string and not a variable. \n ex. protocols = {\"UITableViewDelegate\"}\n\n") end
  end
  
  for i, protocol in ipairs(options.protocols or {}) do
    wax.class.addProtocols(class, protocol)
  end 

  for i, outlet in ipairs(options.outlets or {}) do
	name = outlet:sub(1,1):upper()..outlet:sub(2)
	class["set" .. name] = function(self, value) self[outlet] = value end
  end

  local _M = setmetatable({
      self = class,
    },
    {
      __newindex = function(self, key, value) 
        class[key] = value
      end,
    
      __index = function(self, key) 
        return class[key] or _G[key]
      end,
    
    }
  )

  _G[className] = class
  package.loaded[className] = class
  setfenv(2, _M)
  
  return class
end
