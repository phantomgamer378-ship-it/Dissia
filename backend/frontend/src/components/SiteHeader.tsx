import { NavLink } from "react-router-dom";

/** Render shared navigation and authenticated session controls. */
export function SiteHeader() {
  return (
    <header className="topbar">
      <div className="topbar-container">
        <NavLink className="brand" to="/" aria-label="SANKET AI Home">
          <span className="brand-radar" aria-hidden="true">
            <span className="radar-dot" />
            <span className="radar-ring" />
          </span>
          <span className="brand-text">
            <span className="brand-title">SANKET <small>AI</small></span>
            <span className="brand-subtitle">Emergency Coordination</span>
          </span>
        </NavLink>
        <nav className="topbar-nav" aria-label="Main navigation">
          <a href="/#report-section" className="nav-link">Submit Report</a>
          <NavLink to="/operations" className="nav-link">Operations Workspace</NavLink>
          <span className="status-indicator" title="System Status: Online">
            <span className="indicator-dot" /> Online
          </span>
        </nav>
      </div>
    </header>
  );
}
