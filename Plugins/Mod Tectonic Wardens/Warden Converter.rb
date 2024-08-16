def chooseWardenMon
  blacklist = [:ETERNATUS,:REGIROCK,:REGICE,:REGISTEEL,:MANAPHY,:PHIONE,:DARKRAI,:CRESSELIA,:TAPUKOKO,:TAPULELE,:TAPUFINI,:TAPUBULU,:HOOPA]
  mon = selectWardenPokemon
  if mon != nil
    new_mon = pbTranslateWardenSpecies(mon,true)
    can_translate = (new_mon==nil) ? false : (IS_WARDEN_MON.include?(new_mon) ? true : false)
    if can_translate && !blacklist.include?(mon)
      generateWardenEgg(new_mon)
    else
      Kernel.pbMessage("Unfortunately I can't make an egg for you.")
    end
  end
end