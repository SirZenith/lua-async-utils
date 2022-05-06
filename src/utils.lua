local copas = require "copas"
local http = require "copas.http"
local lfs = require "lfs"
local luv = require "luv"

local M = {}

function M.main_loop()
    copas.running = true
    while not copas.finished() or luv.loop_alive() do
        if not copas.finished() then
            copas.step()
        end
        if luv.loop_alive() then
            luv.run("nowait")
        end
    end
end

-- -----------------------------------------------------------------------------

---@param file_path string
---@param data string
---@param msg_receiver Recorder
function M.write_file(file_path, data, msg_receiver)
    luv.fs_open(file_path, "w+", 438, function(err, fd)
        assert(not err, err)
        luv.fs_write(fd, data, nil, function(err_o, _)
            assert(not err_o, err_o)
            luv.fs_close(fd, function(err_c)
                assert(not err_c, err_c)
                if msg_receiver then
                    msg_receiver:notify(1, "file saved to " .. file_path)
                end
            end)
        end)
    end)
end

-- -----------------------------------------------------------------------------
-- File Checking

---@param path string
---@return boolean
local function file_exists(path)
    local file = io.open(path, "r")
    local ok = file ~= nil
    if file then file:close() end
    return ok
end

---@param path string
---@param size integer
---@return boolean
local function check_file_size(path, size)
    local fsize = lfs.attributes(path, "size")
    if not fsize then
        return false
    else
        return fsize == size
    end
end

local MON = {
    Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
    Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

---@param date string
---@return integer time
local function parse_date(date)
    local p = "%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+)"
    local day, month, year, hour, min, sec = date:match(p)
    month = MON[month]
    local offset = os.time() - os.time(os.date("!*t"))
    local time = os.time({
        day = day, month = month, year = year,
        hour = hour, min = min, sec = sec
    })
    return time + offset
end

---@param path string
---@param date string
---@return boolean
local function check_file_mod(path, date)
    local mod_time = parse_date(date)
    local fmod_time = lfs.attributes(path, "modification")
    if not fmod_time then
        return false
    else
        return fmod_time >= mod_time
    end
end

-- -----------------------------------------------------------------------------
-- Network IO

---@param url string
---@param path string
---@param retry_count integer
---@return boolean can_dl
---@return string? errmsg
local function check_dl_header(url, path, retry_count)
    retry_count = retry_count or 1

    if not file_exists(path) then
        return true, nil
    end

    local code, headers
    for _ = 1, retry_count do
        _, code, headers, _ = http.request {
            url = url, method = "HEAD",
        }
        if code == 200 then break end
    end
    if not headers then
        return false, code
    end
    for k, v in pairs(headers) do
        headers[k:lower()] = v
    end

    local size, mod_time = headers["content-length"], headers["last-modified"]
    if not check_file_size(path, size) then
        return true, nil
    elseif not check_file_mod(path, mod_time) then
        return true, nil
    end
    return false, "file already exists " .. path
end

function M.dl_url(
    queue, retry_count, msg_receiver,
    gen_url, gen_path, gen_error
)
    local data
    while not queue:is_closed() do
        data = queue:pop()
        -- if queue is closed now
        if data == nil then break end

        local url = gen_url(data)
        local out_file = gen_path(data)
        local can_dl, errmsg = check_dl_header(url, out_file, retry_count)
        if not can_dl then
            msg_receiver:notify(1, errmsg)
        else
            local content, code
            for _ = 1, retry_count do
                content, code, _, _ = http.request(url)
                if code == 200 then break end
            end

            if code == 200 then
                M.write_file(out_file, content, msg_receiver)
            else
                msg_receiver:notify(1, gen_error(data, code))
            end
        end
    end
end

return M
