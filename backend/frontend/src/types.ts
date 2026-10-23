export type UserRole = "pending" | "responder" | "coordinator";
export type NoticeKind = "info" | "success" | "error";

export interface PublicConfig {
  gemini_processing_enabled: boolean;
  supabase_auth_enabled: boolean;
  supabase_url: string | null;
  supabase_publishable_key: string | null;
}

export interface UserProfile {
  id: string;
  email: string;
  role: UserRole;
}

export interface DashboardSummary {
  reports: number;
  needs_review: number;
  open_incidents: number;
  active_tasks: number;
}

export interface Extraction {
  incident_category: string;
  incident_summary: string;
  source_evidence?: string[];
  [key: string]: unknown;
}

export interface Report {
  id: string;
  description: string;
  location: string | null;
  received_at: string;
  status: string;
  urgency: string;
  reviewed: boolean;
  association_count: number;
  extraction: Extraction | null;
}

export interface Incident {
  id: string;
  title: string;
  summary: string;
  location: string | null;
  status: string;
  report_count: number;
  created_at: string;
}

export interface ResponseTask {
  id: string;
  title: string;
  description: string;
  incident_title: string;
  status: string;
  assignee: string | null;
  version: number;
}

export interface IncidentCandidate {
  id: string;
  title: string;
  similarity: number;
  evidence: string[];
}

export interface AuditEvent {
  actor: string;
  action: string;
  target_type: string;
  target_id: string;
  created_at: string;
  detail: string | null;
}

export interface UserAccount {
  user_id: string;
  email: string;
  role: UserRole;
  created_at: string;
}

export interface Receipt {
  receipt_id: string;
  status: string;
}

export interface ExtractionRecord {
  version: number;
  provider: string;
  validation_state: string;
  model: string | null;
  duration_ms: number;
  schema_version: number;
  result: Extraction;
}
