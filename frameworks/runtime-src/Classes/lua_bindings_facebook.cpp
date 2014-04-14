/****************************************************************************
 Copyright (c) 2013-2014 Chukong Technologies Inc.
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
#include "lua_bindings_facebook.hpp"
#include "cocos2d.h"
#include "tolua_fix.h"
#include "FacebookInterface.h"

int tolua_isnilValue(lua_State* L, int lo, tolua_Error* err)
{
    if (lua_gettop(L)<abs(lo))
        return 0; /* somebody else should chack this */
    if (lua_isnil(L, lo))
        return 0;
    
    err->index = lo;
    err->array = 0;
    err->type = "value";
    return 1;
}

static int lua_Facebook_login(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
    int argc = lua_gettop(L);
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif
    if (1 == argc)
    {
#if COCOS2D_DEBUG >= 1
        if (!tolua_isnumber(L, 1, 0, &tolua_err))
            goto tolua_lerror;
        else
#endif
        {
           int cbIndex = (int)tolua_tonumber(L, 1, 0);
           FacebookInterface::login(cbIndex, nullptr);
           return 0;
        }
    }
    else if(2 == argc)
    {
#if COCOS2D_DEBUG >= 1
        if (!tolua_isnumber(L, 1, 0, &tolua_err) ||
            !tolua_isstring(L, 2, 0, &tolua_err))
            goto tolua_lerror;
        else
#endif
        {
            int cbIndex = (int)tolua_tonumber(L, 1, 0);
            const char* str = tolua_tostring(L, 2, nullptr);
            FacebookInterface::login(cbIndex, str);
            return 0;
        }
    }

    CCLOG("'login' has wrong number of arguments: %d, was expecting %d\n", argc, 0);
    return 0;
    
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'login'.",&tolua_err);
    return 0;
#endif
}

static int lua_Facebook_logout(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isnumber(L, 1, 0, &tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
        int cbIndex = (int)tolua_tonumber(L, 1, 0);
        FacebookInterface::logout(cbIndex);
        return 0;
    }
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'logout'.",&tolua_err);
    return 0;
#endif
}

static int lua_Facebook_getLoginStatus(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isnumber(L, 1, 0, &tolua_err) ||
        !tolua_isboolean(L, 2, 0, &tolua_err))
        goto tolua_lerror;
    else
#endif
    {
        int cbIndex = (int)tolua_tonumber(L, 1, 0);
        bool force  = tolua_toboolean(L, 2, 0);
        FacebookInterface::getLoginStatus(cbIndex,force);
        return 0;
    }
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'getLoginStatus'.",&tolua_err);
    return 0;
#endif
}

static int lua_Facebook_api(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isstring(L, 1, 0, &tolua_err) ||
        (!lua_isnil(L, 2)   && !tolua_isstring(L, 2,0,&tolua_err)) ||
        (!lua_isnil(L, 3)   && !tolua_isstring(L, 3,0,&tolua_err)) ||
        !tolua_isnumber(L, 4, 0, &tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
        const char* graphPath = tolua_tostring(L, 1, nullptr);
        const char* method    = nullptr;
        if (!lua_isnil(L, 2))
        {
            method = tolua_tostring(L, 2, nullptr);
        }
        
        const char* params    = nullptr;
        if (!lua_isnil(L, 3))
        {
            params = tolua_tostring(L, 3, nullptr);
        }
        
        int cbIndex = (int)tolua_tonumber(L, 4, 0);
        
        std::string ret = FacebookInterface::api(graphPath, method, params, cbIndex);
        if (ret.length() > 0)
        {
            tolua_pushstring(L, ret.c_str());
            return 1;
        }
        
        return 0;
    }
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'api'.",&tolua_err);
    return 0;
#endif
}

static int lua_Facebook_ui(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isstring(L, 1, 0, &tolua_err) ||
        !tolua_isnumber(L, 2, 0, &tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
        const char* params = tolua_tostring(L, 1, nullptr);
        int cbIndex = (int)tolua_tonumber(L, 2, 0);
        
        FacebookInterface::ui(params, cbIndex);
        return 0;
    }
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'ui'.",&tolua_err);
    return 0;
#endif
}


int register_facebook(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
    tolua_open(L);
    lua_getglobal(L, "_G");
    tolua_module(L, "Facebook", 0);
    tolua_beginmodule(L,"Facebook");
        tolua_function(L, "login", lua_Facebook_login);
        tolua_function(L, "logout", lua_Facebook_logout);
        tolua_function(L, "getLoginStatus", lua_Facebook_getLoginStatus);
        tolua_function(L, "api", lua_Facebook_api);
        tolua_function(L, "ui", lua_Facebook_ui);
    tolua_endmodule(L);
    lua_pop(L, 1);
    return 0;
}
