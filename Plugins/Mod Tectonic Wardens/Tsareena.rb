class PokeBattle_Move_ChangeUserOTsareenaForm < PokeBattle_Move
  def pbMoveFailed?(user, _targets, show_message)
      if !user.countsAs?(:OTSAREENA)
          @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
          return true
      elsif user.form != 0
          @battle.pbDisplay(_INTL("But {1} can't use it the way it is now!", user.pbThis(true))) if show_message
          return true 
      end
      return false
  end

  def pbBaseType(user)
    ret = :NORMAL
    if user.hasAbility?(:LIGHTAURA)
        ret = :DARK if GameData::Type.exists?(:DARK)
    elsif user.hasAbility?(:DARKAURA)
        ret = :LIGHT if GameData::Type.exists?(:LIGHT)
    end 
    return ret
  end 

  def pbEffectGeneral(user)
      if user.hasAbility?(:LIGHTAURA)
        user.pbChangeForm(1, _INTL("{1} purged its Dark typing!", user.pbThis))
      elsif user.hasAbility?(:DARKAURA)
        user.pbChangeForm(2, _INTL("{1} purged its Light typing!", user.pbThis))
      end 
  end

  def getEffectScore(user, _target)
      score = super
      score += 100
      score += 50 if user.firstTurn?
      return score
  end
end 