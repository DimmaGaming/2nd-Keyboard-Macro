-- 1. Clear any old scripts from memory so they don't conflict
clear()

-- 2. Bind your specific 2nd keyboard silently using its ID
lmc_device_set_name('MACRO_BOARD', '2B6D316')

-- 3. Listen for key presses on that keyboard
lmc_set_handler('MACRO_BOARD', function(button, direction)

    -- direction == 1 means the key was pressed down (0 is released)
    if (direction == 1) then

        -- 👉 THIS PRINTS THE NUMBER TO THE LOG WINDOW AT THE BOTTOM 👈
        print('Key code: ' .. button)

        -- =========================================================
        -- PUT YOUR ACTUAL MACROS BELOW THIS LINE
        -- =========================================================

        -- Example of how to trigger an AutoHotkey v2 script or Premiere Pro shortcut:
        -- if (button == 97) then
        --     lmc_send_keys(z'{F24}')
        -- elseif (button == 98) then
        --     lmc_send_keys('^+!a')
        -- end

    end
end)
