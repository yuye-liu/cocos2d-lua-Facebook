timer = 0
tSpace = 0

arrName = {
"Einstein", 
"Xzibit",
"Goldsmith",
"Sinatra",
"George",
"Jacko",
"Rick",
"Keanu",
"Arnie",
"Jean-Luc",
}

arrEffects = {}
showEffect = 0

function getOneFriendId()
    local info = nil
    --UNDO
    if( #gAllFriends > 0) then
        local randomIndex = math.floor(math.random() * (#gAllFriends))
        if randomIndex < 1 then
            randomIndex = 1
        end
        info = gAllFriends[randomIndex]
    end
    return info
end

GameLayer = class("GameLayer")
GameLayer.__index = GameLayer

function GameLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, GameLayer)
    return target
end

function GameLayer:init()
    self.listener1 = nil
end

function GameLayer:initData()
    gDoingGameover = false
    gSpawnTimer = 60 * 60
    gTickSpeed = 1
    gScore = 0
    gCoins = 0
    timer = 0
    tSpace = 100
    --UNDO
    gFriendInfo = getOneFriendId()

    local function loadImg(imgData)
        if nil ~= imgData then
            self.friendImg = imgData
        end
    end

    local function friendInfoCallback(response)
        print("come in friendInfoCallback")
        local responseTable = json.decode(response)
        if nil ~= responseTable then
            local url = responseTable.data.url
            LoadUrlImage.addImageAsync(url, loadImg)
        end
    end

    if nil ~= gFriendInfo then
        print("GameLayer", gFriendInfo.id, gFriendInfo.name)
        gFriendID = gFriendInfo.id
        friendName = gFriendInfo.name
        FB.api("/"..gFriendID.."/picture", {width = "90",height = "90"}, friendInfoCallback)
    else
        gFriendID = math.random(10)
        friendName = arrName[gFriendID]
    end

    self:getParent():setTitle(friendName)

    self:addTouchEvent()
end

function GameLayer:addTouchEvent()

    local function onTouchBegan(touch, event)
        print("touch began.")
        if not self:isVisible() then
            print("not visible")
            return true
        end
        local pClick = touch:getLocation()
        showEffect = 0

        for i = 1,#gEntities do
            if gEntities[i] ~= nil then
                local posX,posY = gEntities[i]:getPosition()
                local size = gEntities[i]:getContentSize()

                if isInSize(pClick, posX, posY, size) then
                    gEntities[i]:isClicked(i, pClick)
                end
            end
        end

        local effect = plusSpr.create()
        if TYPE_ADD_1 == showEffect then
            effect:init1(TYPE_ADD_1)
        elseif TYPE_ADD_2 == showEffect then
            effect:init1(TYPE_ADD_2)
            self:disParticle()
        elseif TYPE_ADD_3 == showEffect then
            effect:init1(TYPE_ADD_3)
            self.disParticle()
        else
            effect = nil
        end

        if effect ~= nil then
            effect:spawn();
            effect:setPosition(pClick)
            self:addChild(effect)
            --UNDO
            arrEffects[#arrEffects + 1] = effect
        end

        return false

    end
    self.listener1 = cc.EventListenerTouchOneByOne:create()
    self.listener1:setSwallowTouches(true)
    self.listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self.listener1, self)
end
function GameLayer:remoteTouchEvent()
    if (self.listener1 ~= nill) then
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:removeEventListener(self._listener)
        self.listener1 = nil
    end
end

function GameLayer:startGame(start)
    if start then
        self:initData()
        local function update(dt)
            if timer % tSpace==0 then
                self:spawnEntity(false)
            end

            if not gDoingGameover then
                for i = 1, #gEntities do
                   if gEntities[i] ~= nil then
                        if not gEntities[i].inScene then
                            gEntities[i]:removeFromParent(true)
                            delElement(gEntities, i)
                        end
                    end


                    if arrEffects[i] ~= nil then
                        if not arrEffects[i].inScene then
                            arrEffects[i]:removeFromParent(true)
                            delElement(arrEffects, i)
                        end
                    end
                end

                for i= 1,#gEntities do
                    if gEntities[i] ~= nil then
                        if gEntities[i].inScene then
                            gEntities[i]:tick()
                        end
                    end
                end

                for i=1,#arrEffects do
                    if arrEffects ~= nil then
                        arrEffects[i]:tick()
                    end
                end
            end

            timer = timer  + 1
        end
        
        self:scheduleUpdateWithPriorityLua(update, 0)
        self:addTouchEvent()
    else
        self:remoteTouchEvent()
    end
end

function GameLayer:addEffect(num)
    showEffect  = showEffect + 1
end

function GameLayer:disParticle()
    cclog("will addParticle.")
end

function GameLayer:endGame()
    self:unscheduleUpdate()
    self:removeAllChildren()
    gEntities = {}
    self:startGame(false)
    stManager:changeState(ST_MENU)
    _menuLayer:disResult(true)
end

function GameLayer:spawnEntity(forceFriendsOnly) 
    if forceFriendsOnly then
        entityType = 0
    else
        entityType = getRandom(0, 1)
    end
    local newEntity = entity.create()

    if entityType < 0.6 and gFriendID  ~= nil then
        if g_useFacebook then
            if self.friendImg then
                newEntity:init1(self.friendImg, true)
            else
                local nCelebToSpawn = getRandom(1, 10)
                while nCelebToSpawn == gFriendID do
                    nCelebToSpawn = getRandom(1, 10)
                end

                newEntity:init1('res/Art/nonfriend_' .. (nCelebToSpawn) ..  '.png', false)
            end
        else
            newEntity:init1('res/Art/nonfriend_' .. (gFriendID) .. '.png', true)
        end
    elseif entityType < 0.7 then
        newEntity:init1('res/Art/coin64.png', false)
        newEntity.isCoin = true
    else
        local nCelebToSpawn = getRandom(1, 10)
        while nCelebToSpawn == gFriendID do
            nCelebToSpawn = getRandom(1, 10)
        end

        newEntity:init1('res/Art/nonfriend_' .. (nCelebToSpawn) .. '.png', false)

    end

    newEntity:spawn()
    self:addChild(newEntity)
    gEntities[#gEntities + 1] = newEntity
end

function GameLayer:onEnter()
    self:init()
end

function GameLayer:onExit()
    self:unscheduleUpdate()
end

function GameLayer.create()
    local layer = GameLayer.extend(cc.Layer:create())

    local function onNodeEvent(event)
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
            layer:onExit()
        end
    end
    
    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end


function isInSize (pos, tarX, tarY, size)
    if  pos.x < tarX - size.width/2    or
        pos.x > tarX + size.width/2    or
        pos.y < tarY - size.height/2   or
        pos.y > tarY + size.height/2 then
        return false 
    end

    return true
end


function getRandom(min, max) 
    return math.random(min, max)
end

TYPE_ADD_1 = 1
TYPE_ADD_2 = 2
TYPE_ADD_3 = 3
PLUS_S = "plus_"
URL_ART = "res/Art/"

plusSpr = class("plusSpr")
plusSpr.__index = plusSpr

function plusSpr.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, plusSpr)
    return target
end

function plusSpr:init1(typeImg)
    self.img = nil
    self.life = -1
    local img = URL_ART..PLUS_S..typeImg.._PNG
    --UNDO,new check js init
    --self:init(imag)
    self.life = 30
    self.inScene = true
end

function plusSpr:spawn()
    self.velocityY = 1
end

function plusSpr:tick()
    self.posY = self:getPositionY() + self.velocityY
    self:setPositionY(self.posY)
    self.life = self.life - 1
    if self.life < 0 then
        self.inScene = false
    end
end

function plusSpr.create()
    local sprite = plusSpr.extend(cc.Sprite:create())
    return sprite
end

particle = class("particle")
particle.__index = particle

function particle.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, particle)
    return target
end

function particle:init()

end

function particle:tick()

end

function particle.create()
    local sprite = particle.extend(cc.Sprite:create())
    sprite:init()
    return sprite
end

entity = class("entity")
entity.__index = entity

function entity.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, entity)
    return target
end

function entity:init1(src, isFriend)
    self.bIsClicked = false
    self.sp = nil

    local typeSrc = type(src)
    if typeSrc == "string" then
        self.sp = cc.Sprite:create(src)
    else
        self.sp = cc.Sprite:createWithTexture(src)
    end
    
    if nil == self.sp then
        print("create with src failed")
        self.sp = cc.Sprite:create()
    end

    self:addChild(self.sp)
    self:setContentSize(self.sp:getContentSize())

    self.positionX = 0
    self.positionY = 0
    self.velocityX = 0
    self.velocityY = 0
    self.rotationalVelocity = 0
    self.rotationAngle = 0
    self.isFriend = isFriend
    self.image = src
    self.isCoin = false
    self.middleTime = 0
    self.tickY = 0
    self.rot = 9
    self.inScene = true
end

function entity:spawn()
    local sideMargin = 40
    local gCanvasWidth = winSize.width
    local gCanvasHeight = 60
    self.positionX = getRandom(-sideMargin, gCanvasWidth + sideMargin)
    self.positionY = gCanvasHeight + 30
    self:setPosition(self.positionX, self.positionY)

    self.rotationalVelocity = getRandom(-self.rot, self.rot)
    print(self.rotationalVelocity)

    local distanceToMiddle = getRandom(220, 260) - self.positionX
    self.velocityX = distanceToMiddle * getRandom(0.01, 0.015)
    self.velocityY = getRandom(9, 12)

    self.middleTime = distanceToMiddle/self.velocityX
    self.tickY = -self.velocityY / self.middleTime
end

function entity:tick() 
    self.positionX = self.positionX + self.velocityX
    self.positionY = self.positionY + self.velocityY
    self:setPosition(self.positionX, self.positionY)
    self.rotationAngle = self.rotationAngle + self.rotationalVelocity
    self.sp:setRotation(self.rotationAngle)
    self.velocityY = self.velocityY + self.tickY

    if isOutOfSize(self.positionX, self.positionY) then
        self.inScene = false
        if self.isFriend then
            lifeLayer:loseLife(1)
        end
    end
end

function entity:isClicked(sender, point)
    if not self.bIsClicked then
        if self.isCoin then
            gCoins = gCoins + 1
            self.inScene = false
            return
        end

        if self.isFriend then
            gScore = gScore  + 1
            self.inScene = false
            self:getParent():addEffect(1)
        else
            self:getParent():unscheduleUpdate();
            local scale = cc.ScaleTo:create(0.6, 5, 5)
            local rot = cc.RotateBy:create(0.6, 90, 90)
            self:runAction(rot)

            local seq = cc.Sequence:create(scale,
                cc.CallFunc:create(self.endGame))
            self:runAction(scale)
            self:runAction(seq)
        end

        self.bIsClicked = true
    end
end

function entity:endGame()
    self:getParent():endGame()
end

function entity.create()
    local sprite = entity.extend(cc.Sprite:create())
    return sprite
end

function delElement(arr, idx)
    --UNDO use table method
    local arrSize = #arr
    for i = idx ,#arr - 1 do
        arr[i] = arr[i + 1]
    end

    arr[arrSize] = nil
end

function isOutOfSize(x, y)
    if x < -60 or x > winSize.width + 60 or
       y < -60 or y > winSize.height then
        return true
    end

    return false
end

function getRand(n)
    return math.random(n)
end

