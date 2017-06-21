missilecommandlib = require "missilecommand"

function love.load()

  g_images = {}
  g_images.background = love.graphics.newImage("images/background.png")
  g_images.cursor = love.graphics.newImage("images/cursor.png")

  new_game()

end

function new_game()

  g_mc = missilecommandlib.new()

end

function love.draw()

  love.graphics.draw(g_images.background)

  draw_ui()

end

function draw_ui()

  local mousex,mousey = love.mouse.getPosition()
  love.graphics.draw(g_images.cursor,mousex,mousey,0,1,1,32,32)

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
