--[[ non-critical issues:
	Doesn't parse XML specification
	Can't escape characters in attributes
]]

local comment_pattern = '<!%-%-(.-)%-%->'
local attribute_pattern = '(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))'
local tag_pattern = '<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)'

return function(s)
	local t = {} -- current table of children
	local l = {} -- stack of aforementioned tables
	s = s:gsub(comment_pattern, '') -- remove comments
	for type, name, closed, text in s:gmatch(tag_pattern) do
		if type == '/' then -- closing tag
			t = table.remove(l) -- move to parent's table of children
		else
			-- {tag name, children, attributes}
			local tag = {t=name:lower()}
			local a
			if closed == '' then -- check for attributes
				local len = 0
				for all,aname,_,value,starttxt in text:gmatch(attribute_pattern) do
					len = len + #all
					if not a then a={} tag.a=a end
					a[aname] = value
					if starttxt == '' then continue end
					text,closed = text:sub(len+1),starttxt
					break
				end
			end
			table.insert(t,tag) -- insert tag into table of children
			if closed:sub(1,1) ~= '/' then -- check if tag is not self-closing
				-- move into tag's table of children
				table.insert(l,t)
				t = {}
				tag.c = t
			end
		end
		text = text:match('^[\t\n\r]*(.*[^\t\n\r])') or '' -- find text in tag
		if text ~= '' then table.insert(t,text) end 
	end
	return t
end
