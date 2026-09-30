import "./app_input.css";

export default function AppInput({ className = "", ...inputProps }) {
  const classes = ["app-input", className].filter(Boolean).join(" ");
  return <input className={classes} {...inputProps} />;
}
