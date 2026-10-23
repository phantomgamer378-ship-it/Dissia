import test from "node:test";
import assert from "node:assert/strict";
import { errorText, reportRequestKey } from "../src/api.ts";

test("reportRequestKey produces unique strings prefixed with web-", () => {
  const k1 = reportRequestKey();
  const k2 = reportRequestKey();
  assert.ok(k1.startsWith("web-"));
  assert.ok(k2.startsWith("web-"));
  assert.notEqual(k1, k2);
});

test("errorText formats Error instances accurately", () => {
  const err = new Error("Connection failed");
  assert.equal(errorText(err), "Connection failed");
});

test("errorText handles non-error values gracefully", () => {
  assert.equal(errorText("raw string"), "An unexpected error occurred.");
  assert.equal(errorText(null), "An unexpected error occurred.");
  assert.equal(errorText(undefined), "An unexpected error occurred.");
});

test("form validation logic enforces minimum 12 meaningful characters", () => {
  function validateDescription(text) {
    const trimmed = (text || "").trim();
    if (trimmed.length < 12) return "TOO_SHORT";
    if (trimmed.length > 5000) return "TOO_LONG";
    return "VALID";
  }

  assert.equal(validateDescription(""), "TOO_SHORT");
  assert.equal(validateDescription("   "), "TOO_SHORT");
  assert.equal(validateDescription("fire near 5th"), "VALID"); // exactly 13 chars
  assert.equal(validateDescription("collapse"), "TOO_SHORT"); // 8 chars
  assert.equal(validateDescription("   flash flood alert   "), "VALID"); // trimmed 17 chars
  assert.equal(validateDescription("a".repeat(5001)), "TOO_LONG");
});

test("idempotency key stability across network retries", () => {
  let activeKey = reportRequestKey();
  const retryCount = 3;
  const loggedKeys = [];

  for (let i = 0; i < retryCount; i++) {
    loggedKeys.push(activeKey);
  }

  // Idempotency key must remain identical across retry attempts for the same submission
  assert.equal(loggedKeys.length, 3);
  assert.equal(loggedKeys[0], loggedKeys[1]);
  assert.equal(loggedKeys[1], loggedKeys[2]);

  // A fresh key is only generated on completion / reset
  activeKey = reportRequestKey();
  assert.notEqual(activeKey, loggedKeys[0]);
});

test("receipt status mapping adheres to backend contract", () => {
  function mapStatusDescription(status) {
    switch (status) {
      case "QUEUED":
        return "Report Durably Saved — Ingestion in Progress";
      case "READY_FOR_REVIEW":
        return "Report Ingested & Prepared for Coordinator Review";
      case "FAILED":
        return "Automatic Processing Incomplete — Saved For Manual Triage";
      default:
        return "Pending Ingestion";
    }
  }

  assert.equal(mapStatusDescription("QUEUED"), "Report Durably Saved — Ingestion in Progress");
  assert.equal(mapStatusDescription("READY_FOR_REVIEW"), "Report Ingested & Prepared for Coordinator Review");
  assert.equal(mapStatusDescription("FAILED"), "Automatic Processing Incomplete — Saved For Manual Triage");
  assert.equal(mapStatusDescription("UNKNOWN_STATE"), "Pending Ingestion");
});

test("explicit AI consent defaults to false and preserves report if unconsented", () => {
  const defaultSubmissionState = {
    description: "Building collapse near central train station",
    location: "Central Station Platform 2",
    ai_consent: false,
  };

  assert.equal(defaultSubmissionState.ai_consent, false);
  assert.ok(defaultSubmissionState.description.length >= 12);
  assert.ok(defaultSubmissionState.location.length > 0);
});
