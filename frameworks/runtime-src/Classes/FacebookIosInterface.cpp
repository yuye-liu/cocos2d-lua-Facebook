//
//  FacebookIosInterface.cpp
//  tojs
//
//  Created by lyy on 13-8-20.
//
//

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

#include "FacebookInterface.h"
#include "CCUIKit.h"
#include "CCLuaEngine.h"
using namespace std;

void FacebookInterface::login(int cbIndex,const char* scope)
{
	CCUIKit::shareCCUIKit()->logInFacebook(cbIndex,scope);
}

void FacebookInterface::logout(int cbIndex)
{
    CCUIKit::shareCCUIKit()->logOutFacebook(cbIndex);
}

void FacebookInterface::getLoginStatus(int cbIndex,bool force)
{
    CCUIKit::shareCCUIKit()->getActiveSessionState(cbIndex,force);
}
std::string FacebookInterface::api(const char* graphPath,const char* method,const char* params,int cbIndex)
{
    if (method == NULL)
    {
        method = "null";
    }
    if(params == NULL)
    {
        params = "null";
    }
  
	return CCUIKit::shareCCUIKit()->requestWithGraphPath(graphPath, method, params,cbIndex);
}

void FacebookInterface::ui(const char* params,int cbIndex)
{
    CCUIKit::shareCCUIKit()->ui(params, cbIndex);
}

void FacebookInterface::callback(int cbIndex, const char* params)
{
    auto engine = LuaEngine::getInstance();
    auto stack = engine->getLuaStack();
    auto state = stack->getLuaState();
    int topIndex = lua_gettop(state);
    lua_getglobal(state, "_G");                          /* L: G */
    lua_getfield(state, -1, "FB");                       /* L: G FB */
    lua_pushstring(state, "callback");                   /* L: G FB funcName */
    lua_gettable(state, -2);                             /* L: G FB func */
    if (!lua_isfunction(state, -1))
    {
        CCLOG("[LUA ERROR] name '%s' does not represent a Lua function", "callback");
        lua_settop(state, topIndex);
        return;
    }
    
    if (nullptr != params)
    {
        stack->pushInt(cbIndex);
        stack->pushString(params);
        stack->executeFunction(2);
    }
    else
    {
        stack->pushInt(cbIndex);
        stack->executeFunction(1);
    }
    
    lua_settop(state, topIndex);
}

#endif
