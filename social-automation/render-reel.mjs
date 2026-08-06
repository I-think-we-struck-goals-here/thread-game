#!/usr/bin/env node

import { mkdtemp, mkdir, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const HERE = dirname(fileURLToPath(import.meta.url));
const FPS = 30;
const DURATION = 30;
const FRAME_COUNT = Math.round(FPS * DURATION);

function parseArgs(values) {
  const flags = {};
  for (let index = 0; index < values.length; index += 1) {
    const item = values[index];
    if (!item.startsWith('--')) throw new Error(`Unexpected argument: ${item}`);
    const name = item.slice(2);
    const next = values[index + 1];
    if (!next || next.startsWith('--')) throw new Error(`--${name} requires a value.`);
    flags[name] = next;
    index += 1;
  }
  return flags;
}

function run(command, args) {
  return new Promise((resolvePromise, reject) => {
    const quietArgs = command === 'ffmpeg' ? ['-hide_banner', '-loglevel', 'error', ...args] : args;
    const child = spawn(command, quietArgs, { stdio: 'inherit' });
    child.on('error', reject);
    child.on('exit', code => code === 0 ? resolvePromise() : reject(new Error(`${command} exited ${code}`)));
  });
}

function runCapture(command, args) {
  return new Promise((resolvePromise, reject) => {
    let stdout = '';
    let stderr = '';
    const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    child.stdout.on('data', chunk => { stdout += chunk; });
    child.stderr.on('data', chunk => { stderr += chunk; });
    child.on('error', reject);
    child.on('exit', code => code === 0
      ? resolvePromise(stdout.trim())
      : reject(new Error(`${command} exited ${code}: ${stderr.trim()}`)));
  });
}

function runCaptureDetailed(command, args) {
  return new Promise((resolvePromise, reject) => {
    let stdout = '';
    let stderr = '';
    const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    child.stdout.on('data', chunk => { stdout += chunk; });
    child.stderr.on('data', chunk => { stderr += chunk; });
    child.on('error', reject);
    child.on('exit', code => code === 0
      ? resolvePromise({ stdout: stdout.trim(), stderr: stderr.trim() })
      : reject(new Error(`${command} exited ${code}: ${stderr.trim()}`)));
  });
}

async function audioDuration(path) {
  const output = await runCapture('ffprobe', [
    '-v', 'error', '-show_entries', 'format=duration',
    '-of', 'default=noprint_wrappers=1:nokey=1', path,
  ]);
  const duration = Number(output);
  if (!Number.isFinite(duration) || duration <= 0) throw new Error(`Could not measure ${path}.`);
  return duration;
}

async function auditLayout(page, mode) {
  const capture = time => page.evaluate(({ sampleTime, reelMode }) => {
    window.renderFrame(sampleTime);
    const rect = element => {
      const box = element.getBoundingClientRect();
      return { left: box.left, right: box.right, top: box.top, bottom: box.bottom, width: box.width, height: box.height };
    };
    const list = document.querySelector(reelMode === 'phrase' ? '#phraseList' : '#resultList');
    const rowSelector = reelMode === 'phrase' ? '.phrase-clue' : '.result-connection';
    const rows = [...list.children].map(row => row.querySelector(rowSelector));
    return {
      hook: rect(document.querySelector('#mainHook')),
      list: rect(list),
      rows: rows.map(rect),
      fontSizes: rows.map(row => Number.parseFloat(getComputedStyle(row).fontSize)),
      answer: reelMode === 'phrase' ? rect(document.querySelector('#phraseAnswer')) : null,
      question: rect(document.querySelector('#resultQuestion')),
      cta: rect(document.querySelector('#resultCta')),
    };
  }, { sampleTime: time, reelMode: mode });

  const before = await capture(24.5);
  const final = await capture(29.5);
  const fail = message => { throw new Error(`Reel layout QC failed (${mode}): ${message}`); };
  const close = (a, b, tolerance = .11) => Math.abs(a - b) <= tolerance;

  if (!close(final.hook.left, final.list.left, 1.1)) {
    fail(`heading x=${final.hook.left.toFixed(2)} does not match clue block x=${final.list.left.toFixed(2)}`);
  }
  if (new Set(final.fontSizes.map(size => size.toFixed(2))).size !== 1) {
    fail(`row font sizes differ: ${final.fontSizes.join(', ')}`);
  }
  if (final.rows.some(row => row.left < 72 || row.right > 1008 || row.top < 285 || row.bottom > 1510)) {
    fail(`essential row content leaves the safe frame: ${JSON.stringify(final.rows)}`);
  }
  for (let index = 1; index < final.rows.length; index += 1) {
    if (final.rows[index - 1].bottom > final.rows[index].top) fail(`rows ${index} and ${index + 1} overlap`);
  }
  if (!close(final.question.left + final.question.width / 2, 540, 1.1) ||
      !close(final.cta.left + final.cta.width / 2, 540, 1.1)) {
    fail('question or CTA is not centred');
  }
  if (final.question.bottom > final.cta.top || final.cta.bottom > 1510) {
    fail('question/CTA collision or bottom safe-area breach');
  }

  if (mode === 'join') {
    for (let index = 0; index < final.rows.length; index += 1) {
      for (const edge of ['left', 'right', 'top', 'bottom']) {
        if (!close(before.rows[index][edge], final.rows[index][edge])) {
          fail(`row ${index + 1} ${edge} shifted during answer reveal`);
        }
      }
    }
  } else if (final.rows.at(-1).bottom > final.answer.top || final.answer.bottom > final.question.top) {
    fail('phrase answer collides with its connections or question');
  }
}

const flags = parseArgs(process.argv.slice(2));
const output = resolve(flags.output || 'daily-thread-reel.mp4');
const still = flags.still ? resolve(flags.still) : null;
const introAudio = flags.intro ? resolve(flags.intro) : null;
const answerAudio = flags.answer ? resolve(flags.answer) : null;
const frameDir = await mkdtemp(resolve(tmpdir(), 'daily-thread-reel-'));
const silentVideo = resolve(frameDir, 'silent.mp4');
const mixedAudio = resolve(frameDir, 'mixed.wav');

const defaultData = {
  threadNumber: 170,
  answer: 'TIME',
  clues: [
    { word: 'OVER', connection: 'Overtime' },
    { word: 'BED', connection: 'Bedtime' },
    { word: 'HALF', connection: 'Halftime' },
    { word: 'BOMB', connection: 'Time bomb' },
    { word: 'OUT', connection: 'Timeout' },
  ],
};
const data = flags.data
  ? JSON.parse(await readFile(resolve(flags.data), 'utf8'))
  : defaultData;

await mkdir(dirname(output), { recursive: true });
if (still) await mkdir(dirname(still), { recursive: true });

const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(resolve(HERE, 'reel-template.html')).href, { waitUntil: 'load' });
  await page.waitForFunction(() => document.fonts.status === 'loaded' && [...document.images].every(image => image.complete));
  await page.evaluate(reelData => window.setReelData(reelData), data);
  const stage = page.locator('#reelStage');
  const bounds = await stage.boundingBox();
  if (!bounds || Math.round(bounds.width) !== 1080 || Math.round(bounds.height) !== 1920) {
    throw new Error(`Reel stage is ${bounds?.width}x${bounds?.height}; expected 1080x1920.`);
  }
  await auditLayout(page, data.mode === 'phrase' ? 'phrase' : 'join');

  for (let frame = 0; frame < FRAME_COUNT; frame += 1) {
    await page.evaluate(time => window.renderFrame(time), frame / FPS);
    await stage.screenshot({ path: resolve(frameDir, `frame-${String(frame).padStart(4, '0')}.png`), type: 'png' });
  }

  if (still) {
    await page.evaluate(() => { window.renderFrame(0); window.showSafeGuides(true); });
    await stage.screenshot({ path: still, type: 'png' });
  }
} finally {
  await browser.close();
}

await run('ffmpeg', [
  '-y', '-framerate', String(FPS), '-i', resolve(frameDir, 'frame-%04d.png'),
  '-c:v', 'libx264', '-profile:v', 'high', '-level', '4.1', '-preset', 'slow',
  '-crf', '14', '-maxrate', '12M', '-bufsize', '18M',
  '-pix_fmt', 'yuv420p', '-r', String(FPS), '-an', '-movflags', '+faststart',
  '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', silentVideo,
]);

if (introAudio && answerAudio) {
  const narration = [
    { label: 'intro', path: introAudio, startMs: 300 },
    { label: 'answer', path: answerAudio, startMs: data.answerNarrationStartMs || 25300 },
  ];
  for (let index = 0; index < narration.length; index += 1) {
    narration[index].duration = await audioDuration(narration[index].path);
    const endMs = narration[index].startMs + narration[index].duration * 1000;
    if (index < narration.length - 1 && endMs + 250 > narration[index + 1].startMs) {
      throw new Error(
        `Narration overlap guard failed: ${narration[index].label} ends at ${endMs.toFixed(0)}ms, ` +
        `${narration[index + 1].label} starts at ${narration[index + 1].startMs}ms.`,
      );
    }
    if (endMs > DURATION * 1000 - 150) {
      throw new Error(`Narration clip ${narration[index].label} runs beyond the safe audio tail.`);
    }
  }

  const tickTimes = [4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19, 21, 22, 23, 24];
  const tickExpression = tickTimes.map(start => (
    `(0.022*sin(2*PI*760*(t-${start}))+0.008*sin(2*PI*380*(t-${start})))*` +
    `exp(-36*max(0,t-${start}))*between(t,${start},${start + .14})`
  )).join('+');
  const revealExpression = [5, 10, 15, 20].map(start => (
    `(0.035*sin(2*PI*523.251*(t-${start}))+0.018*sin(2*PI*783.991*(t-${start})))*` +
    `exp(-12*max(0,t-${start}))*between(t,${start},${start + .4})`
  )).join('+');
  const chimeExpression = [25.18, 25.3].map((start, index) => (
    `0.04*sin(2*PI*${index ? 659.255 : 440}*(t-${start}))*exp(-6*max(0,t-${start}))*between(t,${start},${start + .8})`
  )).join('+');
  const bedExpression =
    `(0.008*sin(2*PI*196*t)+0.005*sin(2*PI*246.942*t)+0.0035*sin(2*PI*293.665*t))*` +
    `(0.72+0.28*pow(sin(PI*t/5),2))*min(1,t/1.5)*min(1,(${DURATION}-t)/2)`;
  const soundExpression = `${bedExpression}+${tickExpression}+${revealExpression}+${chimeExpression}`;
  const ffmpegSoundExpression = soundExpression.replaceAll(',', '\\,');
  await run('ffmpeg', [
    '-y', '-i', introAudio,
    '-i', answerAudio,
    '-f', 'lavfi', '-t', String(DURATION), '-i', `aevalsrc=${ffmpegSoundExpression}:s=48000:d=${DURATION}`,
    '-filter_complex',
    `[0:a]aresample=48000,asetpts=PTS-STARTPTS,adelay=${narration[0].startMs}:all=1,volume=1.0[v1];` +
    `[1:a]aresample=48000,asetpts=PTS-STARTPTS,adelay=${narration[1].startMs}:all=1,volume=1.0[v2];` +
    '[v1][v2]amix=inputs=2:duration=longest:dropout_transition=0:normalize=0[narration];' +
    '[2:a]volume=1.5[sfx];' +
    '[narration][sfx]amix=inputs=2:duration=longest:dropout_transition=0:normalize=0,' +
    'acompressor=threshold=.25:ratio=2.5:attack=20:release=200:makeup=1.35[aout]',
    '-map', '[aout]', '-c:a', 'pcm_s24le', '-ar', '48000', '-t', String(DURATION), mixedAudio,
  ]);

  const analysis = await runCaptureDetailed('ffmpeg', [
    '-hide_banner', '-i', mixedAudio,
    '-af', 'loudnorm=I=-15:TP=-1.2:LRA=8:print_format=json',
    '-f', 'null', '-',
  ]);
  const matches = analysis.stderr.match(/\{\s*"input_i"[\s\S]*?\}/g);
  if (!matches?.length) throw new Error('Could not parse first-pass loudness measurements.');
  const measured = JSON.parse(matches.at(-1));
  const normalization =
    'loudnorm=I=-15:TP=-1.2:LRA=8:' +
    `measured_I=${measured.input_i}:measured_TP=${measured.input_tp}:` +
    `measured_LRA=${measured.input_lra}:measured_thresh=${measured.input_thresh}:` +
    `offset=${measured.target_offset}:linear=false,` +
    // Social playback needs consistent perceived level without clipping the
    // narration peaks. This finishing pass is verified against the encoded AAC,
    // not only the lossless intermediate.
    'acompressor=threshold=0.10:ratio=4:attack=15:release=180:makeup=1.4,' +
    'loudnorm=I=-15:TP=-1.5:LRA=8,' +
    // AAC encoding can overshoot the lossless true peak. Keep a final ceiling
    // so the published file remains below the -1 dBTP platform-safe limit.
    'alimiter=limit=0.88:attack=5:release=50:level=false';

  await run('ffmpeg', [
    '-y', '-i', silentVideo, '-i', mixedAudio,
    '-filter:a', normalization,
    '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '128k',
    '-ar', '48000', '-t', String(DURATION), '-movflags', '+faststart', output,
  ]);
} else {
  await run('ffmpeg', ['-y', '-i', silentVideo, '-c', 'copy', output]);
}

await rm(frameDir, { recursive: true, force: true });
console.log(`Rendered ${output}`);
