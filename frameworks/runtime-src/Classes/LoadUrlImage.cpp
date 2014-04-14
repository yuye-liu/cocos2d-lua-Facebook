#include "LoadUrlImage.h"
#include "CCLuaEngine.h"
#include "LuaBasicConversions.h"

USING_NS_CC;
USING_NS_CC_EXT;
using namespace network;


//extern jsval anonEvaluate(JSContext *cx, JSObject *thisObj, const char* string);
//
LoadUrlImage* gLoadUrlImage = nullptr;
//JSObject *jsLoadUrlImageObject = NULL;

LoadUrlImage::LoadUrlImage(){

}

LoadUrlImage* LoadUrlImage::getInstance(){
	if (gLoadUrlImage == nullptr)
		gLoadUrlImage = new LoadUrlImage();
	return gLoadUrlImage;
}

void LoadUrlImage::callback(int cbIndex, cocos2d::Texture2D* texture)
{
    auto engine = LuaEngine::getInstance();
    auto stack = engine->getLuaStack();
    auto state = stack->getLuaState();
    int topIndex = lua_gettop(state);
    lua_getglobal(state, "_G");                          /* L: G */
    lua_getfield(state, -1, "LoadUrlImage");                       /* L: G FB */
    lua_pushstring(state, "callback");                   /* L: G FB funcName */
    lua_gettable(state, -2);                             /* L: G FB func */
    if (!lua_isfunction(state, -1))
    {
        CCLOG("[LUA ERROR] name '%s' does not represent a Lua function", "callback");
        lua_settop(state, topIndex);
        return;
    }
    
    if (nullptr != texture)
    {
        stack->pushInt(cbIndex);
        object_to_luaval<cocos2d::Texture2D>(stack->getLuaState(), "cc.Texture2D",(cocos2d::Texture2D*)texture);
        stack->executeFunction(2);
    }
    else
    {
        stack->pushInt(cbIndex);
        stack->executeFunction(1);
    }
    
    lua_settop(state, topIndex);
	
}

void LoadUrlImage::loadUrlImage(const char* url,int cbIndex){
	getInstance();
	std::string strUrl = url;

	HttpRequest* request = new HttpRequest();
	request->setUrl(url);
	request->setRequestType(HttpRequest::Type::GET);
	request->setResponseCallback(gLoadUrlImage, httpresponse_selector(LoadUrlImage::onLoadCompleted));
	request->setUserData((void*)cbIndex);
	
	request->setTag(strUrl.substr(strUrl.find_last_of('/')).c_str());
	HttpClient::getInstance()->send(request);
	request->release();
	log("loadUrlImage");
}

Image::Format getImageFormat(std::string lowerCase)
{
	Image::Format eImageFormat = Image::Format::UNKOWN;

	if(lowerCase.size() == 0)
		return eImageFormat;

	for (unsigned int i = 0; i < lowerCase.length(); ++i)
		lowerCase[i] = tolower(lowerCase[i]);

	if (std::string::npos != lowerCase.find(".png"))
		eImageFormat = CCImage::Format::PNG;
	else if (std::string::npos != lowerCase.find(".jpg") || std::string::npos != lowerCase.find(".jpeg"))
		eImageFormat = CCImage::Format::JPG;
	else if (std::string::npos != lowerCase.find(".tif") || std::string::npos != lowerCase.find(".tiff"))
		eImageFormat = CCImage::Format::TIFF;
	else if (std::string::npos != lowerCase.find(".webp"))
		eImageFormat = CCImage::Format::WEBP;
	
	return eImageFormat;
}

void LoadUrlImage::onLoadCompleted(HttpClient *sender, HttpResponse *response)
{
	if (!response)
		return;

	int statusCode = response->getResponseCode();	
	log("response code: %d", statusCode);

	if (!response->isSucceed()) 
	{
		log("response failed");
		log("error buffer: %s", response->getErrorBuffer());
		return;
	}
	std::string pathKey = "url_";
	pathKey += response->getHttpRequest()->getTag();	
	
	std::vector<char> *buffer = response->getResponseData();		
	std::string bufffff(buffer->begin(),buffer->end());

	Image* pImage = new Image();
	bool bRet = pImage->initWithImageData((const unsigned char *)bufffff.c_str(),buffer->size());
	if(!bRet){
		log("LoadUrlImage::onLoadCompleted -->initWithImageData fail");
		return;
	}
		
	const char* imageKsy = pathKey.c_str();
	Texture2D * texture2d = TextureCache::getInstance()->addImage(pImage,imageKsy);
	int cbIndex = (int)(response->getHttpRequest()->getUserData());
	if (texture2d)
	{
		log("load urlImage succeed");		
		callback(cbIndex,texture2d);
	}
	else
	{
		log("load urlImage fail");
		callback(cbIndex,nullptr);
	}	
	CC_SAFE_RELEASE(pImage);
}