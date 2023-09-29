    local request = require "resty.reqargs"
    local function getmsgfile()
        local file = io.open ("/home/chakra/godaddy/msgs.txt" , "a" )
        return file
    end
    ngx.log(ngx.NOTICE, 'Using \"ngx.NOTICE\"');
      
    options = {
       max_file_size    = 1024*1024*8
    }
    local status,get, post, files = pcall(request,options)
    if not status then
      ngx.status = 401
      ngx.say('{"result":"failure"}')
      return ngx.exit(401)
    elseif post then
        local file = getmsgfile()
        if file then
            file:write(" new post msg\n")
            for k,v in pairs(post) do
                file:write(k ,":", v,'\n')
            end
            file:write(" Files\n")
            for k,v in pairs(files) do
                file:write(k ,":", '\n')
                for l,w in pairs(v) do
                    file:write(l ,":", w, '\n')
                end
                file:write('\n')
            end
            io.close(file)
        else
            print("error openning file")
        end
        ngx.say('{"result":"success"}');
        return ngx.exit(200)
    elseif get then
        local file = getmsgfile()
        if file then
            file:write(" new get msg\n")
            for k,v in pairs(get) do
                file:write(k ,":", v,'\n')
            end
            io.close(file)
        else
            print("error openning file")
        end
        ngx.say('{"result":"success"}');
        return ngx.exit(200)
    else
      ngx.status = 401
      ngx.say('{"result":"failure"}')
      return ngx.exit(401)
    end
