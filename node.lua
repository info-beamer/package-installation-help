node.alias "install"
util.no_globals()

local SERIAL = sys.get_env "SERIAL"
local font = resource.load_font "Ubuntu-C.ttf"
local gray = resource.create_colored_texture(1,1,1,0.5)
local json = require "json"

local logo, config, st, portrait, info, big
util.file_watch("config.json", function(raw)
    config = json.decode(raw)
    logo = resource.load_image(config.logo.asset_name)
    info = config.info

    local rotation = 0
    big = ""
    for idx = 1, #config.devices do
        local device = config.devices[idx]
        pp(device)
        if device.serial == SERIAL then
            rotation = device.rotation
            big = device.big
        end
    end

    gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
    st = util.screen_transform(rotation)

    portrait = rotation == 90 or rotation == 270
end)

local function wrap(str, limit)
    limit = limit or 72
    local here = 1
    local wrapped = str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
        if fi-here > limit then
            here = st
            return "\n"..word
        end
    end)
    local splitted = {}
    for token in string.gmatch(wrapped, "[^\n]+") do
        splitted[#splitted + 1] = token
    end
    return splitted
end


local v = {
    serial = SERIAL
}

util.data_mapper{
    ["update/(.*)"] = function(key, val)
        v[key] = val
    end
}

local function draw_info()
    local size, k_x, v_x, y
    if portrait then
        size = math.floor(HEIGHT/30)
        y = 30+size*6
        k_x, v_x = 30, 30+font:width("XXXXXXXXXXXXXXXX", size)
        util.draw_correct(logo, 30, 30, WIDTH-30, 30+size*5)
    else
        size = math.floor(HEIGHT/20)
        y = 30+size*6
        k_x, v_x = 30, 30+font:width("XXXXXXXXXXXXXXXX", size)
        util.draw_correct(logo, 30, 30, WIDTH/2-30, 30+size*5)
        gray:draw(WIDTH/2-1, 0, WIDTH/2+1, HEIGHT)
    end

    local function key(str)
        font:write(k_x, y, str, size, 1,1,1,.5)
    end
    local function val(str, col)
        col = col or {1,1,1,.5}
        font:write(v_x, y, str, size, unpack(col))
        y = y + size*1.1
    end

    if v.serial then
        key "Serial number"
        val(v.serial)
    end

    if v.network then
        key "Network config"
        val(v.network)
    end

    if v.ethmac then
        key "Ethernet MAC"
        val(v.ethmac)
    end

    if v.ethip then
        key "Ethernet IPv4"
        val(v.ethip)
    end

    if v.wlanmac then
        key "WiFi MAC"
        val(v.wlanmac)
    end

    if v.wlanip then
        key "WiFi IPv4"
        val(v.wlanip)
    end

    if v.gw then
        key "Gateway"
        val(v.gw)
    end

    if v.online then
        key "Online status"
        local col = {1,0,0,1}
        if v.online == "online" then
            col = {0,1,0,1}
        end
        val(v.online, col)
    end

    key "Timestamp"
    val(math.floor(os.time()))

    if info ~= "" then
        val ""
        local lines = wrap(info, 40)
        for idx = 1, #lines do
            local line = lines[idx]
            key(line)
            val""
        end
    end

    if big ~= "" then
        local s = math.min(400, size*5)
        local w = font:width(big, s)
        local x = WIDTH*0.75
        local y = HEIGHT*0.5
        if portrait then
            x = WIDTH * 0.5
            y = HEIGHT * 0.75
        end
        font:write(x-w/2, y-s/2, big, s, 1,1,1,1)
    end
end

function node.render()
    st()
    gl.clear(0,0,0,1)
    draw_info()
end
