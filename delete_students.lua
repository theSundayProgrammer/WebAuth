local jwt = require "resty.jwt"
local usrpwd=require "checkpwd"
local cjson = require "cjson"

ngx.req.read_body()

local args, err = ngx.req.get_post_args()
if (not args )  then
	ngx.status = 501
	ngx.say(err)
	return ngx.exit(501)
else
	local deleted_students= cjson.decode(args.deleted_students )
	for k,v in ipairs(deleted_students) do
		ngx.log(ngx.NOTICE,"student id =", v)
	end
	local res,err = pcall(usrpwd.delete_students,deleted_students)
	if (not res )  then
		ngx.status = 411
		ngx.say(err)
		return ngx.exit(411)
	else
		local status = ngx.HTTP_OK  
		ngx.header.content_type = "application/json; charset=utf-8"  
		ngx.say(cjson.encode({ status = true }))  
		return ngx.exit(ngx.HTTP_OK)  
	end
end

