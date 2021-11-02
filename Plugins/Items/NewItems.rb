BattleHandlers::ItemOnStatLoss.add(:EJECTPACK,
  proc { |item,battler,user,move,switched,battle|
    next if battle.pbAllFainted?(battler.idxOpposingSide)
    next if !battle.pbCanChooseNonActive?(battler.index)
	next if move.function=="0EE" # U-Turn, Volt-Switch, Flip Turn
	next if move.function=="151" # Parting Shot
    battle.pbCommonAnimation("UseItem",battler)
    battle.pbDisplay(_INTL("{1} is switched out with the {2}!",battler.pbThis,battler.itemName))
    battler.pbConsumeItem(true,false)
    newPkmn = battle.pbGetReplacementPokemonIndex(battler.index)   # Owner chooses
    next if newPkmn<0
    battle.pbRecallAndReplace(battler.index,newPkmn)
    battle.pbClearChoice(battler.index)   # Replacement Pokémon does nothing this round
    switched.push(battler.index)
  }
)

#######################
# ABRAPORTER
#######################
ItemHandlers::UseFromBag.add(:ABRAPORTER,proc { |item|
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you."))
    next 0
  end
  if !GameData::MapMetadata.exists?($game_map.map_id)
    pbMessage(_INTL("Can't use that here."))
    next 0
  end
  healing = $PokemonGlobal.healingSpot
  healing = GameData::Metadata.get.home if !healing   # Home
  if !healing
    pbMessage(_INTL("Can't use that here."))
    next 0
  end
  next 2
})

ItemHandlers::ConfirmUseInField.add(:ABRAPORTER,proc { |item|
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you."))
    next false
  end
  if !GameData::MapMetadata.exists?($game_map.map_id)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  healing = $PokemonGlobal.healingSpot
  healing = GameData::Metadata.get.home if !healing   # Home
  if !healing
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  
  mapname = pbGetMapNameFromId(healing[0])
  next pbConfirmMessage(_INTL("Want to teleport from here and return to {1}?",mapname))
})

ItemHandlers::UseInField.add(:ABRAPORTER,proc { |item|
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you."))
    next 0
  end
  if !GameData::MapMetadata.exists?($game_map.map_id)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next 0
  end
  healing = $PokemonGlobal.healingSpot
  healing = GameData::Metadata.get.home if !healing   # Home
  if !healing
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next 0
  end
  pbUseItemMessage(item)
  pbFadeOutIn {
    $game_temp.player_new_map_id    = healing[0]
    $game_temp.player_new_x         = healing[1]
    $game_temp.player_new_y         = healing[2]
    $game_temp.player_new_direction = 2
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  next 1
})


BattleHandlers::EOREffectItem.add(:POISONORB,
  proc { |item,battler,battle|
    next if !battler.pbCanPoison?(nil,false)
    battler.pbPoison(nil,_INTL("{1} was poisoned by the {2}!",
       battler.pbThis,battler.itemName),false)
  }
)

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,250,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,1000,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,4000,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,12000,item,scene)
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL,proc { |item,pkmn,scene|
  pbEXPAdditionItem(pkmn,50000,item,scene)
})

##################
# EXP Jar
##################

ItemHandlers::UseFromBag.add(:EXPJAR,proc { |item|
	$PokemonGlobal.expJAR = 0 if $PokemonGlobal.expJAR.nil?
	candyTotal = 0
	pbMessage(_INTL("You have {1} Battle Extract stored in the EXP Jar.",$PokemonGlobal.expJAR))
	candyTotal = $PokemonGlobal.expJAR / 300
	if candyTotal > 0
		if pbConfirmMessage(_INTL("You can make {1} candies. Would you like to?", candyTotal))
			pbReceiveItem(:EXPCANDYXS,candyTotal)
			$PokemonGlobal.expJAR = $PokemonGlobal.expJAR%300
		end
	end
	next 1
	})