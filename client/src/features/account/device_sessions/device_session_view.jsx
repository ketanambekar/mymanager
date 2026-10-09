import { useCallback, useEffect, useRef, useState } from "react";
import { ArrowLeft, Camera, Laptop, LogOut, MonitorSmartphone, RefreshCw, ScanLine, X } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import QrScanner from "./widgets/qr_scanner/qr_scanner.jsx";
import { useDeviceSessionController } from "./use_device_session_controller.js";
import { formatDeviceCode, formatDeviceDate } from "./device_session_utils.js";
import "./device_session_view.css";

function DeviceApprovalDialog({ accountEmail, controller, timezone }) {
  const { approval, decisionState, decisionError, isDeciding, decideRequest, closeApproval } = controller;
  const dialogRef = useRef(null);
  useEffect(() => { dialogRef.current?.showModal(); }, []);
  if (!approval) return null;
  const canDecide = ["idle", "error"].includes(decisionState);

  return (
    <dialog aria-labelledby="device-approval-title" aria-modal="true" className="device-dialog" onCancel={(event) => { event.preventDefault(); closeApproval(); }} ref={dialogRef}>
      <div className="device-dialog-heading">
        <span className="device-dialog-icon"><MonitorSmartphone aria-hidden="true" size={20} /></span>
        <div><p className="device-eyebrow">ACCOUNT APPROVAL</p><h2 id="device-approval-title">Approve sign-in?</h2></div>
      </div>
      <p className="device-dialog-copy"><strong>{approval.deviceName}</strong> is requesting access to <strong>{accountEmail}</strong>.</p>
      <dl className="device-request-details">
        <div><dt>Request started</dt><dd>{formatDeviceDate(approval.createdAt, timezone)}</dd></div>
        {approval.userAgent && <div><dt>Browser details</dt><dd>{approval.userAgent}</dd></div>}
        <div><dt>Request expires</dt><dd>{formatDeviceDate(approval.expiresAt, timezone)}</dd></div>
      </dl>
      <p className="device-security-warning">Approve only a login you started on your own device. This gives that device access to your account.</p>
      {decisionState === "pending" && <p className="device-dialog-status" role="status">Sending your decision...</p>}
      {decisionState === "expired" && <p className="device-dialog-error" role="alert">This request is no longer available. Scan a fresh code to continue.</p>}
      {decisionError && <p className="device-dialog-error" role="alert">{decisionError}</p>}
      <div className="device-dialog-actions">
        <AppButton disabled={!canDecide || isDeciding} onClick={() => void decideRequest("deny")} variant="secondary">Deny</AppButton>
        <AppButton disabled={!canDecide || isDeciding} onClick={() => void decideRequest("approve")}>{isDeciding ? "Approving..." : "Approve sign-in"}</AppButton>
      </div>
      <button className="device-dialog-close" onClick={closeApproval} type="button">Close</button>
    </dialog>
  );
}

function RevokeDialog({ controller }) {
  const { deviceToRevoke, setDeviceToRevoke, isRevoking, confirmRevoke } = controller;
  const dialogRef = useRef(null);
  useEffect(() => { dialogRef.current?.showModal(); }, []);
  if (!deviceToRevoke) return null;
  return (
    <dialog aria-labelledby="revoke-device-title" aria-modal="true" className="device-dialog" onCancel={(event) => { event.preventDefault(); setDeviceToRevoke(null); }} ref={dialogRef}>
      <div className="device-dialog-heading">
        <span className="device-dialog-icon device-dialog-icon--warning"><LogOut aria-hidden="true" size={19} /></span>
        <div><p className="device-eyebrow">END SESSION</p><h2 id="revoke-device-title">Sign out this device?</h2></div>
      </div>
      <p className="device-dialog-copy"><strong>{deviceToRevoke.deviceName}</strong> will lose access on its next request. {deviceToRevoke.isCurrent ? "You will also be signed out here." : "Your current device will stay signed in."}</p>
      <div className="device-dialog-actions">
        <AppButton disabled={isRevoking} onClick={() => setDeviceToRevoke(null)} variant="secondary">Keep session</AppButton>
        <AppButton disabled={isRevoking} onClick={() => void confirmRevoke()}>{isRevoking ? "Signing out..." : "Sign out device"}</AppButton>
      </div>
    </dialog>
  );
}

export default function DeviceSessionView({ user, onBack, onCurrentDeviceRevoked }) {
  const controller = useDeviceSessionController(onCurrentDeviceRevoked);
  const [mode, setMode] = useState("scan");
  const [code, setCode] = useState("");
  const [isScanning, setIsScanning] = useState(false);
  const [scannerError, setScannerError] = useState("");
  const timezone = user?.preference?.timezone;

  const handleScan = useCallback((payload) => {
    setIsScanning(false);
    setScannerError("");
    void controller.findQrRequestFromPayload(payload);
  }, [controller.findQrRequestFromPayload]);
  const handleScannerUnavailable = useCallback((message) => {
    setScannerError(message);
    setIsScanning(false);
  }, []);

  function submitCode(event) {
    event.preventDefault();
    const digits = code.replace(/ /g, "");
    void controller.findQrRequest(digits);
  }

  return (
    <main className="device-sessions-page">
      <header className="device-page-header">
        <AppButton leadingIcon={<ArrowLeft size={16} />} onClick={onBack} variant="secondary">Back to workspace</AppButton>
        <span className="device-page-brand"><span aria-hidden="true" className="brand-mark"><i /><i /><i /></span>My<span>Manger</span></span>
      </header>
      <div className="device-page-content">
        <p className="device-eyebrow">ACCOUNT &amp; SECURITY</p>
        <h1>Devices &amp; sessions</h1>
        <p className="device-page-intro">Review the sign-ins connected to your account. Active means signed in and unexpired; it does not indicate that a device is online.</p>

        <section aria-labelledby="sessions-heading" className="device-section">
          <div className="device-section-heading">
            <div><h2 id="sessions-heading">Active sessions</h2><p>{controller.activeCount} {controller.activeCount === 1 ? "session" : "sessions"}</p></div>
            <AppIconButton aria-label="Refresh device sessions" disabled={controller.isLoading} onClick={() => void controller.loadDevices()} title="Refresh sessions" variant="theme"><RefreshCw aria-hidden="true" size={16} /></AppIconButton>
          </div>
          {controller.isLoading && <p className="device-list-state" role="status">Loading active sessions...</p>}
          {controller.loadError && <div className="device-list-error" role="alert"><span>{controller.loadError}</span><AppButton onClick={() => void controller.loadDevices()} variant="secondary">Try again</AppButton></div>}
          {!controller.isLoading && !controller.loadError && controller.devices.length === 0 && <p className="device-list-state">No active sessions found.</p>}
          {!controller.isLoading && !controller.loadError && controller.devices.length > 0 && (
            <ul className="device-session-list">
              {controller.devices.map((device) => (
                <li className="device-session-item" key={device.id}>
                  <span aria-hidden="true" className="device-session-icon"><Laptop size={20} /></span>
                  <div className="device-session-info">
                    <div className="device-session-title"><strong>{device.deviceName}</strong>{device.isCurrent && <span className="device-current-badge">This device</span>}</div>
                    <div className="device-session-dates">
                      <span><b>Signed in since</b> {formatDeviceDate(device.createdAt, timezone)}</span>
                      <span><b>Last used</b> {formatDeviceDate(device.lastUsedAt, timezone)}</span>
                      <span><b>Expires</b> {formatDeviceDate(device.expiresAt, timezone)}</span>
                    </div>
                    {device.userAgent && device.deviceName === "Existing browser or device" && <small className="device-session-agent">{device.userAgent}</small>}
                  </div>
                  <AppButton className="device-revoke-button" onClick={() => controller.setDeviceToRevoke(device)} variant="secondary">Sign out</AppButton>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section aria-labelledby="new-device-heading" className="device-section device-link-section">
          <div className="device-section-heading">
            <div><h2 id="new-device-heading">Sign in another device</h2><p>Approve a MyManger sign-in request with this account.</p></div>
            <ScanLine aria-hidden="true" className="device-link-icon" size={22} />
          </div>
          <div aria-label="Choose QR scanning or code entry" className="device-mode-tabs" role="group">
              <button aria-pressed={mode === "scan"} className={mode === "scan" ? "is-selected" : ""} onClick={() => { setMode("scan"); setScannerError(""); }} type="button"><Camera aria-hidden="true" size={16} />Scan QR</button>
              <button aria-pressed={mode === "code"} className={mode === "code" ? "is-selected" : ""} onClick={() => { setMode("code"); setIsScanning(false); setScannerError(""); }} type="button">Enter code</button>
          </div>
          {mode === "scan" && (
            <div className="device-scan-content">
              {isScanning ? <QrScanner onScan={handleScan} onUnavailable={handleScannerUnavailable} /> : (
                <>
                  <p>Scan the QR code shown on the device waiting to sign in. Scanning does not approve the request.</p>
                  <AppButton leadingIcon={<Camera size={16} />} onClick={() => { setScannerError(""); setIsScanning(true); }} variant="secondary">Open camera</AppButton>
                </>
              )}
              {scannerError && <p className="device-inline-error" role="status">{scannerError}</p>}
            </div>
          )}
          {mode === "code" && (
            <form className="device-code-form" onSubmit={submitCode}>
              <label htmlFor="device-login-code">10-digit sign-in code</label>
              <div className="device-code-entry">
                <AppInput autoComplete="one-time-code" id="device-login-code" inputMode="numeric" maxLength={11} onChange={(event) => setCode(formatDeviceCode(event.target.value))} placeholder="00123 45678" value={code} />
                <AppButton disabled={controller.isLookingUp || code.replace(/ /g, "").length !== 10} type="submit">{controller.isLookingUp ? "Checking..." : "Review request"}</AppButton>
              </div>
              <p>Keep leading zeroes. Reviewing a code never approves it automatically.</p>
            </form>
          )}
          {mode === "scan" && controller.isLookingUp && <p className="device-inline-status" role="status">Looking up sign-in request...</p>}
          {controller.lookupError && <p className="device-inline-error" role="alert">{controller.lookupError}</p>}
          {controller.decisionState === "approved" && <p className="device-inline-success" role="status">Sign-in approved. The new device can now finish logging in.</p>}
          {controller.decisionState === "denied" && <p className="device-inline-success" role="status">Sign-in request denied.</p>}
          {controller.decisionState === "expired" && <p className="device-inline-error" role="alert">That request expired or was already handled. Ask the new device to create a fresh code.</p>}
        </section>
        {controller.notice && <div className={`device-toast is-${controller.notice.tone}`} role={controller.notice.tone === "error" ? "alert" : "status"}><span>{controller.notice.message}</span><AppIconButton aria-label="Dismiss notification" onClick={controller.clearNotice} title="Dismiss" variant="theme"><X aria-hidden="true" size={15} /></AppIconButton></div>}
      </div>
      {controller.approval && <DeviceApprovalDialog accountEmail={user?.email ?? "your account"} controller={controller} timezone={timezone} />}
      {controller.deviceToRevoke && <RevokeDialog controller={controller} />}
    </main>
  );
}
