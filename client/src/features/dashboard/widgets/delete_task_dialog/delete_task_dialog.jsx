import { useEffect, useRef } from "react";
import { AlertTriangle, X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import "./delete_task_dialog.css";

export default function DeleteTaskDialog({ item, onCancel, onConfirm, isPending = false }) {
  const dialogRef = useRef(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (item && !dialog.open) dialog.showModal();
    if (!item && dialog.open) dialog.close();
  }, [item]);

  return (
    <dialog aria-labelledby="delete-task-title" className="delete-task-dialog" onClose={onCancel} ref={dialogRef}>
      <div className="delete-task-heading">
        <span aria-hidden="true" className="delete-task-icon"><AlertTriangle size={19} /></span>
        <div>
          <p className="section-kicker">CONFIRM DELETE</p>
          <h2 id="delete-task-title">Delete {item?.kind ?? "task"}?</h2>
        </div>
        <AppIconButton aria-label="Close confirmation" onClick={onCancel} variant="dialog-close"><X aria-hidden="true" size={17} /></AppIconButton>
      </div>
      <p className="delete-task-message">{item?.title}{item?.kind === "task" && item.subtaskCount > 0 ? ` and its ${item.subtaskCount} ${item.subtaskCount === 1 ? "subtask" : "subtasks"}` : ""} will be permanently removed.</p>
      <div className="delete-task-actions">
        <AppButton disabled={isPending} onClick={onCancel} variant="secondary">Cancel</AppButton>
        <AppButton className="delete-task-confirm" disabled={isPending} onClick={onConfirm}>{isPending ? "Deleting..." : `Delete ${item?.kind ?? "task"}`}</AppButton>
      </div>
    </dialog>
  );
}