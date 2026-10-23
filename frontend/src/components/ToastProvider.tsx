import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from "react";
import type { NoticeKind } from "../types";

interface Notice {
  id: number;
  message: string;
  kind: NoticeKind;
}

interface ToastContextValue {
  notify: (message: string, kind?: NoticeKind) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

/** Provide accessible, dismissible status messages across the application. */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [notices, setNotices] = useState<Notice[]>([]);

  const dismiss = useCallback((id: number) => {
    setNotices((current) => current.filter((notice) => notice.id !== id));
  }, []);

  const notify = useCallback((message: string, kind: NoticeKind = "info") => {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    setNotices((current) => [...current, { id, message, kind }]);
    window.setTimeout(() => dismiss(id), 4500);
  }, [dismiss]);

  const value = useMemo(() => ({ notify }), [notify]);
  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-container" aria-live="assertive" aria-atomic="false">
        {notices.map((notice) => (
          <div key={notice.id} className={"toast toast-" + notice.kind} role="status">
            <span>{notice.message}</span>
            <button className="button button-sm button-quiet" type="button" aria-label="Dismiss notification" onClick={() => dismiss(notice.id)}>×</button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

/** Return the notification helper from the nearest ToastProvider. */
export function useToast(): ToastContextValue {
  const value = useContext(ToastContext);
  if (!value) throw new Error("useToast must be used inside ToastProvider.");
  return value;
}
