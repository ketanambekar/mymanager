import { createPortal } from "react-dom";
import { CalendarDays, ChevronRight, LogOut, MonitorSmartphone, Moon, Sun, X } from "lucide-react";
import { APP_VERSION } from "@/constants/app_constants.js";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import { useAccountDrawerController } from "./use_account_drawer_controller.js";
import "./account_drawer.css";

function AccountAvatar({ user }) {
  return user.avatarUrl
    ? <img alt="" className="account-drawer-avatar" referrerPolicy="no-referrer" src={user.avatarUrl} />
    : <span aria-hidden="true" className="account-drawer-avatar">{(user.displayName || user.email || "M").charAt(0).toUpperCase()}</span>;
}

function formatAccountDate(value, timezone) {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium", timeStyle: "short", timeZone: timezone,
  }).format(new Date(value));
}

export default function AccountDrawer({ user, theme, themeController, onToggleTheme, onOpenDevices, onOpenHabits, onLogout, isLoggingOut }) {
  const drawer = useAccountDrawerController();
  const timezone = user.preference?.timezone;

  function openDevices() {
    drawer.close();
    onOpenDevices();
  }

  return (
    <>
      <button aria-controls="account-drawer" aria-expanded={drawer.isOpen} aria-haspopup="dialog" aria-label="Open profile and settings" className="account-profile-button" onClick={drawer.open} title="Profile & settings" type="button">
        <AccountAvatar user={user} />
      </button>
      {createPortal(
        <dialog aria-labelledby="account-drawer-title" className="account-drawer" id="account-drawer" onClick={drawer.onBackdropClick} onClose={drawer.onClose} onKeyDown={drawer.onKeyDown} ref={drawer.dialogRef}>
          <header className="account-drawer-heading">
            <div><p className="account-drawer-eyebrow">YOUR ACCOUNT</p><h2 id="account-drawer-title">Profile &amp; settings</h2></div>
            <AppIconButton aria-label="Close profile and settings" autoFocus onClick={drawer.close} title="Close" variant="theme"><X aria-hidden="true" size={20} /></AppIconButton>
          </header>
          <div className="account-drawer-body">
            <section aria-label="Your profile" className="account-drawer-profile">
              <AccountAvatar user={user} />
              <div>
                <h3>{user.displayName || "MyManger account"}</h3>
                <p>{user.email}</p>
                {user.status && <span className={`account-profile-status ${user.status === "ACTIVE" ? "is-active" : ""}`}>{user.status.toLowerCase().replace(/_/g, " ")}</span>}
              </div>
            </section>
            <section aria-labelledby="account-workspace-title" className="account-drawer-section">
              <h3 id="account-workspace-title">Workspace</h3>
              <button className="account-drawer-action" onClick={() => { drawer.close(); onOpenHabits(); }} type="button">
                <CalendarDays aria-hidden="true" size={19} />
                <span><strong>Habits</strong><small>Explore your daily task history</small></span>
                <ChevronRight aria-hidden="true" size={16} />
              </button>
            </section>
            <section aria-labelledby="account-preferences-title" className="account-drawer-section">
              <h3 id="account-preferences-title">Preferences</h3>
              {timezone && <dl className="account-drawer-details"><div><dt>Account timezone</dt><dd>{timezone}</dd></div></dl>}
              <button className="account-drawer-action" disabled={themeController.isSaving} onClick={onToggleTheme} type="button">
                {theme === "dark" ? <Sun aria-hidden="true" size={19} /> : <Moon aria-hidden="true" size={19} />}
                <span><strong>{theme === "dark" ? "Switch to light theme" : "Switch to dark theme"}</strong><small>{themeController.isSaving ? "Saving your preference..." : `Currently using ${theme} theme`}</small></span>
                <ChevronRight aria-hidden="true" size={16} />
              </button>
              {themeController.error && <p className="account-drawer-error" role="alert">{themeController.error}</p>}
            </section>
            <section aria-labelledby="account-security-title" className="account-drawer-section">
              <h3 id="account-security-title">Security &amp; devices</h3>
              {user.lastLoginAt && <dl className="account-drawer-details"><div><dt>Last sign-in</dt><dd>{formatAccountDate(user.lastLoginAt, timezone)}</dd></div></dl>}
              <button className="account-drawer-action" onClick={openDevices} type="button">
                <MonitorSmartphone aria-hidden="true" size={19} />
                <span><strong>Devices &amp; sessions</strong><small>Manage sign-ins or sign in another device</small></span>
                <ChevronRight aria-hidden="true" size={16} />
              </button>
              <AppButton className="account-drawer-logout" disabled={isLoggingOut} leadingIcon={<LogOut size={17} />} onClick={onLogout} variant="secondary">{isLoggingOut ? "Signing out..." : "Sign out of this device"}</AppButton>
            </section>
          </div>
          <footer className="account-drawer-footer"><span>MyManger</span><span>Version {APP_VERSION}</span></footer>
        </dialog>,
        document.body,
      )}
    </>
  );
}
