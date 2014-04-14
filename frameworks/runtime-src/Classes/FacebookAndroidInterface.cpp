#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)

#include "FacebookInterface.h"
#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>
#include "CCLuaEngine.h"

using namespace cocos2d;

const char* FBJavaClassName = "org/cocos2dx/lua/FacebookConnectPlugin";


extern "C"{

	void Java_org_cocos2dx_lua_FacebookConnectPlugin_nativeCallback(JNIEnv*  env, jobject thiz, jint cbIndex,jstring params)
	{
		std::string strParams = JniHelper::jstring2string(params);
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

		if (nullptr != strParams.c_str())
		{
		    stack->pushInt(cbIndex);
		    stack->pushString(strParams.c_str());
		    stack->executeFunction(2);
		}
		else
		{
		    stack->pushInt(cbIndex);
		    stack->executeFunction(1);
		}

		lua_settop(state, topIndex);
	}
};

void FacebookInterface::callback(int cbIndex, const char* params){
	
}

void FacebookInterface::login(int cbIndex,const char* scope){

	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t
		, FBJavaClassName
		, "login"
		, "(ILjava/lang/String;)V"))
	{
		if (scope)
		{
			jstring jeventId = t.env->NewStringUTF(scope);
			t.env->CallStaticVoidMethod(t.classID, t.methodID, cbIndex, jeventId);
			t.env->DeleteLocalRef(jeventId);
		} 
		else
		{
			t.env->CallStaticVoidMethod(t.classID, t.methodID, cbIndex, NULL);
		}	
		t.env->DeleteLocalRef(t.classID);
	}  	
}

void FacebookInterface::logout(int cbIndex){
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t
		, FBJavaClassName
		, "logout"
		, "(I)V"))
	{
		t.env->CallStaticVoidMethod(t.classID, t.methodID, cbIndex);
		t.env->DeleteLocalRef(t.classID);
	}  	
}

void FacebookInterface::getLoginStatus(int cbIndex,bool force){
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t
		, FBJavaClassName
		, "getLoginStatus"
		, "(IZ)V"))
	{
		t.env->CallStaticVoidMethod(t.classID, t.methodID, cbIndex,force);
		t.env->DeleteLocalRef(t.classID);
	}  	
}

std::string FacebookInterface::api(const char* graphPath,const char* method,const char* params,int cbIndex){
	JniMethodInfo t;
	std::string errorRet;

	if (JniHelper::getStaticMethodInfo(t
		, FBJavaClassName
		, "api"
		, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)Ljava/lang/String;"))
	{
		jstring jgraphPath = t.env->NewStringUTF(graphPath);
		jstring jmethod = NULL;
		if(method)
			jmethod = t.env->NewStringUTF(method);
		jstring jparams = NULL;
		if(params)
			jparams = t.env->NewStringUTF(params);
		
		jstring ret = (jstring)(t.env->CallStaticObjectMethod(t.classID, t.methodID, jgraphPath,jmethod,jparams,cbIndex));
		t.env->DeleteLocalRef(jgraphPath);
		if(method)
			t.env->DeleteLocalRef(jmethod);
		if(params)
			t.env->DeleteLocalRef(jparams);
		t.env->DeleteLocalRef(t.classID);

		if (ret != NULL)
			errorRet = JniHelper::jstring2string(ret);				
	} 

	return errorRet;
}

void FacebookInterface::ui(const char* params,int cbIndex){
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t
		, FBJavaClassName
		, "ui"
		, "(Ljava/lang/String;I)V"))
	{
		jstring jparams = t.env->NewStringUTF(params);
		t.env->CallStaticVoidMethod(t.classID, t.methodID, jparams,cbIndex);
		t.env->DeleteLocalRef(jparams);
		t.env->DeleteLocalRef(t.classID);
	}  
}

#endif