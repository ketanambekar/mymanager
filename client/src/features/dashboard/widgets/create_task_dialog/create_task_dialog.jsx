import { useEffect, useRef, useState } from "react";
import { Check, ListChecks, Pencil, Plus, Trash2, X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import AppSelect from "@/shared/widgets/app_select/app_select.jsx";
import { CUSTOM_FREQUENCY_UNITS, TASK_FREQUENCIES, TASK_FREQUENCY_OPTIONS } from "@/features/dashboard/constants/task_frequencies.js";
import { localDateString } from "@/features/dashboard/task_recurrence.js";
import { getTaskStatus, TASK_STATUSES } from "@/features/dashboard/task_status.js";
import "./create_task_dialog.css";

export default function CreateTaskDialog({
  isOpen,
  onClose,
  onCreate,
  projects,
  defaultProjectId,
  task = null,
  isPending = false,
  today,
  onAddSubtask,
  onToggleSubtask,
  onEditSubtask,
  onDeleteSubtask,
}) {
  const dialogRef = useRef(null);
  const [title, setTitle] = useState("");
  const [projectId, setProjectId] = useState(defaultProjectId || projects[0]?.id || "");
  const [dueDate, setDueDate] = useState(localDateString);
  const [frequency, setFrequency] = useState(TASK_FREQUENCIES.ONE_TIME);
  const [interval, setInterval] = useState(1);
  const [unit, setUnit] = useState("day");
  const [newSubtaskTitle, setNewSubtaskTitle] = useState("");
  const [editingSubtaskId, setEditingSubtaskId] = useState(null);
  const [editingSubtaskTitle, setEditingSubtaskTitle] = useState("");
  const canChangeSubtasks = task && ![TASK_STATUSES.SKIPPED, TASK_STATUSES.MISSED].includes(getTaskStatus(task));

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
      setNewSubtaskTitle("");
      setEditingSubtaskId(null);
      setEditingSubtaskTitle("");
    }
  }, [defaultProjectId, isOpen, task?.id]);

  async function handleSubmit(event) {
    event.preventDefault();
    await onCreate({ title, projectId, dueDate, recurrence: { frequency, interval, unit } });
  }

  async function handleAddSubtask(event) {
    event.preventDefault();
    if (!task?.id || !newSubtaskTitle.trim()) return;
    if (await onAddSubtask(task.id, newSubtaskTitle)) setNewSubtaskTitle("");
  }

  async function handleEditSubtask(event, subtaskId) {
    event.preventDefault();
    if (await onEditSubtask(task.id, subtaskId, editingSubtaskTitle)) {
      setEditingSubtaskId(null);
      setEditingSubtaskTitle("");
    }
  }

  return (
    <dialog aria-labelledby="task-dialog-title" className="task-dialog" onClose={onClose} ref={dialogRef}>
      <form noValidate onSubmit={handleSubmit}>
        <div className="dialog-heading">
          <div>
            <p className="section-kicker">{task ? "EDIT TASK" : "NEW TASK"}</p>
            <h2 id="task-dialog-title">{task ? "Edit task" : "Add a task"}</h2>
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
          <AppButton disabled={isPending} onClick={onClose} variant="secondary">{task ? "Done" : "Cancel"}</AppButton>
          <AppButton disabled={isPending} type="submit">{isPending ? "Saving..." : task ? "Save changes" : "Create task"}</AppButton>
        </div>
      </form>
      <section aria-labelledby="task-subtasks-heading" className="task-dialog-subtasks">
        <div className="task-dialog-subtasks-heading">
          <h3 id="task-subtasks-heading"><ListChecks aria-hidden="true" size={16} />Subtasks</h3>
          {task && <span>{task.subtasks?.length ?? 0}</span>}
        </div>
        {task ? (
          <>
            {!canChangeSubtasks && <p className="task-dialog-subtask-empty">Reopen this {getTaskStatus(task) === TASK_STATUSES.SKIPPED ? "skipped" : "missed"} task to change subtask completion or add subtasks.</p>}
            {task.subtasks?.length ? (
              <ul className="task-dialog-subtask-list">
                {task.subtasks.map((subtask) => (
                  <li className={subtask.completed ? "task-dialog-subtask is-complete" : "task-dialog-subtask"} key={subtask.id}>
                    {canChangeSubtasks && <AppIconButton
                      aria-label={`${subtask.completed ? "Reopen" : "Complete"} subtask: ${subtask.title}`}
                      aria-pressed={subtask.completed}
                      className="task-dialog-subtask-check"
                      disabled={isPending}
                      onClick={() => onToggleSubtask(task.id, subtask.id)}
                      variant="task-check"
                    >
                      {subtask.completed && <Check aria-hidden="true" size={11} strokeWidth={2.5} />}
                    </AppIconButton>}
                    {editingSubtaskId === subtask.id ? (
                      <form className="task-dialog-subtask-edit" noValidate onSubmit={(event) => handleEditSubtask(event, subtask.id)}>
                        <label className="visually-hidden" htmlFor={`dialog-edit-subtask-${subtask.id}`}>Edit subtask</label>
                        <AppInput
                          autoFocus
                          id={`dialog-edit-subtask-${subtask.id}`}
                          maxLength={120}
                          onChange={(event) => setEditingSubtaskTitle(event.target.value)}
                          onKeyDown={(event) => {
                            if (event.key === "Escape") {
                              event.stopPropagation();
                              setEditingSubtaskId(null);
                            }
                          }}
                          required
                          value={editingSubtaskTitle}
                        />
                        <AppIconButton aria-label="Save subtask" disabled={isPending} title="Save subtask" type="submit" variant="task-action"><Check aria-hidden="true" size={14} /></AppIconButton>
                        <AppIconButton aria-label="Cancel editing subtask" disabled={isPending} onClick={() => setEditingSubtaskId(null)} title="Cancel edit" variant="task-action"><X aria-hidden="true" size={14} /></AppIconButton>
                      </form>
                    ) : (
                      <>
                        <span className="task-dialog-subtask-title">{subtask.title}</span>
                        <div className="task-dialog-subtask-actions">
                          <AppIconButton
                            aria-label={`Edit subtask: ${subtask.title}`}
                            disabled={isPending}
                            onClick={() => {
                              setEditingSubtaskId(subtask.id);
                              setEditingSubtaskTitle(subtask.title);
                            }}
                            title="Edit subtask"
                            variant="task-action"
                          >
                            <Pencil aria-hidden="true" size={13} />
                          </AppIconButton>
                          <AppIconButton
                            aria-label={`Delete subtask: ${subtask.title}`}
                            disabled={isPending}
                            onClick={() => onDeleteSubtask(task.id, subtask.id)}
                            title="Delete subtask"
                            variant="task-action"
                          >
                            <Trash2 aria-hidden="true" size={13} />
                          </AppIconButton>
                        </div>
                      </>
                    )}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="task-dialog-subtask-empty">No subtasks yet.</p>
            )}
            {canChangeSubtasks && <form className="task-dialog-subtask-form" onSubmit={handleAddSubtask}>
              <label className="visually-hidden" htmlFor="task-dialog-new-subtask">New subtask</label>
              <AppInput
                autoComplete="off"
                id="task-dialog-new-subtask"
                maxLength={120}
                onChange={(event) => setNewSubtaskTitle(event.target.value)}
                placeholder="Add a subtask"
                value={newSubtaskTitle}
              />
              <AppButton disabled={isPending || !newSubtaskTitle.trim()} leadingIcon={<Plus aria-hidden="true" size={14} />} type="submit" variant="secondary">Add</AppButton>
            </form>}
          </>
        ) : (
          <p className="task-dialog-subtask-empty">Create the task first to add and manage its subtasks here.</p>
        )}
      </section>
    </dialog>
  );
}
