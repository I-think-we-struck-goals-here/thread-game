#!/usr/bin/env node

import { readFile, readdir, stat, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const LONDON_TIME_ZONE = "Europe/London";
const DAY_NUMBER_ANCHOR = "2026-02-16";
const ROUND_RESET_ANCHOR = "2026-03-31";
const SHUFFLE_SEED = 20260331;
const BUFFER_API_URL = "https://api.buffer.com";
const DAILY_MARKER = "#DailyThread";
const DEFAULT_QUEUE_SIZE = 9;
const DEFAULT_POST_HOUR = 10;
const DEFAULT_POST_MINUTE = 5;
const TEMPLATE_VERSION = "2026-08-05-v3";

function parseArgs(values) {
  const [command = "help", ...rest] = values;
  const flags = {};

  for (let index = 0; index < rest.length; index += 1) {
    const item = rest[index];
    if (!item.startsWith("--")) throw new Error(`Unexpected argument: ${item}`);
    const name = item.slice(2);
    const next = rest[index + 1];
    if (next && !next.startsWith("--")) {
      flags[name] = next;
      index += 1;
    } else {
      flags[name] = true;
    }
  }

  return { command, flags };
}

function numberFlag(flags, name, fallback) {
  if (flags[name] === undefined) return fallback;
  const value = Number(flags[name]);
  if (!Number.isInteger(value)) throw new Error(`--${name} must be an integer.`);
  return value;
}

function parseDateKey(dateKey) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey);
  if (!match) throw new Error(`Invalid date: ${dateKey}`);
  const [, year, month, day] = match;
  const value = Date.UTC(Number(year), Number(month) - 1, Number(day));
  const check = new Date(value).toISOString().slice(0, 10);
  if (check !== dateKey) throw new Error(`Invalid date: ${dateKey}`);
  return { year: Number(year), month: Number(month), day: Number(day), value };
}

function addDays(dateKey, days) {
  const { value } = parseDateKey(dateKey);
  return new Date(value + days * 86_400_000).toISOString().slice(0, 10);
}

function daysBetween(startDateKey, endDateKey) {
  return Math.floor((parseDateKey(endDateKey).value - parseDateKey(startDateKey).value) / 86_400_000);
}

function londonParts(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: LONDON_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(part => [part.type, part.value]));
  return {
    year: Number(values.year),
    month: Number(values.month),
    day: Number(values.day),
    hour: Number(values.hour),
    minute: Number(values.minute),
  };
}

function londonDateKey(date = new Date()) {
  const { year, month, day } = londonParts(date);
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function londonDueAt(dateKey, hour = DEFAULT_POST_HOUR, minute = DEFAULT_POST_MINUTE) {
  const { year, month, day } = parseDateKey(dateKey);
  const target = Date.UTC(year, month - 1, day, hour, minute);
  let guess = target;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    const observed = londonParts(new Date(guess));
    const observedValue = Date.UTC(
      observed.year,
      observed.month - 1,
      observed.day,
      observed.hour,
      observed.minute,
    );
    guess += target - observedValue;
  }

  const check = londonParts(new Date(guess));
  if (
    check.year !== year || check.month !== month || check.day !== day ||
    check.hour !== hour || check.minute !== minute
  ) {
    throw new Error(`Could not resolve London time for ${dateKey}.`);
  }
  return new Date(guess).toISOString();
}

function shuffleWithSeed(items, seed) {
  let state = seed >>> 0;
  const next = () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 4294967296;
  };

  const shuffled = [...items];
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(next() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex], shuffled[index]];
  }
  return shuffled;
}

function normalizeClue(clue) {
  const word = String(clue?.word ?? clue?.w ?? "").trim().toUpperCase();
  const connection = String(clue?.connection ?? clue?.c ?? "").trim();
  if (!word || !connection) throw new Error(`Invalid clue: ${JSON.stringify(clue)}`);
  return { word, connection };
}

function normalizeRound(round) {
  const answer = String(round?.answer ?? "").trim().toUpperCase();
  const clues = Array.isArray(round?.clues) ? round.clues.map(normalizeClue) : [];
  if (!answer || clues.length !== 5) throw new Error(`Invalid round: ${answer || "unknown"}`);
  return { answer, clues };
}

async function loadFutureRounds(roundsPath) {
  const moduleUrl = pathToFileURL(resolve(roundsPath)).href;
  const source = await import(moduleUrl);
  if (!Array.isArray(source.NEW_ROUNDS) || !source.NEW_ROUNDS.length) {
    throw new Error(`NEW_ROUNDS was not found in ${roundsPath}.`);
  }
  return shuffleWithSeed(source.NEW_ROUNDS.map(normalizeRound), SHUFFLE_SEED);
}

function captionFor(post) {
  return `Could you get it from the first clue? 🧵

One hidden word makes a word or phrase with each of the five clues.

Start with ${post.clues[0].word}. Swipe only when you need another.

Got it? Comment how many clues you needed: 1 to 5. No spoilers 🤫

Send this to someone who thinks they’d get it in one.

Ready for today’s thread?
Play Daily Thread free on iPhone. Link in bio.

#DailyThread #WordGame #WordPuzzle #BrainTeaser`;
}

function altTextFor(post, slideNumber) {
  if (slideNumber <= 5) {
    const words = post.clues.slice(0, slideNumber).map(clue => clue.word).join(", ");
    return `Daily Thread #${post.threadNumber}. Clues revealed: ${words}. Find the word connecting all five clues.`;
  }
  if (slideNumber === 6) {
    const connections = post.clues.map(clue => clue.connection).join(", ");
    return `Daily Thread #${post.threadNumber} answer: ${post.answer}. Connections: ${connections}.`;
  }
  return "Daily Thread. One word, five clues, every day. Play free on iPhone through the link in bio.";
}

function postForDate(postDate, futureRounds) {
  const sourceDate = addDays(postDate, -1);
  const cycleIndex = daysBetween(ROUND_RESET_ANCHOR, sourceDate);
  if (cycleIndex < 0) throw new Error(`Social automation only supports dates from ${ROUND_RESET_ANCHOR}.`);
  const round = futureRounds[cycleIndex % futureRounds.length];
  const threadNumber = daysBetween(DAY_NUMBER_ANCHOR, sourceDate) + 1;
  const post = {
    templateVersion: TEMPLATE_VERSION,
    postDate,
    sourceDate,
    threadNumber,
    answer: round.answer,
    clues: round.clues,
  };
  return {
    ...post,
    caption: captionFor(post),
    altText: Array.from({ length: 7 }, (_, index) => altTextFor(post, index + 1)),
  };
}

function desiredPostDates(startDate, days) {
  if (days < 1 || days > 30) throw new Error("--days must be between 1 and 30.");
  return Array.from({ length: days }, (_, index) => addDays(startDate, index));
}

function pngDimensions(buffer) {
  const signature = buffer.subarray(0, 8).toString("hex");
  if (signature !== "89504e470d0a1a0a" || buffer.length < 24) throw new Error("Invalid PNG file.");
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

async function validatePostFolder(folder, expected = null) {
  const rawPost = JSON.parse(await readFile(resolve(folder, "post.json"), "utf8"));
  if (expected) {
    for (const key of ["templateVersion", "postDate", "sourceDate", "threadNumber", "answer"]) {
      if (rawPost[key] !== expected[key]) throw new Error(`${folder} has stale ${key}.`);
    }
    if (JSON.stringify(rawPost.clues) !== JSON.stringify(expected.clues)) {
      throw new Error(`${folder} has stale clues.`);
    }
  }

  for (let slide = 1; slide <= 7; slide += 1) {
    const path = resolve(folder, `slide-${String(slide).padStart(2, "0")}.png`);
    const image = await readFile(path);
    const dimensions = pngDimensions(image);
    if (dimensions.width !== 1080 || dimensions.height !== 1350 || image.length < 20_000) {
      throw new Error(`${path} failed image QC (${dimensions.width}x${dimensions.height}, ${image.length} bytes).`);
    }
  }
  return rawPost;
}

async function folderIsCurrent(folder, expected) {
  try {
    await validatePostFolder(folder, expected);
    return true;
  } catch {
    return false;
  }
}

async function renderPosts({ posts, outputDir, templatePath }) {
  const pending = [];
  for (const post of posts) {
    const folder = resolve(outputDir, post.postDate);
    if (!(await folderIsCurrent(folder, post))) pending.push({ post, folder });
  }

  if (!pending.length) {
    console.log(`Render: ${posts.length} post set(s) already pass QC.`);
    return;
  }

  const { chromium } = await import("playwright");
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 1400 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  try {
    await page.goto(pathToFileURL(templatePath).href, { waitUntil: "load" });
    await page.waitForFunction(() => document.fonts.status === "loaded" && [...document.images].every(image => image.complete));
    const stage = page.locator("#postStage");
    const bounds = await stage.boundingBox();
    if (!bounds || Math.round(bounds.width) !== 1080 || Math.round(bounds.height) !== 1350) {
      throw new Error(`Template canvas is ${bounds?.width}x${bounds?.height}, expected 1080x1350.`);
    }

    for (const { post, folder } of pending) {
      await mkdir(folder, { recursive: true });
      await page.evaluate(data => window.setPostData(data), post);

      for (let slide = 1; slide <= 7; slide += 1) {
        await page.evaluate(number => window.showSlide(number), slide);
        const path = resolve(folder, `slide-${String(slide).padStart(2, "0")}.png`);
        await stage.screenshot({ path, type: "png" });
      }

      await writeFile(resolve(folder, "caption.txt"), `${post.caption}\n`);
      await writeFile(
        resolve(folder, "post.json"),
        `${JSON.stringify({ ...post, generatedAt: new Date().toISOString() }, null, 2)}\n`,
      );
      await validatePostFolder(folder, post);
      console.log(`Rendered Thread #${post.threadNumber} for ${post.postDate} from ${post.sourceDate}.`);
    }
  } finally {
    await browser.close();
  }
}

async function bufferRequest(apiKey, query) {
  const response = await fetch(BUFFER_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) throw new Error(`Buffer returned HTTP ${response.status}.`);
  if (!payload || payload.errors?.length) {
    throw new Error(payload?.errors?.map(error => error.message).join("; ") || "Invalid Buffer response.");
  }
  return payload.data;
}

async function bufferConnection(apiKey) {
  const account = await bufferRequest(apiKey, `query SocialAutomationAccount {
    account { id organizations { id name } }
  }`);
  const organizations = account.account.organizations;
  const channels = [];

  for (const organization of organizations) {
    const result = await bufferRequest(apiKey, `query SocialAutomationChannels {
      channels(input: { organizationId: ${JSON.stringify(organization.id)} }) {
        id name displayName service isDisconnected isLocked
      }
    }`);
    channels.push(...result.channels.map(channel => ({ ...channel, organizationId: organization.id })));
  }

  const instagram = channels.filter(channel => (
    channel.service === "instagram" && !channel.isDisconnected && !channel.isLocked
  ));
  if (instagram.length !== 1) throw new Error(`Expected one available Instagram channel; found ${instagram.length}.`);
  return instagram[0];
}

async function bufferPosts(apiKey, channel, statuses) {
  const statusInput = statuses.join(", ");
  const result = await bufferRequest(apiKey, `query SocialAutomationPosts {
    posts(first: 100, input: {
      organizationId: ${JSON.stringify(channel.organizationId)}
      filter: { status: [${statusInput}], channelIds: [${JSON.stringify(channel.id)}] }
    }) {
      edges { node { id text dueAt status sentAt externalLink } }
    }
  }`);
  return result.posts.edges.map(edge => edge.node);
}

async function waitForImage(url, attempts = 12) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(url, { cache: "no-store" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const image = Buffer.from(await response.arrayBuffer());
      const dimensions = pngDimensions(image);
      if (dimensions.width !== 1080 || dimensions.height !== 1350) {
        throw new Error(`${dimensions.width}x${dimensions.height}`);
      }
      return;
    } catch (error) {
      lastError = error;
      if (attempt < attempts) await new Promise(resolvePromise => setTimeout(resolvePromise, 5_000));
    }
  }
  throw new Error(`Media did not become available at ${url}: ${lastError?.message}`);
}

function mediaUrls(mediaRoot, postDate) {
  return Array.from(
    { length: 7 },
    (_, index) => `${mediaRoot.replace(/\/$/, "")}/${postDate}/slide-${String(index + 1).padStart(2, "0")}.png`,
  );
}

async function createBufferPost(apiKey, channel, post, urls, dueAt) {
  const assets = urls.map((url, index) => `{
        image: {
          url: ${JSON.stringify(url)}
          metadata: { altText: ${JSON.stringify(post.altText[index])} }
        }
      }`).join(",\n      ");
  const result = await bufferRequest(apiKey, `mutation ScheduleDailyThreadCarousel {
    createPost(input: {
      text: ${JSON.stringify(post.caption)}
      channelId: ${JSON.stringify(channel.id)}
      schedulingType: automatic
      mode: customScheduled
      dueAt: ${JSON.stringify(dueAt)}
      metadata: { instagram: { type: post shouldShareToFeed: true } }
      assets: [${assets}]
    }) {
      ... on PostActionSuccess { post { id dueAt status assets { id mimeType } } }
      ... on MutationError { message }
    }
  }`);
  if (!result.createPost?.post) {
    throw new Error(result.createPost?.message || `Buffer rejected ${post.postDate}.`);
  }
  return result.createPost.post;
}

async function scheduleQueue({ posts, outputDir, mediaRoot, queueSize }) {
  const apiKey = process.env.BUFFER_API_KEY?.trim();
  if (!apiKey) throw new Error("BUFFER_API_KEY is required.");
  const channel = await bufferConnection(apiKey);
  const scheduled = await bufferPosts(apiKey, channel, ["scheduled"]);
  const coveredDates = new Set(
    scheduled
      .filter(post => post.text?.includes(DAILY_MARKER) && post.dueAt)
      .map(post => londonDateKey(new Date(post.dueAt))),
  );
  let available = Math.max(0, queueSize - scheduled.length);
  let created = 0;

  for (const expected of posts) {
    if (coveredDates.has(expected.postDate)) {
      console.log(`Buffer: ${expected.postDate} already scheduled.`);
      continue;
    }
    if (available === 0) {
      console.log(`Buffer: queue target of ${queueSize} reached; remaining dates will be added after a slot opens.`);
      break;
    }

    const folder = resolve(outputDir, expected.postDate);
    const post = await validatePostFolder(folder, expected);
    const urls = mediaUrls(mediaRoot, expected.postDate);
    for (const url of urls) await waitForImage(url);
    const dueAt = londonDueAt(expected.postDate);
    const result = await createBufferPost(apiKey, channel, post, urls, dueAt);
    if (result.assets?.length !== 7) throw new Error(`Buffer returned ${result.assets?.length ?? 0} assets for ${expected.postDate}.`);
    console.log(`Buffer: scheduled Thread #${post.threadNumber} for ${expected.postDate} at ${result.dueAt}.`);
    coveredDates.add(expected.postDate);
    available -= 1;
    created += 1;
  }

  console.log(`Buffer queue check complete: ${scheduled.length} existing, ${created} created.`);
}

async function auditToday() {
  const apiKey = process.env.BUFFER_API_KEY?.trim();
  if (!apiKey) throw new Error("BUFFER_API_KEY is required.");
  const channel = await bufferConnection(apiKey);
  const posts = await bufferPosts(apiKey, channel, ["scheduled", "sent"]);
  const today = londonDateKey();
  const match = posts.find(post => (
    post.text?.includes(DAILY_MARKER) && post.dueAt && londonDateKey(new Date(post.dueAt)) === today
  ));
  if (!match) throw new Error(`No scheduled or sent Daily Thread post was found for ${today}.`);
  console.log(`Audit: ${today} is ${match.status}${match.externalLink ? ` at ${match.externalLink}` : ""}.`);
}

async function selfTest(roundsPath) {
  const rounds = await loadFutureRounds(roundsPath);
  const known = postForDate("2026-08-05", rounds);
  if (
    known.threadNumber !== 170 || known.sourceDate !== "2026-08-04" || known.answer !== "TIME" ||
    known.clues.map(clue => clue.word).join(",") !== "OVER,BED,HALF,BOMB,OUT"
  ) {
    throw new Error(`Schedule regression: ${JSON.stringify(known)}`);
  }
  if (londonDueAt("2026-08-06") !== "2026-08-06T09:05:00.000Z") {
    throw new Error("BST scheduling regression.");
  }
  if (londonDueAt("2026-12-06") !== "2026-12-06T10:05:00.000Z") {
    throw new Error("GMT scheduling regression.");
  }
  if (!known.caption.includes("Start with OVER") || !known.caption.includes(DAILY_MARKER)) {
    throw new Error("Caption regression.");
  }
  console.log("Self-test: schedule, London time and caption checks passed.");
}

function help() {
  console.log(`Usage:
  node social-automation/cli.mjs self-test [--rounds path]
  node social-automation/cli.mjs render [--start-date YYYY-MM-DD] [--days 9] [--output docs/social] [--rounds path]
  node social-automation/cli.mjs schedule --media-root URL [--start-date YYYY-MM-DD] [--days 9] [--output docs/social]
  node social-automation/cli.mjs audit`);
}

const { command, flags } = parseArgs(process.argv.slice(2));
const roundsPath = resolve(flags.rounds || resolve(HERE, "../src/new-rounds.js"));
const outputDir = resolve(flags.output || "docs/social");
const startDate = flags["start-date"] || addDays(londonDateKey(), 1);
const days = numberFlag(flags, "days", DEFAULT_QUEUE_SIZE);
const queueSize = numberFlag(flags, "queue-size", DEFAULT_QUEUE_SIZE);

if (command === "self-test") {
  await selfTest(roundsPath);
} else if (command === "render") {
  const rounds = await loadFutureRounds(roundsPath);
  const posts = desiredPostDates(startDate, days).map(date => postForDate(date, rounds));
  await renderPosts({ posts, outputDir, templatePath: resolve(HERE, "template.html") });
} else if (command === "schedule") {
  if (!flags["media-root"]) throw new Error("--media-root is required.");
  const rounds = await loadFutureRounds(roundsPath);
  const posts = desiredPostDates(startDate, days).map(date => postForDate(date, rounds));
  await scheduleQueue({ posts, outputDir, mediaRoot: flags["media-root"], queueSize });
} else if (command === "audit") {
  await auditToday();
} else {
  help();
  if (command !== "help") process.exitCode = 1;
}
