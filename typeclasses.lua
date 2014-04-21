local functional = require('functional')

local function is_of_typeclass(var, typeclass)
  local required_functions = functional.keys(typeclass)
  return functional.all(required_functions, function(name) return functional.has_function(var, name) end)
end

local function preconditions(...)
  local typeclasses = {...}
  return {['typeclasses'] = typeclasses,
    ['__call'] = function(obj) return functional.all(typeclasses, function(class) return is_of_typeclass(obj, class) end ) end
  }
end

-- Monad typeclass
local Monad = {}
Monad.wrap = function(...) return {...} end
Monad.unwrap = function(tab) return functional.head(tab) end

-- Functor typeclass
local Functor = {}
Functor.__call = function() end

-- Monoid typeclass
local Monoid = {}
Monoid.empty = function() return {} end

-- Container typeclass
local Container = {}
Container.__len = function() end
Container.insert = function() end
Container.remove = function() end
Container.preconditions = preconditions(Monoid)

-- Applicative typeclass
local Applicative = {}

-- MonadPlus typeclass
local MonadPlus = {}
MonadPlus.plus = function(a, b) return a or b end

-- Traversable typeclass
local Traversable = {}
Traversable.__pairs = function(tab) return pairs(tab) end
Traversable.preconditions = preconditions(Container)

-- Sequential typeclass
local Sequential = {}
Traversable.__ipairs = function(tab) return ipairs(tab) end
Sequential.head = function() end
Sequential.tail = function() end
Sequential.last = function() end
Sequential.init = function() end
Sequential.preconditions = preconditions(Traversable)

-- Reversable typeclass
local Reversable = {}
Reversable.revert = function(tab) return fold(tab, function(acc, val, key) acc[#tab - key] = val; return acc; end, {}) end
Reversable.preconditions = preconditions(Sequential)

-- Foldable typeclass
local Foldable = {}
Foldable.fold = function(tab, f, acc) return functional.fold(tab, f, acc) end
Foldable.preconditions = preconditions(Traversable)

-- TwoWayFoldable typeclass
local TwoWayFoldable = {}
TwoWayFoldable.foldl = function(tab, f, acc) return tab:fold(f, acc) end
TwoWayFoldable.foldr = function(tab, f, acc) return tab:revert():fold(f, acc) end
TwoWayFoldable.preconditions = preconditions(Foldable, Reversable)

-- Comparable typeclass
local Comparable = {}
Comparable.__eq = function() end

-- Ordered typeclass
local Ordered = {}
Ordered.__le = function() end
Ordered.__lt = function() end
Ordered.preconditions = preconditions(Comparable)

-- Lazy typeclass
local Lazy = {}

-- Arithmetic typeclass
local Arithmetic = {}
Arithmetic.__add = function() return  end
Arithmetic.__sub = function() return  end
Arithmetic.__div = function() return  end
Arithmetic.__mul = function() return  end
Arithmetic.__unm = function() return  end

-- Serializable typeclass
local Serializable = {}
Serializable.__tostring = function() end

-- if preconditions for mixin are not fulfilled, all required typeclasses are mixed in
local function mixin_single_typeclass(tab, typeclass)
  local metatable = getmetatable(tab)
  if typeclass.preconditions and not typeclasses.preconditions(tab) then functional.map(typeclasses.preconditions.typeclasses, function(typeclass) return mixin(tab, typeclass) end) end
  if not metatable then return setmetatable(tab, functional.deep_copy(typeclass)) end
  
  fold(typeclass, function(acc, val, key) acc[key] = acc[key] or (type(val) == 'table' and functional.deep_copy(val)) or val; return acc end, metatable)
end

local function mixin(tab, ...)
  local typeclasses = {...}
  return map(typeclasses, function(typeclass) return mixin_single_typeclass(tab, typeclass) end)
end

local Mixable = {}
Mixable.mixin = mixin

local Createable = {}
Createable.create = function() end

Typeclass = {}
Typeclass.Mixable = Mixable
Typeclass.Createable = Createable

return {
  is_of = is_of_typeclass,
  Typeclass = Typeclass
  }