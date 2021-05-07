local M={}
local login_page = "/login2.html"
--change the value and uncomment the next line
--local jwt_secret = "MyTopSecretPassword"
local function verify(token)
  --pre-cond: token is not nil 
  local jwt = require "resty.jwt"
  local validators = require "resty.jwt-validators"
  validators.set_system_leeway(3600)
  local claim_spec = {
    user = validators.required(),
    timeout=validators.is_not_expired()
  }
  return jwt:verify(jwt_secret, token,claim_spec)
end

function M.login()
  local usrpwd=require "check_redis"
  ngx.req.read_body()
  local args, err = ngx.req.get_post_args()
  -- if user and password exist use that
  -- rather than the JWt token
  if args then
    local usr= args.user;
    local pwd = args.password;
    if (usr~=nil and pwd~=nil )  then
      local res= assert(usrpwd.verify_pwd(usr,pwd)) 
      if res  ~=0 then
	-- password succeeded
	-- then create JWT and set cookie
        local uri = ngx.var.cookie_myuri
        local jwt = require "resty.jwt"
        local jwt_token = jwt:sign ( jwt_secret,{
          header = {typ="JWT", alg="HS256"},
          payload = {user=usr, timeout=ngx.now()}
        })
        ngx.header["Set-Cookie"] = "jwt="..jwt_token..";path=/"
        ngx.ctx.usr=usr
        if uri then
          return ngx.redirect(uri)
	else
          return true
        end
      end
    end
  end
  return ngx.redirect("/login_repeat.html")
  end
  function M.verify_jwt(cur_uri)
  local jwt_token =  ngx.var.cookie_jwt
  local jwt_obj = jwt_token and verify(jwt_token)
  if jwt_obj and jwt_obj["verified"] then
    ngx.ctx.usr=jwt_obj.payload.user
  else
    -- No JWT
    -- save the current uri in a cookie 
    -- and redirect to login page
    ngx.header["Set-Cookie"] = "myuri="..cur_uri..";path=/"
    ngx.log(ngx.NOTICE,"init:myuri=",cur_uri)
    return ngx.redirect(login_page)
  end
end
function M.authn(asset)

  local jwt_token =  ngx.var.cookie_jwt
  local jwt_obj = jwt_token and verify(jwt_token)
  if jwt_obj and jwt_obj["verified"] then
    local user =jwt_obj.payload.user
    ngx.ctx.usr=user
    ngx.log(ngx.NOTICE,"user=", user, ";asset=", asset)

    local userpwd = require "check_redis"
    local results=assert(userpwd.user_auth(user,asset))
    if not results or #results==0  then
      ngx.log(ngx.NOTICE,"not authenticated: user=", user, ";asset=", asset)
      ngx.status = 401
      ngx.say(err)
      return ngx.exit(401)
    else 
      return true
    end
  else
    ngx.header["Set-Cookie"]="myuri="..ngx.var.uri..";path=/logon"
    return ngx.redirect(login_page)
  end
end
return M

