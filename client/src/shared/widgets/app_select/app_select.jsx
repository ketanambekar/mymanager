import "./app_select.css";

export default function AppSelect({ children, className = "", ...selectProps }) {
  const classes = ["app-select", className].filter(Boolean).join(" ");
  return <select className={classes} {...selectProps}>{children}</select>;
}
