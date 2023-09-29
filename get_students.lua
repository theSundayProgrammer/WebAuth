local mysql = require "resty.mysql"
local cjson = require "cjson"
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

	ngx.log(ngx.NOTICE, "user:", ngx.ctx.usr)

        local res, err, errcode, sqlstate =
	db:query('select student_id, first_name, last_name from student')
	if not res then
		ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
		return
	end
	ngx.say(cjson.encode(res))
