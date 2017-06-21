local missile_command = {}

-- Locations of the bases
local BASE_LEFT = 1
local BASE_MIDDLE = 5
local BASE_RIGHT = 9

-- Create a new class object
function missile_command.new()

  -- here we create the class object
  local self = {}

  -- add the "private" variables. We do this by using the _prefix, but as
  -- with most things in Lua, it's not enforced.
  self._counter_missiles = {}
  self._enemy_missiles = {}
  self._next_wave = {}
  self._next_wave.dt = 0
  self._next_wave.t = 4
  self._new_game = true
  self._score = 0
  self._ammo_rate = 0
  self._targets = {}

  -- set up the targets (bases and cities) with default values.
  for i = 1,9 do
    local target = {}
    if i == BASE_LEFT or i == BASE_MIDDLE or i == BASE_RIGHT then
      target.type = "base"
      target.ammo = 4
      target.ammo_max = target.ammo
      if i == BASE_MIDDLE then -- middle base shoots faster!
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
    table.insert(self._targets,target)
  end

  -- hook up all the classes that we can use
  self.is_new_game = missile_command.is_new_game
  self.start_new_game = missile_command.start_new_game
  self.get_score = missile_command.get_score
  self.is_gameover = missile_command.is_gameover
  self.update_ammo = missile_command.update_ammo
  self.update_next_wave = missile_command.update_next_wave
  self.is_missile_exploding = missile_command.is_missile_exploding
  self.is_gameover = missile_command.is_gameover
  self.get_targets = missile_command.get_targets
  self._targets_alive = missile_command._targets_alive
  self.get_targets = missile_command.get_targets
  self.update_ammo = missile_command.update_ammo
  self.update_next_wave = missile_command.update_next_wave
  self.is_missile_exploding = missile_command.is_missile_exploding
  self.update_counter_missiles = missile_command.update_counter_missiles
  self.fire_counter_missile = missile_command.fire_counter_missile
  self.get_counter_missiles = missile_command.get_counter_missiles
  self.is_target_exploding = missile_command.is_target_exploding
  self.update_enemy_missiles = missile_command.update_enemy_missiles
  self.get_enemy_missiles = missile_command.get_enemy_missiles
  self.find_angle_to_position = missile_command.find_angle_to_position
  self._find_distance = missile_command._find_distance
  self._move_to_target = missile_command._move_to_target

  -- return the "class" object for actual usage
  return self

end

-- start a new game
function missile_command.start_new_game(self)

  self._new_game = false

end

-- determine if this is a new game
function missile_command.is_new_game(self)

  return self._new_game

end

-- get the current score
function missile_command.get_score(self)

  return self._score

end

-- determine if the game is over
function missile_command.is_gameover(self)

  for _,target in pairs(self._targets) do
    if target.alive then
      return false
    end
  end
  return true

end

-- get the targets (bases and cities) in a table
function missile_command.get_targets(self)

  return self._targets

end

-- count how many targets are left
function missile_command._targets_alive(self)

  local count = 0
  for _,target in pairs(self._targets) do
    if target.alive then
      count = count + 1
    end
  end
  return count

end

-- increase the ammo for the bases over time depending on how many targets are
-- still alive.
function missile_command.update_ammo(self,dt)

  self._ammo_rate = self:_targets_alive()/#self._targets
  for _,target in pairs(self._targets) do
    if target.alive then
      if target.type == "base" then
        target.ammo = math.min(
          target.ammo_max, -- clamp
          target.ammo + dt*self._ammo_rate)
      end
    end
  end

end

-- update the game for when the next wave of enemy missiles launch
function missile_command.update_next_wave(self,dt)

  self._next_wave.dt = self._next_wave.dt + dt
  if self._next_wave.dt > self._next_wave.t then
    self._next_wave.dt = 0
    for i = 1,4 do -- add four of them
      local missile = {}
      -- Choose a random target
      local target = self._targets[math.random(#self._targets)]
      missile.source = {x=math.random(0,800),y=0}
      missile.current = {x=missile.source.x,y=missile.source.y}
      missile.target = target
      missile.speed = math.random(25,50)
      table.insert(self._enemy_missiles,missile)
    end
  end

end

-- determines if a missile exploded
function missile_command.is_missile_exploding(self)

  if self._missile_exploding then
    self._missile_exploding = false
    return true
  end
  return false

end

-- update counter missiles so that they move to their target and explode,
-- causing enemy missiles within range to also explode.
function missile_command.update_counter_missiles(self,dt)

  for imissile,missile in pairs(self._counter_missiles) do
    local distance = missile.speed*dt
    local distance_to_target = self:_find_distance(missile.current,missile.target)
    if distance_to_target > distance then -- on it's way to target
      self:_move_to_target(missile.current,missile.target,distance)
    else -- missile at target
      if distance_to_target ~= 0 then
        self._missile_exploding = true
      end
      missile.current.x = missile.target.x
      missile.current.y = missile.target.y
      if missile.explode == nil then
        missile.explode = 1
      end
      missile.explode = missile.explode - dt
      if missile.explode <= 0 then
        table.remove(self._counter_missiles,imissile)
      else
        -- destroy all enemy missiles within range
        for ienemy_missile,enemy_missile in pairs(self._enemy_missiles) do
          local missile_distance = self:_find_distance(missile.current,enemy_missile.current)
          if missile_distance < missile.explode*64 then
            table.remove(self._enemy_missiles,ienemy_missile)
            self._score = self._score + 25
            self._next_wave.t = math.max(0.25,self._next_wave.t - 0.025)
          end
        end
      end
    end
  end

end

-- shoot a counter missile to destroy enemy missiles.
function missile_command.fire_counter_missile(self,x,y,b)

  local source
  if b == 1 then -- left
    source = self._targets[BASE_LEFT]
  elseif b == 2 then -- right
    source = self._targets[BASE_RIGHT]
  elseif b == 3 then -- middle
    source = self._targets[BASE_MIDDLE]
  end
  if source and source.alive and source.ammo >= 1 then
    source.ammo = source.ammo - 1
    local counter_missile = {}
    counter_missile.current = {x=source.x,y=source.y}
    counter_missile.source = {x=source.x,y=source.y}
    counter_missile.target = {x=x,y=y}
    counter_missile.speed = source.speed
    table.insert(self._counter_missiles,counter_missile)
    return true
  end
  return false

end

-- return a table containing the counter missiles
function missile_command.get_counter_missiles(self)

  return self._counter_missiles

end

-- determine if a target is exploding
function missile_command.is_target_exploding(self)

  if self._target_exploding then
    self._target_exploding = false
    return true
  end
  return false

end

-- update the target missiles so they move to targets and destroy them when they
-- come in contact.
function missile_command.update_enemy_missiles(self,dt)

  for imissile,missile in pairs(self._enemy_missiles) do
    local distance = missile.speed*dt
    local distance_to_target = self:_find_distance(missile.current,missile.target)
    if distance_to_target > distance then -- on it's way
      self:_move_to_target(missile.current,missile.target,distance)
    else -- at it's target
      if missile.target.alive then
        self._target_exploding = true
      end
      missile.target.alive = false
      table.remove(self._enemy_missiles,imissile)
    end
  end

end

-- get a table containing the enemy missiles
function missile_command.get_enemy_missiles(self)

  return self._enemy_missiles

end

-- find the angle to a position
function missile_command.find_angle_to_position(self,origin,x,y)

  local deltax = x - origin.x
  local deltay = y - origin.y

  -- soh cah toa
  -- toa
  -- tan = opposite over adjacent
  -- tan(angle) = delta(y)/delta(x)
  -- angle = atan( delta(y) / delta(x) )

  return math.atan2(deltay,deltax)

end

-- find the distance between two points
function missile_command._find_distance(self,origin,point)

  local deltax = origin.x - point.x
  local deltay = origin.y - point.y

  -- a^2 = b^2 + c^2
  -- sqrt(a^2) = sqrt(b^2 + c^2)
  -- a = sqrt(b^2 + c^2)
  return math.sqrt(deltax^2+deltay^2)

end

-- move the origin closer to a point by a given distance
function missile_command._move_to_target(self,origin,point,distance)

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

return missile_command
