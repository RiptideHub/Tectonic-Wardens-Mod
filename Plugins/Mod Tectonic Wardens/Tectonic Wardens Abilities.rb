#===============================================================================
# Necromancy, Tinkatink's line signature
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
# Light Aura
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

#===============================================================================
# -ate esque abilities
#===============================================================================

BattleHandlers::MoveBaseTypeModifierAbility.add(:BLACKLIGHT,
  proc { |ability, _user, move, type|
      next if type != :LIGHT || !GameData::Type.exists?(:DARK)
      move.powerBoost = true
      next :DARK
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:WHITEOUT,
  proc { |ability, _user, move, type|
      next if type != :DARK || !GameData::Type.exists?(:LIGHT)
      move.powerBoost = true
      next :LIGHT
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:DARKMATTER,
  proc { |ability, _user, move, type|
      next if type != :NORMAL || !GameData::Type.exists?(:COSMIC)
      move.powerBoost = true
      next :COSMIC
  }
)

#===============================================================================
# Resistance and immunity abilities
#===============================================================================

BattleHandlers::DamageCalcTargetAbility.add(:REALISM,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[GHOST FAIRY].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:ASTRALMAJESTY,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[LIGHT DRAGON].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TROPICALHIDE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[GRASS WATER].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:IRREDEEMABLE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[LIGHT FAIRU].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PACKEDSNOW,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
  if user.battle.snowy?
    if Effectiveness.super_effective?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 0.5
      target.aiLearnsAbility(ability) unless aiCheck
    end
  end   
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:OPAQUENESS,
  proc { |ability, user, target, _move, type, battle, showMessages, aiCheck|
      next false if user.index == target.index
      next false if type != :LIGHT
      if showMessages
          battle.pbShowAbilitySplash(target, ability)
          battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
          battle.pbHideAbilitySplash(target)
      end
      next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:EARTHEATER,
  proc { |ability, user, target, move, type, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityHealAbility(ability, user, target, move, type, :GROUND, battle, showMessages, aiCheck)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:COMETSTORM,
  proc { |ability, user, target, move, type, battle, showMessages, aiCheck|
      next pbBattleMoveImmunityStatAbility(ability, user, target, move, type, :ROCK, :SPEED, 1, :SPECIAL_ATTACK, 1, battle, showMessages, aiCheck)
  }
)

#===============================================================================
# Damage-boosting abilities
#===============================================================================

BattleHandlers::DamageCalcUserAbility.add(:ICYVEINS,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.icy? && type == :ICE||:WATER
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ARSONIST,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FIRE
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:BONECOLLECTOR,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :GROUND
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ROCKYPAYLOAD,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ROCK
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:REQUIEM,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :DARK
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:AFFECTION,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FAIRY
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:POSSESED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :GHOST
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:HIVEMIND,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :BUG
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

#===============================================================================
# Winter Gift (Cherrim signature)
#===============================================================================

BattleHandlers::AttackCalcAllyAbility.add(:WINTERGIFT,
    proc { |ability, _user, battle, attackMult|
        attackMult *= 1.5 if battle.sunny?
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:WINTERGIFT,
    proc { |ability, user, _battle, attackMult|
        attackMult *= 1.5 if user.battle.sunny?
        next attackMult
    }
)

BattleHandlers::SpecialDefenseCalcAllyAbility.add(:WINTERGIFT,
    proc { |ability, _user, battle, spDefMult|
        spDefMult *= 1.5 if battle.sunny?
        next spDefMult
    }
)

BattleHandlers::SpecialDefenseCalcUserAbility.add(:WINTERGIFT,
    proc { |ability, _user, battle, spDefMult|
        spDefMult *= 1.5 if battle.sunny?
        next spDefMult
    }
)

def pbCheckFormOnWeatherChange(abilityLossCheck = false)
  return if fainted? || effectActive?(:Transform)
  if isSpecies?(:OCHERRIM)
      if hasActiveAbility?(:WINTERGIFT)
          newForm = 0
          newForm = 1 if %i[Hail].include?(@battle.pbWeather)
          if @form != newForm
              showMyAbilitySplash(:WINTERGIFT, true)
              hideMyAbilitySplash
              pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
          end
      else
          pbChangeForm(0, _INTL("{1} transformed!", pbThis))
      end
  end
end

#===============================================================================
# Nebula Cloud
#===============================================================================

BattleHandlers::StatLossImmunityAbility.add(:NEBULACLOUD,
  proc { |ability, battler, _stat, battle, showMessages|
      next false unless battler.pbHasType?(:COSMIC)
      if showMessages
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbDisplay(_INTL("{1}'s stats cannot be lowered!", battler.pbThis))
          battle.pbHideAbilitySplash(battler)
      end
      next true
  }
)

BattleHandlers::StatusImmunityAbility.add(:NEBULACLOUD,
  proc { |ability, battler, _status|
      next true if battler.pbHasType?(:COSMIC)
  }
)

BattleHandlers::StatLossImmunityAllyAbility.add(:NEBULACLOUD,
    proc { |ability, bearer, battler, _stat, battle, showMessages|
        next false unless battler.pbHasType?(:COSMIC)
        if showMessages
            battle.pbShowAbilitySplash(bearer, ability)
            battle.pbDisplay(_INTL("{1}'s stats cannot be lowered!", battler.pbThis))
            battle.pbHideAbilitySplash(bearer)
        end
        next true
    }
)

BattleHandlers::StatusImmunityAllyAbility.add(:NEBULACLOUD,
    proc { |ability, battler, _status|
        next true if battler.pbHasType?(:COSMIC)
    }
)

#===============================================================================
# Water Bubble clones
#===============================================================================

BattleHandlers::DamageCalcTargetAbility.add(:LIGHTBULB,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :DARK
      mults[:final_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:LIGHTBULB,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :LIGHT
      mults[:attack_multiplier] *= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TERRORIFIC,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :BUG
      mults[:final_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TERRORIFIC,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :PSYCHIC
      mults[:attack_multiplier] *= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

#===============================================================================
# Others
#===============================================================================

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:VENGEFUL,
  proc { |ability, battler, _battle|
      battler.pbRaiseMultipleStatSteps([:ATTACK, 2, :SPEED, 2], battler, ability: ability)
      next false
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:PRECISION,
  proc { |ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 1.3
  }
)

BattleHandlers::TargetAbilityOnHit.add(:SCORCHSCALE,
    proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
        next unless move.physicalMove? && move.priority
        randomStatusProcTargetAbility(ability, :BURN, 100, user, target, move, battle, aiCheck, aiNumHits)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:TOXICDEBRIS,
    proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
        next if target.pbOpposingSide.effectAtMax?(:PoisonSpikes)
        if aiCheck
            layerSlots = GameData::BattleEffect.get(:PoisonSpikes).maximum - target.pbOpposingSide.countEffect(:Spikes)
            aiNumHits = [aiNumHits,layerSlots].min
            next -getHazardSettingEffectScore(target, user) * aiNumHits
        end
        battle.pbShowAbilitySplash(target, ability)
        target.pbOpposingSide.incrementEffect(:PoisonSpikes)
        battle.pbHideAbilitySplash(target)
    }
)


BattleHandlers::EOREffectAbility.add(:PUREHEART,
  proc { |ability, battler, battle|
      battler.applyFractionalHealing(EOT_ABILITY_HEALING_FRACTION, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:LEECHINGFANGS,
  proc { |ability, user, targets, move, _battle|
    next unless move.bitingMove?
    user.pbRecoverHPFromMultiDrain(targets, 0.13, ability: ability)
  } 
)