--     greyhole
-- but for
--     norns
--
-- ----------
--
-- key1 = alt
-- enc1 = time
-- enc2 = size
-- enc3 = damp
-- alt + enc2 = diff
-- alt + enc3 = feedback
--
-- https://llllllll.co/t/27687
-- @justmat

engine.name = "Greyhole"

local alt = false

local lfo = include("lib/hnds_greyhole")
local lfo_targets = {
  "none",
  "time",
  "size",
  "damp",
  "diff",
  "feedback",
  "mod_depth",
  "mod_freq"
}


function lfo.process()
  -- for lib hnds
  for i = 1, 4 do
    local target = params:get(i .. "lfo_target")
    if params:get(i .. "lfo") == 2 then
      -- delay time
      if target == 2 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 6.00))
      -- size
      elseif target == 3 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.50, 5.00))
      -- dampening
      elseif target == 4 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 1.00))
      -- diffusion
      elseif target == 5 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 1.00))
      -- feedback
      elseif target == 6 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 1.00))
      -- delay line modulation depth
      elseif target == 7 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 1.00))
      -- delay line modulation frequency
      elseif target == 8 then
        params:set(lfo_targets[target], lfo.scale(lfo[i].slope, -1.0, 2.0, 0.00, 10.00))
      end
    end
  end
end


function init()
  -- params
  -- delay time
  params:add_control("time", "time", controlspec.new(0.00, 6.00, "lin", 0.01, 2.00, ""))
  params:set_action("time", function(value) engine.delay_time(value) end)
  -- delay size
  params:add_control("size", "size", controlspec.new(0.5, 5.0, "lin", 0.01, 2.00, ""))
  params:set_action("size", function(value) engine.delay_size(value) end)
  -- dampening 
  params:add_control("damp", "damp", controlspec.new(0.0, 1.0, "lin", 0.01, 0.10, ""))
  params:set_action("damp", function(value) engine.delay_damp(value) end)
  -- diffusion
  params:add_control("diff", "diff", controlspec.new(0.0, 1.0, "lin", 0.01, 0.707, ""))
  params:set_action("diff", function(value) engine.delay_diff(value) end)
  -- feedback
  params:add_control("feedback", "feedback", controlspec.new(0.00, 1.0, "lin", 0.01, 0.20, ""))
  params:set_action("feedback", function(value) engine.delay_fdbk(value) end)
  -- mod depth
  params:add_control("mod_depth", "mod depth", controlspec.new(0.0, 1.0, "lin", 0.01, 0.00, ""))
  params:set_action("mod_depth", function(value) engine.delay_mod_depth(value) end)
  -- mod rate
  params:add_control("mod_freq", "mod freq", controlspec.new(0.0, 10.0, "lin", 0.01, 0.10, "hz"))
  params:set_action("mod_freq", function(value) engine.delay_mod_freq(value) end)

  -- for hnds
  for i = 1, 4 do
    lfo[i].lfo_targets = lfo_targets
  end
  lfo.init()

  norns.enc.sens(1, 5)

  -- redraw timer
  screen_metro = metro.init()
  screen_metro.time = 1/15
  screen_metro.event = function() redraw() end
  screen_metro:start()
end


function key(n, z)
  if n == 1 then alt = z == 1 and true or false end
end


function enc(n, d)
  if alt then
    if n == 2 then
      params:delta("diff", d)
    elseif n == 3 then
      params:delta("feedback", d)
    end
  else
    if n == 1 then
      params:delta("time", d)
    elseif n == 2 then
      params:delta("size", d)
    elseif n == 3 then
      params:delta("damp", d)
    end
  end
end



function redraw()
  screen.clear()
  screen.aa(0)
  screen.level(15)
  screen.move(5, 15)
  screen.font_face(1)
  screen.font_size(16)
  screen.text("greyhole")
  screen.move(75, 15)
  screen.line(120, 15)
  screen.stroke()
  -- controls
  screen.font_size(8)

  screen.level(alt and 2 or 10)
  screen.move(8, 28)
  screen.text("time:")
  screen.move(120, 28)
  screen.font_face(2)
  screen.text_right(format_float(params:get("time"), 2, 2))
  screen.font_face(1)

  screen.move(8, 36)
  screen.text("size:  ")
  screen.move(120, 36)
  screen.font_face(2)
  screen.text_right(format_float(params:get("size"), 2, 2))
  screen.font_face(1)

  screen.move(8, 44)
  screen.text("damp:  ")
  screen.move(120, 44)
  screen.font_face(2)
  screen.text_right(format_float(params:get("damp"), 2, 2))
  screen.font_face(1)
  
  screen.level(alt and 10 or 2)
  screen.move(8, 52)
  screen.text("diff:  ")
  screen.move(120, 52)
  screen.font_face(2)
  screen.text_right(format_float(params:get("diff"), 2, 2))
  screen.font_face(1)

  screen.move(8, 60)
  screen.text("fdbk:  ")
  screen.move(120, 60)
  screen.font_face(2)
  screen.text_right(format_float(params:get("feedback"), 2, 2))

  screen.update()
end

function format_float(num, min_places, max_places)
  -- TODO: exception for min > max
  local buffer = {}
  local s = tostring(num)
  local point_index = string.find(s, "%.")
  
  -- find index of '.' in floating point
  -- if an int, just return a string of num
  if point_index == nil then
    return s
  end
  
  digits_after_point = string.sub(s, point_index + 1, point_index + max_places + 1)
  
  if #digits_after_point > max_places then
    -- float has more precision than max_places, ROUND UP if neccessary
    for i = 1, #digits_after_point do
      -- put all trailing zeroes in string buffer
      if string.sub(digits_after_point, i, i) == '0' then
        table.insert(buffer, '0')
      else
        -- first non-zero character at ith index after .
        first_nz = i
        break
      end
    end
    
    round_digit = string.sub(digits_after_point, #digits_after_point, #digits_after_point)
    
    if round_digit >= '5' then
      digits_after_zeroes = string.sub(digits_after_point, first_nz, #digits_after_point) + 5
    else
      digits_after_zeroes = string.sub(digits_after_point, first_nz, #digits_after_point)
    end
    
    -- truncate the rounding digit and floating point if string was converted to a num
    table.insert(buffer, string.sub(digits_after_zeroes, 1, #digits_after_point - first_nz))
  else
    -- float has less than max_places, no rounding neccessary
    after_point = string.sub(s, point_index + 1, point_index + max_places)
    table.insert(buffer, after_point)
    table.insert(buffer, string.rep("0", min_places - string.len(after_point)) )
  end
  
  return (string.sub(s, 0, point_index) .. table.concat(buffer))
end
