let lastSeen = null;

function update() {
  lastSeen = Date.now();
}

function getStatus(maxAgeMs = 30000) {
  if (!lastSeen) {
    return { connected: false, lastSeen: null, ageMs: null };
  }
  const ageMs = Date.now() - lastSeen;
  const connected = ageMs <= maxAgeMs;
  return { connected, lastSeen, ageMs };
}

module.exports = { update, getStatus };

