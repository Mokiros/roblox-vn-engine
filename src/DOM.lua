local dom
local empty_table = {}
local function loopthrough(t,fn,not_recursive)
	if t==empty_table then return end
	for _,c in ipairs(t) do
		if fn(c) then
			return true
		elseif not not_recursive and loopthrough(dom.getChildren(c),fn) then
			return true
		end
	end
end
dom = {
	getTag = function(self)
		return self and self.t
	end,
	getChildren = function(self)
		if typeof(self)~="table" then
			return empty_table
		elseif self.t then
			return self.c or empty_table
		else
			return self
		end
	end,
	getAttributes = function(self)
		return self and self.a or empty_table
	end,
	getElementByTagName = function(self,tag,not_recursive)
		local el
		loopthrough(dom.getChildren(self),function(c)
			if dom.getTag(c) == tag then
				el = c
				return true
			end
		end,not_recursive)
		return el
	end,
	getElementsByTagName = function(self,tag,not_recursive)
		local el = {}
		loopthrough(dom.getChildren(self),function(c)
			if dom.getTag(c) == tag then
				table.insert(el,c)
			end
		end,not_recursive)
		return el
	end,
	getElementByAttribute = function(self,name,val,not_recursive)
		local el
		loopthrough(dom.getChildren(self),function(c)
			if dom.getAttribute(c,name) == val then
				el = c
				return true
			end
		end,not_recursive)
		return el
	end,
	getElementById = function(self,id,not_recursive)
		return dom.getElementByAttribute(self,'id',id,not_recursive)
	end,
	getAttribute = function(self,attr)
		return dom.getAttributes(self)[attr]
	end,
	getText = function(self)
		local txt = ''
		loopthrough(dom.getChildren(self),function(c)
			if type(c)=='string' then
				txt = txt .. c
			elseif dom.getTag(c)=='br' then
				txt = txt .. '\n'
			end
		end)
		return txt
	end,
	indexById = function(self,not_recursive)
		local el = {}
		loopthrough(dom.getChildren(self),function(c)
			local id = dom.getAttribute(c,'id')
			if id then
				if el[id] then
					error("Found 2 elements with same id attribute.",0)
				end
				el[id] = c
			end
		end,not_recursive)
		return el
	end
}
dom.__index = dom

return dom
