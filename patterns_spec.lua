describe("Basic software patterns implementations", function()
  local luapat
  setup(function()
    luapat = require('luapat')
  end)

  teardown(function()
    luapat = nil
  end)
  
  describe("Singleton pattern", function() 
    local meta
    
    before_each (function()
      meta = {}
      meta.create = function() local x = {} setmetatable(x, meta) return x end
    end)
    
    after_each  (function()
      meta = nil
    end)
    
    it("Singleton is really a singleton", function()
      local single3 = luapat.singletons.get(meta)
      local single1 = meta.create()
      local single2 = meta.create()
      
      assert.is.truthy(single1)
      assert.is.truthy(single2)
      assert.is.truthy(single3)
      
      assert.are.equal(single1, single2)
      assert.are.equal(single3, single2)
    end)
    
    it("Singleton is really a singleton starting from declaring it as singleton", function()
      local single1 = meta.create()
      local single3 = luapat.singletons.get(meta)
      local single2 = meta.create()
      
      assert.is.truthy(single1)
      assert.is.truthy(single2)
      assert.is.truthy(single3)
      
      assert.are_not.equal(single1, single3)
      assert.are.equal(single3, single2)
    end)

    it("Singleton can survive reset and will be second instance", function()
      local single1 = luapat.singletons.get(meta)
      local single2 = meta.create()
      luapat.singletons.reset(meta)
      
      assert.is.truthy(single1)
      assert.is.truthy(single2)
    end)
  
    it("Singleton can be reset", function() 
      local single2 = luapat.singletons.get(meta)
      local single1 = meta.create()
      local single3 = luapat.singletons.get(meta)
    
      assert.are.equal(single1, single2)
      assert.are.equal(single3, single2)
      
      luapat.singletons.reset(meta)
      
      local single4 = luapat.singletons.get(meta)
      local single5 = meta.create()
      
      assert.are.equal(single4, single5)
      assert.are_not.equal(single1, single4)
      assert.are_not.equal(single2, single4)
      assert.are_not.equal(single3, single4)
    end)
  end)
end)