local gfs = require('gears.filesystem')
local rc_dir = gfs.get_configuration_dir()

local fennel = require('fennel')
fennel.path = rc_dir .. '?.fnl;' .. rc_dir .. '?/init.fnl'
table.insert(package.loaders or package.searchers, fennel.searcher)
debug.traceback = fennel.traceback

require('core')
