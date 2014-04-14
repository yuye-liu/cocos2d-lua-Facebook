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
#include "lua_bindings_loadUrlImage.hpp"
#include "cocos2d.h"
#include "LoadUrlImage.h"

static int lua_LoadUrlImage_loadUrlImage(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
    
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (!tolua_isstring(L, 1, 0, &tolua_err) ||
        !tolua_isnumber(L, 2, 0, &tolua_err))
        goto tolua_lerror;
    else
#endif
    {
        std::string url = tolua_tostring(L, 1, "");
        int idx = (int)tolua_tonumber(L, 2, 0);
        LoadUrlImage::loadUrlImage(url.c_str(), idx);
        return 0;
    }
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(L,"#ferror in function 'loadUrlImage'.",&tolua_err);
    return 0;
#endif
}

int register_loadUrlImage(lua_State* L)
{
    if (nullptr == L)
        return 0;
    
    tolua_open(L);
    lua_getglobal(L, "_G");
    tolua_module(L,"LoadUrlImage",0);
    tolua_beginmodule(L,"LoadUrlImage");
        tolua_function(L, "loadUrlImage", lua_LoadUrlImage_loadUrlImage);
    tolua_endmodule(L);
    lua_pop(L, 1);
    
    return 0;
}
