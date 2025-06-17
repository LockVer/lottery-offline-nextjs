import { z } from "zod";

export const getTodayRedemptionResponseSchema = z.array(z.object({
  security_code: z.string(),
  manual_code: z.string(),
  project_name: z.string(),
  redeemed_at: z.string(),
  prize: z.string(),
}));

export type GetTodayRedemptionResponse = z.infer<typeof getTodayRedemptionResponseSchema>;

export const redeemTicketResponseSchema = z.object({
  id: z.number(),
});

export type RedeemTicketResponse = z.infer<typeof redeemTicketResponseSchema>;
