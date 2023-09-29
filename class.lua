local ngx = require "ngx"
local ndk = require "ndk"
local request = require "resty.reqargs"
local date = require("date")
local mysql = require "resty.mysql"
local cjson = require "cjson"
local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
local function update_register(remote_user,present,absent)
	local db, err = mysql:new()
	if not db then
		ngx.say("failed to instantiate mysql: ", err)
		return
	end

	local ok, err, errcode, sqlstate = db:connect{
		host = "127.0.0.1",
		port = 3306,
		database = "crestwood",
		user = "teacher",
		password = "1ChapleLane",
		charset = "utf8",
		max_packet_size = 1024 * 1024,
	}

	if not ok then
		ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
		return
	end


	local cur_time=date(false):fmt("%Y/%m/%d")
	local res
	res, err, errcode, sqlstate =
	db:query('insert into lesson (lesson_date,teacher) values (\"'..cur_time..'\",'..'\"'..remote_user..'\")')
	if not res then
		ngx.say("Cannot create lesson record: ", err, ": ", errcode, ": ", sqlstate, ".")
		return
	end
	res, err, errcode, sqlstate =
	db:query('select MAX(id) from lesson where lesson_date=\"'..cur_time..'\"')
	local id
	for k,v in pairs(res) do
		for k0,v0 in pairs(v) do
			id = tonumber(v0)
		end
	end
	ngx.log(ngx.NOTICE, present);
	local s = cjson.decode(present)
	--ngx.log(ngx.NOTICE, s);
	for k,match in pairs(s) do
		local not_found = true
		local student_id
		while not_found do
			res, err, errcode, sqlstate =
			db:query('select student_id from student where first_name=UPPER(\"'..match..'\")')
			for k,v in pairs(res) do
				for k0,v0 in pairs(v) do
					student_id = tonumber(v0)
				end
			end
			if student_id then
				not_found=false
			else

				res, err, errcode, sqlstate =
				db:query('insert into student (first_name,last_name) values (UPPER(\"'..match..'\"), "UNKNOWN")')
			end


		end
		res, err, errcode, sqlstate =
		db:query("insert into attendance set "
		.."student_id="..tostring(student_id)..","
		.."lesson_id="..tostring(id))
	end                     
	if not res then
		ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
		return
	end
	local ok, err = db:close()
	if not ok then
		ngx.say("failed to close: ", err)
		return
	end
end

    ngx.log(ngx.NOTICE, 'Using \"ngx.NOTICE\"');
      
    local options = {
       max_file_size    = 1024*1024*8
    }
    local status,get, post, files = pcall(request,options)
    if not status then
      ngx.status = 401
      ngx.say('{"result":"failure"}')
      return ngx.exit(401)
    elseif post then
        update_register( ngx.var.remote_user, post["present"],post["absent"])           
        ngx.say('{"result":"success"}');
        return ngx.exit(200)
    elseif get then
        ngx.say('{"result":"fail"}');
        return ngx.exit(401)
    else
      ngx.status = 401
      ngx.say('{"result":"failure"}')
      return ngx.exit(401)
    end

