import { AuthProvider } from "../auth/AuthProvider";
import { OperationsPage } from "./OperationsPage";

/** Load Supabase authentication only on operator routes. */
export function OperationsRoute() {
  return <AuthProvider><OperationsPage /></AuthProvider>;
}
