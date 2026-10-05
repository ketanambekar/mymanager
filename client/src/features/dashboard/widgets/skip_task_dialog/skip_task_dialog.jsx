import { useEffect, useRef, useState } from "react";
import { CircleX, SkipForward, X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import "./skip_task_dialog.css";

const QUICK_REASONS = {
  skip: ["Rest day", "Not feeling well", "Travelling or away", "Busy with higher-priority work", "Not needed this time"],
  miss: ["Forgot about it", "Ran out of time", "Something urgent came up", "Low energy or motivation", "Blocked or waiting on someone"],
};

export default function SkipTaskDialog({ task, action = "skip", error = "", isPending = false, onCancel, onConfirm, onReasonChange }) {
  const dialogRef = useRef(null);
  const [reason, setReason] = useState("");
  const isOpen = Boolean(task);
  const isMiss = action === "miss";
  const title = isMiss ? "Why was this task missed?" : "Why are you skipping this task?";
  const taskAction = isMiss ? "miss" : "skip";
  const quickReasons = QUICK_REASONS[action];

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen && !dialog.open) dialog.showModal();
    if (!isOpen && dialog.open) dialog.close();
  }, [isOpen]);

  useEffect(() => {
    setReason("");
  }, [task?.id]);

  async function handleSubmit(event) {
    event.preventDefault();
    if (!reason.trim() || isPending) return;
    await onConfirm(reason);
  }

  return (
    <dialog aria-labelledby="skip-task-title" className={`skip-task-dialog${isMiss ? " is-miss" : ""}`} onClose={onCancel} ref={dialogRef}>
      <form noValidate onSubmit={handleSubmit}>
        <div className="skip-task-heading">
          <span aria-hidden="true" className="skip-task-icon">{isMiss ? <CircleX size={18} /> : <SkipForward size={18} />}</span>
          <div>
            <p className="section-kicker">{isMiss ? "MARK AS MISSED" : "SKIP OCCURRENCE"}</p>
            <h2 id="skip-task-title">{title}</h2>
          </div>
          <AppIconButton aria-label={`Close ${taskAction} dialog`} disabled={isPending} onClick={onCancel} variant="dialog-close">
            <X aria-hidden="true" size={17} />
          </AppIconButton>
        </div>
        <p className="skip-task-name">{task?.title}</p>
        <div aria-label={`Suggested ${taskAction} reasons`} className="skip-task-reasons" role="group">
          {quickReasons.map((quickReason) => (
            <button
              aria-pressed={reason === quickReason}
              className="skip-task-reason-chip"
              disabled={isPending}
              key={quickReason}
              onClick={() => {
                setReason(quickReason);
                onReasonChange();
              }}
              type="button"
            >
              {quickReason}
            </button>
          ))}
        </div>
        <label className="skip-task-reason-label" htmlFor="task-closure-reason">Reason</label>
        <AppInput
          autoFocus
          aria-describedby={error ? "task-closure-reason-error" : undefined}
          aria-invalid={Boolean(error)}
          id="task-closure-reason"
          maxLength={200}
          onChange={(event) => {
            setReason(event.target.value);
            onReasonChange();
          }}
          placeholder={`Choose a suggestion or enter your own reason for ${taskAction === "miss" ? "missing" : "skipping"} this task`}
          required
          value={reason}
        />
        {error && <p className="skip-task-error" id="task-closure-reason-error" role="alert">{error}</p>}
        <div aria-live="polite" className="skip-task-character-count">{reason.length}/200</div>
        <div className="skip-task-actions">
          <AppButton disabled={isPending} onClick={onCancel} variant="secondary">Cancel</AppButton>
          <AppButton className="skip-task-confirm" disabled={isPending || !reason.trim()} type="submit">
            {isPending ? (isMiss ? "Marking missed..." : "Skipping...") : `Confirm ${taskAction}`}
          </AppButton>
        </div>
      </form>
    </dialog>
  );
}
