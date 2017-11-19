--TODO:
--  Implement a diffculty curve
--  Pseudorandomize, try to make it a little harder
--      - can you write that to a file then pull it up every time?
--  Implement double jump ( a little)

--player and general game
--
--DIFFICULTY IMPLEMENTATION
--  You're given only 30 seconds of time to begin with, but if you touch a yellow block then you gain more time
player = {}
platforms = {}
platformTimer = 0.01
maxPlatformTimer = 1.0
numPlatforms = 0
gameOver = false
yMove = 0
score = 0
highScore = score

-- enemy
createEnemyTimerMax = 1
createEnemyTimer = createEnemyTimerMax
enemyImg = nil
enemies = {}

--projectile
canShoot = true
canShootTimerMax = 0.4
canShootTimer = canShootTimerMax
bulletImg = nil
bullets = {}

--coins
createCoinTimerMax = 3
createCoinTimer = createCoinTimerMax
coinImg = nil
coins = {}

-- life remaining
remainingHealthTimer = 30

function love.load()
    player.x = 100 
    player.y = love.graphics.getHeight()

    player.xVelocity = 0
    player.yVelocity = 0
    player.gravity = -500
    player.ground = love.graphics.getHeight()
    player.jumpHeight = -400


    -- load images
    player.img = love.graphics.newImage('purple.png')
    platformImg = love.graphics.newImage('teal.png')
    enemyImg = love.graphics.newImage('red.png')
    bulletImg = love.graphics.newImage('black.png')
    coinImg = love.graphics.newImage('orange.png')
end

function love.update(dt)

    -- deal with gameover case
    if not gameOver then

        -- construct the platforms
        if platformTimer < 0 then
            newPlatform = { x = 600, y = 700, img = platformImg }
            table.insert(platforms, newPlatform)
            numPlatforms = numPlatforms + 1
            platformTimer = maxPlatformTimer
        end
        platformTimer = platformTimer - dt
        if love.keyboard.isDown('s') then
            if numPlatforms > 0 then
            platforms[numPlatforms].y = platforms[numPlatforms].y + dt*400
            end
        end
        if love.keyboard.isDown('w') then 
            if numPlatforms > 0 then
            platforms[numPlatforms].y = platforms[numPlatforms].y - dt*400
            end
        end
        for i, platform in ipairs(platforms) do
            platform.x = platform.x - dt*180
            -- need to handle garbage collection for platforms
        end
        
        -- implementing fastfall
        if love.keyboard.isDown('down') then
            player.yVelocity = player.yVelocity + 200*dt
        end
            

        --handle jumping of the player
        if love.keyboard.isDown('up') then 
            if player.yVelocity ~= 0 then
                player.yVelocity = player.yVelocity - 200*dt
            end
            if numPlatforms > 0 then
                if player.yVelocity == 0 or math.abs(player.y - platforms[numPlatforms].y) < 10 then
                    player.yVelocity = player.jumpHeight
                end
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
            enemy.x = enemy.x - (300*dt)
            if enemy.x < 0 then
                table.remove(enemies,i)
            end
        end

        --implement coins
        if createCoinTimer < 0 then
            randomNumber = math.random(10, love.graphics.getHeight() - 10)
            newCoin = {x = 1280, y = randomNumber, img = coinImg}
            table.insert(coins, newCoin)
            createCoinTimer = createCoinTimerMax
            remainingHealthTimer = remainingHealthTimer + 10

        end
        createCoinTimer = createCoinTimer - dt

        
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

        --update the positions of the coins
        for i,coin in ipairs(coins) do
            coin.x = coin.x - 250*dt
            if coin.x < 0 then
                table.remove(coins,i)
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

        --handle collision of coins and player
        for i,coin in ipairs(coins) do
            if checkCollisionBullet(player.x,player.y,player.img:getWidth(),player.img:getHeight(), coin.x,coin.y, coin.img:getWidth(), coin.img:getHeight()) then
                score = score + 10
                table.remove(coins,i)
            end
        end

        -- tick the remaining health
        remainingHealthTimer = remainingHealthTimer - dt

    else --what if it's gameover?
        print("restarting...")
        numPlatforms = 0
        if score > highScore then
            highScore = score
        end
        score = 0
        platforms = {}
        coins = {}
        bullets = {}
        enemies = {}
        gameOver = false
        love.timer.sleep(1)
        love.load()
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
    love.graphics.setBackgroundColor(112,128,144)
    if gameOver then
        love.graphics.print("GAME OVER!", love.graphics.getWidth()/2, love.graphics.getHeight()/2,0,5,5)
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

    for i, coin in ipairs(coins) do
        love.graphics.draw(coin.img,coin.x,coin.y)
    end
    love.graphics.print("Score:"..score, 50, 100, 0, 3, 3)
    love.graphics.print("High Score:"..highScore, 50,150,0,3,3)
    love.graphics.print("Life Remaining: "..math.floor(remainingHealthTimer), 50, 200, 0, 3,3)
end
