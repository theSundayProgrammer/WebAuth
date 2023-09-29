local function compute(x,y)
  if (x+y)%2 == 0 then
    return x+y
  else
    error("uneven values")
  end
end

local function try_compute( x,y ,comp)
  return  assert(compute(x,y))
end

local result,err = try_compute(10,20,compute)
if not result then print(err) end
local result,err = pcall(try_compute,10,21,compute)
if not result then print(err) end
local result,err = try_compute(10,22,compute)
if not result then print(err) end
