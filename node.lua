gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
--
util.init_hosted()

local json = require "json"
local easing = require "easing"

local font = resource.load_font "Ubuntu-C.ttf"
local content = {["loaded"] = false}
local content_res = {}
util.auto_loader(content_res)
local current_page = 1
local font_size = 100
local margin = 50
local secs_per_page = 10

local logo = resource.create_colored_texture(0,0,0,0)
local white = resource.create_colored_texture(1,1,1,1)
local magenta = resource.create_colored_texture(226/255, 0/255, 116/255, 1) -- #e20074

util.json_watch("config.json", function(config)
    font = resource.load_font(config.headline_font.asset_name)
    logo = resource.load_image(config.logo.asset_name)
end)

util.json_watch("content.json", function(c)
    content = c
    if content.delay then
      secs_per_page = content.delay
    end
end)

util.data_mapper{
    ["device_info"] = function(info)
        info = json.decode(info)
        location = info.location
        description = info.description
    end,
    ["content"] = function(info)
    end
}


local function draw_text(text, align)
  local l = font:width(text, font_size)

  -- horizonal alignment: 50px from the left, then 0, 1, or 2 times the
  --   half the remaining width minus the length of the string
  local xa = math.floor(math.fmod(align-1, 3)) / 2
  local x = margin + xa * (HEIGHT - 2*margin - l)
  -- vertical alignment: 50px from top, then 0, 1, or 2 times half the height
  local ya = math.floor((align-1) / 3) / 2
  local y = margin + ya * (WIDTH - 2*margin - font_size)

  font:write(x, y, text, font_size, 1,1,1,1)
  -- magenta:draw(x, y, x+2, y+font_size)
  -- magenta:draw(x+l, y, x+l-2, y+font_size)
  -- magenta:draw(x, y, x+l, y+2)
  -- magenta:draw(x, y+font_size-2, x+l, y+font_size)
  -- font:write(margin, 150, "align="..align..",x="..tostring(x)..",y="..tostring(y), 50, 1,1,1,1)
  -- font:write(margin, 210, "l="..tostring(l)..",xa="..tostring(xa)..",ya="..tostring(ya), 50, 1,1,1,1)
end


local function draw_price(text, tween)
  local s = font_size*2
  local l = font:width(text, s)
  --local x = (HEIGHT+l*2)*(1-tween)-l
  local b = WIDTH + l
  local x = easing.outInCubic(tween, b, -l*3 - b, 1)
  font:write(x, (WIDTH+s)/3*2, text, s, 226/255, 0/255, 116/255, 1)
end


local function draw_page()
  if not content["loaded"] then
    font:write(50, 50, "Waiting for content...", 50, 1,1,1,1)
    return
  end
  current_page = math.floor(math.fmod(sys.now()/secs_per_page, #content["pages"]) + 1)
  tween = math.fmod(sys.now(), secs_per_page) / secs_per_page
  --font:write(50, 50, "page " .. tostring(current_page), 50, 1,1,1,1)
  local r
  if tween <= 0.1 then
    r = -90 + tween * 900
  elseif tween >= 0.9 then
    r = (tween - 0.9) * 900
  else
    r = 0
  end
  gl.translate(HEIGHT/2, 0)
  gl.rotate(r, 0, 1, 0)
  gl.translate(-HEIGHT/2, 0)
  if content_res[content["pages"][current_page]["image_name"]] then
    content_res[content["pages"][current_page]["image_name"]]:draw(0, 0, HEIGHT, WIDTH)
    -- magenta:draw(50, 1400, HEIGHT-350, WIDTH-50, 0.5)
    -- magenta:draw(50, 1500, HEIGHT-50, WIDTH-50, 0.5)
    -- magenta:draw(50, 1620, HEIGHT-250, WIDTH-50)
    local p = content["pages"][current_page]
    draw_text(p["teaser_text"], p["align"])
    draw_price(p["price"], tween)
    -- local i = 0
    -- for k, v in string.gmatch(content["pages"][current_page]["teaser_text"], "([^|\n]+)") do
    --   font:write(80, 1660 + 90*i, k, 100, 1,1,1,1)
    --   i = i + 1
    -- end
  else
    font:write(50, 50, "Image "..content["pages"][current_page]["image_name"].." not yet loaded", 50, 1,1,1,1)
  end
end

local function draw_logo()
  local w = 480 * 2
  local h = 518 * 2
  local x = (HEIGHT-w)/4
  local y = WIDTH-h-30
  logo:draw(x, y, x+w, y+h)
end


local fov = math.atan2(HEIGHT, WIDTH*2) * 360 / math.pi

function node.render()
    gl.clear(0.75, 0.75, 0.75, 1)
    gl.perspective(fov, WIDTH/2, HEIGHT/2, -WIDTH,
                        WIDTH/2, HEIGHT/2, 0)
    -- turn to portrait
    gl.rotate(270, 0, 0, 1)
    gl.translate(-HEIGHT, 0)
    draw_logo()
    draw_page()
end
