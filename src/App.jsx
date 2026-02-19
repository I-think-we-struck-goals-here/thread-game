import React, { useState, useEffect, useRef } from "react";

// ─────────────────────────────────────────────
// PRACTICE ROUNDS (easier, used during onboarding)
// ─────────────────────────────────────────────
const PRACTICE_ROUNDS = [
  {
    answer: "STAR",
    clues: [
      { word: "WARS", connection: "Star Wars" },
      { word: "SHOOTING", connection: "Shooting star" },
      { word: "FISH", connection: "Starfish" },
      { word: "HOLLYWOOD", connection: "Hollywood star" },
      { word: "NIGHT", connection: "Stars at night" },
    ],
  },
  {
    answer: "FIRE",
    clues: [
      { word: "CAMP", connection: "Campfire" },
      { word: "ALARM", connection: "Fire alarm" },
      { word: "FLY", connection: "Firefly" },
      { word: "WORK", connection: "Fireworks" },
      { word: "DRAGON", connection: "Dragon breathes fire" },
    ],
  },
  {
    answer: "MOON",
    clues: [
      { word: "FULL", connection: "Full moon" },
      { word: "HONEY", connection: "Honeymoon" },
      { word: "WALK", connection: "Moonwalk" },
      { word: "LIGHT", connection: "Moonlight" },
      { word: "LANDING", connection: "Moon landing" },
    ],
  },
];

// ─────────────────────────────────────────────
// DAILY ROUND POOL (44 rounds from 19 February 2026 brief)
// ─────────────────────────────────────────────
const ALL_ROUNDS = [
  {
    answer: "BRIDGE",
    variants: ["BRIDGES", "BRIDGED"],
    clues: [
      { word: "CAPTAIN", connection: "Captain's bridge (on a ship)" },
      { word: "GAP", connection: "Bridge the gap" },
      { word: "BURN", connection: "Burn your bridges" },
      { word: "CARDS", connection: "Bridge (the card game)" },
      { word: "LONDON", connection: "London Bridge" },
    ],
  },
  {
    answer: "CROWN",
    variants: ["CROWNS", "CROWNED"],
    clues: [
      { word: "TRIPLE", connection: "Triple Crown" },
      { word: "MOLDING", connection: "Crown molding" },
      { word: "TOOTH", connection: "Dental crown" },
      { word: "NETFLIX", connection: "The Crown (TV series)" },
      { word: "JEWEL", connection: "Crown Jewels" },
    ],
  },
  {
    answer: "LIGHT",
    variants: ["LIGHTS", "LIT", "LIGHTER", "LIGHTING"],
    clues: [
      { word: "HEARTED", connection: "Light-hearted" },
      { word: "SHED", connection: "Shed light on something" },
      { word: "FEATHER", connection: "Light as a feather" },
      { word: "NORTHERN", connection: "Northern Lights" },
      { word: "GREEN", connection: "Green light" },
    ],
  },
  {
    answer: "RING",
    variants: ["RINGS", "RINGING", "RANG", "RUNG"],
    clues: [
      { word: "HOLLOW", connection: "Ring hollow" },
      { word: "CIRCUS", connection: "Three-ring circus" },
      { word: "BOXING", connection: "Boxing ring" },
      { word: "TOLKIEN", connection: "Lord of the Rings" },
      { word: "WEDDING", connection: "Wedding ring" },
    ],
  },
  {
    answer: "PITCH",
    variants: ["PITCHED", "PITCHES", "PITCHING"],
    clues: [
      { word: "FORK", connection: "Pitchfork" },
      { word: "SALES", connection: "Sales pitch" },
      { word: "PERFECT", connection: "Perfect pitch" },
      { word: "BLACK", connection: "Pitch black" },
      { word: "TENT", connection: "Pitch a tent" },
    ],
  },
  {
    answer: "WAVE",
    variants: ["WAVES", "WAVED", "WAVING"],
    clues: [
      { word: "NEW", connection: "New wave (music/film genre)" },
      { word: "RADIO", connection: "Radio wave" },
      { word: "HEAT", connection: "Heatwave" },
      { word: "STADIUM", connection: "Mexican wave" },
      { word: "OCEAN", connection: "Ocean wave" },
    ],
  },
  {
    answer: "SPRING",
    variants: ["SPRINGS", "SPRANG", "SPRUNG"],
    clues: [
      { word: "CHICKEN", connection: "No spring chicken" },
      { word: "BOARD", connection: "Springboard" },
      { word: "ROLL", connection: "Spring roll" },
      { word: "CLEAN", connection: "Spring cleaning" },
      { word: "WATER", connection: "Spring water" },
    ],
  },
  {
    answer: "SHELL",
    variants: ["SHELLS", "SHELLED"],
    clues: [
      { word: "COMPANY", connection: "Shell company (fraud)" },
      { word: "FISH", connection: "Shellfish" },
      { word: "SHOCK", connection: "Shell shock" },
      { word: "EGG", connection: "Eggshell" },
      { word: "BEACH", connection: "Seashells on the beach" },
    ],
  },
  {
    answer: "KEY",
    variants: ["KEYS"],
    clues: [
      { word: "LOW", connection: "Low-key" },
      { word: "STONE", connection: "Keystone" },
      { word: "BOARD", connection: "Keyboard" },
      { word: "SKELETON", connection: "Skeleton key" },
      { word: "LOCK", connection: "Lock and key" },
    ],
  },
  {
    answer: "PLANT",
    variants: ["PLANTS", "PLANTED", "PLANTING"],
    clues: [
      { word: "RUBBER", connection: "Rubber plant" },
      { word: "HOUSE", connection: "Houseplant" },
      { word: "NUCLEAR", connection: "Nuclear plant" },
      { word: "SEED", connection: "Plant a seed" },
      { word: "POT", connection: "Potted plant" },
    ],
  },
  {
    answer: "BANK",
    variants: ["BANKS", "BANKED", "BANKING"],
    clues: [
      { word: "FOG", connection: "Fog bank" },
      { word: "SNOW", connection: "Snowbank" },
      { word: "BLOOD", connection: "Blood bank" },
      { word: "PIGGY", connection: "Piggy bank" },
      { word: "RIVER", connection: "River bank" },
    ],
  },
  {
    answer: "CAST",
    variants: ["CASTING", "CASTS"],
    clues: [
      { word: "TYPE", connection: "Typecast" },
      { word: "IRON", connection: "Cast iron" },
      { word: "SHADOW", connection: "Cast a shadow" },
      { word: "FISHING", connection: "Cast a line" },
      { word: "POD", connection: "Podcast" },
    ],
  },
  {
    answer: "MATCH",
    variants: ["MATCHES", "MATCHED", "MATCHING"],
    clues: [
      { word: "GRUDGE", connection: "Grudge match" },
      { word: "BOOK", connection: "Matchbook" },
      { word: "PERFECT", connection: "Perfect match" },
      { word: "TENNIS", connection: "Tennis match" },
      { word: "FIRE", connection: "Strike a match" },
    ],
  },
  {
    answer: "FALL",
    variants: ["FALLS", "FELL", "FALLEN", "FALLING"],
    clues: [
      { word: "ANGEL", connection: "Fallen angel" },
      { word: "FLAT", connection: "Fall flat" },
      { word: "FREE", connection: "Freefall" },
      { word: "LEAF", connection: "Falling leaves" },
      { word: "NIAGARA", connection: "Niagara Falls" },
    ],
  },
  {
    answer: "PAPER",
    variants: ["PAPERS"],
    clues: [
      { word: "ROCK", connection: "Rock, paper, scissors" },
      { word: "TIGER", connection: "Paper tiger" },
      { word: "CHASE", connection: "Paper chase" },
      { word: "TRAIL", connection: "Paper trail" },
      { word: "WALL", connection: "Wallpaper" },
    ],
  },
  {
    answer: "STOCK",
    variants: ["STOCKS", "STOCKED", "STOCKING"],
    clues: [
      { word: "LAUGHING", connection: "Laughing stock" },
      { word: "LIVE", connection: "Livestock" },
      { word: "MARKET", connection: "Stock market" },
      { word: "CHICKEN", connection: "Chicken stock" },
      { word: "TAKE", connection: "Take stock" },
    ],
  },
  {
    answer: "NAIL",
    variants: ["NAILS", "NAILED", "NAILING"],
    clues: [
      { word: "TOOTH", connection: "Fight tooth and nail" },
      { word: "COFFIN", connection: "Nail in the coffin" },
      { word: "HAMMER", connection: "Hammer and nail" },
      { word: "POLISH", connection: "Nail polish" },
      { word: "BED", connection: "Bed of nails" },
    ],
  },
  {
    answer: "TRACK",
    variants: ["TRACKS", "TRACKED", "TRACKING"],
    clues: [
      { word: "FAST", connection: "Fast track" },
      { word: "SIDE", connection: "Sidetracked" },
      { word: "RECORD", connection: "Track record" },
      { word: "SOUND", connection: "Soundtrack" },
      { word: "TRAIN", connection: "Train track" },
    ],
  },
  {
    answer: "STAGE",
    variants: ["STAGES", "STAGED", "STAGING"],
    clues: [
      { word: "BACK", connection: "Backstage" },
      { word: "COACH", connection: "Stagecoach" },
      { word: "FRIGHT", connection: "Stage fright" },
      { word: "ROCKET", connection: "Rocket stage" },
      { word: "LEFT", connection: "Stage left" },
    ],
  },
  {
    answer: "CHECK",
    variants: ["CHECKS", "CHECKED", "CHECKING"],
    clues: [
      { word: "RAIN", connection: "Raincheck" },
      { word: "BODY", connection: "Body check" },
      { word: "BLANK", connection: "Blank check" },
      { word: "REALITY", connection: "Reality check" },
      { word: "CHESS", connection: "Check in chess" },
    ],
  },
  {
    answer: "HEART",
    variants: ["HEARTS", "HEARTED"],
    clues: [
      { word: "SWEET", connection: "Sweetheart" },
      { word: "BRAVE", connection: "Braveheart" },
      { word: "BREAK", connection: "Heartbreak" },
      { word: "ATTACK", connection: "Heart attack" },
      { word: "SLEEVE", connection: "Wear your heart on your sleeve" },
    ],
  },
  {
    answer: "POINT",
    variants: ["POINTS", "POINTED", "POINTING"],
    clues: [
      { word: "COUNTER", connection: "Counterpoint" },
      { word: "GUN", connection: "Gunpoint" },
      { word: "NEEDLE", connection: "Needlepoint" },
      { word: "POWER", connection: "PowerPoint" },
      { word: "VIEW", connection: "Point of view" },
    ],
  },
  {
    answer: "DRUM",
    variants: ["DRUMS", "DRUMMING", "DRUMMED"],
    clues: [
      { word: "EAR", connection: "Eardrum" },
      { word: "MAJOR", connection: "Drum major" },
      { word: "SNARE", connection: "Snare drum" },
      { word: "STICK", connection: "Drumstick" },
      { word: "ROLL", connection: "Drum roll" },
    ],
  },
  {
    answer: "PLATE",
    variants: ["PLATES", "PLATED", "PLATING"],
    clues: [
      { word: "BOILER", connection: "Boilerplate" },
      { word: "HOME", connection: "Home plate (baseball)" },
      { word: "TECTONIC", connection: "Tectonic plates" },
      { word: "LICENSE", connection: "License plate" },
      { word: "DINNER", connection: "Dinner plate" },
    ],
  },
  {
    answer: "PASS",
    variants: ["PASSES", "PASSED", "PASSING", "PAST"],
    clues: [
      { word: "OVER", connection: "Overpass" },
      { word: "WORD", connection: "Password" },
      { word: "MOUNTAIN", connection: "Mountain pass" },
      { word: "BOARDING", connection: "Boarding pass" },
      { word: "FAIL", connection: "Pass or fail" },
    ],
  },
  {
    answer: "CELL",
    variants: ["CELLS"],
    clues: [
      { word: "STEM", connection: "Stem cell" },
      { word: "FUEL", connection: "Fuel cell" },
      { word: "SOLAR", connection: "Solar cell" },
      { word: "PHONE", connection: "Cell phone" },
      { word: "PRISON", connection: "Prison cell" },
    ],
  },
  {
    answer: "JAM",
    variants: ["JAMS", "JAMMED", "JAMMING"],
    clues: [
      { word: "PEARL", connection: "Pearl Jam" },
      { word: "TOE", connection: "Toe jam" },
      { word: "TRAFFIC", connection: "Traffic jam" },
      { word: "GUITAR", connection: "Jam session" },
      { word: "TOAST", connection: "Jam on toast" },
    ],
  },
  {
    answer: "BARK",
    variants: ["BARKS", "BARKING", "BARKED"],
    clues: [
      { word: "CHOCOLATE", connection: "Chocolate bark (the sweet)" },
      { word: "MOON", connection: "Barking at the moon" },
      { word: "WORSE", connection: "Bark worse than your bite" },
      { word: "TREE", connection: "Tree bark" },
      { word: "DOG", connection: "Dog bark" },
    ],
  },
  {
    answer: "CURRENT",
    variants: ["CURRENTS", "CURRENTLY"],
    clues: [
      { word: "ACCOUNT", connection: "Current account" },
      { word: "UNDER", connection: "Undercurrent" },
      { word: "AFFAIRS", connection: "Current affairs" },
      { word: "ELECTRIC", connection: "Electric current" },
      { word: "RIVER", connection: "River current" },
    ],
  },
  {
    answer: "GLASS",
    variants: ["GLASSES"],
    clues: [
      { word: "CEILING", connection: "Glass ceiling" },
      { word: "SPY", connection: "Spyglass" },
      { word: "STAIN", connection: "Stained glass" },
      { word: "WINE", connection: "Wine glass" },
      { word: "SLIPPER", connection: "Glass slipper" },
    ],
  },
  {
    answer: "FRAME",
    variants: ["FRAMES", "FRAMED", "FRAMING"],
    clues: [
      { word: "BLAME", connection: "Frame someone (for a crime)" },
      { word: "TIME", connection: "Time frame" },
      { word: "FREEZE", connection: "Freeze frame" },
      { word: "DOOR", connection: "Door frame" },
      { word: "PICTURE", connection: "Picture frame" },
    ],
  },
  {
    answer: "SEAL",
    variants: ["SEALS", "SEALED", "SEALING"],
    clues: [
      { word: "LIPS", connection: "Seal your lips" },
      { word: "NAVY", connection: "Navy SEAL" },
      { word: "WAX", connection: "Wax seal" },
      { word: "DEAL", connection: "Seal the deal" },
      { word: "APPROVAL", connection: "Seal of approval" },
    ],
  },
  {
    answer: "COURT",
    variants: ["COURTS", "COURTING", "COURTED"],
    clues: [
      { word: "SHIP", connection: "Courtship" },
      { word: "FOOD", connection: "Food court" },
      { word: "SUPREME", connection: "Supreme Court" },
      { word: "JESTER", connection: "Court jester" },
      { word: "BASKETBALL", connection: "Basketball court" },
    ],
  },
  {
    answer: "BREAK",
    variants: ["BREAKS", "BROKE", "BROKEN", "BREAKING"],
    clues: [
      { word: "FAST", connection: "Breakfast" },
      { word: "GROUND", connection: "Groundbreaking" },
      { word: "PRISON", connection: "Prison break" },
      { word: "DANCE", connection: "Breakdance" },
      { word: "DAY", connection: "Daybreak" },
    ],
  },
  {
    answer: "DEAD",
    variants: ["DEADLY"],
    clues: [
      { word: "GRATEFUL", connection: "Grateful Dead" },
      { word: "PAN", connection: "Deadpan" },
      { word: "LINE", connection: "Deadline" },
      { word: "END", connection: "Dead end" },
      { word: "LOCK", connection: "Deadlock" },
    ],
  },
  {
    answer: "SHARP",
    variants: ["SHARPS", "SHARPER", "SHARPEST"],
    clues: [
      { word: "CARD", connection: "Cardsharp" },
      { word: "FLAT", connection: "Sharp vs flat (music)" },
      { word: "SHOOTER", connection: "Sharpshooter" },
      { word: "TONGUE", connection: "Sharp tongue" },
      { word: "KNIFE", connection: "Sharp knife" },
    ],
  },
  {
    answer: "BLIND",
    variants: ["BLINDS", "BLINDED", "BLINDING"],
    clues: [
      { word: "COLOUR", connection: "Colour blind" },
      { word: "VENETIAN", connection: "Venetian blinds" },
      { word: "DATE", connection: "Blind date" },
      { word: "SPOT", connection: "Blind spot" },
      { word: "FOLD", connection: "Blindfold" },
    ],
  },
  {
    answer: "CROSS",
    variants: ["CROSSES", "CROSSED", "CROSSING"],
    clues: [
      { word: "DOUBLE", connection: "Double cross" },
      { word: "ROADS", connection: "Crossroads" },
      { word: "RED", connection: "Red Cross" },
      { word: "WORD", connection: "Crossword" },
      { word: "ANGRY", connection: "Cross (meaning angry)" },
    ],
  },
  {
    answer: "CHAIN",
    variants: ["CHAINS", "CHAINED"],
    clues: [
      { word: "BALL", connection: "Ball and chain" },
      { word: "DAISY", connection: "Daisy chain" },
      { word: "FOOD", connection: "Food chain" },
      { word: "SUPPLY", connection: "Supply chain" },
      { word: "LINK", connection: "Chain link" },
    ],
  },
  {
    answer: "IRON",
    variants: ["IRONS", "IRONING", "IRONED"],
    clues: [
      { word: "WRINKLE", connection: "Iron out the wrinkles" },
      { word: "MAIDEN", connection: "Iron Maiden" },
      { word: "MAN", connection: "Iron Man" },
      { word: "FIST", connection: "Iron fist" },
      { word: "CURTAIN", connection: "Iron Curtain" },
    ],
  },
  {
    answer: "BOARD",
    variants: ["BOARDS", "BOARDED", "BOARDING"],
    clues: [
      { word: "ABOVE", connection: "Above board" },
      { word: "CARD", connection: "Cardboard" },
      { word: "DART", connection: "Dartboard" },
      { word: "SKATE", connection: "Skateboard" },
      { word: "CHALK", connection: "Chalkboard" },
    ],
  },
  {
    answer: "ROCK",
    variants: ["ROCKS", "ROCKED", "ROCKING"],
    clues: [
      { word: "SHAM", connection: "Shamrock" },
      { word: "BED", connection: "Bedrock" },
      { word: "BOTTOM", connection: "Rock bottom" },
      { word: "PAPER", connection: "Rock, paper, scissors" },
      { word: "CLIMBING", connection: "Rock climbing" },
    ],
  },
  {
    answer: "GROUND",
    variants: ["GROUNDS", "GROUNDED", "GROUNDING"],
    clues: [
      { word: "COFFEE", connection: "Coffee grounds" },
      { word: "PLAY", connection: "Playground" },
      { word: "HOG", connection: "Groundhog" },
      { word: "COMMON", connection: "Common ground" },
      { word: "UNDER", connection: "Underground" },
    ],
  },
  {
    answer: "LINE",
    variants: ["LINES", "LINED", "LINING"],
    clues: [
      { word: "PUNCH", connection: "Punchline" },
      { word: "CLOTHES", connection: "Clothesline" },
      { word: "FINE", connection: "Fine line" },
      { word: "BOTTOM", connection: "Bottom line" },
      { word: "FISHING", connection: "Fishing line" },
    ],
  },
];

// ─────────────────────────────────────────────
// DAILY PUZZLE PICKER
// ─────────────────────────────────────────────
const EPOCH = new Date(2026, 1, 16);
// Replace the live round on February 19, 2026, then continue with the new pool.
const ROUND_RESET_DATE = new Date(2026, 1, 19);
// Already used in the previous live run before this reset.
const PREVIOUSLY_PLAYED_ANSWERS = new Set(["SPRING", "CROWN", "FALL", "PLANT"]);
const FUTURE_ROUNDS = ALL_ROUNDS.filter((round) => !PREVIOUSLY_PLAYED_ANSWERS.has(round.answer));

const getDayNumber = () => {
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const ep = new Date(EPOCH);
  ep.setHours(0, 0, 0, 0);
  return Math.max(1, Math.floor((now - ep) / 86400000) + 1);
};

const getFutureDayNumber = () => {
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const reset = new Date(ROUND_RESET_DATE);
  reset.setHours(0, 0, 0, 0);
  return Math.max(1, Math.floor((now - reset) / 86400000) + 1);
};

const getDailyRound = () => {
  if (!FUTURE_ROUNDS.length) return ALL_ROUNDS[0];
  const idx = (getFutureDayNumber() - 1) % FUTURE_ROUNDS.length;
  return FUTURE_ROUNDS[idx];
};

const todayKey = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
};

const storage = {
  async get(key) {
    try {
      const value = localStorage.getItem(key);
      return value === null ? null : { value };
    } catch {
      return null;
    }
  },
  async set(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch {
      // Ignore storage write failures (private mode / quota exceeded).
    }
  },
  async remove(key) {
    try {
      localStorage.removeItem(key);
    } catch {
      // Ignore storage cleanup failures.
    }
  },
};

const HISTORY_KEY = "thread-history-v1";
const HISTORY_MIGRATION_FLAG_KEY = "thread-history-migrated-v1";
const HISTORY_LIMIT = 400;
const DAY_KEY_RE = /^thread-(\d{4}-\d{2}-\d{2})$/;
const DATE_KEY_RE = /^\d{4}-\d{2}-\d{2}$/;

const normalizeHistoryEntry = (entry) => {
  if (!entry || typeof entry !== "object") return null;

  const date = typeof entry.date === "string" ? entry.date.trim() : "";
  if (!DATE_KEY_RE.test(date)) return null;

  const answer = typeof entry.answer === "string" ? entry.answer.trim().toUpperCase() : "";
  if (!answer) return null;

  let cluesUsed = null;
  if (entry.cluesUsed !== null && entry.cluesUsed !== undefined) {
    const parsed = Number(entry.cluesUsed);
    if (!Number.isInteger(parsed) || parsed < 1 || parsed > 5) return null;
    cluesUsed = parsed;
  }

  const updatedAt = Number(entry.updatedAt);
  return {
    date,
    answer,
    cluesUsed,
    solved: cluesUsed !== null,
    updatedAt: Number.isFinite(updatedAt) ? updatedAt : Date.now(),
  };
};

const sortHistoryDesc = (entries) => (
  [...entries].sort((a, b) => b.date.localeCompare(a.date))
);

const mergeHistoryByDate = (existing, incoming) => {
  const byDate = new Map();
  for (const item of existing) {
    byDate.set(item.date, item);
  }
  for (const item of incoming) {
    const prev = byDate.get(item.date);
    if (!prev || item.updatedAt >= prev.updatedAt) {
      byDate.set(item.date, item);
    }
  }
  return sortHistoryDesc([...byDate.values()]).slice(0, HISTORY_LIMIT);
};

const readHistory = async () => {
  const stored = await storage.get(HISTORY_KEY);
  if (!stored) return [];
  try {
    const parsed = JSON.parse(stored.value);
    if (!Array.isArray(parsed)) return [];
    const clean = parsed.map(normalizeHistoryEntry).filter(Boolean);
    return sortHistoryDesc(clean).slice(0, HISTORY_LIMIT);
  } catch {
    return [];
  }
};

const writeHistory = async (entries) => {
  const clean = sortHistoryDesc(entries.map(normalizeHistoryEntry).filter(Boolean)).slice(0, HISTORY_LIMIT);
  await storage.set(HISTORY_KEY, JSON.stringify(clean));
  return clean;
};

const upsertHistoryEntry = async (entry) => {
  const clean = normalizeHistoryEntry(entry);
  if (!clean) return readHistory();
  const current = await readHistory();
  const next = mergeHistoryByDate(current, [clean]);
  await writeHistory(next);
  return next;
};

const removeHistoryEntryByDate = async (dateKey) => {
  if (!DATE_KEY_RE.test(dateKey)) return readHistory();
  const current = await readHistory();
  const next = current.filter((item) => item.date !== dateKey);
  await writeHistory(next);
  return next;
};

const migrateLegacyDailyResults = async () => {
  const migrationDone = await storage.get(HISTORY_MIGRATION_FLAG_KEY);
  if (migrationDone) return readHistory();

  const current = await readHistory();
  const legacyEntries = [];

  try {
    for (let i = 0; i < localStorage.length; i += 1) {
      const key = localStorage.key(i);
      if (!key) continue;
      const match = key.match(DAY_KEY_RE);
      if (!match) continue;

      const raw = localStorage.getItem(key);
      if (!raw) continue;

      let parsed;
      try {
        parsed = JSON.parse(raw);
      } catch {
        continue;
      }

      const entry = normalizeHistoryEntry({
        date: match[1],
        answer: parsed.answer,
        cluesUsed: parsed.cluesUsed,
        updatedAt: Date.now(),
      });
      if (entry) legacyEntries.push(entry);
    }
  } catch {
    // Ignore migration scan failures (private mode / blocked storage APIs).
  }

  const merged = mergeHistoryByDate(current, legacyEntries);
  await writeHistory(merged);
  await storage.set(HISTORY_MIGRATION_FLAG_KEY, "1");
  return merged;
};

const toUtcDateValue = (dateKey) => {
  const [year, month, day] = dateKey.split("-").map(Number);
  return Date.UTC(year, month - 1, day);
};

const dayDiff = (fromDate, toDate) => (
  Math.round((toUtcDateValue(toDate) - toUtcDateValue(fromDate)) / 86400000)
);

const formatHistoryDate = (dateKey) => {
  const date = new Date(`${dateKey}T00:00:00`);
  if (Number.isNaN(date.getTime())) return dateKey;
  return new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(date);
};

const scoreToDots = (score) => {
  if (score === null) return "⚫⚫⚫⚫⚫";
  return Array.from({ length: 5 }, (_, i) => (i < score ? "🟢" : "⚪")).join("");
};

const buildHistoryStats = (history) => {
  const ordered = sortHistoryDesc(history);
  const totalPlayed = ordered.length;
  const solvedEntries = ordered.filter((entry) => entry.cluesUsed !== null);
  const solvedCount = solvedEntries.length;
  const missedCount = totalPlayed - solvedCount;
  const solveRate = totalPlayed ? Math.round((solvedCount / totalPlayed) * 100) : 0;

  const avgClues = solvedCount
    ? solvedEntries.reduce((sum, entry) => sum + entry.cluesUsed, 0) / solvedCount
    : null;
  const bestScore = solvedCount
    ? Math.min(...solvedEntries.map((entry) => entry.cluesUsed))
    : null;

  const scoreCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  for (const entry of solvedEntries) {
    scoreCounts[entry.cluesUsed] += 1;
  }

  const ascDates = [...new Set(ordered.map((entry) => entry.date))].sort((a, b) => a.localeCompare(b));
  let bestStreak = 0;
  let runningStreak = 0;
  let prevDate = null;
  for (const date of ascDates) {
    if (prevDate && dayDiff(prevDate, date) === 1) {
      runningStreak += 1;
    } else {
      runningStreak = 1;
    }
    if (runningStreak > bestStreak) bestStreak = runningStreak;
    prevDate = date;
  }

  let currentStreak = runningStreak;
  if (ascDates.length > 0) {
    const lastPlayed = ascDates[ascDates.length - 1];
    if (dayDiff(lastPlayed, todayKey()) > 1) {
      currentStreak = 0;
    }
  } else {
    currentStreak = 0;
  }

  return {
    totalPlayed,
    solvedCount,
    missedCount,
    solveRate,
    avgClues,
    bestScore,
    scoreCounts,
    currentStreak,
    bestStreak,
    recent: ordered.slice(0, 14),
  };
};

const SCORE_LABELS = ["", "Uncanny", "Brilliant", "Sharp", "Solid", "Got there"];
const SCORE_EMOJI = ["", "🧠", "🔥", "⚡", "👏", "🤝"];

// ─────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────
const C = {
  bg: "#F7F4EF", card: "#FFFFFF", border: "#E4DED4", text: "#1A1714",
  muted: "#756B5D", faint: "#A99C8A", accent: "#2E6B3A", accentSoft: "#E4F0E6",
  gold: "#B8962E", goldSoft: "#FBF6E8", red: "#C05340", redSoft: "#FCEAE6",
  dark: "#1A1714", white: "#FAF8F4",
};

const SCREEN_STYLE = {
  minHeight: "var(--screen-min-height, 100dvh)",
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "var(--screen-justify, center)",
  padding: "var(--screen-padding, max(32px, calc(env(safe-area-inset-top, 0px) + 12px)) 18px max(32px, calc(env(safe-area-inset-bottom, 0px) + 12px)))",
  width: "100%",
  maxWidth: "430px",
  margin: "0 auto",
  zIndex: 1,
  position: "relative",
};

async function copyTextFallback(text) {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      // fall through to execCommand fallback
    }
  }

  try {
    const area = document.createElement("textarea");
    area.value = text;
    area.setAttribute("readonly", "");
    area.style.position = "fixed";
    area.style.opacity = "0";
    area.style.pointerEvents = "none";
    document.body.append(area);
    area.focus();
    area.select();
    const copied = document.execCommand("copy");
    area.remove();
    return copied;
  } catch {
    return false;
  }
}

const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400&family=DM+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');
  :root {
    --screen-min-height: 100dvh;
    --screen-justify: center;
    --screen-padding: max(32px, calc(env(safe-area-inset-top, 0px) + 12px)) 18px max(32px, calc(env(safe-area-inset-bottom, 0px) + 12px));
    --logo-pad-top: 20px;
    --btn-pad: 15px 36px;
    --btn-pad-round: 15px 28px;
    --dots-margin: 14px 0;
    --round-head-top: max(22px, calc(env(safe-area-inset-top, 0px) + 8px));
    --round-prompt-gap: 44px;
    --round-clue-gap: 36px;
    --round-answer-gap: 28px;
    --clue-stack-min-height: 180px;
    --clue-stack-gap: 14px;
    --tutorial-card-min-height: 360px;
  }
  * { box-sizing:border-box; margin:0; padding:0; }
  html, body, #root { min-height:100%; background:${C.bg}; }
  body { -webkit-font-smoothing:antialiased; overflow-x:hidden; }
  ::selection { background:${C.dark}18; }
  input::placeholder { color:${C.faint}; }
  @keyframes fadeUp { from{opacity:0;transform:translateY(14px)} to{opacity:1;transform:translateY(0)} }
  @keyframes shake { 0%,100%{transform:translateX(0)} 20%{transform:translateX(-8px)} 40%{transform:translateX(8px)} 60%{transform:translateX(-4px)} 80%{transform:translateX(4px)} }
  @keyframes popIn { 0%{transform:scale(0.92);opacity:0} 100%{transform:scale(1);opacity:1} }
  @keyframes slideIn { from{opacity:0;transform:translateY(24px)} to{opacity:1;transform:translateY(0)} }
  @keyframes pulse { 0%,100%{opacity:0.2} 50%{opacity:0.45} }
  .fu { animation:fadeUp 0.55s cubic-bezier(0.23,1,0.32,1) both; }
  .pi { animation:popIn 0.4s cubic-bezier(0.34,1.56,0.64,1) both; }
  .si { animation:slideIn 0.55s cubic-bezier(0.23,1,0.32,1) both; }
  .action-row { display:flex; gap:10px; justify-content:center; flex-wrap:wrap; }
  .tutorial-card { max-width:340px; }
  .tutorial-shell { width:100%; max-width:360px; display:flex; flex-direction:column; align-items:center; margin-top:14px; }
  .tutorial-card { width:100%; min-height:var(--tutorial-card-min-height); display:flex; flex-direction:column; justify-content:flex-start; }
  .tutorial-controls { width:100%; max-width:340px; display:flex; flex-direction:column; align-items:center; margin-top:8px; }
  .tutorial-steps { display:flex; flex-direction:column; gap:8px; margin-bottom:20px; }
  .tutorial-step { display:flex; align-items:center; gap:10px; background:${C.card}; border:1px solid ${C.border}; border-radius:12px; padding:10px 12px; text-align:left; }
  .tutorial-step-num { width:22px; height:22px; border-radius:50%; background:${C.accentSoft}; color:${C.accent}; display:flex; align-items:center; justify-content:center; font:700 11px 'DM Sans', sans-serif; flex-shrink:0; }
  .tutorial-step-text { color:${C.dark}; font:500 13px/1.35 'DM Sans', sans-serif; letter-spacing:0.2px; }
  .tutorial-example { background:${C.card}; border:1px solid ${C.border}; border-radius:14px; padding:16px 18px; margin-bottom:16px; text-align:left; }
  .tutorial-example-word { font-family:'Cormorant Garamond', serif; font-size:21px; font-weight:400; letter-spacing:2.4px; color:${C.dark}; margin-bottom:6px; }
  .tutorial-example-word.faded { font-weight:300; color:${C.faint}; }
  .tutorial-example-answer { font-family:'Cormorant Garamond', serif; font-size:24px; font-weight:600; letter-spacing:3px; color:${C.accent}; text-align:center; }
  .clue-stack { width:100%; max-width:380px; min-height:var(--clue-stack-min-height); }
  .round-input-wrap { width:100%; max-width:380px; text-align:center; }
  .round-action-row > button { flex:1; min-width:0; }

  @media (max-width: 560px) {
    :root {
      --screen-justify: center;
      --screen-padding: max(18px, calc(env(safe-area-inset-top, 0px) + 8px)) 14px max(18px, calc(env(safe-area-inset-bottom, 0px) + 10px));
      --logo-pad-top: 12px;
      --btn-pad: 13px 26px;
      --btn-pad-round: 11px 14px;
      --dots-margin: 10px 0;
      --round-head-top: max(12px, calc(env(safe-area-inset-top, 0px) + 4px));
      --round-prompt-gap: 26px;
      --round-clue-gap: 24px;
      --round-answer-gap: 20px;
      --clue-stack-min-height: 150px;
      --clue-stack-gap: 11px;
      --tutorial-card-min-height: 320px;
    }
    .tutorial-card { max-width:100%; }
    .action-row.stack-mobile { flex-direction:column; align-items:stretch; width:100%; }
    .action-row.stack-mobile > button { width:100%; }
    .round-action-row { width:100%; gap:8px; flex-wrap:nowrap; }
    .tutorial-example { padding:14px 14px; margin-bottom:14px; }
    .tutorial-example-word { font-size:18px; letter-spacing:2px; margin-bottom:4px; }
    .tutorial-example-answer { font-size:21px; letter-spacing:2.5px; }
  }
`;

const serif = "'Cormorant Garamond', serif";
const sans = "'DM Sans', sans-serif";

// ─────────────────────────────────────────────
// SHARED UI
// ─────────────────────────────────────────────
function Btn({ children, onClick, v="dark", style={}, disabled }) {
  const styles = {
    dark: { background:C.dark, color:C.white },
    outline: { background:"transparent", color:C.muted, border:`1.5px solid ${C.border}` },
    green: { background:C.accent, color:"#fff" },
  };
  return (
    <button onClick={disabled ? undefined : onClick} style={{
      fontFamily:sans, fontSize:13, fontWeight:600, letterSpacing:"1.5px",
      textTransform:"uppercase", border:"none", padding:"var(--btn-pad, 15px 36px)", borderRadius:100,
      cursor:disabled?"default":"pointer", transition:"all 0.2s ease",
      opacity:disabled?0.35:1, ...styles[v], ...style,
    }}
      onMouseEnter={e=>{if(!disabled)e.target.style.transform="translateY(-1px)"}}
      onMouseLeave={e=>{e.target.style.transform="translateY(0)"}}
    >{children}</button>
  );
}

function Dots({ n, active, color=C.dark }) {
  return (
    <div style={{ display:"flex", gap:7, justifyContent:"center", margin:"var(--dots-margin, 14px 0)" }}>
      {Array.from({length:n},(_,i)=>(
        <div key={i} style={{
          width:7, height:7, borderRadius:"50%",
          background:i<=active?color:C.border, transition:"all 0.3s ease",
        }}/>
      ))}
    </div>
  );
}

function Logo({ sub }) {
  return (
    <div style={{ textAlign:"center", padding:"var(--logo-pad-top, 20px) 0 0", position:"relative", zIndex:2 }}>
      <div style={{ fontFamily:sans, fontSize:9, letterSpacing:"4px", textTransform:"uppercase", color:C.muted, fontWeight:600, marginBottom:5 }}>
        Daily Word Puzzle
      </div>
      <h1 style={{ fontFamily:serif, fontSize:"clamp(2.2rem, 10vw, 38px)", fontWeight:600, letterSpacing:"clamp(6px, 1.8vw, 10px)", color:C.dark, textTransform:"uppercase" }}>
        Thread
      </h1>
      {sub && <div style={{ fontFamily:sans, fontSize:11.5, color:C.muted, marginTop:5, fontStyle:"italic" }}>{sub}</div>}
    </div>
  );
}

// ─────────────────────────────────────────────
// TUTORIAL
// ─────────────────────────────────────────────
const TUT = [
  { icon:"🧵", title:"How Thread works",
    body:"You’re finding one hidden word from clue words.",
    steps:["Start with one clue", "Type your best guess", "Wrong guess reveals the next clue"],
    note:"Fewer clues = better result." },
  { icon:"💡", title:"Clues reveal one by one",
    body:"You start with a single clue. As more appear, the thread gets clearer. Guess whenever you feel it.",
    example:{ words:["SATURN","BOXING","PHONE"], faded:["???","???"], answer:"RING" } },
  { icon:"⚡", title:"Fewer clues = better score",
    body:"A wrong guess costs you — it reveals the next clue. Bold guesses pay off, but bad ones tighten the clock.",
    scoring:true },
  { icon:"📤", title:"Share your result",
    body:"One puzzle a day. When you're done, share a spoiler-free emoji grid with friends.",
    share:true },
];

function Tutorial({ onDone, onSkip }) {
  const [i, setI] = useState(0);
  const touchStartX = useRef(null);
  const c = TUT[i];
  const next = () => i < TUT.length-1 ? setI(i+1) : onDone();
  const previous = () => setI((p) => Math.max(0, p - 1));

  const onTouchStart = (event) => {
    touchStartX.current = event.touches?.[0]?.clientX ?? null;
  };

  const onTouchEnd = (event) => {
    if (touchStartX.current === null) {
      return;
    }

    const endX = event.changedTouches?.[0]?.clientX ?? touchStartX.current;
    const delta = endX - touchStartX.current;
    touchStartX.current = null;

    if (Math.abs(delta) < 42) {
      return;
    }

    if (delta < 0) {
      next();
      return;
    }

    previous();
  };

  return (
    <div style={SCREEN_STYLE}>
      <Logo />

      <div className="tutorial-shell">
        <div
          key={i}
          className="fu tutorial-card"
          onTouchStart={onTouchStart}
          onTouchEnd={onTouchEnd}
          style={{ textAlign:"center" }}
        >
          <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"2.4px", textTransform:"uppercase", color:C.faint, fontWeight:700, marginBottom:10 }}>
            Step {i + 1} of {TUT.length}
          </div>
          <div style={{ fontSize:50, marginBottom:18 }}>{c.icon}</div>
          <h2 style={{ fontFamily:serif, fontSize:"clamp(1.8rem, 7.2vw, 27px)", fontWeight:600, color:C.dark, marginBottom:12 }}>{c.title}</h2>
          <p style={{ fontFamily:sans, fontSize:14, lineHeight:1.75, color:C.muted, marginBottom:24 }}>{c.body}</p>

          {c.steps && (
            <div className="tutorial-steps">
              {c.steps.map((step, idx) => (
                <div key={step} className="tutorial-step">
                  <span className="tutorial-step-num">{idx + 1}</span>
                  <span className="tutorial-step-text">{step}</span>
                </div>
              ))}
              {c.note && (
                <div style={{ fontFamily:sans, fontSize:12, color:C.muted, marginTop:2 }}>
                  {c.note}
                </div>
              )}
            </div>
          )}

          {c.example && (
            <div className="tutorial-example">
              {c.example.words.map((w,j)=><div key={j} className="tutorial-example-word">{w}</div>)}
              {c.example.faded.map((w,j)=><div key={j} className="tutorial-example-word faded">{w}</div>)}
              <div style={{ height:1, background:C.border, margin:"12px 0" }}/>
              <div className="tutorial-example-answer">{c.example.answer}</div>
            </div>
          )}

          {c.scoring && (
            <div style={{ display:"flex", flexDirection:"column", gap:7, marginBottom:20, alignItems:"center" }}>
              {[1,2,3,4,5].map(n=>(
                <div key={n} style={{ display:"flex", alignItems:"center", gap:12, fontFamily:sans, fontSize:13 }}>
                  <div style={{ display:"flex", gap:3 }}>
                    {[1,2,3,4,5].map(d=><div key={d} style={{ width:10,height:10,borderRadius:"50%", background:d<=n?C.accent:C.border }}/>)}
                  </div>
                  <span style={{ color:C.muted, minWidth:55 }}>{n} clue{n>1?"s":""}</span>
                  <span style={{ color:C.dark, fontWeight:600 }}>{SCORE_LABELS[n]}</span>
                </div>
              ))}
            </div>
          )}

          {c.share && (
            <div style={{ background:C.card, border:`1px solid ${C.border}`, borderRadius:14, padding:"18px 28px", marginBottom:20, textAlign:"center", fontFamily:sans }}>
              <div style={{ fontSize:14, fontWeight:600, color:C.dark, marginBottom:5 }}>🧵 THREAD #42</div>
              <div style={{ fontSize:24, letterSpacing:5, marginBottom:5 }}>🟢🟢⚪⚪⚪</div>
              <div style={{ fontSize:12, color:C.muted }}>Brilliant — 2 clues</div>
            </div>
          )}
        </div>

        <div className="tutorial-controls">
          <Dots n={TUT.length} active={i} />
          <div className="action-row stack-mobile" style={{ marginTop:6, width:"100%", maxWidth:340 }}>
            <Btn onClick={next}>
              {i === 0 ? "Show me an example" : i<TUT.length-1 ? "Next" : "Try 3 practice rounds"}
            </Btn>
            <button onClick={onSkip} style={{
              background:"none", border:"none", cursor:"pointer", fontFamily:sans,
              fontSize:12, color:C.faint, fontWeight:500, padding:"8px 16px",
              transition:"color 0.2s",
            }}
              onMouseEnter={e=>e.target.style.color=C.muted}
              onMouseLeave={e=>e.target.style.color=C.faint}
            >Skip to today's puzzle</button>
          </div>
          <div style={{ marginTop:6, fontFamily:sans, fontSize:11, color:C.faint }}>
            Swipe cards left and right
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// GAME ROUND
// ─────────────────────────────────────────────
function Round({ round, isPractice, practiceIdx, dayNum, onFinish, onViewStats }) {
  const [ci, setCi] = useState(0);
  const [guess, setGuess] = useState("");
  const [attempts, setAttempts] = useState([]);
  const [solved, setSolved] = useState(false);
  const [failed, setFailed] = useState(false);
  const [shaking, setShaking] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!solved && !failed) setTimeout(()=>ref.current?.focus(), 300);
  }, [ci, solved, failed]);

  const submit = () => {
    const g = guess.trim().toUpperCase();
    if (!g) return;
    const validAnswers = [round.answer, ...(round.variants || [])];
    if (validAnswers.includes(g)) {
      setSolved(true);
    } else {
      setAttempts(p=>[...p, g]);
      setShaking(true);
      setTimeout(()=>setShaking(false), 500);
      setGuess("");
      if (ci < round.clues.length-1) setTimeout(()=>setCi(p=>p+1), 550);
      else setFailed(true);
    }
  };

  const done = solved || failed;
  const score = solved ? ci+1 : null;
  const visible = round.clues.slice(0, ci+1);

  return (
    <div style={SCREEN_STYLE}>

      {/* Top */}
      <div style={{ position:"absolute", top:"var(--round-head-top, max(22px, calc(env(safe-area-inset-top, 0px) + 8px)))", left:0, right:0, textAlign:"center" }}>
        <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"4px", textTransform:"uppercase", color:C.muted, fontWeight:500 }}>
          {isPractice ? `Practice ${practiceIdx+1} of 3` : `Thread #${dayNum}`}
        </div>
        <Dots n={5} active={ci} color={solved?C.accent:C.dark}/>
      </div>

      {/* Prompt */}
      <div className="fu" style={{ fontFamily:sans, fontSize:13, letterSpacing:"2.5px", textTransform:"uppercase", color:C.muted, textAlign:"center", marginBottom:"var(--round-prompt-gap, 44px)", fontWeight:500 }}>
        What word connects them all?
      </div>

      {/* Clues */}
      <div className="clue-stack" style={{ display:"flex", flexDirection:"column", gap:"var(--clue-stack-gap, 14px)", marginBottom:"var(--round-clue-gap, 36px)" }}>
        {visible.map((clue,i) => {
          const newest = i===ci && !done;
          return (
            <div key={clue.word} className="si" style={{ animationDelay:`${i*50}ms`, display:"flex", alignItems:"flex-start", gap:14 }}>
              <div style={{ fontFamily:serif, fontSize:14, fontWeight:300, color:C.faint, width:18, textAlign:"right", paddingTop:newest?10:6, fontStyle:"italic" }}>{i+1}</div>
              <div style={{ flex:1 }}>
                <div style={{
                  fontFamily:serif,
                  fontSize:newest?"clamp(2rem, 9.2vw, 44px)":"clamp(1.45rem, 6.8vw, 28px)",
                  fontWeight:newest?500:300,
                  letterSpacing:newest?"5px":"3px",
                  color:done?C.muted:newest?C.dark:"#6B6358",
                  transition:"all 0.5s ease", lineHeight:1.15,
                }}>{clue.word}</div>
                {done && <div className="fu" style={{ fontFamily:sans, fontSize:11, color:C.faint, marginTop:3, fontStyle:"italic" }}>{clue.connection}</div>}
              </div>
            </div>
          );
        })}
      </div>

      {/* Solved / Failed */}
      {done && (
        <div className="pi" style={{ textAlign:"center", marginBottom:"var(--round-answer-gap, 28px)" }}>
          <div style={{ fontFamily:serif, fontSize:"clamp(2.5rem, 12vw, 58px)", fontWeight:700, letterSpacing:"clamp(4px, 2vw, 8px)", color:solved?C.accent:C.red, lineHeight:1 }}>
            {round.answer}
          </div>
          <div style={{ fontFamily:sans, fontSize:13.5, color:C.muted, marginTop:10 }}>
            {solved ? `${SCORE_LABELS[score]} — ${score} clue${score>1?"s":""}` : `The thread was ${round.answer.toLowerCase()}`}
          </div>
        </div>
      )}

      {/* Input */}
      {!done && (
        <div className="round-input-wrap" style={{ animation:shaking?"shake 0.4s ease":"none" }}>
          <div style={{ display:"flex", alignItems:"center", borderBottom:`2px solid ${C.dark}`, paddingBottom:10, marginBottom:20 }}>
            <input ref={ref} type="text" value={guess}
              onChange={e=>setGuess(e.target.value.toUpperCase())}
              onKeyDown={e=>e.key==="Enter"&&submit()}
              placeholder="Your guess..." autoComplete="off" spellCheck="false"
              style={{ flex:1, border:"none", outline:"none", background:"transparent", fontFamily:serif, fontSize:"clamp(1.5rem, 7vw, 28px)", fontWeight:500, letterSpacing:"4px", color:C.dark, textAlign:"center" }}
            />
          </div>
          <div className="action-row round-action-row">
            <Btn onClick={submit} style={{ padding:"var(--btn-pad-round, 15px 28px)" }}>Submit</Btn>
          </div>
          {attempts.length>0 && (
            <div style={{ marginTop:18, display:"flex", gap:10, justifyContent:"center", flexWrap:"wrap" }}>
              {attempts.map((a,i)=><span key={i} style={{ fontFamily:sans, fontSize:12, color:C.faint, textDecoration:"line-through", letterSpacing:"1px" }}>{a}</span>)}
            </div>
          )}
          {!isPractice && onViewStats && (
            <button
              type="button"
              onClick={onViewStats}
              style={{
                marginTop: 18,
                background: "none",
                border: "none",
                cursor: "pointer",
                fontFamily: sans,
                fontSize: 11.5,
                letterSpacing: "1px",
                textTransform: "uppercase",
                color: C.faint,
              }}
            >
              View my record
            </button>
          )}
        </div>
      )}

      {/* Continue */}
      {done && (
        <div className="fu" style={{ animationDelay:"0.6s", marginTop:8 }}>
          <Btn onClick={()=>onFinish(score)}>
            {isPractice ? (practiceIdx<2 ? "Next round" : "See practice results") : "See results"}
          </Btn>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────
// PRACTICE DONE
// ─────────────────────────────────────────────
function PracticeDone({ scores, onContinue }) {
  return (
    <div style={SCREEN_STYLE}>
      <Logo/>
      <div className="fu tutorial-card" style={{ textAlign:"center", maxWidth:360, marginTop:28 }}>
        <div style={{ fontSize:50, marginBottom:16 }}>👏</div>
        <h2 style={{ fontFamily:serif, fontSize:"clamp(1.8rem, 8vw, 28px)", fontWeight:600, color:C.dark, marginBottom:10 }}>You've got the idea</h2>
        <p style={{ fontFamily:sans, fontSize:14, lineHeight:1.7, color:C.muted, marginBottom:28 }}>
          Practice is done. Now try today's real puzzle — this one counts.
        </p>
        <div style={{ display:"flex", flexDirection:"column", gap:8, marginBottom:32 }}>
          {PRACTICE_ROUNDS.map((r,i)=>(
            <div key={i} style={{ display:"flex", alignItems:"center", gap:14, padding:"12px 16px", background:C.card, border:`1px solid ${C.border}`, borderRadius:12 }}>
              <div style={{
                width:38, height:38, borderRadius:"50%", display:"flex", alignItems:"center", justifyContent:"center",
                background:scores[i]?C.accentSoft:C.redSoft, fontFamily:sans, fontSize:14, fontWeight:700,
                color:scores[i]?C.accent:C.red,
              }}>{scores[i]||"×"}</div>
              <div>
                <div style={{ fontFamily:serif, fontSize:20, fontWeight:500, letterSpacing:"2px", color:C.dark }}>{r.answer}</div>
                <div style={{ fontFamily:sans, fontSize:11, color:C.muted }}>
                  {scores[i] ? `${SCORE_LABELS[scores[i]]} — ${scores[i]} clue${scores[i]>1?"s":""}` : "Missed"}
                </div>
              </div>
            </div>
          ))}
        </div>
        <Btn onClick={onContinue} style={{ minWidth:240 }}>Play today's thread</Btn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// RESULTS
// ─────────────────────────────────────────────
function Results({ round, score, dayNum, onViewStats }) {
  const [copied, setCopied] = useState(false);
  const ok = score !== null;
  const row = Array.from({length:5},(_,i)=> !ok?"⚫":i<score?"🟢":"⚪").join("");
  const txt = [`🧵 THREAD #${dayNum}`, row, ok?`${SCORE_LABELS[score]} — ${score} clue${score>1?"s":""}`:"Missed today's thread", ""].join("\n");

  const share = async () => {
    if (navigator.share) { try { await navigator.share({text:txt}); return; } catch{} }
    const copiedOk = await copyTextFallback(txt);
    if (copiedOk) {
      setCopied(true);
      setTimeout(()=>setCopied(false),2500);
    }
  };

  return (
    <div style={SCREEN_STYLE}>
      <Logo sub={`Puzzle #${dayNum}`}/>

      <div className="pi" style={{ textAlign:"center", marginTop:24, marginBottom:8 }}>
        <div style={{ fontSize:46, marginBottom:10 }}>{ok?SCORE_EMOJI[score]:"😔"}</div>
        <div style={{ fontFamily:serif, fontSize:"clamp(2.5rem, 12vw, 58px)", fontWeight:700, letterSpacing:"clamp(4px, 2vw, 8px)", color:ok?C.accent:C.red, lineHeight:1 }}>{round.answer}</div>
        <div style={{ fontFamily:sans, fontSize:14, color:C.muted, marginTop:10 }}>
          {ok ? `${SCORE_LABELS[score]} — ${score} clue${score>1?"s":""}` : "You'll get the next one"}
        </div>
      </div>

      <div className="fu" style={{ animationDelay:"0.3s", fontSize:"clamp(1.4rem, 7.2vw, 30px)", letterSpacing:"clamp(2px, 1.6vw, 6px)", marginBottom:30, textAlign:"center" }}>{row}</div>

      {/* Breakdown */}
      <div className="fu" style={{ animationDelay:"0.5s", width:"100%", maxWidth:380, marginBottom:36 }}>
        <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"3px", textTransform:"uppercase", color:C.faint, fontWeight:600, marginBottom:12, textAlign:"center" }}>
          The connections
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:7 }}>
          {round.clues.map((cl,i)=>(
            <div key={i} style={{ display:"flex", alignItems:"center", gap:12, padding:"11px 16px", background:C.card, border:`1px solid ${C.border}`, borderRadius:10 }}>
              <span style={{ fontFamily:serif, fontSize:18, fontWeight:500, letterSpacing:"2px", color:C.dark, minWidth:100 }}>{cl.word}</span>
              <span style={{ fontFamily:sans, fontSize:12, color:C.muted, fontStyle:"italic" }}>{cl.connection}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="fu" style={{ animationDelay:"0.7s", display:"flex", flexDirection:"column", alignItems:"center", gap:10, width:"100%", maxWidth:380 }}>
        <Btn v="green" onClick={share} style={{ minWidth:240 }}>{copied?"Copied to clipboard!":"Share your result"}</Btn>
        {onViewStats && (
          <Btn v="outline" onClick={onViewStats} style={{ minWidth:240 }}>
            View personal record
          </Btn>
        )}
        <div style={{ fontFamily:sans, fontSize:11.5, color:C.faint, marginTop:8 }}>New thread at midnight</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// ALREADY PLAYED TODAY
// ─────────────────────────────────────────────
function AlreadyPlayed({ saved, dayNum, onViewStats }) {
  const [copied, setCopied] = useState(false);
  const round = getDailyRound();
  const s = saved.cluesUsed;
  const ok = s !== null;
  const row = Array.from({length:5},(_,i)=>!ok?"⚫":i<s?"🟢":"⚪").join("");
  const txt = [`🧵 THREAD #${dayNum}`, row, ok?`${SCORE_LABELS[s]} — ${s} clue${s>1?"s":""}`:"Missed today's thread", ""].join("\n");

  const share = async () => {
    if (navigator.share) { try { await navigator.share({text:txt}); return; } catch{} }
    const copiedOk = await copyTextFallback(txt);
    if (copiedOk) {
      setCopied(true);
      setTimeout(()=>setCopied(false),2500);
    }
  };

  return (
    <div style={SCREEN_STYLE}>
      <Logo sub={`Puzzle #${dayNum}`}/>
      <div className="fu" style={{ textAlign:"center", marginTop:26 }}>
        <div style={{ fontFamily:serif, fontSize:"clamp(2.4rem, 11.8vw, 54px)", fontWeight:700, letterSpacing:"clamp(4px, 2vw, 8px)", color:ok?C.accent:C.red, lineHeight:1, marginBottom:10 }}>
          {round.answer}
        </div>
        <div style={{ fontSize:"clamp(1.3rem, 6.6vw, 28px)", letterSpacing:"clamp(2px, 1.4vw, 6px)", marginBottom:10 }}>{row}</div>
        <div style={{ fontFamily:sans, fontSize:13, color:C.muted, marginBottom:32 }}>
          {ok ? `${SCORE_LABELS[s]} — ${s} clue${s>1?"s":""}` : "Missed today's thread"}
        </div>
        <Btn v="green" onClick={share} style={{ minWidth:240 }}>{copied?"Copied!":"Share your result"}</Btn>
        {onViewStats && (
          <div style={{ marginTop:10 }}>
            <Btn v="outline" onClick={onViewStats} style={{ minWidth:240 }}>
              View personal record
            </Btn>
          </div>
        )}
        <div style={{ fontFamily:sans, fontSize:11.5, color:C.faint, marginTop:16 }}>Come back tomorrow for a new thread</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// PERSONAL RECORD (LOCAL)
// ─────────────────────────────────────────────
function StatsBoard({ history, onBack }) {
  const stats = buildHistoryStats(history);
  const hasData = stats.totalPlayed > 0;
  const avgClues = stats.avgClues === null ? "—" : stats.avgClues.toFixed(2).replace(/\.?0+$/, "");
  const bestScore = stats.bestScore === null ? "—" : `${stats.bestScore} clues`;
  const maxBar = Math.max(
    1,
    ...Object.values(stats.scoreCounts),
    stats.missedCount
  );

  const metricItems = [
    { label: "Played", value: stats.totalPlayed },
    { label: "Solved", value: `${stats.solveRate}%` },
    { label: "Average", value: avgClues },
    { label: "Best", value: bestScore },
    { label: "Current streak", value: stats.currentStreak },
    { label: "Best streak", value: stats.bestStreak },
  ];

  return (
    <div style={SCREEN_STYLE}>
      <Logo sub="Your local record" />

      {!hasData && (
        <div className="fu tutorial-card" style={{ textAlign:"center", maxWidth:360, marginTop:28 }}>
          <div style={{ fontSize:48, marginBottom:14 }}>📊</div>
          <h2 style={{ fontFamily:serif, fontSize:"clamp(1.8rem, 8vw, 28px)", fontWeight:600, color:C.dark, marginBottom:10 }}>
            No games saved yet
          </h2>
          <p style={{ fontFamily:sans, fontSize:14, lineHeight:1.7, color:C.muted, marginBottom:26 }}>
            Finish a daily thread and your personal record will appear here automatically on this device.
          </p>
          <Btn onClick={onBack} style={{ minWidth:220 }}>Back</Btn>
        </div>
      )}

      {hasData && (
        <div style={{ width:"100%", maxWidth:390, marginTop:22 }}>
          <div className="fu" style={{ animationDelay:"0.1s", display:"grid", gridTemplateColumns:"repeat(2, minmax(0, 1fr))", gap:8, marginBottom:18 }}>
            {metricItems.map((item) => (
              <div
                key={item.label}
                style={{
                  background: C.card,
                  border: `1px solid ${C.border}`,
                  borderRadius: 12,
                  padding: "12px 10px",
                  textAlign: "center",
                }}
              >
                <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"2px", textTransform:"uppercase", color:C.faint, marginBottom:6 }}>
                  {item.label}
                </div>
                <div style={{ fontFamily:serif, fontSize:22, fontWeight:600, letterSpacing:"1px", color:C.dark }}>
                  {item.value}
                </div>
              </div>
            ))}
          </div>

          <div className="fu" style={{ animationDelay:"0.2s", background:C.card, border:`1px solid ${C.border}`, borderRadius:14, padding:"14px 14px 12px", marginBottom:14 }}>
            <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"2.4px", textTransform:"uppercase", color:C.faint, fontWeight:600, marginBottom:10 }}>
              Score distribution
            </div>
            {[1, 2, 3, 4, 5].map((score) => {
              const count = stats.scoreCounts[score];
              const width = `${(count / maxBar) * 100}%`;
              return (
                <div key={score} style={{ display:"grid", gridTemplateColumns:"40px 1fr 32px", alignItems:"center", gap:10, marginBottom:8 }}>
                  <div style={{ fontFamily:sans, fontSize:12, color:C.muted }}>{score} clue</div>
                  <div style={{ height:8, borderRadius:999, background:C.border, overflow:"hidden" }}>
                    <div style={{ width, minWidth:count ? 6 : 0, height:"100%", background:C.accent, transition:"width 0.3s ease" }} />
                  </div>
                  <div style={{ fontFamily:sans, fontSize:12, color:C.dark, textAlign:"right" }}>{count}</div>
                </div>
              );
            })}
            <div style={{ display:"grid", gridTemplateColumns:"40px 1fr 32px", alignItems:"center", gap:10 }}>
              <div style={{ fontFamily:sans, fontSize:12, color:C.muted }}>Missed</div>
              <div style={{ height:8, borderRadius:999, background:C.border, overflow:"hidden" }}>
                <div style={{ width:`${(stats.missedCount / maxBar) * 100}%`, minWidth:stats.missedCount ? 6 : 0, height:"100%", background:C.red, transition:"width 0.3s ease" }} />
              </div>
              <div style={{ fontFamily:sans, fontSize:12, color:C.dark, textAlign:"right" }}>{stats.missedCount}</div>
            </div>
          </div>

          <div className="fu" style={{ animationDelay:"0.3s", background:C.card, border:`1px solid ${C.border}`, borderRadius:14, padding:"14px 12px", marginBottom:18 }}>
            <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"2.4px", textTransform:"uppercase", color:C.faint, fontWeight:600, marginBottom:10 }}>
              Recent threads
            </div>
            <div style={{ display:"flex", flexDirection:"column", gap:7 }}>
              {stats.recent.map((entry) => (
                <div key={`${entry.date}-${entry.answer}`} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", gap:12, padding:"10px 12px", border:`1px solid ${C.border}`, borderRadius:10, background:"#fff" }}>
                  <div>
                    <div style={{ fontFamily:sans, fontSize:10, letterSpacing:"1.8px", textTransform:"uppercase", color:C.faint }}>
                      {formatHistoryDate(entry.date)}
                    </div>
                    <div style={{ fontFamily:serif, fontSize:21, fontWeight:500, letterSpacing:"2px", color:C.dark, marginTop:1 }}>
                      {entry.answer}
                    </div>
                  </div>
                  <div style={{ textAlign:"right" }}>
                    <div style={{ fontSize:16, letterSpacing:1 }}>{scoreToDots(entry.cluesUsed)}</div>
                    <div style={{ fontFamily:sans, fontSize:11, color:C.muted, marginTop:2 }}>
                      {entry.cluesUsed !== null ? `${SCORE_LABELS[entry.cluesUsed]} (${entry.cluesUsed})` : "Missed"}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="fu" style={{ animationDelay:"0.4s", textAlign:"center", marginBottom:8 }}>
            <Btn onClick={onBack} style={{ minWidth:220 }}>Back</Btn>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
export default function Thread() {
  const [phase, setPhase] = useState("loading");
  const [pIdx, setPIdx] = useState(0);
  const [pScores, setPScores] = useState([]);
  const [dailyScore, setDailyScore] = useState(null);
  const [fade, setFade] = useState(false);
  const [saved, setSaved] = useState(null);
  const [history, setHistory] = useState([]);
  const [statsReturnPhase, setStatsReturnPhase] = useState("daily");

  const dayNum = getDayNumber();
  const daily = useRef(getDailyRound());

  useEffect(() => {
    let mounted = true;
    (async () => {
      const seededHistory = await migrateLegacyDailyResults();
      if (mounted) setHistory(seededHistory);

      try {
        const key = `thread-${todayKey()}`;
        const res = await storage.get(key);
        if (res) {
          const parsed = JSON.parse(res.value);
          if (parsed && parsed.answer === daily.current.answer) {
            if (!mounted) return;
            setSaved(parsed);
            setPhase("already");
            return;
          }
          await storage.remove(key);
          const trimmedHistory = await removeHistoryEntryByDate(todayKey());
          if (mounted) setHistory(trimmedHistory);
        }
      } catch {}
      try {
        const tut = await storage.get("thread-tut-done");
        if (tut) {
          if (mounted) setPhase("daily");
          return;
        }
      } catch {}
      if (mounted) setPhase("tutorial");
    })();
    return () => { mounted = false; };
  }, []);

  const go = (p) => { setFade(true); setTimeout(()=>{ setPhase(p); setFade(false); }, 300); };
  const openStats = (fromPhase) => { setStatsReturnPhase(fromPhase); go("stats"); };
  const closeStats = () => go(statsReturnPhase || "daily");

  const markTut = async () => { try { await storage.set("thread-tut-done","1"); } catch{} };

  const saveDailyResult = async (score) => {
    const date = todayKey();
    const data = { cluesUsed: score, answer: daily.current.answer };
    try { await storage.set(`thread-${date}`, JSON.stringify(data)); } catch {}
    const nextHistory = await upsertHistoryEntry({
      date,
      answer: daily.current.answer,
      cluesUsed: score,
      updatedAt: Date.now(),
    });
    setHistory(nextHistory);
  };

  if (phase === "loading") return (
    <div style={{ ...SCREEN_STYLE, background:C.bg }}>
      <style>{CSS}</style>
      <div style={{ fontFamily:serif, fontSize:30, fontWeight:300, letterSpacing:"10px", color:C.faint, textTransform:"uppercase" }}>Thread</div>
    </div>
  );

  return (
    <div style={{ minHeight:"100dvh", background:C.bg, position:"relative", overflowX:"hidden" }}>
      <style>{CSS}</style>
      <div style={{ opacity:fade?0:1, transform:fade?"translateY(6px)":"none", transition:"all 0.3s ease" }}>

        {phase === "tutorial" && (
          <Tutorial
            onDone={()=>{ markTut(); go("practice"); }}
            onSkip={()=>{ markTut(); go("daily"); }}
          />
        )}

        {phase === "practice" && (
          <Round key={`p${pIdx}`} round={PRACTICE_ROUNDS[pIdx]} isPractice practiceIdx={pIdx}
            onFinish={(score) => {
              const next = [...pScores, score];
              setPScores(next);
              if (pIdx < 2) { setFade(true); setTimeout(()=>{ setPIdx(pIdx+1); setFade(false); }, 300); }
              else go("practice-done");
            }}
          />
        )}

        {phase === "practice-done" && (
          <PracticeDone scores={pScores} onContinue={()=>go("daily")}/>
        )}

        {phase === "daily" && (
          <Round key="daily" round={daily.current} dayNum={dayNum} onViewStats={()=>openStats("daily")}
            onFinish={(score) => {
              setDailyScore(score);
              saveDailyResult(score);
              go("results");
            }}
          />
        )}

        {phase === "results" && (
          <Results round={daily.current} score={dailyScore} dayNum={dayNum} onViewStats={()=>openStats("results")} />
        )}

        {phase === "already" && (
          <AlreadyPlayed saved={saved} dayNum={dayNum} onViewStats={()=>openStats("already")} />
        )}

        {phase === "stats" && (
          <StatsBoard history={history} onBack={closeStats} />
        )}
      </div>
    </div>
  );
}
