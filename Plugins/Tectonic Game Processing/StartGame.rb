# The Game module contains methods for saving and loading the game.
module Game
    # Initializes various global variables and loads the game data.
    def self.initialize
      $PokemonTemp        = PokemonTemp.new
      $game_temp          = Game_Temp.new
      $game_system        = Game_System.new
      $data_animations    = load_data('Data/Animations.rxdata')
      $data_tilesets      = load_data('Data/Tilesets.rxdata')
      $data_common_events = load_data('Data/CommonEvents.rxdata')
      $data_system        = load_data('Data/System.rxdata')
      pbLoadBattleAnimations
      GameData.load_all
      map_file = format('Data/Map%03d.rxdata', $data_system.start_map_id)
      if $data_system.start_map_id == 0 || !pbRgssExists?(map_file)
        raise _INTL('No starting position was set in the map editor.')
      end
    end
  
    # Loads bootup data from save file (if it exists) or creates bootup data (if
    # it doesn't).
    def self.set_up_system
      SaveData.changeFILEPATH($storenamefilesave.nil? ? FileSave.name : $storenamefilesave)
      SaveData.move_old_windows_save if System.platform[/Windows/]
      save_data = (SaveData.exists?) ? SaveData.read_from_file(SaveData::FILE_PATH) : {}
      if save_data.empty?
        SaveData.initialize_bootup_values
      else
        SaveData.load_bootup_values(save_data)
      end
      # Set resize factor
      pbSetResizeFactor(1)
      # Set language (and choose language if there is no save file)
      if Settings::LANGUAGES.length >= 2 && $DEBUG
        $PokemonSystem.language = pbChooseLanguage if save_data.empty?
        pbLoadMessages('Data/' + Settings::LANGUAGES[$PokemonSystem.language][1])
      end
    end
  
    # Called when starting a new game. Initializes global variables
    # and transfers the player into the map scene.
    def self.start_new
      mainMenuLanguage = $PokemonSystem.language
      if $game_map && $game_map.events
        $game_map.events.each_value { |event| event.clear_starting }
      end
      $game_temp.common_event_id = 0 if $game_temp
      $PokemonTemp.begunNewGame = true
      $scene = Scene_Map.new
      SaveData.load_new_game_values
      $PokemonSystem.language = mainMenuLanguage
      $MapFactory = PokemonMapFactory.new($data_system.start_map_id)
      $game_player.moveto($data_system.start_x, $data_system.start_y)
      $game_player.refresh
      $PokemonEncounters = PokemonEncounters.new
      $PokemonEncounters.setup($game_map.map_id)
      $game_map.autoplay
      $game_map.update
    end
  
    # Loads the game from the given save data and starts the map scene.
    # @param save_data [Hash] hash containing the save data
    # @raise [SaveData::InvalidValueError] if an invalid value is being loaded
    def self.load(save_data)
      validate save_data => Hash
      removeIllegalElementsFromAllPokemon(save_data)
      SaveData.load_all_values(save_data)
      self.load_map
      pbAutoplayOnSave
      $game_map.update
      $PokemonMap.updateMap
      $scene = Scene_Map.new
      $PokemonTemp.dependentEvents.refresh_sprite(false)
      pbSetResizeFactor($PokemonSystem.screensize)
      $PokemonSystem.setSystemFrame
      $PokemonSystem.setSpeechFrame
      removeSpeaker
    end
  
    # Loads and validates the map. Called when loading a saved game.
    def self.load_map
      $game_map = $MapFactory.map
      magic_number_matches = ($game_system.magic_number == $data_system.magic_number)
      if !magic_number_matches || $PokemonGlobal.safesave
        if pbMapInterpreterRunning?
          pbMapInterpreter.setup(nil, 0)
        end
        begin
          $MapFactory.setup($game_map.map_id)
        rescue Errno::ENOENT
          if $DEBUG
            pbMessage(_INTL('Map {1} was not found.', $game_map.map_id))
            map = pbWarpToMap
            exit unless map
            $MapFactory.setup(map[0])
            $game_player.moveto(map[1], map[2])
          else
            raise _INTL('The map was not found. The game cannot continue.')
          end
        end
        $game_player.center($game_player.x, $game_player.y)
      else
        $MapFactory.setMapChanged($game_map.map_id)
      end
      if $game_map.events.nil?
        raise _INTL('The map is corrupt. The game cannot continue.')
      end
      $PokemonEncounters = PokemonEncounters.new
      $PokemonEncounters.setup($game_map.map_id)
      pbUpdateVehicle
    end
  
    # Saves the game. Returns whether the operation was successful.
    # @param save_file [String] the save file path
    # @param safe [Boolean] whether $PokemonGlobal.safesave should be set to true
    # @return [Boolean] whether the operation was successful
    # @raise [SaveData::InvalidValueError] if an invalid value is being saved
    def self.save(save_file = SaveData::FILE_PATH, safe: false)
      validate save_file => String, safe => [TrueClass, FalseClass]
      $PokemonGlobal.safesave = safe
      $game_system.save_count += 1
      $game_system.magic_number = $data_system.magic_number
      begin
        SaveData.save_to_file(save_file)
        Graphics.frame_reset
      rescue IOError, SystemCallError
        $game_system.save_count -= 1
        return false
      end
      return true
    end
end


def removeIllegalElementsFromAllPokemon(save_data)
  eachPokemonInSave(save_data) do |pokemon, location|
    echoln("#{pokemon.name} learnable moves: #{pokemon.learnable_moves(false).to_s}")
    echoln("#{pokemon.name} legal abilities: #{pokemon.species_data.legalAbilities.to_s}")

    # Find and remove illegal moves
    pokemon.moves.each do |move|
      next if move.nil?
      moveID = move.id
      
      remove = false

      moveData = GameData::Move.get(moveID)
      if !moveData.learnable? && !(pokemon.species == :SMEARGLE && moveData.primeval)
        pbMessage(_INTL("Pokemon #{pokemon.name} in #{location} has move #{moveData.name} in its move list."))
        pbMessage(_INTL("That move has been cut from the game or is not legal to learn. Removing now."))
        remove = true
      end

      unless pokemon.learnable_moves(false).include?(moveID)
        pbMessage(_INTL("Pokemon #{pokemon.name} in #{location} has move #{moveData.name} in its move list."))
        pbMessage(_INTL("That move is not legal for its species. Removing now."))
        remove = true
      end

      if remove
        pokemon.forget_move(moveID)
        pokemon.remove_first_move(moveID)
      end
    end

    # Find and fix illegal abilities
    unless pokemon.species_data.legalAbilities.include?(pokemon.ability_id)
      pbMessage(_INTL("Pokemon #{pokemon.name} in #{location} has ability #{pokemon.ability.name}."))
      pokemon.recalculateAbilityFromIndex
      pbMessage(_INTL("That ability is not legal for its species. Switching to #{pokemon.ability.name}."))
    end

    # Check and remove illegal items
    pokemon.items.clone.each do |item|
      itemData = GameData::Item.get(item)
      next if itemData.legal?
      pbMessage(_INTL("Pokemon #{pokemon.name} in #{location} has item #{itemData.name}."))
      pbMessage(_INTL("That item has been cut from the game or is not legal to own. Removing now."))
      pokemon.removeItem(item)
    end
  end
rescue StandardError
  pbMessage(_INTL("An error occured while checking for the legality of your party."))
  pbPrintException($!)
end