// Offline CLI integration fixture. Unknown calls and ALL mutations fail closed.
const NativeDate = Date;
globalThis.Date = class extends NativeDate {
  constructor(...args) { super(...(args.length ? args : ["2026-10-06T12:00:00Z"])); }
  static now() { return NativeDate.parse("2026-10-06T12:00:00Z"); }
};

const failed = (process.env.TEST_FAILED_PLATFORMS || "").split(",");
const channels = ["instagram", "tiktok"].map(service => ({
  id: service, service, isDisconnected: failed.includes(service), isLocked: false,
}));
const video = [{ mimeType: "video/mp4" }];
const photos = Array.from({ length: 7 }, () => ({ mimeType: "image/png", image: { altText: "Test clue" } }));
const posts = {
  instagram: [
    { id: "ig1", dueAt: "2026-10-06T09:05:00Z", text: "Thread #232 🧵\nTest", assets: photos },
    { id: "ig2", dueAt: "2026-10-06T17:30:00Z", text: "Test #DailyThread", assets: video },
  ],
  tiktok: [
    { id: "tt1", dueAt: "2026-10-06T11:30:00Z", text: "Test #DailyThreadArchive", assets: photos },
    { id: "tt2", dueAt: "2026-10-06T17:30:00Z", text: "Test #DailyThreadToday", assets: video },
  ],
};

globalThis.fetch = async (url, options) => {
  if (url !== "https://api.buffer.com") throw new Error("Unexpected external request in offline test");
  const { query } = JSON.parse(options.body);
  let data;
  if (/^query SocialAutomationAccount/.test(query)) {
    data = { account: { organizations: [{ id: "test-org" }] } };
  } else if (/^query SocialAutomationChannels/.test(query)) {
    data = { channels };
  } else if (/^query SocialAutomationPosts/.test(query)) {
    const service = /channelIds: \["(instagram|tiktok)"\]/.exec(query)?.[1];
    if (!service) throw new Error("Unknown test channel");
    const statuses = /status: \[([^\]]+)\]/.exec(query)?.[1].split(/,\s*/);
    const nodes = statuses?.includes("scheduled") ? posts[service] : [];
    data = { posts: { edges: nodes.map(node => ({ node: { ...node, status: "scheduled" } })) } };
  } else {
    throw new Error("Unexpected Buffer operation; test never permits mutations");
  }
  return { ok: true, json: async () => ({ data }) };
};
