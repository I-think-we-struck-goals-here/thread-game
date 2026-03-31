// ═══════════════════════════════════════════════════════
// THREAD — CORRECTED ROUNDS (#45–#284)
// 240 rounds for rest of 2026
//
// CHANGES APPLIED:
// 1. All user-specific amendments (rounds 45-131)
// 2. Removed ALL "contained" clues (answer hidden inside clue word)
//    e.g. DELIVER→RIVER, PELICAN→CAN, VICE→ICE, GLOVE→LOVE
// 3. Removed ALL fragment-prefix clues (DE→defence, EX→express, IM→impress)
// 4. Eliminated duplicate answers (RING×4→1, BRIDGE×4→1, WAVE×3→1, etc.)
//    Replaced with: FLOOR, POOL, BAND, ROAD, GATE, TIDE, BUTTON, BRICK,
//    SHADE, WISH, CHARM, NERVE, GUARD, NARROW, SHADOW
// 5. Reordered clues where first clue was too easy
//
// FORMAT: { answer, v:[variants], clues:[{w:"CLUE",c:"connection"}] }
// Clue 1=Misdirect, 2=Fork, 3=Click, 4=Confirm, 5=Gimme
// ═══════════════════════════════════════════════════════

const NEW_ROUNDS = [

// ─── BATCH 1: BODY (#45–#64) ─────────────────────────

// 45 HEAD — changed: final clue now BED (bed head)
{answer:"HEAD",v:["HEADS","HEADED","HEADING"],clues:[
  {w:"FIGURE",c:"Figurehead"},
  {w:"NAIL",c:"Hit the nail on the head"},
  {w:"QUARTERS",c:"Headquarters"},
  {w:"LINE",c:"Headline"},
  {w:"BED",c:"Bed head"},
]},
// 46 HAND — changed: CLOCK now clue 1, everything shifted up
{answer:"HAND",v:["HANDS","HANDED","HANDING"],clues:[
  {w:"CLOCK",c:"Hands of a clock"},
  {w:"SECOND",c:"Secondhand"},
  {w:"SHORT",c:"Shorthand"},
  {w:"UPPER",c:"Upper hand"},
  {w:"SHAKE",c:"Handshake"},
]},
// 47 FOOT — changed: CLUB→LOOSE, BARE shifted up, final=PRINT
{answer:"FOOT",v:["FEET","FOOTED","FOOTING"],clues:[
  {w:"CARBON",c:"Carbon footprint"},
  {w:"NOTE",c:"Footnote"},
  {w:"LOOSE",c:"Footloose"},
  {w:"BARE",c:"Barefoot"},
  {w:"PRINT",c:"Footprint"},
]},
// 48 BACK
{answer:"BACK",v:["BACKS","BACKED","BACKING"],clues:[
  {w:"SET",c:"Setback"},
  {w:"FLASH",c:"Flashback"},
  {w:"BONE",c:"Backbone"},
  {w:"QUARTER",c:"Quarterback"},
  {w:"DOOR",c:"Backdoor"},
]},
// 49 ARM — changed: CHARM→CANDY, CHAIR and STRONG swapped
{answer:"ARM",v:["ARMS","ARMED","ARMING"],clues:[
  {w:"CANDY",c:"Arm candy"},
  {w:"STRONG",c:"Strongarm"},
  {w:"CHAIR",c:"Armchair"},
  {w:"TWISTED",c:"Twist someone's arm"},
  {w:"FIRE",c:"Firearm"},
]},
// 50 EYE
{answer:"EYE",v:["EYES","EYED"],clues:[
  {w:"BIRD",c:"Bird's-eye view"},
  {w:"PRIVATE",c:"Private eye"},
  {w:"NEEDLE",c:"Eye of a needle"},
  {w:"BROW",c:"Eyebrow"},
  {w:"WITNESS",c:"Eyewitness"},
]},
// 51 FACE — changed: ABOUT→PLATE
{answer:"FACE",v:["FACES","FACED","FACING"],clues:[
  {w:"INTER",c:"Interface"},
  {w:"POKER",c:"Poker face"},
  {w:"VALUE",c:"Face value"},
  {w:"PLATE",c:"Faceplate"},
  {w:"CLOCK",c:"Clock face"},
]},
// 52 NECK — changed: BOTTLE and LACE swapped
{answer:"NECK",v:["NECKS","NECKED"],clues:[
  {w:"LACE",c:"Necklace"},
  {w:"WOODS",c:"Neck of the woods"},
  {w:"RED",c:"Redneck"},
  {w:"BOTTLE",c:"Bottleneck"},
  {w:"STIFF",c:"Stiff neck"},
]},
// 53 TONGUE
{answer:"TONGUE",v:["TONGUES"],clues:[
  {w:"SILVER",c:"Silver tongue"},
  {w:"MOTHER",c:"Mother tongue"},
  {w:"CHEEK",c:"Tongue in cheek"},
  {w:"TIED",c:"Tongue-tied"},
  {w:"TIP",c:"Tip of the tongue"},
]},
// 54 FINGER
{answer:"FINGER",v:["FINGERS","FINGERED"],clues:[
  {w:"BUTTER",c:"Butterfingers"},
  {w:"LADY",c:"Ladyfinger (biscuit)"},
  {w:"FISH",c:"Fish finger"},
  {w:"PRINT",c:"Fingerprint"},
  {w:"POINT",c:"Point the finger"},
]},
// 55 SHOULDER
{answer:"SHOULDER",v:["SHOULDERS","SHOULDERED"],clues:[
  {w:"COLD",c:"Cold shoulder"},
  {w:"CHIP",c:"Chip on your shoulder"},
  {w:"HARD",c:"Hard shoulder (motorway)"},
  {w:"BLADE",c:"Shoulder blade"},
  {w:"PAD",c:"Shoulder pad"},
]},
// 56 CHEST — changed: NUT now clue 1, OFF→WAR
{answer:"CHEST",v:["CHESTS"],clues:[
  {w:"NUT",c:"Chestnut"},
  {w:"TREASURE",c:"Treasure chest"},
  {w:"WAR",c:"War chest"},
  {w:"HAIR",c:"Chest hair"},
  {w:"MEDICINE",c:"Medicine chest"},
]},
// 57 JAW
{answer:"JAW",v:["JAWS","JAWED"],clues:[
  {w:"BONE",c:"Jawbone"},
  {w:"SLACK",c:"Slack-jawed"},
  {w:"DROP",c:"Jaw-dropping"},
  {w:"LOCK",c:"Lockjaw"},
  {w:"SHARK",c:"Jaws (the movie)"},
]},
// 58 KNEE — changed: BEG→PAD
{answer:"KNEE",v:["KNEES","KNEED"],clues:[
  {w:"JERK",c:"Knee-jerk reaction"},
  {w:"DEEP",c:"Knee-deep"},
  {w:"CAP",c:"Kneecap"},
  {w:"WEAK",c:"Weak at the knees"},
  {w:"PAD",c:"Knee pad"},
]},
// 59 LIP — changed: BITE and SERVICE swapped
{answer:"LIP",v:["LIPS","LIPPED"],clues:[
  {w:"BITE",c:"Bite your lip"},
  {w:"STIFF",c:"Stiff upper lip"},
  {w:"READ",c:"Lip reading"},
  {w:"STICK",c:"Lipstick"},
  {w:"SERVICE",c:"Lip service"},
]},
// 60 SKIN — changed: BUCK→CRAWL, GOOSE→CARE
{answer:"SKIN",v:["SKINS","SKINNED","SKINNING"],clues:[
  {w:"CRAWL",c:"Makes your skin crawl"},
  {w:"THICK",c:"Thick-skinned"},
  {w:"DEEP",c:"Skin deep"},
  {w:"CARE",c:"Skincare"},
  {w:"BANANA",c:"Banana skin"},
]},
// 61 BONE
{answer:"BONE",v:["BONES","BONED"],clues:[
  {w:"TROM",c:"Trombone"},
  {w:"DRY",c:"Bone dry"},
  {w:"LAZY",c:"Lazy bones"},
  {w:"WISH",c:"Wishbone"},
  {w:"BACK",c:"Backbone"},
]},
// 62 TOOTH — changed: reordered FAIRY→SWEET→SABER→PASTE→BRUSH
{answer:"TOOTH",v:["TEETH","TOOTHED"],clues:[
  {w:"FAIRY",c:"Tooth fairy"},
  {w:"SWEET",c:"Sweet tooth"},
  {w:"SABER",c:"Saber-toothed"},
  {w:"PASTE",c:"Toothpaste"},
  {w:"BRUSH",c:"Toothbrush"},
]},
// 63 SPINE — changed: LESS now clue 1, rest shifted
{answer:"SPINE",v:["SPINES","SPINAL"],clues:[
  {w:"LESS",c:"Spineless"},
  {w:"TINGLING",c:"Spine-tingling"},
  {w:"CHILL",c:"Chill down your spine"},
  {w:"BOOK",c:"Spine of a book"},
  {w:"CORD",c:"Spinal cord"},
]},
// 64 PALM
{answer:"PALM",v:["PALMS","PALMED"],clues:[
  {w:"GREASE",c:"Grease someone's palm"},
  {w:"SUNDAY",c:"Palm Sunday"},
  {w:"READ",c:"Palm reading"},
  {w:"TREE",c:"Palm tree"},
  {w:"HAND",c:"Palm of your hand"},
]},

// ─── BATCH 2: NATURE (#65–#89) ───────────────────────

// 65 STORM — changed: TEA→BARN
{answer:"STORM",v:["STORMS","STORMED","STORMING"],clues:[
  {w:"BRAIN",c:"Brainstorm"},
  {w:"BARN",c:"Barnstormer"},
  {w:"FIRE",c:"Firestorm"},
  {w:"THUNDER",c:"Thunderstorm"},
  {w:"SNOW",c:"Snowstorm"},
]},
// 66 STONE
{answer:"STONE",v:["STONES","STONED"],clues:[
  {w:"MILE",c:"Milestone"},
  {w:"LIME",c:"Limestone"},
  {w:"STEPPING",c:"Stepping stone"},
  {w:"KIDNEY",c:"Kidney stone"},
  {w:"ROLLING",c:"Rolling Stones"},
]},
// 67 ROOT
{answer:"ROOT",v:["ROOTS","ROOTED","ROOTING"],clues:[
  {w:"SQUARE",c:"Square root"},
  {w:"GRASS",c:"Grassroots"},
  {w:"CANAL",c:"Root canal"},
  {w:"BEER",c:"Root beer"},
  {w:"TREE",c:"Tree roots"},
]},
// 68 FLOWER
{answer:"FLOWER",v:["FLOWERS","FLOWERED","FLOWERING"],clues:[
  {w:"WALL",c:"Wallflower"},
  {w:"CAULI",c:"Cauliflower"},
  {w:"SUN",c:"Sunflower"},
  {w:"BED",c:"Flower bed"},
  {w:"POWER",c:"Flower power"},
]},
// 69 BRANCH
{answer:"BRANCH",v:["BRANCHES","BRANCHED","BRANCHING"],clues:[
  {w:"OLIVE",c:"Olive branch"},
  {w:"EXECUTIVE",c:"Executive branch"},
  {w:"OUT",c:"Branch out"},
  {w:"MANAGER",c:"Branch manager"},
  {w:"TREE",c:"Tree branch"},
]},
// 70 FIELD
{answer:"FIELD",v:["FIELDS","FIELDED"],clues:[
  {w:"MINE",c:"Minefield"},
  {w:"LEFT",c:"Out of left field"},
  {w:"TRIP",c:"Field trip"},
  {w:"CORN",c:"Cornfield"},
  {w:"PLAYING",c:"Playing field"},
]},
// 71 CLOUD — changed: STORAGE now clue 1, rest shifted
{answer:"CLOUD",v:["CLOUDS","CLOUDED","CLOUDY"],clues:[
  {w:"STORAGE",c:"Cloud storage"},
  {w:"NINE",c:"Cloud nine"},
  {w:"MUSHROOM",c:"Mushroom cloud"},
  {w:"THUNDER",c:"Thundercloud"},
  {w:"RAIN",c:"Rain cloud"},
]},
// 72 FROST — changed: WINDOW→GLASS
{answer:"FROST",v:["FROSTS","FROSTED","FROSTY"],clues:[
  {w:"ROBERT",c:"Robert Frost (poet)"},
  {w:"BITE",c:"Frostbite"},
  {w:"MORNING",c:"Morning frost"},
  {w:"JACK",c:"Jack Frost"},
  {w:"GLASS",c:"Frosted glass"},
]},
// 73 SNOW
{answer:"SNOW",v:["SNOWS","SNOWED","SNOWING","SNOWY"],clues:[
  {w:"JOB",c:"Snow job (deception)"},
  {w:"BALL",c:"Snowball"},
  {w:"FLAKE",c:"Snowflake"},
  {w:"WHITE",c:"Snow White"},
  {w:"MAN",c:"Snowman"},
]},
// 74 ICE — changed: CUBE now clue 1, VICE removed→BREAK added
{answer:"ICE",v:["ICED","ICY","ICING"],clues:[
  {w:"CUBE",c:"Ice cube"},
  {w:"THIN",c:"On thin ice"},
  {w:"DRY",c:"Dry ice"},
  {w:"CREAM",c:"Ice cream"},
  {w:"BREAK",c:"Icebreaker"},
]},
// 75 SAND — changed: BEACH now clue 1, CASTLE clue 2
{answer:"SAND",v:["SANDS","SANDED","SANDING","SANDY"],clues:[
  {w:"BEACH",c:"Beach sand"},
  {w:"CASTLE",c:"Sandcastle"},
  {w:"QUICK",c:"Quicksand"},
  {w:"PAPER",c:"Sandpaper"},
  {w:"STORM",c:"Sandstorm"},
]},
// 76 WOOD
{answer:"WOOD",v:["WOODS","WOODED","WOODEN"],clues:[
  {w:"DRIFT",c:"Driftwood"},
  {w:"DEAD",c:"Deadwood"},
  {w:"HOLLY",c:"Hollywood"},
  {w:"FIRE",c:"Firewood"},
  {w:"PECKER",c:"Woodpecker"},
]},
// 77 DUST — changed: PAN now clue 1
{answer:"DUST",v:["DUSTED","DUSTING","DUSTY"],clues:[
  {w:"PAN",c:"Dustpan"},
  {w:"STAR",c:"Stardust"},
  {w:"SAW",c:"Sawdust"},
  {w:"BITE",c:"Bite the dust"},
  {w:"GOLD",c:"Gold dust"},
]},
// 78 SEED
{answer:"SEED",v:["SEEDS","SEEDED","SEEDING"],clues:[
  {w:"SESAME",c:"Sesame seed"},
  {w:"BIRD",c:"Birdseed"},
  {w:"DOUBT",c:"Seed of doubt"},
  {w:"SUN",c:"Sunflower seed"},
  {w:"PLANT",c:"Plant a seed"},
]},
// 79 LEAF — changed: OVER→BAY
{answer:"LEAF",v:["LEAVES","LEAFED","LEAFY"],clues:[
  {w:"TURN",c:"Turn over a new leaf"},
  {w:"BAY",c:"Bay leaf"},
  {w:"GOLD",c:"Gold leaf"},
  {w:"TEA",c:"Tea leaf"},
  {w:"MAPLE",c:"Maple leaf"},
]},
// 80 WIND
{answer:"WIND",v:["WINDS","WINDED","WINDING"],clues:[
  {w:"SECOND",c:"Second wind"},
  {w:"WHIRL",c:"Whirlwind"},
  {w:"SHIELD",c:"Windshield"},
  {w:"TRADE",c:"Trade winds"},
  {w:"MILL",c:"Windmill"},
]},
// 81 LAKE
{answer:"LAKE",v:["LAKES"],clues:[
  {w:"SWAN",c:"Swan Lake"},
  {w:"SALT",c:"Salt Lake City"},
  {w:"GREAT",c:"Great Lakes"},
  {w:"DISTRICT",c:"Lake District"},
  {w:"FISHING",c:"Fishing in a lake"},
]},
// 82 RIVER — changed: removed DELIVER, UP, DRIVER (contained/weak)
{answer:"RIVER",v:["RIVERS"],clues:[
  {w:"BED",c:"Riverbed"},
  {w:"SELL",c:"Sell someone down the river"},
  {w:"SIDE",c:"Riverside"},
  {w:"AMAZON",c:"Amazon River"},
  {w:"BANK",c:"River bank"},
]},
// 83 HILL
{answer:"HILL",v:["HILLS"],clues:[
  {w:"ANT",c:"Anthill"},
  {w:"OVER",c:"Over the hill"},
  {w:"DOWN",c:"Downhill"},
  {w:"UP",c:"Uphill battle"},
  {w:"CLIMB",c:"Climb a hill"},
]},
// 84 MOON
{answer:"MOON",v:["MOONS","MOONED","MOONING"],clues:[
  {w:"HONEY",c:"Honeymoon"},
  {w:"ONCE",c:"Once in a blue moon"},
  {w:"FULL",c:"Full moon"},
  {w:"WALK",c:"Moonwalk"},
  {w:"LIGHT",c:"Moonlight"},
]},
// 85 SUN
{answer:"SUN",v:["SUNS","SUNNED","SUNNY"],clues:[
  {w:"DOWN",c:"Sundown"},
  {w:"FLOWER",c:"Sunflower"},
  {w:"BURN",c:"Sunburn"},
  {w:"RISE",c:"Sunrise"},
  {w:"SCREEN",c:"Sunscreen"},
]},
// 86 STAR
{answer:"STAR",v:["STARS","STARRED","STARRING","STARRY"],clues:[
  {w:"ALL",c:"All-star"},
  {w:"SHOOTING",c:"Shooting star"},
  {w:"FISH",c:"Starfish"},
  {w:"WARS",c:"Star Wars"},
  {w:"NIGHT",c:"Starry night"},
]},
// 87 EARTH
{answer:"EARTH",v:["EARTHS","EARTHED","EARTHY"],clues:[
  {w:"SALT",c:"Salt of the earth"},
  {w:"SCORCHED",c:"Scorched earth"},
  {w:"QUAKE",c:"Earthquake"},
  {w:"DOWN",c:"Down to earth"},
  {w:"WORM",c:"Earthworm"},
]},
// 88 TIDE — was WAVE (duplicate), replaced
{answer:"TIDE",v:["TIDES","TIDAL"],clues:[
  {w:"TURNING",c:"Turning of the tide"},
  {w:"RIP",c:"Riptide"},
  {w:"CRIMSON",c:"Crimson Tide"},
  {w:"HIGH",c:"High tide"},
  {w:"LOW",c:"Low tide"},
]},
// 89 ROSE
{answer:"ROSE",v:["ROSES"],clues:[
  {w:"PRIM",c:"Primrose"},
  {w:"COMPASS",c:"Compass rose"},
  {w:"BUD",c:"Rosebud"},
  {w:"THORN",c:"Every rose has its thorn"},
  {w:"RED",c:"Red rose"},
]},

// ─── BATCH 3: OBJECTS & HOME (#90–#119) ──────────────

// 90 DOOR
{answer:"DOOR",v:["DOORS"],clues:[
  {w:"TRAP",c:"Trapdoor"},
  {w:"REVOLVING",c:"Revolving door"},
  {w:"NEXT",c:"Next door"},
  {w:"BELL",c:"Doorbell"},
  {w:"STEP",c:"Doorstep"},
]},
// 91 WALL
{answer:"WALL",v:["WALLS","WALLED"],clues:[
  {w:"FIRE",c:"Firewall"},
  {w:"STONE",c:"Stonewall"},
  {w:"STREET",c:"Wall Street"},
  {w:"BRICK",c:"Brick wall"},
  {w:"PAPER",c:"Wallpaper"},
]},
// 92 TABLE — changed: UNDER→WAIT
{answer:"TABLE",v:["TABLES","TABLED"],clues:[
  {w:"TURN",c:"Turntable"},
  {w:"TIME",c:"Timetable"},
  {w:"ROUND",c:"Round table"},
  {w:"WAIT",c:"Wait tables"},
  {w:"DINNER",c:"Dinner table"},
]},
// 93 WIRE
{answer:"WIRE",v:["WIRES","WIRED","WIRING"],clues:[
  {w:"TRIP",c:"Tripwire"},
  {w:"LESS",c:"Wireless"},
  {w:"HIGH",c:"High-wire act"},
  {w:"BARBED",c:"Barbed wire"},
  {w:"LIVE",c:"Live wire"},
]},
// 94 PIN
{answer:"PIN",v:["PINS","PINNED","PINNING"],clues:[
  {w:"KING",c:"Kingpin"},
  {w:"ROLLING",c:"Rolling pin"},
  {w:"TAIL",c:"Pin the tail on the donkey"},
  {w:"CUSHION",c:"Pincushion"},
  {w:"SAFETY",c:"Safety pin"},
]},
// 95 BAR — changed: BEHIND now clue 1
{answer:"BAR",v:["BARS","BARRED","BARRING"],clues:[
  {w:"BEHIND",c:"Behind bars"},
  {w:"CROW",c:"Crowbar"},
  {w:"HANDLE",c:"Handlebar"},
  {w:"SIDE",c:"Sidebar"},
  {w:"GOLD",c:"Gold bar"},
]},
// 96 BOX — changed: POST now clue 1
{answer:"BOX",v:["BOXES","BOXED","BOXING"],clues:[
  {w:"POST",c:"Post box"},
  {w:"SAND",c:"Sandbox"},
  {w:"PANDORA",c:"Pandora's box"},
  {w:"JUKE",c:"Jukebox"},
  {w:"CARD",c:"Cardboard box"},
]},
// 97 NET
{answer:"NET",v:["NETS","NETTED","NETTING"],clues:[
  {w:"SAFETY",c:"Safety net"},
  {w:"BASKET",c:"Basketball net"},
  {w:"HAIR",c:"Hairnet"},
  {w:"DRAG",c:"Dragnet"},
  {w:"FISHING",c:"Fishing net"},
]},
// 98 HOOK — changed: OFF now clue 1, CAPTAIN now clue 5
{answer:"HOOK",v:["HOOKS","HOOKED","HOOKING"],clues:[
  {w:"OFF",c:"Off the hook"},
  {w:"SINKER",c:"Hook, line and sinker"},
  {w:"CROCHET",c:"Crochet hook"},
  {w:"FISH",c:"Fish hook"},
  {w:"CAPTAIN",c:"Captain Hook"},
]},
// 99 PIPE — changed: DREAM now clue 1
{answer:"PIPE",v:["PIPES","PIPED","PIPING"],clues:[
  {w:"DREAM",c:"Pipe dream"},
  {w:"BAG",c:"Bagpipes"},
  {w:"LINE",c:"Pipeline"},
  {w:"DOWN",c:"Pipe down"},
  {w:"SMOKING",c:"Smoking pipe"},
]},
// 100 BELT
{answer:"BELT",v:["BELTS","BELTED"],clues:[
  {w:"RUST",c:"Rust Belt"},
  {w:"BIBLE",c:"Bible Belt"},
  {w:"BLACK",c:"Black belt"},
  {w:"SEAT",c:"Seat belt"},
  {w:"BUCKLE",c:"Belt buckle"},
]},
// 101 CAP — changed: BOTTLE now clue 1, HANDI now clue 5
{answer:"CAP",v:["CAPS","CAPPED","CAPPING"],clues:[
  {w:"BOTTLE",c:"Bottle cap"},
  {w:"KNEE",c:"Kneecap"},
  {w:"ICE",c:"Ice cap"},
  {w:"NIGHT",c:"Nightcap"},
  {w:"HANDI",c:"Handicap"},
]},
// 102 BLOCK
{answer:"BLOCK",v:["BLOCKS","BLOCKED","BLOCKING"],clues:[
  {w:"WRITER",c:"Writer's block"},
  {w:"ROAD",c:"Roadblock"},
  {w:"CHIP",c:"Chip off the old block"},
  {w:"MENTAL",c:"Mental block"},
  {w:"BUILDING",c:"Building block"},
]},
// 103 ROPE — changed: SHOW now clue 1
{answer:"ROPE",v:["ROPES","ROPED"],clues:[
  {w:"SHOW",c:"Show someone the ropes"},
  {w:"TIGHT",c:"Tightrope"},
  {w:"SKIP",c:"Skipping rope"},
  {w:"JUMP",c:"Jump rope"},
  {w:"TUG",c:"Tug of war rope"},
]},
// 104 PLUG — changed: SHAM removed, PULL now clue 1, BATH added
{answer:"PLUG",v:["PLUGS","PLUGGED","PLUGGING"],clues:[
  {w:"PULL",c:"Pull the plug"},
  {w:"SPARK",c:"Spark plug"},
  {w:"EAR",c:"Earplug"},
  {w:"BATH",c:"Bath plug"},
  {w:"ELECTRIC",c:"Electric plug"},
]},
// 105 CARD
{answer:"CARD",v:["CARDS","CARDED"],clues:[
  {w:"WILD",c:"Wildcard"},
  {w:"POST",c:"Postcard"},
  {w:"SCORE",c:"Scorecard"},
  {w:"REPORT",c:"Report card"},
  {w:"PLAYING",c:"Playing card"},
]},
// 106 CAN — changed: PELICAN removed (contained), WORMS now clue 1
{answer:"CAN",v:["CANS","CANNED","CANNING"],clues:[
  {w:"WORMS",c:"Can of worms"},
  {w:"TRASH",c:"Trash can"},
  {w:"WATERING",c:"Watering can"},
  {w:"SPRAY",c:"Spray can"},
  {w:"TIN",c:"Tin can"},
]},
// 107 BED
{answer:"BED",v:["BEDS","BEDDED"],clues:[
  {w:"HOT",c:"Hotbed"},
  {w:"RIVER",c:"Riverbed"},
  {w:"ROSE",c:"Bed of roses"},
  {w:"BUG",c:"Bed bug"},
  {w:"TIME",c:"Bedtime"},
]},
// 108 CUT
{answer:"CUT",v:["CUTS","CUTTING"],clues:[
  {w:"SHORT",c:"Shortcut"},
  {w:"CLEAR",c:"Clear cut"},
  {w:"TAX",c:"Tax cut"},
  {w:"POWER",c:"Power cut"},
  {w:"PAPER",c:"Paper cut"},
]},
// 109 ROOM
{answer:"ROOM",v:["ROOMS","ROOMED"],clues:[
  {w:"SHOW",c:"Showroom"},
  {w:"ELBOW",c:"Elbow room"},
  {w:"MUSH",c:"Mushroom"},
  {w:"DARK",c:"Darkroom"},
  {w:"CLASS",c:"Classroom"},
]},
// 110 HOUSE
{answer:"HOUSE",v:["HOUSES","HOUSED","HOUSING"],clues:[
  {w:"WARE",c:"Warehouse"},
  {w:"FULL",c:"Full house"},
  {w:"DOG",c:"Doghouse"},
  {w:"GREEN",c:"Greenhouse"},
  {w:"FIRE",c:"Firehouse"},
]},
// 111 LOCK — changed: WARD→SMITH
{answer:"LOCK",v:["LOCKS","LOCKED","LOCKING"],clues:[
  {w:"GRID",c:"Gridlock"},
  {w:"SMITH",c:"Locksmith"},
  {w:"DEAD",c:"Deadlock"},
  {w:"PAD",c:"Padlock"},
  {w:"KEY",c:"Lock and key"},
]},
// 112 FLOOR — was RING (duplicate), replaced entirely
{answer:"FLOOR",v:["FLOORS","FLOORED","FLOORING"],clues:[
  {w:"DANCE",c:"Dance floor"},
  {w:"GROUND",c:"Ground floor"},
  {w:"BOARD",c:"Floorboard"},
  {w:"PLAN",c:"Floor plan"},
  {w:"SHOW",c:"Showroom floor"},
]},
// 113 CHAIR — changed: ELECTRIC now clue 1
{answer:"CHAIR",v:["CHAIRS","CHAIRED"],clues:[
  {w:"ELECTRIC",c:"Electric chair"},
  {w:"ARM",c:"Armchair"},
  {w:"HIGH",c:"Highchair"},
  {w:"WHEEL",c:"Wheelchair"},
  {w:"ROCKING",c:"Rocking chair"},
]},
// 114 CLOCK — changed: ALARM and WISE swapped
{answer:"CLOCK",v:["CLOCKS","CLOCKED","CLOCKING"],clues:[
  {w:"BIO",c:"Biological clock"},
  {w:"WISE",c:"Clockwise"},
  {w:"ALARM",c:"Alarm clock"},
  {w:"WORK",c:"Clockwork"},
  {w:"TOWER",c:"Clock tower"},
]},
// 115 WINDOW
{answer:"WINDOW",v:["WINDOWS"],clues:[
  {w:"OPPORTUNITY",c:"Window of opportunity"},
  {w:"SHOP",c:"Window shopping"},
  {w:"FRENCH",c:"French windows"},
  {w:"LEDGE",c:"Window ledge"},
  {w:"PANE",c:"Window pane"},
]},
// 116 POOL — was BRIDGE (duplicate), replaced entirely
{answer:"POOL",v:["POOLS","POOLED","POOLING"],clues:[
  {w:"CAR",c:"Carpool"},
  {w:"GENE",c:"Gene pool"},
  {w:"DEAD",c:"Deadpool"},
  {w:"TABLE",c:"Pool table"},
  {w:"SWIMMING",c:"Swimming pool"},
]},
// 117 BAND — was RING (duplicate), replaced entirely
{answer:"BAND",v:["BANDS","BANDED"],clues:[
  {w:"BROAD",c:"Broadband"},
  {w:"RUBBER",c:"Rubber band"},
  {w:"ARM",c:"Armband"},
  {w:"WAGON",c:"Bandwagon"},
  {w:"WEDDING",c:"Wedding band"},
]},
// 118 CARPET
{answer:"CARPET",v:["CARPETS","CARPETED"],clues:[
  {w:"MAGIC",c:"Magic carpet"},
  {w:"SWEEP",c:"Sweep under the carpet"},
  {w:"BOMB",c:"Carpet bomb"},
  {w:"RED",c:"Red carpet"},
  {w:"FLOOR",c:"Carpet on the floor"},
]},
// 119 MIRROR — changed: SMOKE now clue 1
{answer:"MIRROR",v:["MIRRORS","MIRRORED"],clues:[
  {w:"SMOKE",c:"Smoke and mirrors"},
  {w:"REAR",c:"Rear-view mirror"},
  {w:"IMAGE",c:"Mirror image"},
  {w:"WING",c:"Wing mirror"},
  {w:"BATHROOM",c:"Bathroom mirror"},
]},

// ─── BATCH 4: ACTIONS (#120–#159) ────────────────────

// 120 DRAW
{answer:"DRAW",v:["DRAWS","DREW","DRAWN","DRAWING"],clues:[
  {w:"LUCK",c:"Luck of the draw"},
  {w:"QUICK",c:"Quick draw"},
  {w:"SWORD",c:"Draw a sword"},
  {w:"BRIDGE",c:"Drawbridge"},
  {w:"BLANK",c:"Draw a blank"},
]},
// 121 RUN
{answer:"RUN",v:["RUNS","RUNNING","RAN"],clues:[
  {w:"LONG",c:"In the long run"},
  {w:"WAY",c:"Runway"},
  {w:"HOME",c:"Home run"},
  {w:"DOWN",c:"Run-down"},
  {w:"OUT",c:"Run out"},
]},
// 122 PLAY
{answer:"PLAY",v:["PLAYS","PLAYED","PLAYING"],clues:[
  {w:"HORSE",c:"Horseplay"},
  {w:"SWORD",c:"Swordplay"},
  {w:"FAIR",c:"Fair play"},
  {w:"FOUL",c:"Foul play"},
  {w:"CHILD",c:"Child's play"},
]},
// 123 DRIVE
{answer:"DRIVE",v:["DRIVES","DROVE","DRIVEN","DRIVING"],clues:[
  {w:"OVER",c:"Overdrive"},
  {w:"HARD",c:"Hard drive"},
  {w:"TEST",c:"Test drive"},
  {w:"WAY",c:"Driveway"},
  {w:"ROAD",c:"Drive down the road"},
]},
// 124 PRESS — changed: EX/IM removed (contained), BUTTON now clue 1
{answer:"PRESS",v:["PRESSED","PRESSING","PRESSES"],clues:[
  {w:"BUTTON",c:"Press a button"},
  {w:"IRON",c:"Iron press"},
  {w:"DRILL",c:"Drill press"},
  {w:"FLOWER",c:"Pressed flower"},
  {w:"CONFERENCE",c:"Press conference"},
]},
// 125 MARK — changed: HALL now clue 1
{answer:"MARK",v:["MARKS","MARKED","MARKING"],clues:[
  {w:"HALL",c:"Hallmark"},
  {w:"BOOK",c:"Bookmark"},
  {w:"TRADE",c:"Trademark"},
  {w:"QUESTION",c:"Question mark"},
  {w:"TARGET",c:"Hit the mark"},
]},
// 126 HOLD — changed: UP now clue 1
{answer:"HOLD",v:["HOLDS","HELD","HOLDING"],clues:[
  {w:"UP",c:"Hold-up"},
  {w:"STRONG",c:"Stronghold"},
  {w:"HOUSE",c:"Household"},
  {w:"FOOT",c:"Foothold"},
  {w:"BREATH",c:"Hold your breath"},
]},
// 127 DROP — changed: NAME now clue 1
{answer:"DROP",v:["DROPS","DROPPED","DROPPING"],clues:[
  {w:"NAME",c:"Name-dropping"},
  {w:"BACK",c:"Backdrop"},
  {w:"RAIN",c:"Raindrop"},
  {w:"OUT",c:"Drop out"},
  {w:"DEW",c:"Dewdrop"},
]},
// 128 CHARGE
{answer:"CHARGE",v:["CHARGES","CHARGED","CHARGING"],clues:[
  {w:"DEPTH",c:"Depth charge"},
  {w:"FREE",c:"Free of charge"},
  {w:"BATTERY",c:"Charge a battery"},
  {w:"COVER",c:"Cover charge"},
  {w:"CAVALRY",c:"Cavalry charge"},
]},
// 129 LAND
{answer:"LAND",v:["LANDS","LANDED","LANDING"],clues:[
  {w:"WASTE",c:"Wasteland"},
  {w:"DREAM",c:"Dreamland"},
  {w:"MARK",c:"Landmark"},
  {w:"LORD",c:"Landlord"},
  {w:"PROMISED",c:"Promised land"},
]},
// 130 STAND
{answer:"STAND",v:["STANDS","STOOD","STANDING"],clues:[
  {w:"GRAND",c:"Grandstand"},
  {w:"BAND",c:"Bandstand"},
  {w:"LAST",c:"Last stand"},
  {w:"ONE",c:"One-night stand"},
  {w:"TAXI",c:"Taxi stand"},
]},
// 131 STRIKE — changed: GOLD now clue 1
{answer:"STRIKE",v:["STRIKES","STRUCK","STRIKING"],clues:[
  {w:"GOLD",c:"Strike gold"},
  {w:"BOWLING",c:"Bowling strike"},
  {w:"LIGHTNING",c:"Lightning strike"},
  {w:"AIR",c:"Airstrike"},
  {w:"MATCH",c:"Strike a match"},
]},
// 132 TURN
{answer:"TURN",v:["TURNS","TURNED","TURNING"],clues:[
  {w:"TABLES",c:"Turn the tables"},
  {w:"COAT",c:"Turncoat"},
  {w:"AROUND",c:"Turnaround"},
  {w:"U",c:"U-turn"},
  {w:"LEFT",c:"Turn left"},
]},
// 133 SWING
{answer:"SWING",v:["SWINGS","SWUNG","SWINGING"],clues:[
  {w:"MOOD",c:"Mood swing"},
  {w:"FULL",c:"In full swing"},
  {w:"VOTE",c:"Swing vote"},
  {w:"DOOR",c:"Swinging door"},
  {w:"PORCH",c:"Porch swing"},
]},
// 134 ROLL
{answer:"ROLL",v:["ROLLS","ROLLED","ROLLING"],clues:[
  {w:"BARREL",c:"Barrel roll"},
  {w:"HONOUR",c:"Honour roll"},
  {w:"ROCK",c:"Rock and roll"},
  {w:"BREAD",c:"Bread roll"},
  {w:"DICE",c:"Roll the dice"},
]},
// 135 SLIP
{answer:"SLIP",v:["SLIPS","SLIPPED","SLIPPING"],clues:[
  {w:"FREUDIAN",c:"Freudian slip"},
  {w:"PINK",c:"Pink slip (fired)"},
  {w:"STREAM",c:"Slipstream"},
  {w:"KNOT",c:"Slipknot"},
  {w:"BANANA",c:"Slip on a banana"},
]},
// 136 TRIP
{answer:"TRIP",v:["TRIPS","TRIPPED","TRIPPING"],clues:[
  {w:"GUILT",c:"Guilt trip"},
  {w:"EGO",c:"Ego trip"},
  {w:"ROAD",c:"Road trip"},
  {w:"ROUND",c:"Round trip"},
  {w:"FIELD",c:"Field trip"},
]},
// 137 BLOW
{answer:"BLOW",v:["BLOWS","BLEW","BLOWN","BLOWING"],clues:[
  {w:"WHISTLE",c:"Whistleblower"},
  {w:"MIND",c:"Mind-blowing"},
  {w:"SNOW",c:"Snowblower"},
  {w:"OVER",c:"Blow over"},
  {w:"CANDLE",c:"Blow out a candle"},
]},
// 138 CATCH
{answer:"CATCH",v:["CATCHES","CAUGHT","CATCHING"],clues:[
  {w:"TWENTY",c:"Catch-22"},
  {w:"PHRASE",c:"Catchphrase"},
  {w:"EYE",c:"Eye-catching"},
  {w:"GOOD",c:"Good catch"},
  {w:"BALL",c:"Catch a ball"},
]},
// 139 SHOT
{answer:"SHOT",v:["SHOTS"],clues:[
  {w:"LONG",c:"Long shot"},
  {w:"BUCK",c:"Buckshot"},
  {w:"SCREEN",c:"Screenshot"},
  {w:"MUG",c:"Mugshot"},
  {w:"GUN",c:"Gunshot"},
]},
// 140 LIFT
{answer:"LIFT",v:["LIFTS","LIFTED","LIFTING"],clues:[
  {w:"SHOP",c:"Shoplifting"},
  {w:"AIR",c:"Airlift"},
  {w:"FACE",c:"Facelift"},
  {w:"SPIRIT",c:"Lift your spirits"},
  {w:"SKI",c:"Ski lift"},
]},
// 141 SPOT
{answer:"SPOT",v:["SPOTS","SPOTTED","SPOTTING"],clues:[
  {w:"SUN",c:"Sunspot"},
  {w:"BLIND",c:"Blind spot"},
  {w:"HOT",c:"Hotspot"},
  {w:"LIGHT",c:"Spotlight"},
  {w:"SWEET",c:"Sweet spot"},
]},
// 142 DRAG
{answer:"DRAG",v:["DRAGS","DRAGGED","DRAGGING"],clues:[
  {w:"QUEEN",c:"Drag queen"},
  {w:"RACE",c:"Drag race"},
  {w:"MAIN",c:"Main drag"},
  {w:"NET",c:"Dragnet"},
  {w:"FEET",c:"Drag your feet"},
]},
// 143 SNAP
{answer:"SNAP",v:["SNAPS","SNAPPED","SNAPPING"],clues:[
  {w:"GINGER",c:"Gingersnap"},
  {w:"COLD",c:"Cold snap"},
  {w:"CHAT",c:"Snapchat"},
  {w:"DECISION",c:"Snap decision"},
  {w:"FINGER",c:"Snap your fingers"},
]},
// 144 BRICK — was BLOCK (duplicate), replaced entirely
{answer:"BRICK",v:["BRICKS","BRICKED"],clues:[
  {w:"GOLD",c:"Gold brick (swindle)"},
  {w:"LAYER",c:"Bricklayer"},
  {w:"WALL",c:"Brick wall"},
  {w:"YELLOW",c:"Yellow brick road"},
  {w:"HOUSE",c:"Brick house"},
]},
// 145 PUSH
{answer:"PUSH",v:["PUSHES","PUSHED","PUSHING"],clues:[
  {w:"OVER",c:"Pushover"},
  {w:"UP",c:"Push-up"},
  {w:"BUTTON",c:"Push-button"},
  {w:"BACK",c:"Pushback"},
  {w:"PRAM",c:"Push a pram"},
]},
// 146 PULL
{answer:"PULL",v:["PULLS","PULLED","PULLING"],clues:[
  {w:"HEART",c:"Pull at heartstrings"},
  {w:"STRINGS",c:"Pull strings"},
  {w:"PLUG",c:"Pull the plug"},
  {w:"WEIGHT",c:"Pull your weight"},
  {w:"TRIGGER",c:"Pull the trigger"},
]},
// 147 SET
{answer:"SET",v:["SETS","SETTING"],clues:[
  {w:"SUN",c:"Sunset"},
  {w:"MIND",c:"Mindset"},
  {w:"BACK",c:"Setback"},
  {w:"UP",c:"Setup"},
  {w:"CHESS",c:"Chess set"},
]},
// 148 STICK
{answer:"STICK",v:["STICKS","STUCK","STICKING"],clues:[
  {w:"LIP",c:"Lipstick"},
  {w:"CHOP",c:"Chopstick"},
  {w:"DRUM",c:"Drumstick"},
  {w:"CANDLE",c:"Candlestick"},
  {w:"HOCKEY",c:"Hockey stick"},
]},
// 149 KICK
{answer:"KICK",v:["KICKS","KICKED","KICKING"],clues:[
  {w:"SIDE",c:"Sidekick"},
  {w:"BUCKET",c:"Kick the bucket"},
  {w:"START",c:"Kickstart"},
  {w:"PENALTY",c:"Penalty kick"},
  {w:"FREE",c:"Free kick"},
]},
// 150 CRACK
{answer:"CRACK",v:["CRACKS","CRACKED","CRACKING"],clues:[
  {w:"WISE",c:"Wisecrack"},
  {w:"FIRE",c:"Firecracker"},
  {w:"DAWN",c:"Crack of dawn"},
  {w:"DOWN",c:"Crackdown"},
  {w:"NUT",c:"Nutcracker"},
]},
// 151 SLIDE — fixed: TROM→HAIR
{answer:"SLIDE",v:["SLIDES","SLID","SLIDING"],clues:[
  {w:"LAND",c:"Landslide"},
  {w:"HAIR",c:"Hair slide"},
  {w:"WATER",c:"Waterslide"},
  {w:"POWER",c:"PowerPoint slide"},
  {w:"PLAY",c:"Playground slide"},
]},
// 152 SPIN
{answer:"SPIN",v:["SPINS","SPUN","SPINNING"],clues:[
  {w:"TAIL",c:"Tailspin"},
  {w:"DOCTOR",c:"Spin doctor"},
  {w:"OFF",c:"Spin-off"},
  {w:"WHEEL",c:"Spinning wheel"},
  {w:"TOP",c:"Spinning top"},
]},
// 153 WRAP
{answer:"WRAP",v:["WRAPS","WRAPPED","WRAPPING"],clues:[
  {w:"SHRINK",c:"Shrink-wrap"},
  {w:"UNDER",c:"Under wraps"},
  {w:"GIFT",c:"Gift wrap"},
  {w:"BUBBLE",c:"Bubble wrap"},
  {w:"CHRISTMAS",c:"Christmas wrapping paper"},
]},
// 154 FENCE — fixed: DE removed (fragment pattern)
{answer:"FENCE",v:["FENCES","FENCED","FENCING"],clues:[
  {w:"SITTING",c:"Sitting on the fence"},
  {w:"SWORD",c:"Fencing (the sport)"},
  {w:"PICKET",c:"Picket fence"},
  {w:"GARDEN",c:"Garden fence"},
  {w:"POST",c:"Fence post"},
]},
// 155 TICK — fixed: STICK removed (contained TICK)
{answer:"TICK",v:["TICKS","TICKED","TICKING"],clues:[
  {w:"CLOCK",c:"Clock ticking"},
  {w:"BOMB",c:"Ticking time bomb"},
  {w:"OFF",c:"Tick someone off"},
  {w:"BOX",c:"Tick the box"},
  {w:"CROSS",c:"Tick or cross"},
]},
// 156 TAP
{answer:"TAP",v:["TAPS","TAPPED","TAPPING"],clues:[
  {w:"WIRE",c:"Wiretap"},
  {w:"DANCE",c:"Tap dance"},
  {w:"SHOULDER",c:"Tap on the shoulder"},
  {w:"BEER",c:"Beer on tap"},
  {w:"WATER",c:"Tap water"},
]},
// 157 DASH
{answer:"DASH",v:["DASHES","DASHED","DASHING"],clues:[
  {w:"HOPES",c:"Dash someone's hopes"},
  {w:"BOARD",c:"Dashboard"},
  {w:"HUNDRED",c:"Hundred-metre dash"},
  {w:"DOOR",c:"DoorDash"},
  {w:"SALT",c:"A dash of salt"},
]},
// 158 SWEEP
{answer:"SWEEP",v:["SWEEPS","SWEPT","SWEEPING"],clues:[
  {w:"CLEAN",c:"Clean sweep"},
  {w:"CHIMNEY",c:"Chimney sweep"},
  {w:"MINE",c:"Minesweeper"},
  {w:"STAKE",c:"Sweepstakes"},
  {w:"FLOOR",c:"Sweep the floor"},
]},
// 159 DEAL — fixed: ORDEAL removed (contained DEAL)
{answer:"DEAL",v:["DEALS","DEALT","DEALING"],clues:[
  {w:"WHEEL",c:"Wheel and deal"},
  {w:"RAW",c:"Raw deal"},
  {w:"BIG",c:"Big deal"},
  {w:"NEW",c:"New Deal"},
  {w:"CARDS",c:"Deal the cards"},
]},

// ─── BATCH 5: ABSTRACT & QUALITIES (#160–#189) ──────

// 160 COLD
{answer:"COLD",v:["COLDER","COLDEST"],clues:[
  {w:"SHOULDER",c:"Cold shoulder"},
  {w:"CASE",c:"Cold case"},
  {w:"FEET",c:"Cold feet"},
  {w:"TURKEY",c:"Cold turkey"},
  {w:"WAR",c:"Cold War"},
]},
// 161 HOT
{answer:"HOT",v:["HOTTER","HOTTEST"],clues:[
  {w:"DOG",c:"Hot dog"},
  {w:"HEADED",c:"Hot-headed"},
  {w:"POTATO",c:"Hot potato"},
  {w:"ROD",c:"Hot rod"},
  {w:"WATER",c:"Hot water"},
]},
// 162 DEEP
{answer:"DEEP",v:["DEEPER","DEEPEST"],clues:[
  {w:"SKIN",c:"Skin deep"},
  {w:"STATE",c:"Deep state"},
  {w:"END",c:"Deep end"},
  {w:"FREEZE",c:"Deep freeze"},
  {w:"SEA",c:"Deep sea"},
]},
// 163 DARK
{answer:"DARK",v:["DARKER","DARKEST","DARKNESS"],clues:[
  {w:"HORSE",c:"Dark horse"},
  {w:"WEB",c:"Dark web"},
  {w:"ROOM",c:"Darkroom"},
  {w:"AGES",c:"Dark Ages"},
  {w:"NIGHT",c:"After dark"},
]},
// 164 WILD
{answer:"WILD",v:["WILDER","WILDEST"],clues:[
  {w:"CARD",c:"Wildcard"},
  {w:"GOOSE",c:"Wild goose chase"},
  {w:"FIRE",c:"Wildfire"},
  {w:"WEST",c:"Wild West"},
  {w:"LIFE",c:"Wildlife"},
]},
// 165 LONG — fixed: FUR removed (LONG contained in FURLONG)
{answer:"LONG",v:["LONGER","LONGEST"],clues:[
  {w:"WINDED",c:"Long-winded"},
  {w:"SHOT",c:"Long shot"},
  {w:"LIFE",c:"Lifelong"},
  {w:"ISLAND",c:"Long Island"},
  {w:"SLEEVE",c:"Long sleeve"},
]},
// 166 SHORT
{answer:"SHORT",v:["SHORTER","SHORTEST","SHORTS"],clues:[
  {w:"SELL",c:"Short sell"},
  {w:"CIRCUIT",c:"Short circuit"},
  {w:"CHANGE",c:"Shortchanged"},
  {w:"HAND",c:"Shorthand"},
  {w:"CUT",c:"Shortcut"},
]},
// 167 FLAT
{answer:"FLAT",v:["FLATS","FLATTEN"],clues:[
  {w:"EARTH",c:"Flat earther"},
  {w:"TYRE",c:"Flat tyre"},
  {w:"LINE",c:"Flatline"},
  {w:"MATE",c:"Flatmate"},
  {w:"IRON",c:"Flat iron"},
]},
// 168 COOL
{answer:"COOL",v:["COOLER","COOLEST","COOLED","COOLING"],clues:[
  {w:"CUCUMBER",c:"Cool as a cucumber"},
  {w:"DOWN",c:"Cooldown"},
  {w:"JAZZ",c:"Cool jazz"},
  {w:"HEAD",c:"Cool-headed"},
  {w:"POOL",c:"Cooling pool"},
]},
// 169 ROUGH
{answer:"ROUGH",v:["ROUGHER","ROUGHEST","ROUGHED"],clues:[
  {w:"DIAMOND",c:"Diamond in the rough"},
  {w:"DRAFT",c:"Rough draft"},
  {w:"RIDER",c:"Rough Riders"},
  {w:"HOUSE",c:"Roughhouse"},
  {w:"PATCH",c:"Rough patch"},
]},
// 170 SOFT
{answer:"SOFT",v:["SOFTER","SOFTEST"],clues:[
  {w:"WARE",c:"Software"},
  {w:"SPOT",c:"Soft spot"},
  {w:"BALL",c:"Softball"},
  {w:"SPOKEN",c:"Soft-spoken"},
  {w:"SERVE",c:"Soft serve (ice cream)"},
]},
// 171 HARD
{answer:"HARD",v:["HARDER","HARDEST"],clues:[
  {w:"DIE",c:"Die Hard"},
  {w:"BALL",c:"Hardball"},
  {w:"COPY",c:"Hard copy"},
  {w:"CORE",c:"Hardcore"},
  {w:"ROCK",c:"Hard rock"},
]},
// 172 FINE — fixed: RE removed (fragment FINE in REFINE)
{answer:"FINE",v:["FINES","FINED","FINER","FINEST"],clues:[
  {w:"TUNE",c:"Fine-tune"},
  {w:"ART",c:"Fine art"},
  {w:"PRINT",c:"Fine print"},
  {w:"DINING",c:"Fine dining"},
  {w:"WINE",c:"Fine wine"},
]},
// 173 FAIR — fixed: AFFAIR removed (contained FAIR)
{answer:"FAIR",v:["FAIRS","FAIRER","FAIREST"],clues:[
  {w:"GROUND",c:"Fairground"},
  {w:"WEATHER",c:"Fair weather friend"},
  {w:"TRADE",c:"Fair trade"},
  {w:"GAME",c:"Fair game"},
  {w:"COUNTY",c:"County fair"},
]},
// 174 FREE
{answer:"FREE",v:["FREED","FREEING"],clues:[
  {w:"LANCE",c:"Freelance"},
  {w:"RANGE",c:"Free range"},
  {w:"LOAD",c:"Freeloader"},
  {w:"STYLE",c:"Freestyle"},
  {w:"FALL",c:"Freefall"},
]},
// 175 OPEN
{answer:"OPEN",v:["OPENS","OPENED","OPENING"],clues:[
  {w:"BOOK",c:"Open book"},
  {w:"ENDED",c:"Open-ended"},
  {w:"HEART",c:"Open-hearted"},
  {w:"WIDE",c:"Wide open"},
  {w:"DOOR",c:"Open door"},
]},
// 176 CLOSE — fixed: DIS removed (fragment CLOSE in DISCLOSE)
{answer:"CLOSE",v:["CLOSES","CLOSED","CLOSING"],clues:[
  {w:"CALL",c:"Close call"},
  {w:"KNIT",c:"Close-knit"},
  {w:"SHAVE",c:"Close shave"},
  {w:"RANGE",c:"Close range"},
  {w:"DOOR",c:"Close the door"},
]},
// 177 CLEAR — fixed: NU removed (fragment CLEAR in NUCLEAR)
{answer:"CLEAR",v:["CLEARS","CLEARED","CLEARING","CLEARER"],clues:[
  {w:"COAST",c:"Coast is clear"},
  {w:"CRYSTAL",c:"Crystal clear"},
  {w:"CUT",c:"Clear-cut"},
  {w:"HEAD",c:"Clear-headed"},
  {w:"SKY",c:"Clear sky"},
]},
// 178 THIN
{answer:"THIN",v:["THINNER","THINNEST"],clues:[
  {w:"AIR",c:"Thin air"},
  {w:"ICE",c:"On thin ice"},
  {w:"WEAR",c:"Wearing thin"},
  {w:"SKIN",c:"Thin-skinned"},
  {w:"PAPER",c:"Paper thin"},
]},
// 179 THICK
{answer:"THICK",v:["THICKER","THICKEST"],clues:[
  {w:"BLOOD",c:"Blood is thicker than water"},
  {w:"PLOT",c:"The plot thickens"},
  {w:"SKIN",c:"Thick-skinned"},
  {w:"THIEVES",c:"Thick as thieves"},
  {w:"SKULL",c:"Thick skull"},
]},
// 180 DOUBLE
{answer:"DOUBLE",v:["DOUBLES","DOUBLED","DOUBLING"],clues:[
  {w:"TROUBLE",c:"Double trouble"},
  {w:"DUTCH",c:"Double Dutch"},
  {w:"TAKE",c:"Double take"},
  {w:"EDGE",c:"Double-edged sword"},
  {w:"AGENT",c:"Double agent"},
]},
// 181 SINGLE
{answer:"SINGLE",v:["SINGLES","SINGLED"],clues:[
  {w:"HANDED",c:"Single-handedly"},
  {w:"MINDED",c:"Single-minded"},
  {w:"OUT",c:"Single out"},
  {w:"FILE",c:"Single file"},
  {w:"MALT",c:"Single malt"},
]},
// 182 SPARE
{answer:"SPARE",v:["SPARES","SPARED","SPARING"],clues:[
  {w:"BOWLING",c:"Bowling spare"},
  {w:"RIB",c:"Spare rib"},
  {w:"ROOM",c:"Spare room"},
  {w:"CHANGE",c:"Spare change"},
  {w:"TYRE",c:"Spare tyre"},
]},
// 183 BLANK
{answer:"BLANK",v:["BLANKS","BLANKED"],clues:[
  {w:"POINT",c:"Point blank"},
  {w:"DRAW",c:"Draw a blank"},
  {w:"CANVAS",c:"Blank canvas"},
  {w:"SPACE",c:"Blank space"},
  {w:"CHEQUE",c:"Blank cheque"},
]},
// 184 RAW
{answer:"RAW",v:["RAWER","RAWEST"],clues:[
  {w:"DEAL",c:"Raw deal"},
  {w:"NERVE",c:"Raw nerve"},
  {w:"MATERIAL",c:"Raw material"},
  {w:"TALENT",c:"Raw talent"},
  {w:"FISH",c:"Raw fish (sushi)"},
]},
// 185 STRAIGHT
{answer:"STRAIGHT",v:["STRAIGHTER","STRAIGHTEST"],clues:[
  {w:"NARROW",c:"Straight and narrow"},
  {w:"JACKET",c:"Straitjacket"},
  {w:"FACE",c:"Straight-faced"},
  {w:"FORWARD",c:"Straightforward"},
  {w:"LINE",c:"Straight line"},
]},
// 186 ROUND
{answer:"ROUND",v:["ROUNDS","ROUNDED","ROUNDING"],clues:[
  {w:"MERRY",c:"Merry-go-round"},
  {w:"ABOUT",c:"Roundabout"},
  {w:"TABLE",c:"Round table"},
  {w:"TRIP",c:"Round trip"},
  {w:"BOXING",c:"Boxing round"},
]},
// 187 SQUARE
{answer:"SQUARE",v:["SQUARES","SQUARED"],clues:[
  {w:"BACK",c:"Back to square one"},
  {w:"ROOT",c:"Square root"},
  {w:"MEAL",c:"Square meal"},
  {w:"TIME",c:"Times Square"},
  {w:"PEG",c:"Square peg in a round hole"},
]},
// 188 NARROW — was FLAT (duplicate), replaced entirely
{answer:"NARROW",v:["NARROWS","NARROWED","NARROWING"],clues:[
  {w:"ESCAPE",c:"Narrow escape"},
  {w:"STRAIGHT",c:"Straight and narrow"},
  {w:"DOWN",c:"Narrow down"},
  {w:"BOAT",c:"Narrowboat"},
  {w:"MINDED",c:"Narrow-minded"},
]},
// 189 LEVEL
{answer:"LEVEL",v:["LEVELS","LEVELLED","LEVELLING"],clues:[
  {w:"SPIRIT",c:"Spirit level"},
  {w:"HEADED",c:"Level-headed"},
  {w:"ENTRY",c:"Entry level"},
  {w:"PLAYING",c:"Level playing field"},
  {w:"SEA",c:"Sea level"},
]},

// ─── BATCH 6: ANIMALS (#190–#209) ────────────────────

// 190 HORSE
{answer:"HORSE",v:["HORSES"],clues:[
  {w:"SEA",c:"Seahorse"},
  {w:"DARK",c:"Dark horse"},
  {w:"POWER",c:"Horsepower"},
  {w:"TROJAN",c:"Trojan horse"},
  {w:"SHOE",c:"Horseshoe"},
]},
// 191 DOG
{answer:"DOG",v:["DOGS","DOGGED"],clues:[
  {w:"UNDER",c:"Underdog"},
  {w:"TOP",c:"Top dog"},
  {w:"BULL",c:"Bulldog"},
  {w:"HOT",c:"Hot dog"},
  {w:"WATCH",c:"Watchdog"},
]},
// 192 CAT
{answer:"CAT",v:["CATS"],clues:[
  {w:"COPY",c:"Copycat"},
  {w:"TOM",c:"Tomcat"},
  {w:"WILD",c:"Wildcat"},
  {w:"NAP",c:"Catnap"},
  {w:"FISH",c:"Catfish"},
]},
// 193 FISH — fixed: SELFISH removed (contained FISH)
{answer:"FISH",v:["FISHES","FISHED","FISHING"],clues:[
  {w:"SWORD",c:"Swordfish"},
  {w:"BLOW",c:"Blowfish"},
  {w:"GOLD",c:"Goldfish"},
  {w:"STAR",c:"Starfish"},
  {w:"JELLY",c:"Jellyfish"},
]},
// 194 BIRD
{answer:"BIRD",v:["BIRDS"],clues:[
  {w:"EARLY",c:"Early bird"},
  {w:"LADY",c:"Ladybird"},
  {w:"THUNDER",c:"Thunderbird"},
  {w:"BLACK",c:"Blackbird"},
  {w:"SONG",c:"Birdsong"},
]},
// 195 BEAR
{answer:"BEAR",v:["BEARS","BORE","BORNE","BEARING"],clues:[
  {w:"FRUIT",c:"Bear fruit"},
  {w:"GRUDGE",c:"Bear a grudge"},
  {w:"POLAR",c:"Polar bear"},
  {w:"TEDDY",c:"Teddy bear"},
  {w:"HUG",c:"Bear hug"},
]},
// 196 BULL — fixed: ETIN removed (fragment pattern)
{answer:"BULL",v:["BULLS"],clues:[
  {w:"PIT",c:"Pit bull"},
  {w:"HORN",c:"Bullhorn"},
  {w:"EYE",c:"Bull's-eye"},
  {w:"RED",c:"Red rag to a bull"},
  {w:"MARKET",c:"Bull market"},
]},
// 197 FLY
{answer:"FLY",v:["FLIES","FLEW","FLOWN","FLYING"],clues:[
  {w:"BUTTER",c:"Butterfly"},
  {w:"BAR",c:"Barfly"},
  {w:"DRAGON",c:"Dragonfly"},
  {w:"WHEEL",c:"Flywheel"},
  {w:"FISHING",c:"Fly-fishing"},
]},
// 198 FOX
{answer:"FOX",v:["FOXES","FOXED"],clues:[
  {w:"OUT",c:"Outfox"},
  {w:"TROT",c:"Foxtrot"},
  {w:"SILVER",c:"Silver fox"},
  {w:"HOLE",c:"Foxhole"},
  {w:"CUB",c:"Fox cub"},
]},
// 199 BUG — fixed: HUM removed (BUG contained in HUMBUG), DE removed (fragment)
{answer:"BUG",v:["BUGS","BUGGED","BUGGING"],clues:[
  {w:"LIGHTNING",c:"Lightning bug"},
  {w:"LADY",c:"Ladybug"},
  {w:"PHONE",c:"Phone bug (listening device)"},
  {w:"BED",c:"Bed bug"},
  {w:"SPRAY",c:"Bug spray"},
]},
// 200 DUCK
{answer:"DUCK",v:["DUCKS","DUCKED","DUCKING"],clues:[
  {w:"LAME",c:"Lame duck"},
  {w:"SITTING",c:"Sitting duck"},
  {w:"UGLY",c:"Ugly duckling"},
  {w:"DONALD",c:"Donald Duck"},
  {w:"RUBBER",c:"Rubber duck"},
]},
// 201 WOLF
{answer:"WOLF",v:["WOLVES"],clues:[
  {w:"LONE",c:"Lone wolf"},
  {w:"SHEEP",c:"Wolf in sheep's clothing"},
  {w:"CRY",c:"Cry wolf"},
  {w:"WERE",c:"Werewolf"},
  {w:"PACK",c:"Wolf pack"},
]},
// 202 MOUSE
{answer:"MOUSE",v:["MICE"],clues:[
  {w:"QUIET",c:"Quiet as a mouse"},
  {w:"TRAP",c:"Mousetrap"},
  {w:"PAD",c:"Mouse pad"},
  {w:"MICKEY",c:"Mickey Mouse"},
  {w:"COMPUTER",c:"Computer mouse"},
]},
// 203 CROW
{answer:"CROW",v:["CROWS","CROWED"],clues:[
  {w:"SCARE",c:"Scarecrow"},
  {w:"BAR",c:"Crowbar"},
  {w:"FEET",c:"Crow's feet (wrinkles)"},
  {w:"FLIES",c:"As the crow flies"},
  {w:"ROOSTER",c:"Rooster crows"},
]},
// 204 SNAKE
{answer:"SNAKE",v:["SNAKES","SNAKED","SNAKING"],clues:[
  {w:"RATTLE",c:"Rattlesnake"},
  {w:"GRASS",c:"Snake in the grass"},
  {w:"CHARMER",c:"Snake charmer"},
  {w:"LADDER",c:"Snakes and ladders"},
  {w:"BITE",c:"Snake bite"},
]},
// 205 HAWK
{answer:"HAWK",v:["HAWKS","HAWKED","HAWKING"],clues:[
  {w:"WAR",c:"War hawk"},
  {w:"NIGHT",c:"Nighthawk"},
  {w:"MO",c:"Mohawk"},
  {w:"TONY",c:"Tony Hawk"},
  {w:"EYE",c:"Hawk-eye"},
]},
// 206 MONKEY
{answer:"MONKEY",v:["MONKEYS"],clues:[
  {w:"WRENCH",c:"Monkey wrench"},
  {w:"BUSINESS",c:"Monkey business"},
  {w:"BARS",c:"Monkey bars"},
  {w:"SPIDER",c:"Spider monkey"},
  {w:"BRASS",c:"Brass monkey"},
]},
// 207 WORM
{answer:"WORM",v:["WORMS","WORMED"],clues:[
  {w:"BOOK",c:"Bookworm"},
  {w:"GLOW",c:"Glowworm"},
  {w:"SILK",c:"Silkworm"},
  {w:"EARTH",c:"Earthworm"},
  {w:"CAN",c:"Can of worms"},
]},
// 208 GUARD — was FLY (duplicate), replaced entirely
{answer:"GUARD",v:["GUARDS","GUARDED","GUARDING"],clues:[
  {w:"BODY",c:"Bodyguard"},
  {w:"OFF",c:"Off guard"},
  {w:"LIFE",c:"Lifeguard"},
  {w:"OLD",c:"Old guard"},
  {w:"MOUTH",c:"Mouthguard"},
]},
// 209 LAMB
{answer:"LAMB",v:["LAMBS"],clues:[
  {w:"SILENCE",c:"Silence of the Lambs"},
  {w:"GENTLE",c:"Gentle as a lamb"},
  {w:"CHOP",c:"Lamb chop"},
  {w:"SPRING",c:"Spring lamb"},
  {w:"MARY",c:"Mary had a little lamb"},
]},

// ─── BATCH 7: COLOURS & METALS (#210–#219) ──────────

// 210 BLACK
{answer:"BLACK",v:["BLACKS","BLACKED"],clues:[
  {w:"SMITH",c:"Blacksmith"},
  {w:"MARKET",c:"Black market"},
  {w:"SHEEP",c:"Black sheep"},
  {w:"OUT",c:"Blackout"},
  {w:"BIRD",c:"Blackbird"},
]},
// 211 WHITE
{answer:"WHITE",v:["WHITES"],clues:[
  {w:"WASH",c:"Whitewash"},
  {w:"COLLAR",c:"White collar"},
  {w:"NOISE",c:"White noise"},
  {w:"FLAG",c:"White flag"},
  {w:"EGG",c:"Egg white"},
]},
// 212 RED
{answer:"RED",v:["REDS"],clues:[
  {w:"HERRING",c:"Red herring"},
  {w:"TAPE",c:"Red tape"},
  {w:"CARPET",c:"Red carpet"},
  {w:"CROSS",c:"Red Cross"},
  {w:"CARD",c:"Red card"},
]},
// 213 BLUE
{answer:"BLUE",v:["BLUES"],clues:[
  {w:"PRINT",c:"Blueprint"},
  {w:"COLLAR",c:"Blue collar"},
  {w:"CHIP",c:"Blue chip"},
  {w:"TOOTH",c:"Bluetooth"},
  {w:"SKY",c:"Blue sky"},
]},
// 214 GREEN
{answer:"GREEN",v:["GREENS","GREENER"],clues:[
  {w:"EVER",c:"Evergreen"},
  {w:"HOUSE",c:"Greenhouse"},
  {w:"THUMB",c:"Green thumb"},
  {w:"CARD",c:"Green card"},
  {w:"GRASS",c:"Green grass"},
]},
// 215 SILVER
{answer:"SILVER",v:["SILVERS"],clues:[
  {w:"QUICK",c:"Quicksilver"},
  {w:"LINING",c:"Silver lining"},
  {w:"BULLET",c:"Silver bullet"},
  {w:"SCREEN",c:"Silver screen"},
  {w:"TONGUE",c:"Silver tongue"},
]},
// 216 GOLD
{answer:"GOLD",v:["GOLDS","GOLDEN"],clues:[
  {w:"MARI",c:"Marigold"},
  {w:"MINE",c:"Gold mine"},
  {w:"RUSH",c:"Gold rush"},
  {w:"STANDARD",c:"Gold standard"},
  {w:"FISH",c:"Goldfish"},
]},
// 217 COPPER
{answer:"COPPER",v:["COPPERS"],clues:[
  {w:"SLANG",c:"Copper (slang for police)"},
  {w:"HEAD",c:"Copperhead (snake)"},
  {w:"FIELD",c:"Copperfield (David)"},
  {w:"WIRE",c:"Copper wire"},
  {w:"PENNY",c:"Copper penny"},
]},
// 218 STEEL
{answer:"STEEL",v:["STEELS","STEELED"],clues:[
  {w:"NERVES",c:"Nerves of steel"},
  {w:"STAINLESS",c:"Stainless steel"},
  {w:"DRUM",c:"Steel drum"},
  {w:"WOOL",c:"Steel wool"},
  {w:"BEAM",c:"Steel beam"},
]},
// 219 LEAD — fixed: MIS removed (fragment LEAD in MISLEAD)
{answer:"LEAD",v:["LEADS","LED","LEADING"],clues:[
  {w:"PENCIL",c:"Lead pencil"},
  {w:"BALLOON",c:"Lead balloon"},
  {w:"ROLE",c:"Lead role"},
  {w:"PIPE",c:"Lead pipe"},
  {w:"SINGER",c:"Lead singer"},
]},

// ─── BATCH 8: FOOD & DRINK (#220–#233) ──────────────

// 220 TOAST
{answer:"TOAST",v:["TOASTS","TOASTED","TOASTING"],clues:[
  {w:"FRENCH",c:"French toast"},
  {w:"TOWN",c:"Toast of the town"},
  {w:"CHAMPAGNE",c:"Raise a toast"},
  {w:"BUTTER",c:"Buttered toast"},
  {w:"BURNT",c:"Burnt toast"},
]},
// 221 CAKE
{answer:"CAKE",v:["CAKES","CAKED"],clues:[
  {w:"CUP",c:"Cupcake"},
  {w:"PIECE",c:"Piece of cake"},
  {w:"PAN",c:"Pancake"},
  {w:"CHEESE",c:"Cheesecake"},
  {w:"BIRTHDAY",c:"Birthday cake"},
]},
// 222 CREAM
{answer:"CREAM",v:["CREAMS","CREAMED","CREAMY"],clues:[
  {w:"SUN",c:"Suncream"},
  {w:"CROP",c:"Cream of the crop"},
  {w:"SOUR",c:"Sour cream"},
  {w:"ICE",c:"Ice cream"},
  {w:"WHIPPED",c:"Whipped cream"},
]},
// 223 SUGAR
{answer:"SUGAR",v:["SUGARS","SUGARED","SUGARY"],clues:[
  {w:"COAT",c:"Sugarcoat"},
  {w:"CANE",c:"Sugar cane"},
  {w:"DADDY",c:"Sugar daddy"},
  {w:"CUBE",c:"Sugar cube"},
  {w:"BROWN",c:"Brown sugar"},
]},
// 224 SALT
{answer:"SALT",v:["SALTS","SALTED","SALTY"],clues:[
  {w:"WOUND",c:"Rub salt in the wound"},
  {w:"GRAIN",c:"Take with a grain of salt"},
  {w:"EARTH",c:"Salt of the earth"},
  {w:"LAKE",c:"Salt lake"},
  {w:"PEPPER",c:"Salt and pepper"},
]},
// 225 PEPPER
{answer:"PEPPER",v:["PEPPERS","PEPPERED"],clues:[
  {w:"SERGEANT",c:"Sgt. Pepper's"},
  {w:"CORN",c:"Peppercorn"},
  {w:"MINT",c:"Peppermint"},
  {w:"SPRAY",c:"Pepper spray"},
  {w:"SALT",c:"Salt and pepper"},
]},
// 226 NUT
{answer:"NUT",v:["NUTS","NUTTY"],clues:[
  {w:"TOUGH",c:"Tough nut to crack"},
  {w:"SHELL",c:"Nutshell"},
  {w:"DOUGH",c:"Doughnut"},
  {w:"COCO",c:"Coconut"},
  {w:"BOLT",c:"Nut and bolt"},
]},
// 227 BEAN
{answer:"BEAN",v:["BEANS"],clues:[
  {w:"SPILL",c:"Spill the beans"},
  {w:"JELLY",c:"Jelly bean"},
  {w:"COFFEE",c:"Coffee bean"},
  {w:"RUNNER",c:"Runner bean"},
  {w:"MR",c:"Mr. Bean"},
]},
// 228 FRUIT
{answer:"FRUIT",v:["FRUITS","FRUITED","FRUITY"],clues:[
  {w:"FORBIDDEN",c:"Forbidden fruit"},
  {w:"GRAPE",c:"Grapefruit"},
  {w:"PASSION",c:"Passion fruit"},
  {w:"BASKET",c:"Fruit basket"},
  {w:"SALAD",c:"Fruit salad"},
]},
// 229 JUICE
{answer:"JUICE",v:["JUICES","JUICED","JUICY"],clues:[
  {w:"CREATIVE",c:"Creative juices"},
  {w:"STEW",c:"Stew in your own juices"},
  {w:"LEMON",c:"Lemon juice"},
  {w:"ORANGE",c:"Orange juice"},
  {w:"APPLE",c:"Apple juice"},
]},
// 230 HONEY
{answer:"HONEY",v:["HONEYS"],clues:[
  {w:"MOON",c:"Honeymoon"},
  {w:"TRAP",c:"Honeytrap"},
  {w:"COMB",c:"Honeycomb"},
  {w:"BEE",c:"Honeybee"},
  {w:"POT",c:"Honey pot"},
]},
// 231 CHERRY
{answer:"CHERRY",v:["CHERRIES"],clues:[
  {w:"PICK",c:"Cherry-pick"},
  {w:"TOP",c:"Cherry on top"},
  {w:"BLOSSOM",c:"Cherry blossom"},
  {w:"BOMB",c:"Cherry bomb"},
  {w:"PIE",c:"Cherry pie"},
]},
// 232 APPLE
{answer:"APPLE",v:["APPLES"],clues:[
  {w:"ADAM",c:"Adam's apple"},
  {w:"BIG",c:"Big Apple (New York)"},
  {w:"PINE",c:"Pineapple"},
  {w:"EYE",c:"Apple of my eye"},
  {w:"PIE",c:"Apple pie"},
]},
// 233 LEMON
{answer:"LEMON",v:["LEMONS"],clues:[
  {w:"LIFE",c:"When life gives you lemons"},
  {w:"ADE",c:"Lemonade"},
  {w:"DROP",c:"Lemon drop"},
  {w:"SQUEEZE",c:"Squeeze a lemon"},
  {w:"ZEST",c:"Lemon zest"},
]},

// ─── BATCH 9: MISC (#234–#284) ──────────────────────

// 234 TIME
{answer:"TIME",v:["TIMES","TIMED","TIMING"],clues:[
  {w:"OVER",c:"Overtime"},
  {w:"BED",c:"Bedtime"},
  {w:"HALF",c:"Halftime"},
  {w:"BOMB",c:"Time bomb"},
  {w:"OUT",c:"Timeout"},
]},
// 235 NIGHT
{answer:"NIGHT",v:["NIGHTS","NIGHTLY"],clues:[
  {w:"FORT",c:"Fortnight"},
  {w:"MID",c:"Midnight"},
  {w:"MARE",c:"Nightmare"},
  {w:"CAP",c:"Nightcap"},
  {w:"OWL",c:"Night owl"},
]},
// 236 DAY
{answer:"DAY",v:["DAYS"],clues:[
  {w:"BIRTH",c:"Birthday"},
  {w:"EVERY",c:"Everyday"},
  {w:"HOL",c:"Holiday"},
  {w:"RAINY",c:"Rainy day"},
  {w:"BREAK",c:"Daybreak"},
]},
// 237 POWER
{answer:"POWER",v:["POWERS","POWERED","POWERFUL"],clues:[
  {w:"HORSE",c:"Horsepower"},
  {w:"MAN",c:"Manpower"},
  {w:"WILL",c:"Willpower"},
  {w:"FLOWER",c:"Flower power"},
  {w:"STATION",c:"Power station"},
]},
// 238 WORK
{answer:"WORK",v:["WORKS","WORKED","WORKING"],clues:[
  {w:"CLOCK",c:"Clockwork"},
  {w:"FIRE",c:"Fireworks"},
  {w:"TEAM",c:"Teamwork"},
  {w:"NET",c:"Network"},
  {w:"HOME",c:"Homework"},
]},
// 239 SHOW
{answer:"SHOW",v:["SHOWS","SHOWED","SHOWING"],clues:[
  {w:"SIDE",c:"Sideshow"},
  {w:"ROAD",c:"Roadshow"},
  {w:"SLIDE",c:"Slideshow"},
  {w:"TALK",c:"Talk show"},
  {w:"GAME",c:"Game show"},
]},
// 240 STOP
{answer:"STOP",v:["STOPS","STOPPED","STOPPING"],clues:[
  {w:"NON",c:"Non-stop"},
  {w:"BACK",c:"Backstop"},
  {w:"PIT",c:"Pit stop"},
  {w:"DOOR",c:"Doorstop"},
  {w:"BUS",c:"Bus stop"},
]},
// 241 SIGN — fixed: DE removed (fragment SIGN in DESIGN)
{answer:"SIGN",v:["SIGNS","SIGNED","SIGNING"],clues:[
  {w:"VITAL",c:"Vital signs"},
  {w:"CALL",c:"Call sign"},
  {w:"ROAD",c:"Road sign"},
  {w:"STAR",c:"Star sign"},
  {w:"STOP",c:"Stop sign"},
]},
// 242 NOTE
{answer:"NOTE",v:["NOTES","NOTED"],clues:[
  {w:"FOOT",c:"Footnote"},
  {w:"KEY",c:"Keynote"},
  {w:"WORTHY",c:"Noteworthy"},
  {w:"STICKY",c:"Sticky note"},
  {w:"MUSIC",c:"Musical note"},
]},
// 243 GAME
{answer:"GAME",v:["GAMES","GAMED","GAMING"],clues:[
  {w:"END",c:"Endgame"},
  {w:"NAME",c:"The name of the game"},
  {w:"BLAME",c:"Blame game"},
  {w:"BOARD",c:"Board game"},
  {w:"FAIR",c:"Fair game"},
]},
// 244 LOVE — fixed: GLOVE removed (contained LOVE)
{answer:"LOVE",v:["LOVES","LOVED","LOVING"],clues:[
  {w:"PUPPY",c:"Puppy love"},
  {w:"TOUGH",c:"Tough love"},
  {w:"SEAT",c:"Loveseat"},
  {w:"LETTER",c:"Love letter"},
  {w:"TENNIS",c:"Love (tennis zero)"},
]},
// 245 ROAD — was BRIDGE (duplicate), replaced entirely
{answer:"ROAD",v:["ROADS"],clues:[
  {w:"CROSS",c:"Crossroads"},
  {w:"RAIL",c:"Railroad"},
  {w:"BLOCK",c:"Roadblock"},
  {w:"SILK",c:"Silk Road"},
  {w:"TRIP",c:"Road trip"},
]},
// 246 BOAT
{answer:"BOAT",v:["BOATS","BOATED","BOATING"],clues:[
  {w:"SAME",c:"In the same boat"},
  {w:"DREAM",c:"Dreamboat"},
  {w:"LIFE",c:"Lifeboat"},
  {w:"GRAVY",c:"Gravy boat"},
  {w:"SAIL",c:"Sailboat"},
]},
// 247 SHIP
{answer:"SHIP",v:["SHIPS","SHIPPED","SHIPPING"],clues:[
  {w:"WORK",c:"Workmanship"},
  {w:"OWNER",c:"Ownership"},
  {w:"FLAG",c:"Flagship"},
  {w:"BATTLE",c:"Battleship"},
  {w:"ROCKET",c:"Rocket ship"},
]},
// 248 PORT
{answer:"PORT",v:["PORTS"],clues:[
  {w:"PASS",c:"Passport"},
  {w:"AIR",c:"Airport"},
  {w:"STORM",c:"Any port in a storm"},
  {w:"WINE",c:"Port wine"},
  {w:"DOCK",c:"Port dock"},
]},
// 249 TRAIN
{answer:"TRAIN",v:["TRAINS","TRAINED","TRAINING"],clues:[
  {w:"THOUGHT",c:"Train of thought"},
  {w:"GRAVY",c:"Gravy train"},
  {w:"BRAIN",c:"Brain training"},
  {w:"WRECK",c:"Train wreck"},
  {w:"STATION",c:"Train station"},
]},
// 250 RACE
{answer:"RACE",v:["RACES","RACED","RACING"],clues:[
  {w:"RAT",c:"Rat race"},
  {w:"ARMS",c:"Arms race"},
  {w:"DRAG",c:"Drag race"},
  {w:"HORSE",c:"Horse race"},
  {w:"HUMAN",c:"Human race"},
]},
// 251 WAR
{answer:"WAR",v:["WARS"],clues:[
  {w:"TUG",c:"Tug of war"},
  {w:"COLD",c:"Cold war"},
  {w:"STAR",c:"Star Wars"},
  {w:"ZONE",c:"War zone"},
  {w:"WORLD",c:"World war"},
]},
// 252 FIRE
{answer:"FIRE",v:["FIRES","FIRED","FIRING"],clues:[
  {w:"HELL",c:"Hellfire"},
  {w:"CROSS",c:"Crossfire"},
  {w:"SURE",c:"Surefire"},
  {w:"RAPID",c:"Rapid fire"},
  {w:"CEASE",c:"Ceasefire"},
]},
// 253 WATER
{answer:"WATER",v:["WATERS","WATERED","WATERING"],clues:[
  {w:"BREAK",c:"Breakwater"},
  {w:"MARK",c:"Watermark"},
  {w:"MUDDY",c:"Muddy the waters"},
  {w:"FALL",c:"Waterfall"},
  {w:"DEEP",c:"Deep water"},
]},
// 254 EDGE — fixed: HEDGE and LEDGE removed (contained EDGE)
{answer:"EDGE",v:["EDGES","EDGED","EDGING"],clues:[
  {w:"CUTTING",c:"Cutting edge"},
  {w:"RAZOR",c:"Razor's edge"},
  {w:"WATER",c:"Water's edge"},
  {w:"KNIFE",c:"Knife edge"},
  {w:"CLIFF",c:"Cliff edge"},
]},
// 255 CORE — fixed: SCORE removed (contained CORE)
{answer:"CORE",v:["CORES","CORED"],clues:[
  {w:"HARD",c:"Hardcore"},
  {w:"VALUES",c:"Core values"},
  {w:"APPLE",c:"Apple core"},
  {w:"ROTTEN",c:"Rotten to the core"},
  {w:"EARTH",c:"Earth's core"},
]},
// 256 TOWER
{answer:"TOWER",v:["TOWERS","TOWERED","TOWERING"],clues:[
  {w:"IVORY",c:"Ivory tower"},
  {w:"EIFFEL",c:"Eiffel Tower"},
  {w:"CONTROL",c:"Control tower"},
  {w:"CLOCK",c:"Clock tower"},
  {w:"WATER",c:"Water tower"},
]},
// 257 SHADOW — was CROWN (duplicate), replaced entirely
{answer:"SHADOW",v:["SHADOWS","SHADOWED","SHADOWING"],clues:[
  {w:"FIVE",c:"Five o'clock shadow"},
  {w:"EYE",c:"Eye shadow"},
  {w:"CABINET",c:"Shadow cabinet"},
  {w:"PUPPET",c:"Shadow puppet"},
  {w:"CAST",c:"Cast a shadow"},
]},
// 258 POCKET
{answer:"POCKET",v:["POCKETS","POCKETED"],clues:[
  {w:"PICK",c:"Pickpocket"},
  {w:"AIR",c:"Air pocket"},
  {w:"DEEP",c:"Deep pockets"},
  {w:"POOL",c:"Pool pocket"},
  {w:"WATCH",c:"Pocket watch"},
]},
// 259 PATCH
{answer:"PATCH",v:["PATCHES","PATCHED","PATCHING"],clues:[
  {w:"ROUGH",c:"Rough patch"},
  {w:"EYE",c:"Eye patch"},
  {w:"NICOTINE",c:"Nicotine patch"},
  {w:"CABBAGE",c:"Cabbage patch"},
  {w:"PUMPKIN",c:"Pumpkin patch"},
]},
// 260 WATCH
{answer:"WATCH",v:["WATCHES","WATCHED","WATCHING"],clues:[
  {w:"BIRD",c:"Birdwatching"},
  {w:"DOG",c:"Watchdog"},
  {w:"NIGHT",c:"Night watch"},
  {w:"TOWER",c:"Watchtower"},
  {w:"WRIST",c:"Wristwatch"},
]},
// 261 GATE — was RING (duplicate), replaced entirely
{answer:"GATE",v:["GATES","GATED"],clues:[
  {w:"FLOOD",c:"Floodgate"},
  {w:"TAIL",c:"Tailgate"},
  {w:"WATER",c:"Watergate"},
  {w:"GOLDEN",c:"Golden Gate"},
  {w:"GARDEN",c:"Garden gate"},
]},
// 262 COAT
{answer:"COAT",v:["COATS","COATED","COATING"],clues:[
  {w:"TURN",c:"Turncoat"},
  {w:"SUGAR",c:"Sugarcoat"},
  {w:"UNDER",c:"Undercoat"},
  {w:"TOP",c:"Topcoat"},
  {w:"RAIN",c:"Raincoat"},
]},
// 263 POST
{answer:"POST",v:["POSTS","POSTED","POSTING"],clues:[
  {w:"OUT",c:"Outpost"},
  {w:"LAMP",c:"Lamppost"},
  {w:"SIGN",c:"Signpost"},
  {w:"CARD",c:"Postcard"},
  {w:"BOX",c:"Post box"},
]},
// 264 STEP
{answer:"STEP",v:["STEPS","STEPPED","STEPPING"],clues:[
  {w:"DOOR",c:"Doorstep"},
  {w:"FOOT",c:"Footstep"},
  {w:"TWO",c:"Two-step"},
  {w:"QUICK",c:"Quickstep"},
  {w:"FIRST",c:"First step"},
]},
// 265 SCORE
{answer:"SCORE",v:["SCORES","SCORED","SCORING"],clues:[
  {w:"FOUR",c:"Four score (and seven years)"},
  {w:"UNDER",c:"Underscore"},
  {w:"SETTLE",c:"Settle a score"},
  {w:"CARD",c:"Scorecard"},
  {w:"HIGH",c:"High score"},
]},
// 266 STAMP — was MARK (duplicate of #125), replaced entirely
{answer:"STAMP",v:["STAMPS","STAMPED","STAMPING"],clues:[
  {w:"RUBBER",c:"Rubber stamp"},
  {w:"COLLECT",c:"Stamp collecting"},
  {w:"POST",c:"Postage stamp"},
  {w:"GROUND",c:"Stamping ground"},
  {w:"PASSPORT",c:"Passport stamp"},
]},
// 267 BUTTON — was BRIDGE (duplicate), replaced entirely
{answer:"BUTTON",v:["BUTTONS","BUTTONED"],clues:[
  {w:"BELLY",c:"Belly button"},
  {w:"CUTE",c:"Cute as a button"},
  {w:"PUSH",c:"Push-button"},
  {w:"PANIC",c:"Panic button"},
  {w:"MASH",c:"Button mashing"},
]},
// 268 MARKET
{answer:"MARKET",v:["MARKETS","MARKETED","MARKETING"],clues:[
  {w:"FLEA",c:"Flea market"},
  {w:"SUPER",c:"Supermarket"},
  {w:"STOCK",c:"Stock market"},
  {w:"BLACK",c:"Black market"},
  {w:"BULL",c:"Bull market"},
]},
// 269 GARDEN
{answer:"GARDEN",v:["GARDENS","GARDENED","GARDENING"],clues:[
  {w:"BEER",c:"Beer garden"},
  {w:"MADISON",c:"Madison Square Garden"},
  {w:"ROOF",c:"Roof garden"},
  {w:"SECRET",c:"Secret garden"},
  {w:"FLOWER",c:"Flower garden"},
]},
// 270 MASTER
{answer:"MASTER",v:["MASTERS","MASTERED","MASTERING"],clues:[
  {w:"GRAND",c:"Grandmaster"},
  {w:"HEAD",c:"Headmaster"},
  {w:"WEB",c:"Webmaster"},
  {w:"CLASS",c:"Masterclass"},
  {w:"PIECE",c:"Masterpiece"},
]},
// 271 WHEEL
{answer:"WHEEL",v:["WHEELS","WHEELED"],clues:[
  {w:"CART",c:"Cartwheel"},
  {w:"FLY",c:"Flywheel"},
  {w:"HAMSTER",c:"Hamster wheel"},
  {w:"STEERING",c:"Steering wheel"},
  {w:"SPARE",c:"Spare wheel"},
]},
// 272 BOOT
{answer:"BOOT",v:["BOOTS","BOOTED","BOOTING"],clues:[
  {w:"CAMP",c:"Boot camp"},
  {w:"LEG",c:"Bootleg"},
  {w:"CAR",c:"Car boot"},
  {w:"COWBOY",c:"Cowboy boots"},
  {w:"MUDDY",c:"Muddy boots"},
]},
// 273 TAIL
{answer:"TAIL",v:["TAILS","TAILED","TAILING"],clues:[
  {w:"COCK",c:"Cocktail"},
  {w:"PONY",c:"Ponytail"},
  {w:"DOVE",c:"Dovetail"},
  {w:"FAIRY",c:"Fairy tale (tail/tale)"},
  {w:"SPIN",c:"Tailspin"},
]},
// 274 CAMP
{answer:"CAMP",v:["CAMPS","CAMPED","CAMPING"],clues:[
  {w:"BOOT",c:"Boot camp"},
  {w:"FIRE",c:"Campfire"},
  {w:"BASE",c:"Base camp"},
  {w:"SUMMER",c:"Summer camp"},
  {w:"TENT",c:"Camp tent"},
]},
// 275 MASK
{answer:"MASK",v:["MASKS","MASKED","MASKING"],clues:[
  {w:"OXYGEN",c:"Oxygen mask"},
  {w:"GAS",c:"Gas mask"},
  {w:"FACE",c:"Face mask"},
  {w:"SKI",c:"Ski mask"},
  {w:"HALLOWEEN",c:"Halloween mask"},
]},
// 276 GIFT
{answer:"GIFT",v:["GIFTS","GIFTED"],clues:[
  {w:"HORSE",c:"Don't look a gift horse in the mouth"},
  {w:"WRAP",c:"Gift wrap"},
  {w:"GAB",c:"Gift of the gab"},
  {w:"CARD",c:"Gift card"},
  {w:"BIRTHDAY",c:"Birthday gift"},
]},
// 277 NERVE — was CATCH (duplicate), replaced entirely
{answer:"NERVE",v:["NERVES"],clues:[
  {w:"STEEL",c:"Nerves of steel"},
  {w:"RAW",c:"Raw nerve"},
  {w:"WRACKING",c:"Nerve-wracking"},
  {w:"LAST",c:"Last nerve"},
  {w:"DAMAGE",c:"Nerve damage"},
]},
// 278 HEAT — was WAVE (duplicate), replaced entirely
{answer:"HEAT",v:["HEATS","HEATED","HEATING"],clues:[
  {w:"DEAD",c:"Dead heat"},
  {w:"WAVE",c:"Heatwave"},
  {w:"STROKE",c:"Heatstroke"},
  {w:"KITCHEN",c:"Can't stand the heat"},
  {w:"MOMENT",c:"Heat of the moment"},
]},
// 279 SPACE
{answer:"SPACE",v:["SPACES","SPACED"],clues:[
  {w:"CYBER",c:"Cyberspace"},
  {w:"BLANK",c:"Blank space"},
  {w:"AIR",c:"Airspace"},
  {w:"OUTER",c:"Outer space"},
  {w:"PARKING",c:"Parking space"},
]},
// 280 CORNER
{answer:"CORNER",v:["CORNERS","CORNERED","CORNERING"],clues:[
  {w:"CUT",c:"Cut corners"},
  {w:"STONE",c:"Cornerstone"},
  {w:"TIGHT",c:"In a tight corner"},
  {w:"SHOP",c:"Corner shop"},
  {w:"ROUND",c:"Round the corner"},
]},
// 281 CHARM — was POCKET (duplicate), replaced entirely
{answer:"CHARM",v:["CHARMS","CHARMED","CHARMING"],clues:[
  {w:"LUCKY",c:"Lucky charm"},
  {w:"PRINCE",c:"Prince Charming"},
  {w:"BRACELET",c:"Charm bracelet"},
  {w:"THIRD",c:"Third time's a charm"},
  {w:"OFFENSIVE",c:"Charm offensive"},
]},
// 282 SHADE — was CLOUD (duplicate), replaced entirely
{answer:"SHADE",v:["SHADES","SHADED","SHADING","SHADY"],clues:[
  {w:"LAMP",c:"Lampshade"},
  {w:"THROW",c:"Throw shade"},
  {w:"TREE",c:"Tree shade"},
  {w:"SUN",c:"Sunshade"},
  {w:"COOL",c:"Cool shade"},
]},
// 283 WISH — was STRIKE (duplicate), replaced entirely
{answer:"WISH",v:["WISHES","WISHED","WISHING"],clues:[
  {w:"BONE",c:"Wishbone"},
  {w:"DEATH",c:"Death wish"},
  {w:"WELL",c:"Wishing well"},
  {w:"THINKING",c:"Wishful thinking"},
  {w:"STAR",c:"Wish upon a star"},
]},
// 284 MAP
{answer:"MAP",v:["MAPS","MAPPED","MAPPING"],clues:[
  {w:"ROAD",c:"Roadmap"},
  {w:"OFF",c:"Off the map"},
  {w:"TREASURE",c:"Treasure map"},
  {w:"MIND",c:"Mind map"},
  {w:"WORLD",c:"World map"},
]},

];

export { NEW_ROUNDS };
