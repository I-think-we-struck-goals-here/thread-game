// Keep platform failures visible without withholding work from the other queue.
export async function runPlatformTasks(operation, tasks, report = console.error) {
  const failures = [];
  for (const [platform, task] of tasks) {
    try {
      await task();
    } catch (error) {
      const message = `${platform} ${operation} failed: ${error?.message || String(error)}`;
      report(message);
      failures.push(new Error(message));
    }
  }
  if (failures.length) {
    throw new AggregateError(failures, `${operation} failed for ${failures.length} platform(s); all platforms were attempted.`);
  }
}

export function selectBufferChannel(channels, service, organizationCount) {
  const matches = channels.filter(channel => channel.service === service);
  const available = matches.filter(channel => !channel.isDisconnected && !channel.isLocked);
  if (available.length !== 1) {
    // Counts only: never put account/channel identities or credentials in public logs.
    const disconnected = matches.filter(channel => channel.isDisconnected).length;
    const locked = matches.filter(channel => channel.isLocked).length;
    throw new Error(
      `Expected one available ${service} channel; found ${available.length}. ` +
      `Buffer channel status: organizations=${organizationCount}, channels=${channels.length}, ` +
      `matching=${matches.length}, disconnected=${disconnected}, locked=${locked}. ` +
      `Check the ${service} connection and channel access in Buffer; no channel was selected.`,
    );
  }
  return available[0];
}
