local rc_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local fennel = require('fennel')
fennel.path = rc_dir .. '?.fnl;' .. rc_dir .. '?/init.fnl'
table.insert(package.loaders or package.searchers, fennel.searcher)
debug.traceback = fennel.traceback

require('core')
