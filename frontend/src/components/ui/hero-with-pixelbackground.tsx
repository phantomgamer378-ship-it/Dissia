import { motion, type Variants } from "motion/react";
import { Link } from "react-router-dom";
import { ShieldCheck, ArrowDown, ChevronRight, Activity } from "lucide-react";
import { PixelBackground } from "./hero-with-pixelbackground-utils/pixel-background";
import { Timeline } from "./hero-with-pixelbackground-utils/timeline";

export interface HeroWithPixelBackgroundProps {
  className?: string;
  reportSectionId?: string;
  operationsPath?: string;
}

/**
 * Rebranded SANKET AI Hero component with interactive pixel background,
 * subtle cyan/teal illumination, animated entrance, and dual operational CTAs.
 */
export function HeroWithPixelBackground({
  className = "",
  reportSectionId = "#report-section",
  operationsPath = "/operations",
}: HeroWithPixelBackgroundProps) {
  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.12,
        delayChildren: 0.05,
      },
    },
  };

  const itemVariants: Variants = {
    hidden: { opacity: 0, y: 16 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.6,
        ease: "easeOut",
      },
    },
  };

  return (
    <div
      className={`relative min-h-[580px] w-full overflow-hidden bg-gradient-to-b from-[#080d1a] via-[#091122] to-[#070b16] py-16 px-4 sm:px-6 lg:px-8 border-b border-[rgba(20,184,166,0.12)] ${className}`}
    >
      {/* Decorative Interactive Pixel Canvas Background */}
      <PixelBackground
        gap={26}
        speed={0.5}
        colors={["#14b8a6", "#06b6d4", "#2dd4bf", "#38bdf8"]}
        opacity={0.32}
      />

      {/* Subtle radial glow in the center */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute left-1/2 top-1/3 -translate-x-1/2 -translate-y-1/2 h-96 w-96 rounded-full bg-[radial-gradient(ellipse_at_center,rgba(20,184,166,0.14),transparent_70%)] blur-2xl"
      />

      <div className="relative mx-auto max-w-5xl text-center z-10 flex flex-col items-center">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="w-full flex flex-col items-center"
        >
          {/* Eyebrow Badge */}
          <motion.div variants={itemVariants} className="mb-4">
            <span className="inline-flex items-center gap-2 rounded-full border border-[rgba(20,184,166,0.3)] bg-[rgba(20,184,166,0.08)] px-3.5 py-1 text-xs font-semibold text-[#2dd4bf] backdrop-blur-md shadow-sm">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#14b8a6] opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-[#14b8a6]" />
              </span>
              COMMUNITY REPORTING · HUMAN-VERIFIED REVIEW
            </span>
          </motion.div>

          {/* Main Headline */}
          <motion.h1
            variants={itemVariants}
            className="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight text-white mb-4 max-w-4xl leading-[1.12]"
          >
            Every Signal Matters.{" "}
            <span className="bg-gradient-to-r from-[#2dd4bf] via-[#14b8a6] to-[#38bdf8] bg-clip-text text-transparent">
              Every Report Counts.
            </span>
          </motion.h1>

          {/* Supporting Text */}
          <motion.p
            variants={itemVariants}
            className="text-base sm:text-lg md:text-xl text-slate-300 max-w-2xl mb-8 leading-relaxed font-normal"
          >
            Turn fragmented emergency observations into structured information that authorized coordinators can review, verify, and act upon.
          </motion.p>

          {/* Primary & Secondary Call to Actions */}
          <motion.div
            variants={itemVariants}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full sm:w-auto mb-10"
          >
            <a
              href={reportSectionId}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-[#0d9488] to-[#14b8a6] hover:from-[#115e59] hover:to-[#0f766e] text-white px-6 py-3.5 text-sm font-bold shadow-lg shadow-[rgba(20,184,166,0.25)] transition-all hover:-translate-y-0.5 focus-visible:ring-2 focus-visible:ring-[#2dd4bf] focus-visible:ring-offset-2 focus-visible:ring-offset-[#080d1a]"
            >
              <ArrowDown className="w-4 h-4" aria-hidden="true" />
              Submit an Emergency Report
            </a>

            <Link
              to={operationsPath}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-lg border border-[rgba(20,184,166,0.3)] bg-[rgba(15,23,42,0.6)] hover:bg-[rgba(20,184,166,0.12)] text-slate-200 hover:text-white px-6 py-3.5 text-sm font-semibold backdrop-blur-sm transition-all hover:border-[rgba(20,184,166,0.6)] focus-visible:ring-2 focus-visible:ring-[#2dd4bf] focus-visible:ring-offset-2 focus-visible:ring-offset-[#080d1a]"
            >
              Authorized Operator Access
              <ChevronRight className="w-4 h-4 text-[#2dd4bf]" aria-hidden="true" />
            </Link>
          </motion.div>

          {/* Operational Progression Timeline */}
          <motion.div variants={itemVariants} className="w-full">
            <Timeline />
          </motion.div>

          {/* Trust Indicator */}
          <motion.div
            variants={itemVariants}
            className="mt-4 flex items-center gap-2 text-xs font-medium text-slate-400"
          >
            <ShieldCheck className="w-4 h-4 text-[#2dd4bf]" aria-hidden="true" />
            <span>AI-assisted analysis. Human-led decisions. No autonomous dispatches.</span>
            <Activity className="w-3.5 h-3.5 text-slate-500 ml-2" aria-hidden="true" />
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}
