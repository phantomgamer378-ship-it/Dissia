import { ShieldCheck, EyeOff, Lock, UserCheck, AlertOctagon, Database } from "lucide-react";

export interface PrivacySectionProps {
  className?: string;
}

const POLICIES = [
  {
    icon: EyeOff,
    title: "Zero PII Collection",
    description:
      "We do not collect names, phone numbers, email addresses, or IP cookies for public report submissions. Only observation descriptions and optional landmarks are recorded.",
  },
  {
    icon: Lock,
    title: "Strict AI Consent Boundary",
    description:
      "Third-party LLM processing (Google Gemini) is exclusively invoked when the reporter checks the explicit consent box. Otherwise, text is kept strictly on-premises for manual human review.",
  },
  {
    icon: UserCheck,
    title: "Human Authority Only",
    description:
      "AI extractions are tagged as unverified proposals. Only authorized, authenticated human emergency coordinators have the authority to confirm facts and dispatch tasks.",
  },
  {
    icon: Database,
    title: "Audited Ledger & Retention",
    description:
      "All coordinator reviews, state transitions, and task assignments generate append-only audit events for strict public accountability and post-incident analysis.",
  },
  {
    icon: ShieldCheck,
    title: "Idempotent Data Integrity",
    description:
      "Cryptographic idempotency keys prevent duplicate report creation during intermittent connectivity, network timeouts, or repeated button clicks.",
  },
  {
    icon: AlertOctagon,
    title: "Service Boundaries & Scope",
    description:
      "SANKET AI operates as a coordination and synthesis platform. It is not an emergency dispatch hotline and does not provide automated life-rescue services.",
  },
];

/**
 * Privacy, Data Governance, and Ethical AI Oversight section.
 */
export function PrivacySection({ className = "" }: PrivacySectionProps) {
  return (
    <section
      id="privacy-section"
      className={`mx-auto max-w-5xl py-12 px-4 border-t border-slate-800/80 ${className}`}
      aria-labelledby="privacy-heading"
    >
      <div className="text-center mb-10">
        <span className="text-[11px] font-bold tracking-widest uppercase text-[#14b8a6] bg-[rgba(20,184,166,0.1)] px-3 py-1 rounded-full border border-[rgba(20,184,166,0.2)] inline-block mb-3">
          DATA GOVERNANCE &amp; ETHICS
        </span>
        <h2 id="privacy-heading" className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
          Privacy, Human Oversight &amp; Safety Commitments
        </h2>
        <p className="mt-2 text-sm text-slate-400 max-w-2xl mx-auto">
          Built according to strict ethical AI principles and human-in-the-loop disaster coordination protocols.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {POLICIES.map((policy, idx) => {
          const Icon = policy.icon;
          return (
            <div
              key={idx}
              className="rounded-xl border border-slate-800 bg-[rgba(15,23,42,0.5)] p-5 shadow-sm transition-all hover:border-[rgba(20,184,166,0.3)]"
            >
              <div className="flex items-center gap-3 mb-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[rgba(20,184,166,0.1)] border border-[rgba(20,184,166,0.2)] text-[#2dd4bf]">
                  <Icon className="h-4 w-4" aria-hidden="true" />
                </div>
                <h3 className="text-sm font-bold text-slate-100">{policy.title}</h3>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed m-0">{policy.description}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
