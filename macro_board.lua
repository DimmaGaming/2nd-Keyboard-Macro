-- ==========================================
-- LUAMACROS INITIALIZATION
-- ==========================================
lmc.minimizeToTray = true
lmc_minimize()

lmc_device_set_name('MACRO_BOARD', '2B6D316')

-- ==========================================
-- THE CORE MACRO FUNCTION
-- ==========================================
lmc_set_handler('MACRO_BOARD', function(button, direction)

  -- ========================================================
  -- 1. SPLIT-KEY HOLD TRIGGERS (Raw F-Keys, NO MODIFIERS)
  -- Pushing down sends F19-F22. Lifting UP sends F24.
  -- ========================================================

  -- Pause Key (19) -> Scale
  if (button == 19) then
    if (direction == 1) then lmc_send_keys('{F19}')
    elseif (direction == 0) then lmc_send_keys('{F24}') end
    return

  -- Scroll Lock Key (145) -> Position X
  elseif (button == 145) then
    if (direction == 1) then lmc_send_keys('{F20}')
    elseif (direction == 0) then lmc_send_keys('{F24}') end
    return

  -- Home Key (36) -> Position Y
  elseif (button == 36) then
    if (direction == 1) then lmc_send_keys('{F21}')
    elseif (direction == 0) then lmc_send_keys('{F24}') end
    return

  -- Page Up Key (33) -> Rotation
  elseif (button == 33) then
    if (direction == 1) then lmc_send_keys('{F22}')
    elseif (direction == 0) then lmc_send_keys('{F24}') end
    return
  end


  -- ========================================================
  -- 2. STANDARD MACRO KEYS (Taps)
  -- Prevent "Key Up" from firing normal macros a second time
  -- ========================================================
  if (direction == 0) then return end


  -- ========================================================
  -- CATEGORY 1: APP SWITCHERS & PREMIERE MACROS
  -- ========================================================
  if (button == 37) then
    lmc_send_keys('^+%{F13}')

  elseif (button == 38) then
    lmc_send_keys('^+%{F14}')

  elseif (button == 39) then
    lmc_send_keys('^+%{F15}')

  elseif (button == 40) then
    lmc_send_keys('^+%{F16}')

  elseif (button == 34) then
    lmc_send_keys('^+%{F17}')

  elseif (button == 35) then
    lmc_send_keys('^+%{F18}')



  -- ========================================================
  -- CATEGORY 3: WORKSPACE AUTOMATION
  -- ========================================================

  -- Backtick Key (192) -> Enter/Exit Editing Mode (Ctrl+Shift+Alt+F23)
  -- AHK checks physical Ctrl state: no Ctrl = Enter, Ctrl held = Exit
  elseif (button == 192) then
    lmc_send_keys('^+%{F23}')

  -- ========================================================
  -- CATEGORY 4: AUDIO MACROS
  -- ========================================================
  -- Insert Key (45) -> Add Gain +6dB (Ctrl+Alt+F13)
  elseif (button == 45) then
    lmc_send_keys('^%{F13}')

  -- Delete Key (46) -> Add Gain -6dB (Ctrl+Alt+F14)
  elseif (button == 46) then
    lmc_send_keys('^%{F14}')

  end
end)
