import { useRef, useState, type FormEvent } from "react";
import { useAuth } from "../auth/AuthProvider";
import { useToast } from "../components/ToastProvider";
import { Workspace } from "../components/workspace/Workspace";

/** Render sign-in, pending approval, password recovery, and the operator workspace. */
export function OperationsPage() {
  const { session, profile, loadingProfile, recoveryMode, setRecoveryMode, signOut } = useAuth();
  const { notify } = useToast();

  async function endSession() {
    try {
      await signOut();
      notify("You have signed out.", "success");
    } catch (reason) {
      notify(reason instanceof Error ? reason.message : "Unable to sign out.", "error");
    }
  }

  return (
    <main id="main-content" className="section operations-section" aria-labelledby="ops-heading">
      <div className="section-header">
        <div><span className="section-tag">OPERATIONS</span><h1 id="ops-heading">Emergency Coordination Workspace</h1></div>
        <p className="section-desc">Authorized personnel can review source reports, manage incidents, and approve traceable response tasks.</p>
      </div>
      {profile && <div className="session-controls"><span className="badge badge-role">{profile.role.toUpperCase()}</span><button className="button button-outline button-sm" type="button" onClick={() => void endSession()}>Sign out</button></div>}
      {recoveryMode ? (
        <RecoveryPanel onDone={() => setRecoveryMode(false)} />
      ) : loadingProfile && session ? (
        <div className="card access-state-card" role="status"><h2>Checking your account access…</h2><p>Please wait while SANKET verifies your current role.</p></div>
      ) : profile?.role === "pending" ? (
        <PendingAccess />
      ) : profile ? (
        <Workspace />
      ) : (
        <SignInPanel />
      )}
    </main>
  );
}

function SignInPanel() {
  const { client, ready, error, status, setStatus, signIn, signUp, sendPasswordReset } = useAuth();
  const { notify } = useToast();
  const formRef = useRef<HTMLFormElement>(null);
  const [busy, setBusy] = useState(false);

  async function runCredentials(action: (email: string, password: string) => Promise<void>) {
    const form = formRef.current;
    if (!form || !form.reportValidity()) return;
    const data = new FormData(form);
    setBusy(true);
    try {
      await action(String(data.get("email") ?? ""), String(data.get("password") ?? ""));
    } catch (reason) {
      setStatus(reason instanceof Error ? reason.message : "Sign-in request failed.");
    } finally {
      setBusy(false);
    }
  }

  async function requestReset() {
    const form = formRef.current;
    const input = form?.elements.namedItem("email");
    if (!(input instanceof HTMLInputElement) || !input.reportValidity()) return;
    setBusy(true);
    try {
      await sendPasswordReset(input.value);
    } catch (reason) {
      setStatus(reason instanceof Error ? reason.message : "Password reset request failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card login-card">
      <form ref={formRef} className="auth-form" onSubmit={(event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        void runCredentials(signIn);
      }}>
        <div className="auth-form-fields">
          <div className="form-group"><label htmlFor="login-email">Work email</label><input id="login-email" name="email" type="email" autoComplete="username" maxLength={254} required placeholder="you@example.org" /></div>
          <div className="form-group"><label htmlFor="login-password">Password</label><input id="login-password" name="password" type="password" autoComplete="current-password" minLength={8} required placeholder="At least 8 characters" /></div>
        </div>
        <div className="auth-actions">
          <button className="button button-primary" type="submit" disabled={!ready || !client || busy}>{busy ? "Please wait…" : "Sign in"}</button>
          <button className="button button-outline" type="button" disabled={!ready || !client || busy} onClick={() => void runCredentials(signUp)}>Create account</button>
          <button className="button button-quiet" type="button" disabled={!ready || !client || busy} onClick={() => void requestReset()}>Forgot password?</button>
        </div>
      </form>
      <p className={"auth-status" + (error ? " status-error" : "")} role="status" aria-live="polite">{status}</p>
      {!ready && <p className="item-meta">Loading secure sign-in configuration…</p>}
      {error && <button className="button button-quiet button-sm" type="button" onClick={() => notify(error, "error")}>Show setup detail</button>}
    </div>
  );
}

function RecoveryPanel({ onDone }: { onDone: () => void }) {
  const { updatePassword, setStatus } = useAuth();
  const { notify } = useToast();
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("Choose a new password for your account.");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (password.length < 8) {
      setMessage("Use a password with at least 8 characters.");
      return;
    }
    setBusy(true);
    try {
      await updatePassword(password);
      setStatus("Password updated. Sign in with your new password.");
      setPassword("");
      setMessage("Password updated. Sign in with your new password.");
      onDone();
      notify("Password updated.", "success");
    } catch (reason) {
      setMessage(reason instanceof Error ? reason.message : "Password update failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card recovery-card">
      <h2>Reset your password</h2>
      <form className="auth-form" onSubmit={(event) => void submit(event)}>
        <div className="form-group"><label htmlFor="recovery-password">Choose a new password</label><input id="recovery-password" type="password" autoComplete="new-password" minLength={8} required value={password} onChange={(event) => setPassword(event.target.value)} /></div>
        <button className="button button-primary" type="submit" disabled={busy}>{busy ? "Updating…" : "Update password"}</button>
      </form>
      <p className="auth-status" role="status" aria-live="polite">{message}</p>
    </div>
  );
}

function PendingAccess() {
  const { refreshProfile } = useAuth();
  const { notify } = useToast();
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("Check again after your coordinator approves access.");

  async function checkAccess() {
    setBusy(true);
    try {
      await refreshProfile();
      setMessage("Access status refreshed.");
    } catch (reason) {
      const text = reason instanceof Error ? reason.message : "Unable to check access.";
      setMessage(text);
      notify(text, "error");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card access-state-card" role="status">
      <span className="badge badge-queued">Approval required</span>
      <h2>Your account is waiting for coordinator approval</h2>
      <p>Your account is confirmed. A coordinator must assign a responder or coordinator role before operational data is available.</p>
      <p className="auth-status" aria-live="polite">{message}</p>
      <button className="button button-outline button-sm" type="button" disabled={busy} onClick={() => void checkAccess()}>{busy ? "Checking…" : "Check access"}</button>
    </div>
  );
}
