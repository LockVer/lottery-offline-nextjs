import { z } from "zod"

export const ActivateSoftwareRequestSchema = z.object({
    license: z.string(),
    machineCode: z.string(),
});

export type ActivateSoftwareRequest = z.infer<typeof ActivateSoftwareRequestSchema>;