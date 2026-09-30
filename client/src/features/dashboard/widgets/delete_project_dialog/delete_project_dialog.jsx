import { useEffect, useRef } from "react";
import { AlertTriangle, X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import "./delete_project_dialog.css";

export default function DeleteProjectDialog({ isOpen, project, onCancel, onConfirm, isPending = false }) {
  const dialogRef = useRef(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen && !dialog.open) dialog.showModal();
    if (!isOpen && dialog.open) dialog.close();
  }, [isOpen]);

  return (
    <dialog aria-labelledby="delete-project-title" className="delete-project-dialog" onClose={onCancel} ref={dialogRef}>
      <div className="delete-project-heading">
        <span aria-hidden="true" className="delete-project-icon"><AlertTriangle size={19} /></span>
        <div>
          <p className="section-kicker">CONFIRM DELETE</p>
          <h2 id="delete-project-title">Delete {project?.name ?? "project"}?</h2>
        </div>
        <AppIconButton aria-label="Close confirmation" onClick={onCancel} variant="dialog-close"><X aria-hidden="true" size={17} /></AppIconButton>
      </div>
      <p className="delete-project-message">Its tasks will move to {project?.parentProjectId ? "its parent project" : "General"}. Subprojects will move up one level.</p>
      <div className="delete-project-actions">
        <AppButton disabled={isPending} onClick={onCancel} variant="secondary">Cancel</AppButton>
        <AppButton className="delete-project-confirm" disabled={isPending} onClick={onConfirm}>{isPending ? "Deleting..." : "Delete project"}</AppButton>
      </div>
    </dialog>
  );
}