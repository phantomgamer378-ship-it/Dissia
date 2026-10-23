import { useState, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { api, errorText, reportRequestKey } from "../api";
import { useToast } from "../components/ToastProvider";
import type { PublicConfig, Receipt } from "../types";

/** Show public product information and the report intake form. */
export function LandingPage() {
  const [description, setDescription] = useState("");
  const [location, setLocation] = useState("");
  const [aiConsent, setAiConsent] = useState(false);
  const [receiptId, setReceiptId] = useState<string | null>(null);
  const { notify } = useToast();
  const configQuery = useQuery({
    queryKey: ["public-config"],
    queryFn: () => api<PublicConfig>("/api/v1/config"),
  });
  const receiptQuery = useQuery({
    queryKey: ["report-receipt", receiptId],
    enabled: Boolean(receiptId),
    queryFn: () => api<Receipt>("/api/v1/reports/" + receiptId + "/receipt"),
    refetchInterval: (query) => query.state.data?.status === "READY_FOR_REVIEW" ? false : 3000,
  });
  const submission = useMutation({
    mutationFn: (values: { description: string; location: string | null; ai_consent: boolean }) =>
      api<Receipt>("/api/v1/reports", undefined, {
        method: "POST",
        headers: { "Idempotency-Key": reportRequestKey() },
        body: JSON.stringify(values),
      }),
    onSuccess: (result) => {
      setReceiptId(result.receipt_id);
      setDescription("");
      setLocation("");
      setAiConsent(false);
      notify("Report submitted and queued for review.", "success");
    },
    onError: (error) => notify(errorText(error), "error"),
  });

  async function submitReport(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const text = description.trim();
    if (text.length < 12) {
      notify("Description must be at least 12 characters.", "error");
      return;
    }
    submission.mutate({ description: text, location: location.trim() || null, ai_consent: aiConsent });
  }

  async function copyReceipt() {
    if (!receiptId) return;
    try {
      await navigator.clipboard.writeText(receiptId);
      notify("Receipt ID copied.", "success");
    } catch {
      notify("Unable to copy the receipt ID.", "error");
    }
  }

  const readyForReview = receiptQuery.data?.status === "READY_FOR_REVIEW";

  return (
    <main id="main-content">
      <section className="hero">
        <div className="hero-content">
          <div className="hero-badge"><span className="pulse-beacon" /> Community Reporting · Verified Human Review</div>
          <h1>Rapid Emergency Intake &amp; <em>Traceable Response</em></h1>
          <p className="hero-lede">Transform incoming crisis observations into structured, source-grounded incident proposals. Coordinators review each report, connect related observations, and authorize traceable response tasks.</p>
          <div className="hero-actions">
            <a className="button button-primary button-lg focus-visible:ring-2 focus-visible:ring-cyan-400" href="#report-section">Submit an Emergency Report ↓</a>
            <Link className="button button-outline button-lg" to="/operations">Authorized Operator Access →</Link>
          </div>
        </div>
        <aside className="hero-alert-banner" role="alert">
          <div className="alert-icon" aria-hidden="true">!</div>
          <div><strong>Immediate Life Danger?</strong><p>Contact your national or local emergency dispatch (e.g. 112 / 911 / 999) directly. SANKET AI is a coordination aid; reports here are not monitored as an emergency hotline.</p></div>
        </aside>
      </section>

      <section className="section intake-section" id="report-section" aria-labelledby="report-heading">
        <div className="section-header">
          <div><span className="section-tag">PUBLIC INTAKE</span><h2 id="report-heading">Submit an Incident Observation</h2></div>
          <p className="section-desc">Submit facts observed firsthand. Reports are stored durably for authorized coordinator triage. No personal contact details are collected.</p>
        </div>
        <div className="card form-card">
          <form className="form-layout" onSubmit={(event) => void submitReport(event)}>
            <div className="form-group full-width">
              <label htmlFor="report-description">What happened? <span className="required">*</span><span className="char-count">{description.length} / 5000 (min 12)</span></label>
              <textarea id="report-description" name="description" rows={5} minLength={12} maxLength={5000} required value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Describe what occurred, hazards observed (e.g. fire, flood, collapse), trapped individuals, and current conditions..." />
            </div>
            <div className="form-group full-width">
              <label htmlFor="report-location">Location or nearest landmark <span className="optional">(optional)</span></label>
              <input id="report-location" name="location" type="text" maxLength={300} value={location} onChange={(event) => setLocation(event.target.value)} placeholder="Street, neighborhood, landmark, or coordinates if known" />
            </div>
            {configQuery.data?.gemini_processing_enabled && (
              <div className="form-group full-width">
                <label className="checkbox-label" htmlFor="ai-consent"><input id="ai-consent" type="checkbox" aria-label="Allow AI service to prepare an unverified summary for coordinator review" checked={aiConsent} onChange={(event) => setAiConsent(event.target.checked)} /> Allow an AI service to prepare an unverified summary for coordinator review.</label>
              </div>
            )}
            <div className="form-actions full-width">
              <button className="button button-primary button-lg focus-visible:ring-2 focus-visible:ring-cyan-400" type="submit" disabled={submission.isPending}>
                {submission.isPending ? "Submitting…" : "Submit Report"}
              </button>
              <p className="privacy-note">Do not include names, phone numbers, or other personal contact details.</p>
            </div>
          </form>
        </div>
        {receiptId && (
          <div className="receipt-box" role="status" aria-live="polite">
            <div className="receipt-header"><span className="section-tag">REPORT RECEIVED</span><span className={"badge " + (readyForReview ? "badge-ready" : "badge-queued")}>{receiptQuery.data?.status ?? "QUEUED"}</span></div>
            <p>Your report was saved. Keep this receipt ID for reference.</p>
            <div className="receipt-id-row"><code className="receipt-code">{receiptId}</code><button className="button button-sm button-quiet" type="button" onClick={() => void copyReceipt()}>Copy ID</button></div>
            {readyForReview && <p className="item-meta">Processing finished; a coordinator still needs to review the proposal.</p>}
          </div>
        )}
      </section>
    </main>
  );
}
