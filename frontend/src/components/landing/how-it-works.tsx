import { FileEdit, Cpu, UserCheck } from "lucide-react";

export interface HowItWorksProps {
  className?: string;
}

const STEPS = [
  {
    number: "01",
    title: "Report",
    icon: FileEdit,
    tag: "Firsthand Observations",
    description:
      "Share what happened and provide a useful location or landmark when known. No personal contact details, phone numbers, or account registrations are required.",
    details: "Durable cryptographic deduplication ensures every observation is preserved.",
  },
  {
    number: "02",
    title: "Structure",
    icon: Cpu,
    tag: "Consent-Enforced AI",
    description:
      "Where explicitly permitted by the reporter and configured by system policy, Gemini AI parses raw text to suggest structured incident categories and urgency levels.",
    details: "Unconsented reports bypass the AI service entirely and queue directly for human triage.",
  },
  {
    number: "03",
    title: "Verify",
    icon: UserCheck,
    tag: "Human Authority",
    description:
      "Authorized coordinators review every proposal against raw source evidence, correlate related reports, and authorize audited response tasks.",
    details: "Consequential operational actions are never executed autonomously by machine models.",
  },
];

/**
 * Three-step operational explanation of the SANKET AI human-in-the-loop workflow.
 */
export function HowItWorks({ className = "" }: HowItWorksProps) {
  return (
    <section
      id="how-it-works"
      className={`mx-auto max-w-5xl py-12 px-4 ${className}`}
      aria-labelledby="how-it-works-heading"
    >
      <div className="text-center mb-10">
        <span className="text-[11px] font-bold tracking-widest uppercase text-[#14b8a6] bg-[rgba(20,184,166,0.1)] px-3 py-1 rounded-full border border-[rgba(20,184,166,0.2)] inline-block mb-3">
          VERIFIED WORKFLOW
        </span>
        <h2 id="how-it-works-heading" className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
          How SANKET AI Coordinates Emergency Observations
        </h2>
        <p className="mt-2 text-sm text-slate-400 max-w-2xl mx-auto">
          An open, source-grounded pipeline designed to convert chaotic community reports into verified, actionable incident records without hallucinations or autonomous actions.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {STEPS.map((step) => {
          const Icon = step.icon;
          return (
            <div
              key={step.number}
              className="relative flex flex-col justify-between rounded-xl border border-[rgba(20,184,166,0.18)] bg-[rgba(15,23,42,0.65)] p-6 shadow-sm backdrop-blur-sm transition-all hover:border-[rgba(20,184,166,0.4)] hover:shadow-md"
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex h-11 w-11 items-center justify-center rounded-lg bg-[rgba(20,184,166,0.12)] border border-[rgba(20,184,166,0.25)] text-[#2dd4bf]">
                    <Icon className="h-5 w-5" aria-hidden="true" />
                  </div>
                  <span className="font-mono text-xl font-extrabold text-slate-500">
                    {step.number}
                  </span>
                </div>

                <div className="mb-2">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-[#14b8a6]">
                    {step.tag}
                  </span>
                  <h3 className="text-lg font-bold text-white mt-0.5 mb-2">{step.title}</h3>
                </div>

                <p className="text-xs text-slate-300 leading-relaxed mb-4">
                  {step.description}
                </p>
              </div>

              <div className="pt-3 border-t border-slate-800 text-[11px] text-slate-400 font-medium">
                {step.details}
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
