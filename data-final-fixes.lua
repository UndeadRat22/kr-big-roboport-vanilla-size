-- kr-big-roboport-vanilla-size: shrink Krastorio 2's big roboport (and its
-- logistic/construction mode variants) to the vanilla roboport footprint.
--
-- Geometry only: collision/selection boxes, sprite scales and shifts,
-- charging pad offsets, stationing offset, circuit connector position, and
-- the death remnant. Stats (charging energy, radii, slots, health, ...)
-- are left exactly as Krastorio 2 defines them.
--
-- Runs in data-final-fixes so it sees the final K2 values, including the
-- -logistic-mode / -construction-mode variants K2 creates in data-updates.

local BASE_NAME = "kr-big-roboport"

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

-- Scale a shift/offset given in either array form {x, y} or named {x=, y=}.
local function scale_shift(shift, s)
  if type(shift) ~= "table" then return shift end
  if shift.x ~= nil or shift.y ~= nil then
    return { x = (shift.x or 0) * s, y = (shift.y or 0) * s }
  end
  if shift[1] ~= nil or shift[2] ~= nil then
    return { (shift[1] or 0) * s, (shift[2] or 0) * s }
  end
  return shift
end

local function is_sprite_table(t)
  return type(t) == "table" and (t.filename ~= nil or t.layers ~= nil)
end

-- Scale a sprite (or animation, or array of sprites): halves `scale` and
-- shifts so the graphic shrinks toward the building center. Recurses into
-- `layers`. Sprites without filename/layers (e.g. util.empty_sprite()) are
-- left untouched.
local function scale_sprite(sprite, s)
  if type(sprite) ~= "table" then return end
  if sprite[1] ~= nil and is_sprite_table(sprite[1]) then
    for _, sub in ipairs(sprite) do scale_sprite(sub, s) end
    return
  end
  if not is_sprite_table(sprite) then return end
  if type(sprite.scale) == "number" then sprite.scale = sprite.scale * s end
  if sprite.shift ~= nil then sprite.shift = scale_shift(sprite.shift, s) end
  if sprite.layers ~= nil then
    for _, layer in ipairs(sprite.layers) do scale_sprite(layer, s) end
  end
end

-- circuit_connector is the table returned by
-- circuit_connector_definitions.create_single: { sprites = ..., points = ... }.
-- `points` holds wire/shadow red/green attachment points; `sprites` holds the
-- connector plug graphics (whose `shift` carries the position) plus LED light
-- offsets. Scale every position; keep the plug sprite size itself unchanged
-- (circuit connectors stay legible on smaller buildings, as in vanilla).
local function scale_circuit_connector(conn, s)
  if type(conn) ~= "table" then return end
  if type(conn.points) == "table" then
    for _, wire in pairs(conn.points) do
      if type(wire) == "table" then
        for key, point in pairs(wire) do
          if type(point) == "table" then
            wire[key] = scale_shift(point, s)
          end
        end
      end
    end
  end
  if type(conn.sprites) == "table" then
    for key, value in pairs(conn.sprites) do
      if type(value) == "table" then
        if value.filename ~= nil then
          if value.shift ~= nil then value.shift = scale_shift(value.shift, s) end
        else
          conn.sprites[key] = scale_shift(value, s)
        end
      end
    end
  end
end

------------------------------------------------------------------------------
-- Resize
------------------------------------------------------------------------------

local vanilla = data.raw.roboport["roboport"]
local big = data.raw.roboport[BASE_NAME]

if vanilla and big then
  local function selection_width(roboport)
    return roboport.selection_box[2][1] - roboport.selection_box[1][1]
  end

  local scale = selection_width(vanilla) / selection_width(big)

  -- Idempotence guard: if the footprints already match (e.g. this mod ran
  -- before, or another mod already resized it), do nothing.
  if scale ~= 1 then
    for name, roboport in pairs(data.raw.roboport) do
      if name == BASE_NAME or name:sub(1, #BASE_NAME + 1) == BASE_NAME .. "-" then
        -- Footprint: identical to the vanilla roboport.
        roboport.collision_box = table.deepcopy(vanilla.collision_box)
        roboport.selection_box = table.deepcopy(vanilla.selection_box)

        -- Graphics: shrink toward the center by the same factor.
        scale_sprite(roboport.base, scale)
        scale_sprite(roboport.base_patch, scale)
        scale_sprite(roboport.base_animation, scale)
        scale_sprite(roboport.door_animation_up, scale)
        scale_sprite(roboport.door_animation_down, scale)
        if type(roboport.water_reflection) == "table" and roboport.water_reflection.pictures then
          scale_sprite(roboport.water_reflection.pictures, scale)
        end

        -- Charging pads and idle-bot stationing: pull in with the building.
        if roboport.charging_offsets then
          for i, offset in ipairs(roboport.charging_offsets) do
            roboport.charging_offsets[i] = scale_shift(offset, scale)
          end
        end
        if roboport.stationing_offset then
          roboport.stationing_offset = scale_shift(roboport.stationing_offset, scale)
        end
        if roboport.spawn_and_station_height then
          roboport.spawn_and_station_height = roboport.spawn_and_station_height * scale
        end

        -- Circuit connector: move with the building, keep plug size.
        scale_circuit_connector(roboport.circuit_connector, scale)

        -- K2's "big random pipes" remnant is sized for ~6.5x6.5 buildings and
        -- is shared with many other K2 machines, so it cannot be scaled in
        -- place. Use the vanilla roboport remnant instead: it is built for
        -- exactly this footprint.
        if data.raw.corpse["roboport-remnants"] then
          roboport.corpse = "roboport-remnants"
        end
      end
    end
  end
end
