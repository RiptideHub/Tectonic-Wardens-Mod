#===============================================================================
# At the end of the turn, uses Clash if the user has a substitue active (Necromancy, Tinkatink line signature)
#===============================================================================

BattleHandlers::EOREffectAbility.add(:NECROMANCY,
  proc { |ability, battler, battle|
        next unless battler.effectActive?(:Substitute)
        battle.pbShowAbilitySplash(battler, ability)
        battle.forceUseMove(battler, :CLASH)
        battle.pbHideAbilitySplash(battler)
    }
)
 
#===============================================================================
# Boosts Light-type moves of everyone in the field (Light Aura)
#===============================================================================

class PokeBattle_Move
  def pbCalcAbilityDamageMultipliers(user,target,type,baseDmg,multipliers,aiCheck=false)
    # Global Ability
    if (@battle.pbCheckGlobalAbility(:DARKAURA) && type == :DARK) ||
      (@battle.pbCheckGlobalAbility(:FAIRYAURA) && type == :FAIRY) ||
      (@battle.pbCheckGlobalAbility(:LIGHTAURA) && type == :LIGHT)
      if @battle.pbCheckGlobalAbility(:AURABREAK)
          multipliers[:base_damage_multiplier] *= 2 / 3.0
      else
          multipliers[:base_damage_multiplier] *= 4 / 3.0
      end
  end
end
end 

BattleHandlers::AbilityOnSwitchIn.add(:LIGHTAURA,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is radiating a luminous aura!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)