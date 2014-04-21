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
  
    it("Derived class singleton does not affect parent class if singletonized first", function() 
      local meta2 = {}
      local metameta2 = {}
      metameta2.__index = function(t, k) return meta[k] end
      setmetatable(meta2, metameta2)
          
      local single2 = luapat.singletons.get(meta2)
      local single1 = luapat.singletons.get(meta)
      local single3 = meta.create()
      local single4 = meta2.create()
      
      assert.are.equal(single1, single3)
      assert.are.equal(single2, single4)
      assert.are_not.equal(single1, single2)
      assert.are_not.equal(single3, single4)
      
      luapat.singletons.reset(meta)
      local single5 = meta2.create()
      local single6 = luapat.singletons.get(meta)
      local single7 = meta.create()
      
      assert.are.equal(single6, single7)
      assert.are_not.equal(single6, single1)
      assert.are.equal(single5, single4)
      assert.are_not.equal(single5, single6)
      
      luapat.singletons.reset(meta2)
      local single8 = luapat.singletons.get(meta2)
      local single9 = meta.create()
      local single10 = meta2.create()
      
      assert.are.equal(single8, single10)
      assert.are.equal(single9, single7)
      assert.are.equal(single6, single9)
      assert.are_not.equal(single8, single9)
      
    end)
  
    it("Derived class and base class have the same singleton object if base class was singletonized first", function() 
      local meta2 = {}
      local metameta2 = {}
      metameta2.__index = function(t, k) return meta[k] end
      setmetatable(meta2, metameta2)
          
      local single1 = luapat.singletons.get(meta)
      local single2 = luapat.singletons.get(meta2)
      local single3 = meta.create()
      local single4 = meta2.create()
      
      assert.are.equal(single1, single3)
      assert.are.equal(single2, single4)
      assert.are.equal(single1, single2)
      assert.are.equal(single3, single4)
      
      luapat.singletons.reset(meta)
      local single5 = meta2.create()
      local single6 = luapat.singletons.get(meta)
      local single7 = meta.create()
      
      assert.are.equal(single6, single7)
      assert.are_not.equal(single6, single1)
      assert.are.equal(single5, single4)
      assert.are_not.equal(single5, single6)
      
      luapat.singletons.reset(meta2)
      local single8 = luapat.singletons.get(meta2)
      local single9 = meta.create()
      local single10 = meta2.create()
      
      assert.are.equal(single8, single10)
      assert.are.equal(single9, single7)
      assert.are.equal(single6, single9)
      assert.are.equal(single8, single9)
      
    end)
  end)
end)