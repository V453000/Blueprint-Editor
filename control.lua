local mod_gui = require("mod-gui")
local blueprint_editor_surface_size = 1
local blueprint_editor_original_position = {0,0}
local blueprint_editor_original_surface = 'nauvis'
local blueprint_editor_original_controller = 1
local original_blueprint_string = ''

function debug_print(text)
  --game.print(text)
end

local blueprint_editor_surface_name = 'bp-editor-surface'

function migrate_inventory(source, destination)
  for item_name, item_count in pairs(source.get_inventory[1]) do
    destination.insert{name = item_name, count = item_count}
  end
end

function reset_concrete(target_surface)
  local buildable_tiles = {'water'}--for resetting water for offshore pumps
  for name,tile in pairs(game.tile_prototypes) do
    if tile.items_to_place_this then
      --game.print(name)
      table.insert(buildable_tiles, name)
    end
  end

  local old_tiles = target_surface.find_tiles_filtered(buildable_tiles)
  local new_tiles = {}
  for _, t in pairs(old_tiles) do
    local coord_test = (t.position.x + t.position.y)%2
    local tile_name = 'lab-white'
    if (coord_test==0) then
      tile_name = 'lab-dark-1'
    else
      tile_name = 'lab-dark-2'
    end  
    table.insert(new_tiles, {name = tile_name, position=t.position})
  end
  edit_surface.set_tiles(new_tiles)
  debug_print('Concrete replaced with lab tiles.')
end

function set_lab_tiles(target_surface)
  local old_tiles = target_surface.find_tiles_filtered({})
    local new_tiles = {}
    for _, t in pairs(old_tiles) do
      local coord_test = (t.position.x + t.position.y)%2
      local tile_name = 'lab-white'
      if (coord_test==0) then
        tile_name = 'lab-dark-1'
      else
        tile_name = 'lab-dark-2'
      end  
      table.insert(new_tiles, {name = tile_name, position=t.position})
    end
    edit_surface.set_tiles(new_tiles)
    debug_print('Generated lab tiles.')
end

function generate_lab_tile_surface(player, surface_name, surface_size)
  if game.surfaces[surface_name] then
    debug_print('Edit surface found.')
    edit_surface = game.surfaces[surface_name]
  else
    debug_print('Edit surface not found, creating...')
    -- local map_settings =
    -- {
    --   seed = 666,
    --   width = 8*32,
    --   height = 8*32,
      
    --   autoplace_controls = {
    --     coal = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     ["copper-ore"] = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     ["crude-oil"] = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     ["enemy-base"] = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     ["iron-ore"] = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     stone = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     trees = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     },
    --     ["uranium-ore"] = {
    --       frequency = 1,
    --       richness = 1,
    --       size = 0
    --     }
    --   },

    --   autoplace_settings = {},
    --   cliff_settings = {
    --     cliff_elevation_0 = 10,
    --     cliff_elevation_interval = 40,
    --     name = "cliff",
    --     richness = 0
    --   },
    --   peaceful_mode = false,
    --   property_expression_names = {},
    --   starting_area = 1,
    --   starting_points = {
    --     {
    --       x = 0,
    --       y = 0
    --     }
    --   },
    --   terrain_segmentation = 1,
    --   water = 0,

    -- }
    local map_settings = game.surfaces['nauvis'].map_gen_settings
    map_settings.width = 64
    map_settings.height = 64
    edit_surface = game.create_surface(surface_name, map_settings)--, map_settings)
    
    -- edit_surface.request_to_generate_chunks( {0,0} , 2)
    -- edit_surface.force_generate_chunk_requests()
    -- player.force.chart_all()
    
    --set_lab_tiles(edit_surface)
    
    --edit_surface.destroy_decoratives({invert=true})
    debug_print('Destroyed decoratives.')
  end

  return edit_surface
end

local function toggle_editor_and_teleport(player, destination_surface_name, original_position, blueprint_editor_original_controller, editor_on)
  if editor_on == true then  
    player.teleport({0,0}, destination_surface_name)
      if player.controller_type ~= 4 then
        player.toggle_map_editor()
      end
  else
    player.teleport(blueprint_editor_original_position, destination_surface_name)
    if player.controller_type == 4 and blueprint_editor_original_controller ~= 4 then
      player.toggle_map_editor()
    end
  end
end

local function clear_entities(target_surface)
  local entity_list = target_surface.find_entities()
  for _, ent in pairs(entity_list) do
    ent.destroy()
  end
  debug_print('Destroyed entities.')
end

local function build_blueprint(player, blueprint_string, target_surface)
  player.cursor_stack.import_stack(original_blueprint_string)

  local ghosts = player.cursor_stack.build_blueprint{surface = target_surface.name, position = {0,0}, force = 'player', force_build = true }
  player.cursor_stack.clear()
  debug_print('Built blueprint.')

  local ghost_trains = {}
  for _,ghost in pairs(ghosts) do
    if ghost.valid == true then
      if ghost.ghost_type == 'locomotive' or ghost.ghost_type == 'cargo-wagon' or ghost.ghost_type == 'fluid-wagon' or ghost.ghost_type == 'artillery-wagon' then
        table.insert(ghost_trains, ghost)
      else
        debug_print(ghost.ghost_name)
        ghost.silent_revive()
      end
    end
  end
  debug_print('Revived ghosts.')

  for _,ghost in pairs(ghost_trains) do
    if ghost.valid == true then
      debug_print(ghost.ghost_name)
      ghost.silent_revive()
    end
  end
  debug_print('Revived train ghosts.')

  for _, slot in pairs(target_surface.find_entities_filtered{name = "item-request-proxy"}) do
    for name,count in pairs(slot.item_requests) do
      slot.proxy_target.insert({name = name, count = count})
    end
    slot.destroy()
  end
end

local function is_string_book(player, string)
  player.cursor_stack.import_stack(string)
  local result = false
  if player.cursor_stack.name == 'blueprint-book' then
    result = true
  end
  return result
end

local function search_blueprint_string_for_entities(player, entity_type, string)
  local entities = {}
  player.cursor_stack.import_stack(string)
  local all_entities = player.cursor_stack.get_blueprint_entities()
  if all_entities then
    for _, ent in pairs(all_entities) do
      if game.entity_prototypes[ent.name].type == entity_type then
        table.insert(entities, ent)
      end
    end
  end
  return entities
end

local function search_blueprint_string_for_entity_name(player, entity_name, string)
  local entities = {}
  player.cursor_stack.import_stack(string)
  local all_entities = player.cursor_stack.get_blueprint_entities()
  if all_entities then
    for _, ent in pairs(all_entities) do
      if game.entity_prototypes[ent.name].name == entity_name then
        table.insert(entities, ent)
      end
    end
  end
  return entities
end

local function search_blueprint_string_for_tiles(player, tile_name, string)
  local tiles = {}
  player.cursor_stack.import_stack(string)
  local all_tiles = player.cursor_stack.get_blueprint_tiles()
  if all_tiles then
    for _, t in pairs(all_tiles) do
      if t.name == tile_name then
        table.insert(tiles, t)
      end
    end
  end
  return tiles
end


local function determine_rail_offset(player, original_blueprint_string)
  local straight_rails = search_blueprint_string_for_entity_name(player, 'straight-rail', original_blueprint_string)
  local curved_rails = search_blueprint_string_for_entity_name(player, 'curved-rail', original_blueprint_string)
  local train_stops = search_blueprint_string_for_entity_name(player, 'train-stop', original_blueprint_string)

  local rail_offset = { x = 0, y = 0}

  for id, straight_rail in pairs(straight_rails) do
    if (straight_rail.position.x % 2 == 0) or (straight_rail.position.y % 2 == 0) then
      rail_offset = { x = 1, y = 1}
      debug_print('Shifting because of straight rails.')
    end
  end
  for id, curved_rail in pairs(curved_rails) do
    if (curved_rail.position.x % 2 == 1) or (curved_rail.position.y % 2 == 1) then
      rail_offset = {x = 1, y = 1}
      debug_print('Shifting because of curved rails.')
    end
  end
  for id, train_stop in pairs(train_stops) do
    if (train_stop.position.x % 2 == 0) or (train_stop.position.y % 2 == 0) then
      rail_offset = {x = 1, y = 1}
      debug_print('Shifting because of train stops.')
    end
  end
  -- data = {}
  -- data.straight_rails = straight_rails
  -- data.curved_rails = curved_rails
  -- data.train_stops = train_stops
  -- return data
  return rail_offset

end



local function add_positions(position_A, position_B)
  position_result = {position_A.x + position_B.x, position_A.y + position_B.y}
  return position_result
end
local function add_array_and_position(array_A, position_B)
  position_result = {array_A[1] + position_B.x, array_A[1] + position_B.y}
  return position_result
end

local function tiles_for_landfill(player, original_blueprint_string, target_surface)
  local rail_offset = determine_rail_offset(player, original_blueprint_string)
  local landfill_tiles = search_blueprint_string_for_tiles(player, 'landfill', original_blueprint_string)
  local water_tiles = {}
  for name,tile in pairs(landfill_tiles) do
    table.insert(water_tiles, {name = 'water', position = add_positions(tile.position, rail_offset)})
  end
  target_surface.set_tiles(water_tiles)
end

local function find_resource(resource_category_name)
  for ent_name, ent in pairs(game.entity_prototypes) do
    if ent.type == 'resource' then
      if ent.resource_category == resource_category_name then
        return(ent_name)
      end
    end
  end
end
local function resources_for_mining_drills(player, original_blueprint_string, target_surface)
  local rail_offset = determine_rail_offset(player, original_blueprint_string)

  local mining_drills = search_blueprint_string_for_entities(player, 'mining-drill', original_blueprint_string)
  if mining_drills then
    for entity_id, drill in pairs(mining_drills) do
      --game.print(drill.name)
      for category_name,bool in pairs(game.entity_prototypes[drill.name].resource_categories) do
        --game.print(category)
        local res_name = find_resource(category_name)
        local res_ent = target_surface.create_entity{name = res_name, position = add_positions(drill.position, rail_offset)}
      end
    end
  end
end

local function rotate_collision_box_4way(collision_box, direction)
  --{{Xa, Ya},{Xb, Yb}}
  local Xa = collision_box.left_top.x
  local Ya = collision_box.left_top.y
  local Xb = collision_box.right_bottom.x
  local Yb = collision_box.right_bottom.y

  local result_collision_box = collision_box
  
  -- East
  if direction == 2 then
    result_collision_box = {left_top = {x= -Yb, y=-Xb}, right_bottom = {x= -Ya,y= -Xa}}
  -- South
  elseif direction == 4 then
    result_collision_box = {left_top = {x= -Xb,y= -Yb}, right_bottom = {x= -Xa,y= -Ya}}
  -- West
  elseif direction == 6 then
    result_collision_box = {left_top = {x= Ya,y= Xa}, right_bottom = {x= Yb,y= Xb}}
  end

  return result_collision_box
end

local function tile_list_from_collision_box(collision_box, offset, tile_name)
  --{{Xa, Ya},{Xb, Yb}}
  -- local offset_x = offset.x
  -- local offset_y = offset.y
  local Xa = collision_box.left_top.x + offset.x
  local Ya = collision_box.left_top.y + offset.y
  local Xb = collision_box.right_bottom.x + offset.x
  local Yb = collision_box.right_bottom.y + offset.y

  local tile_list = {}

  for y = Ya, Yb, 1 do
    for x = Xa, Xb, 1 do
      table.insert(tile_list, {name = tile_name, position = {x,y}})
    end
  end

  return tile_list
end

local function water_for_offshore_pumps(player, original_blueprint_string, target_surface)
  local rail_offset = determine_rail_offset(player, original_blueprint_string)
  local offshore_pumps = search_blueprint_string_for_entities(player, 'offshore-pump', original_blueprint_string)
  for entity_id, pump in pairs(offshore_pumps) do
    --game.print(pump.direction)
    local pump_prototype = game.entity_prototypes[pump.name]
    local collision_box_offset = pump_prototype.adjacent_tile_collision_box
    --local collision_box_offset = { { -1, -2 }, { 1, -1 } }
    local rotated_collision_box = rotate_collision_box_4way(collision_box_offset, pump.direction)
    local water_tile_list = tile_list_from_collision_box(rotated_collision_box, {x = pump.position.x + rail_offset.x, y = pump.position.y + rail_offset.y}, 'water')
    target_surface.set_tiles(water_tile_list)
    --log(serpent.block(water_tile_list))
  end
end

local function landfill_for_entities(player, original_blueprint_string, target_surface)
  local rail_offset = determine_rail_offset(player, original_blueprint_string)
  local landfill_tiles = search_blueprint_string_for_tiles(player, 'landfill', original_blueprint_string)
  local landfill_tiles_with_rail_offset = {}
  for _, tile in pairs(landfill_tiles) do
    table.insert(landfill_tiles_with_rail_offset, {name = tile.name, position = add_positions(tile.position, rail_offset)})
  end
  target_surface.set_tiles(landfill_tiles_with_rail_offset)
end

local function place_offshore_pumps(player, original_blueprint_string, target_surface)
  local rail_offset = determine_rail_offset(player, original_blueprint_string)
  local offshore_pumps = search_blueprint_string_for_entities(player, 'offshore-pump', original_blueprint_string)
  for entity_id, pump in pairs(offshore_pumps) do
    target_surface.create_entity({name = pump.name, position = add_positions(pump.position, rail_offset), direction = pump.direction, force='player'})
  end
end

local function fill_in_water(target_surface)
  local water_tiles = target_surface.find_tiles_filtered({name = 'water'})
  local tiles_to_fill = {}
  for _, tile in pairs(water_tiles) do
    table.insert(tiles_to_fill, {name = 'blue-refined-concrete', position = tile.position})
  end
  target_surface.set_tiles(tiles_to_fill)
end

local function get_surface_area(edit_surface)
  local surface_min_x = 0
  local surface_min_y = 0
  local surface_max_x = 0
  local surface_max_y = 0
  for chunk in edit_surface.get_chunks() do
    if chunk.x < surface_min_x then
      surface_min_x = chunk.x
    end
    if chunk.y < surface_min_y then
      surface_min_y = chunk.y
    end
    if chunk.x > surface_max_x then
      surface_max_x = chunk.x
    end
    if chunk.y > surface_max_y then
      surface_max_y = chunk.y
    end
  end
  local area = {{surface_min_x*32, surface_min_y*32}, {surface_max_x*32, surface_max_y*32}}
  return area
end

local function make_edit_surface_big_enough(player, string, edit_surface)
  -- get min/max for blueprint entities
  player.cursor_stack.import_stack(string)
  local blueprint_entities = player.cursor_stack.get_blueprint_entities()
  local blueprint_min_x = 0
  local blueprint_min_y = 0
  local blueprint_max_x = 0
  local blueprint_max_y = 0
  if blueprint_entities then
    for _, ent in pairs(blueprint_entities) do
      if ent.position.x < blueprint_min_x then
        blueprint_min_x = ent.position.x
      end
      if ent.position.y < blueprint_min_y then
        blueprint_min_y = ent.position.y
      end
      if ent.position.x > blueprint_max_x then
        blueprint_max_x = ent.position.x
      end
      if ent.position.y > blueprint_max_y then
        blueprint_max_y = ent.position.y
      end
    end
  end
  local blueprint_size_x = -blueprint_min_x + blueprint_max_x
  local blueprint_size_y = -blueprint_min_y + blueprint_max_y

  -- get min/max for current edit_surface
  local surface_min_x = 0
  local surface_min_y = 0
  local surface_max_x = 0
  local surface_max_y = 0
  for chunk in edit_surface.get_chunks() do
    if chunk.x < surface_min_x then
      surface_min_x = chunk.x
    end
    if chunk.y < surface_min_y then
      surface_min_y = chunk.y
    end
    if chunk.x > surface_max_x then
      surface_max_x = chunk.x
    end
    if chunk.y > surface_max_y then
      surface_max_y = chunk.y
    end
  end
  local surface_size_x = (-surface_min_x + surface_max_x)*32
  local surface_size_y = (-surface_min_y + surface_max_y)*32
  
  -- evaluate min/max
  local anything_out_of_bounds = false
  local needed_size = 1
  if surface_size_x < blueprint_size_x then
    anything_out_of_bounds = true
    needed_size = blueprint_size_x
  end
  if surface_size_y < blueprint_size_y then
    anything_out_of_bounds = true
    if blueprint_size_y > needed_size then
      needed_size = blueprint_size_y
    end
  end
  edit_surface.request_to_generate_chunks( {0,0} , math.ceil(needed_size/32/2) + 1 )
  edit_surface.force_generate_chunk_requests()
  -- player.force.chart_all()
end

local function reset_blueprint_editing(player, original_blueprint_string, edit_surface)
  clear_entities(edit_surface)
  reset_concrete(edit_surface)
  --set_lab_tiles(edit_surface)
  resources_for_mining_drills(player, original_blueprint_string, edit_surface)
  tiles_for_landfill(player, original_blueprint_string, edit_surface)
  water_for_offshore_pumps(player, original_blueprint_string, edit_surface)
  landfill_for_entities(player, original_blueprint_string, edit_surface)
  place_offshore_pumps(player, original_blueprint_string, edit_surface)
  fill_in_water(edit_surface)
  build_blueprint(player, original_blueprint_string, edit_surface)
end

local function enter_blueprint_editing(player)
  if player.surface.name ~= blueprint_editor_surface_name then
    blueprint_editor_original_position = player.position
    blueprint_editor_original_surface = player.surface
    local do_stuff = false

    if player.cursor_stack.valid_for_read then
      if player.cursor_stack.is_blueprint == true then
        if player.cursor_stack.is_blueprint_setup() == true then
          do_stuff = true
        else
          game.print('Blueprint is empty.')
        end
      elseif player.cursor_stack.is_blueprint_book == true then
        local book_inventory = player.cursor_stack.get_inventory(defines.inventory.item_main)
        if book_inventory.is_empty() == false then
          if player.cursor_stack.is_blueprint_setup() == true then
            do_stuff = true
          end
        else
          game.print('Blueprint book is empty.')
        end
      else
        game.print('Item in cursor is not a Blueprint or a Blueprint book.')
      end
    end

    if do_stuff == true then
      create_bp_editor_popup(player)
      visibility_bp_editor_popup(player, true)
      visibility_bp_editor_button(player, false)
      
      original_blueprint_string = player.cursor_stack.export_stack()
      input_blueprint = player.cursor_stack
      local is_book = is_string_book(player, original_blueprint_string)
      if is_book == true then
        input_blueprint = player.cursor_stack.get_inventory(defines.inventory.item_main)[player.cursor_stack.active_index]
      end
      blueprint_editor_original_label = input_blueprint.label
      blueprint_editor_original_blueprint_icons = input_blueprint.blueprint_icons
      blueprint_editor_original_controller = player.controller_type

      make_edit_surface_big_enough(player, original_blueprint_string, edit_surface)
      
      clear_entities(edit_surface)
      reset_concrete(edit_surface)
      --set_lab_tiles(edit_surface)
      toggle_editor_and_teleport(player, blueprint_editor_surface_name, blueprint_editor_original_position, blueprint_editor_original_controller, true)
      edit_surface.destroy_decoratives({invert=true})

      resources_for_mining_drills(player, original_blueprint_string, edit_surface)
      tiles_for_landfill(player, original_blueprint_string, edit_surface)
      water_for_offshore_pumps(player, original_blueprint_string, edit_surface)
      landfill_for_entities(player, original_blueprint_string, edit_surface)
      place_offshore_pumps(player, original_blueprint_string, edit_surface)
      fill_in_water(edit_surface)
      build_blueprint(player, original_blueprint_string, edit_surface)
    end
  else
    game.print('You are already in Blueprint Editor.')
  end
end

local function finish_blueprint_editing(player, blueprint_editor_original_position, blueprint_editor_original_controller, blueprint_editor_original_surface, editor_surface_name, discard_changes)
  if discard_changes == false then
    player.cursor_stack.set_stack('blueprint')
    local result_blueprint_string  = ''
    if game.surfaces[editor_surface_name] then
      local surface_size = 1
      local surface_area = get_surface_area(game.surfaces[editor_surface_name])
      player.cursor_stack.create_blueprint({
        surface = editor_surface_name,
        force = 'player',
        area = surface_area,
        always_include_tiles = true,
        include_entities = true,
        include_modules = true,
        include_trains = true,
        include_station_names = true
      })
      if blueprint_editor_original_label then
        player.cursor_stack.label = blueprint_editor_original_label
      end
      if blueprint_editor_original_blueprint_icons then
        player.cursor_stack.blueprint_icons = blueprint_editor_original_blueprint_icons
      end
      result_blueprint_string = player.cursor_stack.export_stack()
    else
      game.print('Blueprint editor surface not found.')
    end
    toggle_editor_and_teleport(player, blueprint_editor_original_surface, blueprint_editor_original_position, blueprint_editor_original_controller, false)
    local is_book = is_string_book(player, original_blueprint_string)
    if is_book == true then
      player.cursor_stack.import_stack(original_blueprint_string)
      local i = player.cursor_stack.active_index
      player.cursor_stack.get_inventory(defines.inventory.item_main)[i].import_stack(result_blueprint_string)
    else
      player.cursor_stack.import_stack(result_blueprint_string)
    end
  else
    toggle_editor_and_teleport(player, blueprint_editor_original_surface, blueprint_editor_original_position, blueprint_editor_original_controller, false)
    player.cursor_stack.import_stack(original_blueprint_string)
  end
  clear_entities(game.surfaces[editor_surface_name])
  visibility_bp_editor_popup(player, false)
  visibility_bp_editor_button(player, true)
end

local function guess_button_visibility(player, editor_surface_name)
  if mod_gui.get_button_flow(player)['blueprint-edit-button'] then
    if player.controller_type == 4 and player.surface.name == editor_surface_name then
      mod_gui.get_button_flow(player)['blueprint-edit-button'].visible = false
      player.gui.center['bp-editor-popup-flow']['bp-editor-popup-frame'].visible = true
    else
      mod_gui.get_button_flow(player)['blueprint-edit-button'].visible = true
      player.gui.center['bp-editor-popup-flow']['bp-editor-popup-frame'].visible = false
    end
  end
end

function visibility_bp_editor_button(player, visibility)
  if mod_gui.get_button_flow(player)['blueprint-edit-button'] then
    mod_gui.get_button_flow(player)['blueprint-edit-button'].visible = visibility
  end
end
function visibility_bp_editor_popup(player, visibility)
  if player.gui.center['bp-editor-popup-flow']['bp-editor-popup-frame'] then
    player.gui.center['bp-editor-popup-flow']['bp-editor-popup-frame'].visible = visibility
  end
end
function clear_bp_editor_button(player)
  if mod_gui.get_button_flow(player)['blueprint-edit-button'] then
    mod_gui.get_button_flow(player)['blueprint-edit-button'].destroy()
  end
end
function clear_bp_editor_popup(player)
  if player.gui.center['bp-editor-popup-frame'] then
    player.gui.center['bp-editor-popup-frame'].destroy()
  end
  if player.gui.center['bp-editor-popup-flow'] then
    player.gui.center['bp-editor-popup-flow'].destroy()
  end
end
function create_top_button(player)
  clear_bp_editor_button(player)
  local button = mod_gui.get_button_flow(player).add
  {
    type = "sprite-button",
    name = "blueprint-edit-button",
    sprite = "edit-blueprints-button",
    style = "shortcut_bar_button_blue",
    tooltip = {'gui-tooltip.edit-blueprints-button'}
  }
  button.style.height = 36
  button.style.width = 36
  button.style.padding = 1
end
function create_bp_editor_popup(player)
  clear_bp_editor_popup(player)

  local flow = player.gui.center.add({
    type = 'flow',
    name = 'bp-editor-popup-flow',
    direction = 'vertical'
  })
  flow.style.height = player.display_resolution.height*0.8/player.display_scale
  flow.style.vertical_align = 'bottom'
  flow.style.horizontal_align = 'center'

  local frame = flow.add({
    type = 'frame',
    name = 'bp-editor-popup-frame',
    direction = 'horizontal',
    caption = 'Blueprint editor'
  })
  frame.style.vertically_stretchable = false
  frame.ignored_by_interaction = false
  
  local button_exit = frame.add
  {
    type = "button",
    name = "blueprint-edit-button-discard",
    caption = 'Discard',
    tooltip = 'Discard changes and exit the editor.',
    style = 'red_back_button'
  }
  local button_reset = frame.add
  {
    type = "button",
    name = "blueprint-edit-button-reset",
    caption = 'Reset',
    tooltip = 'Reset changes and keep editing.',
    style = 'dialog_button'
  }
  local button_discard = frame.add
  {
    type = "button",
    name = "blueprint-edit-button-finish",
    caption = 'Finish',
    tooltip = 'Confirm changes and exit the editor.',
    style = 'confirm_button'
  }

  return frame
end

script.on_event(defines.events.on_player_display_resolution_changed  ,
  function(event)
    local player = game.get_player(event.player_index)
    create_top_button(player)
    create_bp_editor_popup(player)
    guess_button_visibility(player, blueprint_editor_surface_name)
  end
)

script.on_event(defines.events.on_player_cursor_stack_changed ,
  function(event)
    local player = game.get_player(event.player_index)
    create_top_button(player)
    generate_lab_tile_surface(player, 'bp-editor-surface', blueprint_editor_surface_size )
  end
)

script.on_event(defines.events.on_player_created ,
  function(event)
    local player = game.get_player(event.player_index)
    create_top_button(player)
    generate_lab_tile_surface(player, 'bp-editor-surface', blueprint_editor_surface_size )
  end
)

script.on_event(defines.events.on_gui_click ,
  function(event)
    if event.element.name == "blueprint-edit-button" then
      local player = game.get_player(event.player_index)
      -- blueprint_editor_original_position = player.position
      enter_blueprint_editing(player)
    end

    if event.element.name == "blueprint-edit-button-finish" then
      local player = game.get_player(event.player_index)
      finish_blueprint_editing(player, blueprint_editor_original_position, blueprint_editor_original_controller, blueprint_editor_original_surface, 'bp-editor-surface', false)
    end
    if event.element.name == "blueprint-edit-button-reset" then
      local player = game.get_player(event.player_index)
      reset_blueprint_editing(player, original_blueprint_string, edit_surface)
    end
    if event.element.name == "blueprint-edit-button-discard" then
      local player = game.get_player(event.player_index)
      finish_blueprint_editing(player, blueprint_editor_original_position, blueprint_editor_original_controller, blueprint_editor_original_surface, 'bp-editor-surface', true)
    end
  end
)