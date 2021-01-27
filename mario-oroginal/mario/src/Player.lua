--[[
    GD50
    Super Mario Bros. Remake

    -- Player Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Player = Class{__includes = Entity}

function Player:init(def, score)
    Entity.init(self, def)
    self.score = score
    self.levelComplete = def.levelComplete

    if self.levelComplete then
        Timer.after(4, function () self.levelComplete = false end)
    end
end

function Player:update(dt)
    Entity.update(self, dt)
end

function Player:render()
    Entity.render(self)
end

function Player:renderLevelComplete()
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.printf("Level Complete!", 0, 5, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf("Level Complete!", 0, 4, VIRTUAL_WIDTH - 1, 'center')
end

function Player:checkLeftCollisions(dt)
    -- check for left two tiles collision
    local tileTopLeft = self.map:pointToTile(self.x + 1, self.y + 1)
    local tileBottomLeft = self.map:pointToTile(self.x + 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopLeft and tileBottomLeft) and (tileTopLeft:collidable() or tileBottomLeft:collidable()) then
        self.x = (tileTopLeft.x - 1) * TILE_SIZE + tileTopLeft.width - 1
    else
        
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object
        if #collidedObjects > 0 then
            self.x = self.x + PLAYER_WALK_SPEED * dt
        end
    end
end

function Player:checkRightCollisions(dt)
    -- check for right two tiles collision
    local tileTopRight = self.map:pointToTile(self.x + self.width - 1, self.y + 1)
    local tileBottomRight = self.map:pointToTile(self.x + self.width - 1, self.y + self.height - 1)

    -- place player outside the X bounds on one of the tiles to reset any overlap
    if (tileTopRight and tileBottomRight) and (tileTopRight:collidable() or tileBottomRight:collidable()) then
        self.x = (tileTopRight.x - 1) * TILE_SIZE - self.width
    else
        
        self.y = self.y - 1
        local collidedObjects = self:checkObjectCollisions()
        self.y = self.y + 1

        -- reset X if new collided object
        if #collidedObjects > 0 then
            self.x = self.x - PLAYER_WALK_SPEED * dt
        end
    end
end

function Player:checkObjectCollisions()
    local collidedObjects = {}

    for k, object in pairs(self.level.objects) do
        if object:collides(self) then
            if object.solid then
                table.insert(collidedObjects, object)
            elseif object.consumable then
                object.onConsume(self)
                table.remove(self.level.objects, k)
            end

            --For removing a locked box if needed
            if object.lockedBox and keyCollected then
                table.remove(self.level.objects, k)
            end
        end
    end

    return collidedObjects
end