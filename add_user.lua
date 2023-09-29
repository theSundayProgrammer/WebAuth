local jwt = require "resty.jwt"
local usrpwd=require "check_redis"
local parser = require "resty.multipart.parser"

local cjson = require "cjson"
ngx.req.read_body()

local body = ngx.req.get_body_data()

local p, err = parser.new(body, ngx.var.http_content_type)
if not p then
  status = ngx.INTERNAL_SERVER_ERROR
  ngx.header.content_type = "application/json; charset=utf-8"  
  ngx.say("failed to create parser: ", err)
  return ngx.exit(ngx.INTERNAL_SERVER_ERROR)  
end
local user 
local newpwd

while true do
  local part_body, name, mime, filename = p:parse_part()
  if not part_body then
    break
  end
  if name=="user" then
    user=part_body
  end
  if name=="newpwd" then
    newpwd=part_body
  end
end
if user and newpwd then 
  local res,err = pcall(usrpwd.add_user,user,newpwd)
  if not res   then
    ngx.status = 411
    ngx.log(ngx.NOTICE,"failed to insert:", err)
    return ngx.exit(411)
  else
    status = ngx.HTTP_OK  
    ngx.header.content_type = "application/json; charset=utf-8"  
    ngx.say(cjson.encode({ status = true }))  
    return ngx.exit(ngx.HTTP_OK)  
  end
else 
    ngx.status = 411
    ngx.log(ngx.NOTICE,"user name or password is empty")
    return ngx.exit(411)
end
