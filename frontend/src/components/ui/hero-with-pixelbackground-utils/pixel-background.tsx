import { useEffect, useRef } from "react";

export interface PixelBackgroundProps {
  className?: string;
  gap?: number;
  speed?: number;
  colors?: string[];
  opacity?: number;
  direction?: "up" | "down" | "random";
}

interface Pixel {
  x: number;
  y: number;
  size: number;
  baseAlpha: number;
  currentAlpha: number;
  speed: number;
  color: string;
}

/**
 * Animated Canvas Pixel Grid for high-stakes technical dashboards.
 * Renders an optimized, GPU-friendly grid of subtle glowing signal pixels.
 * Automatically respects prefers-reduced-motion and cleans up animation frames.
 */
export function PixelBackground({
  className = "",
  gap = 24,
  speed = 0.6,
  colors = ["#14b8a6", "#06b6d4", "#2dd4bf", "#0ea5e9"],
  opacity = 0.35,
}: PixelBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d", { alpha: true });
    if (!ctx) return;

    let animationFrameId: number;
    let pixels: Pixel[] = [];
    const mediaQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    let prefersReducedMotion = mediaQuery.matches;

    const handleMotionChange = (e: MediaQueryListEvent) => {
      prefersReducedMotion = e.matches;
    };
    mediaQuery.addEventListener("change", handleMotionChange);

    const resize = () => {
      const rect = canvas.parentElement?.getBoundingClientRect() || {
        width: window.innerWidth,
        height: 600,
      };
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      // Reinitialize pixels on resize
      pixels = [];
      const cols = Math.floor(rect.width / gap);
      const rows = Math.floor(rect.height / gap);

      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          // Sparsely populate active pixels (approx 22% density for clean minimalism)
          if (Math.random() > 0.22) continue;
          const color = colors[Math.floor(Math.random() * colors.length)] ?? "#14b8a6";
          const baseAlpha = (Math.random() * 0.4 + 0.1) * opacity;
          pixels.push({
            x: c * gap + (gap / 2),
            y: r * gap + (gap / 2),
            size: Math.random() > 0.7 ? 2.5 : 1.5,
            baseAlpha,
            currentAlpha: baseAlpha,
            speed: (Math.random() * 0.8 + 0.2) * speed * 0.02,
            color,
          });
        }
      }
    };

    let resizeTimer: NodeJS.Timeout;
    const handleResize = () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(resize, 100);
    };

    resize();
    window.addEventListener("resize", handleResize);

    let time = 0;
    const render = () => {
      const rect = canvas.parentElement?.getBoundingClientRect();
      const width = rect?.width || window.innerWidth;
      const height = rect?.height || 600;

      ctx.clearRect(0, 0, width, height);

      time += 0.02;

      for (const p of pixels) {
        if (!prefersReducedMotion) {
          // Subtle pulse oscillation
          p.currentAlpha = p.baseAlpha + Math.sin(time + p.x + p.y) * 0.12 * opacity;
          if (p.currentAlpha < 0.02) p.currentAlpha = 0.02;
        }

        ctx.fillStyle = p.color;
        ctx.globalAlpha = p.currentAlpha;
        ctx.fillRect(p.x, p.y, p.size, p.size);
      }

      ctx.globalAlpha = 1.0;

      if (!prefersReducedMotion) {
        animationFrameId = requestAnimationFrame(render);
      }
    };

    render();

    return () => {
      cancelAnimationFrame(animationFrameId);
      clearTimeout(resizeTimer);
      window.removeEventListener("resize", handleResize);
      mediaQuery.removeEventListener("change", handleMotionChange);
    };
  }, [gap, speed, colors, opacity]);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      className={`pointer-events-none absolute inset-0 h-full w-full ${className}`}
      style={{ display: "block" }}
    />
  );
}
