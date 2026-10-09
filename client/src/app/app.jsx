import "@/styles/tokens.css";
import "@/styles/themes.css";
import "./app.css";
import DashboardView from "@/features/dashboard/dashboard_view.jsx";
import DeviceSessionView from "@/features/account/device_sessions/device_session_view.jsx";
import HabitView from "@/features/habits/habit_view.jsx";
import LoginView from "@/features/onboarding/login/login_view.jsx";
import { useLoginController } from "@/features/onboarding/login/use_login_controller.js";
import { useThemeController } from "@/styles/controller/use_theme_controller.js";

export default function App() {
  const login = useLoginController();
  const themeController = useThemeController(login.user?.preference, login.onPreferenceUpdated);
  if (login.isBootstrapping) return <div className="app-loading" role="status">Loading your workspace...</div>;
  if (login.user && login.path === "/devices") {
    return <DeviceSessionView onBack={() => login.navigate("/")} onCurrentDeviceRevoked={login.clearSession} user={login.user} />;
  }
  if (login.user && login.path === "/habits") {
    return <HabitView onBack={() => login.navigate("/")} />;
  }
  return login.user && login.path !== "/login"
    ? <DashboardView isLoggingOut={login.isLoggingOut} onLogout={login.logout} onOpenDevices={() => login.navigate("/devices")} onOpenHabits={() => login.navigate("/habits")} theme={themeController.theme} themeController={themeController} user={login.user} onToggleTheme={themeController.toggleTheme} />
    : <LoginView
      error={login.error}
      isAuthenticating={login.isAuthenticating}
      onLogin={login.login}
      onError={login.setError}
      onStartQrLogin={login.startQrLogin}
      onCancelQrLogin={login.cancelQrLogin}
      onRetryQrLogin={login.retryQrLogin}
      qrStatus={login.qrStatus}
      qrRequest={login.qrRequest}
      qrError={login.qrError}
      qrSecondsRemaining={login.qrSecondsRemaining}
    />;
}
