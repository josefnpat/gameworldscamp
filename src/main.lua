io.stdout:setvbuf("no")

local BASE_LEFT = 1
local BASE_MIDDLE = 5
local BASE_RIGHT = 9

function new_game()

  -- globals
  counter_missiles = {}
  enemy_missiles = {}
  next_missile_dt = 0
  next_missile_t = 4
  new_game_screen = true
  score = 0
  base_reload_rate = 0

  targets = {}
  for i = 1,9 do
    local target = {}
    if i == BASE_LEFT or i == BASE_MIDDLE or i == BASE_RIGHT then
      target.type = "base"
      target.ammo = 4
      target.ammo_max = target.ammo
      if i == BASE_LEFT or i == BASE_RIGHT then
        target.speed = 300
      else
        target.speed = 600
      end
    else
      target.type = "city"
    end
    target.x = 80 * i
    target.alive = true
    target.y = 500
    table.insert(targets,target)
  end


end

function love.load()

  new_game()

  fonts = {}
  fonts.default = love.graphics.newFont("Audiowide-Regular.ttf",18)
  fonts.title = love.graphics.newFont("Audiowide-Regular.ttf",64)
  fonts.subtitle = love.graphics.newFont("Audiowide-Regular.ttf",24)
  love.graphics.setFont(fonts.default)

  images = {}
  images.base = love.graphics.newImage("base.png")
  images.city = love.graphics.newImage("city.png")
  images.background = love.graphics.newImage("background.png")
  images.cursor = love.graphics.newImage("cursor.png")

  music = love.audio.newSource("mmc_3.ogg")

  sounds = {}
  sounds.explode = love.audio.newSource("explode.ogg","static")
  sounds.shoot = love.audio.newSource("shoot.ogg","static")
  sounds.space = love.audio.newSource("space.ogg","static")
  sounds.target = love.audio.newSource("target.ogg","static")

  music:setLooping(true)
  music:play()

end

function love.draw()

  love.graphics.draw(images.background)

  love.graphics.setColor(0,0,255)
  for _,missile in pairs(counter_missiles) do
    love.graphics.line(missile.source.x,missile.source.y,missile.current.x,missile.current.y)
  end
  love.graphics.setColor(255,255,255)

  for _,target in pairs(targets) do
    if target.alive then
      if target.type == "base" then
        local angle = find_angle_to_mouse(target)
        --love.graphics.circle("line",target.x,target.y,32)
        if target.ammo < 1 then
          love.graphics.setColor(127,127,127)
        end
        love.graphics.draw(images.base,target.x,target.y,angle,1,1,32,32)
        love.graphics.printf(string.rep("I",target.ammo),target.x-32,target.y+32,64,"center")
        love.graphics.setColor(255,255,255)
      else --if target.type == "city" then
        love.graphics.circle("fill",target.x,target.y,32)
        love.graphics.draw(images.city,target.x,target.y,0,1,1,32,32)
      end
    end
  end

  for _,missile in pairs(counter_missiles) do
    if missile.explode then
      love.graphics.setColor(math.random(255),math.random(255),math.random(255))
      love.graphics.circle("fill",missile.current.x,missile.current.y,missile.explode*64)
      love.graphics.setColor(255,255,255)
    end
  end

  love.graphics.setColor(255,0,0)
  for _,missile in pairs(enemy_missiles) do
    love.graphics.line(missile.source.x,missile.source.y,missile.current.x,missile.current.y)
  end
  love.graphics.setColor(255,255,255)

  love.graphics.setFont(fonts.subtitle)
  love.graphics.print("SCORE: "..score,32,32)

  if new_game_screen then
    love.graphics.setFont(fonts.title)
    love.graphics.printf("MISSILE COMMAND",0,150,800,"center")
    love.graphics.setFont(fonts.subtitle)
    love.graphics.printf("DEFEND CITIES",0,300,800,"center")
  elseif is_gameover() then
    love.graphics.setFont(fonts.title)
    love.graphics.printf("THE END",0,300,800,"center")
  end
  love.graphics.setFont(fonts.default)

  local mx,my = love.mouse.getPosition()
  love.graphics.draw(images.cursor,mx,my,0,1,1,32,32)

end

function find_distance(origin,point)
  local deltax = origin.x - point.x
  local deltay = origin.y - point.y
  local distance_to_target = math.sqrt(deltax^2+deltay^2)
  return distance_to_target
end

function find_angle_to_mouse(origin)
  local mx,my = love.mouse.getPosition()
  -- soh cah toa
  -- toa
  -- tan = opposite over adjacent
  -- tan(angle) = delta(y)/delta(x)
  -- angle = atan( delta(y) / delta(x) )
  local deltax = mx - origin.x
  local deltay = my - origin.y
  local angle = math.atan2(deltay,deltax)
  return angle
end

function move_to_target(origin,point,distance)
  local deltax = origin.x - point.x
  local deltay = origin.y - point.y
  -- soh cah toa
  -- 1) toa
  -- tan = opposite over adjacent
  -- tan(angle) = delta(y)/delta(x)
  -- angle = atan( delta(y) / delta(x) )
  local angle = math.atan2(deltay,deltax) + math.pi
  -- 1) soh
  -- sin = opposite / hypotenuse
  -- sin(angle) = y / distance
  -- y = sin(angle) * distance
  local y = math.sin(angle) * distance
  -- 2) cah
  -- cos = opposite / hypotenuse
  -- cos(angle) = x / distance
  -- x = cos(angle) * distance
  local x = math.cos(angle) * distance

  origin.x = origin.x + x
  origin.y = origin.y + y
end

function is_gameover()
  for _,target in pairs(targets) do
    if target.alive then
      return false
    end
  end
  return true
end

function targets_alive()
  local count = 0
  for _,target in pairs(targets) do
    if target.alive then
      count = count + 1
    end
  end
  return count
end

function love.update(dt)

  if is_gameover() or new_game_screen then
    return
  end

  base_reload_rate = targets_alive()/#targets

  for _,target in pairs(targets) do
    if target.alive then
      if target.type == "base" then
        target.ammo = math.min(target.ammo_max,target.ammo + dt*base_reload_rate)
      end
    end
  end

  next_missile_dt = next_missile_dt + dt
  if next_missile_dt > next_missile_t then
    next_missile_dt = 0
    for i = 1,4 do
      local missile = {}
      -- Choose a random target
      local target = targets[math.random(#targets)]
      missile.source = {x=math.random(0,800),y=0}
      missile.current = {x=missile.source.x,y=missile.source.y}
      missile.target = target
      missile.speed = math.random(25,50)
      table.insert(enemy_missiles,missile)
    end
  end

  for imissile,missile in pairs(counter_missiles) do

    local distance = missile.speed*dt
    local distance_to_target = find_distance(missile.current,missile.target)

    if distance_to_target > distance then -- on it's way to target
      move_to_target(missile.current,missile.target,distance)
    else -- missile at target
      if distance_to_target ~= 0 then
        sounds.explode:stop()
        sounds.explode:play()
      end
      missile.current.x = missile.target.x
      missile.current.y = missile.target.y
      if missile.explode == nil then
        missile.explode = 1
      end
      missile.explode = missile.explode - dt
      if missile.explode <= 0 then
        table.remove(counter_missiles,imissile)
      else
        for ienemy_missile,enemy_missile in pairs(enemy_missiles) do
          local missile_distance = find_distance(missile.current,enemy_missile.current)
          if missile_distance < missile.explode*64 then
            table.remove(enemy_missiles,ienemy_missile)
            score = score + 25
            next_missile_t = math.max(0.25,next_missile_t - 0.025)
          end
        end
      end
    end
  end

  for imissile,missile in pairs(enemy_missiles) do
    local distance = missile.speed*dt
    local distance_to_target = find_distance(missile.current,missile.target)
    if distance_to_target > distance then
      move_to_target(missile.current,missile.target,distance)
    else
      if missile.target.alive then
        sounds.target:stop()
        sounds.target:play()
      end
      missile.target.alive = false
      table.remove(enemy_missiles,imissile)
    end
  end

end

function love.mousepressed(x,y,b)

  if new_game_screen then
    return
  end

  local source
  if b == 1 then -- left
    source = targets[BASE_LEFT]
  elseif b == 2 then -- right
    source = targets[BASE_RIGHT]
  elseif b == 3 then -- middle
    source = targets[BASE_MIDDLE]
  end
  if source and source.alive and source.ammo >= 1 then
    sounds.shoot:stop()
    sounds.shoot:play()
    source.ammo = source.ammo - 1
    local counter_missile = {}
    counter_missile.current = {x=source.x,y=source.y}
    counter_missile.source = {x=source.x,y=source.y}
    counter_missile.target = {x=x,y=y}
    counter_missile.speed = source.speed
    table.insert(counter_missiles,counter_missile)
  end
end

function love.keypressed(key)
  if key == "space" then
    sounds.space:stop()
    sounds.space:play()
    if new_game_screen then
      new_game_screen = false
    end
    if is_gameover() then
      new_game()
    end
  end
end
