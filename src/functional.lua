-- Functional programming facilities
-- @author Tomasz Lewowski
-- @release 0.1

--- Accumulate value of a function during container traversal
-- Accumulates value using function f on previous value of accumulator and current value.
-- f shall be associative and commutative, as order of execution is undefined in case of associative tables
-- in case of arrays it is linear
-- Also known as: accumulate (C++), reduce (JavaScript, Python), inject (JavaScript)
-- @param tab Container that will be traversed
-- @param f Function to be applied to each element of tab. Accumulator is passed as the first argument, current value as the second and current key as the third.
-- @param acc Accumulator, changed after each call
-- @return Final value of acc, after traversing entire table
local function fold(tab, f, acc)
  assert(type(tab) == 'table', "fold can be called only on tables")
  for k, v in pairs(tab) do
    acc = f(acc, v, k)
  end
  return acc
end

-- Transforms values in a table by applying given function to each of them. Does not modify the original table.
-- @param tab Container that will be traversed
-- @param f Function applied to each element. First argument is value of the element, second argument is the key.
-- @returns New table with preserved keys and transformed values
local function map(tab, f)
  return fold(tab, function(acc, val, key) acc[key] = f(val, key); return acc end, {})
end

-- returns two values: first is a table containing elements satisfying predicate, second is a table containing elements not satisfying predicate
local function partition(tab, pred)
  assert(type(tab) == 'table', "only tables may be partitioned")
  return unpack(fold(tab, function(acc, val, key) 
      if pred(val, key) then acc[1][key] = val 
	  else acc[2][key] = val end 
	  return acc end, 
	{{},{}}))
end

-- Returns table containing only elements, that satisfy given predicate
local function filter(tab, pred)
  return (partition(tab, pred))
end

-- Returns key of first element satifying predicate
local function first(tab, pred)
  assert(type(tab) == 'table', "any can be called only on tables")
  for k, v in pairs(tab) do
    if pred(v, k) then return k end
  end
  return nil
end

-- Checks if all elements in a table satisfy a predicate
local function all(tab, pred)
  assert(type(tab) == 'table', "all can be called only on tables")
  return first(tab, function(v, k) return not pred(v, k) end) == nil
end

-- Checks if any of elements in a table satisfy a predicate
local function any(tab, pred)
  assert(type(tab) == 'table', "any can be called only on tables")
  return first(tab, pred) ~= nil
end

-- True if given table is empty, false otherwise
local function empty(tab)
  return not any(tab, function() return true end)
end


-- Returns "some" element from the table
-- in sequences, it is first element, in associative arrays it can be any
local function head(tab)
  assert(not empty(tab), "Empty table has no head")
  return tab[first(tab, function() return true end)]
end

-- Returns all elements from the table, except one (the one returned by 'head')
-- in sequences, it is first element, in associative arrays it can be any
-- it is a slow function, as it has to copy the whole table (lua does not offer table reuse without modifying it)
local function tail(tab)
  assert(not empty(tab), "Empty table has no tail")
  local head_val = tab[first(tab, function() return true end)]
  local found = false -- in case this value appears more than once in a table
  return filter(tab, function(x)
    res = found or x ~= head_val 
	if not found and x == head_val then found = true end 
	return res 
	end)
end

-- calls f for all elements in tab
local function forall(tab, f)
  fold(tab, function(acc, v, k) f(v, k); return nil end, nil)
  return nil
end

-- Accumulates value using function f on previous value of accumulator and current value.
-- f shall be associative and commutative, as order of execution is undefined in case of associative tables
-- in case of arrays it is linear
-- Holds temporary results
local function scan(tab, f, acc)
  assert(type(tab) == 'table', "scan can be called only on tables")
  local result = {acc}
  for _, v in pairs(tab) do
    result[#result + 1] = f(result[#result], v, k)
  end
  
  return result
end

-- returns size of a table (counts also associative entries, unlike #tab)
local function sizeof(tab)
  return fold(tab, function(acc, x) return acc+1 end, 0)
end

-- Returns sum of a table
local function sum(tab)
  return fold(tab, function(a, b) return a+b end, 0)
end

-- Returns product of a table
local function product(tab)
  return fold(tab, function(a, b) return a*b end, 1)
end

-- Returns concatenated table
-- Don't use it for large (>100 kB) tables!
-- Don't use for associative tables! order of concatenation is then undefined
local function concatenate(tab)
  return fold(tab, function(a, b) return a..b end, '')
end

-- returns the biggest value in a table
local function maximum(tab)
  assert(not empty(tab), "empty table does not have a maximum")
  return fold(tab, function(a, b) return (a > b and a) or b end, tab[first(tab, function() return true end)])
end

-- returns the smallest value in a table
local function minimum(tab)
  assert(not empty(tab), "empty table does not have a maximum")
  return fold(tab, function(a, b) return (a < b and a) or b end, tab[first(tab, function() return true end)])
end

-- Merges unlimited amount of tables with given function
-- Results in one table made out of this function's results 
-- f is applied to a table
local function zip_with(f, ...)
  assert(type(f) == 'function', "First argument to zip_with must be a function")
  if ... == nil then return nil end
  local input_tables = {...}
  
  assert(all(input_tables, function(v) return type(v) == 'table' end), "Can zip only tables, for making single tables see pack")
  local keys = {}
  local output_tables = {}
  
  for _, tab in pairs(input_tables) do
    -- no check for sizes, because it'd require traversing whole table each time
  	for k, _ in pairs(tab) do
      if not keys[k] then
  	    output_tables[k] = f(map(input_tables, function(t) return t[k] end))
	    end
	  end
  end

  return output_tables
end

-- Merges unlimited amount of tables by keys
-- Results in one table made out of tuples
local function zip(...)
  return zip_with(function(x) return x end, ...)
end

-- Returns function that is a result of applying f1 to results of call to f2
-- f1 shall have only one argument
local function compose(f1, f2)
  assert(type(f1) == type(f2) and type(f1) == 'function', "compose can be called only on functions")
  return function(...) return f1(f2(...)) end
end

-- true if table is a sequence - only consecutive positive integers starting from 0
local function is_sequence(tab)
  if type(tab) ~= 'table' then return false end
  return #tab == sizeof(tab)
end

-- Flips order of arguments in function
-- f shall have only two arguments
local function flip(f)
  assert(type(f) == 'function', "flip can be called only on function")
  return function(x,y) return f(y,x) end
end

-- extracts n arguments from a sequence args
-- args must be a sequence, but may have nils inside
-- returns it as n values
local function extract_args(n, args)
  assert(type(n) == type(0) and n >= 0, "Count must be non-negative integer")
  assert(type(args) == 'table', "Args must be a table")
  
  local function helper(n, k, args)
    if k > n then 
      return nil
    else 
      return args[k], helper(n, k+1, args)
    end
  end
  
  return helper(n, 1, args)
end

-- Changes order of arguments to given in the sequence
-- second argument is a sequence of integers indicating which argument shall go in the place
local function flipall(f, seq)
  assert(is_sequence(seq), "Argument order must be a sequence")
  assert(type(f) == 'function', "Only function arguments may be flipped")
  
  local arg_seq = seq
  return function (...) 
      local received_args = {...}
	  local ordered_args = fold(arg_seq, function(acc, v, k) acc[v] = received_args[k]; return acc end, {})
	  return f(extract_args(#arg_seq, ordered_args))
    end  
end

-- Takes elements out of internal tables and put them into first level of tables (removes second level)
-- if key is present in more than one table, last of them is present in resulting table 
local function key_sensitive_flatten(input_tables)
  assert(type(input_tables) == 'table', "Only table can be flattened")
  local result = {}
  for _, tab in pairs(input_tables) do
    for k, t in pairs(tab) do
	  result[k] = t
	end
  end
  
  return result
end

-- Takes elements out of all internal tables into ordered list
-- All elements will be present in this list, but order is not defined
local function key_insensitive_flatten(input_tables)
  assert(type(input_tables) == 'table', "Only table can be flattened")
  local result = {}
  for _, tab in pairs(input_tables) do
    fold(tab, function(acc, v) acc[#acc + 1] = v; return acc end, result)
  end
  
  return result
end

-- returns all keys of a given table
local function keys(tab)
  assert(type(tab) == 'table', "Only table has keys")
  return fold(tab, function(acc, v, k) acc[#acc + 1] = k; return acc end, {})
end

-- returns all values of a given table
local function values(tab)
  return fold(tab, function(acc, v) acc[#acc + 1] = v; return acc end, {})
end

-- returns true if tab contains val, false otherwise
local function contains(tab, val)
  assert(type(tab) == 'table', "Contains can be called only on tables")
  return any(tab, function(x) return x == val end)
end

-- returns true if values in tables are equal (number of occurrences counts)
local function are_values_equal(tab1, tab2)
  assert(type(tab1) == 'table', "values can be compared on tables")
  assert(type(tab2) == 'table', "values can be compared on tables")

  local tab = fold(tab1, function(acc, x) if acc[x] then acc[x] = acc[x] + 1 else acc[x] = 1 end return acc end, {})
  return #fold(tab2, function(acc, x) if acc[x] then acc[x] = acc[x] - 1 else acc[x] = -1 end if acc[x] == 0 then acc[x] = nil end return acc end, tab) == 0
end

-- Function currying, i.e. returns function that must be called with a total number of arguments equal to arg_count
-- but not necessarily in one shot, e.g. f1 = curry(f, 5); f2 = curried(2,4); f3 = f(2,5); value = f3(5)
local function curry(f, arg_count)
  assert(type(f) == 'function', "only a function may be curried")
  assert(arg_count > 0, "you may curry a function only for a positive number of arguments")
  
  local tab = {}
  local function func(...)
    tab = fold({...}, function(acc, x) acc[#acc + 1] = x; return acc end, tab)
	if #tab >= arg_count then
	  return f(unpack(tab))
	else
	  return curry(func, arg_count - #tab)
	end
  end
  return func
end

-- calls mutator on its results until predicate on the result is true
local function call_until(pred, mutator, start_val)
  local val = start_val
  while not pred(val) do
    val = mutator(val)
  end
  return val
end

-- returns a sequence with requested number of values generated by func
local function take(n, func)
  assert(type(n) == type(0), "count must be a number")
  local function take_helper(n, func)
    if n <= 0 then return nil
	else return func(), take_helper(n - 1, func)
	end
  end
  
  return {take_helper(n, func)}  
end

-- returns func after taking n elements from the front
local function drop(n, func)
  assert(type(n) == type(0), "count must be a number")
  take(n, func)
  return func
end

-- returns n numbers starting from begin incrementing with step
local function range(n, begin, step)
  assert(type(n) == type(0), "count must be a number")
  assert(type(begin) == type(0), "begin value must be a number")
  assert(type(step) == type(0), "step must be a number")
  local value = begin
  return take(n, function() local res = value; value = value + step; return res end) 
end

-- creates an iterator that returns given elements in cycle
local function cycle(...)
  local pieces = {...}
  assert(#pieces > 0, "to cycle must get more than one item")
  
  local current = 1
  local function cycle_helper()
    local res = pieces[current]
	if current == #pieces then 
	  current = 1
	else 
	  current = current + 1
	end
	
	return (type(res) == 'function' and res()) or res	
  end
  
  return cycle_helper
end

-- returns a table with p replicated n times
local function times(n, p)
  return take(n, cycle(p))
end

-- returns true if metatable of a given variable contains method with given name
local function has_function(var, name)
  assert(type(name) == 'string', 'function name must be a string')
  return (getmetatable(var) and (type(getmetatable(var)[name]) == 'function')) or false
end

-- checks if given variables have the same type
local function are_same_type(var1, var2)
  return type(var1) == type(var2) and getmetatable(var1) == getmetatable(var2)
end

-- deep copy of a table
local function deep_copy(tab)
  return map(tab, function(val) if type(val) == 'table' then return copy(tab) else return val end end)
end

-- bind (partial application)
-- memoize
-- once
-- after
-- before
-- catch_value

local functional = {
  fold = fold,
  map = map,
  partition = partition,
  filter = filter,
  first = first,
  all = all,
  any = any,
  empty = empty,
  forall = forall,
  head = head,
  tail = tail,
  scan = scan,
  sizeof = sizeof,
  sum = sum,
  product = product,
  concatenate = concatenate,
  maximum = maximum,
  minimum = minimum,
  zip_with = zip_with,
  zip = zip,
  compose = compose,
  flip = flip,
  extract_args = extract_args,
  flipall = flipall,
  key_sensitive_flatten = key_sensitive_flatten, 
  key_insensitive_flatten = key_insensitive_flatten,
  keys = keys,
  values = values,
  contains = contains,
  are_values_equal = are_values_equal,
  curry = curry,
  call_until = call_until,
  times = times,
  take = take,
  drop = drop,
  range = range,
  is_sequence = is_sequence,
  cycle = cycle,
  has_function = has_function,
  are_same_type = are_same_type,
  deep_copy = deep_copy
}

return functional