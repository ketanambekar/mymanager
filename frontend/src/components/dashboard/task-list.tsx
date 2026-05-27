import {
  ArrowRight,
  CheckCircle2,
  Clock3,
  Eye,
  ListTodo,
  Pause,
  Pencil,
  Play,
  Plus,
  RotateCcw,
  Trash2,
  X,
} from "lucide-react";
import { ReactNode, useEffect, useMemo, useState } from "react";
import { TaskItem, TaskStatus } from "@/types/dashboard";
import { Badge } from "../ui/badge";
import { Card } from "../ui/card";

const statusBadgeClasses: Record<TaskStatus, string> = {
  ACTIVE: "border-emerald-500/40 bg-emerald-500/20 text-emerald-300",
  IN_PROGRESS: "border-orange-500/40 bg-orange-500/20 text-orange-300",
  COMPLETED: "border-sky-500/40 bg-sky-500/20 text-sky-300",
  HOLD: "border-zinc-500/40 bg-zinc-500/20 text-zinc-300",
  IN_REVIEW: "border-violet-500/40 bg-violet-500/20 text-violet-300",
  PENDING: "border-amber-500/40 bg-amber-500/20 text-amber-300",
};

const statusCardClasses: Record<TaskStatus, string> = {
  ACTIVE:
    "border-emerald-400/60 bg-gradient-to-br from-emerald-500/14 via-emerald-500/8 to-[var(--surface-muted)] hover:from-emerald-500/20 hover:via-emerald-500/12 shadow-[inset_0_1px_0_rgba(16,185,129,0.24)]",
  IN_PROGRESS:
    "border-orange-400/60 bg-gradient-to-br from-orange-500/15 via-orange-500/9 to-[var(--surface-muted)] hover:from-orange-500/20 hover:via-orange-500/13 shadow-[inset_0_1px_0_rgba(249,115,22,0.24)]",
  COMPLETED:
    "border-sky-400/60 bg-gradient-to-br from-sky-500/15 via-sky-500/10 to-[var(--surface-muted)] hover:from-sky-500/22 hover:via-sky-500/14 shadow-[inset_0_1px_0_rgba(14,165,233,0.24)]",
  HOLD:
    "border-zinc-400/60 bg-gradient-to-br from-zinc-500/16 via-zinc-500/10 to-[var(--surface-muted)] hover:from-zinc-500/22 hover:via-zinc-500/14 shadow-[inset_0_1px_0_rgba(161,161,170,0.2)]",
  IN_REVIEW:
    "border-violet-400/60 bg-gradient-to-br from-violet-500/15 via-violet-500/10 to-[var(--surface-muted)] hover:from-violet-500/21 hover:via-violet-500/14 shadow-[inset_0_1px_0_rgba(139,92,246,0.24)]",
  PENDING:
    "border-amber-400/60 bg-gradient-to-br from-amber-500/16 via-amber-500/10 to-[var(--surface-muted)] hover:from-amber-500/22 hover:via-amber-500/14 shadow-[inset_0_1px_0_rgba(245,158,11,0.24)]",
};

type TaskListProps = {
  tasks: TaskItem[];
  title?: string;
  disabled?: boolean;
  onStatusChange?: (taskId: number, status: TaskStatus) => void;
  onUpdateTask?: (taskId: number, values: { name?: string; description?: string | null; status?: TaskStatus }) => Promise<void>;
  onCreateSubTask?: (taskId: number, name: string) => Promise<void>;
  onUpdateSubTask?: (subTaskId: number, values: { name?: string; status?: TaskStatus }) => Promise<void>;
  onDeleteSubTask?: (subTaskId: number) => Promise<void>;
  headerAction?: ReactNode;
};

function getPrimaryAction(status: TaskStatus): { label: string; nextStatus: TaskStatus; icon: typeof Play } {
  switch (status) {
    case "PENDING":
      return { label: "Start Task", nextStatus: "ACTIVE", icon: Play };
    case "ACTIVE":
      return { label: "Move to In Progress", nextStatus: "IN_PROGRESS", icon: ArrowRight };
    case "IN_PROGRESS":
      return { label: "Send to Review", nextStatus: "IN_REVIEW", icon: ArrowRight };
    case "IN_REVIEW":
      return { label: "Approve Complete", nextStatus: "COMPLETED", icon: CheckCircle2 };
    case "HOLD":
      return { label: "Resume Task", nextStatus: "ACTIVE", icon: Play };
    case "COMPLETED":
      return { label: "Reopen", nextStatus: "ACTIVE", icon: RotateCcw };
    default:
      return { label: "Update", nextStatus: status, icon: ArrowRight };
  }
}

export function TaskList({
  tasks,
  title = "Task Queue",
  disabled = false,
  onStatusChange,
  onUpdateTask,
  onCreateSubTask,
  onUpdateSubTask,
  onDeleteSubTask,
  headerAction,
}: TaskListProps) {
  const [expandedTaskIds, setExpandedTaskIds] = useState<Record<number, boolean>>({});
  const [activeTaskForSubtasks, setActiveTaskForSubtasks] = useState<number | null>(null);
  const [newSubTaskName, setNewSubTaskName] = useState("");
  const [taskDraftName, setTaskDraftName] = useState("");
  const [taskDraftDescription, setTaskDraftDescription] = useState("");
  const [taskDraftStatus, setTaskDraftStatus] = useState<TaskStatus>("PENDING");
  const [editingSubTaskId, setEditingSubTaskId] = useState<number | null>(null);
  const [editingSubTaskName, setEditingSubTaskName] = useState("");
  const [isSubTaskActionRunning, setIsSubTaskActionRunning] = useState(false);
  const iconOnlyActionButtonClassName =
    "inline-flex h-7 w-7 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface)] px-0 text-[11px] font-semibold text-[var(--ink)] transition-colors hover:border-[var(--brand-orange)] hover:bg-[var(--surface-strong)] disabled:cursor-not-allowed disabled:opacity-45";

  const activeTask = useMemo(() => {
    if (!activeTaskForSubtasks) {
      return null;
    }

    return tasks.find((task) => task.id === activeTaskForSubtasks) ?? null;
  }, [activeTaskForSubtasks, tasks]);

  useEffect(() => {
    if (!activeTask) {
      setTaskDraftName("");
      setTaskDraftDescription("");
      setTaskDraftStatus("PENDING");
      return;
    }

    setTaskDraftName(activeTask.name);
    setTaskDraftDescription(activeTask.description ?? "");
    setTaskDraftStatus(activeTask.status);
  }, [activeTask]);

  async function handleSaveTaskDetails() {
    if (!activeTask || !onUpdateTask) {
      return;
    }

    const trimmedName = taskDraftName.trim();
    if (!trimmedName) {
      return;
    }

    setIsSubTaskActionRunning(true);
    try {
      await onUpdateTask(activeTask.id, {
        name: trimmedName,
        description: taskDraftDescription.trim() ? taskDraftDescription.trim() : null,
        status: taskDraftStatus,
      });
    } finally {
      setIsSubTaskActionRunning(false);
    }
  }

  async function handleAddSubTask() {
    if (!activeTask || !onCreateSubTask) {
      return;
    }

    const trimmedName = newSubTaskName.trim();
    if (!trimmedName) {
      return;
    }

    setIsSubTaskActionRunning(true);
    try {
      await onCreateSubTask(activeTask.id, trimmedName);
      setNewSubTaskName("");
    } finally {
      setIsSubTaskActionRunning(false);
    }
  }

  async function handleToggleSubTaskStatus(subTaskId: number, status: TaskStatus) {
    if (!onUpdateSubTask) {
      return;
    }

    const nextStatus: TaskStatus = status === "COMPLETED" ? "PENDING" : "COMPLETED";

    setIsSubTaskActionRunning(true);
    try {
      await onUpdateSubTask(subTaskId, { status: nextStatus });
    } finally {
      setIsSubTaskActionRunning(false);
    }
  }

  async function handleSaveSubTaskEdit() {
    if (!onUpdateSubTask || !editingSubTaskId) {
      return;
    }

    const trimmedName = editingSubTaskName.trim();
    if (!trimmedName) {
      return;
    }

    setIsSubTaskActionRunning(true);
    try {
      await onUpdateSubTask(editingSubTaskId, { name: trimmedName });
      setEditingSubTaskId(null);
      setEditingSubTaskName("");
    } finally {
      setIsSubTaskActionRunning(false);
    }
  }

  async function handleDeleteSubTask(subTaskId: number) {
    if (!onDeleteSubTask) {
      return;
    }

    setIsSubTaskActionRunning(true);
    try {
      await onDeleteSubTask(subTaskId);
      if (editingSubTaskId === subTaskId) {
        setEditingSubTaskId(null);
        setEditingSubTaskName("");
      }
    } finally {
      setIsSubTaskActionRunning(false);
    }
  }

  return (
    <Card className="h-full rounded-xl p-4">
      <div className="mb-2 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-base font-extrabold">{title}</h3>
        <div className="flex items-center gap-2">
          {headerAction}
          <Badge className="w-fit">{tasks.length} items</Badge>
        </div>
      </div>
      <p className="mb-3 text-xs leading-5 text-[var(--muted)]">Prioritize by status and due window. Fast triage, then execute.</p>

      {tasks.length === 0 ? (
        <div className="rounded-md border border-dashed border-[var(--border-strong)] bg-[var(--surface-muted)] p-4 text-sm text-[var(--muted)]">
          Queue is clear. Add a new task to keep momentum.
        </div>
      ) : null}

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-2">
        {tasks.map((task) => {
          const completedSubTaskCount = task.subTasks.filter((subtask) => subtask.status === "COMPLETED").length;

          return (
          <div
            key={task.id}
            className={`flex h-full w-full flex-col rounded-xl p-3.5 text-left transition-colors ${statusCardClasses[task.status]}`}
          >
            <div className="flex items-start justify-between gap-2">
              <p className="min-w-0 flex-1 text-sm font-semibold leading-5 text-[var(--ink)]">{task.name}</p>
              <Badge
                className={`inline-flex shrink-0 items-center gap-1 border text-[10px] uppercase tracking-[0.08em] ${statusBadgeClasses[task.status]}`}
              >
                {task.status.replace("_", " ")}
              </Badge>
            </div>

            {task.description ? (
              <div className="mt-1.5 text-xs leading-5 text-[var(--muted)]">
                <p>
                  {expandedTaskIds[task.id]
                    ? task.description
                    : task.description.length > 120
                      ? `${task.description.slice(0, 120)}...`
                      : task.description}
                </p>
                {task.description.length > 120 ? (
                  <button
                    type="button"
                    className="mt-1 font-semibold text-[var(--ink)] underline underline-offset-2"
                    onClick={() => setExpandedTaskIds((state) => ({ ...state, [task.id]: !state[task.id] }))}
                  >
                    {expandedTaskIds[task.id] ? "View less" : "View more"}
                  </button>
                ) : null}
              </div>
            ) : null}

            <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs">
              <span className="truncate text-[var(--muted)]">{task.projectName}</span>
              <span className="inline-flex items-center gap-1 text-[var(--muted)]">
                <Clock3 className="h-3.5 w-3.5" /> {task.dueText}
              </span>
              <button
                type="button"
                className="inline-flex items-center gap-1 rounded-full border border-[var(--border)] bg-[var(--surface)] px-2 py-0.5 text-[10px] text-[var(--muted)] hover:border-[var(--brand-orange)] hover:text-[var(--ink)]"
                title="Open task details"
                onClick={() => setActiveTaskForSubtasks(task.id)}
              >
                <Eye className="h-3.5 w-3.5" /> Details
              </button>
              {task.subTaskCount > 0 ? (
                <button
                  type="button"
                  className="inline-flex items-center gap-1 rounded-full border border-[var(--border)] bg-[var(--surface)] px-2 py-0.5 text-[10px] text-[var(--muted)] hover:border-[var(--brand-orange)] hover:text-[var(--ink)]"
                  title={`${completedSubTaskCount}/${task.subTaskCount} subtasks completed`}
                  onClick={() => setActiveTaskForSubtasks(task.id)}
                >
                  <ListTodo className="h-3.5 w-3.5" /> {completedSubTaskCount}/{task.subTaskCount}
                </button>
              ) : (
                <button
                  type="button"
                  className="inline-flex items-center gap-1 rounded-full border border-dashed border-[var(--border)] bg-[var(--surface)] px-2 py-0.5 text-[10px] text-[var(--muted)] hover:border-[var(--brand-orange)] hover:text-[var(--ink)]"
                  title="Add first subtask"
                  onClick={() => setActiveTaskForSubtasks(task.id)}
                >
                  <Plus className="h-3.5 w-3.5" /> Add subtask
                </button>
              )}
            </div>

            {onStatusChange ? (
              <div className="mt-3 flex w-full flex-wrap items-center gap-2">
                {(() => {
                  const primaryAction = getPrimaryAction(task.status);
                  const PrimaryIcon = primaryAction.icon;

                  return (
                    <button
                      type="button"
                      disabled={disabled || primaryAction.nextStatus === task.status}
                      onClick={() => onStatusChange(task.id, primaryAction.nextStatus)}
                      className="inline-flex h-8 items-center justify-center gap-1.5 rounded-full border border-[var(--brand-orange)] bg-[var(--brand-orange)]/20 px-3 text-[10px] font-semibold text-[var(--ink)] transition-colors hover:bg-[var(--brand-orange)]/30 disabled:cursor-not-allowed disabled:opacity-45"
                    >
                      <PrimaryIcon className="h-3.5 w-3.5" />
                      <span className="truncate">{primaryAction.label}</span>
                    </button>
                  );
                })()}

                <div className="ml-auto flex items-center gap-2">
                  <button
                    type="button"
                    disabled={disabled || task.status === "HOLD" || task.status === "COMPLETED"}
                    onClick={() => onStatusChange(task.id, "HOLD")}
                    className={iconOnlyActionButtonClassName}
                    aria-label="Put on Hold"
                    title="Put on Hold"
                  >
                    <Pause className="h-3.5 w-3.5" />
                  </button>

                  <button
                    type="button"
                    disabled={disabled || task.status === "COMPLETED"}
                    onClick={() => onStatusChange(task.id, "COMPLETED")}
                    className={iconOnlyActionButtonClassName}
                    aria-label="Mark Complete"
                    title="Mark Complete"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            ) : null}
          </div>
          );
        })}
      </div>

      {activeTask ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4">
          <div className="w-full max-w-lg rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-4 shadow-xl">
            <div className="mb-3 flex items-center justify-between gap-3">
              <div>
                <h4 className="text-sm font-extrabold text-[var(--ink)]">Task Details</h4>
                <p className="text-xs text-[var(--muted)]">{activeTask.projectName}</p>
              </div>
              <button
                type="button"
                className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface)] text-[var(--muted)] hover:text-[var(--ink)]"
                onClick={() => {
                  setActiveTaskForSubtasks(null);
                  setEditingSubTaskId(null);
                  setEditingSubTaskName("");
                }}
                aria-label="Close subtasks"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="mb-3 space-y-2 rounded-md border border-[var(--border)] bg-[var(--surface)] p-3">
              <label className="grid gap-1 text-xs">
                <span className="font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Task Name</span>
                <input
                  value={taskDraftName}
                  onChange={(event) => setTaskDraftName(event.target.value)}
                  className="h-9 min-w-0 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 text-sm outline-none focus:border-[var(--brand-orange)]"
                />
              </label>

              <label className="grid gap-1 text-xs">
                <span className="font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Description</span>
                <textarea
                  value={taskDraftDescription}
                  onChange={(event) => setTaskDraftDescription(event.target.value)}
                  className="min-h-20 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 py-2 text-sm outline-none focus:border-[var(--brand-orange)]"
                />
              </label>

              <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr),auto] sm:items-end">
                <label className="grid gap-1 text-xs">
                  <span className="font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Status</span>
                  <select
                    value={taskDraftStatus}
                    onChange={(event) => setTaskDraftStatus(event.target.value as TaskStatus)}
                    className="h-9 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 text-sm outline-none focus:border-[var(--brand-orange)]"
                  >
                    <option value="PENDING">Pending</option>
                    <option value="ACTIVE">Active</option>
                    <option value="IN_PROGRESS">In Progress</option>
                    <option value="IN_REVIEW">In Review</option>
                    <option value="HOLD">Hold</option>
                    <option value="COMPLETED">Completed</option>
                  </select>
                </label>

                <button
                  type="button"
                  className="inline-flex h-9 items-center justify-center rounded-md border border-[var(--brand-orange)] bg-[var(--brand-orange)]/20 px-3 text-xs font-semibold text-[var(--ink)] hover:bg-[var(--brand-orange)]/30 disabled:cursor-not-allowed disabled:opacity-50"
                  onClick={() => {
                    void handleSaveTaskDetails();
                  }}
                  disabled={isSubTaskActionRunning || !taskDraftName.trim()}
                >
                  Save Details
                </button>
              </div>
            </div>

            <h5 className="mb-2 text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Subtasks</h5>

            <div className="mb-3 flex items-center gap-2">
              <input
                value={newSubTaskName}
                onChange={(event) => setNewSubTaskName(event.target.value)}
                placeholder="Add new subtask"
                className="h-9 min-w-0 flex-1 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-3 text-sm outline-none focus:border-[var(--brand-orange)]"
              />
              <button
                type="button"
                className="inline-flex h-9 items-center gap-1 rounded-md border border-[var(--border)] bg-[var(--surface)] px-3 text-xs font-semibold text-[var(--ink)] hover:border-[var(--brand-orange)] disabled:cursor-not-allowed disabled:opacity-50"
                disabled={isSubTaskActionRunning || !newSubTaskName.trim()}
                onClick={() => {
                  void handleAddSubTask();
                }}
              >
                <Plus className="h-3.5 w-3.5" /> Add
              </button>
            </div>

            <div className="max-h-[42vh] space-y-2 overflow-y-auto pr-1">
              {activeTask.subTasks.length === 0 ? (
                <div className="rounded-md border border-dashed border-[var(--border)] p-3 text-xs text-[var(--muted)]">
                  No subtasks yet.
                </div>
              ) : (
                activeTask.subTasks.map((subtask) => {
                  const isCompleted = subtask.status === "COMPLETED";
                  const isEditing = editingSubTaskId === subtask.id;

                  return (
                    <div key={subtask.id} className="rounded-md border border-[var(--border)] bg-[var(--surface)] p-2.5">
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface-muted)] hover:border-[var(--brand-orange)]"
                          onClick={() => {
                            void handleToggleSubTaskStatus(subtask.id, subtask.status);
                          }}
                          disabled={isSubTaskActionRunning || !onUpdateSubTask}
                          aria-label={isCompleted ? "Mark pending" : "Mark complete"}
                          title={isCompleted ? "Mark pending" : "Mark complete"}
                        >
                          <CheckCircle2 className={`h-3.5 w-3.5 ${isCompleted ? "text-sky-500" : "text-[var(--muted)]"}`} />
                        </button>

                        {isEditing ? (
                          <input
                            value={editingSubTaskName}
                            onChange={(event) => setEditingSubTaskName(event.target.value)}
                            className="h-8 min-w-0 flex-1 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 text-xs outline-none focus:border-[var(--brand-orange)]"
                            autoFocus
                          />
                        ) : (
                          <span className={`min-w-0 flex-1 text-xs ${isCompleted ? "line-through text-[var(--muted)]" : "text-[var(--ink)]"}`}>
                            {subtask.name}
                          </span>
                        )}

                        {isEditing ? (
                          <button
                            type="button"
                            className="inline-flex h-7 items-center rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2 text-[10px] font-semibold hover:border-[var(--brand-orange)]"
                            onClick={() => {
                              void handleSaveSubTaskEdit();
                            }}
                            disabled={isSubTaskActionRunning || !editingSubTaskName.trim()}
                          >
                            Save
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface-muted)] hover:border-[var(--brand-orange)]"
                            onClick={() => {
                              setEditingSubTaskId(subtask.id);
                              setEditingSubTaskName(subtask.name);
                            }}
                            disabled={isSubTaskActionRunning || !onUpdateSubTask}
                            aria-label="Edit subtask"
                            title="Edit subtask"
                          >
                            <Pencil className="h-3.5 w-3.5" />
                          </button>
                        )}

                        <button
                          type="button"
                          className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-[var(--border)] bg-[var(--surface-muted)] hover:border-[var(--danger)] hover:text-[var(--danger)]"
                          onClick={() => {
                            void handleDeleteSubTask(subtask.id);
                          }}
                          disabled={isSubTaskActionRunning || !onDeleteSubTask}
                          aria-label="Delete subtask"
                          title="Delete subtask"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      ) : null}
    </Card>
  );
}
