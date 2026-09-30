import "./app_button.css";

export default function AppButton({
  children,
  className = "",
  leadingIcon,
  type = "button",
  variant = "primary",
  ...buttonProps
}) {
  const classes = ["app-button", `app-button--${variant}`, className].filter(Boolean).join(" ");

  return (
    <button className={classes} type={type} {...buttonProps}>
      {leadingIcon && <span aria-hidden="true" className="app-button__icon">{leadingIcon}</span>}
      {children}
    </button>
  );
}
