local mod_gui = require("mod-gui")
local custom_mod_gui = require("custom-mod-gui")

function debug_print(text)
  game.print(text)
end

local e_name = 'bp-editor-surface'


local map_settings = 
  {
    seed = 666,
    width = 32*8,
    height = 32*8,
    
    autoplace_controls = {
      coal = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      ["copper-ore"] = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      ["crude-oil"] = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      ["enemy-base"] = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      ["iron-ore"] = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      stone = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      trees = {
        frequency = 1,
        richness = 1,
        size = 0
      },
      ["uranium-ore"] = {
        frequency = 1,
        richness = 1,
        size = 0
      }
    },

    autoplace_settings = {},
    cliff_settings = {
      cliff_elevation_0 = 10,
      cliff_elevation_interval = 40,
      name = "cliff",
      richness = 0
    },
    peaceful_mode = false,
    property_expression_names = {},
    starting_area = 1,
    starting_points = {
      {
        x = 0,
        y = 0
      }
    },
    terrain_segmentation = 1,
    water = 0,

  }

local function migrate_inventory(source, destination)
  for item_name, item_count in pairs(source.get_inventory[1]) do
    destination.insert{name = item_name, count = item_count}
  end
end

local function generate_lab_tile_surface(player, surface_name)
  if game.surfaces[surface_name] then
    debug_print('Edit surface found.')
    edit_surface = game.surfaces[surface_name]
  else
    debug_print('Edit surface not found, creating...')
    edit_surface = game.create_surface(surface_name, map_settings)
    
    edit_surface.request_to_generate_chunks( {0,0} , 8)
    edit_surface.force_generate_chunk_requests()
    player.force.chart_all()
    
    -- local old_tiles = edit_surface.find_tiles_filtered({})
    -- local new_tiles = {}
    -- for _, t in pairs(old_tiles) do
    --   local coord_test = (t.position.x + t.position.y)%2
    --   local tile_name = 'lab-white'
    --   if (coord_test==0) then
    --     tile_name = 'lab-dark-1'
    --   else
    --     tile_name = 'lab-dark-2'
    --   end  
    --   table.insert(new_tiles, {name = tile_name, position=t.position})
    -- end
    -- edit_surface.set_tiles(new_tiles)
    -- debug_print('Generated lab tiles.')
    
    edit_surface.destroy_decoratives({invert=true})
    debug_print('Destroyed decoratives.')
  end

  return edit_surface
end

local function enter_blueprint_editing(player)
  if player.cursor_stack.valid_for_read then
    if player.cursor_stack.name == 'blueprint' then
      if player.cursor_stack.is_blueprint_setup() == true then
        create_bp_editor_popup(player)
        visibility_bp_editor_popup(player, true)
        visibility_bp_editor_button(player, false)

        blueprint_editor_original_label = player.cursor_stack.label
        blueprint_editor_original_blueprint_icons = player.cursor_stack.blueprint_icons
        local original_blueprint_string = player.cursor_stack.export_stack()
      
        --bp_editor_surface = generate_lab_tile_surface(player, 'bp-editor-surface')

        local entity_list = edit_surface.find_entities()
        for _, ent in pairs(entity_list) do
          ent.destroy()
        end
        debug_print('Destroyed entities.')
        
        if player.controller_type ~= 4 then
          player.toggle_map_editor()
        end
        player.teleport({0,0}, e_name)

        player.cursor_stack.import_stack(original_blueprint_string)

        ghosts = player.cursor_stack.build_blueprint{surface = e_name, position = {0,0}, force = 'player' }
        player.cursor_stack.clear()
        debug_print('Built blueprint.')

        ghost_trains = {}
        for _,ghost in pairs(ghosts) do
          if ghost.ghost_name == 'locomotive' or ghost.ghost_name == 'cargo-wagon' or ghost.ghost_name == 'fluid-wagon' or ghost.ghost_name == 'artillery-wagon' then
            table.insert(ghost_trains, ghost)
          else
            debug_print(ghost.ghost_name)
            ghost.silent_revive()
          end
        end
        debug_print('Revived ghosts.')

        for _,ghost in pairs(ghost_trains) do
          debug_print(ghost.ghost_name)
          ghost.silent_revive()
        end
        debug_print('Revived train ghosts.')
    
      else
        game.print('Blueprint in cursor is empty.')
      end
    else
      game.print('Item in cursor is not a blueprint.')
    end
  else
    game.print('No blueprint in cursor.')
  end
end

local function finish_blueprint_editing(player, blueprint_editor_original_position)
  player.cursor_stack.set_stack('blueprint')
  local result_blueprint_string  = ''
  if game.surfaces['bp-editor-surface'] then
    player.cursor_stack.create_blueprint({
      surface = 'bp-editor-surface',
      force = 'player',
      area = {{-32*8, -32*8},{32*8,32*8}},
      always_include_tiles = true,
      include_entities = true,
      include_modules = true,
      include_trains = true,
      include_station_names = true
    })
    result_blueprint_string = player.cursor_stack.export_stack()
    player.cursor_stack.label = blueprint_editor_original_label
    player.cursor_stack.blueprint_icons = blueprint_editor_original_blueprint_icons
  else
    game.print('Blueprint editor surface not found.')
  end
  player.teleport(blueprint_editor_original_position, 'nauvis')
  if player.controller_type == 4 then
    player.toggle_map_editor()
  end
  --player.cursor_stack.set_stack('blueprint')
  player.cursor_stack.import_stack(result_blueprint_string)
  visibility_bp_editor_popup(player, false)
  visibility_bp_editor_button(player, true)
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
    game.print('destroyed blueprint-edit-button')
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
  mod_gui.get_button_flow(player).add
  {
    type = "sprite-button",
    name = "blueprint-edit-button",
    sprite = "blueprint-editor-button-1",
    style = mod_gui.button_style
  }
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
    direction = 'vertical',
    caption = 'Blueprint editor'
  })
  frame.style.vertically_stretchable = false
  frame.ignored_by_interaction = false
  frame.style.use_header_filler = true
  
  local button_exit = frame.add
  {
    type = "sprite-button",
    name = "blueprint-edit-button-exit",
    sprite = "blueprint-editor-button-1",
    style = mod_gui.button_style
  }

  return frame
end






script.on_event(defines.events.on_player_created ,
  function(event)
    local player = game.get_player(event.player_index)
    create_top_button(player)
    generate_lab_tile_surface(player, 'bp-editor-surface')
  end
)

script.on_event(defines.events.on_gui_click ,
  function(event)
    blueprint_editor_original_position = {0,0}
    if event.element.name == "blueprint-edit-button" then
      local player = game.get_player(event.player_index)
      blueprint_editor_original_position = player.position
      enter_blueprint_editing(player)
    end

    if event.element.name == "blueprint-edit-button-exit" then
      local player = game.get_player(event.player_index)
      finish_blueprint_editing(player, blueprint_editor_original_position)
    end
  end
)
