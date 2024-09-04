def playTemporalIslandUnlock
  $PokemonGlobal.noWildEXPTutorialized = true
  tutorialMessages = 
  [
      _INTL("You can now travel to the Temporal Island via the next Avatar Totem you find!")
  ]
  playTutorial(tutorialMessages)
end