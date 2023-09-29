local cjson = require "cjson"
local userdb= require "checkpwd"
local status,users,groups=pcall(userdb.get_users_roles)
if status then
	local res={}
	res["users"]=users
	res["roles"]=groups
--[[ test code
  local result= cjson.encode(res)
	local output=cjson.decode(result)
	for k,v in pairs(output) do
		print (k)
		for key,val in pairs(v) do
			print("  ",val)
		end
	end
--]]
  ngx.header.content_type = "application/json; charset=utf-8"  
	ngx.say(cjson.encode(res))
else
  ngx.status = ngx.INTERNAL_SERVER_ERROR
  ngx.say("failed to access Database;", users)
  return ngx.exit(ngx.INTERNAL_SERVER_ERROR)  
end
