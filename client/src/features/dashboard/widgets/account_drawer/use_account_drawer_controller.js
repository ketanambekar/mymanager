import { useEffect, useRef, useState } from "react";

export function useAccountDrawerController() {
  const dialogRef = useRef(null);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!isOpen) return undefined;
    const previousOverflow = document.documentElement.style.overflow;
    document.documentElement.style.overflow = "hidden";
    return () => { document.documentElement.style.overflow = previousOverflow; };
  }, [isOpen]);

  function open() {
    dialogRef.current.showModal();
    setIsOpen(true);
  }

  function close() {
    dialogRef.current.close();
  }

  return {
    dialogRef, isOpen, open, close,
    onClose: () => setIsOpen(false),
    onKeyDown: (event) => {
      if (event.key !== "Tab") return;
      const buttons = [...dialogRef.current.querySelectorAll("button:not(:disabled)")];
      const first = buttons[0];
      const last = buttons[buttons.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    },
    onBackdropClick: (event) => {
      if (event.target !== dialogRef.current) return;
      const bounds = dialogRef.current.getBoundingClientRect();
      if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) close();
    },
  };
}
