import { Link } from "react-router-dom";
import { Shield, Lock } from "lucide-react";

export interface SiteFooterProps {
  className?: string;
}

/**
 * Responsive Minimal Footer for SANKET AI.
 */
export function SiteFooter({ className = "" }: SiteFooterProps) {
  return (
    <footer
      className={`border-t border-slate-800/80 bg-[#060a14] py-10 px-4 sm:px-6 lg:px-8 text-xs text-slate-400 ${className}`}
    >
      <div className="mx-auto max-w-7xl flex flex-col md:flex-row items-center justify-between gap-6">
        {/* Brand identity & Mission */}
        <div className="flex flex-col items-center md:items-start gap-1">
          <div className="flex items-center gap-2">
            <Shield className="h-4 w-4 text-[#14b8a6]" aria-hidden="true" />
            <strong className="text-sm font-bold text-slate-200 tracking-wide">
              SANKET AI
            </strong>
            <span className="text-slate-500">·</span>
            <span className="text-slate-400">Emergency Information Coordination</span>
          </div>
          <p className="text-[11px] text-slate-500 m-0">
            Source-grounded crisis observation intake with verified human coordinator review.
          </p>
        </div>

        {/* Operational disclaimer */}
        <div className="text-center md:text-right max-w-md">
          <p className="text-[11px] text-slate-400 m-0 leading-relaxed">
            <strong className="text-slate-300">Operational Disclaimer:</strong> SANKET AI is a decision-support aid. It does not perform autonomous dispatching. In life-threatening emergencies, call national emergency dispatch directly.
          </p>
        </div>

        {/* Links */}
        <div className="flex items-center gap-4">
          <a href="#how-it-works" className="hover:text-[#2dd4bf] transition-colors">
            Workflow
          </a>
          <a href="#report-section" className="hover:text-[#2dd4bf] transition-colors">
            Report
          </a>
          <a href="#privacy-section" className="hover:text-[#2dd4bf] transition-colors">
            Ethics &amp; Privacy
          </a>
          <Link
            to="/operations"
            className="inline-flex items-center gap-1 font-semibold text-[#2dd4bf] hover:underline"
          >
            <Lock className="h-3 w-3" aria-hidden="true" />
            Operator Access
          </Link>
        </div>
      </div>

      <div className="mx-auto max-w-7xl mt-8 pt-6 border-t border-slate-900 text-center text-[10px] text-slate-600">
        © {new Date().getFullYear()} SANKET AI · Prototype for reviewable emergency information coordination.
      </div>
    </footer>
  );
}
