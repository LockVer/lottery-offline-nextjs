import { invoke } from "@tauri-apps/api/core";

import { Project } from "@/types/project";
import { getDatabaseInstance } from "@/lib/database/database-connection";

export const listProjectsQueryOptions = {
  queryKey: ["project-list"],
  queryFn: async (): Promise<Project[]> => {
    const db = await getDatabaseInstance();
    const res = await db.select<Project[]>("SELECT * FROM projects");
    return res;
  },
};

export const importProjectMutationOptions = {
  mutationKey: ["project-list"],
  mutationFn: async ({ path, name }: { path: string; name: string }) => {
    await invoke("import_project_dat", { path, name });
  },
};

export const deleteProjectMutationOption = {
  mutationKey: ["project-list"],
  mutationFn: async ({ id }: { id: number }) => {
    const db = await getDatabaseInstance();
    const res = await db.execute("delete from projects where id = ?", [id]);
    if (res.rowsAffected === 0) {
      throw new Error("Project not found");
    }
    return true;
  }
};

export const getProjectByIdQueryOptions = (id: number | string) => ({
  queryKey: ["project", id],
  queryFn: async (): Promise<Project> => {
    const db = await getDatabaseInstance();
    const result = await db.select<Project[]>("SELECT * FROM projects WHERE id = ?", [id]);
    if (result.length === 0) {
      throw new Error("Project not found");
    }
    return result[0];
  }
});

export const getProjectStatsQueryOptions = (id: number | string) => ({
  queryKey: ["project-stats", id],
  queryFn: async () => {
    const db = await getDatabaseInstance();
    const result = await db.select<{prize: number, count: number}[]>(
      `SELECT prize, COUNT(*) as count FROM tickets 
       WHERE project_id = ? 
       GROUP BY prize 
       ORDER BY prize`,
      [id]
    );
    return result;
  }
});

export const renameProjectMutationOption = {
  mutationKey: ["project-list"],
  mutationFn: async ({ id, name }: { id: number; name: string }) => {
    const db = await getDatabaseInstance();
    const res = await db.execute("update projects set name = ? where id = ?", [name, id]);
    if (res.rowsAffected === 0) {
      throw new Error("Project not found");
    }
    return true;
  }
}