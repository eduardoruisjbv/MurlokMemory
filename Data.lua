local _, MM = ...

MM.modes = {
    { key = "m+", label = "M+" },
    { key = "solo", label = "Solo" },
    { key = "2v2", label = "2v2" },
    { key = "3v3", label = "3v3" },
    { key = "rbg", label = "RBG" },
}

MM.classSlugs = {
    DEATHKNIGHT = "death-knight",
    DEMONHUNTER = "demon-hunter",
    DRUID = "druid",
    EVOKER = "evoker",
    HUNTER = "hunter",
    MAGE = "mage",
    MONK = "monk",
    PALADIN = "paladin",
    PRIEST = "priest",
    ROGUE = "rogue",
    SHAMAN = "shaman",
    WARLOCK = "warlock",
    WARRIOR = "warrior",
}

MM.specSlugs = {
    [62] = "arcane", [63] = "fire", [64] = "frost",
    [65] = "holy", [66] = "protection", [70] = "retribution",
    [71] = "arms", [72] = "fury", [73] = "protection",
    [102] = "balance", [103] = "feral", [104] = "guardian", [105] = "restoration",
    [250] = "blood", [251] = "frost", [252] = "unholy",
    [253] = "beast-mastery", [254] = "marksmanship", [255] = "survival",
    [256] = "discipline", [257] = "holy", [258] = "shadow",
    [259] = "assassination", [260] = "outlaw", [261] = "subtlety",
    [262] = "elemental", [263] = "enhancement", [264] = "restoration",
    [265] = "affliction", [266] = "demonology", [267] = "destruction",
    [268] = "brewmaster", [269] = "windwalker", [270] = "mistweaver",
    [577] = "havoc", [581] = "vengeance", [1467] = "devastation",
    [1468] = "preservation", [1473] = "augmentation", [1480] = "devourer",
}
