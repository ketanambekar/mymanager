import { PROJECT_COLOR_OPTIONS } from "./constants/project_color_options.js";

export function hslToHex(hue, saturation, lightness) {
  const chroma = (1 - Math.abs(2 * lightness - 1)) * saturation;
  const huePart = hue / 60;
  const secondary = chroma * (1 - Math.abs((huePart % 2) - 1));
  let channels;

  if (huePart < 1) channels = [chroma, secondary, 0];
  else if (huePart < 2) channels = [secondary, chroma, 0];
  else if (huePart < 3) channels = [0, chroma, secondary];
  else if (huePart < 4) channels = [0, secondary, chroma];
  else if (huePart < 5) channels = [secondary, 0, chroma];
  else channels = [chroma, 0, secondary];

  const offset = lightness - chroma / 2;
  return `#${channels.map((channel) => Math.round((channel + offset) * 255).toString(16).padStart(2, "0")).join("").toUpperCase()}`;
}

export function getAvailableProjectColorOptions(projects, currentProject = null) {
  const used = new Set(projects.filter((project) => project.id !== currentProject?.id).map((project) => project.color?.toLowerCase()));
  const ownColor = currentProject?.color?.toLowerCase();
  const ownOption = ownColor && (PROJECT_COLOR_OPTIONS.find((option) => option.color.toLowerCase() === ownColor)
    ?? { id: "current", label: "Current color", color: currentProject.color });
  const options = PROJECT_COLOR_OPTIONS.filter((option) => !used.has(option.color.toLowerCase()) && option.color.toLowerCase() !== ownColor);
  if (ownOption) options.unshift(ownOption);

  for (let attempt = 0; options.length < 9; attempt += 1) {
    const hue = (attempt * 137.508) % 360;
    if (hue >= 65 && hue <= 165) continue;
    const color = hslToHex(hue, 0.62, 0.52);
    if (used.has(color.toLowerCase()) || options.some((option) => option.color.toLowerCase() === color.toLowerCase())) continue;
    options.push({ id: `generated-${attempt}`, label: `Color ${attempt + 1}`, color });
  }

  return options.slice(0, 9);
}

export function resolveProjectColor(projectId, projects, seenProjectIds = new Set()) {
  const project = projects.find((candidate) => candidate.id === projectId);
  if (!project) return null;
  if (seenProjectIds.has(project.id)) return project.color;

  const parentProject = projects.find((candidate) => candidate.id === project.parentProjectId);
  if (!parentProject) return project.color;

  const nextSeenProjectIds = new Set(seenProjectIds);
  nextSeenProjectIds.add(project.id);
  const parentColor = resolveProjectColor(parentProject.id, projects, nextSeenProjectIds);
  return parentColor
    ? `color-mix(in srgb, ${project.color} 72%, ${parentColor} 28%)`
    : project.color;
}