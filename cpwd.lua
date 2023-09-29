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
local oldpwd 
local newpwd

while true do
  local part_body, name, mime, filename = p:parse_part()
  if not part_body then
    break
  end
  if name=="oldpwd" then
    oldpwd=part_body
  end
  if name=="newpwd" then
    newpwd=part_body
  end
end
local usr =ngx.ctx.usr
ngx.log(ngx.NOTICE,"old:",oldpwd,"   new:",newpwd)
local res,err = usrpwd.update_newpwd(usr,oldpwd,newpwd)
if (not res )  then
  ngx.status = 411
  ngx.say(err)
  return ngx.exit(411)
else
  status = ngx.HTTP_OK  
  ngx.header.content_type = "application/json; charset=utf-8"  
  ngx.say(cjson.encode({ status = res==1 }))  
  return ngx.exit(ngx.HTTP_OK)  

end
