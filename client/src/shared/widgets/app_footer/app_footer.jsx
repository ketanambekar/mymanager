import { useEffect, useState } from "react";
import { APP_VERSION } from "@/constants/app_constants.js";
import "./app_footer.css";

export default function AppFooter({ className = "" }) {
  const [year, setYear] = useState(() => new Date().getFullYear());

  useEffect(() => {
    const intervalId = window.setInterval(() => setYear(new Date().getFullYear()), 60000);
    return () => window.clearInterval(intervalId);
  }, []);

  return (
    <footer className={["workspace-footer", className].filter(Boolean).join(" ")}>
      <span className="footer-message"><span aria-hidden="true" className="footer-status" />Make room for better work.</span>
      <small className="footer-copyright">Copyright © {year} MyManger - All Rights Reserved. | A Product by <strong>KRD Labs</strong></small>
      <span className="footer-version">MyManger <b>v{APP_VERSION}</b></span>
    </footer>
  );
}