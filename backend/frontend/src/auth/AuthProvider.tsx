import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { Session, SupabaseClient } from "@supabase/supabase-js";
import { api, errorText } from "../api";
import type { PublicConfig, UserProfile } from "../types";

export interface AuthContextValue {
  client: SupabaseClient | null;
  session: Session | null;
  profile: UserProfile | null;
  config: PublicConfig | null;
  ready: boolean;
  loadingProfile: boolean;
  error: string | null;
  status: string;
  setStatus: (message: string) => void;
  recoveryMode: boolean;
  setRecoveryMode: (value: boolean) => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  sendPasswordReset: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

/** Own the Supabase session and resolve application roles through FastAPI. */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [client, setClient] = useState<SupabaseClient | null>(null);
  const [config, setConfig] = useState<PublicConfig | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [ready, setReady] = useState(false);
  const [loadingProfile, setLoadingProfile] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState("Checking secure sign-in configuration…");
  const [recoveryMode, setRecoveryMode] = useState(false);
  const latestToken = useRef<string | null>(null);
  const profileRequest = useRef(0);

  const syncProfile = useCallback(async (next: Session | null, force = false) => {
    setSession(next);
    setError(null);
    if (!next) {
      latestToken.current = null;
      setProfile(null);
      setLoadingProfile(false);
      return;
    }
    if (!force && latestToken.current === next.access_token) return;
    latestToken.current = next.access_token;
    const requestId = ++profileRequest.current;
    setLoadingProfile(true);
    try {
      const nextProfile = await api<UserProfile>("/api/v1/auth/me", next.access_token);
      if (requestId === profileRequest.current) {
        setProfile(nextProfile);
        setStatus("Signed in as " + nextProfile.email + ". Access: " + nextProfile.role + ".");
      }
    } catch (reason) {
      if (requestId === profileRequest.current) {
        setError(errorText(reason));
        setProfile(null);
        setStatus(errorText(reason) + " Reload the page and try again.");
        latestToken.current = null;
      }
    } finally {
      if (requestId === profileRequest.current) setLoadingProfile(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    let subscription: { unsubscribe: () => void } | null = null;

    void api<PublicConfig>("/api/v1/config")
      .then(async (publicConfig) => {
        if (cancelled) return;
        setConfig(publicConfig);
        if (!publicConfig.supabase_auth_enabled || !publicConfig.supabase_url || !publicConfig.supabase_publishable_key) {
          setStatus("Secure sign-in is not configured on this server.");
          setError("Supabase Auth is not configured.");
          setReady(true);
          return;
        }
        const { createClient } = await import("@supabase/supabase-js");
        const supabase = createClient(publicConfig.supabase_url, publicConfig.supabase_publishable_key, {
          auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true },
        });
        if (cancelled) return;
        setClient(supabase);
        const listener = supabase.auth.onAuthStateChange((event, nextSession) => {
          if (event === "PASSWORD_RECOVERY") setRecoveryMode(true);
          void syncProfile(nextSession);
        });
        subscription = listener.data.subscription;
        const { data, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        await syncProfile(data.session, true);
        if (!cancelled) {
          if (!data.session) setStatus("Sign in with an approved account, or request a new account.");
          setReady(true);
        }
      })
      .catch((reason: unknown) => {
        if (!cancelled) {
          setError(errorText(reason));
          setStatus("Sign-in setup failed: " + errorText(reason));
          setReady(true);
        }
      });

    return () => {
      cancelled = true;
      subscription?.unsubscribe();
      profileRequest.current += 1;
    };
  }, [syncProfile]);

  const signIn = useCallback(async (email: string, password: string) => {
    if (!client) throw new Error("Secure sign-in is not configured.");
    const { error: authError } = await client.auth.signInWithPassword({ email: email.trim().toLowerCase(), password });
    if (authError) throw authError;
    setStatus("Signed in. Checking account access…");
  }, [client]);

  const signUp = useCallback(async (email: string, password: string) => {
    if (!client) throw new Error("Secure sign-in is not configured.");
    const { data, error: authError } = await client.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: { emailRedirectTo: window.location.origin + "/operations" },
    });
    if (authError) throw authError;
    setStatus(data.session
      ? "Account created. A coordinator must approve your access."
      : "Account request received. Confirm your email, then sign in. Coordinator approval is also required.");
  }, [client]);

  const sendPasswordReset = useCallback(async (email: string) => {
    if (!client) throw new Error("Secure sign-in is not configured.");
    const { error: authError } = await client.auth.resetPasswordForEmail(email.trim().toLowerCase(), {
      redirectTo: window.location.origin + "/operations",
    });
    if (authError) throw authError;
    setStatus("If this address has an account, a password reset link is on its way.");
  }, [client]);

  const updatePassword = useCallback(async (password: string) => {
    if (!client) throw new Error("Secure sign-in is not configured.");
    const { error: authError } = await client.auth.updateUser({ password });
    if (authError) throw authError;
    await client.auth.signOut();
    setRecoveryMode(false);
    setStatus("Password updated. Sign in with your new password.");
  }, [client]);

  const signOut = useCallback(async () => {
    if (!client) return;
    const { error: authError } = await client.auth.signOut();
    if (authError) throw authError;
  }, [client]);

  const refreshProfile = useCallback(async () => {
    if (!client) throw new Error("Sign in to check account access.");
    const { data, error: sessionError } = await client.auth.getSession();
    if (sessionError) throw sessionError;
    if (!data.session) throw new Error("Sign in to check account access.");
    await syncProfile(data.session, true);
  }, [client, syncProfile]);

  const value = useMemo<AuthContextValue>(() => ({
    client, session, profile, config, ready, loadingProfile, error, status, setStatus,
    recoveryMode, setRecoveryMode, signIn, signUp, sendPasswordReset, updatePassword,
    signOut, refreshProfile,
  }), [client, session, profile, config, ready, loadingProfile, error, status,
    recoveryMode, signIn, signUp, sendPasswordReset, updatePassword, signOut, refreshProfile]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

/** Read the authenticated Supabase user and server-assigned SANKET role. */
export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used inside AuthProvider.");
  return value;
}
