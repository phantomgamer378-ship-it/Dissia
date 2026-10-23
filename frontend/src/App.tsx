import { lazy, Suspense, useEffect } from "react";
import { BrowserRouter, Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { SiteHeader } from "./components/SiteHeader";

import { SiteFooter } from "./components/landing/site-footer";

const LandingPage = lazy(() => import("./pages/LandingPage").then((module) => ({ default: module.LandingPage })));
const OperationsRoute = lazy(() => import("./pages/OperationsRoute").then((module) => ({ default: module.OperationsRoute })));

/** Configure the public landing and protected operations routes. */
export function App() {
  return (
    <BrowserRouter>
      <AuthPreviewRedirect />
      <a href="#main-content" className="skip-link">Skip to main content</a>
      <SiteHeader />
      <Suspense fallback={<main id="main-content" className="section text-slate-300" role="status">Loading SANKET AI…</main>}>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/operations" element={<OperationsRoute />} />
          <Route path="*" element={<main id="main-content" className="section text-slate-100"><h1>Page not found</h1><a className="button button-primary" href="/">Return home</a></main>} />
        </Routes>
      </Suspense>
      <SiteFooter />
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
