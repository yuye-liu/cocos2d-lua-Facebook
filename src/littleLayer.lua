require("json")

alreadyLogin = false

BTN_PLAY = 0
BTN_BRAG = 1
BTN_CHALLENGE = 2
BTN_STORE = 3


btn_x = 0
btn_y = 0
btn_w = 300
btn_h = 90

MenuLayer = class("MenuLayer")
MenuLayer.__index = MenuLayer
function MenuLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, MenuLayer)
    return target
end

function MenuLayer:init()
    self:initData()
end

function MenuLayer:setDisplay(visible)
    self:setVisible(visible)
end

function MenuLayer:initData()
    local play = self:getBtn(res.s_button_play, res.s_button_play_hot, BTN_PLAY)
    play:setPosition(cc.p(0, btn_h*2))
    local brag = self:getBtn(res.s_button_brag, res.s_button_brag_hot, BTN_BRAG)
    brag:setPosition(cc.p(0, btn_h))
    local challenge = self:getBtn(res.s_button_challenge, res.s_button_challenge_hot, BTN_CHALLENGE)
    challenge:setPosition(cc.p(0, 0))
        
    local size = play:getContentSize()
    self.menu = cc.Menu:create(play, brag, challenge)
    self:addChild(self.menu)
    self.menu:setPosition(cc.p(size.width/2, size.height/2))
end

function MenuLayer:setMenuTouchEnable(enable)
    if self.menu ~= nil then

    end
end

-- function fbCallback(response)
-- end

-- function requestCallback(response)
-- end

function MenuLayer:getBtn(normal, down, tag)
    if down == nil then
        down = normal
    end

    local normal_sp = cc.Sprite:create(normal)
    local down_sp = cc.Sprite:create(down)

    local function onClick(tag, sender)
        local tagSender = sender:getTag()
        cclog("you need" .. tagSender)
        if BTN_PLAY == tagSender then
            stManager:changeState(ST_PLAY)
        elseif BTN_BRAG == tagSender then
            if gLoginStatus then
                print(gScore)
                if gScore  >= 0 then
                    FB.ui({ method = "feed", caption = "I just smashed " .. gScore .. " friends! Can you beat it?", picture = "http://www.friendsmash.com/images/logo_large.jpg", name = "Checkout my Friend Smash greatness!"},function(response)
                            print("come in fbCallback")
                        end)
                else
                    cclog("not login")
                end
            end
        elseif BTN_CHALLENGE == tagSender then
            if gLoginStatus then
                FB.ui({ method = "apprequests", message = "My Great Request"},function(response)
                        print("come in requestCallback")
                    end)
            else
                cclog("not login")
            end
        elseif BTN_STORE == tagSender then
            cclog("CLICK STORE!------")
        end
    end

    local btn = cc.MenuItemSprite:create(normal_sp, down_sp)
    btn:registerScriptTapHandler(onClick)
    btn:setTag(tag)

    return btn
end

function MenuLayer:onEnter()
    self:init()
end

function MenuLayer:onExit()

end

function MenuLayer.create()
    local layer = MenuLayer.extend(cc.Layer:create())

    local function onNodeEvent(event)
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
        end
    end
    
    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end


LifeLayer = class("LifeLayer")
LifeLayer.__index = LifeLayer

function LifeLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, LifeLayer)
    return target
end

function LifeLayer:init(num)
    if num == nil then
        num = 0
    end

    self.life = num
    self.imgs = {}
    self.max = num
    self:initImg()
    self:setLife(num)
end

function LifeLayer:setLife(num)
    self.life = num
    if num <= 0 then
        self:getParent():endGame()
    end

    self:refreshImg()
end

function LifeLayer:getLife()
    return self.life
end

function LifeLayer:loseLife(num)
    local curLife = self.life
    curLife = curLife - 1
    self:setLife(curLife)
end

function LifeLayer:initImg()
    self:removeAllChildren()
    self.imgs = {}
    for i = 1, self.max do
        local sp = cc.Sprite:create(res.s_heart64)
        local size = sp:getContentSize()
        sp:setPosition(cc.p(size.width/2 + (size.width + 1)*i, size.height/2))
        self:addChild(sp)
        self.imgs[i] = sp
    end
end

function LifeLayer:refreshImg()
    local begin = 0
    if begin < self.life then
        begin = self.life
    end
    
    for i =  begin + 1 ,self.max do
        if self.imgs[i] ~= nil then
            self.imgs[i]:setVisible(false)
        end
    end
end

function LifeLayer:onEnter()
    --self:init()
end

function LifeLayer:onExit()
    
end

function LifeLayer.create()
    local layer = LifeLayer.extend(cc.Layer:create())

    local function onNodeEvent(event)
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
        end
    end
    
    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end


gAllFriends = {}
gHeadImg = nil

HeadLayer = class("HeadLayer")
HeadLayer.__index = HeadLayer

function HeadLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, HeadLayer)
    return target
end

function HeadLayer:init()
    self.bInGetUserInfo = false
    self.headImg = nil
    self.headimgName = nil

    self.lbName = cc.Label:createWithBMFont(res.s_Arial_fnt, "Welcome, player.")
    self.lbName:setAnchorPoint(cc.p(0, 0))
    self:addChild(self.lbName)
    self.lbName:setPosition(cc.p(0, 50))
    self.login = self:getBtn(res.s_login0, res.s_login1, 1)
    self.logout = self:getBtn(res.s_logout0, res.s_logout1, 2)
    self.menu = cc.Menu:create(self.login, self.logout)
    self:addChild(self.menu)
    self.login:setPosition(cc.p(165, 26))
    self.logout:setPosition(cc.p(165, 26))
    self.menu:setPosition(cc.p(0,0))
    self.logout:setVisible(false)
    gHeadImg = cc.Sprite:create()
    self:addChild(gHeadImg)

    self.count = 1
    --UNDO
    local function update(dt)
        --gLoginStatus UNDO
        if self.count % 21 == 0 and (not gLoginStatus) then
            self:checkLoginStatus()
            self.count = 0
        end
        self.count = self.count + 1
    end
    self:scheduleUpdateWithPriorityLua(update, 0)
end

function HeadLayer:checkLoginStatus()
    if nil ~= FB and (not self.bInGetUserInfo) then
    else
        if nil == FB then
            cclog("can't connet to facebook,please check the internet.")
        else
            cclog("you are not login in.")
        end
    end
end

function HeadLayer:afterLogin()
    gFriendData = {}
    

    --
    FB.api("/me",function(response)
                    print("come in meInformationCallback")
                    local responseTable = json.decode(response, 1)
                    if( nil ~= responseTable and nil ~= responseTable.error) then
                        cclog(responseTable.error)
                        return
                    end
                    print("meInformationCallback",responseTable, responseTable.name)
                    
                    local strName = "Welcome, " .. responseTable.name

                    self.lbName:setString(strName)
                    local id = responseTable.id

                    function loadImg(imageKey)
                        if(nil ~= imageKey) then
                            self:setHeadImg(imageKey)
                        end
                    end

                    LoadUrlImage.addImageAsync("http://graph.facebook.com/"..id.."/picture?width=90&height=90", loadImg)
                    
        end)
  
    FB.api("/me/friends",function(response)
            print("come in getFriendsCallback")
            local responseTable = json.decode(response, 1)
            print("getFriendsCallback", responseTable, responseTable.data)
            if nil ~= responseTable and nil ~= responseTable.data then
                gAllFriends = responseTable.data
            end
        end)
    gLoginStatus = true
    self:setBtnState(false)

    g_useFacebook = true
end

function HeadLayer:setBtnState(st)
    self.login:setVisible(st)
    self.logout:setVisible(not st)

    if (self.headImg ~= nil) then
        self.headImg:setVisible(not st)
    end

    if(self.headImg ~= nil) then
        self.headImg:removeFromParent(true)
        self.headImg = nil
    end
end

function HeadLayer:setName(name)
    self.lbName:setString("Welcome, ".. name)
end

function HeadLayer:setHeadImg(src)
    self.headImg = cc.Sprite:createWithTexture(src)
    self:addChild(self.headImg)
    self.headimgName = src
    self.headImg:setPosition(50, 0)
    self.headImg:setVisible(true)
end

function HeadLayer:setHeadImgSp(sp)
    self:addChild(sp)
    sp:setPosition(cc.p(50, 0))
end

function HeadLayer:getBtn(normal, down, tag)
        if (down == nil) then
            down = normal
        end
        local normal_sp = cc.Sprite:create(normal)
        local down_sp = cc.Sprite:create(down)

        local function onClick(tag, sender)
            local tag = sender:getTag()
            if FB == nil then
                cclog("can't connet to facebook,please check the internet.")
                return
            end

            if 1 == tag then
                cclog("-------log in-----")
                if FB ~= nil then
                    FB.login(function(response)
                        if alreadyLogin then
                            return
                        end

                        alreadyLogin = true
                        print("come in login")
                        local responseTable = json.decode(response, 1)
                        if nil ~= responseTable and nil ~= responseTable.authResponse and responseTable.status=='connected'then
                            self:afterLogin()
                        end
                    end)
                else
                    print("can't connet to facebook,please check the internet.")
                end
            elseif 2 == tag then
                cclog("-------log out-----")
                if FB ~= nil then
                    alreadyLogin  = false
                    FB.logout(function(response)
                        print("come in logout")
                        local responseTable = json.decode(response, 1)
                        print("responseTable",responseTable, responseTable.status )
                        if(responseTable.status=='unknown') then
                            print("come in unknown")
                            self:setName("player")
                            gLoginStatus = false
                            gFriendData = {}
                            self:setBtnState(true)
                        end
                    end)
                end
            end
        end

        local btn = cc.MenuItemSprite:create(normal_sp, down_sp)
        btn:registerScriptTapHandler(onClick)
        btn:setTag(tag)

        return btn
end

function HeadLayer:onEnter()
    self:init()
end

function HeadLayer:onExit()
    self:unscheduleUpdate()
end

function HeadLayer.create()
    local layer = HeadLayer.extend(cc.Layer:create())

    local function onNodeEvent(event)
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
        end
    end
    
    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end

TY_COIN = 1
count_int = 0

ResultLayer = class("ResultLayer")
ResultLayer.__index = ResultLayer

function ResultLayer.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, ResultLayer)
    return target
end

function ResultLayer:init()
    self.bInit = false

    if self.bInit then
        return
    end

    self.bkImg = cc.Sprite:create(res.s_modal_box_copy2)
    self.bkImg:setAnchorPoint(cc.p(0, 0))
    self:addChild(self.bkImg)

    local size = self.bkImg:getContentSize()
    local t_x = 70
    local t_y = size.height - 60--self.bkImg.getContentSize().height - 20
    local t_h = 77
    local img_w = 35
    local img_h = -20
    local f_sc = 1.0
    self.lbTitle = cc.Label:createWithBMFont(res.s_Arial_fnt, "Results")
    self.lbTitle:setPosition(cc.p(t_x, t_y))
    self.lbTitle:setAnchorPoint(cc.p(0, 0))
    self:addChild(self.lbTitle)

    self.lbScore = cc.Label:createWithBMFont(res.s_Arial_fnt, self:getString(0,0))
    self:addChild(self.lbScore)
    self.lbScore:setAnchorPoint(cc.p(0, 0))
    self.lbScore:setPosition(cc.p(t_x, t_y - t_h))
    self.imgScore = cc.Sprite:create(res.s_scores64)
    self:addChild(self.imgScore)
    self.imgScore:setPosition(cc.p(t_x - img_w, t_y - t_h - img_h))

    self.lbCoin = cc.Label:createWithBMFont(res.s_Arial_fnt, self:getString(0, TY_COIN))
    self:addChild(self.lbCoin)
    self.lbCoin:setAnchorPoint(cc.p(0, 0))
    self.lbCoin:setPosition(cc.p(t_x, t_y - t_h*2))
    self.imgCoin = cc.Sprite:create(res.s_coin_bundle64)
    self:addChild(self.imgCoin)
    self.imgCoin:setPosition(cc.p(t_x-img_w, t_y-t_h*2-img_h))

    local function onClick(tag, sender)
        _menuLayer:disResult(false)
    end

    self.closeItem = cc.MenuItemImage:create(res.s_close_button,res.s_close_button)
    self.closeItem:setPosition(cc.p(size.width - 30, size.height-30))
    self.closeItem:registerScriptTapHandler(onClick)
    self.menu = cc.Menu:create(self.closeItem)
    self:addChild(self.menu)
    self.menu:setPosition(cc.p(0, 0))
end

function ResultLayer:setScore(num)
    self.lbScore:setString(self:getString(num, 0))
end

function ResultLayer:setCoin(num)
    self.lbCoin:setString(self.getString(num, TY_COIN))
end
 
function ResultLayer:setNum(score, coin)
    self:setScore(score)
    self:setCoin(coin)
end

function ResultLayer:getString(num, strType)
    local str = ""
    if strType == TY_COIN then
        str = "and grabbed " .. num .. " coins!"
    else
        str = "You smashed " .. num .. " friends"
    end

    return str
end

function ResultLayer:onEnter()
    --self:init()
end

function ResultLayer:onExit()
    
end

function ResultLayer.create()
    local layer = ResultLayer.extend(cc.Layer:create())
    layer:init()
    local function onNodeEvent(event)
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
        end
    end
    
    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end





