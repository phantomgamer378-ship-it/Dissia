import { HeroWithPixelBackground } from "../components/ui/hero-with-pixelbackground";
import { EmergencyAlert } from "../components/landing/emergency-alert";
import { HowItWorks } from "../components/landing/how-it-works";
import { ReportForm } from "../components/landing/report-form";
import { PrivacySection } from "../components/landing/privacy-section";

/**
 * Public Landing Page for SANKET AI.
 * Integrates the pixel-background hero, critical triage notice,
 * operational workflow explanation, live report intake form,
 * and data privacy / human oversight commitments.
 */
export function LandingPage() {
  return (
    <main id="main-content" className="min-h-screen bg-[#070b16] text-slate-100 flex flex-col">
      {/* Hero Section with Interactive Pixel Background & Operational Progression */}
      <HeroWithPixelBackground
        reportSectionId="#report-section"
        operationsPath="/operations"
      />

      {/* Critical Emergency Warning Banner */}
      <div className="px-4 -mt-8 sm:-mt-10 z-20 relative">
        <EmergencyAlert />
      </div>

      {/* Three-step Operational Workflow */}
      <HowItWorks className="mt-8" />

      {/* Citizen Emergency Observation Intake Form & Live Receipt Polling */}
      <ReportForm className="mt-4" />

      {/* Privacy, Data Governance & Ethical AI Oversight */}
      <PrivacySection className="mt-8 pb-16" />
    </main>
  );
}
