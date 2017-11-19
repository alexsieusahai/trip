--TODO:
--  Powerups

--player and general game
player = {}
platforms = {}
platformTimer = 0.01
maxPlatformTimer = 1.0
numPlatforms = 0
gameOver = false
yMove = 0
score = 0
highScore = score

-- lets blink the player if he takes damage
numBlinks = -1
blink = false

-- try this
oldPlatformHeight = 700

-- enemy
createEnemyTimerMax = 0.2
createEnemyTimer = createEnemyTimerMax
enemyImg = nil
enemies = {}

--projectile
canShoot = true
canShootTimerMax = 0.3
canShootTimer = canShootTimerMax
bulletImg = nil
bullets = {}

--coins
createCoinTimerMax = 3
createCoinTimer = createCoinTimerMax
coinImg = nil
coins = {}

-- life remaining
remainingHealthTimer = 3

function love.load()
    player.x = 100 
    player.y = love.graphics.getHeight()

    player.xVelocity = 0
    player.yVelocity = 0
    player.gravity = -900
    player.ground = love.graphics.getHeight()
    player.jumpHeight = -700


    -- load images
    player.img = love.graphics.newImage('purple.png')
    platformImg = love.graphics.newImage('tealBig.png')
    enemyImg = love.graphics.newImage('red.png')
    bulletImg = love.graphics.newImage('black.png') coinImg = love.graphics.newImage('orange.png')
end

function love.update(dt)

    -- deal with gameover case
    if not gameOver then

        -- construct the platforms
        if platformTimer < 0 then
            newPlatform = { x = 600, y = oldPlatformHeight, img = platformImg }
            table.insert(platforms, newPlatform)
            numPlatforms = numPlatforms + 1
            platformTimer = maxPlatformTimer
        end

        platformTimer = platformTimer - dt
        if numPlatforms > 0 then
            oldPlatformHeight = platforms[numPlatforms].y
        end

        if love.keyboard.isDown('down') then
            if numPlatforms > 0 then
                platforms[numPlatforms].y = platforms[numPlatforms].y + dt*400
                if platforms[numPlatforms].y > 700 then
                    platforms[numPlatforms].y = 700
                end
            end
        end
        if love.keyboard.isDown('up') then 
            if numPlatforms > 0 then
                platforms[numPlatforms].y = platforms[numPlatforms].y - dt*400
            end
        end
        for i, platform in ipairs(platforms) do
            platform.x = platform.x - dt*300
            -- need to handle garbage collection for platforms
        end
        
        -- implementing fastfall
        if love.keyboard.isDown('s') then
            player.yVelocity = player.yVelocity + 200*dt
        end

        if love.keyboard.isDown('a') then
            player.x = player.x - dt*400
        end

        if player.x < 0 then
            gameOver = true
        end
        

        --handle jumping of the player
        if love.keyboard.isDown('w') then 
            if player.yVelocity ~= 0 then
                player.yVelocity = player.yVelocity - 200*dt
            end
            if numPlatforms > 0 then
                if player.yVelocity == 0 then
                    player.yVelocity = player.jumpHeight
                end
            end
        end
        
        if love.keyboard.isDown('d') then
            player.x = player.x + dt*200
            if player.x > 400 then
                player.x = 400 
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
                player.x = platform.x-player.img:getWidth()
            end
        end

        -- implement enemies
        if createEnemyTimer < 0 then
            -- is pseudorandom better than totally random or no?

            --randomNumber = math.random(10, love.graphics.getHeight() - 10)
            randomNumber = math.random(player.y-250,player.y+250)

            newEnemy = {x = 1280, y = randomNumber, img = enemyImg}
            table.insert(enemies, newEnemy)
            createEnemyTimer = createEnemyTimerMax
        end
        createEnemyTimer = createEnemyTimer - dt

        -- update positions of enemies
        for i, enemy in ipairs(enemies) do
            enemy.x = enemy.x - (500*dt)
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

        end
        createCoinTimer = createCoinTimer - dt

        
        -- handle shooting
        canShootTimer = canShootTimer - dt
        if canShootTimer < 0 then
            canShoot = true
        end
        -- implement shooting action
        if canShoot then
                newBullet = { x = player.x + player.img:getWidth(), y = player.y-player.img:getHeight()/2, img = bulletImg}
                canShoot = false
                canShootTimer = canShootTimerMax
                table.insert(bullets,newBullet)
        end
        
        -- update the positions of bullets
        for i,bullet in ipairs(bullets) do
            bullet.x = bullet.x + (350*dt)
            if bullet.x > love.graphics.getWidth() then 
                table.remove(bullets,i)
            end
        end

        --update the positions of the coins
        for i,coin in ipairs(coins) do
            coin.x = coin.x - 300*dt
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
            if checkCollisionSquares(player.x,player.y, enemy.x, enemy.y, enemy.img:getHeight()) then
                remainingHealthTimer = remainingHealthTimer - 1
                numBlinks = 6
                table.remove(enemies,i)
            end
        end

        --handle collision of coins and player
        for i,coin in ipairs(coins) do
            --if checkCollisionLenient(player.x,player.y,player.img:getWidth(),player.img:getHeight(), coin.x,coin.y, coin.img:getWidth(), coin.img:getHeight()) then
            if checkCollisionSquares(player.x,player.y,coin.x-4,coin.y+4,player.img:getHeight()) then
                score = score + 10
                remainingHealthTimer = remainingHealthTimer + 1
                table.remove(coins,i)
            end
        end

        -- tick the remaining health
        if remainingHealthTimer <= 0 then
            gameOver = true
        end

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
        remainingHealthTimer = 3
        enemies = {}
        numBlinks = -1
        oldPlatformHeight = 700
        gameOver = false
        love.timer.sleep(1)
        love.load()
    end
end

function checkCollisionSquares(x1,y1,x2,y2,r)
    if math.abs(x1-x2) < r and math.abs(y1-y2) < r then
        return true
    end
    return false
end


function checkCollisionY(player,platform,yMove)
    -- handle player death next
    --
    -- what happens if the player hits the side of THE NEXT block?

    if player.x > platform.x and player.x < platform.x+platform.img:getWidth() then
        if player.y > platform.y+yMove then
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
       
function checkCollisionLenient(x1,y1,w1,h1,x2,y2,w2,h2)
    return x1-x2-w2 < 10  and
           x2-x1-w1 < 10 and
           y1-y2-h2 < 10 and
           y2-y1-h1 < 10 
end

function checkCollision(x1,y1,w1,h1,x2,y2,w2,h2)
end


function checkFailure(player,platform)
    if player.x+player.img:getWidth() > platform.x and player.x < platform.x then
        if player.y-40 > platform.y then
            return true
        end
    end
    return false
end

function love.draw()
    -- handle gameover case
    love.graphics.rectangle('fill',0,0,10,love.graphics.getHeight())
    love.graphics.setBackgroundColor(112,128,144)
    if gameOver then
        love.graphics.print("GAME OVER!", love.graphics.getWidth()/2, 100,0,5,5)
    end
    love.graphics.draw(player.img,player.x,player.y, 0, 1, 1, 0, 32) -- first 0 is angle
    for i, platform in ipairs(platforms) do
        love.graphics.draw(platform.img, platform.x,platform.y)
    end
    for i,enemy in ipairs(enemies) do 
        love.graphics.draw(enemy.img,enemy.x,enemy.y)
    end

    -- lets handle blinking
    if numBlinks >= 0 then
        numBlinks = numBlinks - 1
        if numBlinks % 2 == 0 then
            player.img = love.graphics.newImage('white.png')
        else
            player.img = love.graphics.newImage('purple.png')
        end
    end

    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet.img,bullet.x,bullet.y)
    end

    for i, coin in ipairs(coins) do
        love.graphics.draw(coin.img,coin.x,coin.y)
    end
    love.graphics.print("Score:"..score, 50, 100, 0, 3, 3)
    love.graphics.print("High Score:"..highScore, 50,150,0,3,3)
    love.graphics.print("Lives Remaining: "..math.floor(remainingHealthTimer), 50, 200, 0, 3,3)
end
