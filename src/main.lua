require("Cocos2d")
require("Cocos2dConstants")

cc.FileUtils:getInstance():addSearchResolutionsOrder("src")
cc.FileUtils:getInstance():addSearchResolutionsOrder("res")

res = require "resource"
require("facebook_plugin")
require("littleLayer")
require("LoadImage")
require("gameLayer")

worldWidth = 480
worldHeight = 800
SIZE_MOD = 7
winSize = cc.size(480,800)

ST_MENU = 1
ST_PLAY = 2

app_id = "290786477730812"
app_secret = "2cdc7b30f1135b0380b32baaef3adfd8"
app_namespace = "facesample"

app_url = "http://apps.facebook.com/' . $app_namespace . '/"
scope = "email,publish_actions"

gLoginStatus = false   --global login status.
stManager  = nil    --global varibale, manage game state.
g_useFacebook = false  --global varibale, is use facebook.

-- cclog
cclog = function(...)
    print(string.format(...))
end

function callback(...)
    FB.callback(...)
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
end

_menuLayer = nil
local MyLayer = class("MyLayer")
MyLayer.__index = MyLayer

function MyLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, MyLayer)
    return target
end

function MyLayer:setDisplay(visble)
    self:setVisible(visble)
end

function MyLayer:addBackground()
    self.headLayer = HeadLayer.create()
    self.headLayer:setPosition(cc.p(10, winSize.height - 100))
    self:addChild(self.headLayer)

    self.menuLayer = MenuLayer.create()
    self:addChild(self.menuLayer)
    _menuLayer = self
end

function MyLayer:disResult(display)
    if display then
        self.resultLayer = ResultLayer.create()
        self.resultLayer:setNum(gScore, gCoins)
        self.resultLayer:setPosition(cc.p(23, 120))
        self:addChild(self.resultLayer)
        self.menuLayer:setMenuTouchEnable(false)
    else
        if self.resultLayer ~= nil then
            self.resultLayer:removeFromParent(true)
            self.menuLayer:setMenuTouchEnable(true)
        end
    end
end

function MyLayer:onEnter()
    self.resultLayer = nil
    self:addBackground()
end

function MyLayer:onExit()
end

function MyLayer.create()
    local layer = MyLayer.extend(cc.Layer:create())
    if nil ~= layer then
        local function onNodeEvent(event)
            if "enter" == event then
                layer:onEnter()
            elseif "exit" == event then
                layer:onExit()
            end
        end
        layer:registerScriptHandler(onNodeEvent)
    end

    return layer
end

--count
count = 0
gTickSpeed = 0
gFriendID = 0
gScore = 0
gCoins = 0
gSpawnTimer = 0
gDoingGameover = false
gExplosionParticles = {}
gBombImages = {}
gEntities = {}
gLifeImages = {}
gExplosionTimerLength = 100

TO_RADIANS = math.pi/180

IMG_HEADER = "nonfriend_"
_PNG = ".png"

lifeLayer = nil
lifeCount = 3

PlayLayer = class("PlayLayer")
PlayLayer.__index = PlayLayer
function PlayLayer.extend(target) 
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, PlayLayer)
    return target
end

function PlayLayer:init()
    self.title = cc.Label:createWithBMFont(res.s_Arial_fnt, "smash ani")
    self.score = cc.Label:createWithBMFont(res.s_Arial_fnt, "score")
    self.life  = nil
    self.lbScore = cc.Label:createWithBMFont(res.s_Arial_fnt, "731")
    self.curScore = -1

    lifeLayer  = LifeLayer.create()
    self.title:setPosition(cc.p(10, winSize.height - 30))
    self.title:setAnchorPoint(cc.p(0, 0.5))
    self:addChild(self.title)
    self.score:setPosition(cc.p(378, winSize.height - 30))
    self:addChild(self.score)
    self.lbScore:setPosition(cc.p(421, winSize.height - 32))
    self.lbScore:setAnchorPoint(cc.p(0, 0.5))
    self:addChild(self.lbScore)
    lifeLayer:setPosition(cc.p(5, winSize.height - 130))
    self:addChild(lifeLayer)

    self.gameLayer = GameLayer.create()
    self:addChild(self.gameLayer)

    local function update(dt)
        if count % 300 == 0 then
            --cc.log("update:", count, gEntities.length);
        end
        count = count + 1

        if self.curScore ~= gScore then
            self.curScore = gScore
            self.lbScore:setString(self.curScore)
        end
    end

    self:scheduleUpdateWithPriorityLua(update, 0)
end

function PlayLayer:setTitle(name)
    self.title:setString("smash "..name.."!")
end

function PlayLayer:endGame()
    self.gameLayer:endGame()
end

function PlayLayer:setDisplay(visble) 
    self:setVisible(visble)

    if visble then
        lifeLayer:init(lifeCount)
        self.gameLayer:startGame(true)
    end
end

function PlayLayer:onEnter()
    self:init()
end

function PlayLayer:onExit()
    self:unscheduleUpdate()
end

function PlayLayer.create()
    local layer = PlayLayer.extend(cc.Layer:create())

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

local StManager = class("StManager")
function StManager:ctor()
    self.stArr = {}
    self.curSt  = -1
    self.scene   = nil
end

function StManager:init(sc)
    self.scene = sc
    self:addLayers()
end

function StManager:addLayers()
    local layer = MyLayer.create()
    self.scene:addChild(layer)
    layer:setDisplay(false)
    self.stArr[ST_MENU] = layer

    local player = PlayLayer.create()
    self.stArr[ST_PLAY] = player
    player:setDisplay(false)
    self.scene:addChild(player)

    self:changeState(ST_MENU)
end

function StManager:changeState(st)
    if self.curSt == st then
        return
    end
    print("changeState", self.curSt, self.stArr[self.curSt])
    if self.curSt >= ST_MENU and self.stArr[self.curSt] ~= nil then
        self.stArr[self.curSt]:setDisplay(false)
    end

    self.stArr[st]:setDisplay(true)
    self.curSt = st
end

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    local backLayer = cc.Layer:create()
    local bkImg     = cc.Sprite:create(res.s_frontscreen_background)
    backLayer:addChild(bkImg)
    bkImg:setAnchorPoint(cc.p(0, 0))
    bkImg:setPosition(cc.p(0, -70))

    local sceneGame = cc.Scene:create()
    sceneGame:addChild(backLayer)

    stManager = StManager.new()
    stManager:init(sceneGame)

    if nil ~= cc.Director:getInstance():getRunningScene() then
		cc.Director:getInstance():replaceScene(sceneGame)
	else
		cc.Director:getInstance():runWithScene(sceneGame)
	end
end


xpcall(main, __G__TRACKBACK__)
