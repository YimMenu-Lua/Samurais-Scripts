return function(x, y, text, size, color, font)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT('STRING')
    HUD.SET_TEXT_COLOUR(color[1], color[2], color[3], color[4])
    HUD.SET_TEXT_SCALE(1, size); HUD.SET_TEXT_FONT(font or 7); HUD.SET_TEXT_CENTRE(true)
    HUD.SET_TEXT_OUTLINE(); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end
