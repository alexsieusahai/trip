--TODO:
--  Implement goodies to incentivize the player
--  Implement fastfall NEEDS TO BE DONE
--  Implement a diffculty curve
--  Pseudorandomize, try to make it a little harder

--player and general game
player = {}
platforms = {}
player.speed = 200
platformTimer = 0.01
maxPlatformTimer = 1.0
numPlatforms = 0
gameOver = false
yMove = 0
score = 0

-- enemy
createEnemyTimerMax = 1
createEnemyTimer = createEnemyTimerMax
enemyImg = nil
enemies = {}

--projectile
canShoot = true
canShootTimerMax = 0.5
canShootTimer = canShootTimerMax
bulletImg = nil
bullets = {}

function love.load()
    player.x = 100 
    player.y = love.graphics.getHeight()

    player.xVelocity = 0
    player.yVelocity = 0
    player.gravity = -500
    player.ground = love.graphics.getHeight()
    player.jumpHeight = -600


    -- load images
    player.img = love.graphics.newImage('purple.png')
    platformImg = love.graphics.newImage('teal.png')
    enemyImg = love.graphics.newImage('red.png')
    bulletImg = love.graphics.newImage('white.png')
end

function love.update(dt)

    -- deal with gameover case
    if not gameOver then

        -- construct the platforms
        if platformTimer < 0 then
            newPlatform = { x = 1040, y = 700, img = platformImg }
            table.insert(platforms, newPlatform)
            numPlatforms = numPlatforms + 1
            platformTimer = maxPlatformTimer
        end
        platformTimer = platformTimer - dt
        if love.keyboard.isDown('s') then
            platforms[numPlatforms].y = platforms[numPlatforms].y + dt*350
        end
        if love.keyboard.isDown('w') then 
            platforms[numPlatforms].y = platforms[numPlatforms].y - dt*350
        end
        for i, platform in ipairs(platforms) do
            platform.x = platform.x - dt*180
            -- need to handle garbage collection for platforms
        end
        
        -- implementing fastfall
        

        --handle jumping of the player
        if love.keyboard.isDown('up') then 
            if player.yVelocity == 0 or math.abs(player.y - platforms[numPlatforms].y) < 10 then
                player.yVelocity = player.jumpHeight
            end
        end
        
        -- simple game physics
        if player.yVelocity ~= 0 then
            player.y = player.y + player.yVelocity * dt
        end
        player.yVelocity = player.yVelocity - player.gravity*dt
        if player.y > player.ground then
            player.yVelocity = 0
            player.y = player.ground
        end
        if player.y > player.ground then
            player.y = player.ground
        end

        yMove = player.yVelocity * dt
        -- lets handle collisions now
        for i,platform in ipairs(platforms) do
            if checkCollisionY(player,platform,yMove) then
                player.y = platform.y
                player.yVelocity = 0
            end
            if checkFailure(player,platform) then
                gameOver = true
            end
        end

        -- implement enemies
        if createEnemyTimer < 0 then
            randomNumber = math.random(10, love.graphics.getHeight() - 10)
            newEnemy = {x = 1280, y = randomNumber, img = enemyImg}
            table.insert(enemies, newEnemy)
            createEnemyTimer = createEnemyTimerMax
        end
        createEnemyTimer = createEnemyTimer - dt

        -- update positions of enemies
        for i, enemy in ipairs(enemies) do
            enemy.x = enemy.x - (200*dt)
            if enemy.x < 0 then
                table.remove(enemies,i)
            end
        end
        
        -- handle shooting
        canShootTimer = canShootTimer - dt
        if canShootTimer < 0 then
            canShoot = true
        end
        -- implement shooting action
        if love.keyboard.isDown('right') and canShoot then
            newBullet = { x = player.x + player.img:getWidth(), y = player.y, img = bulletImg}
            canShoot = false
            canShootTimer = canShootTimerMax
            table.insert(bullets,newBullet)
        end
        
        -- update the positions of bullets
        for i,bullet in ipairs(bullets) do
            bullet.x = bullet.x + (250*dt)
            if bullet.x > love.graphics.getWidth() then 
                table.remove(bullets,i)
            end
        end

        -- handle collision of bullets and enemies
        for i,bullet in ipairs(bullets) do 
            for j,enemy in ipairs(enemies) do
                if checkCollisionBullet(enemy.x,enemy.y,enemy.img:getWidth(),enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                    table.remove(bullets,i)
                    table.remove(enemies,j)
                    score = score + 1
                end
            end
        end

        -- handle collision of enemies and player
        for i,enemy in ipairs(enemies) do
            if checkCollisionBullet(player.x,player.y,player.img:getWidth(),player.img:getHeight(), enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight()) then
                gameOver = true;
                table.remove(enemies,i)
            end
        end

    end
end

function checkCollisionY(player,platform,yMove)
    -- handle player death next
    --
    -- what happens if the player hits the side of THE NEXT block?

    if player.x > platform.x and player.x < platform.x+platform.img:getWidth() then
        if player.y > platform.y+yMove then
            player.yVelocity = 0
            player.y = platform.y
            return true
        end
    end
    return false
end

function checkCollisionBullet(x1,y1,w1,h1,x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
end
       

function checkFailure(player,platform)
    if player.x+player.img:getWidth() > platform.x and player.x < platform.x then
        if player.y-40 > platform.y then
            gameOver = true
        end
    end
    return false
end

function love.draw()
    -- handle gameover  case
    if gameOver then
        love.graphics.print("GAME OVER!", 50, 50)
    end
    love.graphics.draw(player.img,player.x,player.y, 0, 1, 1, 0, 32) -- first 0 is angle
    for i, platform in ipairs(platforms) do
        love.graphics.draw(platform.img, platform.x,platform.y)
    end
    for i,enemy in ipairs(enemies) do 
        love.graphics.draw(enemy.img,enemy.x,enemy.y)
    end

    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet.img,bullet.x,bullet.y)
    end

    love.graphics.print(score, 50, 100)
end
