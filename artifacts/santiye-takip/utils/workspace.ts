import AsyncStorage from "@react-native-async-storage/async-storage";

export const WORKSPACE_KEY = "santiye_workspace_v1";

export interface WorkspaceInfo {
  id: string;
  invite_code: string;
  company_name: string;
  api_url: string;
  auth_token?: string;
  revision?: number;
}

export async function loadWorkspace(): Promise<WorkspaceInfo | null> {
  try {
    const raw = await AsyncStorage.getItem(WORKSPACE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as WorkspaceInfo;
  } catch {
    return null;
  }
}

export async function saveWorkspace(ws: WorkspaceInfo): Promise<void> {
  await AsyncStorage.setItem(WORKSPACE_KEY, JSON.stringify(ws));
}

export async function clearWorkspace(): Promise<void> {
  await AsyncStorage.removeItem(WORKSPACE_KEY);
}
