return {

  -- Color overrides:
  colors = {
    -- The default text color
    foreground = "rgb(170,170,170)",
    -- The default background color
    background = "black", -- rgb(0,0,0)

    -- Overrides the cell background color when the current cell is occupied by the
    -- cursor and the cursor style is set to Block
    cursor_bg = "#52ad70",
    -- Overrides the text color when the current cell is occupied by the cursor
    cursor_fg = "black",
    -- Specifies the border color of the cursor when the cursor style is set to Block,
    -- or the color of the vertical or horizontal bar when the cursor style is set to
    -- Bar or Underline.
    cursor_border = "#52ad70",

    -- the foreground color of selected text
    selection_fg = "black",
    -- the background color of selected text
    selection_bg = "#fffacd",

    -- The color of the scrollbar "thumb"; the portion that represents the current viewport
    scrollbar_thumb = "#222222",

    -- The color of the split lines between panes
    split = "#444444",

    ansi = {
      "rgb(0,0,0)",
      "rgb(170,0,0)",
      "rgb(0,170,0)",
      "rgb(170,85,0)",
      "rgb(0,0,170)",
      "rgb(170,0,170)",
      "rgb(0,170,170)",
      "rgb(170,170,170)",
    },
    brights = {
      "rgb(85,85,85)",
      "rgb(255,85,85)",
      "rgb(85,255,85)",
      "rgb(255,255,85)",
      "rgb(85,85,255)",
      "rgb(255,85,255)",
      "rgb(85,255,255)",
      "rgb(255,255,255)",
    },

    -- Arbitrary colors of the palette in the range from 16 to 255
    indexed = {},

    -- Since: 20220319-142410-0fcdea07
    -- When the IME, a dead key or a leader key are being processed and are effectively
    -- holding input pending the result of input composition, change the cursor
    -- to this color to give a visual cue about the compose state.
    compose_cursor = "orange",

    -- Colors for copy_mode and quick_select
    -- available since: 20220807-113146-c2fee766
    -- In copy_mode, the color of the active text is:
    -- 1. copy_mode_active_highlight_* if additional text was selected using the mouse
    -- 2. selection_* otherwise
    copy_mode_active_highlight_bg = { Color = "#000000" },
    -- use `AnsiColor` to specify one of the ansi color palette values
    -- (index 0-15) using one of the names "Black", "Maroon", "Green",
    --  "Olive", "Navy", "Purple", "Teal", "Silver", "Grey", "Red", "Lime",
    -- "Yellow", "Blue", "Fuchsia", "Aqua" or "White".
    copy_mode_active_highlight_fg = { AnsiColor = "Black" },
    copy_mode_inactive_highlight_bg = { Color = "#52ad70" },
    copy_mode_inactive_highlight_fg = { AnsiColor = "White" },

    quick_select_label_bg = { Color = "peru" },
    quick_select_label_fg = { Color = "#ffffff" },
    quick_select_match_bg = { AnsiColor = "Navy" },
    quick_select_match_fg = { Color = "#ffffff" },
  },
  default_cursor_style = "BlinkingBar", -- Harder on graphics, change to SteadyBar?
  -- Milliseconds
  cursor_blink_rate = 3000,

  -- ✨transparency✨ (default - 1)
  window_background_opacity = 0.85,
  -- Don't change my colors pls (default - true, equivalent to BrightAndBold)
  bold_brightens_ansi_colors = "No",

  -- I don´t wanna see no tabs if I aint usin' them. (default - false)
  hide_tab_bar_if_only_one_tab = true,

  -- Point out when input echo is disabled (default)
  detect_password_input = true,

  -- nopety nope nope nope. (default "SystemBeep")
  audible_bell = "Disabled",

  -- Show the title, and keep a border for resizing (default)
  window_decorations = "TITLE|RESIZE",
  -- No padding pls
  -- default: left = '1cell', right = '1cell', top = '0.5cell', bottom = '0.5cell'
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  hide_mouse_cursor_when_typing = false,
}
