import { useState } from "react";
import { NavLink } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowDown, Lock, Menu, X } from "lucide-react";
import { api } from "../../api";

export interface SiteHeaderProps {
  className?: string;
}

interface HealthResponse {
  status: string;
}

/**
 * Responsive Navigation Header for SANKET AI.
 * Includes verified backend health check indicator, anchor navigation,
 * and mobile drawer toggle.
 */
export function SiteHeader({ className = "" }: SiteHeaderProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Poll backend health status to verify real platform availability
  const healthQuery = useQuery({
    queryKey: ["system-health"],
    queryFn: () => api<HealthResponse>("/healthz"),
    refetchInterval: 30000,
    retry: 1,
  });

  const isOnline = healthQuery.data?.status === "ok";
  const isError = healthQuery.isError;
  const isLoading = healthQuery.isLoading;

  return (
    <header
      className={`sticky top-0 z-50 w-full border-b border-[rgba(20,184,166,0.15)] bg-[rgba(8,13,26,0.85)] backdrop-blur-md transition-all ${className}`}
    >
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand identity */}
        <NavLink
          to="/"
          className="flex items-center gap-3 text-white no-underline group focus-visible:ring-2 focus-visible:ring-[#2dd4bf] rounded-md"
          aria-label="SANKET AI Home"
        >
          <div className="relative flex h-8 w-8 items-center justify-center rounded-lg bg-[rgba(20,184,166,0.15)] border border-[rgba(20,184,166,0.3)]">
            <span className="relative flex h-3 w-3">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#14b8a6] opacity-75" />
              <span className="relative inline-flex h-3 w-3 rounded-full bg-[#14b8a6]" />
            </span>
          </div>

          <div className="flex flex-col">
            <div className="flex items-center gap-1.5 font-extrabold text-base tracking-wider text-white">
              <span>SANKET</span>
              <span className="text-xs px-1.5 py-0.2 rounded bg-[rgba(20,184,166,0.2)] text-[#2dd4bf] border border-[rgba(20,184,166,0.3)] font-mono">
                AI
              </span>
            </div>
            <span className="text-[10px] uppercase tracking-widest text-slate-400 font-semibold">
              Emergency Coordination
            </span>
          </div>
        </NavLink>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-6" aria-label="Main Navigation">
          <a
            href="#how-it-works"
            className="text-xs font-semibold text-slate-300 hover:text-[#2dd4bf] transition-colors"
          >
            How It Works
          </a>
          <a
            href="#report-section"
            className="text-xs font-semibold text-slate-300 hover:text-[#2dd4bf] transition-colors"
          >
            Intake Portal
          </a>
          <a
            href="#privacy-section"
            className="text-xs font-semibold text-slate-300 hover:text-[#2dd4bf] transition-colors"
          >
            Privacy &amp; Safety
          </a>

          {/* Verified Health Indicator */}
          <div
            className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-semibold border ${
              isOnline
                ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-300"
                : isError
                ? "border-rose-500/30 bg-rose-500/10 text-rose-300"
                : "border-slate-700 bg-slate-800 text-slate-400"
            }`}
            title={
              isOnline
                ? "Gateway & Backend Status: Verified Operational"
                : isError
                ? "Backend Status: Offline / Unreachable"
                : "Checking backend liveness..."
            }
          >
            <span
              className={`h-2 w-2 rounded-full ${
                isOnline
                  ? "bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.8)]"
                  : isError
                  ? "bg-rose-400"
                  : "bg-slate-400 animate-pulse"
              }`}
            />
            <span>
              {isOnline ? "Online (Verified)" : isError ? "Offline" : isLoading ? "Connecting…" : "Unknown"}
            </span>
          </div>
        </nav>

        {/* Action Buttons */}
        <div className="hidden md:flex items-center gap-3">
          <a
            href="#report-section"
            className="inline-flex items-center gap-1.5 rounded-lg border border-[rgba(20,184,166,0.3)] bg-[rgba(20,184,166,0.1)] hover:bg-[rgba(20,184,166,0.2)] text-white px-3.5 py-2 text-xs font-semibold transition-all"
          >
            <ArrowDown className="h-3.5 w-3.5 text-[#2dd4bf]" aria-hidden="true" />
            Report Hazard
          </a>

          <NavLink
            to="/operations"
            className="inline-flex items-center gap-1.5 rounded-lg bg-gradient-to-r from-[#0d9488] to-[#14b8a6] hover:from-[#115e59] hover:to-[#0f766e] text-white px-3.5 py-2 text-xs font-bold shadow-md shadow-[rgba(20,184,166,0.2)] transition-all"
          >
            <Lock className="h-3.5 w-3.5" aria-hidden="true" />
            Operations Workspace
          </NavLink>
        </div>

        {/* Mobile menu button */}
        <div className="flex md:hidden items-center gap-2">
          {/* Mobile Health Dot */}
          <span
            className={`h-2.5 w-2.5 rounded-full ${
              isOnline ? "bg-emerald-400" : isError ? "bg-rose-400" : "bg-slate-400"
            }`}
            title={isOnline ? "Online" : "Offline"}
          />
          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="rounded-lg p-2 text-slate-300 hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-[#2dd4bf]"
            aria-label={mobileMenuOpen ? "Close navigation menu" : "Open navigation menu"}
            aria-expanded={mobileMenuOpen}
          >
            {mobileMenuOpen ? (
              <X className="h-5 w-5 text-slate-200" aria-hidden="true" />
            ) : (
              <Menu className="h-5 w-5 text-slate-200" aria-hidden="true" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Drawer Navigation */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-slate-800 bg-[#080d1a] px-4 py-5 space-y-4">
          <nav className="flex flex-col space-y-3" aria-label="Mobile Navigation">
            <a
              href="#how-it-works"
              onClick={() => setMobileMenuOpen(false)}
              className="text-sm font-semibold text-slate-200 hover:text-[#2dd4bf]"
            >
              How It Works
            </a>
            <a
              href="#report-section"
              onClick={() => setMobileMenuOpen(false)}
              className="text-sm font-semibold text-slate-200 hover:text-[#2dd4bf]"
            >
              Intake Portal
            </a>
            <a
              href="#privacy-section"
              onClick={() => setMobileMenuOpen(false)}
              className="text-sm font-semibold text-slate-200 hover:text-[#2dd4bf]"
            >
              Privacy &amp; Safety
            </a>
          </nav>

          <div className="pt-3 border-t border-slate-800 flex flex-col gap-2.5">
            <a
              href="#report-section"
              onClick={() => setMobileMenuOpen(false)}
              className="inline-flex items-center justify-center gap-2 rounded-lg border border-[rgba(20,184,166,0.3)] bg-[rgba(20,184,166,0.1)] text-white px-4 py-2.5 text-xs font-semibold"
            >
              <ArrowDown className="h-3.5 w-3.5 text-[#2dd4bf]" aria-hidden="true" />
              Report Hazard
            </a>

            <NavLink
              to="/operations"
              onClick={() => setMobileMenuOpen(false)}
              className="inline-flex items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-[#0d9488] to-[#14b8a6] text-white px-4 py-2.5 text-xs font-bold"
            >
              <Lock className="h-3.5 w-3.5" aria-hidden="true" />
              Operations Workspace
            </NavLink>
          </div>
        </div>
      )}
    </header>
  );
}
