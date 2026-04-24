import { PageKey, Permission, useApp } from "@/context/AppContext";

export function usePermission(pageKey: PageKey): Permission {
  const { roles, appUsers, currentUserId, loaded } = useApp();
  if (!loaded) return "none";
  const user = appUsers.find((u) => u.id === currentUserId);
  if (!user) return "none";
  const role = roles.find((r) => r.id === user.roleId);
  if (!role) return "none";
  return role.permissions[pageKey] ?? "none";
}
