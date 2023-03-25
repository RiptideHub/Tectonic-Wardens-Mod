BattleHandlers::AbilityChangeOnBattlerFainting.add(:POWEROFALCHEMY,
    proc { |ability, battler, fainted, battle|
        next if battler.opposes?(fainted)
        next if fainted.ungainableAbility? ||
           %i[POWEROFALCHEMY RECEIVER TRACE WONDERGUARD].include?(fainted.ability_id)
        battle.pbShowAbilitySplash(battler, ability, true)
        stolenAbility = fainted.baseAbility
        battler.ability = stolenAbility
        battle.pbReplaceAbilitySplash(battler)
        battle.pbDisplay(_INTL("{1}'s {2} was taken over!", fainted.pbThis, abilityName(stolenAbility)))
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::AbilityChangeOnBattlerFainting.copy(:POWEROFALCHEMY, :RECEIVER)
