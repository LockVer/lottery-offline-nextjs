import { getDatabaseInstance } from "@/lib/database/database-connection";
import { GetTodayRedemptionResponse } from "./type";

export const getTodayRedemptionQueryOption = {
  queryKey: ["today-redemption"],
  queryFn: async () => {
    const db = await getDatabaseInstance();
    const today = new Date();
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
    const startOfTomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1).toISOString();
    
    const res = await db.select<{ security_code: string, manual_code: string, project_name: string, redeemed_at: string, prize: string }[]>(
      `SELECT 
        tickets.security_code,
        tickets.manual_code,
        projects.name as project_name,
        tickets.redeemed_at,
        tickets.prize
      FROM tickets
      JOIN projects ON tickets.project_id = projects.id
      WHERE tickets.redeemed_at >= ? AND tickets.redeemed_at < ?
      ORDER BY tickets.redeemed_at DESC`,
      [startOfToday, startOfTomorrow]
    );
    return res as GetTodayRedemptionResponse;
  }
}

export const redeemTicketMutationOption = {
  mutationFn: async (manual_code: string) => {
    const db = await getDatabaseInstance();
    const ticket = await db.select<{ id: number, prize: string, is_redeemed: number, project_id: number }[]>("SELECT * FROM tickets WHERE manual_code = ? OR security_code = ?", [manual_code, manual_code]);
    if (ticket.length === 0) {
      throw new Error("Ticket not found");
    }
    if (ticket.length > 1) {
      throw new Error("Multiple tickets found, please use security code");
    }

    if (ticket[0].is_redeemed === 1) {
      throw new Error("Ticket already redeemed");
    }

    const ticketId = ticket[0].id;
    const currentTimeStamp = new Date().toISOString();
    await db.execute("UPDATE tickets SET redeemed_at = ?, is_redeemed = 1 WHERE id = ?", [currentTimeStamp, ticketId]);
    await db.execute("UPDATE projects SET redeemed_tickets = redeemed_tickets + 1, updated_at = ? WHERE id = ?", [currentTimeStamp, ticket[0].project_id]);
    return ticket[0].prize;
  }
}