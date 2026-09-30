import { useEffect, useRef, useState } from "react";
import { Check, ChevronRight, ClockAlert, ListChecks, Pencil, Plus, Repeat2, Trash2, X } from "lucide-react";
import { getRecurrenceLabel, localDateString } from "@/features/dashboard/task_recurrence.js";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import "./task_row.css";

function formatDate(dateString) {
  if (!dateString) return "No due date";
  const date = new Date(`${dateString}T00:00:00`);
  return new Intl.DateTimeFormat("en", { month: "short", day: "numeric" }).format(date);
}

export default function TaskRow({ task, projectName, projectColor, onToggle, onAddSubtask, onToggleSubtask, onEditTask, onEditSubtask, onDeleteTask, isPending = false }) {
  const [subtaskTitle, setSubtaskTitle] = useState("");
  const [editingSubtaskId, setEditingSubtaskId] = useState(null);
  const [editingSubtaskTitle, setEditingSubtaskTitle] = useState("");
  const [isSubtaskPanelOpen, setIsSubtaskPanelOpen] = useState(false);
  const subtaskDetailsRef = useRef(null);
  const subtasks = task.subtasks ?? [];
  const completedSubtaskCount = subtasks.filter((subtask) => subtask.completed).length;
  const recurrenceLabel = getRecurrenceLabel(task.recurrence);
  const isOverdue = !task.completed && Boolean(task.dueDate) && task.dueDate < localDateString();

  useEffect(() => {
    if (!isSubtaskPanelOpen) return undefined;

    function closeSubtasks(event) {
      const details = subtaskDetailsRef.current;
      if (details?.open && !details.contains(event.target)) details.open = false;
    }

    function handleEscape(event) {
      if (event.key !== "Escape") return;
      const details = subtaskDetailsRef.current;
      if (!details?.open) return;
      details.open = false;
      details.querySelector("summary")?.focus();
    }

    document.addEventListener("pointerdown", closeSubtasks);
    document.addEventListener("keydown", handleEscape);
    return () => {
      document.removeEventListener("pointerdown", closeSubtasks);
      document.removeEventListener("keydown", handleEscape);
    };
  }, [isSubtaskPanelOpen]);

  async function handleAddSubtask(event) {
    event.preventDefault();
    if (await onAddSubtask(task.id, subtaskTitle)) setSubtaskTitle("");
  }

  async function handleEditSubtask(event) {
    event.preventDefault();
    if (await onEditSubtask(task.id, editingSubtaskId, editingSubtaskTitle)) setEditingSubtaskId(null);
  }

  return (
    <li className={`task-row${task.completed ? " is-complete" : ""}${isOverdue ? " is-overdue" : ""}`} style={{ "--project-color": projectColor(task.projectId) }}>
      <div className="task-row-main">
        <AppIconButton
          aria-label={`${task.completed ? "Mark as to do" : "Complete"}: ${task.title}`}
          aria-pressed={task.completed}
          className="task-check"
          disabled={isPending}
          onClick={() => onToggle(task.id)}
          variant="task-check"
        >
          {task.completed && <Check aria-hidden="true" size={13} strokeWidth={2.5} />}
        </AppIconButton>
        <span className="task-copy">
          <span className="task-title">{task.title}</span>
          <span className="task-project">{projectName(task.projectId)}</span>
          {recurrenceLabel && <span className="task-recurrence"><Repeat2 aria-hidden="true" size={12} />{recurrenceLabel}</span>}
        </span>
        <time className="task-date" dateTime={task.dueDate || undefined}>
          {isOverdue && <span className="task-overdue-label"><ClockAlert aria-hidden="true" size={12} />Overdue</span>}
          {isOverdue && " "}{formatDate(task.dueDate)}
        </time>
        <div className="task-row-actions">
          <AppIconButton aria-label={`Edit task: ${task.title}`} disabled={isPending} onClick={() => onEditTask(task.id)} title="Edit task" variant="task-action"><Pencil aria-hidden="true" size={14} /></AppIconButton>
          <AppIconButton aria-label={`Delete task: ${task.title}`} disabled={isPending} onClick={() => onDeleteTask(task.id)} title="Delete task" variant="task-action"><Trash2 aria-hidden="true" size={14} /></AppIconButton>
        </div>
      </div>
      <details className="task-subtasks" onToggle={(event) => setIsSubtaskPanelOpen(event.currentTarget.open)} ref={subtaskDetailsRef}>
        <summary>
          <ListChecks aria-hidden="true" className="subtask-list-icon" size={14} />
          <span>{subtasks.length ? "Subtasks" : "Add a subtask"}</span>
          {subtasks.length > 0 && <span className="subtask-count">{completedSubtaskCount}/{subtasks.length}</span>}
          <ChevronRight aria-hidden="true" className="subtask-chevron" size={14} />
        </summary>
        <div className="task-subtasks-body">
          {subtasks.length > 0 && (
            <ul className="subtask-list">
              {subtasks.map((subtask) => (
                <li className={subtask.completed ? "subtask-item is-complete" : "subtask-item"} key={subtask.id}>
                  <AppIconButton
                    aria-label={`${subtask.completed ? "Reopen" : "Complete"} subtask: ${subtask.title}`}
                    aria-pressed={subtask.completed}
                    className="task-check subtask-check"
                    disabled={isPending}
                    onClick={() => onToggleSubtask(task.id, subtask.id)}
                    variant="task-check"
                  >
                    {subtask.completed && <Check aria-hidden="true" size={11} strokeWidth={2.5} />}
                  </AppIconButton>
                  {editingSubtaskId === subtask.id ? (
                    <form className="subtask-edit-form" noValidate onSubmit={handleEditSubtask}>
                      <label className="visually-hidden" htmlFor={`edit-subtask-${subtask.id}`}>Edit subtask</label>
                      <AppInput autoFocus id={`edit-subtask-${subtask.id}`} maxLength={120} onChange={(event) => setEditingSubtaskTitle(event.target.value)} onKeyDown={(event) => {
                        if (event.key === "Escape") {
                          event.stopPropagation();
                          setEditingSubtaskId(null);
                        }
                      }} required value={editingSubtaskTitle} />
                      <AppIconButton aria-label="Save subtask" disabled={isPending} title="Save subtask" type="submit" variant="task-action"><Check aria-hidden="true" size={14} /></AppIconButton>
                      <AppIconButton aria-label="Cancel editing subtask" onClick={() => setEditingSubtaskId(null)} title="Cancel edit" variant="task-action"><X aria-hidden="true" size={14} /></AppIconButton>
                    </form>
                  ) : (
                    <>
                      <span>{subtask.title}</span>
                      <div className="subtask-actions">
                        <AppIconButton aria-label={`Edit subtask: ${subtask.title}`} disabled={isPending} onClick={() => { setEditingSubtaskId(subtask.id); setEditingSubtaskTitle(subtask.title); }} title="Edit subtask" variant="task-action"><Pencil aria-hidden="true" size={13} /></AppIconButton>
                        <AppIconButton aria-label={`Delete subtask: ${subtask.title}`} disabled={isPending} onClick={() => onDeleteTask(task.id, subtask.id)} title="Delete subtask" variant="task-action"><Trash2 aria-hidden="true" size={13} /></AppIconButton>
                      </div>
                    </>
                  )}
                </li>
              ))}
            </ul>
          )}
          <form className="subtask-form" onSubmit={handleAddSubtask}>
            <label className="visually-hidden" htmlFor={`subtask-title-${task.id}`}>New subtask for {task.title}</label>
            <AppInput autoComplete="off" id={`subtask-title-${task.id}`} maxLength={120} onChange={(event) => setSubtaskTitle(event.target.value)} placeholder="Add a subtask" value={subtaskTitle} />
            <AppButton className="subtask-add-button" disabled={isPending} leadingIcon={<Plus size={14} />} type="submit" variant="secondary">Add</AppButton>
          </form>
        </div>
      </details>
    </li>
  );
}
