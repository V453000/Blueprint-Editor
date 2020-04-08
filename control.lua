function debug_print(text)
  game.print(text)
end

local e_name = 'edit'


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


local player = game.player or game.get_player(event and event.player_index or 1)

local function enter_blueprint_editing()
  if player.cursor_stack.valid_for_read then
    if player.cursor_stack.is_blueprint_setup() == true then

      local original_position = player.position
      local original_surface = player.surface
      local original_blueprint_string = player.cursor_stack.export_stack()

      if game.surfaces[e_name] then
        debug_print('Edit surface found.')
        edit_surface = game.surfaces[e_name]
      else
        debug_print('Edit surface not found, creating...')
        edit_surface = game.create_surface(e_name, map_settings)
        
        edit_surface.request_to_generate_chunks( {0,0} , 8)
        edit_surface.force_generate_chunk_requests()
        player.force.chart_all()

        local old_tiles = edit_surface.find_tiles_filtered({})
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
        
        edit_surface.destroy_decoratives({invert=true})
        debug_print('Destroyed decoratives.')
      end


      local entity_list = edit_surface.find_entities()
      for _, ent in pairs(entity_list) do
        ent.destroy()
      end
      debug_print('Destroyed entities.')

      player.teleport({0,0}, e_name)

      player.cursor_stack.import_stack(original_blueprint_string)

      ghosts = player.cursor_stack.build_blueprint{surface = e_name, position = {0,0}, force = 'player' }
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
    game.print('No blueprint in cursor.')
  end
end

local function finish_blueprint_editing()
  player.cursor_stack.set_stack('blueprint')
  player.cursor_stack.create_blueprint({
    surface = 'edit',
    force = 'player',
    area = {{-32*8, -32*8},{32*8,32*8}},
    always_include_tiles = true,
    include_entities = true,
    include_modules = true,
    include_trains = true,
    include_station_names = true
  })
player.teleport(original_position, original_surface)
end

enter_blueprint_editing()