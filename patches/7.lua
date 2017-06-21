missilecommandlib = require "missilecommand"

function love.load()

  g_images = {}
  g_images.background = love.graphics.newImage("images/background.png")
  g_images.cursor = love.graphics.newImage("images/cursor.png")
  g_images.base = love.graphics.newImage("images/base.png")
  g_images.city = love.graphics.newImage("images/city.png")

  new_game()

end

function new_game()

  g_mc = missilecommandlib.new()

end

function love.draw()

  love.graphics.draw(g_images.background)

  love.graphics.setColor(0,0,255)
  draw_missiles(g_mc:get_counter_missiles())
  love.graphics.setColor(255,255,255)

  draw_explosions(g_mc:get_counter_missiles())

  love.graphics.setColor(255,0,0)
  draw_missiles(g_mc:get_enemy_missiles())
  love.graphics.setColor(255,255,255)

  draw_targets(g_mc:get_targets())

  draw_ui()

end

function draw_missiles(missiles)

  for _,missile in pairs(missiles) do
    love.graphics.line(missile.source.x,missile.source.y,missile.current.x,missile.current.y)
  end

end

function draw_targets(targets)

  for _,target in pairs(targets) do
    if target.alive then
      if target.type == "base" then
        local mousex,mousey = love.mouse.getPosition()
        local angle = g_mc:find_angle_to_position(target,mousex,mousey)
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

function draw_explosions(counter_missiles)

  for _,missile in pairs(counter_missiles) do
    if missile.explode then
      love.graphics.setColor(math.random(255),math.random(255),math.random(255))
      love.graphics.circle("fill",missile.current.x,missile.current.y,missile.explode*64)
    end
  end
  love.graphics.setColor(255,255,255)

end

function draw_ui()

  local mousex,mousey = love.mouse.getPosition()
  love.graphics.draw(g_images.cursor,mousex,mousey,0,1,1,32,32)

end

function love.update(dt)

  if not g_mc:is_gameover() and not g_mc:is_new_game() then
    g_mc:update_ammo(dt)
    g_mc:update_counter_missiles(dt)
    g_mc:update_enemy_missiles(dt)
    g_mc:update_next_wave(dt)
  end

end

function love.mousepressed(x,y,button)

  if not g_mc:is_new_game() then
    g_mc:fire_counter_missile(x,y,button)
  end

end

function love.keypressed(key)

  if key == "space" then
    if g_mc:is_new_game() then
      g_mc:start_new_game()
    end
    if g_mc:is_gameover() then
      new_game()
    end
  end

end
