import { useEffect, useRef, useState } from "react";
import { getApiErrorMessage, isVersionConflict } from "@/services/api_client.js";
import { getSession } from "@/features/onboarding/login/login_repository.js";
import { updatePreferences } from "./preference_repository.js";

export function useThemeController(preference, onPreferenceUpdated) {
  const [theme, setTheme] = useState("dark");
  const [error, setError] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [timezoneDismissed, setTimezoneDismissed] = useState(false);
  const pending = useRef(false);
  const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  useEffect(() => {
    setTheme(preference?.theme?.toLowerCase() === "light" ? "light" : "dark");
    setTimezoneDismissed(false);
  }, [preference?.theme, preference?.timezone]);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
  }, [theme]);

  async function save(body, rollbackTheme) {
    if (!preference?.version || pending.current) return false;
    pending.current = true;
    setIsSaving(true);
    setError("");
    try {
      const updated = await updatePreferences({ ...body, version: preference.version });
      onPreferenceUpdated(updated);
      setTimezoneDismissed(false);
      return true;
    } catch (requestError) {
      if (rollbackTheme) setTheme(rollbackTheme);
      if (isVersionConflict(requestError)) {
        try { onPreferenceUpdated((await getSession()).preference); } catch { /* Keep the last known server preference. */ }
      }
      setError(getApiErrorMessage(requestError));
      return false;
    } finally {
      pending.current = false;
      setIsSaving(false);
    }
  }

  function toggleTheme() {
    const nextTheme = theme === "light" ? "dark" : "light";
    setTheme(nextTheme);
    void save({ theme: nextTheme }, theme);
  }

  return {
    theme,
    toggleTheme,
    isSaving,
    error,
    timezoneMismatch: Boolean(preference && browserTimezone && preference.timezone !== browserTimezone && !timezoneDismissed),
    browserTimezone,
    saveTimezone: () => save({ timezone: browserTimezone }),
    dismissTimezone: () => setTimezoneDismissed(true),
  };
}
