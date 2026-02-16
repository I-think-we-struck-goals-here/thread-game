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
// DAILY ROUND POOL (33 rounds)
// ─────────────────────────────────────────────
const ALL_ROUNDS = [
  { answer: "BRIDGE", clues: [
    { word: "LONDON", connection: "London Bridge" }, { word: "CARDS", connection: "Bridge (card game)" },
    { word: "BURN", connection: "Burn your bridges" }, { word: "NOSE", connection: "Bridge of your nose" },
    { word: "SUSPEND", connection: "Suspension bridge" },
  ]},
  { answer: "CROWN", clues: [
    { word: "JEWEL", connection: "Crown Jewels" }, { word: "TOOTH", connection: "Dental crown" },
    { word: "NETFLIX", connection: "The Crown (TV series)" }, { word: "THORNS", connection: "Crown of thorns" },
    { word: "VICTORIA", connection: "Crown of Queen Victoria" },
  ]},
  { answer: "LIGHT", clues: [
    { word: "SPEED", connection: "Speed of light" }, { word: "HOUSE", connection: "Lighthouse" },
    { word: "FEATHER", connection: "Light as a feather" }, { word: "NORTHERN", connection: "Northern Lights" },
    { word: "GREEN", connection: "Green light" },
  ]},
  { answer: "RING", clues: [
    { word: "SATURN", connection: "Rings of Saturn" }, { word: "BOXING", connection: "Boxing ring" },
    { word: "PHONE", connection: "Give someone a ring" }, { word: "TOLKIEN", connection: "Lord of the Rings" },
    { word: "WEDDING", connection: "Wedding ring" },
  ]},
  { answer: "PITCH", clues: [
    { word: "TENT", connection: "Pitch a tent" }, { word: "PERFECT", connection: "Perfect pitch" },
    { word: "ELEVATOR", connection: "Elevator pitch" }, { word: "BLACK", connection: "Pitch black" },
    { word: "BASEBALL", connection: "Baseball pitch" },
  ]},
  { answer: "WAVE", clues: [
    { word: "HAIR", connection: "Wave in your hair" }, { word: "STADIUM", connection: "Mexican wave" },
    { word: "MICRO", connection: "Microwave" }, { word: "HEAT", connection: "Heatwave" },
    { word: "OCEAN", connection: "Ocean wave" },
  ]},
  { answer: "SPRING", clues: [
    { word: "MATTRESS", connection: "Mattress spring" }, { word: "CLEAN", connection: "Spring cleaning" },
    { word: "ROLL", connection: "Spring roll" }, { word: "WATER", connection: "Natural spring" },
    { word: "BLOSSOM", connection: "Spring blossoms" },
  ]},
  { answer: "SHELL", clues: [
    { word: "SHOCK", connection: "Shell shock" }, { word: "PETROL", connection: "Shell (oil company)" },
    { word: "TURTLE", connection: "Turtle shell" }, { word: "EGG", connection: "Eggshell" },
    { word: "BEACH", connection: "Seashells on the beach" },
  ]},
  { answer: "KEY", clues: [
    { word: "FLORIDA", connection: "Florida Keys" }, { word: "PIANO", connection: "Piano keys" },
    { word: "SKELETON", connection: "Skeleton key" }, { word: "BOARD", connection: "Keyboard" },
    { word: "LOCK", connection: "Lock and key" },
  ]},
  { answer: "PLANT", clues: [
    { word: "FACTORY", connection: "Manufacturing plant" }, { word: "SPY", connection: "Plant a spy" },
    { word: "RUBBER", connection: "Rubber plant" }, { word: "POWER", connection: "Power plant" },
    { word: "SEED", connection: "Plant a seed" },
  ]},
  { answer: "BANK", clues: [
    { word: "RIVER", connection: "River bank" }, { word: "ROBBER", connection: "Bank robber" },
    { word: "BLOOD", connection: "Blood bank" }, { word: "PIGGY", connection: "Piggy bank" },
    { word: "ENGLAND", connection: "Bank of England" },
  ]},
  { answer: "CAST", clues: [
    { word: "SHADOW", connection: "Cast a shadow" }, { word: "FISHING", connection: "Cast a line" },
    { word: "IRON", connection: "Cast iron" }, { word: "MOVIE", connection: "Movie cast" },
    { word: "BROKEN", connection: "Plaster cast" },
  ]},
  { answer: "MATCH", clues: [
    { word: "FIRE", connection: "Strike a match" }, { word: "TENNIS", connection: "Tennis match" },
    { word: "PERFECT", connection: "Perfect match" }, { word: "MIX", connection: "Mix and match" },
    { word: "BOOK", connection: "Matchbook" },
  ]},
  { answer: "FALL", clues: [
    { word: "NIAGARA", connection: "Niagara Falls" }, { word: "GRACE", connection: "Fall from grace" },
    { word: "LEAF", connection: "Falling leaves" }, { word: "FREE", connection: "Freefall" },
    { word: "WALL", connection: "Berlin Wall fell" },
  ]},
  { answer: "PAPER", clues: [
    { word: "ROCK", connection: "Rock, paper, scissors" }, { word: "TOILET", connection: "Toilet paper" },
    { word: "TRAIL", connection: "Paper trail" }, { word: "NEWS", connection: "Newspaper" },
    { word: "WALL", connection: "Wallpaper" },
  ]},
  { answer: "STOCK", clues: [
    { word: "CHICKEN", connection: "Chicken stock" }, { word: "MARKET", connection: "Stock market" },
    { word: "LAUGHING", connection: "Laughing stock" }, { word: "GUN", connection: "Gunstock" },
    { word: "TAKE", connection: "Take stock" },
  ]},
  { answer: "NAIL", clues: [
    { word: "COFFIN", connection: "Nail in the coffin" }, { word: "HAMMER", connection: "Hammer and nail" },
    { word: "POLISH", connection: "Nail polish" }, { word: "SALON", connection: "Nail salon" },
    { word: "BED", connection: "Bed of nails" },
  ]},
  { answer: "TRACK", clues: [
    { word: "TRAIN", connection: "Train track" }, { word: "RECORD", connection: "Track record" },
    { word: "RACE", connection: "Racetrack" }, { word: "SOUND", connection: "Soundtrack" },
    { word: "LOST", connection: "Lose track" },
  ]},
  { answer: "STAGE", clues: [
    { word: "FRIGHT", connection: "Stage fright" }, { word: "ROCKET", connection: "Rocket stage" },
    { word: "COACH", connection: "Stagecoach" }, { word: "GRIEF", connection: "Stages of grief" },
    { word: "LEFT", connection: "Stage left" },
  ]},
  { answer: "CHECK", clues: [
    { word: "CHESS", connection: "Check in chess" }, { word: "RAIN", connection: "Raincheck" },
    { word: "SPELL", connection: "Spellcheck" }, { word: "REALITY", connection: "Reality check" },
    { word: "BLANK", connection: "Blank check" },
  ]},
  { answer: "HEART", clues: [
    { word: "BRAVE", connection: "Braveheart" }, { word: "ATTACK", connection: "Heart attack" },
    { word: "BREAK", connection: "Heartbreak" }, { word: "SWEET", connection: "Sweetheart" },
    { word: "SLEEVE", connection: "Heart on your sleeve" },
  ]},
  { answer: "POINT", clues: [
    { word: "NEEDLE", connection: "Needle point" }, { word: "BULLET", connection: "Bullet point" },
    { word: "GUN", connection: "Gunpoint" }, { word: "POWER", connection: "PowerPoint" },
    { word: "VIEW", connection: "Point of view" },
  ]},
  { answer: "DRUM", clues: [
    { word: "STICK", connection: "Drumstick" }, { word: "EAR", connection: "Eardrum" },
    { word: "SNARE", connection: "Snare drum" }, { word: "STEEL", connection: "Steel drum" },
    { word: "ROLL", connection: "Drum roll" },
  ]},
  { answer: "PLATE", clues: [
    { word: "TECTONIC", connection: "Tectonic plates" }, { word: "ARMOUR", connection: "Armour plating" },
    { word: "LICENSE", connection: "License plate" }, { word: "HOME", connection: "Home plate" },
    { word: "DINNER", connection: "Dinner plate" },
  ]},
  { answer: "PASS", clues: [
    { word: "MOUNTAIN", connection: "Mountain pass" }, { word: "BOARDING", connection: "Boarding pass" },
    { word: "TIME", connection: "Pass the time" }, { word: "FOOTBALL", connection: "Football pass" },
    { word: "FAIL", connection: "Pass or fail" },
  ]},
  { answer: "CELL", clues: [
    { word: "PRISON", connection: "Prison cell" }, { word: "PHONE", connection: "Cell phone" },
    { word: "SOLAR", connection: "Solar cell" }, { word: "BLOOD", connection: "Blood cell" },
    { word: "DIVIDE", connection: "Cell division" },
  ]},
  { answer: "JAM", clues: [
    { word: "TRAFFIC", connection: "Traffic jam" }, { word: "GUITAR", connection: "Jam session" },
    { word: "TOAST", connection: "Jam on toast" }, { word: "PEARL", connection: "Pearl Jam" },
    { word: "DOOR", connection: "Door jamb" },
  ]},
  { answer: "BARK", clues: [
    { word: "DOG", connection: "Dog bark" }, { word: "TREE", connection: "Tree bark" },
    { word: "MOON", connection: "Barking at the moon" }, { word: "CHOCOLATE", connection: "Chocolate bark" },
    { word: "BITE", connection: "Bark worse than bite" },
  ]},
  { answer: "CURRENT", clues: [
    { word: "ELECTRIC", connection: "Electric current" }, { word: "AFFAIRS", connection: "Current affairs" },
    { word: "RAISIN", connection: "Currant (the fruit)" }, { word: "OCEAN", connection: "Ocean current" },
    { word: "RIVER", connection: "River current" },
  ]},
  { answer: "GLASS", clues: [
    { word: "CEILING", connection: "Glass ceiling" }, { word: "STAIN", connection: "Stained glass" },
    { word: "SPY", connection: "Spyglass" }, { word: "WINE", connection: "Wine glass" },
    { word: "SLIPPER", connection: "Glass slipper" },
  ]},
  { answer: "FRAME", clues: [
    { word: "PICTURE", connection: "Picture frame" }, { word: "BLAME", connection: "Frame someone" },
    { word: "TIME", connection: "Time frame" }, { word: "DOOR", connection: "Door frame" },
    { word: "FREEZE", connection: "Freeze frame" },
  ]},
  { answer: "SEAL", clues: [
    { word: "NAVY", connection: "Navy SEAL" }, { word: "WAX", connection: "Wax seal" },
    { word: "ARCTIC", connection: "Arctic seal" }, { word: "DEAL", connection: "Seal the deal" },
    { word: "APPROVAL", connection: "Seal of approval" },
  ]},
  { answer: "COURT", clues: [
    { word: "BASKETBALL", connection: "Basketball court" }, { word: "JESTER", connection: "Court jester" },
    { word: "SUPREME", connection: "Supreme Court" }, { word: "SHIP", connection: "Courtship" },
    { word: "FOOD", connection: "Food court" },
  ]},
];

// ─────────────────────────────────────────────
// DAILY PUZZLE PICKER
// ─────────────────────────────────────────────
const EPOCH = new Date(2026, 1, 16);

const getDayNumber = () => {
  const now = new Date(); now.setHours(0,0,0,0);
  const ep = new Date(EPOCH); ep.setHours(0,0,0,0);
  return Math.max(1, Math.floor((now - ep) / 86400000) + 1);
};

const getDailyRound = () => {
  const day = getDayNumber();
  const shuffled = [...ALL_ROUNDS];
  let s = day * 2654435761;
  for (let i = shuffled.length - 1; i > 0; i--) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    const j = s % (i + 1);
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled[0];
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
    --tutorial-card-min-height: 430px;
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
  .tutorial-controls { width:100%; max-width:340px; display:flex; flex-direction:column; align-items:center; margin-top:12px; }
  .tutorial-steps { display:flex; flex-direction:column; gap:8px; margin-bottom:20px; }
  .tutorial-step { display:flex; align-items:center; gap:10px; background:${C.card}; border:1px solid ${C.border}; border-radius:12px; padding:10px 12px; text-align:left; }
  .tutorial-step-num { width:22px; height:22px; border-radius:50%; background:${C.accentSoft}; color:${C.accent}; display:flex; align-items:center; justify-content:center; font:700 11px 'DM Sans', sans-serif; flex-shrink:0; }
  .tutorial-step-text { color:${C.dark}; font:500 13px/1.35 'DM Sans', sans-serif; letter-spacing:0.2px; }
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
      --tutorial-card-min-height: 360px;
    }
    .tutorial-card { max-width:100%; }
    .action-row.stack-mobile { flex-direction:column; align-items:stretch; width:100%; }
    .action-row.stack-mobile > button { width:100%; }
    .round-action-row { width:100%; gap:8px; flex-wrap:nowrap; }
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

function ThreadLine() {
  return <div style={{
    position:"fixed", top:0, left:"50%", width:1, height:"100vh",
    background:`linear-gradient(to bottom, transparent, ${C.faint} 18%, ${C.faint} 82%, transparent)`,
    animation:"pulse 4s ease-in-out infinite", pointerEvents:"none", zIndex:0,
  }}/>;
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
    body:"You’re finding one hidden word from clue words. It takes about 20 seconds per round.",
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
            <div style={{ background:C.card, border:`1px solid ${C.border}`, borderRadius:14, padding:"20px 24px", marginBottom:20, textAlign:"left" }}>
              {c.example.words.map((w,j)=><div key={j} style={{ fontFamily:serif, fontSize:24, fontWeight:400, letterSpacing:"3px", color:C.dark, marginBottom:8 }}>{w}</div>)}
              {c.example.faded.map((w,j)=><div key={j} style={{ fontFamily:serif, fontSize:24, fontWeight:300, letterSpacing:"3px", color:C.faint, marginBottom:8 }}>{w}</div>)}
              <div style={{ height:1, background:C.border, margin:"12px 0" }}/>
              <div style={{ fontFamily:serif, fontSize:28, fontWeight:600, letterSpacing:"4px", color:C.accent, textAlign:"center" }}>{c.example.answer}</div>
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
function Round({ round, isPractice, practiceIdx, dayNum, onFinish }) {
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
    if (g === round.answer) {
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
function Results({ round, score, dayNum }) {
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
        <div style={{ fontFamily:sans, fontSize:11.5, color:C.faint, marginTop:8 }}>New thread at midnight</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// ALREADY PLAYED TODAY
// ─────────────────────────────────────────────
function AlreadyPlayed({ saved, dayNum }) {
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
        <div style={{ fontFamily:sans, fontSize:11.5, color:C.faint, marginTop:16 }}>Come back tomorrow for a new thread</div>
      </div>
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

  const dayNum = getDayNumber();
  const daily = useRef(getDailyRound());

  useEffect(() => {
    (async () => {
      try {
        const res = await storage.get(`thread-${todayKey()}`);
        if (res) { setSaved(JSON.parse(res.value)); setPhase("already"); return; }
      } catch {}
      try {
        const tut = await storage.get("thread-tut-done");
        if (tut) { setPhase("daily"); return; }
      } catch {}
      setPhase("tutorial");
    })();
  }, []);

  const go = (p) => { setFade(true); setTimeout(()=>{ setPhase(p); setFade(false); }, 300); };

  const markTut = async () => { try { await storage.set("thread-tut-done","1"); } catch{} };

  const saveDailyResult = async (score) => {
    const data = { cluesUsed: score, answer: daily.current.answer };
    try { await storage.set(`thread-${todayKey()}`, JSON.stringify(data)); } catch {}
  };

  if (phase === "loading") return (
    <div style={{ ...SCREEN_STYLE, background:C.bg }}>
      <style>{CSS}</style><ThreadLine/>
      <div style={{ fontFamily:serif, fontSize:30, fontWeight:300, letterSpacing:"10px", color:C.faint, textTransform:"uppercase" }}>Thread</div>
    </div>
  );

  return (
    <div style={{ minHeight:"100dvh", background:C.bg, position:"relative", overflowX:"hidden" }}>
      <style>{CSS}</style>
      <ThreadLine/>
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
          <Round key="daily" round={daily.current} dayNum={dayNum}
            onFinish={(score) => {
              setDailyScore(score);
              saveDailyResult(score);
              go("results");
            }}
          />
        )}

        {phase === "results" && (
          <Results round={daily.current} score={dailyScore} dayNum={dayNum}/>
        )}

        {phase === "already" && (
          <AlreadyPlayed saved={saved} dayNum={dayNum}/>
        )}
      </div>
    </div>
  );
}
