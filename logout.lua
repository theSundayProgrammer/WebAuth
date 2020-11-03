local M={}
function M.init()
  local jwt_token =  ngx.var.cookie_jwt
  if not jwt_token then return end

      ngx.header["Set-Cookie"] = "jwt=;Max-Age=0;path=/"
end
return M

