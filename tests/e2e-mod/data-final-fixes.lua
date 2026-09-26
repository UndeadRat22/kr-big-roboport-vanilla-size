-- E2E data-stage checks for kr-big-roboport-vanilla-size.
-- Depends on kr-big-roboport-vanilla-size, so its data-final-fixes has
-- already run when this file executes. Verifies the modified prototypes
-- directly in data.raw (graphics scales, shifts, pad bounds, stats).

local function check(cond, label)
  log("E2E " .. (cond and "PASS" or "FAIL") .. " " .. label)
end

local function close(a, b, eps)
  return math.abs(a - b) <= (eps or 0.001)
end

local function box_matches(a, b)
  return close(a[1][1], b[1][1]) and close(a[1][2], b[1][2])
    and close(a[2][1], b[2][1]) and close(a[2][2], b[2][2])
end

local vanilla = data.raw.roboport["roboport"]
local big = data.raw.roboport["kr-big-roboport"]

if not big then
  check(true, "kr-big-roboport absent (no Krastorio 2) - mod is a no-op")
  log("E2E DATA OK")
elseif vanilla then
  check(box_matches(big.collision_box, vanilla.collision_box), "collision box matches vanilla roboport")
  check(box_matches(big.selection_box, vanilla.selection_box), "selection box matches vanilla roboport")

  for _, suffix in ipairs({ "-logistic-mode", "-construction-mode" }) do
    local variant = data.raw.roboport["kr-big-roboport" .. suffix]
    check(variant ~= nil, "variant exists: " .. suffix)
    if variant then
      check(box_matches(variant.collision_box, vanilla.collision_box), "collision box matches vanilla: " .. suffix)
      check(box_matches(variant.selection_box, vanilla.selection_box), "selection box matches vanilla: " .. suffix)
    end
  end

  -- Graphics: K2 2.x uses base scale 0.5 for an 8x8 footprint; halved for 4x4.
  local base_layer = big.base and big.base.layers and big.base.layers[1]
  if base_layer then
    check(close(base_layer.scale, 0.25), "base sprite scale is 0.25 (was 0.5)")
    check(close(base_layer.shift[1], 0) and close(base_layer.shift[2], -0.21), "base sprite shift scaled to {0, -0.21}")
  end
  local shadow_layer = big.base and big.base.layers and big.base.layers[2]
  if shadow_layer then
    check(close(shadow_layer.scale, 0.25), "shadow sprite scale is 0.25")
  end
  local anim_layer = big.base_animation and big.base_animation.layers and big.base_animation.layers[1]
  if anim_layer then
    check(close(anim_layer.scale, 0.25), "base animation scale is 0.25")
  end
  if big.water_reflection and big.water_reflection.pictures then
    check(close(big.water_reflection.pictures.scale, 2.5), "water reflection scale is 2.5 (was 5)")
  end

  -- Charging pads: count preserved, pulled inside the vanilla footprint.
  if big.charging_offsets then
    check(#big.charging_offsets == 20, "charging pad count preserved (20)")
    local max_off = 0
    for _, offset in ipairs(big.charging_offsets) do
      max_off = math.max(max_off, math.abs(offset[1] or 0), math.abs(offset[2] or 0))
    end
    check(max_off <= 1.75, "charging pads within vanilla footprint (max |offset| = " .. string.format("%.3f", max_off) .. ")")
  end

  -- Stats untouched.
  check(big.logistics_radius == 100, "logistics radius unchanged (100)")
  check(big.construction_radius == 200, "construction radius unchanged (200)")
  check(big.robot_slots_count == 20, "robot slots unchanged (20)")

  -- Remnant swap.
  check(big.corpse == "roboport-remnants", "corpse is vanilla roboport-remnants")

  -- Circuit connector points moved inside the smaller footprint.
  local wire = big.circuit_connector and big.circuit_connector.points and big.circuit_connector.points.wire
  if wire and wire.red then
    local x = wire.red.x or wire.red[1]
    local y = wire.red.y or wire.red[2]
    check(math.abs(x) <= 1.7 and math.abs(y) <= 1.7, "circuit connector red wire inside footprint")
  end

  log("E2E DATA OK")
end
