import { useEffect, useRef, useState } from "react";
import { Check, X } from "lucide-react";
import { getAvailableProjectColorOptions } from "@/features/dashboard/project_color_utils.js";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import AppSelect from "@/shared/widgets/app_select/app_select.jsx";
import "./create_project_dialog.css";

function getNestedProjectIds(projects, projectId) {
  return projects
    .filter((candidate) => candidate.parentProjectId === projectId)
    .flatMap((candidate) => [candidate.id, ...getNestedProjectIds(projects, candidate.id)]);
}

export default function CreateProjectDialog({ isOpen, onClose, onCreate, projects, project = null, isPending = false }) {
  const dialogRef = useRef(null);
  const [name, setName] = useState("");
  const [parentProjectId, setParentProjectId] = useState("");
  const [customColor, setCustomColor] = useState("#7383B5");
  const [color, setColor] = useState(() => getAvailableProjectColorOptions(projects)[0].color);
  const availableColorOptions = getAvailableProjectColorOptions(projects, project);
  const colorTaken = projects.some((candidate) => candidate.id !== project?.id && candidate.color?.toLowerCase() === color.toLowerCase());
  const invalidParentIds = new Set(project ? [project.id, ...getNestedProjectIds(projects, project.id)] : []);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen && !dialog.open) dialog.showModal();
    if (!isOpen && dialog.open) dialog.close();
    if (isOpen) {
      const initialColor = project?.color ?? getAvailableProjectColorOptions(projects)[0].color;
      setName(project?.name ?? "");
      setParentProjectId(project?.parentProjectId ?? "");
      setColor(initialColor);
      if (!availableColorOptions.some((option) => option.color.toLowerCase() === initialColor.toLowerCase())) setCustomColor(initialColor);
    }
  }, [isOpen, project]);

  async function handleSubmit(event) {
    event.preventDefault();
    if (await onCreate({ name, parentProjectId, color })) {
      setName("");
      setParentProjectId("");
    }
  }

  return (
    <dialog className="project-dialog" onClose={onClose} ref={dialogRef}>
      <form noValidate onSubmit={handleSubmit}>
        <div className="dialog-heading">
          <div>
            <p className="section-kicker">{project ? "EDIT PROJECT" : "NEW PROJECT"}</p>
            <h2>{project ? "Edit project" : "Create a project"}</h2>
          </div>
          <AppIconButton aria-label="Close dialog" onClick={onClose} variant="dialog-close"><X aria-hidden="true" size={17} /></AppIconButton>
        </div>
        <label className="field-label" htmlFor="project-name">Project name</label>
        <AppInput autoFocus id="project-name" maxLength={60} onChange={(event) => setName(event.target.value)} placeholder="What are you building?" required value={name} />
        <label className="field-label" htmlFor="project-parent">
          Parent project
          <AppSelect id="project-parent" onChange={(event) => setParentProjectId(event.target.value)} value={parentProjectId}>
            <option value="">No parent project</option>
            {projects.map((candidate) => <option disabled={invalidParentIds.has(candidate.id)} key={candidate.id} value={candidate.id}>{candidate.parentProjectId ? `Subproject: ${candidate.name}` : candidate.name}</option>)}
          </AppSelect>
        </label>
        <fieldset className="project-color-field">
          <legend>Project color</legend>
          <div className="project-color-options">
            {availableColorOptions.map((option) => (
              <label className="project-color-option" key={option.id} title={option.label}>
                <input checked={color.toLowerCase() === option.color.toLowerCase()} name="project-color" onChange={() => setColor(option.color)} type="radio" value={option.color} />
                <span aria-hidden="true" className="project-color-swatch" style={{ "--swatch-color": option.color }}><Check size={14} strokeWidth={2.5} /></span>
                <span className="visually-hidden">{option.label}</span>
              </label>
            ))}
            <label className={color.toLowerCase() === customColor.toLowerCase() ? "project-color-option project-color-option--custom selected" : "project-color-option project-color-option--custom"} title="Custom color">
              <input aria-label="Choose custom project color" checked={!availableColorOptions.some((option) => option.color.toLowerCase() === color.toLowerCase())} onChange={(event) => { setCustomColor(event.target.value.toUpperCase()); setColor(event.target.value.toUpperCase()); }} type="color" value={customColor} />
              <span aria-hidden="true" className="project-color-swatch" style={{ "--swatch-color": customColor }}><Check size={14} strokeWidth={2.5} /></span>
              <span className="visually-hidden">Custom color</span>
            </label>
          </div>
          {colorTaken && <p className="project-color-error" role="alert">That color is already used. Choose another one.</p>}
        </fieldset>
        <div className="dialog-actions">
          <AppButton disabled={isPending} onClick={onClose} variant="secondary">Cancel</AppButton>
          <AppButton disabled={isPending} type="submit">{isPending ? "Saving..." : project ? "Save changes" : "Create project"}</AppButton>
        </div>
      </form>
    </dialog>
  );
}