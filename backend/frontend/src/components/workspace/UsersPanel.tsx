import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { api, errorText } from "../../api";
import { useToast } from "../ToastProvider";
import type { UserAccount, UserRole } from "../../types";

/** Let coordinators grant or remove user roles through server-checked actions. */
export function UsersPanel({ token, currentEmail }: { token: string | null; currentEmail: string }) {
  const queryClient = useQueryClient();
  const { notify } = useToast();
  const query = useQuery({
    queryKey: ["user-accounts"],
    queryFn: () => api<{ items: UserAccount[] }>("/api/v1/users", token),
  });
  const updateRole = useMutation({
    mutationFn: ({ user, role }: { user: UserAccount; role: UserRole }) =>
      api("/api/v1/users/" + encodeURIComponent(user.user_id) + "/role", token, {
        method: "PATCH",
        body: JSON.stringify({ role }),
      }),
    onSuccess: (_, variables) => {
      notify("Updated access for " + variables.user.email + ".", "success");
      void queryClient.invalidateQueries({ queryKey: ["user-accounts"] });
    },
    onError: (error) => notify(errorText(error), "error"),
  });

  return (
    <>
      <div className="panel-toolbar">
        <p className="panel-subtitle">Assign each registered account its least-privilege operational role.</p>
        <div className="toolbar-actions"><button className="button button-quiet button-sm" type="button" onClick={() => void query.refetch()}>↻ Refresh accounts</button></div>
      </div>
      <div className="items-list" aria-live="polite">
        {query.isPending ? <div className="empty-state">Loading accounts…</div> : query.error ? <div className="empty-state status-error">{errorText(query.error)}</div> : !query.data?.items.length ? <div className="empty-state">No accounts have requested access yet.</div> : query.data.items.map((user) => (
          <AccountCard key={user.user_id} user={user} currentEmail={currentEmail} saving={updateRole.isPending} onSave={(role) => updateRole.mutate({ user, role })} />
        ))}
      </div>
    </>
  );
}

function AccountCard({ user, currentEmail, saving, onSave }: {
  user: UserAccount;
  currentEmail: string;
  saving: boolean;
  onSave: (role: UserRole) => void;
}) {
  const [role, setRole] = useState<UserRole>(user.role);
  const isSelf = user.email.toLowerCase() === currentEmail.toLowerCase();
  return (
    <article className="item-card account-card">
      <div>
        <strong className="item-title">{user.email}</strong>
        <p className="item-meta">Registered {new Date(user.created_at).toLocaleString()}</p>
        <span className={"badge " + (user.role === "pending" ? "badge-queued" : "badge-role")}>{user.role.toUpperCase()}</span>
      </div>
      <div className="item-actions">
        <label className="visually-hidden" htmlFor={"user-role-" + user.user_id}>Role for {user.email}</label>
        <select id={"user-role-" + user.user_id} className="select-sm" value={isSelf ? "coordinator" : role} disabled={isSelf || saving} onChange={(event) => setRole(event.target.value as UserRole)}>
          <option value="pending">Pending</option><option value="responder">Responder</option><option value="coordinator">Coordinator</option>
        </select>
        <button className="button button-outline button-sm" type="button" disabled={isSelf || saving || role === user.role} title={isSelf ? "Your coordinator access is protected." : undefined} onClick={() => onSave(role)}>Save role</button>
      </div>
    </article>
  );
}
