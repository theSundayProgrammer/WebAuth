# WebAuth
>A Openresty project to illustrate the use of Redis for authentication and authorisation.

## Context
While developing a website to take student role calls on the phone, I decided to
use MySQL for the student database and a Redis for authentication and 
authorisation. I am using Openresty (NGINX) as my web server. Hence all the code 
will be in Lua. The [project](https://github.com/theSundayProgrammer/WebAuth) is still its alpha
stage but for now logging with uid/pwd : joe3/password  at 
[Norwest Computing](https://test.norwestcomputing.com.au/new_class) 
will get you access to the attendance register for a fictional class.
In the first stage only I am publishing only the user authentication part. In the 
next stage I will publish the actual 
## Basic Authentication
Nginx provides a [simple authentication schema](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/). 
It consists of a simple text file with user names and hashed passwords. In the 
following configuration any web client trying to access the _/api_ area will be
prompted for a password unless the client has already logged in
````
    location /api {
      auth_basic           “Administrator’s Area”;
      auth_basic_user_file /etc/apache2/.htpasswd; 
    ..........
    }
````
Here _/etc/apache2/.htpasswd_ is the text file containing user names and passwords.
This type of authentication will suffice for a website with a small number of users.
Authorisation, of the all-or-nothing kind can be implemented by having different
password files for different locations. 
So if a user has to be removed the user name must be removed from all the password files

## Advanced Authentication
Using a datbase to store the username and password has some advantages; the main
one being concurerency (a database can be read and updated concuurently). The other
advantage would be that it is possible to implement authorisation based on roles
or groups as well. However
a full Role Based Access Control (RBAC) has to be implemented by the database server.

### Javascript Web Tokens
JWT  (Javascript Web Tokens) is a convention used to save the authentication details 
in a cookie. The user name and other details such as time to expire is stored with a signature in a cookie. Since a HTTP request is stateless the cookie contains
all the details about the user. Thus if multiple servers are used for load
balancing any server can verify the JWT token if the secret key to sign
it is known. The contents are base64 encoded and hence accessible to the client 

Hence if a web-location needs a user to be authenticated then the user is redirected 
to a logon page. On successful logon the user is then redirected to the requested
page. The implementation of this functionality is present in 'check_access.lua'

## Why Redis
Redis is a NOSQL key-value database. While the type of the key can be only a string
the type of a value can in addition to being a primitive type like number, string, blob or
hyperloglog, can also be a set, a map or a sequence. A map in Redis is called a
HMAP  or hasp-map, indicating its implementation, and a sequence is called a
list. For details refer to Redis.

Notice that the three data structures: set, map and sequence cover almost all
data structure requirements. Redis does not provide a recursive data structure.
A set cannot contain another set. With some discipline though we could
achieve the same result by having a set of keys with each key refering to
another set or map or sequence.

## Authentication
User names and hashed passwords are store in a map whose key is 
"users:passwords". One of the first design issues that needs to be addressed
is nomenclature of keys. I use the convention that the prefixi, "users" in this
case is plural when it refers to the collection 'users' and singular if we need
to create a key for a specific user say, "user:joe." 

The password may be hashed as follows:
````lua
local function hash_pwd(user,pwd)  
local sha256 = require"resty.sha256"
-- create a private closure for calculating digest of single string
  local chunk = sha256:new() 
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
A simple usage example is shown below:
````lua
local usrauth=require "check_redis"
local user="joe3"
local password="password"
local verified,err = usrauth.verify_pwd(user,password)
if verified and verified==1 then
--success
else
--fail
end
````
The list of functions available are: 

* **add_role**_(user\_name,role)_
 adds a role to the set "role:<user_name>"
* **del_user_role**_(user\_name,role)_
 deletes a role from the set "role:<user_name>"
* **get_assets**_()_
gets the set "users:assets"
* **get_users**_()_
gets the set of keys of the map "users:passwords"
* **add_asset**_(asset\_name,role)_
adds "role" to set "assets:<asset_name>"
* **del_asset**_(asset)_
deletes the "asset" from the set "users:assets" and deletes the key "asset:<asset_name>"
* **del_user**_(user\_name)_
deletes the key "<user_name>" from the map "users:passwords" and deletes the key-value pair with key "role:<user_name>"
* **add_user**_(user,pwd)_
adds key-value <user,hashed_pwd> to the map "users:passwords" Notice that if the user exists already its password is overwritten
* **verify_pwd**_(user,pwd)_
verify the password as shown above
* **user_auth**_(user\_name,asset\_name)_
Computes the intersection of "role:<user_name>" and "asset:<asset_name>" and returns true if the set contains at least one element
* **del_roles**_(role)_
"role" is removed from the set "users:roles", and from every set "role:\*" and "asset:\*"
* **get_roles**_()_
gets the list of all roles

