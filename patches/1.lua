function love.load()

  g_images = {}
  g_images.background = love.graphics.newImage("images/background.png")

end

function love.draw()

  love.graphics.draw(g_images.background)

end
