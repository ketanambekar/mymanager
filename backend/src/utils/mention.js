function extractMentions(text) {
  if (!text) return [];
  const matches = String(text).match(/@([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})/g) || [];
  return matches.map((m) => m.slice(1).toLowerCase());
}

module.exports = { extractMentions };
