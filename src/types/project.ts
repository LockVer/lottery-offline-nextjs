import z from "zod";

export const ProjectSchema = z.object({
  id: z.number(),
  name: z.string(),
  description: z.string().optional(),
  created_at: z.string(),
  updated_at: z.string(),
  total_tickets: z.number(),
  redeemed_tickets: z.number(),
});


export type Project = z.infer<typeof ProjectSchema>;