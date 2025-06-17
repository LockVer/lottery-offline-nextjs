import { z } from "zod";

export const RedemptionSchema = z.object({
  id: z.number(),
  ticket_id: z.number(),
  redeemed_at: z.string(),
});

export type Redemption = z.infer<typeof RedemptionSchema>;