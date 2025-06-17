import { Project } from "@/types/project";
import { z } from "zod";


export const CreateProjectRequestSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  csv_path: z.string(),
});

export type CreateProjectRequest = z.infer<typeof CreateProjectRequestSchema>;

export type ProjectListResponse = Project[];

export const DeleteProjectRequestSchema = z.object({
  id: z.number(),
});

export type DeleteProjectRequest = z.infer<typeof DeleteProjectRequestSchema>;

export const GetProjectTotalRequestSchema = z.object({
  id: z.number(),
});

export type GetProjectTotalRequest = z.infer<typeof GetProjectTotalRequestSchema>;
}
  