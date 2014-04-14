LoadUrlImage = LoadUrlImage or {}

LoadUrlImage.cbArray = {}

function LoadUrlImage.indexOf(cb)
    local index = 0
    for i = 1, #LoadUrlImage.cbArray do
        if LoadUrlImage.cbArray[i] == cb then
            index = i
            break
        end
    end

    return index
end

function LoadUrlImage.pushCb(cb)
    LoadUrlImage.cbArray[#LoadUrlImage.cbArray + 1] = cb
    return #LoadUrlImage.cbArray
end

function LoadUrlImage.addImageAsync(url, cb)
    local type_cb = type(cb)

    if type_cb ~= "function" then
        error(string.format("Expression is of type %s, not function",type_cb))
    end

    local cbIndex = LoadUrlImage.indexOf(cb)
    if cbIndex == 0 then
        cbIndex = LoadUrlImage.pushCb(cb)
    end
    print("LoadUrlImage addImageAsync", cbIndex - 1)
    LoadUrlImage.loadUrlImage(url,cbIndex - 1)
end

--cbIndex, imageKey
function LoadUrlImage.callback(...)
    local arg = {...}
    local argNum = #arg
    print("LoadUrlImage callback", arg[1])
    if arg[1] >= 0 and arg[1] < #LoadUrlImage.cbArray then
        if argNum == 2 then
            LoadUrlImage.cbArray[arg[1] + 1](arg[2])
        else
            LoadUrlImage.cbArray[arg[1] + 1]()
        end 
    end
end
