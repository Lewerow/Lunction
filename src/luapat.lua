require('functional')
local typeclasses = require('typeclasses')

-- the Singleton pattern, or at least part that is possible to make in Lua
local singleton_holder = {}
singleton_holder.existing = {}
singleton_holder.resetting = {}

local singletons = {}
singletons.get = function(typename)
    if singleton_holder.existing[typename] then return singleton_holder.existing[typename] end
  
-- will be added when is_of function will be fixed
--    assert(typeclasses.is_of(typename, Typeclass.Createable), "Singleton must be of Createable typeclass")
    
    singleton_holder.resetting[typename] = typename.create
    singleton_holder.existing[typename] = typename.create()
    
    typename.create = function() return singletons.get(typename) end
    
    return singleton_holder.existing[typename]
  end
singletons.reset = function(typename)
    if not singleton_holder.resetting[typename] then return end
    singleton_holder.existing[typename] = nil
    typename.create = singleton_holder.resetting[typename]
    singleton_holder.resetting[typename] = nil
  end

-- Chain of Responsibility pattern, implemented as a router


return {
  singletons = singletons
  }