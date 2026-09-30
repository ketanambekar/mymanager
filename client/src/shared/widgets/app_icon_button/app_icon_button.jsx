import "./app_icon_button.css";

export default function AppIconButton({
  children,
  className = "",
  type = "button",
  variant = "default",
  ...buttonProps
}) {
  const classes = ["app-icon-button", `app-icon-button--${variant}`, className].filter(Boolean).join(" ");

  return (
    <button className={classes} type={type} {...buttonProps}>
      {children}
    </button>
  );
}
