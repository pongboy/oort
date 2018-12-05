local Easing = require('nibui.Easing')
local dynamic = require('nibui.NOM').dynamic

local envelopes_w = 60

local envelopes = {
    id = 'envelopes',
    x = dynamic 'left', y = dynamic 'top',
    w = envelopes_w, h = dynamic '^' 'h',

    open = function(self)
        self.x = {dynamic 'left', 0.3, Easing.InCubic}
    end,
    close = function(self)
        self.x = {dynamic '-' (dynamic 'left', envelopes_w+1), 0.3, Easing.OutCubic}
    end,
}

for i=0,3 do
    table.insert(envelopes, dynamic '=>' ('elements.envelope', {
        x = dynamic 'left', y = dynamic '+' (dynamic '^' 'y', dynamic '%' (25*i, 'h')),
        w = dynamic '^' 'w', h = dynamic '%' (25+1, 'h'),
        background = 16+i,
        index = i,
    }));
end

local app = {
    x = dynamic 'left', y = dynamic '+' (dynamic '^' 'y', 13),
    w = dynamic '^' 'w', h = dynamic '-' (dynamic '^' 'h', 25),
    background = 7,
    envelopes,
}


local nom = {
    x = dynamic '+' (dynamic '^' 'x', 1),
    y = dynamic '+' (dynamic '^' 'y', 1),
    w = dynamic '-' (dynamic '^' 'w', 2),
    h = dynamic '-' (dynamic '^' 'h', 2+16),
    background = 7,
    border_color = 6,
    dynamic '=>' 'elements.header',
    app,
    dynamic '=>' 'elements.status',
    {
        x = dynamic '-' (dynamic 'left', 1),
        y = dynamic '+' (dynamic 'bottom', 1),
        w = dynamic '+' (dynamic '^' 'w', 2),
        h = 1,
        background = 4
    },
}


return nom
