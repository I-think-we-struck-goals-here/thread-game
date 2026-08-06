#!/usr/bin/env node

import { readFile, readdir, stat, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn } from "node:child_process";

const HERE = dirname(fileURLToPath(import.meta.url));
const LONDON_TIME_ZONE = "Europe/London";
const DAY_NUMBER_ANCHOR = "2026-02-16";
const ROUND_RESET_ANCHOR = "2026-03-31";
const SHUFFLE_SEED = 20260331;
const BUFFER_API_URL = "https://api.buffer.com";
const DAILY_MARKER = "#DailyThread";
const DEFAULT_QUEUE_SIZE = 9;
const DEFAULT_DAYS = 5;
const CAROUSEL_POST_TIME = { hour: 10, minute: 5 };
const REEL_POST_TIME = { hour: 18, minute: 30 };
const TEMPLATE_VERSION = "2026-08-06-v5-carousel-layout";
const REEL_HIGHLIGHT_EXCEPTIONS = new Map([
  ["SPINE|SPINAL CORD", "Spinal"],
  ["FENCE|FENCING (THE SPORT)", "Fencing"],
  ["STRAIGHT|STRAITJACKET", "Strait"],
]);

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

function runProcess(command, args) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, { stdio: "inherit" });
    child.on("error", reject);
    child.on("exit", code => code === 0
      ? resolvePromise()
      : reject(new Error(`${command} exited ${code}`)));
  });
}

function runCapture(command, args) {
  return new Promise((resolvePromise, reject) => {
    let stdout = "";
    let stderr = "";
    const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
    child.stdout.on("data", chunk => { stdout += chunk; });
    child.stderr.on("data", chunk => { stderr += chunk; });
    child.on("error", reject);
    child.on("exit", code => code === 0
      ? resolvePromise(stdout.trim())
      : reject(new Error(`${command} exited ${code}: ${stderr.trim()}`)));
  });
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

function londonDueAt(dateKey, hour = CAROUSEL_POST_TIME.hour, minute = CAROUSEL_POST_TIME.minute) {
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

function reelCaptionFor(post) {
  return `Could you connect all five? 🧵

${post.clues[0].word} was clue one. How many clues did you need?

Comment 1–5. No spoilers 🤫

Play today’s Daily Thread free on iPhone. Link in bio.

#DailyThread #WordGame #WordPuzzle #BrainTeaser`;
}

function reelAltTextFor(post) {
  const words = post.clues.map(clue => clue.word).join(", ");
  const connections = post.clues.map(clue => clue.connection).join(", ");
  return `Daily Thread #${post.threadNumber} word-puzzle Reel. The clues ${words} appear one every five seconds. The answer ${post.answer} makes: ${connections}.`;
}

function normalizedConnection(value) {
  return value.toLocaleUpperCase().replace(/\s+/g, " ").trim();
}

function isPureJoin(clue, answer) {
  const connection = normalizedConnection(clue.connection);
  const clueWord = normalizedConnection(clue.word);
  const answerWord = normalizedConnection(answer);
  return [
    `${clueWord}${answerWord}`,
    `${clueWord} ${answerWord}`,
    `${answerWord}${clueWord}`,
    `${answerWord} ${clueWord}`,
  ].includes(connection);
}

function highlightForPhrase(clue, answer) {
  const connection = clue.connection;
  const answerIndex = connection.toLocaleUpperCase().indexOf(answer.toLocaleUpperCase());
  if (answerIndex !== -1) return connection.slice(answerIndex, answerIndex + answer.length);
  const exception = REEL_HIGHLIGHT_EXCEPTIONS.get(`${answer}|${normalizedConnection(connection)}`);
  if (!exception) throw new Error(`No Reel highlight for ${answer}: ${connection}`);
  return exception;
}

function reelDataFor(post) {
  const mode = post.clues.every(clue => isPureJoin(clue, post.answer)) ? "join" : "phrase";
  return {
    threadNumber: post.threadNumber,
    mode,
    answer: post.answer,
    answerNarrationStartMs: 26600,
    clues: post.clues.map(clue => mode === "join"
      ? { word: clue.word, connection: clue.connection }
      : { ...clue, highlight: highlightForPhrase(clue, post.answer) }),
  };
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
    reelCaption: reelCaptionFor(post),
    reelAltText: reelAltTextFor(post),
    reel: reelDataFor(post),
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

function reelFilename(post) {
  return `daily-thread-${post.threadNumber}-reel.mp4`;
}

async function validateReel(path) {
  const file = await stat(path);
  if (file.size < 100_000 || file.size > 300_000_000) {
    throw new Error(`${path} failed file-size QC (${file.size} bytes).`);
  }
  const output = await runCapture("ffprobe", [
    "-v", "error",
    "-show_entries", "stream=codec_type,codec_name,width,height,r_frame_rate,sample_rate:format=duration",
    "-of", "json",
    path,
  ]);
  const probe = JSON.parse(output);
  const video = probe.streams?.find(stream => stream.codec_type === "video");
  const audio = probe.streams?.find(stream => stream.codec_type === "audio");
  const duration = Number(probe.format?.duration);
  if (
    video?.codec_name !== "h264" || video.width !== 1080 || video.height !== 1920 ||
    video.r_frame_rate !== "30/1" || audio?.codec_name !== "aac" ||
    Number(audio.sample_rate) !== 48_000 || Math.abs(duration - 30) > .05
  ) {
    throw new Error(`${path} failed encoded-media QC: ${JSON.stringify(probe)}`);
  }
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
    if (JSON.stringify(rawPost.reel) !== JSON.stringify(expected.reel)) {
      throw new Error(`${folder} has stale Reel data.`);
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
  const reelData = JSON.parse(await readFile(resolve(folder, "reel.json"), "utf8"));
  if (JSON.stringify(reelData) !== JSON.stringify(rawPost.reel)) {
    throw new Error(`${folder} Reel manifest does not match post.json.`);
  }
  const reelCaption = (await readFile(resolve(folder, "reel-caption.txt"), "utf8")).trim();
  const reelAltText = (await readFile(resolve(folder, "reel-alt-text.txt"), "utf8")).trim();
  if (reelCaption !== rawPost.reelCaption || reelAltText !== rawPost.reelAltText) {
    throw new Error(`${folder} has stale Reel copy.`);
  }
  await validateReel(resolve(folder, reelFilename(rawPost)));
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

async function renderPosts({ posts, outputDir, templatePath, reelRendererPath }) {
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
      await assertCarouselLayout(page, post);

      for (let slide = 1; slide <= 7; slide += 1) {
        await page.evaluate(number => window.showSlide(number), slide);
        const path = resolve(folder, `slide-${String(slide).padStart(2, "0")}.png`);
        await stage.screenshot({ path, type: "png" });
      }

      await writeFile(resolve(folder, "caption.txt"), `${post.caption}\n`);
      await writeFile(resolve(folder, "reel-caption.txt"), `${post.reelCaption}\n`);
      await writeFile(resolve(folder, "reel-alt-text.txt"), `${post.reelAltText}\n`);
      await writeFile(resolve(folder, "reel.json"), `${JSON.stringify(post.reel, null, 2)}\n`);
      await writeFile(
        resolve(folder, "post.json"),
        `${JSON.stringify({ ...post, generatedAt: new Date().toISOString() }, null, 2)}\n`,
      );
    }
  } finally {
    await browser.close();
  }

  for (const { post, folder } of pending) {
    await runProcess(process.execPath, [
      reelRendererPath,
      "--data", resolve(folder, "reel.json"),
      "--intro", resolve(HERE, "voice/intro.wav"),
      "--answer", resolve(HERE, "voice/answer.wav"),
      "--output", resolve(folder, reelFilename(post)),
    ]);
    await validatePostFolder(folder, post);
    console.log(`Rendered carousel and ${post.reel.mode}-mode Reel for Thread #${post.threadNumber} on ${post.postDate}.`);
  }
}

async function assertCarouselLayout(page, post, expectedClueSize = null) {
  const metrics = await page.evaluate(() => window.getCarouselLayoutMetrics());
  if (metrics.paper !== "#f8f5f0" || metrics.stageBackground !== "rgb(248, 245, 240)") {
    throw new Error(`Thread #${post.threadNumber} has the wrong paper colour: ${JSON.stringify(metrics)}.`);
  }
  if (metrics.clueSizes.length !== 1 || metrics.clueSizes[0] < 22 || metrics.clueSizes[0] > 42) {
    throw new Error(`Thread #${post.threadNumber} has inconsistent or unreadable clue sizing: ${JSON.stringify(metrics)}.`);
  }
  if (expectedClueSize !== null && metrics.clueSizes[0] !== expectedClueSize) {
    throw new Error(`Thread #${post.threadNumber} expected ${expectedClueSize}px clues, got ${metrics.clueSizes[0]}px.`);
  }
  if (metrics.firstWordRight > metrics.howToPlayLeft - metrics.safeGap + .5) {
    throw new Error(`Thread #${post.threadNumber} first clue overlaps the How to play safe area: ${JSON.stringify(metrics)}.`);
  }
  if (metrics.firstWordWidth >= metrics.stackWidth) {
    throw new Error(`Thread #${post.threadNumber} is measuring a full-width clue container instead of its glyphs.`);
  }
  return metrics;
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
      edges {
        node {
          id
          text
          dueAt
          status
          sentAt
          externalLink
          assets {
            id
            mimeType
            ... on ImageAsset {
              image { altText }
            }
          }
        }
      }
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

async function waitForVideo(url, attempts = 12) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(url, { cache: "no-store" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const video = Buffer.from(await response.arrayBuffer());
      if (video.length < 100_000 || video.subarray(4, 8).toString("ascii") !== "ftyp") {
        throw new Error(`invalid MP4 (${video.length} bytes)`);
      }
      return;
    } catch (error) {
      lastError = error;
      if (attempt < attempts) await new Promise(resolvePromise => setTimeout(resolvePromise, 5_000));
    }
  }
  throw new Error(`Video did not become available at ${url}: ${lastError?.message}`);
}

function carouselMediaUrls(mediaRoot, postDate) {
  return Array.from(
    { length: 7 },
    (_, index) => `${mediaRoot.replace(/\/$/, "")}/${postDate}/slide-${String(index + 1).padStart(2, "0")}.png`,
  );
}

function reelMediaUrl(mediaRoot, post) {
  return `${mediaRoot.replace(/\/$/, "")}/${post.postDate}/${reelFilename(post)}`;
}

async function createBufferCarousel(apiKey, channel, post, urls, dueAt) {
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

async function createBufferReel(apiKey, channel, post, url, dueAt) {
  const result = await bufferRequest(apiKey, `mutation ScheduleDailyThreadReel {
    createPost(input: {
      text: ${JSON.stringify(post.reelCaption)}
      channelId: ${JSON.stringify(channel.id)}
      schedulingType: automatic
      mode: customScheduled
      dueAt: ${JSON.stringify(dueAt)}
      metadata: { instagram: { type: reel shouldShareToFeed: true } }
      assets: [{
        video: {
          url: ${JSON.stringify(url)}
          metadata: { thumbnailOffset: 600 title: ${JSON.stringify(`Daily Thread #${post.threadNumber}`)} }
        }
      }]
    }) {
      ... on PostActionSuccess { post { id dueAt status assets { id mimeType } } }
      ... on MutationError { message }
    }
  }`);
  if (!result.createPost?.post) {
    throw new Error(result.createPost?.message || `Buffer rejected Reel ${post.postDate}.`);
  }
  return result.createPost.post;
}

function bufferPostKind(post) {
  const mime = asset => String(asset?.mimeType || "").toLowerCase();
  if (post.assets?.length === 7 && post.assets.every(asset => mime(asset).startsWith("image"))) return "carousel";
  if (post.assets?.length === 1 && mime(post.assets[0]).startsWith("video")) return "reel";
  return null;
}

function desiredBufferItems(posts, mediaRoot) {
  return posts.flatMap(post => [
    {
      kind: "carousel",
      post,
      dueAt: londonDueAt(post.postDate, CAROUSEL_POST_TIME.hour, CAROUSEL_POST_TIME.minute),
      urls: carouselMediaUrls(mediaRoot, post.postDate),
    },
    {
      kind: "reel",
      post,
      dueAt: londonDueAt(post.postDate, REEL_POST_TIME.hour, REEL_POST_TIME.minute),
      url: reelMediaUrl(mediaRoot, post),
    },
  ]).sort((a, b) => a.dueAt.localeCompare(b.dueAt));
}

async function scheduleQueue({ posts, outputDir, mediaRoot, queueSize }) {
  const apiKey = process.env.BUFFER_API_KEY?.trim();
  if (!apiKey) throw new Error("BUFFER_API_KEY is required.");
  const channel = await bufferConnection(apiKey);
  const scheduled = await bufferPosts(apiKey, channel, ["scheduled"]);
  const sent = await bufferPosts(apiKey, channel, ["sent"]);
  const covered = new Set(
    [...scheduled, ...sent]
      .filter(post => post.text?.includes(DAILY_MARKER) && post.dueAt && bufferPostKind(post))
      .map(post => `${londonDateKey(new Date(post.dueAt))}:${bufferPostKind(post)}`),
  );
  const items = desiredBufferItems(posts, mediaRoot);
  let available = Math.max(0, queueSize - scheduled.length);
  let created = 0;

  for (const item of items) {
    const key = `${item.post.postDate}:${item.kind}`;
    if (covered.has(key)) {
      console.log(`Buffer: ${item.post.postDate} ${item.kind} already scheduled or sent.`);
      continue;
    }
    if (available === 0) {
      console.log(`Buffer: queue target of ${queueSize} reached; remaining posts will be added after a slot opens.`);
      break;
    }

    const folder = resolve(outputDir, item.post.postDate);
    const post = await validatePostFolder(folder, item.post);
    let dueAt = item.dueAt;
    if (new Date(dueAt).getTime() <= Date.now()) {
      if (item.post.postDate !== londonDateKey()) {
        console.log(`Buffer: skipping expired ${item.post.postDate} ${item.kind}.`);
        continue;
      }
      dueAt = new Date(Date.now() + 5 * 60_000).toISOString();
      console.log(`Buffer: recovering late ${item.kind} for today at ${dueAt}.`);
    }

    let result;
    if (item.kind === "carousel") {
      for (const url of item.urls) await waitForImage(url);
      result = await createBufferCarousel(apiKey, channel, post, item.urls, dueAt);
      if (result.assets?.length !== 7) {
        throw new Error(`Buffer returned ${result.assets?.length ?? 0} carousel assets for ${item.post.postDate}.`);
      }
    } else {
      await waitForVideo(item.url);
      result = await createBufferReel(apiKey, channel, post, item.url, dueAt);
      if (result.assets?.length !== 1 || !String(result.assets[0].mimeType || "").toLowerCase().startsWith("video")) {
        throw new Error(`Buffer returned an invalid Reel asset for ${item.post.postDate}.`);
      }
    }

    console.log(`Buffer: scheduled Thread #${post.threadNumber} ${item.kind} for ${item.post.postDate} at ${result.dueAt}.`);
    covered.add(key);
    available -= 1;
    created += 1;
  }

  console.log(`Buffer queue check complete: ${scheduled.length} existing, ${created} created.`);

  const verified = (await bufferPosts(apiKey, channel, ["scheduled"]))
    .filter(post => post.text?.includes(DAILY_MARKER) && bufferPostKind(post));
  if (!verified.length) throw new Error("Buffer audit found no scheduled Daily Thread posts.");
  const verifiedCarousels = verified.filter(post => bufferPostKind(post) === "carousel");
  const verifiedReels = verified.filter(post => bufferPostKind(post) === "reel");
  let verifiedImages = 0;
  for (const post of verifiedCarousels) {
    const missingAltText = post.assets.filter(asset => !asset.image?.altText?.trim());
    if (missingAltText.length) {
      throw new Error(`Buffer post ${post.id} is missing alt text on ${missingAltText.length} image(s).`);
    }
    verifiedImages += post.assets.length;
  }
  console.log(`Buffer audit: ${verifiedCarousels.length} carousel(s), ${verifiedReels.length} Reel(s), ${verifiedImages} carousel images described.`);
}

async function auditToday() {
  const apiKey = process.env.BUFFER_API_KEY?.trim();
  if (!apiKey) throw new Error("BUFFER_API_KEY is required.");
  const channel = await bufferConnection(apiKey);
  const posts = await bufferPosts(apiKey, channel, ["scheduled", "sent"]);
  const today = londonDateKey();
  const matches = posts.filter(post => (
    post.text?.includes(DAILY_MARKER) && post.dueAt &&
    londonDateKey(new Date(post.dueAt)) === today && bufferPostKind(post)
  ));
  const byKind = new Map(matches.map(post => [bufferPostKind(post), post]));
  const missing = ["carousel", "reel"].filter(kind => !byKind.has(kind));
  if (missing.length) {
    throw new Error(`Daily Thread audit for ${today} is missing: ${missing.join(", ")}.`);
  }
  for (const kind of ["carousel", "reel"]) {
    const post = byKind.get(kind);
    console.log(`Audit: ${today} ${kind} is ${post.status}${post.externalLink ? ` at ${post.externalLink}` : ""}.`);
  }
}

async function carouselLayoutTest(rounds, templatePath) {
  const { chromium } = await import("playwright");
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 1400 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  let minimumSize = 42;
  let scaledRounds = 0;

  try {
    await page.goto(pathToFileURL(templatePath).href, { waitUntil: "load" });
    await page.waitForFunction(() => document.fonts.status === "loaded" && [...document.images].every(image => image.complete));

    for (let index = 0; index < rounds.length; index += 1) {
      const fixture = { threadNumber: index + 1, ...rounds[index] };
      await page.evaluate(data => window.setPostData(data), fixture);
      const metrics = await assertCarouselLayout(page, fixture);
      minimumSize = Math.min(minimumSize, metrics.clueSizes[0]);
      if (metrics.clueSizes[0] < 42) scaledRounds += 1;
    }

    const fourLetterFixture = {
      threadNumber: 171,
      answer: "GOLD",
      clues: [
        { word: "MARI", connection: "Marigold" },
        { word: "MINE", connection: "Gold mine" },
        { word: "RUSH", connection: "Gold rush" },
        { word: "STANDARD", connection: "Gold standard" },
        { word: "FISH", connection: "Goldfish" },
      ],
    };
    await page.evaluate(data => window.setPostData(data), fourLetterFixture);
    await assertCarouselLayout(page, fourLetterFixture, 42);

    const tomorrowFixture = {
      threadNumber: 172,
      answer: "DOUBLE",
      clues: [
        { word: "TROUBLE", connection: "Double trouble" },
        { word: "DUTCH", connection: "Double Dutch" },
        { word: "TAKE", connection: "Double take" },
        { word: "EDGE", connection: "Double-edged sword" },
        { word: "AGENT", connection: "Double agent" },
      ],
    };
    await page.evaluate(data => window.setPostData(data), tomorrowFixture);
    await assertCarouselLayout(page, tomorrowFixture, 34);
  } finally {
    await browser.close();
  }

  console.log(`Carousel layout: ${rounds.length} rounds passed; ${scaledRounds} first clue(s) scale, readability floor ${minimumSize}px.`);
}

async function selfTest(roundsPath, templatePath) {
  const rounds = await loadFutureRounds(roundsPath);
  const known = postForDate("2026-08-05", rounds);
  if (
    known.threadNumber !== 170 || known.sourceDate !== "2026-08-04" || known.answer !== "TIME" ||
    known.clues.map(clue => clue.word).join(",") !== "OVER,BED,HALF,BOMB,OUT"
  ) {
    throw new Error(`Schedule regression: ${JSON.stringify(known)}`);
  }
  if (known.reel.mode !== "join") {
    throw new Error("Known join-mode Reel regression.");
  }
  const phraseFixture = {
    threadNumber: 0,
    answer: "BRIDGE",
    clues: [
      { word: "NOSE", connection: "Bridge of the nose" },
      { word: "CROSS", connection: "Cross that bridge" },
      { word: "WATER", connection: "Bridge over troubled water" },
      { word: "DENTAL", connection: "Dental bridge" },
      { word: "TOWER", connection: "Tower Bridge" },
    ],
  };
  if (reelDataFor(phraseFixture).mode !== "phrase") {
    throw new Error("Phrase-mode Reel regression.");
  }
  for (let index = 0; index < rounds.length; index += 1) {
    reelDataFor({ threadNumber: index + 1, ...rounds[index] });
  }
  if (
    londonDueAt("2026-08-06", 10, 5) !== "2026-08-06T09:05:00.000Z" ||
    londonDueAt("2026-08-06", 18, 30) !== "2026-08-06T17:30:00.000Z"
  ) {
    throw new Error("BST scheduling regression.");
  }
  if (
    londonDueAt("2026-12-06", 10, 5) !== "2026-12-06T10:05:00.000Z" ||
    londonDueAt("2026-12-06", 18, 30) !== "2026-12-06T18:30:00.000Z"
  ) {
    throw new Error("GMT scheduling regression.");
  }
  if (!known.caption.includes("Start with OVER") || !known.caption.includes(DAILY_MARKER)) {
    throw new Error("Caption regression.");
  }
  await carouselLayoutTest(rounds, templatePath);
  console.log(`Self-test: ${rounds.length} rounds, two Reel modes, London times and captions passed.`);
}

async function planSchedule({ posts, outputDir, mediaRoot }) {
  for (const post of posts) await validatePostFolder(resolve(outputDir, post.postDate), post);
  for (const item of desiredBufferItems(posts, mediaRoot)) {
    const media = item.kind === "carousel" ? `${item.urls.length} images` : item.url;
    console.log(`${item.dueAt} | ${item.post.postDate} | ${item.kind} | ${media}`);
  }
}

function help() {
  console.log(`Usage:
  node social-automation/cli.mjs self-test [--rounds path]
  node social-automation/cli.mjs render [--start-date YYYY-MM-DD] [--days 5] [--output docs/social] [--rounds path]
  node social-automation/cli.mjs plan --media-root URL [--start-date YYYY-MM-DD] [--days 5] [--output docs/social]
  node social-automation/cli.mjs schedule --media-root URL [--start-date YYYY-MM-DD] [--days 5] [--output docs/social]
  node social-automation/cli.mjs audit`);
}

const { command, flags } = parseArgs(process.argv.slice(2));
const roundsPath = resolve(flags.rounds || resolve(HERE, "../src/new-rounds.js"));
const outputDir = resolve(flags.output || "docs/social");
const startDate = flags["start-date"] || londonDateKey();
const days = numberFlag(flags, "days", DEFAULT_DAYS);
const queueSize = numberFlag(flags, "queue-size", DEFAULT_QUEUE_SIZE);

if (command === "self-test") {
  await selfTest(roundsPath, resolve(HERE, "template.html"));
} else if (command === "render") {
  const rounds = await loadFutureRounds(roundsPath);
  const posts = desiredPostDates(startDate, days).map(date => postForDate(date, rounds));
  await renderPosts({
    posts,
    outputDir,
    templatePath: resolve(HERE, "template.html"),
    reelRendererPath: resolve(HERE, "render-reel.mjs"),
  });
} else if (command === "plan") {
  if (!flags["media-root"]) throw new Error("--media-root is required.");
  const rounds = await loadFutureRounds(roundsPath);
  const posts = desiredPostDates(startDate, days).map(date => postForDate(date, rounds));
  await planSchedule({ posts, outputDir, mediaRoot: flags["media-root"] });
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
