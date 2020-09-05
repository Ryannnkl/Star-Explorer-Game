display.setStatusBar( display.HiddenStatusBar )
local cx, cy = display.contentCenterX, display.contentCenterY
--local fundo = display.newRect( cx, cy, display.contentWidth, display.contentHeight )
local physics = require("physics")
local composer = require("composer")
physics.start()
physics.setGravity( 0, 0 )

-- gerador de seeds aleatorias
math.randomseed( os.time( ) )

local sheetOptions = {
	frames = {
		{   -- 1) asteroid 1
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        {   -- 2) asteroid 2
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        {   -- 3) asteroid 3
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        {   -- 4) ship
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {   -- 5) laser
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
	},
}
local objectSheet = graphics.newImageSheet( "./assets/gameObjects.png", sheetOptions )

-- Variaveis de inicio
local lives = 3
local score = 0
local died = false

local asteroidsTable = {}
 
local ship
local gameLoopTimer
local livesText
local scoreText
local spanMeteoros = 1000
-- iniciando grupos de displays
local backGroup = display.newGroup()  -- Displays para grupo do fundo
local mainGroup = display.newGroup()  -- Display grupo para ship, asteroids, lasers, etc.
local uiGroup = display.newGroup()    -- Display grupo para UI

local background = display.newImageRect( backGroup, "./assets/background.png", display.contentWidth, display.contentHeight )
background.x = cx
background.y = cy

ship = display.newImageRect( mainGroup, objectSheet, 4, 74, 55 ) -- (poe no grupo principal, informa a folha de estilo, informa o quadro, largura, altura)
ship.x = cx
ship.y = display.contentHeight - 70 -- -75 para subir um pouco
physics.addBody( ship, { radius=30, isSensor=true } ) --  sensor é um objeto que detecta colizão
ship.myName = "ship"

livesText = display.newText( uiGroup, "Vidas: " .. lives, 55, 30, native.systemFont, 22 )
scoreText = display.newText(uiGroup, "Pontos: " .. score, cx, 30, native.systemFont, 22 )

local function upText(  )
	livesText.text = "Lives: " .. lives
    scoreText.text = "Score: " .. score
end

local function createAsteroid()
	
	local newAsteroid = display.newImageRect(  objectSheet, 1, 102, 85 )
    table.insert( asteroidsTable, newAsteroid )
    physics.addBody( newAsteroid, "dynamic", { radius=40, bounce=0.8 } )
    newAsteroid.myName = "asteroid"

    local whereFrom = math.random( 3 )

    if whereFrom == 1 then
    	newAsteroid.x = math.random( display.contentWidth )
        newAsteroid.y = 101
        newAsteroid:setLinearVelocity( math.random( 40,120 ), math.random( 20,60 ) )
   elseif ( whereFrom == 2 ) then
        -- From the top
        newAsteroid.x = math.random( display.contentWidth )
        newAsteroid.y = 101
        newAsteroid:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) )
    elseif ( whereFrom == 3 ) then
        -- From the right
        newAsteroid.x = display.contentWidth 
        newAsteroid.y = 101
        newAsteroid:setLinearVelocity( math.random( -120,-40 ), math.random( 20,60 ) )
    end

    newAsteroid:applyTorque( math.random( -6,6 ) )

end

local function fireLaser()
 
    local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
    physics.addBody( newLaser, "dynamic", { isSensor=true } )
    newLaser.isBullet = true
    newLaser.myName = "laser"
    newLaser.x = ship.x
    newLaser.y = ship.y
    newLaser:toBack()
    transition.to( newLaser, { y=-40, time=500, 
    	onComplete = function() display.remove( newLaser ) end -- lixeira para os laysers dps do uso
    	} )
end
ship:addEventListener( "tap", fireLaser )

local function dragShip( event )
	local ship = event.target -- objeto tocado
	local phase = event.phase

	if  "began" == phase  then
        -- coloca foco na nave ao tocar 
        display.currentStage:setFocus( ship )
        ship.touchOffsetX = event.x - ship.x
        elseif "moved" == phase then
        -- Mover a nave para a nova posicão tocada
        ship.x = event.x - ship.touchOffsetX
        elseif  ("ended" == phase or "cancelled" == phase)  then
        -- retira o foco da nave ao soltar
        display.currentStage:setFocus( nil )
    end
    return true
end
ship:addEventListener( "touch", dragShip )

local function gameLoop(  )
	createAsteroid()
	for i = #asteroidsTable, 1, -1 do
		local thisAsteroid = asteroidsTable[i]
 
        if ( thisAsteroid.x < -100 or
             thisAsteroid.x > display.contentWidth + 100 or
             thisAsteroid.y < 100 or
             thisAsteroid.y > display.contentHeight + 100 )
        then
        	
            display.remove( thisAsteroid )
            table.remove( asteroidsTable, i )
        end
	end
end

gameLoopTimer = timer.performWithDelay( spanMeteoros, gameLoop, 0 )

local function restoreShip()
 
    ship.isBodyActive = false
    ship.x = cx
    ship.y = display.contentHeight - 70
 
    -- Fade in the ship
    transition.to( ship, { alpha=1, time=4000,
        onComplete = function()
            ship.isBodyActive = true
            died = false
        end
    } )
end

local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
        if ( ( obj1.myName == "laser" and obj2.myName == "asteroid" ) or
             ( obj1.myName == "asteroid" and obj2.myName == "laser" ) )
        then
 			display.remove( obj1 )
            display.remove( obj2 )

            for i = #asteroidsTable, 1, -1 do
                if ( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
                    table.remove( asteroidsTable, i )
                    break
                end
            end
            score = score + 100
            scoreText.text = "Score: " .. score

            elseif ( ( obj1.myName == "ship" and obj2.myName == "asteroid" ) or
                 ( obj1.myName == "asteroid" and obj2.myName == "ship" ) )then
            	if ( died == false ) then
 					died = true

 					lives = lives - 1
                	livesText.text = "Lives: " .. lives
                	if ( lives == 0 ) then
                    	display.remove( ship )
                	else
                    	ship.alpha = 0
                    	timer.performWithDelay( 1000, restoreShip )
                end
            end
        end
    end
end
Runtime:addEventListener( "collision", onCollision )