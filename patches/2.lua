function love.load()

  g_images = {}
  g_images.background = love.graphics.newImage("images/background.png")
  g_images.cursor = love.graphics.newImage("images/cursor.png")

end

function love.draw()

  love.graphics.draw(g_images.background)

  draw_ui()

end

function draw_ui()

  local mousex,mousey = love.mouse.getPosition()
  love.graphics.draw(g_images.cursor,mousex,mousey,0,1,1,32,32)

end
