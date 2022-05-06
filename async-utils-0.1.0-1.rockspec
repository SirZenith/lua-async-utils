package = "async-utils"
version = "v0.1.0-1"
source = {
    url = "git://github.com/SirZenith/lua-async-utils.git",
    tag = version,
}
description = {
    homepage = "https://github.com/SirZenith/lua-async-utils",
    license = "MIT/X11"
}
dependencies = {}
build = {
    type = "builtin",
    modules = {
        ["async-utils"] = "src/init.lua",
        ["async-utils.recorder"] = "src/recorder.lua",
        ["async-utils.task_queue"] = "src/task_queue.lua"
    }
}
