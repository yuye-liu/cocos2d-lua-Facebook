SIZE_MOD  = 7
winSize = cc.size(480,800)

app_id = "290786477730812"
app_secret = "2cdc7b30f1135b0380b32baaef3adfd8"
app_namespace = "facesample"

app_url = "http://apps.facebook.com/' . $app_namespace . '/"
scope   = "email,publish_actions"

--global login status
gLoginStatus = false
--global varibale, manage game state.
stManager = nil
--global varibale, is use facebook.      
g_useFacebook = false

g_menuLayer = nil

count = 0
gGameBombs
gBombsUsed
gTickGameInterval
gTickSpeed
gFriendID
gScore = 0
gCoins = 0
gContext
gCanvasElement
gSpawnTimer
gScoreUIText
gSmashUIText
gDoingGameover
gGameOverEntity
gLives
gInitialLives
gExplosionParticles = []
gBombImages = []
gEntities = []
gLifeImages = []
gExplosionTimerLength = 100
gExplosionTimer

TO_RADIANS = Math.PI/180

IMG_HEADER = "nonfriend_"
_PNG = ".png"

lifeLayer;
lifeCount = 3
