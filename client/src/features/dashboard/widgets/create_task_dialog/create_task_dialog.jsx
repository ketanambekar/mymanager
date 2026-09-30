import { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import AppSelect from "@/shared/widgets/app_select/app_select.jsx";
import { CUSTOM_FREQUENCY_UNITS, TASK_FREQUENCIES, TASK_FREQUENCY_OPTIONS } from "@/features/dashboard/constants/task_frequencies.js";
import { localDateString } from "@/features/dashboard/task_recurrence.js";
import "./create_task_dialog.css";

export default function CreateTaskDialog({ isOpen, onClose, onCreate, projects, defaultProjectId, task = null, isPending = false, today }) {
  const dialogRef = useRef(null);
  const [title, setTitle] = useState("");
  const [projectId, setProjectId] = useState(defaultProjectId || projects[0]?.id || "");
  const [dueDate, setDueDate] = useState(localDateString);
  const [frequency, setFrequency] = useState(TASK_FREQUENCIES.ONE_TIME);
  const [interval, setInterval] = useState(1);
  const [unit, setUnit] = useState("day");

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen && !dialog.open) dialog.showModal();
    if (!isOpen && dialog.open) dialog.close();
    if (isOpen) {
      const selectedProject = projects.find((project) => project.id === defaultProjectId);
      setTitle(task?.title ?? "");
      setDueDate(task ? task.dueDate ?? "" : today || localDateString());
      setFrequency(task?.recurrence?.frequency ?? TASK_FREQUENCIES.ONE_TIME);
      setInterval(task?.recurrence?.interval ?? 1);
      setUnit(task?.recurrence?.unit ?? "day");
      setProjectId(task ? task.projectId : selectedProject?.id ?? projects[0]?.id ?? "");
    }
  }, [defaultProjectId, isOpen, projects, task, today]);

  async function handleSubmit(event) {
    event.preventDefault();
    const created = await onCreate({ title, projectId, dueDate, recurrence: { frequency, interval, unit } });
    if (created) {
      setTitle("");
      setDueDate("");
    }
  }

  return (
    <dialog className="task-dialog" onClose={onClose} ref={dialogRef}>
      <form noValidate onSubmit={handleSubmit}>
        <div className="dialog-heading">
          <div>
            <p className="section-kicker">{task ? "EDIT TASK" : "NEW TASK"}</p>
            <h2>{task ? "Edit task" : "Add a task"}</h2>
          </div>
          <AppIconButton aria-label="Close dialog" onClick={onClose} variant="dialog-close"><X aria-hidden="true" size={17} /></AppIconButton>
        </div>
        <label className="field-label" htmlFor="task-title">Task name</label>
        <AppInput autoFocus id="task-title" maxLength={120} onChange={(event) => setTitle(event.target.value)} placeholder="What needs to get done?" required value={title} />
        <div className="dialog-fields">
          <label className="field-label" htmlFor="task-project">
            Project
            <AppSelect id="task-project" onChange={(event) => setProjectId(event.target.value)} value={projectId}>
              {projects.map((project) => <option key={project.id} value={project.id}>{project.parentProjectId ? `Subproject: ${project.name}` : project.name}</option>)}
              <option value="">General</option>
            </AppSelect>
          </label>
          <label className="field-label" htmlFor="task-due-date">
            {frequency === TASK_FREQUENCIES.ONE_TIME ? "Due date" : "First due date"}
            <AppInput id="task-due-date" onChange={(event) => setDueDate(event.target.value)} type="date" value={dueDate} />
          </label>
        </div>
        <label className="field-label" htmlFor="task-frequency">
          Frequency
          <AppSelect id="task-frequency" onChange={(event) => setFrequency(event.target.value)} value={frequency}>
            {TASK_FREQUENCY_OPTIONS.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
          </AppSelect>
        </label>
        {frequency === TASK_FREQUENCIES.CUSTOM && (
          <div className="task-custom-frequency">
            <label className="field-label" htmlFor="task-interval">Every
              <AppInput id="task-interval" max={365} min={1} onChange={(event) => setInterval(event.target.value)} type="number" value={interval} />
            </label>
            <label className="field-label" htmlFor="task-interval-unit">Unit
              <AppSelect id="task-interval-unit" onChange={(event) => setUnit(event.target.value)} value={unit}>
                {CUSTOM_FREQUENCY_UNITS.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
              </AppSelect>
            </label>
          </div>
        )}
        <div className="dialog-actions">
          <AppButton disabled={isPending} onClick={onClose} variant="secondary">Cancel</AppButton>
          <AppButton disabled={isPending} type="submit">{isPending ? "Saving..." : task ? "Save changes" : "Create task"}</AppButton>
        </div>
      </form>
    </dialog>
  );
}
