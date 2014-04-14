package org.cocos2dx.lua;

import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.widget.Toast;

import com.facebook.FacebookException;
import com.facebook.FacebookOperationCanceledException;
import com.facebook.FacebookRequestError;
import com.facebook.HttpMethod;
import com.facebook.Request;
import com.facebook.Response;
import com.facebook.Session;
import com.facebook.Session.OpenRequest;
import com.facebook.SessionState;
import com.facebook.UiLifecycleHelper;
import com.facebook.model.GraphObject;
import com.facebook.widget.WebDialog;
import com.facebook.widget.WebDialog.OnCompleteListener;

public class FacebookConnectPlugin {
	private static Activity mActivity = null;
	private static Context mContext = null;
	private static FacebookConnectPlugin mFacebookPlugin = null;
	private UiLifecycleHelper uiHelper;
	private static OpenRequest mOpenRequest = null;
	private static boolean mNeedPublishPermissions = false;
	private static RequestCallback mRequestCallback = null;
	private static SessionStatusCallback mStatusCallback = null;
	private static final List<String> allPublishPermissions = Arrays.asList(
			"publish_actions", "ads_management", "create_event", "rsvp_event",
			"manage_friendlists", "manage_notifications", "manage_pages");
	private static MyHandler myHandler = null;
	private static final String TAG = "FacebookPlugin";

	public FacebookConnectPlugin(Activity activity) {
		mActivity = activity;
		mFacebookPlugin = this;
		mContext = mActivity.getApplicationContext();
		mStatusCallback = new SessionStatusCallback();
		myHandler = new MyHandler();
		uiHelper = new UiLifecycleHelper(activity, mStatusCallback);
	}

	public void onCreate(Bundle savedInstanceState) {
		uiHelper.onCreate(savedInstanceState);
	}

	public static void login(int cbIndex, String scope) {
		Log.i(TAG, "dsafsdfas");
		Session session = Session.getActiveSession();
		if (session == null) {
			session = new Session(mContext);
			Session.setActiveSession(session);
		}

		String[] permissions = null;
		mNeedPublishPermissions = false;
		if (scope != null) {
			permissions = scope.split(",");
			for (int i = 0; i < permissions.length; i++) {
				if (allPublishPermissions.contains(permissions[i])) {
					mNeedPublishPermissions = true;
					break;
				}
			}
		}

		if (session.isOpened()) {
			Log.i(TAG, "openActiveSession2");
			if (scope == null
					|| session.getPermissions().containsAll(
							Arrays.asList(permissions))) {
				Log.e(TAG, "FB.login() called when user is already connected.");
			} else {
				mStatusCallback.mCallByMode = SessionStatusCallback.CallByLogin;
				mStatusCallback.mCallbackIndex = cbIndex;
				if (mNeedPublishPermissions) {
					session.requestNewPublishPermissions(new Session.NewPermissionsRequest(
							mActivity, Arrays.asList(permissions)));
				} else {
					session.requestNewReadPermissions(new Session.NewPermissionsRequest(
							mActivity, Arrays.asList(permissions)));
				}
			}
		} else {
			mStatusCallback.mCallByMode = SessionStatusCallback.CallByLogin;
			mStatusCallback.mCallbackIndex = cbIndex;
			Log.i(TAG, "openActiveSession1");
			if (!session.isClosed()) {
				mOpenRequest = new Session.OpenRequest(mActivity);
				if (permissions != null)
					mOpenRequest.setPermissions(Arrays.asList(permissions));
				mOpenRequest.setCallback(mStatusCallback);

				if (mNeedPublishPermissions) {
					Log.i(TAG, "openActiveSession4");
					session.openForPublish(mOpenRequest);
				} else {
					Log.i(TAG, "openActiveSession5");
					session.openForRead(mOpenRequest);
				}

			} else {
				Log.i(TAG, "openActiveSession");
				Session.openActiveSession(mActivity, true, mStatusCallback);
			}
		}

		/*
		 * Session session = Session.getActiveSession(); if (!session.isOpened()
		 * && !session.isClosed()) { session.openForRead(new
		 * Session.OpenRequest(mActivity)
		 * .setPermissions(Arrays.asList("basic_info")).setCallback(
		 * mStatusCallback)); } else { Session.openActiveSession(mActivity,
		 * true, mStatusCallback); }
		 */
	}

	public static void logout(int cbIndex) {
		mStatusCallback.mCallByMode = SessionStatusCallback.CallByLogout;
		mStatusCallback.mCallbackIndex = cbIndex;
		Session session = Session.getActiveSession();
		if (!session.isClosed())
			session.closeAndClearTokenInformation();
		else
			Log.e(TAG, "FB.logout() called without an access token.");
	}

	public static String api(String graphPath, String method, String params,
			int cbIndex) {
		Log.v(TAG, "api-graphPath:" + graphPath);

		Session session = Session.getActiveSession();
		if (session != null && session.isOpened()) {
			HttpMethod httpMethod = HttpMethod.GET;
			if (method != null) {
				if (method.compareTo("post") == 0)
					httpMethod = HttpMethod.POST;
				else if (method.compareTo("delete") == 0)
					httpMethod = HttpMethod.DELETE;
			}

			Bundle parameters = new Bundle();
			try {
				if (params != null) {
					JSONObject jsonObject = new JSONObject(params);
					Iterator<String> iterator = jsonObject.keys();
					String key = null;
					String value = null;
					while (iterator.hasNext()) {
						key = iterator.next();
						Object object = jsonObject.get(key);
						if (object instanceof String) {
							value = (String) object;
							if (key.compareTo("method") != 0)
								parameters.putString(key, value);
						} else if (object instanceof Integer) {
							parameters.putInt(key,
									((Integer) object).intValue());
						} else if (object instanceof Boolean) {
							parameters.putBoolean(key,
									((Boolean) object).booleanValue());
						} else if (object instanceof Double) {
							parameters.putDouble(key,
									((Double) object).doubleValue());
						} else {
							Log.w(TAG, "other type:" + object.toString());
						}
					}
				}
			} catch (JSONException e) {
				e.printStackTrace();
			}

			Request request = new Request(session, graphPath, parameters,
					httpMethod, new FacebookConnectPlugin.RequestCallback(
							cbIndex));
			Message message = myHandler.obtainMessage(
					MyHandler.EXECUTE_REQUEST, request);

			message.sendToTarget();
		} else {
			return "{\"message\":\"An active access token must be used to query information about the current user.\""
					+ ",\"type\":\"OAuthException\",\"code\": 2500}";
		}
		return null;
	}

	void _ui(String params, int cbIndex) {
		String action = null;
		Bundle parameters = new Bundle();
		try {
			JSONObject jsonObject = new JSONObject(params);
			action = jsonObject.getString("method");
			Iterator iterator = jsonObject.keys();
			String key = null;
			String value = null;
			while (iterator.hasNext()) {
				key = (String) iterator.next();
				Object object = jsonObject.get(key);
				if (object instanceof String) {
					value = (String) object;
					if (key.compareTo("method") != 0)
						parameters.putString(key, value);
				} else if (object instanceof Integer) {
					parameters.putInt(key, ((Integer) object).intValue());
				} else if (object instanceof Boolean) {
					parameters.putBoolean(key,
							((Boolean) object).booleanValue());
				} else if (object instanceof Double) {
					parameters.putDouble(key, ((Double) object).doubleValue());
				} else {
					Log.v(TAG, "other type:" + object.toString());
				}
			}
		} catch (JSONException e) {
			e.printStackTrace();
		}
		WebDialog uiDialog = (new WebDialog.Builder(mActivity,
				Session.getActiveSession(), action, parameters))
				.setOnCompleteListener(new WebDialogListener(cbIndex)).build();
		uiDialog.show();
	}

	public static void ui(String params, int cbIndex) {
		Session session = Session.getActiveSession();
		if (session == null) {
			session = new Session(mContext);
			Session.setActiveSession(session);
		}

		if (session.isOpened()) {
			Message message = myHandler.obtainMessage(
					MyHandler.EXECUTE_WEBDIALOG, params);
			message.arg1 = cbIndex;
			message.sendToTarget();
		} else {
			mStatusCallback.mCallByMode = SessionStatusCallback.CallByFBUI;
			mStatusCallback.mCallbackIndex = cbIndex;
			mStatusCallback.params = params;

			if (!session.isClosed()) {
				session.openForRead(new Session.OpenRequest(mActivity)
						.setCallback(mStatusCallback));
			} else {
				Session.openActiveSession(mActivity, true, mStatusCallback);
			}
		}
	}

	public static void getLoginStatus(int cbIndex, boolean force) {
		Log.v(TAG, "getLoginStatus" + cbIndex);
		Session session = Session.getActiveSession();
		if (session == null) {
			nativeCallback(cbIndex,
					"{\"authResponse\":null,\"status\":\"unknown\"}");
		} else {
			if (session.isOpened()) {
				nativeCallback(cbIndex, "{\"authResponse\":{\"accessToken\":\""
						+ session.getAccessToken()
						+ "\"},\"status\":\"connected\"}");
			} else if (session.getState() == SessionState.CLOSED_LOGIN_FAILED) {
				nativeCallback(cbIndex, "{\"authResponse\":{\"accessToken\":\""
						+ session.getAccessToken()
						+ "\"},\"status\":\"not_authorized\"}");
			} else {
				nativeCallback(cbIndex, "{\"authResponse\":{\"accessToken\":\""
						+ session.getAccessToken()
						+ "\"},\"status\":\"unknown\"}");
			}
		}
	}
	
	public void onResume() {
		// For scenarios where the main activity is launched and user
		// session is not null, the session state change notification
		// may not be triggered. Trigger it if it's open/closed.
		Session session = Session.getActiveSession();
		if (session != null && (session.isOpened() || session.isClosed())) {
			if (session.getState().isOpened()) {
				Log.i(TAG, "Logged in...");
			} else if (session.getState().isClosed()) {
				Log.i(TAG, "Logged out...");
			}
		}
		uiHelper.onResume();
	}

	public void onPause() {
		uiHelper.onPause();
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		uiHelper.onActivityResult(requestCode, resultCode, data);
	}

	public void onSaveInstanceState(Bundle outState) {
		uiHelper.onSaveInstanceState(outState);
	}

	public void onDestory() {
		uiHelper.onDestroy();
	}

	private static native void nativeCallback(int cbIndex, String params);

	// ***************class**********************

	static class MyHandler extends Handler {
		static final int EXECUTE_REQUEST = 1;
		static final int EXECUTE_WEBDIALOG = 2;

		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
			case EXECUTE_REQUEST: {
				Request request = (Request) msg.obj;
				request.executeAsync();
				break;
			}
			case EXECUTE_WEBDIALOG: {
				mFacebookPlugin._ui((String) (msg.obj), msg.arg1);
				break;
			}
			default:
				break;
			}
		}
	}

	static class RequestCallback implements Request.Callback {

		private int mCallbackIndex = -1;

		public RequestCallback(int cbIndex) {
			mCallbackIndex = cbIndex;
		}

		@Override
		public void onCompleted(Response response) {
			FacebookRequestError error = response.getError();
			if (error != null) {
				JSONObject jsonObject = new JSONObject();
				try {
					jsonObject.put("type", error.getErrorType());
					jsonObject.put("message", error.getErrorMessage());
					nativeCallback(mCallbackIndex,
							"{\"error\":" + jsonObject.toString() + "}");
				} catch (JSONException e) {
					e.printStackTrace();
				}
			} else {
				GraphObject object = response.getGraphObject();
				Object tObject = object
						.getProperty(Response.NON_JSON_RESPONSE_PROPERTY);
				if (tObject == null && object != null) {
					JSONObject jsonObject = object.getInnerJSONObject();
					if (jsonObject != null)
						nativeCallback(mCallbackIndex, jsonObject.toString());
				} else {
					nativeCallback(mCallbackIndex, tObject.toString());
				}
			}
		}

	}

	static class SessionStatusCallback implements Session.StatusCallback {
		int mCallbackIndex = -1;

		String params = null;

		int mCallByMode = CallByNull;
		static final int CallByNull = 0;
		static final int CallByLogin = 1;
		static final int CallByLogout = 2;
		static final int CallByFBUI = 3;

		@Override
		public void call(Session session, SessionState state,
				Exception exception) {
			Log.v("SessionStatusCallback", "call cbIndex:" + mCallbackIndex);
			Log.v("SessionStatusCallback", "state:" + state.toString());
			if (exception != null)
				Log.v("SessionStatusCallback",
						"exception:" + exception.toString());
			switch (mCallByMode) {
			case CallByLogin:
				if (session.isOpened()) {
					mCallByMode = CallByNull;
					// Date curDate = new Date();
					// Log.v(Tag,"getExpirationDate:"+(session.getExpirationDate().getTime()-curDate.getTime()));

					if (mCallbackIndex != -1)
						nativeCallback(mCallbackIndex,
								"{\"authResponse\":{\"accessToken\":\""
										+ session.getAccessToken()
										+ "\"},\"status\":\"connected\"}");
				} else if (state == SessionState.CLOSED_LOGIN_FAILED) {
					mCallByMode = CallByNull;
					if (mCallbackIndex != -1)
						nativeCallback(mCallbackIndex,
								"{\"authResponse\":null,\"status\":\"not_authorized\"}");
				}
				break;
			case CallByLogout:
				if (session.isClosed()) {
					mCallByMode = CallByNull;
					if (mCallbackIndex != -1)
						nativeCallback(mCallbackIndex,
								"{\"authResponse\":{},\"status\":\"unknown\"}");
				}
				break;
			case CallByFBUI: {
				if (session.isOpened()) {
					mCallByMode = CallByNull;
					Message message = myHandler.obtainMessage(
							MyHandler.EXECUTE_WEBDIALOG, params);
					message.arg1 = mCallbackIndex;
					message.sendToTarget();
				} else if (state == SessionState.CLOSED_LOGIN_FAILED) {
					mCallByMode = CallByNull;
					if (mCallbackIndex != -1)
						nativeCallback(mCallbackIndex, "null");
				}
				break;
			}
			default:
				break;
			}
		}
	}

	static class WebDialogListener implements WebDialog.OnCompleteListener {

		private int mCallbackIndex;

		public WebDialogListener(int cbIndex) {
			mCallbackIndex = cbIndex;
		}

		@Override
		public void onComplete(Bundle values, FacebookException error) {
			if (error != null) {
				nativeCallback(mCallbackIndex, "null");
				error.printStackTrace();
			} else {
				if (values != null) {
					Set<String> keySet = values.keySet();
					JSONObject jsonObject = new JSONObject();

					for (String key : keySet) {
						Object valueObject = values.get(key);
						try {
							if (valueObject instanceof String)
								jsonObject.put(key, (String) valueObject);
							else if (valueObject instanceof Integer)
								jsonObject.put(key,
										((Integer) valueObject).intValue());
							else if (valueObject instanceof Double)
								jsonObject.put(key,
										((Double) valueObject).doubleValue());
							else if (valueObject instanceof Boolean)
								jsonObject.put(key,
										((Boolean) valueObject).booleanValue());
							else if (valueObject instanceof JSONObject)
								jsonObject.put(key, valueObject);
						} catch (JSONException e) {
							e.printStackTrace();
						}
					}
					nativeCallback(mCallbackIndex, jsonObject.toString());
				}
			}
		}
	}

}
