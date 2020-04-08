/c
game.player.cursor_stack.set_stack('blueprint')
game.player.cursor_stack.create_blueprint({
  surface = 'edit',
  force = 'player',
  area = {{-32*8, -32*8},{32*8,32*8}},
  always_include_tiles = true,
  include_entities = true,
  include_modules = true,
  include_trains = true,
  include_station_names = true
})
game.player.teleport(blueprint_editor_original_position, 'nauvis')