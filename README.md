# WebAuth
>A small project to illustrate the use of Redis for authentication and authorisation.

##Context
While developing a website to take sudent role calls on the phone, I decided to
use MySQL for the student database and a Redis for authentication and 
authorisation. I am using Openresty (NGINX) as my webserver. Since all the code 
will be in Lua. The project is still its alpha
stage and a public user name and password will soon be provided.

##Why Redis
Redis a NOSQL key-value database. While the type of the key can be only a string
the type of a value can in addition to being a primitive type like number, string, blob or
hyperloglog, can also be a set, a map or a sequence. A map in Redis is called a
HMAP  or hasp-map, indicating its implementation, and a sequence is called a list. For details refer to Redis.

Notice that the three data structures: set, map and sequence cover almost all
dat structure requirements. Redis does not provide a recursive data structure.
A set cannot contain another set. With some discipline though we could
achieve the same result by having a set of keys with each key refering to
another set or map or requence.

##Authentication
User names and hashed passwords are store in a map whose key is 
"users:passwords". One of the first design issues that needs to be addressed
is nomenclature of keys. I use the convention that the prefixi, "users" in this
case is plural when it refers to the collection 'users' and singular if we need
to create a key for a specific user say, "user:joe." 

The password may be hashed as follows:
````lua
	local function hash_pwd(user,pwd)  
	local sha256 = require"resty.sha256"
	  local chunk = sha256:new() -- create a private closure for calculating digest of single string
	  local seed="hsGtghLTh5fglo6d" -- secret prefix
	  chunk:update(user)
	  chunk:update(seed) 
	  chunk:update(pwd)               
	  return str.to_hex(chunk:final())
	end
````
The following helper function  wraps the openning and closing of connection for 
a redis command
````lua
local function exec(func)
  local red = redis:new()

  red:set_timeouts(1000, 1000, 1000) -- 1 sec
  assert( red:connect("127.0.0.1", 6379))
  local results, err = func(red)
  red:set_keepalive(1000,100)
    return results,err
end
````
Hence a verify password function is more easily implemented as follows
````lua
local usertable="users:passwords"
function verify_pwd(user,pwd)
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
````


