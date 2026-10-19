-- LAZNEWB.lua
-- Cleaned and fixed MacroQuest helper script.
-- This version is intentionally syntax-safe, small, and loadable.
-- It includes the guide links, PoK quest list, and a minimal functional UI.

local mq = require('mq')
local imgui = require('ImGui')

local SCRIPT_NAME = 'LAZNEWB'
local WIN_FLAGS = 0
local COL_BUTTON, COL_BUTTON_HOVERED, COL_BUTTON_ACTIVE = 21, 22, 23

local running = true
local windowOpen = true
local windowMinimized = false
local selectedMode = 'guides'
local status = 'Ready. Choose a section.'

local selectedEpicClass = 'Bard'
local selectedEpicTier = 'Pre-1.5'
local selectedPokQuest = 1

local serverGuideLinks = {
    { label = 'Project Lazarus Home', url = 'https://www.lazaruseq.com/' },
    { label = 'Getting Started Guide', url = 'https://www.lazaruseq.com/pages/getting-started-guide' },
    { label = 'Lazarus Quests', url = 'https://www.lazaruseq.com/pages/quests' },
    { label = 'Leveling Guide (reference)', url = 'https://www.lazaruseq.com/pages/leveling-guide' },
    { label = 'Lazarus NPC Guide', url = 'https://www.lazaruseq.com/pages/npcs' },
    { label = 'Lazarus Currencies', url = 'https://www.lazaruseq.com/pages/currencies' },
    { label = 'Tradeskills', url = 'https://www.lazaruseq.com/pages/tradeskills' },
    { label = 'Lazarus Server Rules', url = 'https://www.lazaruseq.com/pages/server-rules' },
    { label = "Almar's Omens Leveling Reference", url = 'https://www.almarsguides.com/eq/leveling/Omens/' },
    { label = 'EQProgression Reference', url = 'https://www.eqprogression.com/' },
    { label = 'E3Next Wiki', url = 'https://github.com/RekkasGit/E3Next/wiki' },
    { label = "Bingle's Guide", url = 'https://docs.google.com/document/d/1Jj3OPbcvPbY2sfW8fVtGxJARPVW9UneCS8Qhe6-pueA/edit?tab=t.0#heading=h.gzwg84jrqihi' },
}

local epicClasses = {
    'Bard', 'Beastlord', 'Berserker', 'Cleric', 'Druid', 'Enchanter',
    'Magician', 'Monk', 'Necromancer', 'Paladin', 'Ranger', 'Rogue',
    'Shadow Knight', 'Shaman', 'Warrior', 'Wizard',
}

local epicTiers = { 'Pre-1.5', '1.0', '1.5', '2.0' }

local classGuideSlugs = {
    bard = 'bard',
    beastlord = 'beastlord',
    berserker = 'berserker',
    cleric = 'cleric',
    druid = 'druid',
    enchanter = 'enchanter',
    magician = 'magician',
    monk = 'monk',
    necromancer = 'necromancer',
    paladin = 'paladin',
    ranger = 'ranger',
    rogue = 'rogue',
    ['shadow knight'] = 'shadow-knight',
    shaman = 'shaman',
    warrior = 'warrior',
    wizard = 'wizard',
}

local pokQuests = {
    { name = 'The Charm of Knowledge', reward = 'Journeyman Lazarus Charm', npc = 'Bolgar', level = 'Check the in-game quest requirements.' },
    { name = "Dronk's Hitlist", reward = 'Lazarus class armor set', npc = 'Dronk', level = 'Available at level 1.' },
    { name = "Montolio's Memories", reward = 'Ornate Lazarus class armor set', npc = 'Montolio', level = 'Level 30 required.' },
    { name = "Vierna's Hate", reward = 'Intricate Lazarus class armor set', npc = 'Vierna', level = 'Level 50 required.' },
    { name = 'Gift of Knowledge', reward = 'Gift of Knowledge', npc = 'Azray Velfor', level = 'Check the in-game quest requirements.' },
    { name = 'The Door Remembers', reward = 'Check the in-game quest steps.', npc = 'Keiran', level = 'Follow the quest dialogue and task requirements.' },
}

local porterDestinations = {
    'poknowledge',
    'freeporttemple',
    'abysmal',
    'barindu',
    'cobaltscar',
    'dawnshroud',
    'dranik',
    'draniksscar',
    'fieldofbone',
    'fungusgrove',
    'gunthak',
    'iceclad',
    'jaggedpine',
    'nadox',
    'natimbi',
    'northkarana',
    'paludal',
    'qinimi',
    'sharvahl',
    'skyfire',
    'timorous',
    'wakening',
    'wallofslaughter',
    'westwastes',
}

local pokServiceTargets = {
    { label = 'Shady Merchant', npc = 'A Shady Merchant' },
    { label = 'Tribute Master', npc = 'Enva' },
    { label = 'BUFF LADY', npc = 'Rubrae' },
    { label = 'LDoN Magus Porter', npc = 'Magus Alaria' },
}

local function safeTlo(fn, fallback)
    local ok, value = pcall(fn)
    if ok and value ~= nil then
        return value
    end
    return fallback
end

local function numberTlo(fn, fallback)
    local value = safeTlo(fn, fallback)
    return tonumber(value) or fallback
end

local function currentName()
    return tostring(safeTlo(function() return mq.TLO.Me.DisplayName() end, ''))
end

local function currentClass()
    return tostring(safeTlo(function() return mq.TLO.Me.Class() end, 'Unknown'))
end

local function currentZone()
    return tostring(safeTlo(function() return mq.TLO.Zone.ShortName() end, 'Unknown')):lower()
end

local function setStatus(message)
    status = tostring(message or '')
    mq.cmdf('/echo [LAZNEWB] %s', status)
end

local function openExternalUrl(url, text)
    if safeTlo(function() return mq.TLO.Plugin('MQ2Web').IsLoaded() end, false) == true then
        mq.cmdf('/web %s', url)
    else
        mq.cmdf('/exec rundll32.exe "url.dll,FileProtocolHandler %s" bg', url)
    end
    setStatus(text or 'Opened external guide.')
end

local function openServerGuide(index)
    local guide = serverGuideLinks[index]
    if guide then
        openExternalUrl(guide.url, 'Opened ' .. guide.label .. '.')
    end
end

local function openAllakhazamHome()
    openExternalUrl('https://everquest.allakhazam.com/', 'Opened Allakhazam home.')
end

local function setMode(mode)
    if mode == 'epic' or mode == 'pok' or mode == 'guides' then
        selectedMode = mode
        setStatus('Mode set to ' .. mode .. '.')
    end
end

local function drawCombo(label, preview, itemsCallback)
    if imgui.BeginCombo(label, preview) then
        local ok, err = pcall(itemsCallback)
        imgui.EndCombo()
        if not ok then
            error(err)
        end
    end
end

local function drawModeButtons()
    imgui.Spacing()
    local entries = {
        { key = 'epic', label = 'Class Epic', c = { 0.70, 0.12, 0.16 } },
        { key = 'pok', label = 'PoK Quests', c = { 0.42, 0.18, 0.62 } },
        { key = 'guides', label = 'Guides', c = { 0.20, 0.35, 0.55 } },
    }

    for i, entry in ipairs(entries) do
        local c = entry.c
        imgui.PushStyleColor(COL_BUTTON, c[1], c[2], c[3], 1.0)
        imgui.PushStyleColor(COL_BUTTON_HOVERED, math.min(c[1] + 0.13, 1), math.min(c[2] + 0.13, 1), math.min(c[3] + 0.13, 1), 1.0)
        imgui.PushStyleColor(COL_BUTTON_ACTIVE, math.min(c[1] + 0.20, 1), math.min(c[2] + 0.20, 1), math.min(c[3] + 0.20, 1), 1.0)

        if imgui.Button(entry.label .. '##mode_' .. entry.key, 185, 29) then
            setMode(entry.key)
        end

        imgui.PopStyleColor(3)
        if i < #entries then
            imgui.SameLine()
        end
    end
end

local function drawGuidePanel()
    imgui.Text('Project Lazarus and EQ reference links')
    imgui.TextWrapped('Open a guide or reference page directly from this script.')

    for i, guide in ipairs(serverGuideLinks) do
        if imgui.Button(guide.label .. '##server_' .. i, 240, 26) then
            openServerGuide(i)
        end
        if i % 2 == 1 and i < #serverGuideLinks then
            imgui.SameLine()
        end
    end

    imgui.Separator()
    if imgui.Button('Allakhazam Home##allakhazam', 200, 26) then
        openAllakhazamHome()
    end

    imgui.Separator()
    if imgui.Button('Lazarus Quest List##quickquests', 220, 26) then
        openServerGuide(3)
    end
end

local function drawEpicPanel()
    imgui.Text('Class Epic guide finder')
    imgui.TextWrapped('Select a class and tier to open the matching Lazarus guide.')

    imgui.Text('Select class:')
    for i, className in ipairs(epicClasses) do
        if imgui.Button(className .. (selectedEpicClass == className and ' *' or '') .. '##class_' .. i, 110, 24) then
            selectedEpicClass = className
            setStatus('Selected ' .. className .. '.')
        end
        if i % 6 ~= 0 and i < #epicClasses then
            imgui.SameLine()
        end
    end

    imgui.Text('Select tier:')
    for i, tier in ipairs(epicTiers) do
        if imgui.Button(tier .. (selectedEpicTier == tier and ' *' or '') .. '##tier_' .. i, 120, 24) then
            selectedEpicTier = tier
            setStatus(selectedEpicClass .. ' ' .. tier .. ' guide selected.')
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end

    imgui.Separator()

    local classSlug = classGuideSlugs[selectedEpicClass:lower()]
    if classSlug and imgui.Button('Open Lazarus ' .. selectedEpicClass .. ' Guide##classguide', 240, 26) then
        openExternalUrl('https://www.lazaruseq.com/pages/' .. classSlug, 'Opened the Lazarus ' .. selectedEpicClass .. ' guide.')
    end

    if imgui.Button('Lazarus Quests##epicquests', 180, 26) then
        openServerGuide(3)
    end
    imgui.SameLine()
    if imgui.Button('Allakhazam##epicalla', 170, 26) then
        openAllakhazamHome()
    end
end

local function drawPokPanel()
    imgui.Text('Plane of Knowledge quest helper')
    imgui.TextWrapped('Use the quest list below to select a known PoK quest and open the guide.')

    for i, quest in ipairs(pokQuests) do
        if imgui.Button(quest.name .. '##pokquest_' .. i, 300, 26) then
            selectedPokQuest = i
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end

    local quest = pokQuests[selectedPokQuest]
    if quest then
        imgui.Separator()
        imgui.Text('Selected quest: ' .. quest.name)
        imgui.Text('NPC: ' .. quest.npc)
        imgui.Text('Reward: ' .. quest.reward)
        imgui.TextWrapped(quest.level)

        if imgui.Button('Open Lazarus Quests##pokquestlist', 200, 26) then
            openServerGuide(3)
        end
        imgui.SameLine()
        if imgui.Button('Open Allakhazam##pokallakhazam', 190, 26) then
            openExternalUrl('https://everquest.allakhazam.com/search.html?q=' .. quest.name, 'Opened Allakhazam for ' .. quest.name .. '.')
        end
    end

    imgui.Separator()
    imgui.Text('PoK service targets')
    for i, target in ipairs(pokServiceTargets) do
        if imgui.Button(target.label .. '##pokservice_' .. i, 200, 26) then
            setStatus('PoK target selected: ' .. target.label .. ' (' .. target.npc .. ')')
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end
end

local function drawPorterPanel()
    imgui.Separator()
    imgui.Text('Simple travel helpers')

    local selectedPort = porterDestinations[1] or 'poknowledge'
    drawCombo('Destination##porter', selectedPort, function()
        for i, zone in ipairs(porterDestinations) do
            if imgui.Selectable(zone, i == 1) then
                -- placeholder selection
            end
        end
    end)

    if imgui.Button('Go to selected destination##travel', 200, 26) then
        setStatus('Travel target set.')
    end
end

local function drawWindow()
    if not windowOpen then
        return
    end

    if windowMinimized then
        imgui.SetNextWindowSize(250, 58, 2)
        imgui.PushStyleVar(0, 4)
        imgui.PushStyleColor(1, 1, 1, 1, 1)
        local open, draw = imgui.Begin('LAZNEWB##mini', windowOpen, WIN_FLAGS)
        windowOpen = open
        if draw then
            if imgui.Button('Restore##restoremini', 160, 26) then
                windowMinimized = false
            end
            imgui.SameLine()
            if imgui.Button('X##closemini', 25, 26) then
                windowOpen = false
            end
        end
        imgui.End()
        imgui.PopStyleColor()
        imgui.PopStyleVar()
        return
    end

    imgui.SetNextWindowSize(810, 780, 2)
    imgui.PushStyleVar(0, 4)
    imgui.PushStyleColor(1, 1, 1, 1, 1)

    local open, draw = imgui.Begin('LAZNEWB##main', windowOpen, WIN_FLAGS)
    windowOpen = open

    if draw then
        local meName = currentName()
        local meClass = currentClass()
        local zone = currentZone()
        imgui.Text(string.format('%s | %s | %s', meName ~= '' and meName or 'Not in game', meClass, zone))

        if imgui.Button('Minimize##minimize', 105, 24) then
            windowMinimized = true
        end
        imgui.SameLine()
        if imgui.Button('Stop##stop', 90, 24) then
            running = false
        end

        imgui.Separator()
        drawModeButtons()

        if selectedMode == 'epic' then
            drawEpicPanel()
        elseif selectedMode == 'pok' then
            drawPokPanel()
        else
            drawGuidePanel()
        end

        drawPorterPanel()
        imgui.Separator()
        imgui.TextWrapped(status)
    end

    imgui.End()
    imgui.PopStyleColor()
    imgui.PopStyleVar()
end

local function commandHandler(...)
    local args = {}
    for i = 1, select('#', ...) do
        args[#args + 1] = tostring(select(i, ...) or '')
    end
    local cmd = table.concat(args, ' '):gsub('^%s+', ''):gsub('%s+$', '')
    local lower = cmd:lower()

    if lower == '' or lower == 'toggle' then
        windowOpen = not windowOpen
    elseif lower == 'hide' then
        windowOpen = false
    elseif lower == 'show' or lower == 'restore' then
        windowOpen = true
        windowMinimized = false
    elseif lower == 'minimize' or lower == 'mini' then
        windowOpen = true
        windowMinimized = true
    elseif lower == 'epic' or lower == 'pok' or lower == 'guides' then
        setMode(lower)
        windowOpen = true
    elseif lower == 'stop' or lower == 'shutdown' or lower == 'quit' then
        running = false
    elseif lower == 'help' then
        mq.cmd('/echo /laznewb [show|hide|toggle|minimize|restore|epic|pok|guides|stop|help]')
    else
        mq.cmd('/echo Unknown /laznewb command. Try /laznewb help')
    end
end

mq.bind('/laznewb', commandHandler)
mq.imgui.init(SCRIPT_NAME, drawWindow)

mq.cmd('/echo LAZNEWB loaded.')

while running do
    mq.doevents()
    mq.delay(100)
end

mq.unbind('/laznewb')
mq.cmd('/echo LAZNEWB unloaded.')
