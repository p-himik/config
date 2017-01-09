local base = require("wibox.widget.base")
local util = require("awful.util")
local table = table
local pairs = pairs
local ipairs = ipairs
local floor = math.floor
local orderedPairs = require('util').orderedPairs

local function round(x)
    return floor(x + 0.5)
end

local grid = { mt = {} }

function grid:layout(context, width, height)
    local result = {}
    local median_width = floor(width / self._private.num_columns)
    local median_height = floor(height / self._private.num_lines)
    for _, d in pairs(self._private.widgets) do
        local w = floor(median_width * d.cols)
        local h = floor(median_height * d.lines)

        local cw, ch = base.fit_widget(self, context, d.widget, w, h)
        if cw < w then cw = w end
        if ch < h then ch = h end

        local x = round(median_width * (d.left - 1))
        local y = round(median_height * (d.top - 1))
        table.insert(result, base.place_widget_at(d.widget, x, y, cw, ch))
    end
    return result
end

function grid:add_child(child, left, top, n_cols, n_lines)
    base.check_widget(child)

    for i = 0, (n_lines - 1) do
        local line = self._private.matrix[top + i]
        if line == nil then
            line = {}
            self._private.matrix[top + i] = line
        end

        for j = 0, (n_cols - 1) do
            line[left + j] = child
        end
    end

    local widget_data = {}
    widget_data.widget = child
    widget_data.left = left
    widget_data.top = top
    widget_data.cols = n_cols
    widget_data.lines = n_lines

    table.insert(self._private.widgets, widget_data)

    if self._private.num_lines < n_lines + (top - 1) then
        self._private.num_lines = n_lines + (top - 1)
    end

    if self._private.num_columns < n_cols + (left - 1) then
        self._private.num_columns = n_cols + (left - 1)
    end

    local s = self
    child:connect_signal(
        "widget::layout_changed",
        function ()
            s:emit_signal("widget::layout_changed")
        end
    )
    self:emit_signal("widget::layout_changed")
end

function grid:get_child(left, top)
    local line = self._private.matrix[left]
    if line == nil then return line end
    return line[top]
end

function grid:fit(context, width, height)
    local matrix = self._private.matrix
    local max_width = 0
    local cumul_height = 0

    for _, line in orderedPairs(matrix) do
        local prev_widget
        local max_height = 0
        for _, w in orderedPairs(line) do
            local cumul_width = 0
            if (prev_widget == nil or w ~= prev_widget) then
                local w, h = base.fit_widget(self, context, w, width, height)
                cumul_width = cumul_width + w
                if max_height < h then max_height = h end
                prev_widget = w
            end
            print(cumul_width)
            if max_width < cumul_width then max_width = cumul_width end
        end

        cumul_height = max_height + cumul_height
    end
    return max_width, cumul_height
end

function grid.new()
    local ret = base.make_widget(nil, nil, { enable_properties = true })

    util.table.crush(ret, grid, true)

    ret._private.matrix = {}
    ret._private.widgets = {}
    ret._private.num_lines = 0
    ret._private.num_columns = 0

    return ret
end

function grid.mt:__call(...)
    return grid.new(...)
end

return setmetatable(grid, grid.mt)
