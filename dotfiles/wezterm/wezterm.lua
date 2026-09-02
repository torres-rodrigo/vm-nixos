local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = wezterm.config_builder()

config.enable_wayland = false
config.automatically_reload_config = true

config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'

config.max_fps = 144
config.animation_fps = 144

config.color_scheme = 'Tomorrow Night (Gogh)'

config.font = wezterm.font_with_fallback { 'Aspergers', 'Autism', 'CaskaydiaCove NF SemiBold' }
config.font_size = 16
config.line_height = 1.0

config.adjust_window_size_when_changing_font_size = false
config.enable_scroll_bar = false
config.use_resize_increments = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_and_split_indices_are_zero_based = true
config.default_workspace = 'master'
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.85
config.window_padding = {
    left = 6.5,
    right = 0.0,
    top = 5.5,
    bottom = 0.0
}
config.window_content_alignment = {
    horizontal = 'Left',
    vertical = 'Top',
}

config.scrollback_lines = 10000
config.alternate_buffer_wheel_scroll_speed = 1

-- Keymaps
local act = wezterm.action
local wezterm_cli = wezterm.executable_dir .. '/wezterm'

local master_workspace = {
    name = 'master',
    spawn = {},
}

local workspace_slots = { }

local last_workspace = nil
local previous_workspace = nil
local workspace_order = {}
local workspace_seen = {}

local function shallow_copy(tbl)
    local copy = {}
    for k, v in pairs(tbl or {}) do
        copy[k] = v
    end
    return copy
end

local configured_workspaces = {}

local function declare_configured_workspace(spec)
    local spawn = shallow_copy(spec.spawn)
    spawn.workspace = spec.name
    configured_workspaces[spec.name] = spawn
end

declare_configured_workspace(master_workspace)
for _, spec in pairs(workspace_slots) do
    declare_configured_workspace(spec)
end

local function workspace_exists(name)
    for _, workspace in ipairs(mux.get_workspace_names()) do
        if workspace == name then
            return true
        end
    end
    return false
end

local function remember_workspace(name)
    if not name or name == 'master' or workspace_seen[name] then
        return
    end

    workspace_seen[name] = true
    table.insert(workspace_order, name)
end

local function prune_workspace_order()
    local active_workspaces = {}
    local order = {}

    for _, workspace in ipairs(mux.get_workspace_names()) do
        active_workspaces[workspace] = true
    end

    workspace_seen = {}
    for _, workspace in ipairs(workspace_order) do
        if active_workspaces[workspace] then
            workspace_seen[workspace] = true
            table.insert(order, workspace)
        end
    end

    workspace_order = order
end

local function pane_ids_for_workspace(name)
    local pane_ids = {}

    for _, mux_window in ipairs(mux.all_windows()) do
        if mux_window:get_workspace() == name then
            for _, tab in ipairs(mux_window:tabs()) do
                for _, pane in ipairs(tab:panes()) do
                    table.insert(pane_ids, pane:pane_id())
                end
            end
        end
    end

    return pane_ids
end

local function kill_panes(pane_ids)
    for _, pane_id in ipairs(pane_ids) do
        local success, _, stderr = wezterm.run_child_process {
            wezterm_cli,
            'cli',
            'kill-pane',
            '--pane-id',
            tostring(pane_id),
        }
        if not success then
            wezterm.log_error('failed to kill pane ' .. tostring(pane_id) .. ': ' .. stderr)
        end
    end
end

local function spawn_configured_workspace(name, overrides)
    local spawn = shallow_copy(overrides)
    for k, v in pairs(configured_workspaces[name]) do
        spawn[k] = v
    end
    mux.spawn_window(spawn)
end

local function fallback_workspace_for_delete(name)
    if previous_workspace and previous_workspace ~= name and workspace_exists(previous_workspace) then
        return previous_workspace
    end

    return 'master'
end

local function reset_or_delete_workspace(name, window)
    local old_pane_ids = pane_ids_for_workspace(name)

    if configured_workspaces[name] then
        spawn_configured_workspace(name)
        mux.set_active_workspace(name)
    elseif window:active_workspace() == name then
        mux.set_active_workspace(fallback_workspace_for_delete(name))
    end

    kill_panes(old_pane_ids)
end

local function workspace_choices()
    local choices = {}

    for _, workspace in ipairs(mux.get_workspace_names()) do
        table.insert(choices, { id = workspace, label = workspace })
    end

    table.sort(choices, function(a, b)
        return a.label < b.label
    end)

    return choices
end

local function switch_to_configured_workspace(name)
    local spawn = shallow_copy(configured_workspaces[name])
    spawn.workspace = nil

    return act.SwitchToWorkspace {
        name = name,
        spawn = spawn,
    }
end

local function workspace_name_for_slot(slot)
    local spec = workspace_slots[slot]
    if spec then
        return spec.name
    end

    prune_workspace_order()
    return workspace_order[slot - 1]
end

local function switch_to_workspace_slot(slot)
    return wezterm.action_callback(function(window, pane)
        local name = workspace_name_for_slot(slot)
        if name then
            if configured_workspaces[name] then
                window:perform_action(switch_to_configured_workspace(name), pane)
            else
                mux.set_active_workspace(name)
            end
        else
            wezterm.log_info('workspace slot ' .. tostring(slot) .. ' has no workspace')
        end
    end)
end

config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = 'NONE',
        action = act.ScrollByLine(-1),
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = 'NONE',
        action = act.ScrollByLine(1),
    },
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = 'CTRL',
        alt_screen = false,
        action = act.ScrollByCurrentEventWheelDelta,
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = 'CTRL',
        alt_screen = false,
        action = act.ScrollByCurrentEventWheelDelta,
    },
}

config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1500 }

-- Defaults
-- Copy on select
-- Ctrl-+ Increase Font
-- Ctrl-- Decrease Font
-- Ctrl-Shift-0 Reset Font (Has some issues)
-- Ctrl-Shift-T = New Tab
-- Ctrl-Shift-V = Paste
-- Ctrl-Shift-P Command pallet
-- Ctrl-Shift-X Activate Copy Mode
-- Ctrl-Shift-U Search and paste char
-- Ctrl-Shift-Space Quick select patterns
config.keys = {
    { key = 'Space', mods = 'LEADER|CTRL', action = act.SendKey { key = 'Space', mods = 'CTRL' }, },
    { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES', }, },
    {
        key = 'n',
        mods = 'LEADER',
        action = act.PromptInputLine {
            description = wezterm.format {
                { Attribute = { Intensity = 'Bold' } },
                { Text = 'Enter name for new workspace' },
            },
            action = wezterm.action_callback(function(window, pane, line)
                if line and line ~= '' then
                    remember_workspace(line)
                    window:perform_action(
                        act.SwitchToWorkspace {
                            name = line,
                        },
                        pane
                    )
                end
            end),
        },
    },
    {
        key = 'd',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, _)
            reset_or_delete_workspace(window:active_workspace(), window)
        end),
    },
    {
        key = 'k',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            window:perform_action(
                act.InputSelector {
                    title = 'Reset/Delete Workspace',
                    choices = workspace_choices(),
                    fuzzy = true,
                    fuzzy_description = 'Workspace: ',
                    action = wezterm.action_callback(function(inner_window, _, id)
                        if id then
                            reset_or_delete_workspace(id, inner_window)
                        end
                    end),
                },
                pane
            )
        end),
    },
    {
        key = 'l',
        mods = 'LEADER',
        action = wezterm.action_callback(function()
            if previous_workspace and workspace_exists(previous_workspace) then
                mux.set_active_workspace(previous_workspace)
            end
        end),
    },

    { key = '1', mods = 'LEADER', action = switch_to_configured_workspace 'master', },

    { key = '`', mods = 'CTRL', action = act.ActivateLastTab },
    { key = '0', mods = 'CTRL', action = act.ActivateTab(0) },
    { key = '1', mods = 'CTRL', action = act.ActivateTab(1) },
    { key = '2', mods = 'CTRL', action = act.ActivateTab(2) },
    { key = '3', mods = 'CTRL', action = act.ActivateTab(3) },
    { key = '5', mods = 'CTRL', action = act.ActivateTab(5) },
    { key = '6', mods = 'CTRL', action = act.ActivateTab(6) },
    { key = '7', mods = 'CTRL', action = act.ActivateTab(7) },
    { key = '4', mods = 'CTRL', action = act.ActivateTab(4) },
    { key = '8', mods = 'CTRL', action = act.ActivateTab(8) },
    { key = '9', mods = 'CTRL', action = act.ActivateTab(9) },

    { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab{confirm=false} },
    { key = 'q', mods = 'ALT', action = act.CloseCurrentPane{confirm=false} },

    { key = '\\', mods = 'ALT', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    { key = '-', mods = 'ALT', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },

    { key = 's', mods = 'CTRL|SHIFT|ALT', action = act.PaneSelect { mode = 'SwapWithActiveKeepFocus' } },

    { key = 'h', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Right' },

    { key = 'UpArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize{ 'Up', 5 } },
    { key = 'DownArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize{ 'Down', 5 } },
    { key = 'LeftArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize{ 'Left', 5 } },
    { key = 'RightArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize{ 'Right', 5 } },

    { key = 't', mods = 'LEADER', action = act.TogglePaneZoomState },

    { key = '2', mods = 'LEADER', action = switch_to_workspace_slot(2)},
    { key = '3', mods = 'LEADER', action = switch_to_workspace_slot(3)},
    { key = '4', mods = 'LEADER', action = switch_to_workspace_slot(4)},
    { key = '5', mods = 'LEADER', action = switch_to_workspace_slot(5)},
    { key = '6', mods = 'LEADER', action = switch_to_workspace_slot(6)},
    { key = '7', mods = 'LEADER', action = switch_to_workspace_slot(7)},
    { key = '8', mods = 'LEADER', action = switch_to_workspace_slot(8)},
    { key = '9', mods = 'LEADER', action = switch_to_workspace_slot(9)},
}

local copy_mode = nil
if wezterm.gui then
    copy_mode = wezterm.gui.default_key_tables().copy_mode

    local clear_and_close = act.Multiple {
      act.ClearSelection,
      act.CopyMode 'Close',
    }

    table.insert(copy_mode, { key = 'Escape', mods = 'NONE', action = clear_and_close, })
    table.insert(copy_mode, { key = 'q', mods = 'NONE', action = clear_and_close, })
    table.insert(copy_mode, { key = 'c', mods = 'CTRL', action = clear_and_close, })
    table.insert(copy_mode, { key = 'g', mods = 'CTRL', action = clear_and_close, })

    table.insert(copy_mode, {
      key = 'y',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(act.CopyMode 'Close', pane)
        window:perform_action(act.ClearSelection, pane)
      end),
    })

    table.insert(copy_mode, {
      key = 'Space',
      mods = 'CTRL|SHIFT',
      action = act.Multiple {
        -- Go back to the previous Output zone start
        act.CopyMode { MoveBackwardZoneOfType = "Output" },
        -- Select that whole Output zone
        act.CopyMode { SetSelectionMode = "SemanticZone" },
      },
    })
end

config.key_tables = {
    copy_mode = copy_mode,
}

wezterm.on('update-right-status', function(window, _)
    local active_workspace = window:active_workspace()
    remember_workspace(active_workspace)

    if active_workspace ~= last_workspace then
        if last_workspace then
            previous_workspace = last_workspace
        end
        last_workspace = active_workspace
    end

    window:set_right_status(active_workspace)
end)

wezterm.on('gui-startup', function(cmd)
    spawn_configured_workspace('master', cmd)
    mux.set_active_workspace 'master'
end)

return config
