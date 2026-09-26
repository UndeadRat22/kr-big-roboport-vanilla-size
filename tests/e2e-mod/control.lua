-- E2E runtime checks for kr-big-roboport-vanilla-size.
-- Runs on a headless server (see tests/run-e2e*.sh). Verifies at runtime:
--   1. kr-big-roboport (and its mode variants) place successfully
--   2. Their bounding boxes match the vanilla roboport's
--   3. Two big roboports (and a big next to a vanilla one) fit at 4-tile
--      spacing - impossible with the original 8x8 footprint
-- Without Krastorio 2, verifies the mod is a no-op.

local function check(cond, label)
  log("E2E " .. (cond and "PASS" or "FAIL") .. " " .. label)
end

local function close(a, b)
  return math.abs(a - b) <= 0.001
end

local function flat_land(surface, left, top, right, bottom)
  surface.request_to_generate_chunks({ (left + right) / 2, (top + bottom) / 2 }, 4)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = left, right - 1 do
    for y = top, bottom - 1 do
      tiles[#tiles + 1] = { name = "landfill", position = { x, y } }
    end
  end
  surface.set_tiles(tiles, true)
end

script.on_event(defines.events.on_tick, function()
  if game.tick < 10 then return end
  if storage.done then return end
  storage.done = true

  local big_proto = prototypes.entity["kr-big-roboport"]
  if not big_proto then
    check(true, "kr-big-roboport absent without Krastorio 2 - mod is a no-op")
    log("E2E DONE")
    return
  end

  local surface = game.surfaces["nauvis"]
  flat_land(surface, -8, -8, 40, 8)

  local vanilla_port = surface.create_entity({ name = "roboport", position = { 0, 0 }, force = "player" })
  check(vanilla_port ~= nil, "vanilla roboport placed")

  local big = surface.create_entity({ name = "kr-big-roboport", position = { 8, 0 }, force = "player" })
  check(big ~= nil, "kr-big-roboport placed")

  if vanilla_port and big then
    local vb, bb = vanilla_port.bounding_box, big.bounding_box
    check(
      close(vb.right_bottom.x - vb.left_top.x, bb.right_bottom.x - bb.left_top.x)
      and close(vb.right_bottom.y - vb.left_top.y, bb.right_bottom.y - bb.left_top.y),
      "runtime bounding box matches vanilla roboport"
    )
  end

  -- Two big roboports 4 tiles apart: overlaps at the original 7.5x7.5 size.
  local big2 = surface.create_entity({ name = "kr-big-roboport", position = { 12, 0 }, force = "player" })
  check(big2 ~= nil, "two big roboports fit at 4-tile spacing")

  -- Big roboport next to a vanilla one, also 4 tiles apart.
  local big3 = surface.create_entity({ name = "kr-big-roboport", position = { 4, 0 }, force = "player" })
  check(big3 ~= nil, "big roboport fits next to vanilla roboport at 4-tile spacing")

  for _, name in ipairs({ "kr-big-roboport-logistic-mode", "kr-big-roboport-construction-mode" }) do
    local variant = surface.create_entity({ name = name, position = { 24, 0 }, force = "player" })
    check(variant ~= nil, "variant placed: " .. name)
    if variant and vanilla_port then
      local vb, bb = vanilla_port.bounding_box, variant.bounding_box
      check(
        close(vb.right_bottom.x - vb.left_top.x, bb.right_bottom.x - bb.left_top.x)
        and close(vb.right_bottom.y - vb.left_top.y, bb.right_bottom.y - bb.left_top.y),
        "variant bounding box matches vanilla: " .. name
      )
    end
    if variant then
      variant.destroy()
    end
  end

  log("E2E DONE")
end)
