# All HP based effects will deal less damage the higher this is
BOSS_HP_BASED_EFFECT_RESISTANCE = 4

def pbBigAvatarBattle(*args)
	rule = "3v#{args.length}"
	setBattleRule(rule)
	pbAvatarBattleCore(*args)
end

def pbSmallAvatarBattle(*args)
	rule = "2v#{args.length}"
	setBattleRule(rule)
	pbAvatarBattleCore(*args)
end

def pbAvatarBattleCore(*args)
  outcomeVar = $PokemonTemp.battleRules["outcomeVar"] || 1
  canLose    = $PokemonTemp.battleRules["canLose"] || false
  # Skip battle if the player has no able Pokémon, or if holding Ctrl in Debug mode
  if $Trainer.able_pokemon_count == 0 || ($DEBUG && Input.press?(Input::CTRL))
    pbMessage(_INTL("SKIPPING BATTLE...")) if $Trainer.pokemon_count > 0
    pbSet(outcomeVar,1)   # Treat it as a win
    $PokemonTemp.clearBattleRules
    $PokemonGlobal.nextBattleBGM       = nil
    $PokemonGlobal.nextBattleME        = nil
    $PokemonGlobal.nextBattleCaptureME = nil
    $PokemonGlobal.nextBattleBack      = nil
    pbMEStop
    return 1   # Treat it as a win
  end
  # Record information about party Pokémon to be used at the end of battle (e.g.
  # comparing levels for an evolution check)
  Events.onStartBattle.trigger(nil)
  # Generate wild Pokémon based on the species and level
  foeParty = []
  
  respawnFollower = false
  for arg in args
    if arg.is_a?(Array)
		for i in 0...arg.length/2
			speciesData = GameData::Species.get(arg[i*2])
			pkmn = pbGenerateWildPokemon(speciesData.species,arg[i*2+1])
			pkmn.forced_form = speciesData.form
			pkmn.boss = true
			pkmn.name += " " + speciesData.real_form_name if speciesData.form != 0
			setAvatarProperties(pkmn)
			foeParty.push(pkmn)
		end
	end
  end
  # Calculate who the trainers and their party are
  playerTrainers    = [$Trainer]
  playerParty       = $Trainer.party
  playerPartyStarts = [0]
  room_for_partner = (foeParty.length > 1)
  if !room_for_partner && $PokemonTemp.battleRules["size"] &&
     !["single", "1v1", "1v2", "1v3"].include?($PokemonTemp.battleRules["size"])
    room_for_partner = true
  end
  if $PokemonGlobal.partner && !$PokemonTemp.battleRules["noPartner"] && room_for_partner
    ally = NPCTrainer.new($PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
    ally.id    = $PokemonGlobal.partner[2]
    ally.party = $PokemonGlobal.partner[3]
    playerTrainers.push(ally)
    playerParty = []
    $Trainer.party.each { |pkmn| playerParty.push(pkmn) }
    playerPartyStarts.push(playerParty.length)
    ally.party.each { |pkmn| playerParty.push(pkmn) }
    setBattleRule("double") if !$PokemonTemp.battleRules["size"]
  end
  # Create the battle scene (the visual side of it)
  scene = pbNewBattleScene
  # Create the battle class (the mechanics side of it)
  battle = PokeBattle_Battle.new(scene,playerParty,foeParty,playerTrainers,nil)
  battle.party1starts = playerPartyStarts
  battle.bossBattle = true
  # Set various other properties in the battle class
  pbPrepareBattle(battle)
  $PokemonTemp.clearBattleRules
  # Perform the battle itself
  decision = 0
  pbBattleAnimation(pbGetAvatarBattleBGM(foeParty),(foeParty.length==1) ? 0 : 2,foeParty) {
    pbSceneStandby {
      decision = battle.pbStartBattle
    }
	pbPokemonFollow(1) if decision != 1 && $game_switches[59] # In cave with Yezera
    pbAfterBattle(decision,canLose)
  }
  Input.update
  # Save the result of the battle in a Game Variable (1 by default)
  #    0 - Undecided or aborted
  #    1 - Player won
  #    2 - Player lost
  #    3 - Player or wild Pokémon ran from battle, or player forfeited the match
  #    4 - Wild Pokémon was caught
  #    5 - Draw
  pbSet(outcomeVar,decision)
  return (decision==1)
end

def setAvatarProperties(pkmn)
	avatar_data = nil
	if pkmn.form != 0
		speciesFormSymbol = (pkmn.species.to_s + "_" + pkmn.form.to_s).to_sym
		avatar_data = GameData::Avatar.try_get(speciesFormSymbol)
	end
	if avatar_data.nil?
		avatar_data = GameData::Avatar.get(pkmn.species.to_sym)
	end

	pkmn.forced_form = avatar_data.form if avatar_data.form != 0

	pkmn.forget_all_moves()
	avatar_data.moves1.each do |move|
		pkmn.learn_move(move)
	end
	
	pkmn.item = avatar_data.item
	pkmn.ability = avatar_data.ability
	pkmn.hpMult = avatar_data.hp_mult
	pkmn.dmgMult = avatar_data.dmg_mult
	pkmn.dmgResist = avatar_data.dmg_resist
	pkmn.extraMovesPerTurn = avatar_data.num_turns - 1
	
	pkmn.calc_stats()
end


def calcHPMult(pkmn)
	hpMult = 1
	if pkmn.boss
		avatar_data = GameData::Avatar.get(pkmn.species.to_sym)
		hpMult = avatar_data.hp_mult
	end
	return hpMult
end
		

def pbPlayCrySpecies(species, form = 0, volume = 90, pitch = nil)
  GameData::Species.play_cry_from_species(species, form, volume, pitch)
end

class Pokemon
	attr_accessor :boss
	
	# @return [0, 1, 2] this Pokémon's gender (0 = male, 1 = female, 2 = genderless)
	  def gender
		return 2 if boss?
		if !@gender
		  gender_ratio = species_data.gender_ratio
		  case gender_ratio
		  when :AlwaysMale   then @gender = 0
		  when :AlwaysFemale then @gender = 1
		  when :Genderless   then @gender = 2
		  else
			female_chance = GameData::GenderRatio.get(gender_ratio).female_chance
			@gender = ((@personalID & 0xFF) < female_chance) ? 1 : 0
		  end
		end
		return @gender
	  end
	  
	def boss?
		return boss
	end
end

def pbPlayerPartyMaxLevel(countFainted = false)
  maxPlayerLevel = -100
  $Trainer.party.each do |pkmn|
    maxPlayerLevel = pkmn.level if pkmn.level > maxPlayerLevel && (!pkmn.fainted? || countFainted)
  end
  return maxPlayerLevel
end

def pbGetAvatarBattleBGM(_wildParty)   # wildParty is an array of Pokémon objects
	if $PokemonGlobal.nextBattleBGM
		return $PokemonGlobal.nextBattleBGM.clone
	end
	ret = nil

	legend = false
	_wildParty.each do |p|
		legend = true if isLegendary?(p.species)
	end

	# Check global metadata
	music = legend ? GameData::Metadata.get.legendary_avatar_battle_BGM : GameData::Metadata.get.avatar_battle_BGM
	ret = pbStringToAudioFile(music) if music && music!=""
	ret = pbStringToAudioFile("Battle wild") if !ret
	return ret
end

def createBossGraphics(species_internal_name,overworldMult=1.5,battleMult=1.5)
	# Create the overworld sprite
	begin
		overworldBitmap = AnimatedBitmap.new('Graphics/Characters/Followers/' + species_internal_name)
		copiedOverworldBitmap = overworldBitmap.copy
		bossifiedOverworld = bossify(copiedOverworldBitmap.bitmap,overworldMult)
		bossifiedOverworld.to_file('Graphics/Characters/zAvatar_' + species_internal_name + '.png')
	rescue Exception
		e = $!
		pbPrintException(e)
	end
	
	# Create the front in battle sprite
	begin
		battlebitmap = AnimatedBitmap.new('Graphics/Pokemon/Front/' + species_internal_name)
		copiedBattleBitmap = battlebitmap.copy
		bossifiedBattle = bossify(copiedBattleBitmap.bitmap,battleMult)
		bossifiedBattle.to_file('Graphics/Pokemon/Avatars/' + species_internal_name + '.png')
	rescue Exception
		e = $!
		pbPrintException(e)
	end
	
	# Create the back in battle sprite
	begin
		battlebitmap = AnimatedBitmap.new('Graphics/Pokemon/Back/' + species_internal_name)
		copiedBattleBitmap = battlebitmap.copy
		bossifiedBattle = bossify(copiedBattleBitmap.bitmap,battleMult)
		bossifiedBattle.to_file('Graphics/Pokemon/Avatars/' + species_internal_name + '_back.png')
	rescue Exception
		e = $!
		pbPrintException(e)
	end
end
 
def bossify(bitmap,scaleFactor,verticalOffset = 0)
  copiedBitmap = Bitmap.new(bitmap.width*scaleFactor,bitmap.height*scaleFactor)
  for x in 0..copiedBitmap.width
	for y in 0..copiedBitmap.height
	  color = bitmap.get_pixel(x/scaleFactor,y/scaleFactor + verticalOffset)
	  color.alpha   = [color.alpha,140].min
	  color.red     = [color.red + 50,255].min
	  color.blue    = [color.blue + 50,255].min
	  copiedBitmap.set_pixel(x,y,color)
	end
  end
  return copiedBitmap
end


class PokeBattle_Battle
	SUMMON_MIN_HEALTH_LEVEL = 15
	SUMMON_MAX_HEALTH_LEVEL = 50

	def addAvatarBattler(species,level,sideIndex=1)
		return if @autoTesting

		indexOnSide = @sideSizes[sideIndex]
		if indexOnSide > 3
			echoln("Cannot create new avatar battler on side #{sideIndex} since the side is already full!")
			return false
		end

		# Create the new pokemon
		newPokemon = pbGenerateWildPokemon(species,level)
		newPokemon.boss = true
		setAvatarProperties(newPokemon)

		# Put the pokemon into the party
		partyIndex = pbParty(sideIndex).length
		pbParty(sideIndex)[partyIndex] = newPokemon

		# Put the battler into the battle
		battlerIndexNew = indexOnSide * 2 + sideIndex
		if @battlers[battlerIndexNew].nil?
			pbCreateBattler(battlerIndexNew,newPokemon,sideIndex)
		else
			@battlers[battlerIndexNew].pbInitialize(newPokemon,partyIndex)
		end
		newBattler = @battlers[battlerIndexNew]
		sideSizes[sideIndex] += 1

		# Put the pokemon's party index into the party order tracker
		partyOrder = [@party1order,@party2order]
		partyOrder.insert(indexOnSide,partyIndex)

		# Create any missing battler slots
		0.upto(battlerIndexNew) do |idxBattler|
			next unless @battlers[idxBattler].nil?
			pbCreateBattler(idxBattler)
			scene.pbCreatePokemonSprite(idxBattler)
		end

		# Set the battler's starting health
		if level >= SUMMON_MAX_HEALTH_LEVEL
			healthPercent = 1.0
		elsif level <= SUMMON_MIN_HEALTH_LEVEL
			healthPercent = 0.5
		else
			healthPercent = 0.5 + (level - SUMMON_MIN_HEALTH_LEVEL) / (SUMMON_MAX_HEALTH_LEVEL - SUMMON_MIN_HEALTH_LEVEL).to_f
			healthPercent = 1.0 if healthPercent > 1.0
		end
		newBattler.hp = (newBattler.totalhp * healthPercent).ceil

		# Remake all the battle boxes
		scene.sprites["dataBox_#{battlerIndexNew}"] = PokemonDataBox.new(newBattler,@sideSizes[sideIndex],@scene.viewport)
		eachBattler do |b|
			next unless b.index % 2 == sideIndex
			databox = scene.sprites["dataBox_#{b.index}"]
			databox.dispose
			databox.initialize(b,@sideSizes[sideIndex],@scene.viewport)
			databox.visible = true
		end

		# Create a dummy sprite for the avatar
		scene.pbCreatePokemonSprite(battlerIndexNew)
		
		# Recreate all the battle sprites
		eachBattler do |b|
			next unless b.index % 2 == sideIndex
			battleSprite = scene.sprites["pokemon_#{b.index}"]
			battleSprite.dispose
			battleSprite.initialize(@scene.viewport,@sideSizes[sideIndex],b.index,@scene.animations)
			scene.pbChangePokemon(b.index,b.pokemon)
			battleSprite.visible = true
		end

		# Set the new avatars tone to be appropriate for entering the field
		pkmnSprite = @scene.sprites["pokemon_#{battlerIndexNew}"]
		pkmnSprite.tone    = Tone.new(-80,-80,-80)

		# Remake the targeting menu
		@scene.sprites["targetWindow"] = TargetMenuDisplay.new(@scene.viewport,200,@sideSizes)
		@scene.sprites["targetWindow"].visible = false

		# Send it out into the battle
		@scene.animateIntroNewAvatar(battlerIndexNew)
		pbOnActiveOne(newBattler)
		pbCalculatePriority

		return true
	end
end

class PokeBattle_Scene
	attr_reader :animations
	def animateIntroNewAvatar(battlerIndexNew)
		# Animation of new pokemon appearing
		dataBoxAnim = DataBoxAppearAnimation.new(@sprites,@viewport,battlerIndexNew)
		@animations.push(dataBoxAnim)
		# Set up wild Pokémon returning to normal colour and playing intro
		# animations (including cry)
		@animations.push(BattleIntroAnimationSolo.new(@sprites,@viewport,battlerIndexNew))
		# Play all the animations
		while inPartyAnimation?; pbUpdate; end
	end
end

#===============================================================================
# Shows a single wild Pokémon fading back to its normal color, and triggers their intro
# animation
#===============================================================================
class BattleIntroAnimationSolo < PokeBattle_Animation
	def initialize(sprites,viewport,idxBattler)
	  @idxBattler = idxBattler
	  super(sprites,viewport)
	end
  
	def createProcesses
		battler = addSprite(@sprites["pokemon_#{@idxBattler}"],PictureOrigin::Bottom)
		battler.moveTone(0,4,Tone.new(0,0,0,0))
		battler.setCallback(0,[@sprites["pokemon_#{@idxBattler}"],:pbPlayIntroAnimation])
	end
end

class PokeBattle_Battler
	attr_accessor :choicesTaken
	attr_accessor :lastMoveChosen

	def assignMoveset(moves)
		@moves = []
		@pokemon.moves = []
		moves.each do |m|
			pokeMove = Pokemon::Move.new(m)
			moveObject = PokeBattle_Move.from_pokemon_move(@battle,pokeMove)
			@moves.push(moveObject)
			@pokemon.moves.push(pokeMove)
		end
		@lastMoveChosen = nil
	end

	def pbChangeFormBoss(formID,formChangeMessage)
		@pokemon.forced_form = formID
		pbChangeForm(formID, formChangeMessage)
	end
end