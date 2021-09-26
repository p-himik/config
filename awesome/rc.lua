local gfs = require('gears.filesystem')
local rc_dir = gfs.get_configuration_dir()
local in_rc = function (path)
  return rc_dir .. path
end

local fennel = require('fennel')
fennel.path = table.concat({in_rc('?.fnl'),
                            in_rc('?/init.fnl')}, ';')
fennel['macro-path'] = table.concat({in_rc('?.fnl'),
                                     in_rc('?/init-macros.fnl'),
				     in_rc('?/init.fnl')}, ';')
table.insert(package.loaders or package.searchers, fennel.searcher)
debug.traceback = fennel.traceback

require('core')
