import { GoogleLogin, GoogleOAuthProvider } from "@react-oauth/google";
import AppFooter from "@/shared/widgets/app_footer/app_footer.jsx";
import "./login.css";

const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
const isConfigured = Boolean(import.meta.env.VITE_API_BASE_URL && googleClientId && !googleClientId.startsWith("your-"));

export default function LoginView({ error, isAuthenticating, onLogin, onError }) {
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
        </div>
      </section>
      <AppFooter className="login-footer" />
    </main>
  );
}