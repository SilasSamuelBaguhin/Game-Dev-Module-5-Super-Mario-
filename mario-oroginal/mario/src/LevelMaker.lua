--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local flagPostColor = math.random(#FLAG_POSTS)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    --Generate ONE lock box and ONE key in a random position
    local lockBoxPosition = math.random(1, width)
    local keyPosition = math.random(1, width)
    local keySkin = math.random(1,4) -- reference to color skin used

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
    if math.random(7) == 1 and x ~= 1 and lockBoxPosition ~= x and keyPosition ~= x then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 and keyPosition ~= x then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- spawn key
            if x == keyPosition then
                table.insert(objects,
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight + 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keySkin,
                        collidable = true,
                        consumable = true,
                        solid = false,

                        -- key has its own function to add to the player's score
                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.score = player.score + 500
                            keyCollected = true
                        end    
                    }                                                                   
            )
            end

            --spawn lock box
            if x == lockBoxPosition then

                table.insert(objects,

                    --lock box
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        --make it random variant
                        frame = keySkin + 4,
                        collidable = true,
                        hit = false,
                        solid = true,
                        lockedBox = false,

                        --collision function takes itself
                            onCollide = function(obj)

                                if not obj.hit then --so that we only run this one time

                                    if keyCollected then
                                        gSounds['pickup']:play()
                                        obj.hit = true
                                        obj.lockedBox = true
                                        -- obj.lockBox = true --set to true so our code in Player.lua can make it disappear

                                        --spawn flag
                                        local flagObjects = getFlag(tiles, objects, width, height, flagPostColor)
                                        for k, obj in pairs (flagObjects) do 
                                            table.insert(objects, obj)
                                        end
                                    else
                                        gSounds['empty-block']:play()
                                    end
                                end
                            end
                    }
            )
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end

function getFlag(tiles, objects, width, height, flagPostColor)

    local flag = {}
    local yPos = 6
    local xPos = -1

    -- check valid flag position
    for x = width - 1, 1, -1 do
        if tiles[yPos][x].id == TILE_ID_EMPTY and tiles[yPos + 1][x].id == TILE_ID_GROUND then
            xPos = x
            break
        end
    end   
    
    for k, obj in pairs(objects) do
        if obj.x == (xPos - 1) * TILE_SIZE then
            table.remove(objects, k)
        end
    end

    --create flagPost
    for poleType = 2, 0, -1 do
        
        table.insert(flag, generateFlagPost(width, flagPostColor, xPos, yPos, poleType))

        if poleType == 1 then
            yPos = yPos -1
            table.insert(flag, generateFlagPost(width, flagPostColor, xPos, yPos, poleType))

            yPos = yPos -1
            table.insert(flag, generateFlagPost(width, flagPostColor, xPos, yPos, poleType))
        end

        yPos = yPos - 1
    end


    -- add flag
    table.insert(flag, generateFlag(width, xPos, yPos + 2))

    return flag
end

function generateFlag(width, xPos, yPos)
    local baseFrame = FLAGS[math.random(#FLAGS)]
    return GameObject {
        texture = 'flags',
        x = (xPos - 1) * TILE_SIZE + 8,
        y = (yPos - 1) * TILE_SIZE - 8,
        width = 16,
        height = 16,
        animation = Animation {
            frames = {baseFrame, baseFrame + 1},
            interval = 0.2
        }
    }
end

function generateFlagPost(width, flagPostColor, xPos, yPos, poleType)
    return GameObject{
        texture = 'flags',
        x = (xPos - 1) * TILE_SIZE,
        y = (yPos - 1) * TILE_SIZE,
        width = 6,
        height = 16,
        frame = flagPostColor + poleType * FLAG_OFFSET,
        collidable = true,
        consumable = true,
        solid = false,

        -- when the flag is collected, a new level starts
        onConsume = function(player, object)
            gSounds['pickup']:play()
            player.score = player.score + 250 * getFlagSegmentMultiplier(poleType)

            gStateMachine:change('play',{
                lastLevelWidth = width,
                score = player.score,
                levelComplete = true,
                keyCollected = false
            })
        end
    }
end

function getFlagSegmentMultiplier(poleType)
    if poleType == 0 then 
        return 3
    elseif poleType == 1 then
        return 2
    elseif poleType == 2 then
        return 1
    end

    return 0
end