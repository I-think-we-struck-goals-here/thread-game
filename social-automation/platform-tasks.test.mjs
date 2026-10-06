import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { runPlatformTasks, selectBufferChannel } from "./platform-tasks.mjs";

for (const failures of [[], ["Instagram"], ["TikTok"], ["Instagram", "TikTok"]]) {
  test(`independent tasks: failing ${failures.join(", ") || "none"}`, async () => {
    const attempted = [], reported = [];
    const run = runPlatformTasks("schedule", ["Instagram", "TikTok"].map(platform => [platform, async () => {
      attempted.push(platform);
      if (failures.includes(platform)) throw new Error("fixture unavailable");
    }]), message => reported.push(message));
    if (failures.length) await assert.rejects(run, error => error instanceof AggregateError && error.errors.length === failures.length);
    else await run;
    assert.deepEqual(attempted, ["Instagram", "TikTok"]);
    assert.equal(reported.length, failures.length);
    for (const platform of failures) assert.ok(reported.some(message => message.startsWith(`${platform} schedule failed:`)));
  });
}

const healthy = { id: "private-channel", displayName: "private-name", service: "instagram", isDisconnected: false, isLocked: false };
test("even non-Error throws cannot block the next platform", async () => {
  for (const thrown of [null, undefined, "unavailable"]) {
    let attempted = false;
    await assert.rejects(runPlatformTasks("audit", [
      ["Instagram", () => { throw thrown; }],
      ["TikTok", async () => { attempted = true; }],
    ], () => {}), AggregateError);
    assert.equal(attempted, true);
  }
});
test("only the exact unique available service is selected", () => {
  assert.equal(selectBufferChannel([healthy, { ...healthy, service: "tiktok" }], "instagram", 1), healthy);
});
for (const [name, channels, expected] of [
  ["missing", [], /matching=0, disconnected=0, locked=0/],
  ["different service", [{ ...healthy, service: "tiktok" }], /matching=0/],
  ["disconnected", [{ ...healthy, isDisconnected: true }], /matching=1, disconnected=1, locked=0/],
  ["locked", [{ ...healthy, isLocked: true }], /matching=1, disconnected=0, locked=1/],
  ["both flags", [{ ...healthy, isLocked: true, isDisconnected: true }], /matching=1, disconnected=1, locked=1/],
  ["ambiguous", [healthy, { ...healthy, id: "private-second" }], /found 2/],
]) {
  test(`channel diagnostics: ${name}`, () => {
    assert.throws(() => selectBufferChannel(channels, "instagram", channels.length ? 1 : 0), error => {
      assert.match(error.message, expected);
      assert.doesNotMatch(error.message, /private-/);
      return true;
    });
  });
}

// Exercise the real CLI, including queue coverage/deduplication and today's audits.
for (const command of ["schedule", "audit"]) {
  for (const failures of [[], ["instagram"], ["tiktok"], ["instagram", "tiktok"]]) {
    test(`${command} CLI attempts both platforms with ${failures.join(",") || "no"} outage`, () => {
      const result = spawnSync(process.execPath, [
        "--import", fileURLToPath(new URL("./test-fixtures/buffer-channel-outage.mjs", import.meta.url)),
        fileURLToPath(new URL("./cli.mjs", import.meta.url)), command,
        ...(command === "schedule" ? ["--start-date", "2026-10-06", "--days", "1", "--media-root", "https://example.invalid/test"] : []),
      ], { encoding: "utf8", timeout: 15_000, env: { ...process.env, BUFFER_API_KEY: "offline-test-only", TEST_FAILED_PLATFORMS: failures.join(",") } });
      assert.ifError(result.error);
      assert.equal(result.status, failures.length ? 1 : 0, result.stderr);
      for (const service of ["instagram", "tiktok"]) {
        const label = service === "instagram" ? "Instagram" : "TikTok";
        if (failures.includes(service)) {
          assert.ok(result.stderr.includes(`${label} ${command} failed:`), result.stderr);
          assert.match(result.stderr, /disconnected=1/);
        } else if (command === "schedule") {
          assert.match(result.stdout, service === "instagram" ? /Buffer queue check complete: 2 occupied, 0 created/ : /TikTok queue check complete: 2 occupied, 0 created/);
        } else {
          assert.match(result.stdout, service === "instagram" ? /Audit: 2026-10-06 reel is scheduled/ : /TikTok audit: 2026-10-06 daily is scheduled/);
        }
      }
      assert.doesNotMatch(result.stderr, /Unexpected (Buffer operation|external request)/);
    });
  }
}

test("workflow audits after schedule failure but not failed media publication or cancellation", async () => {
  const workflow = await readFile(new URL("../.github/workflows/daily-social.yml", import.meta.url), "utf8");
  assert.match(workflow, /name: Publish immutable media files\s+id: publish_media/);
  assert.match(workflow, /name: Verify both platforms even after a scheduling failure\s+if: \$\{\{ !cancelled\(\) && steps\.publish_media\.outcome == 'success' \}\}/);
  assert.doesNotMatch(workflow, /continue-on-error:\s*true/);
});
