import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, Clock, Copy, AlertCircle, FileCheck } from "lucide-react";
import { api } from "../../api";
import { useToast } from "../ToastProvider";
import type { Receipt } from "../../types";

export interface ReportReceiptProps {
  receiptId: string;
  onReset?: () => void;
  className?: string;
}

/**
 * Live Receipt Box component with real-time TanStack Query polling.
 * Accurately surfaces backend processing status without misrepresenting automated verification.
 */
export function ReportReceipt({ receiptId, onReset, className = "" }: ReportReceiptProps) {
  const { notify } = useToast();
  const [copied, setCopied] = useState(false);

  // Poll receipt endpoint every 3 seconds until terminal status (READY_FOR_REVIEW or failure)
  const receiptQuery = useQuery({
    queryKey: ["report-receipt", receiptId],
    enabled: Boolean(receiptId),
    queryFn: () => api<Receipt>("/api/v1/reports/" + receiptId + "/receipt"),
    refetchInterval: (query) => {
      const status = query.state.data?.status;
      if (status === "READY_FOR_REVIEW" || status === "FAILED") {
        return false;
      }
      return 3000;
    },
  });

  const rawStatus = receiptQuery.data?.status ?? "QUEUED";
  const isReady = rawStatus === "READY_FOR_REVIEW";
  const isFailed = rawStatus === "FAILED";

  async function handleCopy() {
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(receiptId);
      } else {
        // Fallback for environments where navigator.clipboard is unavailable
        const el = document.createElement("textarea");
        el.value = receiptId;
        document.body.appendChild(el);
        el.select();
        document.execCommand("copy");
        document.body.removeChild(el);
      }
      setCopied(true);
      notify("Receipt ID copied to clipboard.", "success");
      setTimeout(() => setCopied(false), 2500);
    } catch {
      notify("Unable to copy to clipboard.", "error");
    }
  }

  return (
    <div
      className={`rounded-xl border border-[rgba(20,184,166,0.3)] bg-[rgba(10,18,34,0.85)] p-6 shadow-xl backdrop-blur-md ${className}`}
      role="status"
      aria-live="polite"
      aria-label="Submission Receipt and Processing Status"
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-800">
        <div className="flex items-center gap-3">
          <div
            className={`flex h-10 w-10 items-center justify-center rounded-lg border ${
              isReady
                ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400"
                : isFailed
                ? "bg-rose-500/10 border-rose-500/30 text-rose-400"
                : "bg-cyan-500/10 border-cyan-500/30 text-cyan-400"
            }`}
          >
            {isReady ? (
              <FileCheck className="h-5 w-5" aria-hidden="true" />
            ) : isFailed ? (
              <AlertCircle className="h-5 w-5" aria-hidden="true" />
            ) : (
              <Clock className="h-5 w-5 animate-pulse" aria-hidden="true" />
            )}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                REPORT CONFIRMATION
              </span>
              <span
                className={`inline-flex items-center gap-1 rounded px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ${
                  isReady
                    ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/40"
                    : isFailed
                    ? "bg-rose-500/20 text-rose-300 border border-rose-500/40"
                    : "bg-amber-500/20 text-amber-300 border border-amber-500/40"
                }`}
              >
                {rawStatus}
              </span>
            </div>
            <h3 className="text-base font-bold text-white mt-0.5">
              {isReady
                ? "Report Ingested & Prepared for Coordinator Review"
                : isFailed
                ? "Automatic Processing Incomplete — Saved For Manual Triage"
                : "Report Durably Saved — Ingestion in Progress"}
            </h3>
          </div>
        </div>

        {onReset && (
          <button
            type="button"
            onClick={onReset}
            className="text-xs font-semibold text-slate-400 hover:text-white underline underline-offset-4 self-start sm:self-auto cursor-pointer"
          >
            Submit another observation
          </button>
        )}
      </div>

      <div className="py-4 space-y-3">
        <p className="text-xs text-slate-300 m-0">
          Your report was persisted with a cryptographic idempotency token. Retain this receipt identifier for your records:
        </p>

        <div className="flex items-center justify-between gap-3 p-3 rounded-lg bg-[rgba(15,23,42,0.8)] border border-slate-800">
          <code className="font-mono text-xs sm:text-sm text-cyan-300 select-all break-all">
            {receiptId}
          </code>
          <button
            type="button"
            onClick={() => void handleCopy()}
            className="inline-flex items-center gap-1.5 rounded-md border border-[rgba(20,184,166,0.3)] bg-[rgba(20,184,166,0.1)] px-3 py-1.5 text-xs font-semibold text-cyan-300 hover:bg-[rgba(20,184,166,0.2)] transition-all cursor-pointer shrink-0"
            aria-label="Copy Receipt Identifier"
          >
            {copied ? (
              <>
                <CheckCircle2 className="h-3.5 w-3.5 text-emerald-400" aria-hidden="true" />
                <span>Copied</span>
              </>
            ) : (
              <>
                <Copy className="h-3.5 w-3.5" aria-hidden="true" />
                <span>Copy ID</span>
              </>
            )}
          </button>
        </div>
      </div>

      <div className="pt-3 border-t border-slate-800 text-xs text-slate-400 space-y-1">
        {isReady && (
          <p className="text-emerald-400/90 font-medium m-0 flex items-center gap-1.5">
            <CheckCircle2 className="h-4 w-4 shrink-0" aria-hidden="true" />
            Processing finished. An authorized human coordinator will review this proposal before any action is authorized.
          </p>
        )}
        <p className="text-[11px] text-slate-500 m-0">
          Note: Ingestion and receipt confirmation does not imply that emergency field units have been dispatched.
        </p>
      </div>
    </div>
  );
}
