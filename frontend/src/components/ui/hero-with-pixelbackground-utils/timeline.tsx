import { type ReactNode } from "react";

export interface TimelineItem {
  step: string;
  title: string;
  description: string;
  tag?: string;
}

export interface TimelineProps {
  items?: TimelineItem[];
  children?: ReactNode;
  className?: string;
}

const DEFAULT_TIMELINE_ITEMS: TimelineItem[] = [
  {
    step: "01",
    title: "Observation Ingestion",
    description: "Public reports are recorded durably with cryptographic idempotency.",
    tag: "Source-Grounded",
  },
  {
    step: "02",
    title: "Optional AI Structuring",
    description: "Unverified proposals prepared only with explicit reporter consent.",
    tag: "Consent-Enforced",
  },
  {
    step: "03",
    title: "Authorized Coordinator Review",
    description: "Human operators verify evidence before authorizing response tasks.",
    tag: "Human-in-the-Loop",
  },
];

/**
 * Responsive operational timeline and sequence progression component.
 * Displays milestone markers with high contrast and zero horizontal overflow.
 */
export function Timeline({
  items = DEFAULT_TIMELINE_ITEMS,
  children,
  className = "",
}: TimelineProps) {
  if (children) {
    return <div className={`relative ${className}`}>{children}</div>;
  }

  return (
    <div
      className={`grid grid-cols-1 md:grid-cols-3 gap-4 w-full max-w-5xl mx-auto my-6 ${className}`}
      role="region"
      aria-label="Coordination Workflow Stages"
    >
      {items.map((item, index) => (
        <div
          key={item.step || index}
          className="relative flex flex-col p-4 rounded-xl border border-[rgba(20,184,166,0.18)] bg-[rgba(10,15,29,0.7)] backdrop-blur-md shadow-sm transition-all hover:border-[rgba(20,184,166,0.36)]"
        >
          <div className="flex items-center justify-between gap-2 mb-2">
            <span className="font-mono text-xs font-bold text-[#14b8a6] px-2 py-0.5 rounded bg-[rgba(20,184,166,0.1)] border border-[rgba(20,184,166,0.2)]">
              {item.step}
            </span>
            {item.tag && (
              <span className="text-[10px] font-semibold tracking-wider uppercase text-slate-400">
                {item.tag}
              </span>
            )}
          </div>
          <h4 className="text-sm font-bold text-slate-100 mb-1">{item.title}</h4>
          <p className="text-xs text-slate-400 leading-relaxed m-0">{item.description}</p>
        </div>
      ))}
    </div>
  );
}
