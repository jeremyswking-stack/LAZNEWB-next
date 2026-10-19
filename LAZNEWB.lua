-- LAZNEWB.lua
-- MacroQuest helper UI styled to match the provided screenshots.
-- Clean, syntax-safe version with bright blue buttons and dark theme.

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
local selectedEpicClass = 'Paladin'
local selectedEpicTier = '1.0'
local selectedPokQuest = 1

local serverGuideLinks = {
    { label = 'Project Lazarus Home', url = 'https://www.lazaruseq.com/' },
    { label = 'Getting Started Guide', url = 'https://www.lazaruseq.com/pages/getting-started-guide' },
    { label = 'Lazarus Quests', url = 'https://www.lazaruseq.com/pages/quests' },
    { label = 'Leveling Guide (reference)', url = 'https://www.lazaruseq.com/pages/leveling-guide' },
    { label = 'Allaclone Items and Zones', url = 'https://www.lazaruseq.com/alla' },
    { label = 'Lazarus NPC Guide', url = 'https://www.lazaruseq.com/pages/npcs' },
    { label = 'Free Starting AAs', url = 'https://www.lazaruseq.com/pages/free-starting-aas' },
    { label = 'Lazarus Currencies', url = 'https://www.lazaruseq.com/pages/currencies' },
    { label = 'Type 7 Hotzone Augments', url = 'https://www.lazaruseq.com/pages/type-7-hotzone-augments' },
    { label = 'Type 3 Augments', url = 'https://www.lazaruseq.com/pages/type-3-augments' },
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
    'Shadow Knight', 'Shaman', 'Warrior', 'Wizard'
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
    { name = 'The Charm of Knowledge', npc = 'Bolgar', reward = 'Journeyman Lazarus Charm', level = 'Check the in-game quest requirements.' },
    { name = "Dronk's Hitlist", npc = 'Dronk', reward = 'Lazarus class armor set', level = 'Available at level 1.' },
    { name = "Montolio's Memories", npc = 'Montolio', reward = 'Ornate Lazarus class armor set', level = 'Level 30 required.' },
    { name = "Vierna's Hate", npc = 'Vierna', reward = 'Intricate Lazarus class armor set', level = 'Level 50 required.' },
    { name = 'Gift of Knowledge', npc = 'Azray Velfor', reward = 'Gift of Knowledge', level = 'Check the in-game quest requirements.' },
    { name = 'The Door Remembers', npc = 'Keiran', reward = 'Check the in-game quest steps.', level = 'Follow the quest dialogue and task requirements.' },
}

local pokServiceTargets = {
    { label = 'GOTO Shady Merchant', npc = 'A Shady Merchant' },
    { label = 'GOTO Tribute Master', npc = 'Enva' },
    { label = 'GOTO BUFF LADY', npc = 'Rubrae' },
    { label = 'GOTO LDoN Magus Porter', npc = 'Magus Alaria' },
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

local function styleBlueButtons()
    imgui.PushStyleColor(COL_BUTTON, 0.20, 0.35, 0.55, 1.0)
    imgui.PushStyleColor(COL_BUTTON_HOVERED, 0.34, 0.52, 0.77, 1.0)
    imgui.PushStyleColor(COL_BUTTON_ACTIVE, 0.15, 0.28, 0.46, 1.0)
end

local function styleRedButton()
    imgui.PushStyleColor(COL_BUTTON, 0.82, 0.12, 0.12, 1.0)
    imgui.PushStyleColor(COL_BUTTON_HOVERED, 0.95, 0.24, 0.24, 1.0)
    imgui.PushStyleColor(COL_BUTTON_ACTIVE, 0.70, 0.08, 0.08, 1.0)
end

local function styleOrangeButton()
    imgui.PushStyleColor(COL_BUTTON, 0.96, 0.52, 0.10, 1.0)
    imgui.PushStyleColor(COL_BUTTON_HOVERED, 1.00, 0.62, 0.20, 1.0)
    imgui.PushStyleColor(COL_BUTTON_ACTIVE, 0.87, 0.42, 0.05, 1.0)
end

local function styleGreenButton()
    imgui.PushStyleColor(COL_BUTTON, 0.00, 0.72, 0.18, 1.0)
    imgui.PushStyleColor(COL_BUTTON_HOVERED, 0.16, 0.88, 0.30, 1.0)
    imgui.PushStyleColor(COL_BUTTON_ACTIVE, 0.00, 0.54, 0.15, 1.0)
end

local function styleModeButtons()
    local entries = {
        { key = 'epic', label = 'Class Epic', c = { 0.82, 0.10, 0.10 } },
        { key = 'pok', label = 'PoK Quests', c = { 0.45, 0.20, 0.62 } },
        { key = 'guides', label = 'Guides', c = { 0.20, 0.35, 0.55 } },
    }

    for i, entry in ipairs(entries) do
        local c = entry.c
        imgui.PushStyleColor(COL_BUTTON, c[1], c[2], c[3], 1.0)
        imgui.PushStyleColor(COL_BUTTON_HOVERED, math.min(c[1] + 0.14, 1), math.min(c[2] + 0.14, 1), math.min(c[3] + 0.14, 1), 1.0)
        imgui.PushStyleColor(COL_BUTTON_ACTIVE, math.min(c[1] + 0.20, 1), math.min(c[2] + 0.20, 1), math.min(c[3] + 0.20, 1), 1.0)

        if imgui.Button(entry.label .. '##mode_' .. entry.key, 180, 30) then
            setMode(entry.key)
        end

        imgui.PopStyleColor(3)
        if i < #entries then
            imgui.SameLine()
        end
    end
end

local function drawGuidePanel()
    imgui.Text('Project Lazarus and EverQuest guides')
    imgui.TextWrapped('Open a server guide or Allakhazam directly for quest, item, drop, and zone references.')

    styleBlueButtons()
    for i, guide in ipairs(serverGuideLinks) do
        if imgui.Button(guide.label .. '##server_' .. i, 220, 36) then
            openServerGuide(i)
        end
        if i % 2 == 1 and i < #serverGuideLinks then
            imgui.SameLine()
        end
    end
    imgui.PopStyleColor(3)

    imgui.Separator()
    local blueButtonWidth = 220
    styleBlueButtons()
    if imgui.Button('Allakhazam Home##allakhazam', blueButtonWidth, 36) then
        openAllakhazamHome()
    end
    imgui.PopStyleColor(3)

    imgui.Separator()
    styleBlueButtons()
    if imgui.Button('Lazarus Quest List##quickquests', blueButtonWidth, 36) then
        openServerGuide(3)
    end
    imgui.PopStyleColor(3)
end

local function drawEpicPanel()
    imgui.Text('Class Epic guide finder')
    imgui.TextWrapped('Choose the character, class, and epic tier. This section provides walkthrough references only; it does not run the epic, fight, or loot.')

    local charName = currentName()
    if charName == '' then
        charName = 'Silentpal'
    end

    imgui.Text(charName)

    imgui.Text('Select the epic class:')
    styleBlueButtons()
    for i, className in ipairs(epicClasses) do
        if imgui.Button(className .. (selectedEpicClass == className and ' *' or '') .. '##class_' .. i, 120, 24) then
            selectedEpicClass = className
            setStatus('Selected class: ' .. className)
        end
        if i % 6 ~= 0 and i < #epicClasses then
            imgui.SameLine()
        end
    end
    imgui.PopStyleColor(3)

    imgui.Text('Select the guide tier:')
    styleBlueButtons()
    for i, tier in ipairs(epicTiers) do
        if imgui.Button(tier .. (selectedEpicTier == tier and ' *' or '') .. '##tier_' .. i, 120, 24) then
            selectedEpicTier = tier
            setStatus('Selected tier: ' .. tier)
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end
    imgui.PopStyleColor(3)

    imgui.Separator()
    imgui.Text('Guide: ' .. selectedEpicClass .. ' ' .. selectedEpicTier .. ' Epic | character: ' .. charName)

    styleBlueButtons()
    if imgui.Button('Lazarus Quest Guide##guide_btn', 220, 32) then
        openServerGuide(3)
    end
    imgui.SameLine()
    if imgui.Button('Allakhazam Home##alla_btn', 180, 32) then
        openAllakhazamHome()
    end
    imgui.PopStyleColor(3)

    local classSlug = classGuideSlugs[selectedEpicClass:lower()]
    if classSlug and imgui.Button('Open Lazarus ' .. selectedEpicClass .. ' Guide##classguide', 240, 32) then
        openExternalUrl('https://www.lazaruseq.com/pages/' .. classSlug, 'Opened the Lazarus ' .. selectedEpicClass .. ' guide.')
    end
end

local function drawPokPanel()
    imgui.Text('Plane of Knowledge quest helper')
    imgui.TextWrapped('Select a quest to see its NPC and reward. The helper can port and navigate the group, hail the NPC, and accept an exact matching task offer on the driver. It does not fight or loot.')

    styleOrangeButton()
    for i, quest in ipairs(pokQuests) do
        if imgui.Button(quest.name .. '##pokquest_' .. i, 300, 30) then
            selectedPokQuest = i
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end
    imgui.PopStyleColor(3)

    local quest = pokQuests[selectedPokQuest]
    if quest then
        imgui.Separator()
        imgui.Text('NPC: ' .. quest.npc)
        imgui.Text('Reward: ' .. quest.reward)
        imgui.TextWrapped(quest.level)

        styleBlueButtons()
        if imgui.Button('Open Lazarus Quests##pokquestlist', 200, 32) then
            openServerGuide(3)
        end
        imgui.SameLine()
        if imgui.Button('Search Quest on Allakhazam##pokallakhazam', 230, 32) then
            openExternalUrl('https://everquest.allakhazam.com/search.html?q=' .. quest.name, 'Opened Allakhazam for ' .. quest.name .. '.')
        end
        imgui.PopStyleColor(3)
    end

    imgui.Separator()
    imgui.Text('PoK services and LDoN NPCs')
    styleOrangeButton()
    for i, target in ipairs(pokServiceTargets) do
        if imgui.Button(target.label .. '##pokservice_' .. i, 220, 30) then
            setStatus('PoK target selected: ' .. target.label .. ' (' .. target.npc .. ')')
        end
        if i % 2 == 1 then
            imgui.SameLine()
        end
    end
    imgui.PopStyleColor(3)
end

local function drawHeader()
    imgui.PushStyleColor(1, 0.10, 0.18, 0.28, 1.0)
    imgui.PushStyleColor(2, 0.14, 0.22, 0.32, 1.0)
    imgui.PushStyleColor(3, 0.10, 0.18, 0.28, 1.0)

    imgui.BeginChild('header', 0, 38, true)
    imgui.Text('LAZNEWB')
    imgui.SameLine()
    if imgui.Button('X##closex', 22, 22) then
        running = false
    end
    imgui.EndChild()

    imgui.PopStyleColor(3)
end

local function drawWindow()
    if not windowOpen then
        return
    end

    if windowMinimized then
        imgui.SetNextWindowSize(250, 50, 2)
        imgui.Begin('LAZNEWB##mini', true, WIN_FLAGS)
        if imgui.Button('Restore##restoremini', 160, 26) then
            windowMinimized = false
        end
        imgui.End()
        return
    end

    imgui.SetNextWindowSize(820, 760, 2)
    imgui.PushStyleVar(0, 0)
    imgui.PushStyleColor(1, 0.05, 0.07, 0.10, 1.0)
    local open, draw = imgui.Begin('LAZNEWB', windowOpen, WIN_FLAGS)
    windowOpen = open

    if draw then
        drawHeader()

        local meName = currentName()
        if meName == '' then
            meName = 'Silentpal'
        end

        -- top row controls
        styleGreenButton()
        if imgui.Button('Minimize##minimize', 100, 30) then
            windowMinimized = true
        end
        imgui.PopStyleColor(3)

        imgui.SameLine()
        imgui.Text('Driver: ' .. meName)

        imgui.Separator()

        -- mode buttons
        styleModeButtons()
        imgui.Separator()

        if selectedMode == 'guides' then
            drawGuidePanel()
        elseif selectedMode == 'pok' then
            drawPokPanel()
        else
            drawEpicPanel()
        end

        imgui.Separator()
        imgui.TextWrapped(status)

        styleRedButton()
        if imgui.Button('STOP LAZNEWB##stop', 150, 30) then
            running = false
        end
        imgui.PopStyleColor(3)
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

mg.cmd('/echo LAZNEWB loaded.')

while running do
    mq.doevents()
    mq.delay(100)
end

mq.unbind('/laznewb')
mq.cmd('/echo LAZNEWB unloaded.')
