class PokemonPokedexInfo_Scene
    SIGNATURE_COLOR = Color.new(211, 175, 44)
    SIGNATURE_COLOR_LIGHTER = Color.new(228, 207, 128)

    def pageTitles
        return [_INTL("INFO"), _INTL("ABILITIES"), _INTL("STATS"), _INTL("DEF. MATCHUPS"),
                _INTL("ATK. MATCHUPS"), _INTL("LEVEL UP MOVES"), _INTL("TUTOR MOVES"),
                _INTL("EVOLUTIONS"), _INTL("AREA"), _INTL("FORMS"), _INTL("ANALYSIS")]
    end

    def pbStartScene(dexlist, index, region, battle = false, linksEnabled = false)
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @dexlist = dexlist
        @index   = index
        @region  = region
        @page = battle ? 2 : 1
        @linksEnabled = linksEnabled
        @evolutionIndex = -1
        @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types"))
        @types_emphasized_bitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types_emphasized"))
        @moveInfoDisplayBitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/move_info_display_dex"))
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["infosprite"] = PokemonSprite.new(@viewport)
        @sprites["infosprite"].setOffset(PictureOrigin::Center)
        @sprites["infosprite"].x = 104
        @sprites["infosprite"].y = 136
        @mapdata = pbLoadTownMapData
        map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
        mappos = map_metadata ? map_metadata.town_map_position : nil
        if @region < 0                                 # Use player's current region
            @region = mappos ? mappos[0] : 0 # Region 0 default
        end
        @sprites["areamap"] = IconSprite.new(0, 0, @viewport)
        @sprites["areamap"].setBitmap("Graphics/Pictures/#{@mapdata[@region][1]}")
        @sprites["areamap"].x += (Graphics.width - @sprites["areamap"].bitmap.width) / 2
        @sprites["areamap"].y += (Graphics.height + 32 - @sprites["areamap"].bitmap.height) / 2
        for hidden in Settings::REGION_MAP_EXTRAS
            next unless hidden[0] == @region && hidden[1] > 0 && $game_switches[hidden[1]]
            pbDrawImagePositions(@sprites["areamap"].bitmap, [
                                     ["Graphics/Pictures/#{hidden[4]}",
                                      hidden[2] * PokemonRegionMap_Scene::SQUAREWIDTH,
                                      hidden[3] * PokemonRegionMap_Scene::SQUAREHEIGHT,],
                                 ])
        end
        @sprites["areahighlight"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["areaoverlay"] = IconSprite.new(0, 0, @viewport)
        @sprites["areaoverlay"].setBitmap("Graphics/Pictures/Pokedex/overlay_area")
        @sprites["formfront"] = PokemonSprite.new(@viewport)
        @sprites["formfront"].setOffset(PictureOrigin::Center)
        @sprites["formfront"].x = 130
        @sprites["formfront"].y = 158
        @sprites["formback"] = PokemonSprite.new(@viewport)
        @sprites["formback"].setOffset(PictureOrigin::Bottom)
        @sprites["formback"].x = 382 # y is set below as it depends on metrics
        @sprites["formicon"] = PokemonSpeciesIconSprite.new(nil, @viewport)
        @sprites["formicon"].setOffset(PictureOrigin::Center)
        @sprites["formicon"].x = 82
        @sprites["formicon"].y = 328
        @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow", 8, 28, 40, 2, @viewport)
        @sprites["uparrow"].x = 242
        @sprites["uparrow"].y = 268
        @sprites["uparrow"].play
        @sprites["uparrow"].visible = false
        @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow", 8, 28, 40, 2, @viewport)
        @sprites["downarrow"].x = 242
        @sprites["downarrow"].y = 348
        @sprites["downarrow"].play
        @sprites["downarrow"].visible = false
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x = 48
        @sprites["leftarrow"].y = 52
        @sprites["leftarrow"].play
        @sprites["leftarrow"].visible = false
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x = 184
        @sprites["rightarrow"].y = 52
        @sprites["rightarrow"].play
        @sprites["rightarrow"].visible = false
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["selectionarrow"] = IconSprite.new(0, 0, @viewport)
        @sprites["selectionarrow"].setBitmap("Graphics/Pictures/selarrow")
        @sprites["selectionarrow"].visible = false
        @sprites["selectionarrow"].x = 32
        # Create the move extra info display
        @moveInfoDisplay = SpriteWrapper.new(@viewport)
        @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        @sprites["moveInfoDisplay"] = @moveInfoDisplay
        # Create overlay for selected move's extra info (shows move's BP, description)
        @extraInfoOverlay = BitmapSprite.new(Graphics.width, Graphics.height,  @viewport)
        pbSetNarrowFont(@extraInfoOverlay.bitmap)
        @sprites["extraInfoOverlay"] = @extraInfoOverlay

        @scroll = -1
        @horizontalScroll = 0
        @title = "Undefined"
        pbSetSystemFont(@sprites["overlay"].bitmap)
        pbUpdateDummyPokemon
        @available = pbGetAvailableForms
        drawPage(@page)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @typebitmap.dispose
        @viewport.dispose
        @types_emphasized_bitmap.dispose
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbUpdateDummyPokemon
        @species = @dexlist[@index][0]
        @gender, @form = $Trainer.pokedex.last_form_seen(@species)
        species_data = GameData::Species.get_species_form(@species, @form)
        @title = species_data.form_name ? "#{species_data.name} (#{species_data.form_name})" : species_data.name
        @sprites["infosprite"].setSpeciesBitmap(@species, @gender, @form)
        forceShiny = debugControl
        @sprites["formfront"].setSpeciesBitmap(@species, @gender, @form, forceShiny) if @sprites["formfront"]
        if @sprites["formback"]
            if forceShiny
                @sprites["formback"].setSpeciesBitmapHueShifted(@species, @gender, @form, forceShiny)
            else
                @sprites["formback"].setSpeciesBitmap(@species, @gender, @form, false, false, true)
                @sprites["formback"].y = 256
                @sprites["formback"].y += species_data.back_sprite_y * 2
            end
        end
        @sprites["formicon"].pbSetParams(@species, @gender, @form) if @sprites["formicon"]
    end

    def pbGetAvailableForms
        ret = []
        @multiple_forms = false
        # Find all genders/forms of @species that have been seen
        GameData::Species.each do |sp|
            next if sp.species != @species
            next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
            next if sp.pokedex_form != sp.form
            @multiple_forms = true if sp.form > 0
            case sp.gender_ratio
            when :AlwaysMale, :AlwaysFemale, :Genderless
                real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
                next if !$Trainer.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
                real_gender = 2 if sp.gender_ratio == :Genderless
                ret.push([sp.form_name, real_gender, sp.form])
            else # Both male and female
                for real_gender in 0...2
                    next if !$Trainer.pokedex.seen_form?(@species, real_gender,
sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
                    ret.push([sp.form_name, real_gender, sp.form])
                    break if sp.form_name && !sp.form_name.empty? # Only show 1 entry for each non-0 form
                end
            end
        end
        # Sort all entries
        ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
        # Create form names for entries if they don't already exist
        ret.each do |entry|
            if !entry[0] || entry[0].empty? # Necessarily applies only to form 0
                case entry[1]
                when 0 then entry[0] = _INTL("Male")
                when 1 then entry[0] = _INTL("Female")
                else
                    entry[0] = @multiple_forms ? _INTL("One Form") : _INTL("Genderless")
                end
            end
            entry[1] = 0 if entry[1] == 2 # Genderless entries are treated as male
        end
        return ret
    end

    def drawPage(page)
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        # Make certain sprites visible or invisible
        @sprites["infosprite"].visible = (@page == 1)
        @sprites["areamap"].visible       = false if @sprites["areamap"] # (@page==7) if @sprites["areamap"]
        @sprites["areahighlight"].visible = false if @sprites["areahighlight"] # (@page==7) if @sprites["areahighlight"]
        @sprites["areaoverlay"].visible   = false if @sprites["areaoverlay"] # (@page==7) if @sprites["areaoverlay"]
        @sprites["formfront"].visible     = (@page == 10) if @sprites["formfront"]
        @sprites["formback"].visible      = (@page == 10) if @sprites["formback"]
        @sprites["formicon"].visible      = (@page == 10) if @sprites["formicon"]
        @sprites["moveInfoDisplay"].visible = @page == 6 || @page == 7  if @sprites["moveInfoDisplay"]
        @sprites["extraInfoOverlay"].visible = @page == 6 || @page == 7 if @sprites["extraInfoOverlay"]
        @sprites["extraInfoOverlay"].bitmap.clear if @sprites["extraInfoOverlay"]
        @sprites["selectionarrow"].visible = false
        # Draw page title
        overlay = @sprites["overlay"].bitmap
        base = Color.new(219, 240, 240)
        shadow = Color.new(88, 88, 80)
        # remove tribes page if not using tribes plugin
        pageTitle = pageTitles[page - 1]
        drawFormattedTextEx(overlay, 50, 2, Graphics.width, "<outln2>#{pageTitle}</outln2>", base, shadow, 18)
        xPos = 240
        # shift x position so that double digit page number does not overlap with the right facing arrow
        xPos -= 14 if @page >= 10
        drawFormattedTextEx(overlay, xPos, 2, Graphics.width, "<outln2>[#{page}/#{pageTitles.length - 1}]</outln2>", base,
  shadow, 18)
        # Draw species name on top right	
        speciesName = GameData::Species.get(@species).name
		speciesName = "#{speciesName} #{@form + 1}" if @multiple_forms
        # shift x position so that species name does not overlap with the right facing arrow
        xPos += 14 if @page >= 10
        drawFormattedTextEx(overlay, xPos + 104, 2, Graphics.width, "<outln2>#{speciesName}</outln2>", base, shadow, 18)
        # Draw page-specific information
        case page
        when 1 then drawPageInfo
        when 2 then drawPageAbilities
        when 3 then drawPageStats
        when 4 then drawPageMatchups
        when 5 then drawPageMatchups2
        when 6 then drawPageLevelUpMoves
        when 7 then drawPageTutorMoves
        when 8 then drawPageEvolution
        when 9 then drawPageArea
        when 10 then drawPageForms
        when 11 then drawPageDEBUG
        end
    end

    def drawPageInfo
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_info"))
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(88, 88, 80)
        shadow = Color.new(168, 184, 184)
        imagepos = []
        imagepos.push([_INTL("Graphics/Pictures/Pokedex/overlay_info"), 0, 0]) if @brief
        species_data = GameData::Species.get_species_form(@species, @form)
        # Write various bits of text
        indexText = "???"
        if @dexlist[@index][4] > 0
            indexNumber = @dexlist[@index][4]
            indexNumber -= 1 if @dexlist[@index][5]
            indexText = format("%03d", indexNumber)
        end
        textpos = [
            [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
             246, 36, 0, Color.new(248, 248, 248), Color.new(0, 0, 0),],
            [_INTL("Height"), 314, 152, 0, base, shadow],
            [_INTL("Weight"), 314, 184, 0, base, shadow],
        ]
        if $Trainer.owned?(@species)
            # Show the owned icon
            imagepos.push(["Graphics/Pictures/Pokedex/icon_own", 212, 44])
        end
        # Write the category
        textpos.push([_INTL("{1} Pokémon", species_data.category), 246, 68, 0, base, shadow])
        # Write the height and weight
        height = species_data.height
        weight = species_data.weight
        if System.user_language[3..4] == "US" # If the user is in the United States
            inches = (height / 0.254).round
            pounds = (weight / 0.45359).round
            textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), 460, 152, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), 494, 184, 1, base, shadow])
        else
            textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), 470, 152, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), 482, 184, 1, base, shadow])
        end
        # Draw the Pokédex entry text
        drawTextEx(overlay, 40, 244, Graphics.width - (40 * 2), 4, # overlay, x, y, width, num lines
                 species_data.pokedex_entry, base, shadow)
        # Draw the footprint
        footprintfile = GameData::Species.footprint_filename(@species, @form)
        if footprintfile
            footprint = RPG::Cache.load_bitmap("", footprintfile)
            overlay.blt(226, 138, footprint, footprint.rect)
            footprint.dispose
        end
        # Draw the type icon(s)
        type1 = species_data.type1
        type2 = species_data.type2
        type1_number = GameData::Type.get(type1).id_number
        type2_number = GameData::Type.get(type2).id_number
        type1rect = Rect.new(0, type1_number * 32, 96, 32)
        type2rect = Rect.new(0, type2_number * 32, 96, 32)
        overlay.blt(296, 120, @typebitmap.bitmap, type1rect)
        overlay.blt(396, 120, @typebitmap.bitmap, type2rect) if type1 != type2
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw all images
        pbDrawImagePositions(overlay, imagepos)
    end

    def drawPageAbilities
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_abilities"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        for i in @available
            next unless i[2] == @form
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            abilities = fSpecies.abilities
            # ability 1
            abilityTextX = 30
            abilityIDLabelX = 380
            ability1Y = 76
            drawTextEx(overlay, abilityIDLabelX, ability1Y, 450, 1, _INTL("Ability 1"), base, shadow)
            if abilities[0]
                ability1 = GameData::Ability.get(abilities[0])
                abilityNameColor = base
                abilityNameShadow = shadow
                abilityNameText = ability1.name
                if ability1.is_signature?
                    abilityNameText = "<outln2>" + abilityNameText + "</outln2>"
                    abilityNameColor = SIGNATURE_COLOR_LIGHTER
                    abilityNameShadow = base
                end
                drawFormattedTextEx(overlay, abilityTextX, ability1Y, 450, abilityNameText, abilityNameColor,
              abilityNameShadow)
                drawTextEx(overlay, abilityTextX, ability1Y + 32, 450, 3, ability1.description, base, shadow)
            else
                drawTextEx(overlay, abilityTextX, 128, 450, 1, _INTL("None"), base, shadow)
            end
            # ability 1
            ability2Y = 236
            drawTextEx(overlay, abilityIDLabelX, ability2Y, 450, 1, _INTL("Ability 2"), base, shadow)
            if abilities[1]
                ability2 = GameData::Ability.get(abilities[1])
                abilityNameColor = base
                abilityNameShadow = shadow
                abilityNameText = ability2.name
                if ability2.is_signature?
                    abilityNameText = "<outln2>" + abilityNameText + "</outln2>"
                    abilityNameColor = SIGNATURE_COLOR_LIGHTER
                    abilityNameShadow = base
                end
                drawFormattedTextEx(overlay, abilityTextX, ability2Y, 450, abilityNameText, abilityNameColor,
              abilityNameShadow)
                drawTextEx(overlay, abilityTextX, ability2Y + 32, 450, 3, ability2.description, base, shadow)
            else
                drawTextEx(overlay, abilityTextX, ability2Y, 450, 1, _INTL("None"), base, shadow)
            end
        end
    end

    def genderRateToString(gender)
        case gender
        when :AlwaysMale            then    return _INTL("Male")
        when :FemaleOneEighth       then    return _INTL("7/8 Male")
        when :Female25Percent       then    return _INTL("3/4 Male")
        when :Female50Percent       then    return _INTL("50/50")
        when :Female75Percent       then    return _INTL("3/4 Fem.")
        when :FemaleSevenEighths    then    return _INTL("7/8 Fem.")
        when :AlwaysFemale          then    return _INTL("Female")
        when :Genderless            then    return _INTL("None")
        end
        return "No data"
    end

    def growthRateToString(growthRate)
        case growthRate
        when :Medium        then    return _INTL("Medium")
        when :Erratic       then    return _INTL("Erratic")
        when :Fluctuating   then    return _INTL("Flux")
        when :Parabolic     then    return _INTL("Med. Slow")
        when :Fast          then    return _INTL("Fast")
        when :Slow          then    return _INTL("Slow")
        end
    end

    def drawPageStats
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_stats"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        baseStatNames = [_INTL("HP"), _INTL("Attack"), _INTL("Defense"), _INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("Speed")]
        otherStatNames = [_INTL("Gender Rate"), _INTL("Growth Rate"), _INTL("Catch Dif."), _INTL("Exp. Grant"), _INTL("PEHP / SEHP")]

        # Everything else

		# Only give me 1 element in the case where the 2 forms are only gender.
        if @available.length >= 2 && @available[0][0] == "Male" && @available[1][0] == "Female"
            available = [@available[0]]
        else
            available = @available
        end

        tribes = []
        for i in available
            next unless i[2] == @form
            speciesFormData = GameData::Species.get_species_form(@species, @form)
            speciesFormData.tribes.each do |tribe|
                tribes.push(getTribeName(tribe))
            end
        end
        tribesDescription = tribes.join(", ")

        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            yBase = 96

            # Base stats
            drawTextEx(overlay, 30, yBase - 40, 450, 1, _INTL("Base Stats"), base, shadow)
            baseStats = fSpecies.base_stats
            total = 0
            baseStats.each_with_index do |stat, index|
                next unless stat
                statValue = stat[1]
                total += statValue
                # Draw stat line
                drawTextEx(overlay, 30, yBase + 32 * index, 450, 1, baseStatNames[index], base, shadow)
                statString = statValue.to_s
                prevos = fSpecies.get_prevolutions
                if $DEBUG && prevos.length == 1
                    prevoSpeciesData = GameData::Species.get(prevos[0][0])
                    statSym = prevoSpeciesData.base_stats.keys[index]
                    prevoSpeciesStatValue = prevoSpeciesData.base_stats[statSym]
                    statUpgradePercentage = (((statValue.to_f / prevoSpeciesStatValue.to_f) - 1) * 100).floor
                    statString += " (#{statUpgradePercentage})" if Input.press?(Input::CTRL)
                end
                drawTextEx(overlay, 136, yBase + 32 * index, 450, 1, statString, base, shadow)
            end
            drawTextEx(overlay, 30, yBase + 32 * 6 + 14, 450, 1, _INTL("Total"), base, shadow)
            drawTextEx(overlay, 136, yBase + 32 * 6 + 14, 450, 1, total.to_s, base, shadow)
            # Other stats
            drawTextEx(overlay, 250, yBase - 40, 450, 1, _INTL("Other Stats"), base, shadow)
            otherStats = []
            genderRate = fSpecies.gender_ratio
            genderRateString = genderRateToString(genderRate)
            otherStats.push(genderRateString)
            growthRate = fSpecies.growth_rate
            growthRateString = growthRateToString(growthRate)
            otherStats.push(growthRateString)

            otherStats.push(catchDifficultyFromRareness(fSpecies.catch_rate))

            otherStats.push(fSpecies.base_exp)

            physEHP = fSpecies.physical_ehp
            specEHP = fSpecies.special_ehp
            otherStats.push(physEHP.to_s + " / " + specEHP.to_s)

            otherStats.each_with_index do |stat, index|
                next unless stat
                # Draw stat line
                drawTextEx(overlay, 230, yBase + 32 * index, 450, 1, otherStatNames[index], base, shadow)
                drawTextEx(overlay, 378, yBase + 32 * index, 450, 1, stat.to_s, base, shadow)
            end
            items = []
            items.push(fSpecies.wild_item_common) if fSpecies.wild_item_common
            items.push(fSpecies.wild_item_uncommon) if fSpecies.wild_item_uncommon
            items.push(fSpecies.wild_item_rare) if fSpecies.wild_item_rare
            items.uniq!
            items.compact!
            itemsString = ""
            if items.length > 0
                items.each_with_index do |item, index|
                    name = GameData::Item.get(item).name
                    itemsString += name
                    itemsString += ", " if index < items.length - 1
                end
            else
                itemsString = _INTL("None")
            end
            drawTextEx(overlay, 230, yBase + 174, 450, 1, _INTL("Wild Items"), base, shadow)
            drawTextEx(overlay, 230, yBase + 203, 450, 1, itemsString, base, shadow)

            drawTextEx(overlay, 30, yBase + 244, 450, 1, _INTL("Tribes:"), base, shadow)
            drawTextEx(overlay, 120, yBase + 244, 800, 1, tribesDescription, base, shadow)
        end
    end

    def drawPageMatchups
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_matchups"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        xLeft = 36
        yBase = 60
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            # type1 = GameData::Type.get(fSpecies.type1)
            # type2 = GameData::Type.get(fSpecies.type2)

            immuneTypes = []
            barelyEffectiveTypes = []
            resistentTypes = []
            weakTypes = []
            hyperWeakTypes = []

            GameData::Type.each do |t|
                next if t.pseudo_type

                effect = Effectiveness.calculate(t.id, fSpecies.type1, fSpecies.type2)

                if Effectiveness.ineffective?(effect)
                    immuneTypes.push(t)
                elsif Effectiveness.barely_effective?(effect)
                    barelyEffectiveTypes.push(t)
                elsif Effectiveness.not_very_effective?(effect)
                    resistentTypes.push(t)
                elsif Effectiveness.hyper_effective?(effect)
                    hyperWeakTypes.push(t)
                elsif Effectiveness.super_effective?(effect)
                    weakTypes.push(t)
                end
            end
            weakTypes = [].concat(hyperWeakTypes, weakTypes)
            resistentTypes = [].concat(barelyEffectiveTypes, resistentTypes)

            # Draw the types the pokemon is weak to
            drawTextEx(overlay, xLeft, yBase, 450, 1, _INTL("Weak:"), base, shadow)
            if weakTypes.length == 0
                drawTextEx(overlay, xLeft, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                weakTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    bitmapUsed = hyperWeakTypes.include?(t) ? @types_emphasized_bitmap.bitmap : @typebitmap.bitmap
                    overlay.blt(xLeft, yBase + 30 + 36 * index, bitmapUsed, typerect)
                end
            end

            # Draw the types the pokemon resists
            resistOffset = 112
            drawTextEx(overlay, xLeft + resistOffset, yBase, 450, 1, _INTL("Resist:"), base, shadow)
            if resistentTypes.length == 0
                drawTextEx(overlay, xLeft + resistOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                resistentTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    bitmapUsed = barelyEffectiveTypes.include?(t) ? @types_emphasized_bitmap.bitmap : @typebitmap.bitmap
                    overlay.blt(xLeft + resistOffset + (index >= 7 ? 100 : 0), yBase + 30 + 36 * (index % 7),
              bitmapUsed, typerect)
                end
            end

            # Draw the types the pokemon is immune to
            immuneOffset = 324
            drawTextEx(overlay, xLeft + immuneOffset, yBase, 450, 1, _INTL("Immune:"), base, shadow)
            if immuneTypes.length == 0
                drawTextEx(overlay, xLeft + immuneOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                immuneTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + immuneOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end
        end
    end

    def drawPageMatchups2
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_matchups"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        xLeft = 36
        yBase = 60
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            immuneTypes = []
            resistentTypes = []
            weakTypes = []

            GameData::Type.each do |t|
                next if t.pseudo_type

                effect1 = Effectiveness.calculate(fSpecies.type1, t.id, t.id)
                effect2 = Effectiveness.calculate(fSpecies.type2, t.id, t.id)
                effect = [effect1, effect2].max

                if Effectiveness.ineffective?(effect)
                    immuneTypes.push(t)
                elsif Effectiveness.not_very_effective?(effect)
                    resistentTypes.push(t)
                elsif Effectiveness.super_effective?(effect)
                    weakTypes.push(t)
                end
            end

            # Draw the types the pokemon is super effective against
            drawTextEx(overlay, xLeft, yBase, 450, 1, _INTL("Super:"), base, shadow)
            if weakTypes.length == 0
                drawTextEx(overlay, xLeft, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                weakTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + (index >= 7 ? 100 : 0), yBase + 30 + 36 * (index % 7), @typebitmap.bitmap,
              typerect)
                end
            end

            # Draw the types the pokemon can't deal but NVE damage to
            resistOffset = 212
            drawTextEx(overlay, xLeft + resistOffset, yBase, 450, 1, _INTL("Not Very:"), base, shadow)
            if resistentTypes.length == 0
                drawTextEx(overlay, xLeft + resistOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                resistentTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + resistOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end

            # Draw the types the pokemon can't deal but immune damage to
            immuneOffset = 324
            drawTextEx(overlay, xLeft + immuneOffset, yBase, 450, 1, _INTL("No Effect:"), base, shadow)
            if immuneTypes.length == 0
                drawTextEx(overlay, xLeft + immuneOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                immuneTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + immuneOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end
        end
    end

    def getFormattedMoveName(move, maxWidth = 99_999)
        fSpecies = GameData::Species.get_species_form(@species, @form)
        move_data = GameData::Move.get(move)
        moveName = move_data.name

        isSTAB = move_data.category < 2 && [fSpecies.type1, fSpecies.type2].include?(move_data.type)

        # Chop letters off of excessively long names to make them fit into the maximum width
        overlay = @sprites["overlay"].bitmap
        expectedMoveNameWidth = overlay.text_size(moveName).width
        expectedMoveNameWidth *= 1.2 if isSTAB
        expectedMoveNameWidth *= 1.2 if move_data.is_signature?
        if expectedMoveNameWidth > maxWidth
            charactersToShave = 3
            loop do
                testString = moveName[0..-charactersToShave] + "..."
                expectedTestStringWidth = overlay.text_size(testString).width
                expectedTestStringWidth *= 1.2 if isSTAB
                expectedTestStringWidth *= 1.2 if move_data.is_signature?
                excessWidth = expectedTestStringWidth - maxWidth
                break if excessWidth <= 0
                charactersToShave += 1
            end
            shavedName = moveName[0..-charactersToShave]
            shavedName = shavedName[0..-1] if shavedName[shavedName.length-1] == " "
            moveName = shavedName + "..."
        end

        # Add formatting based on if the move is the same type as the user
        # Or of any of its evolutions
        if isSTAB
            moveName = "<b>#{moveName}</b>"
        elsif move_data.category < 2 && isAnyEvolutionOfType(fSpecies, move_data.type)
            moveName = "<i>#{moveName}</i>"
        end

        color = Color.new(64, 64, 64)
        if move_data.is_signature?
            if isSTAB
                moveName = "<outln2>" + moveName + "</outln2>"
            else
                moveName = "<outln>" + moveName + "</outln>"
            end
            shadow = SIGNATURE_COLOR
        else
            shadow = Color.new(176, 176, 176)
        end
        return moveName, color, shadow
    end

    def isAnyEvolutionOfType(species_data, type)
        ret = false
        species_data.get_evolutions.each do |evolution_data|
            evoSpecies_data = GameData::Species.get_species_form(evolution_data[0], @form)
            ret = true if [evoSpecies_data.type1, evoSpecies_data.type2].include?(type)
            ret = true if isAnyEvolutionOfType(evoSpecies_data, type) # Recursion!!
        end
        return ret
    end

    MAX_LENGTH_MOVE_LIST = 7
    MOVE_LIST_STARTING_Y = 54

    def drawPageLevelUpMoves
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_moves"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        selected_move = nil
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            learnset = fSpecies.moves
            displayIndex = 0
            @scrollableLists = [learnset]
            learnset.each_with_index do |learnsetEntry, listIndex|
                next if listIndex < @scroll
                level = learnsetEntry[0]
                move = learnsetEntry[1]
                return if !move || !level
                levelLabel = level.to_s
                levelLabel = _INTL("E") if level == 0
                # Draw stat line
                offsetX = 0
                maxWidth = displayIndex == 0 ? 158 : 170
                moveName, moveColor, moveShadow = getFormattedMoveName(move, maxWidth)
                if listIndex == @scroll
                    offsetX = 12
                    selected_move = move
                end
                moveDrawY = MOVE_LIST_STARTING_Y + 30 * displayIndex
                drawTextEx(overlay, xLeft + offsetX, moveDrawY, 450, 1, levelLabel, moveColor, moveShadow)
                drawFormattedTextEx(overlay, xLeft + 30 + offsetX, moveDrawY, 450, moveName, moveColor, moveShadow)
                if listIndex == @scroll
                    @sprites["selectionarrow"].y = moveDrawY - 4
                    @sprites["selectionarrow"].visible = true
                end
                displayIndex += 1
                break if displayIndex > MAX_LENGTH_MOVE_LIST
            end
        end

        drawMoveInfo(selected_move)
    end

    def drawPageTutorMoves
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_moves"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)

        selected_move = nil
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            species_data = GameData::Species.get_species_form(@species, i[2])
            compatibleMoves = species_data.learnable_moves
            compatiblePhysMoves = compatibleMoves.select do |move|
                movaData = GameData::Move.get(move)
                next movaData.category == 0
            end
            compatiblePhysMoves.sort_by!{|moveID| GameData::Move.get(moveID).name}
            compatibleSpecMoves = compatibleMoves.select do |move|
                movaData = GameData::Move.get(move)
                next movaData.category == 1
            end
            compatibleSpecMoves.sort_by!{|moveID| GameData::Move.get(moveID).name}
            compatibleStatusMoves = compatibleMoves.select do |move|
                movaData = GameData::Move.get(move)
                next movaData.category == 2
            end
            compatibleStatusMoves.sort_by!{|moveID| GameData::Move.get(moveID).name}
            @scrollableLists = [compatiblePhysMoves, compatibleSpecMoves, compatibleStatusMoves]
            categoryName = [_INTL("Physical"),_INTL("Special"),_INTL("Status")][@horizontalScroll]
            drawFormattedTextEx(overlay, xLeft, 60, 192, "<ac><b>#{categoryName}</b></ac>", base, shadow)
            displayIndex = 1
            listIndex = -1
            if @scrollableLists[@horizontalScroll].length > 0
                @scrollableLists[@horizontalScroll].each_with_index do |move, _index|
                    listIndex += 1
                    next if listIndex < @scroll
                    maxWidth = displayIndex == 0 ? 188 : 200
                    moveName, moveColor, moveShadow = getFormattedMoveName(move, 200)
                    offsetX = 0
                    if listIndex == @scroll
                        selected_move = move
                        offsetX = 12
                    end
                    moveDrawY = MOVE_LIST_STARTING_Y + 30 * displayIndex
                    drawFormattedTextEx(overlay, xLeft + offsetX, moveDrawY, 450, moveName, moveColor, moveShadow)
                    if listIndex == @scroll
                        @sprites["selectionarrow"].y = moveDrawY - 4
                        @sprites["selectionarrow"].visible = true
                    end
                    displayIndex += 1
                    break if displayIndex > MAX_LENGTH_MOVE_LIST
                end
            else
                drawFormattedTextEx(overlay, xLeft + 60, 90, 450, _INTL("None"), base, shadow)
            end
        end

        drawMoveInfo(selected_move)
    end

    def drawMoveInfo(selected_move)
        unless selected_move.nil?
            # Extra move info display
            @extraInfoOverlay.bitmap.clear
            overlay = @extraInfoOverlay.bitmap
            moveData = GameData::Move.get(selected_move)

            # Prepare values
            base   = Color.new(248, 248, 248)
            faded_base = Color.new(110,110,110)
            shadow = Color.new(104, 104, 104)
            column1LabelX = 246
            column2LabelX = 322
            column3LabelX = 430
            column1ValueX = 274
            column2ValueX = 368
            column3ValueX = 460
            row1LabelY = 80
            row2LabelY = 146
            row3LabelY = 210
            row1ValueY = row1LabelY + 32
            row2ValueY = row2LabelY + 32
            row3ValueY = row3LabelY + 32

            nameX = 374
            nameY = 46
            descriptionX = 8
            descriptionY = 286

            # Labels #
            
            # Start with the name
            textpos = [[moveData.name, nameX, nameY, 2, base, shadow]]

            # Row 1
            textpos.concat([
                [_INTL("TYPE"), column1LabelX, row1LabelY, 0, base, shadow],
                [_INTL("CATEGORY"), column2LabelX, row1LabelY, 0, base, shadow],
                [_INTL("POWER"), column3LabelX, row1LabelY, 0, base, shadow],
            ])

            # Row 1
            textpos.concat([
                [_INTL("ACC"), column1LabelX, row2LabelY, 0, base, shadow],
                [_INTL("PRIORITY"), column2LabelX, row2LabelY, 0, base, shadow],
                [_INTL("PP"), column3LabelX, row2LabelY, 0, base, shadow],
            ])

            # Row 1
            textpos.concat([
                [_INTL("TAG"), column1LabelX, row3LabelY, 0, base, shadow],
                [_INTL("TARGET"), column2LabelX, row3LabelY, 0, base, shadow],
            ])

            # Values #
            base = Color.new(64,64,64)
            shadow = Color.new(176,176,176)

            # Row 1
            # Draw selected move's damage category icon and type icon
            imagepos = [
                ["Graphics/Pictures/types", column1LabelX, row1ValueY + 8, 0, GameData::Type.get(moveData.type).id_number * 28, 64, 28],
                ["Graphics/Pictures/category", column2LabelX + 16, row1ValueY + 8, 0, moveData.category * 28, 64, 28],
            ]
            pbDrawImagePositions(overlay, imagepos)

            # Base damage
            case moveData.base_damage
            when 0 then textpos.push(["---", column3ValueX, row1ValueY, 2, faded_base, shadow])   # Status move
            when 1 then textpos.push(["???", column3ValueX, row1ValueY, 2, base, shadow])   # Variable power move
            else        textpos.push([moveData.base_damage.to_s, column3ValueX, row1ValueY, 2, base, shadow])
            end

            # Row 2
            # Accuracy
            if moveData.accuracy == 0
                textpos.push(["---", column1ValueX, row2ValueY, 2, faded_base, shadow])
            else
                textpos.push(["#{moveData.accuracy}%", column1ValueX, row2ValueY, 2, base, shadow])
            end
            # Priority
            textpos.push([moveData.priorityLabel,column2ValueX, row2ValueY, 2, moveData.priority != 0 ? base : faded_base, shadow])

            # PP
            textpos.push([moveData.total_pp.to_s,column3ValueX, row2ValueY, 2, moveData.total_pp > 0 ? base : faded_base, shadow])

            # Row 3
            moveCategoryLabel = moveData.tagLabel || "---"
            textpos.push([moveCategoryLabel, column1ValueX, row3ValueY, 2, moveData.tagLabel ? base : faded_base, shadow])
            # Targeting
            targetingData = GameData::Target.get(moveData.target)
            textpos.push([targetingData.get_targeting_label,column2LabelX + 4, row3ValueY, 0, base, shadow])

            # Targeting graphic
            targetingGraphicTextPos = []
            targetingGraphicColumn1X = column2LabelX + 84
            targetingGraphicColumn2X = targetingGraphicColumn1X + 46
            targetingGraphicRow1Y = row3LabelY + 4
            targetingGraphicRow2Y = targetingGraphicRow1Y + 26

            targetableColor = Color.new(120,5,5)
            untargetableColor = faded_base

            # Foes
            foeColor = targetingData.show_foe_targeting? ? targetableColor : untargetableColor
            targetingGraphicTextPos.push([_INTL("Foe"),targetingGraphicColumn1X, targetingGraphicRow1Y, 0, foeColor, shadow])
            targetingGraphicTextPos.push([_INTL("Foe"),targetingGraphicColumn2X, targetingGraphicRow1Y, 0, foeColor, shadow])

            # User
            userColor = targetingData.show_user_targeting? ? targetableColor : untargetableColor
            targetingGraphicTextPos.push([_INTL("User"),targetingGraphicColumn1X, targetingGraphicRow2Y, 0, userColor, shadow])

            # Ally
            allyColor = targetingData.show_ally_targeting? ? targetableColor : untargetableColor
            targetingGraphicTextPos.push([_INTL("Ally"),targetingGraphicColumn2X, targetingGraphicRow2Y, 0, allyColor, shadow])

            # Draw the targeting graphic text
            pbSetNarrowFont(overlay)
            overlay.font.size = 20
            pbDrawTextPositions(overlay, targetingGraphicTextPos)
            pbSetSystemFont(overlay)

            # Draw all text
            pbDrawTextPositions(overlay, textpos)

            # Draw selected move's description
            drawTextEx(overlay, descriptionX, descriptionY, 496, 3, moveData.description, base, shadow)
        end
    end

    def drawPageEvolution
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_evolution"))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            coordinateY = 54
            if @species != :EEVEE
                prevoTitle = _INTL("Pre-Evolutions of {1}", @title)
                drawTextEx(overlay, (Graphics.width - prevoTitle.length * 10) / 2, coordinateY, 450, 1, prevoTitle,
              base, shadow)
                coordinateY += 34
            end
            index = 0

            # Show pre-volutions
            prevolutions = fSpecies.get_prevolutions
            if @species != :EEVEE
                if prevolutions.length == 0
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
                    coordinateY += 30
                else
                    prevolutions.each do |evolution|
                        method = evolution[1]
                        parameter = evolution[2]
                        species = evolution[0]
                        return if !method || !species
                        evolutionName = GameData::Species.get_species_form(species, i[2]).name
                        methodDescription = describeEvolutionMethod(method, parameter)
                        # Draw preevolution description
                        color = index == @evolutionIndex ? Color.new(255, 100, 80) : base
                        evolutionLineText = _INTL("Evolves from ") + evolutionName + " " + methodDescription
                        drawTextEx(overlay, xLeft, coordinateY, 450, 2, evolutionLineText, color, shadow)
                        coordinateY += 30
                        coordinateY += 30 if method != :Level
                        index += 1
                    end
                end
            end

            evoTitle = _INTL("Evolutions of {1}", @title)
            drawTextEx(overlay, (Graphics.width - evoTitle.length * 10) / 2, coordinateY, 450, 1, evoTitle, base,
              shadow)
            coordinateY += 34

            @evolutionsArray = prevolutions

            # Show evolutions
            allEvolutions = getEvolutionsRecursive(fSpecies)

            if allEvolutions.length == 0
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
                coordinateY += 30
            elsif @species == :EEVEE
                drawTextEx(overlay, xLeft, coordinateY, 450, 7, _INTL("Evolves into Vaporeon with a Water Stone, " +
                    _INTL("Jolteon with a Thunder Stone, Flareon with a Fire Stone, Espeon with a Dawn Stone, ") +
                        _INTL("Umbreon with a Dusk Stone, Leafeon with a Leaf Stone, Glaceon with an Ice Stone, ") +
                            _INTL("Sylveon with a Moon Stone, and Giganteon at level 42.")
                                                                     ), base, shadow)
            else
                allEvolutions.each do |fromSpecies, evolutions|
                    evolutions.each do |evolution|
                        species = evolution[0]
                        method = evolution[1]
                        parameter = evolution[2]
                        next if method.nil? || species.nil?
                        speciesData = GameData::Species.get_species_form(species, i[2])
                        next if speciesData.nil?
                        @evolutionsArray.push(evolution)
                        evolutionName = speciesData.name
                        methodDescription = describeEvolutionMethod(method, parameter)
                        # Draw evolution description
                        color = index == @evolutionIndex ? Color.new(255, 100, 80) : base
                        fromSpeciesName = GameData::Species.get(fromSpecies).name
                        evolutionTextLine = _INTL("Evolves into ") + evolutionName + " " + methodDescription
                        if fromSpecies != fSpecies.species
                            evolutionTextLine = evolutionTextLine + _INTL(" (through {1})",fromSpeciesName)
                        end
                        drawTextEx(overlay, xLeft, coordinateY, 450, 2, evolutionTextLine, color, shadow)
                        coordinateY += 30
                        coordinateY += 30 if method != :Level || fromSpecies != fSpecies.species
                        index += 1
                    end
                end
            end
        end
    end

    def getNameForEncounterType(encounterType)
        case encounterType
        when :Land
            return _INTL("Grass")
        when :LandSparse
            return _INTL("Sparse Grass")
        when :LandTall
            return _INTL("Tall Grass")
        when :Special
            return _INTL("Other")
        when :FloweryGrass
            return _INTL("Yellow Flowers")
        when :FloweryGrass2
            return _INTL("Blue Flowers")
        when :SewerWater
            return _INTL("Sewage")
        when :SewerFloor
            return _INTL("Dirty Floor")
        when :DarkCave
            return _INTL("Dark Ground")
        when :Mud
            return _INTL("Mud")
        when :Puddle
            return _INTL("Puddle")
        when :LandTinted
            return _INTL("Secret Grass")
        when :Cloud
            return _INTL("Dark Clouds")
        end
        return _INTL("Unknown")
    end

    def getEncounterableAreas(species)
        areas = []
        GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
            if HIDDEN_MAPS.key?(enc_data.map)
                switchID = HIDDEN_MAPS[enc_data.map]
                next unless $game_switches[switchID]
            end

            enc_data.types.each do |type, slots|
                next unless slots
                slots.each	do |slot|
                    next unless GameData::Species.get(slot[1]).species == species
                    name = begin
                        pbGetMessage(MessageTypes::MapNames, enc_data.map)
                    rescue StandardError
                        nil
                    end || "???"
                    name = "#{name} [#{getNameForEncounterType(type)}]"
                    areas.push(name)
                    break
                end
            end
        end
        areas.uniq!
        return areas
    end

    def drawPageArea
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_area"))
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(88, 88, 80)
        shadow = Color.new(168, 184, 184)

        xLeft = 36
        for i in @available
            next unless i[2] == @form
            # Determine which areas the pokemon can be encountered in
            areas = getEncounterableAreas(@species)

            # Draw the areas the pokemon can be encountered in
            coordinateY = 54
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Encounterable Areas for {1}", @title),
  base, shadow)
            coordinateY += 30
            if areas.length == 0
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
            else
                areas.each do |area_name|
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, area_name, base, shadow)
                    coordinateY += 30
                end
            end

            # Determine which areas the pokemon's pre-evos can be encountered in
            prevo_areas = []
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            prevolutions = fSpecies.get_prevolutions
            currentPrevo = prevolutions.length > 0 ? prevolutions[0] : nil
            until currentPrevo.nil?
                currentPrevoSpecies = currentPrevo[0]
                currentPrevoSpeciesName = GameData::Species.get(currentPrevoSpecies).name
                prevosAreas = getEncounterableAreas(currentPrevoSpecies)
                prevosAreas.each do |area_name|
                    prevo_areas.push([area_name, currentPrevoSpeciesName])
                end

                # Find the prevo of the prevo
                prevosfSpecies = GameData::Species.get_species_form(currentPrevoSpecies, 0)
                prevolutions = prevosfSpecies.get_prevolutions
                currentPrevo = prevolutions.length > 0 ? prevolutions[0] : nil
            end
            prevo_areas.uniq!

            next unless prevo_areas.length != 0
            # Draw the areas the pokemon's pre-evos can be encountered in
            coordinateY += 60
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Encounter Areas for Pre-Evolutions", @title),
                      base, shadow)
            coordinateY += 30
            if prevo_areas.length == 0
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
            else
                prevo_areas.each do |area_name, prevo_name|
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, "#{area_name} (#{prevo_name})", base,
  shadow)
                    coordinateY += 30
                end
            end
        end
    end

    def drawPageForms
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_forms"))
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(88, 88, 80)
        shadow = Color.new(168, 184, 184)
        # Write species and form name
        formname = ""
        for i in @available
            if i[1] == @gender && i[2] == @form
                formname = i[0]
                break
            end
        end
        textpos = [
            [GameData::Species.get(@species).name, Graphics.width / 2, Graphics.height - 94, 2, base, shadow],
            [formname, Graphics.width / 2, Graphics.height - 62, 2, base, shadow],
        ]
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
    end

    def pbGoToPrevious
        newindex = @index
        while newindex > 0
            newindex -= 1
            if !isLegendary(@dexlist[newindex][0]) || $Trainer.seen?(@dexlist[newindex][0])
                @index = newindex
                break
            end
        end
    end

    def pbGoToNext
        newindex = @index
        while newindex < @dexlist.length - 1
            newindex += 1
            if !isLegendary(@dexlist[newindex][0]) || $Trainer.seen?(@dexlist[newindex][0])
                @index = newindex
                break
            end
        end
    end

    def pbChooseForm
        index = 0
        for i in 0...@available.length
            if @available[i][1] == @gender && @available[i][2] == @form
                index = i
                break
            end
        end
        oldindex = -1
        loop do
            if oldindex != index
                $Trainer.pokedex.set_last_form_seen(@species, @available[index][1], @available[index][2])
                pbUpdateDummyPokemon
                drawPage(@page)
                @sprites["uparrow"].visible   = (index > 0)
                @sprites["downarrow"].visible = (index < @available.length - 1)
                oldindex = index
            end
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::UP)
                pbPlayCursorSE
                index = (index + @available.length - 1) % @available.length
            elsif Input.trigger?(Input::DOWN)
                pbPlayCursorSE
                index = (index + 1) % @available.length
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                break
            end
        end
        @sprites["uparrow"].visible   = false
        @sprites["downarrow"].visible = false
    end

    def pbScroll
        @scroll = 0
        @sprites["leftarrow"].visible = @page == 7
        @sprites["rightarrow"].visible = @page == 7
        drawPage(@page)
        loop do
            Graphics.update
            Input.update
            pbUpdate
            doRefresh = false
            if Input.repeat?(Input::UP)
                if @scroll > 0
                    pbPlayCursorSE
                    @scroll -= 1
                    doRefresh = true
                elsif Input.trigger?(Input::UP)
                    pbPlayCursorSE
                    @scroll = @scrollableLists[@horizontalScroll].length - 1
                    doRefresh = true
                end
            elsif Input.repeat?(Input::DOWN)
                if @scroll < @scrollableLists[@horizontalScroll].length - 1
                    pbPlayCursorSE
                    @scroll += 1
                    doRefresh = true
                elsif Input.trigger?(Input::DOWN)
                    pbPlayCursorSE
                    @scroll = 0
                    doRefresh = true
                end
            elsif Input.repeat?(Input::LEFT)
                if @horizontalScroll > 0
                    pbPlayCursorSE
                    @horizontalScroll -= 1
                    @scroll = 0
                    doRefresh = true
                elsif Input.trigger?(Input::LEFT)
                    pbPlayCursorSE
                    @horizontalScroll = @scrollableLists.length - 1
                    @scroll = 0
                    doRefresh = true
                end
            elsif Input.repeat?(Input::RIGHT)
                if @horizontalScroll < @scrollableLists.length - 1
                    pbPlayCursorSE
                    @horizontalScroll += 1
                    @scroll = 0
                    doRefresh = true
                elsif Input.trigger?(Input::RIGHT)
                    pbPlayCursorSE
                    @horizontalScroll = 0
                    @scroll = 0
                    doRefresh = true
                end
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                @scroll = -1
                drawPage(@page)
                break
            end
            drawPage(@page) if doRefresh
        end
        @sprites["leftarrow"].visible = false
        @sprites["rightarrow"].visible = false
    end

    def pbScrollEvolutions
        @evolutionIndex = 0
        drawPage(@page)
        loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.repeat?(Input::UP) && @evolutionIndex > 0
                pbPlayCursorSE
                @evolutionIndex -= 1
                dorefresh = true
            elsif Input.repeat?(Input::DOWN) && @evolutionIndex < @evolutionsArray.length - 1
                pbPlayCursorSE
                @evolutionIndex += 1
                dorefresh = true
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                otherSpecies = @evolutionsArray[@evolutionIndex][0]
                return otherSpecies
            end
            drawPage(@page) if dorefresh
        end
        return nil
    end

    def drawPageDEBUG
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_evolution"))
        overlay = @sprites["overlay"].bitmap
        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            coordinateY = 54

            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Analysis of {1}", @title), base, shadow)
            coordinateY += 34

            # Use count
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Use count: #{@dexlist[@index][16]}, #{@dexlist[@index][17]}"), base,
    shadow)
            coordinateY += 32

            # Earliest level accessible
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Earliest level: #{fSpecies.earliest_available}"), base,
              shadow)
            coordinateY += 32

            # Speed tier

            numberFaster = 0
            total = 0
            mySpeed = fSpecies.base_stats[:SPEED]
            GameData::Species.each do |otherSpeciesData|
                next if otherSpeciesData.form != 0
                next if otherSpeciesData.get_evolutions.length > 0
                next if isLegendary(otherSpeciesData.id) || isQuarantined(otherSpeciesData.id)
                numberFaster += 1 if mySpeed > otherSpeciesData.base_stats[:SPEED]
                total += 1
            end

            fasterThanPercentOfMetaGame = numberFaster.to_f / total.to_f
            fasterThanPercentOfMetaGame = (fasterThanPercentOfMetaGame * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Faster than #{fasterThanPercentOfMetaGame}% of final evos"), base,
              shadow)
            coordinateY += 32

            # Pokeball catch chance
            totalHP = calcHPGlobal(fSpecies.base_stats[:HP], 40, 8)
            currentHP = (totalHP * 0.15).floor
            chanceToCatch = theoreticalCaptureChance(:NONE, currentHP, totalHP, fSpecies.catch_rate)
            chanceToCatch = (chanceToCatch * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("#{chanceToCatch}% chance to catch at level 40, %15 health"), base,
              shadow)
            coordinateY += 32

            # Coverage types

            typesOfCoverage = get_bnb_coverage(fSpecies)

            drawTextEx(overlay, xLeft, coordinateY, 450, 1,
                _INTL("BnB coverage #{typesOfCoverage.length}: #{typesOfCoverage[0..[2, typesOfCoverage.length].min]}"), base, shadow)
            coordinateY += 32
            if typesOfCoverage.length > 2
                for index in 1..10
                    rangeStart = (5 * index) - 2
                    rangeEnd = [rangeStart + 5, typesOfCoverage.length].min
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, typesOfCoverage[rangeStart..rangeEnd].to_s, base,
                shadow)
                    coordinateY += 32
                    break if rangeEnd == typesOfCoverage.length
                end
            end

            # Metagame coverage
            numberCovered = 0
            GameData::Species.each do |otherSpeciesData|
                next if otherSpeciesData.form != 0
                next if otherSpeciesData.get_evolutions.length > 0
                next if isLegendary(otherSpeciesData.id) || isQuarantined(otherSpeciesData.id)

                typesOfCoverage.each do |coverageType|
                    effect = Effectiveness.calculate(coverageType, otherSpeciesData.type1,
    otherSpeciesData.type2)

                    if Effectiveness.super_effective?(effect)
                        numberCovered += 1
                        break
                    end
                end
            end

            coversPercentOfMetaGame = numberCovered.to_f / total.to_f
            coversPercentOfMetaGame = (coversPercentOfMetaGame * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Covers #{coversPercentOfMetaGame}% of final evos"), base,
              shadow)
            coordinateY += 32

            drawTextEx(overlay, xLeft, coordinateY, 450, 6, _INTL("Notes: #{fSpecies.notes}"), base, shadow)
            coordinateY += 32
        end
    end

    def pbScene
		formIndex = 0
		for i in 0...@available.length
			if @available[i][1] == @gender && @available[i][2] == @form
				formIndex = i
				break
			end
		end
		oldFormIndex = formIndex

        GameData::Species.play_cry_from_species(@species, @form)
        highestLeftRepeat = 0
        highestRightRepeat = 0
        loop do
			if oldFormIndex != formIndex
				$Trainer.pokedex.set_last_form_seen(@species, @available[formIndex][1], @available[formIndex][2])
				pbUpdateDummyPokemon
				drawPage(@page)
				oldFormIndex = formIndex
			end
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
                GameData::Species.play_cry_from_species(@species, @form) if @page == 1
            elsif Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)
                if @page == 1
                    pbPlayCloseMenuSE
                    break
                elsif @page == 6 || @page == 7 # Move lists
                    pbPlayDecisionSE
                    pbScroll
                    dorefresh = true
                elsif @page == 8 && @evolutionsArray.length > 0   # Evolutions
                    if @linksEnabled
                        pbPlayDecisionSE
                        newSpecies = pbScrollEvolutions
                        return newSpecies if newSpecies
                        @evolutionIndex = -1
                        dorefresh = true
                    else
                        pbPlayBuzzerSE
                    end
                elsif @page == 10
                    if @available.length > 1
                        pbPlayDecisionSE
                        pbChooseForm
                        dorefresh = true
                    end
                end
            elsif Input.repeat?(Input::UP)
				if Input.press?(Input::ACTION)
        			formIndex = (formIndex + @available.length-1) % @available.length
					if formIndex != oldFormIndex
						pbPlayCursorSE
					else
						pbPlayBuzzerSE
					end
				else
					oldindex = @index
					pbGoToPrevious
					if @index != oldindex
						@scroll = -1
						pbUpdateDummyPokemon
						@available = pbGetAvailableForms
						pbSEStop
						(@page == 1) ? GameData::Species.play_cry_from_species(@species, @form) : pbPlayCursorSE
						dorefresh = true
					end
				end
            elsif Input.repeat?(Input::DOWN)
				if Input.press?(Input::ACTION)
        			formIndex = (formIndex + 1) % @available.length
					if formIndex != oldFormIndex
						pbPlayCursorSE
					else
						pbPlayBuzzerSE
					end
				else
					oldindex = @index
					pbGoToNext
					if @index != oldindex
						@scroll = -1
						pbUpdateDummyPokemon
						@available = pbGetAvailableForms
						pbSEStop
						(@page == 1) ? GameData::Species.play_cry_from_species(@species, @form) : pbPlayCursorSE
						dorefresh = true
					end
				end
            elsif Input.repeat?(Input::LEFT)
                highestRightRepeat = 0
                repeats = 1 + Input.time?(Input::LEFT) / 100_000
                if repeats > highestLeftRepeat
                    highestLeftRepeat = repeats
                    oldpage = @page
                    @page -= 1
                    @page = pageTitles.length - 1 if @page < 1 # Wrap around
                    if @page != oldpage
                        @scroll = -1
                        @horizontalScroll = 0
                        pbPlayCursorSE
                        dorefresh = true
                    end
                end
            elsif Input.repeat?(Input::RIGHT)
                highestLeftRepeat = 0
                repeats = 1 + Input.time?(Input::RIGHT) / 100_000
                if repeats > highestRightRepeat
                    highestRightRepeat = repeats
                    oldpage = @page
                    @page += 1
                    @page = 1 if @page > pageTitles.length - 1 # Wrap around
                    if @page != oldpage
                        @scroll = -1
                        @horizontalScroll = 0
                        pbPlayCursorSE
                        dorefresh = true
                    end
                end
            elsif Input.pressex?(:NUMBER_1)
                dorefresh = true if moveToPage(1)
            elsif Input.pressex?(:NUMBER_2)
                dorefresh = true if moveToPage(2)
            elsif Input.pressex?(:NUMBER_3)
                dorefresh = true if moveToPage(3)
            elsif Input.pressex?(:NUMBER_4)
                dorefresh = true if moveToPage(4)
            elsif Input.pressex?(:NUMBER_5)
                dorefresh = true if moveToPage(5)
            elsif Input.pressex?(:NUMBER_6)
                dorefresh = true if moveToPage(6)
            elsif Input.pressex?(:NUMBER_7)
                dorefresh = true if moveToPage(7)
            elsif Input.pressex?(:NUMBER_8)
                dorefresh = true if moveToPage(8)
            elsif Input.pressex?(:NUMBER_9)
                dorefresh = true if moveToPage(9)
            elsif Input.pressex?(:NUMBER_0)
                dorefresh = true if moveToPage(10)
            elsif Input.press?(Input::ACTION) && debugControl
                @scroll = -1
                pbPlayCursorSE
                @page = pageTitles.length
                dorefresh = true
            else
                highestLeftRepeat = 0
                highestRightRepeat = 0
            end
            drawPage(@page) if dorefresh
        end
        return @index
    end

    def moveToPage(pageNum)
        oldpage = @page
        @page = pageNum
        @page = 1 if @page < 1
        @page = 10 if @page > 10
        if @page != oldpage
            @scroll = -1
            pbPlayCursorSE
            return true
        end
        return false
    end
end
