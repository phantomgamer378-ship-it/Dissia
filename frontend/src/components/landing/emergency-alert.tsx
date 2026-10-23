import { AlertTriangle, PhoneCall } from "lucide-react";

export interface EmergencyAlertProps {
  className?: string;
}

/**
 * Critical emergency warning banner.
 * Informs citizens with immediate life danger to contact local emergency dispatch (112 / 911 / 999) directly.
 * Follows WCAG high-contrast standards and role="alert" semantics.
 */
export function EmergencyAlert({ className = "" }: EmergencyAlertProps) {
  return (
    <aside
      className={`mx-auto max-w-5xl rounded-xl border-2 border-red-500/40 bg-gradient-to-r from-red-950/40 via-red-900/20 to-neutral-900/60 p-5 shadow-lg shadow-red-950/20 backdrop-blur-md ${className}`}
      role="alert"
      aria-label="Critical Emergency Notice"
    >
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-red-600/20 border border-red-500/40 text-red-400">
          <AlertTriangle className="h-5 w-5" aria-hidden="true" />
        </div>

        <div className="flex-1">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <strong className="text-sm font-bold text-red-200 uppercase tracking-wide">
              Immediate Life Danger? Contact your local emergency services now.
            </strong>
          </div>
          <p className="text-xs text-slate-300 leading-relaxed m-0">
            <strong>SANKET AI is a coordination aid, not an emergency dispatch hotline.</strong> Do not wait for this platform when someone is in immediate danger. Dial your regional emergency dispatch number directly: <span className="font-semibold text-white">112</span> (India/EU), <span className="font-semibold text-white">911</span> (US/Canada), or <span className="font-semibold text-white">999</span> (UK).
          </p>
        </div>

        <div className="shrink-0 pt-2 sm:pt-0">
          <span className="inline-flex items-center gap-1.5 rounded-md border border-red-500/30 bg-red-500/10 px-3 py-1.5 text-xs font-semibold text-red-300">
            <PhoneCall className="h-3.5 w-3.5" aria-hidden="true" />
            Dispatch Direct
          </span>
        </div>
      </div>
    </aside>
  );
}
