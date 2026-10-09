import { GoogleLogin, GoogleOAuthProvider } from "@react-oauth/google";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppFooter from "@/shared/widgets/app_footer/app_footer.jsx";
import QrCode from "./widgets/qr_code/qr_code.jsx";
import "./login.css";

const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
const isConfigured = Boolean(import.meta.env.VITE_API_BASE_URL && googleClientId && !googleClientId.startsWith("your-"));

function formatCountdown(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

function formatCode(code) {
  return code ? `${code.slice(0, 5)} ${code.slice(5)}` : "";
}

export default function LoginView({
  error, isAuthenticating, onLogin, onError, qrStatus, qrRequest, qrError,
  qrSecondsRemaining, onStartQrLogin, onCancelQrLogin, onRetryQrLogin,
}) {
  const showQrPanel = qrStatus !== "idle";
  return (
    <main className="login-screen">
      <div aria-hidden="true" className="login-backdrop" />
      <header className="login-header">
        <span className="login-brand"><span aria-hidden="true" className="login-brand-mark"><i /><i /><i /></span><span className="login-brand-copy">My<span>Manger</span></span></span>
        <span className="login-header-label">YOUR WORKSPACE</span>
      </header>
      <section aria-labelledby="login-heading" className="login-content">
        <p className="login-kicker">A CLEARER WAY TO WORK</p>
        <h1 id="login-heading">MyManger</h1>
        <p className="login-subtitle">Make room for better work.</p>
        <div className="login-action">
          {isConfigured ? (
            <GoogleOAuthProvider clientId={googleClientId} onScriptLoadError={() => onError("Google sign-in could not load. Check your connection and try again.")}>
              <GoogleLogin onSuccess={(response) => void onLogin(response.credential)} onError={() => onError("Google sign-in could not start. Please try again.")} useOneTap={false} text="continue_with" size="large" width="280" />
            </GoogleOAuthProvider>
          ) : (
            <button aria-describedby="login-unavailable" className="login-google-button" disabled type="button"><span aria-hidden="true" className="login-google-mark">G</span>Continue with Google</button>
          )}
          {!isConfigured && <p id="login-unavailable" role="status">Google sign-in is not configured yet.</p>}
          {isAuthenticating && <p role="status">Signing in...</p>}
          {error && <p className="login-error" role="alert">{error}</p>}
          <div className="login-device-divider"><span>OR</span></div>
          {!showQrPanel && <AppButton onClick={onStartQrLogin} variant="secondary">Log in with another device</AppButton>}
          {showQrPanel && (
            <section aria-labelledby="login-device-heading" className="login-device-panel">
              <div className="login-device-heading">
                <div>
                  <p className="login-kicker">SECURE DEVICE LINK</p>
                  <h2 id="login-device-heading">Log in with another device</h2>
                </div>
                {qrStatus === "waiting" && <span aria-label={`Expires in ${formatCountdown(qrSecondsRemaining)}`} className="login-device-countdown">{formatCountdown(qrSecondsRemaining)}</span>}
              </div>
              {qrStatus === "creating" && <p className="login-device-state" role="status">Creating a secure sign-in request...</p>}
              {qrRequest && ["waiting", "claiming", "error", "cancelling"].includes(qrStatus) && (
                <div className="login-device-content">
                  <div className="login-device-qr"><QrCode label="Scan this QR code from a device already signed in to MyManger" value={qrRequest.qrPayload} /></div>
                  <div className="login-device-code">
                    <span>Or enter this code in MyManger</span>
                    <strong>{formatCode(qrRequest.code)}</strong>
                    <small>This code expires in {formatCountdown(qrSecondsRemaining)}.</small>
                  </div>
                </div>
              )}
              {qrStatus === "waiting" && <p className="login-device-state" role="status">Waiting for approval from your signed-in device...</p>}
              {qrStatus === "claiming" && <p className="login-device-state" role="status">Approved. Finishing sign-in...</p>}
              {qrStatus === "cancelling" && <p className="login-device-state" role="status">Cancelling this sign-in request...</p>}
              {qrStatus === "denied" && <p className="login-device-state" role="status">This sign-in request was denied.</p>}
              {qrStatus === "cancelled" && <p className="login-device-state" role="status">This sign-in request was cancelled.</p>}
              {qrStatus === "expired" && <p className="login-device-state" role="status">This sign-in request expired. Create a new one to try again.</p>}
              {qrError && <p className="login-error" role="alert">{qrError}</p>}
              <div className="login-device-actions">
                {qrStatus === "waiting" && <AppButton onClick={onCancelQrLogin} variant="secondary">Cancel</AppButton>}
                {qrStatus === "error" && <AppButton onClick={qrRequest ? onRetryQrLogin : onStartQrLogin} variant="secondary">{qrRequest ? "Retry" : "Try again"}</AppButton>}
                {["denied", "cancelled", "expired"].includes(qrStatus) || (qrStatus === "error" && qrRequest)
                  ? <AppButton onClick={onStartQrLogin} variant="primary">Generate a new code</AppButton>
                  : null}
              </div>
            </section>
          )}
        </div>
      </section>
      <AppFooter className="login-footer" />
    </main>
  );
}