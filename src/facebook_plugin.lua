
FB = FB or {}

FB.cbArray = {}
FB.vaildMethod = {}

function FB.indexOf(cb)
    local index = 0
    for i = 1, #FB.cbArray do
        if FB.cbArray[i] == cb then
            index = i
            break
        end
    end

    return index
end

function FB.pushCb(cb)
    FB.cbArray[#FB.cbArray + 1] = cb
    return #FB.cbArray
end



function FB.login(...)
    local arg = {...}
    local argNum = #arg
    
    if argNum > 0 then
        local type_cb = type(arg[1])
        if type_cb ~= 'function' then
           error(string.format("Expression is of type %s ,not function",type_cb))
        end
        local cbIndex = FB.indexOf(arg[1])
        if cbIndex == 0 then
           cbIndex = FB.pushCb(arg[1])
        end
        print("login cbIndex", cbIndex - 1)
        if argNum == 2 then
            if arg[2].scope ~= nil and type(arg[2].scope) ==  'string' then
                Facebook.login(cbIndex - 1, arg[2].scope)
            else
                Facebook.login(cbIndex - 1)
            end
        else
            Facebook.login(cbIndex - 1)
        end
    else
        Facebook.login(-1)
    end
end

function FB.getLoginStatus(...)
    local arg = {...}
    local argNum = #arg

    if argNum > 0 then
        local type_cb = type(arg[1])
        if type_cb == 'function' then
            error(string.format("Expression is of type %s ,not function",type_cb))
        end

        local cbIndex = FB.indexOf(arg[1])
        if cbIndex == 0 then
           cbIndex = FB.pushCb(arg[1])
        end

        if argNum == 2 then
            if force == 'true' then
                Facebook.getLoginStatus(cbIndex - 1, true)
            else
                Facebook.getLoginStatus(cbIndex - 1, false)
            end
        else
            Facebook.getLoginStatus(cbIndex - 1, false)
        end
    end
end

function FB.logout(...)
    local arg = {...}
    local argNum = #arg

    if (argNum > 0) then
        local type_cb = type(arg[1])
        if (type_cb ~= 'function') then
            error(string.format("Expression is of type %s ,not function",type_cb))
        end

        local cbIndex = FB.indexOf(arg[1])
        if (cbIndex == 0) then
            cbIndex = FB.pushCb(cb)
        end

        Facebook.logout(cbIndex - 1)
    
    else
        Facebook.logout(-1)
    end
end

--path,method,params,cb
function FB.api(...)
    local arg = {...}
    local argNum = #arg
    local typePath = type(arg[1])
    if typePath ~= "string" then
        error(string.format("Expression is of type %s ,not string",type_cb))
    elseif string.len(arg[1]) == 0 then
        error("The passed argument could not be parsed as a url.")
    end

    local method = nil
    local params = nil
    local callback = nil

    for i = 2, argNum do
        local typeArg = type(arg[i])
        if typeArg == "string" then
            method = arg[i]
        elseif typeArg == "table" then
            params = arg[i]
        elseif typeArg == "function" then
            callback = arg[i]
        end
    end

    if nil ~= method and method ~= 'get' and method ~= 'post' and method ~= 'delete' then
        error(string.format("Invalid method passed to ApiClient: %s ", method))
    end

    local cbIndex = 0
    if nil ~= callback then
        cbIndex = FB.indexOf(callback)
        if (cbIndex == 0) then
            cbIndex = FB.pushCb(callback)
        end
    end
    
    local tmp = string.find(arg[1], "?")
    if tmp ~= nil then
        if (string.len(arg[1]) > tmp) then
            local temParams = "{" ..string.sub(arg[1], tmp + 1) .. "}"
            temParams = string.gsub(temParams, "&", ",")
            temParams = string.gsub(temParams, "=", ":")

            --UNDO eval json
            local testTemParams = json.decode(temParams, 1)
            --temParams = eval(temParams);
            if (nil ~= params) then
                for k, v in pairs(params) do
                    --print(k, v)
                    params[k] = testTemParams[k]
                end
            else
                --print(params)
                params = testTemParams
            end
        end

        arg[1] = string.sub(arg[1], 1, tmp - 1)
    end

    if string.find(arg[1], "/picture") ~= 0 then
        if nil ~= params then
            params.redirect = "false"
        else
            params = {redirect = "false"}
        end
    end
    --print(arg[1], method, json.encode(params), cbIndex)
    local errMsg = Facebook.api(arg[1], method, json.encode(params), cbIndex - 1)
    if errMsg ~= nil then
        -- var errorObj = eval('(' + error + ')');
        -- throw  errorObj;
        error("call Facebook.api error")
    end
end

function FB.ui(...) 
    local arg = {...}
    local argNum = #arg
    if argNum == 2 then
        local cbIndex = FB.indexOf(arg[2])
        if (cbIndex == 0) then
            cbIndex = FB.pushCb(arg[2])
        end
        Facebook.ui(json.encode(arg[1]), cbIndex - 1)
    end
end
--index, params
function FB.callback(...)
    local arg = {...}
    local argNum = #arg
    if arg[1] >= 0 and arg[1] < #FB.cbArray then
        if argNum == 2 then
            local params = string.gsub(arg[2], "\\/", "/")
            FB.cbArray[arg[1] + 1](params)
        else
            FB.cbArray[arg[1] + 1]()
        end 
    end
end

return FB