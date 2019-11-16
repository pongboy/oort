local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Canvas = Neact.Component:new()

function Canvas:new(props)
  return new(Canvas, {
               props = props,
               state = {
                 cursor_x = 0, cursor_y = 0,
                 show_cursor = false,
               }
  })
end

function Canvas:pick_color(x, y)
  self.props.onpickcolor(self.props.sprite:get_pixel(x, y))
end

function Canvas:render(state, props)
  props.scale = props.scale < 1 and 1 or props.scale

  local w, h = props.sprite.width*props.scale, props.sprite.height*props.scale

  return {
    x = NOM.left+(NOM.width-w)/2+props.offset_x,
    y = NOM.top+(NOM.height-h)/2+props.offset_y,
    w = w+2, h = h+2,

    background = 8,
    border_size = 1,
    border_color = 1,

    clip_to = 1,

    draw_checkboard = function(self)
      local x, y, w, h = self.x+1, self.y+1, self.w-2, self.h-2

      local side = 8*props.scale
      local colors = { 10, 8 }

      -- Draw a checkers pattern
      for iy=y,y+h-1,side do
        for ix=x,x+w-1,side do
          fill_rect(ix, iy, side, side, colors[math.floor(((ix-x)+(iy-y))/side) % 2 + 1])
        end
      end
    end,

    draw_cursor = function(self)
      if state.show_cursor then
        fill_rect(self.x+state.cursor_x*props.scale+1,
                  self.y+state.cursor_y*props.scale+1,
                  props.scale,
                  props.scale,
                  props.color-1)
      end
    end,

    draw_sprite = function(self, spr)
      local data = spr.data
      local w, h = spr.width, spr.height

      for y=0,h-1 do
        for x=0,w-1 do
          local c = data[y*w+x]

          if c then
            fill_rect(self.x+1+x*props.scale, self.y+1+y*props.scale,
                      props.scale, props.scale,
                      c + (props.palette-1)*16)
          end
        end
      end
    end,

    draw = function(self)
      if self.dirty then
        self.dirty = false

        clip(unwrap(Widget.clip_box(self, 1)))

        fill_rect(self.x, self.y, self.w, self.h, self.border_color)

        self:draw_checkboard()

        self:draw_sprite(props.sprite)
        self:draw_sprite(props.preview)

        self:draw_cursor()
      end
    end,

    onenter = function(w)
      w.document:set_cursor("pencil")

      self:set_state({
          show_cursor = true
      })
    end,

    onleave = function(w)
      w.document:set_cursor("default")

      self:set_state({
          show_cursor = false
      })
    end,

    onpress = function(w, event)
      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if props.picker then
        self:pick_color(nx, ny)
      else
        self.props.tool:press(props.preview, props.sprite, nx, ny, props.color-1)
      end
    end,

    onclick = function(w, event)
      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if props.picker then
        -- self:pick_color(nx, ny)
      else
        self.props.tool:release(props.sprite, nx, ny, props.color-1)
      end
    end,

    onmove = function(w, event)
      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if event.drag then
        if props.picker then
          self:pick_color(nx, ny)
        else
          props.tool:move(props.sprite,
                          state.cursor_x, state.cursor_y,
                          nx, ny,
                          props.color-1)
        end
      end

      self:set_state {
        cursor_x = nx,
        cursor_y = ny
      }
    end,
  }
end

return Canvas
