function toMilliseconds(exp) {
  const match = String(exp).match(/^(\d+)([mhd])$/i);
  if (!match) return 15 * 60 * 1000;
  const value = Number(match[1]);
  const unit = match[2].toLowerCase();
  if (unit === 'm') return value * 60 * 1000;
  if (unit === 'h') return value * 60 * 60 * 1000;
  return value * 24 * 60 * 60 * 1000;
}

module.exports = { toMilliseconds };
