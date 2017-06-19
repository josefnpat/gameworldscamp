local BASE_LEFT = 1
local BASE_MIDDLE = 5
local BASE_RIGHT = 9

function new_game()

  -- globals
  g_counter_missiles = {}
  g_enemy_missiles = {}
  g_next_wave = {}
  g_next_wave.dt = 0
  g_next_wave.t = 4
  g_new_game = true
  g_score = 0
  g_ammo_rate = 0
  g_targets = {}
  for i = 1,9 do
    local target = {}
    if i == BASE_LEFT or i == BASE_MIDDLE or i == BASE_RIGHT then
      target.type = "base"
      target.ammo = 4
      target.ammo_max = target.ammo
      if i == BASE_MIDDLE then
        target.speed = 600
      else
        target.speed = 300
      end
    else
      target.type = "city"
    end
    target.x = 80 * i
    target.alive = true
    target.y = 500
    table.insert(g_targets,target)
  end

end

function love.load()

  g_images = {}
  g_images.base = love.graphics.newImage("images/base.png")
  g_images.city = love.graphics.newImage("images/city.png")
  g_images.background = love.graphics.newImage("images/background.png")
  g_images.cursor = love.graphics.newImage("images/cursor.png")

  fonts = {}
  fonts.default = love.graphics.newFont("fonts/Audiowide-Regular.ttf",18)
  fonts.title = love.graphics.newFont("fonts/Audiowide-Regular.ttf",64)
  fonts.subtitle = love.graphics.newFont("fonts/Audiowide-Regular.ttf",24)
  love.graphics.setFont(fonts.default)

  g_music = love.audio.newSource("music/mmc_3.ogg")
  g_music:setLooping(true)
  g_music:play()

  g_sounds = {}
  g_sounds.explode = love.audio.newSource("sounds/explode.ogg","static")
  g_sounds.shoot = love.audio.newSource("sounds/shoot.ogg","static")
  g_sounds.space = love.audio.newSource("sounds/space.ogg","static")
  g_sounds.target = love.audio.newSource("sounds/target.ogg","static")

  new_game()

end

function love.draw()

  love.graphics.draw(g_images.background)

  love.graphics.setColor(0,0,255)
  draw_missiles(g_counter_missiles)
  love.graphics.setColor(255,255,255)

  draw_explosions()

  love.graphics.setColor(255,0,0)
  draw_missiles(g_enemy_missiles)
  love.graphics.setColor(255,255,255)

  draw_targets()

  draw_ui()
end

function draw_missiles(missiles)

  for _,missile in pairs(missiles) do
    love.graphics.line(missile.source.x,missile.source.y,missile.current.x,missile.current.y)
  end

end

function draw_targets()

  for _,target in pairs(g_targets) do
    if target.alive then
      if target.type == "base" then
        local angle = find_angle_to_mouse(target)
        if target.ammo < 1 then
          love.graphics.setColor(127,127,127)
        end
        love.graphics.draw(g_images.base,target.x,target.y,angle,1,1,32,32)
        love.graphics.printf(string.rep("I",target.ammo),target.x-32,target.y+32,64,"center")
        love.graphics.setColor(255,255,255)
      else --if target.type == "city" then
        love.graphics.draw(g_images.city,target.x,target.y,0,1,1,32,32)
      end
    end
  end

end

function draw_explosions()

  for _,missile in pairs(g_counter_missiles) do
    if missile.explode then
      love.graphics.setColor(math.random(255),math.random(255),math.random(255))
      love.graphics.circle("fill",missile.current.x,missile.current.y,missile.explode*64)
      love.graphics.setColor(255,255,255)
    end
  end

end

function draw_ui()

  love.graphics.setColor(255,255,255)

  love.graphics.setFont(fonts.subtitle)
  love.graphics.print("SCORE: "..g_score,32,32)

  if g_new_game then
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
  love.graphics.draw(g_images.cursor,mx,my,0,1,1,32,32)

end

function find_distance(origin,point)
  local deltax = origin.x - point.x
  local deltay = origin.y - point.y
  -- a^2 = b^2 + c^2
  -- sqrt(a^2) = sqrt(b^2 + c^2)
  -- a = sqrt(b^2 + c^2)
  return math.sqrt(deltax^2+deltay^2)
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

  local deltax = point.x - origin.x
  local deltay = point.y - origin.y

  -- soh cah toa
  -- 1) toa
  -- tan = opposite over adjacent
  -- tan(angle) = delta(y)/delta(x)
  -- angle = atan( delta(y) / delta(x) )
  local angle = math.atan2(deltay,deltax)

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

  for _,target in pairs(g_targets) do
    if target.alive then
      return false
    end
  end
  return true

end

function targets_alive()

  local count = 0
  for _,target in pairs(g_targets) do
    if target.alive then
      count = count + 1
    end
  end
  return count

end

function love.update(dt)

  if is_gameover() or g_new_game then
    return
  end

  update_ammo(dt)
  update_next_wave(dt)
  update_counter_missiles(dt)
  update_enemy_missiles(dt)

end

function update_ammo(dt)

  g_ammo_rate = targets_alive()/#g_targets
  for _,target in pairs(g_targets) do
    if target.alive then
      if target.type == "base" then
        target.ammo = math.min(target.ammo_max,target.ammo + dt*g_ammo_rate)
      end
    end
  end

end

function update_next_wave(dt)

  g_next_wave.dt = g_next_wave.dt + dt
  if g_next_wave.dt > g_next_wave.t then
    g_next_wave.dt = 0
    for i = 1,4 do
      local missile = {}
      -- Choose a random target
      local target = g_targets[math.random(#g_targets)]
      missile.source = {x=math.random(0,800),y=0}
      missile.current = {x=missile.source.x,y=missile.source.y}
      missile.target = target
      missile.speed = math.random(25,50)
      table.insert(g_enemy_missiles,missile)
    end
  end

end

function update_counter_missiles(dt)

  for imissile,missile in pairs(g_counter_missiles) do
    local distance = missile.speed*dt
    local distance_to_target = find_distance(missile.current,missile.target)
    if distance_to_target > distance then -- on it's way to target
      move_to_target(missile.current,missile.target,distance)
    else -- missile at target
      if distance_to_target ~= 0 then
        g_sounds.explode:stop()
        g_sounds.explode:play()
      end
      missile.current.x = missile.target.x
      missile.current.y = missile.target.y
      if missile.explode == nil then
        missile.explode = 1
      end
      missile.explode = missile.explode - dt
      if missile.explode <= 0 then
        table.remove(g_counter_missiles,imissile)
      else
        for ienemy_missile,enemy_missile in pairs(g_enemy_missiles) do
          local missile_distance = find_distance(missile.current,enemy_missile.current)
          if missile_distance < missile.explode*64 then
            table.remove(g_enemy_missiles,ienemy_missile)
            g_score = g_score + 25
            g_next_wave.t = math.max(0.25,g_next_wave.t - 0.025)
          end
        end
      end
    end
  end

end

function update_enemy_missiles(dt)

  for imissile,missile in pairs(g_enemy_missiles) do
    local distance = missile.speed*dt
    local distance_to_target = find_distance(missile.current,missile.target)
    if distance_to_target > distance then
      move_to_target(missile.current,missile.target,distance)
    else
      if missile.target.alive then
        g_sounds.target:stop()
        g_sounds.target:play()
      end
      missile.target.alive = false
      table.remove(g_enemy_missiles,imissile)
    end
  end

end

function love.mousepressed(x,y,b)

  if g_new_game then
    return
  end

  local source
  if b == 1 then -- left
    source = g_targets[BASE_LEFT]
  elseif b == 2 then -- right
    source = g_targets[BASE_RIGHT]
  elseif b == 3 then -- middle
    source = g_targets[BASE_MIDDLE]
  end
  if source and source.alive and source.ammo >= 1 then
    g_sounds.shoot:stop()
    g_sounds.shoot:play()
    source.ammo = source.ammo - 1
    local counter_missile = {}
    counter_missile.current = {x=source.x,y=source.y}
    counter_missile.source = {x=source.x,y=source.y}
    counter_missile.target = {x=x,y=y}
    counter_missile.speed = source.speed
    table.insert(g_counter_missiles,counter_missile)
  end

end

function love.keypressed(key)

  if key == "space" then
    g_sounds.space:stop()
    g_sounds.space:play()
    if g_new_game then
      g_new_game = false
    end
    if is_gameover() then
      new_game()
    end
  end

end
