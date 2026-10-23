"""Validated request and extraction schemas."""

from enum import Enum
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class Category(str, Enum):
    FLOOD = "FLOOD"
    FIRE = "FIRE"
    COLLAPSE = "COLLAPSE"
    MEDICAL = "MEDICAL"
    HAZMAT = "HAZMAT"
    OTHER = "OTHER"


class Urgency(str, Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    UNKNOWN = "UNKNOWN"


class ReportSubmission(BaseModel):
    """Public report intake; contact details are intentionally not collected."""
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    description: str = Field(min_length=12, max_length=5000)
    location: str | None = Field(default=None, max_length=300)
    ai_consent: bool = False


class Extraction(BaseModel):
    """Unverified, source-grounded extraction proposal."""
    model_config = ConfigDict(extra="forbid")
    incident_category: Category
    incident_summary: str = Field(max_length=500)
    reported_event_time: str | None = None
    location_wording: str | None = None
    location_clues: list[str]
    reported_hazards: list[str]
    reported_needs: list[str]
    urgency_level: Urgency
    urgency_rationale: str
    source_evidence: list[str]
    ambiguity_notes: list[str]


class IncidentCreate(BaseModel):
    """Coordinator-created incident proposal."""
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    title: str = Field(min_length=4, max_length=160)
    summary: str = Field(min_length=8, max_length=2000)
    location: str | None = Field(default=None, max_length=300)
    report_id: str | None = None


class IncidentUpdate(BaseModel):
    """Coordinator-managed incident status and detail updates."""
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    title: str | None = Field(default=None, min_length=4, max_length=160)
    summary: str | None = Field(default=None, min_length=8, max_length=2000)
    location: str | None = Field(default=None, max_length=300)
    status: Literal["OPEN", "ACTIVE", "RESOLVED", "CLOSED"] | None = None


class TaskCreate(BaseModel):
    """Response task proposed by an authorized coordinator."""
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    title: str = Field(min_length=4, max_length=160)
    description: str = Field(min_length=5, max_length=1000)


class TaskTransition(BaseModel):
    """Task status transition with optional assignment, notes, and version check."""
    model_config = ConfigDict(extra="forbid")
    status: str
    assignee: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=1000)
    version: int = Field(ge=1)


class ReportAssociation(BaseModel):
    """Coordinator decision for a report-to-incident candidate relationship."""
    model_config = ConfigDict(extra="forbid")
    report_id: str
    state: Literal["CONFIRMED", "REJECTED"]


class UserRoleUpdate(BaseModel):
    """Coordinator-managed access level for a registered Supabase user."""
    model_config = ConfigDict(extra="forbid")
    role: Literal["pending", "coordinator", "responder"]
