
local cjson_safe = require "cjson.safe"
local optl = require("optl")

local function get_argByName(name)
	local x = 'arg_'..name
    local _name = ngx.unescape_uri(ngx.var[x])
    return _name
end

local _action = get_argByName("action")
local _mod = get_argByName("mod")
local _id = get_argByName("id")
local _value = get_argByName("value")
local _value_type = get_argByName("value_type")
local tmpdict = ngx.shared.config_dict

if _action == "get" then

	if _mod == "all_mod" then
		local _tb,tb_all = tmpdict:get_keys(0),{}
		for i,v in ipairs(_tb) do
			tb_all[v] = tmpdict:get(v)
		end
		optl.sayHtml_ext(tb_all)
	elseif _mod == "count_mod" then
		local _tb = tmpdict:get_keys(0)
		optl.sayHtml_ext(table.getn(_tb))
	elseif _mod == "" then
		local _tb = tmpdict:get_keys(0)
		optl.sayHtml_ext(_tb)
	else	
		local _tb = tmpdict:get(_mod)
		if _tb == nil then optl.sayHtml_ext({code="error",msg="mod is Non-existent"}) end
		_tb = cjson_safe.decode(_tb) or {}
		if _id == "" then
			optl.sayHtml_ext(_tb)
		elseif _id == "count_id" then
			local cnt = 0
			for k,v in pairs(_tb) do
				cnt = cnt+1
			end
			optl.sayHtml_ext({count=cnt})
		else
			--- realIpFrom_Mod 和 base 特殊处理
			if _mod ~= "realIpFrom_Mod" and _mod ~= "base" then
				_id = tonumber(_id)
			end			
			optl.sayHtml_ext({id=_id,value=_tb[_id]})
		end
	end	
elseif _action == "set" then


	local _tb = tmpdict:get(_mod)
	if _tb == nil then optl.sayHtml_ext({code="error",msg="mod is Non-existent"}) end

	if _id == "" then
	-- id 参数不存在 （整体set）
		local tmp_value = cjson_safe.decode(_value)--将value参数的值 转换成json/table
		if type(tmp_value) == "table" then
			local _old_value = cjson_safe.decode(tmpdict:get(_mod))--将原有数据取出 并转成 json/table
			local re = tmpdict:replace(_mod,_value)--将对应mod整体进行替换
			optl.sayHtml_ext({replace=re,old_value=_old_value,new_value=tmp_value})
		else
			optl.sayHtml_ext({code="error",msg="value to json error"})
		end
	else
		
		if _value_type == "json" then
			_value = cjson_safe.decode(_value) ---- 将value参数的值 转换成json/table
			if type(_value) ~= "table" then
				optl.sayHtml_ext({code="error",msg="value to json error"})
			end			
		end		
		
		_tb = cjson_safe.decode(_tb) or {}
		--- realIpFrom_Mod base 特殊处理
		if _mod ~= "realIpFrom_Mod" and _mod ~= "base" then
			_id = tonumber(_id)
		end
		local _old_value = _tb[_id]
		--- 判断id是否存在
		if _old_value == nil then optl.sayHtml_ext({code="error",msg="id is nil"}) end
		_tb[_id] = _value
		local re = tmpdict:replace(_mod,cjson_safe.encode(_tb))
		optl.sayHtml_ext({replace=re,old_value=_old_value,new_value=_value})
			

	end
elseif _action == "add" then

	local _tb = tmpdict:get(_mod)
	if _tb == nil then 
		optl.sayHtml_ext({code="error",msg="mod is Non-existent"}) 
	end

	if _value_type == "json" then
		_value = cjson_safe.decode(_value) ---- 将value参数的值 转换成json/table
		if type(_value) ~= "table" then
			optl.sayHtml_ext({code="error",msg="value to json error"})
		end
	end

	_tb = cjson_safe.decode(_tb) or {}
	
	
	if _mod == "realIpFrom_Mod"  then
		if _tb[_id] == nil and _id ~= "" then
			_tb[_id] = _value
			local re = tmpdict:replace(_mod,cjson_safe.encode(_tb))
			optl.sayHtml_ext({mod=_mod,value=tmpdict:get(_mod)})
		else
		 	optl.sayHtml_ext({code="error",msg="id is existent"})
		end 
		
	elseif  _mod == "base" then
		optl.sayHtml_ext({code="error",msg="base does not support add"})
	else
		table.insert(_tb,_value)
		local re = tmpdict:replace(_mod,cjson_safe.encode(_tb))
		optl.sayHtml_ext({mod=_mod,value=tmpdict:get(_mod)})
	end
elseif _action == "del" then
	

	local _tb = tmpdict:get(_mod)
	if _tb == nil then optl.sayHtml_ext({code="error",msg="mod is Non-existent"}) end
	_tb = cjson_safe.decode(_tb) or {}
	

	if _mod == "realIpFrom_Mod" then
		local rr = _tb[_id]
		if rr == nil then
			optl.sayHtml_ext({code="error",msg="id is Non-existent"})
		else
			_tb[_id] = nil
			local re = tmpdict:replace(_mod,cjson_safe.encode(_tb))
			optl.sayHtml_ext({mod=_mod,id=_id,re=re})
		end
	elseif _mod == "base" then
		optl.sayHtml_ext({code="error",msg="base does not support del"})
	else
		_id = tonumber(_id)
		if _id == nil then
			optl.sayHtml_ext({code="error",msg="_id is not number"})
		else
			local rr = table.remove(_tb,_id)
			if rr == nil then
				optl.sayHtml_ext({code="error",msg="id is Non-existent"})
			else
				local re = tmpdict:replace(_mod,cjson_safe.encode(_tb))
				optl.sayHtml_ext({mod=_mod,id=_id,re=re})
			end		
		end			
	end

else
	optl.sayHtml_ext({code="error",msg="action error"})
end