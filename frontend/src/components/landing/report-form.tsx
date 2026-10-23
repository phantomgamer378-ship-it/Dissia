import { useState, useRef, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Send, MapPin, Sparkles, Shield, AlertCircle } from "lucide-react";
import { api, errorText, reportRequestKey } from "../../api";
import { useToast } from "../ToastProvider";
import { ReportReceipt } from "./report-receipt";
import type { PublicConfig, Receipt } from "../../types";

export interface ReportFormProps {
  className?: string;
}

/**
 * Public Emergency Observation Intake Form.
 * Features strict client & server character bounds, durable idempotency,
 * and explicit opt-in consent for third-party AI structuring.
 */
export function ReportForm({ className = "" }: ReportFormProps) {
  const [description, setDescription] = useState("");
  const [location, setLocation] = useState("");
  const [aiConsent, setAiConsent] = useState(false);
  const [receiptId, setReceiptId] = useState<string | null>(null);
  const [validationError, setValidationError] = useState<string | null>(null);

  // Maintain a stable idempotency key for this logical submission attempt across retries
  const currentIdempotencyKeyRef = useRef<string>(reportRequestKey());

  const { notify } = useToast();

  // Inspect real backend capabilities (Gemini toggle)
  const configQuery = useQuery({
    queryKey: ["public-config"],
    queryFn: () => api<PublicConfig>("/api/v1/config"),
  });

  const submission = useMutation({
    mutationFn: (values: { description: string; location: string | null; ai_consent: boolean }) =>
      api<Receipt>("/api/v1/reports", undefined, {
        method: "POST",
        headers: {
          "Idempotency-Key": currentIdempotencyKeyRef.current,
        },
        body: JSON.stringify(values),
      }),
    onSuccess: (result) => {
      const id = result.receipt_id || result.id;
      if (id) {
        setReceiptId(id);
      }
      setValidationError(null);
      notify("Report successfully recorded and queued for coordinator review.", "success");
      // Generate a fresh key for the subsequent logical submission
      currentIdempotencyKeyRef.current = reportRequestKey();
    },
    onError: (error) => {
      notify(errorText(error), "error");
    },
  });

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setValidationError(null);

    const trimmedDesc = description.trim();
    if (trimmedDesc.length < 12) {
      const msg = "Description must be at least 12 meaningful characters (excluding leading/trailing spaces).";
      setValidationError(msg);
      notify(msg, "error");
      return;
    }

    if (trimmedDesc.length > 5000) {
      const msg = "Description exceeds the maximum limit of 5,000 characters.";
      setValidationError(msg);
      notify(msg, "error");
      return;
    }

    submission.mutate({
      description: trimmedDesc,
      location: location.trim() || null,
      ai_consent: aiConsent,
    });
  }

  function handleReset() {
    setReceiptId(null);
    setDescription("");
    setLocation("");
    setAiConsent(false);
    setValidationError(null);
    currentIdempotencyKeyRef.current = reportRequestKey();
  }

  return (
    <section
      id="report-section"
      className={`mx-auto max-w-5xl py-12 px-4 ${className}`}
      aria-labelledby="report-form-heading"
    >
      <div className="mb-8">
        <span className="text-[11px] font-bold tracking-widest uppercase text-[#14b8a6] bg-[rgba(20,184,166,0.1)] px-3 py-1 rounded-full border border-[rgba(20,184,166,0.2)] inline-block mb-2">
          CITIZEN INTAKE PORTAL
        </span>
        <h2 id="report-form-heading" className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
          Submit an Emergency Observation
        </h2>
        <p className="mt-2 text-sm text-slate-300 max-w-2xl">
          Share what you observed firsthand. Include only facts and verifiable conditions needed to coordinate emergency response.
        </p>
      </div>

      {receiptId ? (
        <ReportReceipt receiptId={receiptId} onReset={handleReset} />
      ) : (
        <div className="rounded-xl border border-[rgba(20,184,166,0.22)] bg-[rgba(15,23,42,0.75)] p-6 sm:p-8 shadow-2xl backdrop-blur-md">
          <form onSubmit={(e) => void handleSubmit(e)} className="space-y-6" noValidate>
            {/* Observation description textarea */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <label
                  htmlFor="report-description"
                  className="text-sm font-bold text-slate-200 flex items-center gap-1.5"
                >
                  What happened? <span className="text-red-400" aria-hidden="true">*</span>
                </label>
                <span
                  className={`font-mono text-xs ${
                    description.trim().length >= 12 && description.length <= 5000
                      ? "text-slate-400"
                      : "text-amber-400"
                  }`}
                  aria-live="polite"
                >
                  {description.length} / 5,000 (min 12)
                </span>
              </div>

              <textarea
                id="report-description"
                name="description"
                rows={5}
                required
                minLength={12}
                maxLength={5000}
                value={description}
                onChange={(e) => {
                  setDescription(e.target.value);
                  if (validationError && e.target.value.trim().length >= 12) {
                    setValidationError(null);
                  }
                }}
                placeholder="Describe hazards observed (e.g., active fire, flash flood, structural collapse), individuals in danger, road obstructions, and current visible conditions..."
                className="w-full rounded-lg border border-slate-700 bg-slate-900/90 px-4 py-3 text-sm text-slate-100 placeholder-slate-500 transition-all focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/30 focus:outline-none"
                aria-describedby="desc-hint"
              />
              <p id="desc-hint" className="text-xs text-slate-400">
                Provide objective, factual observations. Be specific about visible severity and location.
              </p>
            </div>

            {/* Location or Landmark input */}
            <div className="space-y-2">
              <label
                htmlFor="report-location"
                className="text-sm font-bold text-slate-200 flex items-center gap-1.5"
              >
                <MapPin className="h-4 w-4 text-[#14b8a6]" aria-hidden="true" />
                Location or Nearest Landmark <span className="text-xs font-normal text-slate-400">(optional)</span>
              </label>

              <input
                id="report-location"
                name="location"
                type="text"
                maxLength={300}
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Street name, cross-street, building landmark, neighborhood, or GPS coordinates if known"
                className="w-full rounded-lg border border-slate-700 bg-slate-900/90 px-4 py-2.5 text-sm text-slate-100 placeholder-slate-500 transition-all focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/30 focus:outline-none"
                aria-describedby="location-hint"
              />
              <p id="location-hint" className="text-xs text-slate-400">
                Helps coordinators correlate multiple reports from the same geographic zone.
              </p>
            </div>

            {/* Explicit AI Consent Boundary Checkbox */}
            {configQuery.data?.gemini_processing_enabled && (
              <div className="rounded-lg border border-[rgba(20,184,166,0.25)] bg-[rgba(20,184,166,0.06)] p-4 transition-all">
                <label htmlFor="ai-consent" className="flex items-start gap-3 cursor-pointer">
                  <input
                    id="ai-consent"
                    type="checkbox"
                    checked={aiConsent}
                    onChange={(e) => setAiConsent(e.target.checked)}
                    aria-label="Allow AI service to prepare an unverified summary for coordinator review"
                    className="mt-1 h-4 w-4 rounded border-slate-700 bg-slate-900 text-[#14b8a6] focus:ring-[#14b8a6] cursor-pointer"
                  />
                  <div className="text-xs text-slate-300 leading-relaxed">
                    <span className="font-semibold text-slate-100 flex items-center gap-1.5 mb-0.5">
                      <Sparkles className="h-3.5 w-3.5 text-[#2dd4bf]" aria-hidden="true" />
                      Allow AI service to prepare an unverified summary for coordinator review.
                    </span>
                    <p className="text-slate-400 m-0">
                      If checked, Gemini AI will assist human operators by extracting structured entities from your observation. If left unchecked, your report is saved safely without invoking external AI models.
                    </p>
                  </div>
                </label>
              </div>
            )}

            {/* Validation Error banner */}
            {validationError && (
              <div
                className="flex items-center gap-2 p-3 rounded-lg border border-red-500/40 bg-red-950/30 text-red-300 text-xs"
                role="alert"
              >
                <AlertCircle className="h-4 w-4 shrink-0 text-red-400" aria-hidden="true" />
                <span>{validationError}</span>
              </div>
            )}

            {/* Form actions and Privacy Notice */}
            <div className="pt-2 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-t border-slate-800">
              <div className="flex items-center gap-2 text-xs text-slate-400">
                <Shield className="h-4 w-4 text-[#14b8a6] shrink-0" aria-hidden="true" />
                <span>
                  <strong>Privacy Notice:</strong> Do not include names, phone numbers, or personal identifying information.
                </span>
              </div>

              <button
                type="submit"
                disabled={submission.isPending}
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-[#0d9488] to-[#14b8a6] hover:from-[#115e59] hover:to-[#0f766e] disabled:opacity-50 disabled:cursor-not-allowed text-white px-7 py-3 text-sm font-bold shadow-lg shadow-[rgba(20,184,166,0.2)] transition-all cursor-pointer focus-visible:ring-2 focus-visible:ring-[#2dd4bf] focus-visible:ring-offset-2 focus-visible:ring-offset-[#080d1a]"
              >
                {submission.isPending ? (
                  <>
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    <span>Submitting Report…</span>
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4" aria-hidden="true" />
                    <span>Submit Report</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
}
