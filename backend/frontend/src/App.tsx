import { lazy, Suspense, useEffect } from "react";
import { BrowserRouter, Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { SiteHeader } from "./components/SiteHeader";

const LandingPage = lazy(() => import("./pages/LandingPage").then((module) => ({ default: module.LandingPage })));
const OperationsRoute = lazy(() => import("./pages/OperationsRoute").then((module) => ({ default: module.OperationsRoute })));

/** Configure the public landing and protected operations routes. */
export function App() {
  return (
    <BrowserRouter>
      <AuthPreviewRedirect />
      <a href="#main-content" className="skip-link">Skip to main content</a>
      <SiteHeader />
      <Suspense fallback={<main id="main-content" className="section" role="status">Loading SANKET AI…</main>}>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/operations" element={<OperationsRoute />} />
          <Route path="*" element={<main id="main-content" className="section"><h1>Page not found</h1><a className="button button-primary" href="/">Return home</a></main>} />
        </Routes>
      </Suspense>
      <footer>
        <div className="footer-container">
          <div className="footer-brand"><strong>SANKET AI</strong> · Emergency Information Coordination Platform</div>
          <div className="footer-meta"><span>Verified Human-in-the-Loop Review</span> · <span>Zero Unsupported Autonomous Dispatches</span></div>
        </div>
      </footer>
    </BrowserRouter>
  );
}

function AuthPreviewRedirect() {
  const location = useLocation();
  const navigate = useNavigate();
  useEffect(() => {
    const preview = new URLSearchParams(location.search).get("preview");
    if (location.pathname === "/" && preview === "auth") {
      navigate("/operations?preview=auth", { replace: true });
    }
  }, [location.pathname, location.search, navigate]);
  return null;
}
