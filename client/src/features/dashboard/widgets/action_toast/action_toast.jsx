import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { CircleCheck, CircleAlert, X } from "lucide-react";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import "./action_toast.css";

export default function ActionToast({ notification, onDismiss }) {
  const toastRef = useRef(null);
  const container = notification?.tone === "error" ? document.querySelector("dialog[open]") ?? document.body : document.body;

  useEffect(() => {
    const toast = toastRef.current;
    if (!toast) return;
    if (notification && !toast.matches(":popover-open")) toast.showPopover();
    if (!notification && toast.matches(":popover-open")) toast.hidePopover();
  }, [notification, container]);

  return createPortal(
    <div className={`action-toast ${notification?.tone === "error" ? "is-error" : "is-success"}`} popover="manual" ref={toastRef} role={notification?.tone === "error" ? "alert" : "status"} style={{ "--celebration-color": notification?.color ?? "var(--green)" }}>
      {notification?.celebrate && <span aria-hidden="true" className="toast-confetti">{Array.from({ length: 12 }, (_, index) => <i key={index} />)}</span>}
      {notification?.tone === "error" ? <CircleAlert aria-hidden="true" size={19} /> : <CircleCheck aria-hidden="true" size={19} />}
      <span className="action-toast-message">{notification?.message}</span>
      <AppIconButton aria-label="Dismiss notification" onClick={onDismiss} title="Dismiss" variant="toast-close"><X aria-hidden="true" size={15} /></AppIconButton>
    </div>,
    container,
  );
}