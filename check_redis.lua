--local mysql = require "resty.mysql"
local str = require "resty.string"
local redis = require "resty.redis"
local function hash_pwd(user,pwd)
local sha256 = require"resty.sha256"
  local chunk = sha256:new() 
  local seed="hs8r876545UwVJoH" --sample secret prefix
  chunk:update(user)
  chunk:update(seed) 
  chunk:update(pwd)              
  return str.to_hex(chunk:final())
end
local usertable="users:passwords"
local user_roles="users:roles"
local user_assets="users:assets"
local M={}
local function exec(func)
  local red = redis:new()

  red:set_timeouts(1000, 1000, 1000) -- 1 sec
  assert( red:connect("127.0.0.1", 6379))
  local results, err = func(red)
  red:set_keepalive(1000,100)
    return results,err
end
function M.add_role(user,role)
  local compute = function(red)
    local exist = red:hexists(usertable, user)
    if exist==1 then
        red:sadd(user_roles, role)
    return  red:sadd("role:"..user, role)
  else
    return 0,"No such user"
  end
  end
  return exec(compute)
end
function M.del_user_role(user,role)
  local compute = function(red)
    local exist = red:hexists(usertable, user)
    if exist==1 and red:sismember("role:"..user, role)==1 then
    return  red:srem("role:"..user, role)
  else
    return 0,"No such user"
  end
  end
  return exec(compute)
end
function M.get_assets()
  local compute = function(red)
    return  red:smembers(user_assets)
  end
  return exec(compute)
end
function M.get_users()
  local compute = function(red)
    return  red:hkeys(usertable)
  end
  return exec(compute)
end
function M.add_asset(asset,role)
  local compute = function(red)
        red:sadd(user_roles, role)
    red:sadd(user_assets, asset)
    return  red:sadd("asset:"..asset,role)
  end
  return exec(compute)
end
function M.del_asset(asset)
  local compute = function(red)
    red:srem(user_assets,asset)
    return  red:del("asset:"..asset)
  end
  return exec(compute)
end
function M.del_user(user)
  local compute = function(red)
    red:del("role:"..user)
    return  red:hdel(usertable,user)
  end
  return exec(compute)
end
function M.add_user(user,pwd)
  local compute = function(red)
    return  red:hmset(usertable,user, hash_pwd(user,pwd))
  end
  return exec(compute)
end
function M.verify_pwd(user,pwd)
  local compute = function(red)
    return  red:hmget(usertable,user)
  end
  local results,err = exec(compute)
  if  results then 
    return hash_pwd(user,pwd)==results[1] and 1 or 0 
  else
    return results,err
  end
end
function M.update_newpwd(user,oldpwd,newpwd)
  if M.verify_pwd(user,oldpwd) == 1 then
  return M.add_user(user,newpwd)
else
  return false,"invalid or old password or user not found"
end
end
function M.user_auth(user,asset)
  local compute = function(red)
    return  red:sinter("role:" .. user, "asset:"..asset)
  end
  return exec(compute)
end

function M.del_roles(role)
  local compute = function(red)
    red:srem(user_roles,role)
    local users= assert(red:hkeys(usertable))
    for k,v in pairs(users) do
       red:srem("role:"..v, role)
     end
  end
  return exec(compute)
end
function M.get_roles()
  local compute = function(red)
    return  red:smembers(user_roles)
  end
  return exec(compute)
end
return M

