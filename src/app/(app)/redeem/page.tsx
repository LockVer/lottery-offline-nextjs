"use client";

import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { toast } from "sonner";
import { useTranslation } from "react-i18next";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  getTodayRedemptionQueryOption,
  redeemTicketMutationOption,
} from "@/app/(api)/redeem/query";
import { GetTodayRedemptionResponse } from "@/app/(api)/redeem/type";
import { MoreHorizontal } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const RedeemResultArea = ({ lastWinning }: { lastWinning: string | null }) => {
  const { t } = useTranslation();
  return (
    <div className="flex items-center justify-center min-h-[120px] border rounded-md">
      {lastWinning === null ? (
        <p className="text-muted-foreground text-3xl italic">
          {t("page.redeem.waiting")}
        </p>
      ) : lastWinning === "" ||
        lastWinning === "0" ||
        lastWinning === "false" ? (
        <p className="text-muted-foreground text-3xl italic">
          {t("page.redeem.notWinning")}
        </p>
      ) : (
        <p className="text-green-600 text-3xl italic">
          {t("page.redeem.winning", { prize: lastWinning })}
        </p>
      )}
    </div>
  );
};

type SortField = "project_name" | "redeemed_at" | "prize";
type SortDirection = "asc" | "desc";

const DailyRedemptionRecordArea = ({
  records,
}: {
  records: GetTodayRedemptionResponse;
}) => {
  const { t } = useTranslation();
  const [sortField, setSortField] = useState<SortField>("redeemed_at");
  const [sortDirection, setSortDirection] = useState<SortDirection>("desc");

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortDirection("asc");
    }
  };

  const sortedRecords = [...records].sort((a, b) => {
    let comparison = 0;

    if (sortField === "project_name") {
      comparison = a.project_name.localeCompare(b.project_name);
    }
    if (sortField === "redeemed_at") {
      comparison =
        new Date(a.redeemed_at).getTime() - new Date(b.redeemed_at).getTime();
    }
    if (sortField === "prize") {
      const prizeA = a.prize && a.prize !== "0" ? Number(a.prize) || 0 : 0;
      const prizeB = b.prize && b.prize !== "0" ? Number(b.prize) || 0 : 0;
      comparison = prizeA - prizeB;
    }

    return sortDirection === "asc" ? comparison : -comparison;
  });

  const SortableHeader = ({
    field,
    label,
  }: {
    field: SortField;
    label: string;
  }) => (
    <TableHead className="cursor-pointer" onClick={() => handleSort(field)}>
      <div className="flex items-center">
        {label}
        {sortField === field && (
          <>
            <span className="ml-1 text-xs">
              {sortDirection === "asc" ? "↑" : "↓"}
            </span>
          </>
        )}
      </div>
    </TableHead>
  );

  return (
    <div className="flex-1 overflow-auto border rounded-md">
      <Table>
        <TableHeader>
          <TableRow>
            <SortableHeader
              field="project_name"
              label={t("redeem.project", { defaultValue: "Project" })}
            />
            <SortableHeader
              field="redeemed_at"
              label={t("redeem.time", { defaultValue: "Time" })}
            />
            <SortableHeader
              field="prize"
              label={t("redeem.prize", { defaultValue: "Prize" })}
            />
            <TableHead className="w-[40px]"></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {sortedRecords.length === 0 ? (
            <TableRow>
              <TableCell colSpan={4} className="text-center py-8">
                {t("redeem.noRecords", { defaultValue: "No records today" })}
              </TableCell>
            </TableRow>
          ) : (
            sortedRecords.map((record, idx) => (
              <TableRow key={idx}>
                <TableCell>{record.project_name}</TableCell>
                <TableCell>
                  {new Date(record.redeemed_at).toLocaleTimeString()}
                </TableCell>
                <TableCell
                  className={
                    record.prize && record.prize !== "0"
                      ? "text-green-400 font-bold"
                      : "text-muted-foreground"
                  }
                >
                  {record.prize && record.prize !== "0"
                    ? record.prize
                    : t("redeem.notWinning", { defaultValue: "No Prize" })}
                </TableCell>
                <TableCell>
                  <TooltipProvider>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button size="icon" variant="ghost" className="h-4 w-4 p-0 flex items-center">
                          <span className="sr-only">Open menu</span>
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <DropdownMenuItem>
                              <div className="flex items-center justify-between w-full">
                                <span className="text-muted-foreground">
                                  {t("redeem.securityCode", {
                                    defaultValue: "Security Code",
                                  })}
                                </span>
                                <span className="ml-4 text-right font-mono">
                                  {record.security_code}
                                </span>
                              </div>
                            </DropdownMenuItem>
                          </TooltipTrigger>
                          <TooltipContent>
                            <p>
                              {t("redeem.securityCode", {
                                defaultValue: "Security Code",
                              })}
                            </p>
                          </TooltipContent>
                        </Tooltip>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <DropdownMenuItem>
                              <div className="flex items-center justify-between w-full">
                                <span className="text-muted-foreground">
                                  {t("redeem.manualCode", {
                                    defaultValue: "Manual Code",
                                  })}
                                </span>
                                <span className="ml-4 text-right font-mono">
                                  {record.manual_code}
                                </span>
                              </div>
                            </DropdownMenuItem>
                          </TooltipTrigger>
                          <TooltipContent>
                            <p>
                              {t("redeem.manualCode", {
                                defaultValue: "Manual Code",
                              })}
                            </p>
                          </TooltipContent>
                        </Tooltip>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TooltipProvider>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );
};

export default function RedeemPage() {
  const { t } = useTranslation();
  const [code, setCode] = useState("");
  const [lastWinning, setLastWinning] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);

  const getRedemptionRecord = useQuery(getTodayRedemptionQueryOption);
  const redeemTicket = useMutation(redeemTicketMutationOption);
  const queryClient = useQueryClient();

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  /**
   * 清空输入框并重新聚焦
   */
  const clear = () => {
    setCode("");
    inputRef.current?.focus();
  };

  /**
   * 判断字符串是否为ASCII码格式并转换为UTF-8字符
   * @param input 输入的字符串
   * @returns 转换后的字符串
   */
  const convertAsciiToUtf8 = (input: string): string => {
    // 移除空格并检查是否为纯数字
    const trimmedInput = input.trim();
    
    // 检查是否为连续的数字（可能是ASCII码）
    if (/^\d+$/.test(trimmedInput)) {
      try {
        // 如果是2-3位数字，可能是单个ASCII码
        if (trimmedInput.length >= 2 && trimmedInput.length <= 3) {
          const asciiCode = parseInt(trimmedInput, 10);
          if (asciiCode >= 32 && asciiCode <= 126) { // 可打印ASCII字符范围
            const convertedChar = String.fromCharCode(asciiCode);
            console.log(`ASCII码转换: ${asciiCode} -> ${convertedChar}`);
            return convertedChar;
          }
        }
        
        // 如果是更长的数字串，尝试按每2-3位分割并转换
        const chars: string[] = [];
        let i = 0;
        while (i < trimmedInput.length) {
          // 优先尝试3位数字
          if (i + 3 <= trimmedInput.length) {
            const threeDigit = trimmedInput.substring(i, i + 3);
            const code = parseInt(threeDigit, 10);
            if (code >= 100 && code <= 126) {
              chars.push(String.fromCharCode(code));
              i += 3;
              continue;
            }
          }
          
          // 然后尝试2位数字
          if (i + 2 <= trimmedInput.length) {
            const twoDigit = trimmedInput.substring(i, i + 2);
            const code = parseInt(twoDigit, 10);
            if (code >= 32 && code <= 99) {
              chars.push(String.fromCharCode(code));
              i += 2;
              continue;
            }
          }
          
          // 如果都不匹配，跳过当前字符
          i++;
        }
        
        if (chars.length > 0) {
          const convertedString = chars.join('');
          console.log(`ASCII码序列转换: ${trimmedInput} -> ${convertedString}`);
          return convertedString;
        }
      } catch (error) {
        console.error('ASCII码转换失败:', error);
      }
    }
    
    // 如果不是ASCII码格式或转换失败，返回原始输入
    return input;
  };

  /**
   * 执行兑奖操作
   */
  const redeem = async () => {
    // 检查并转换ASCII码
    const processedCode = convertAsciiToUtf8(code);
    console.log("processedCode", processedCode);
    redeemTicket.mutate(processedCode, {
      onSuccess: (prize: string | null) => {
        clear();
        toast.success("兑换成功");
        queryClient.invalidateQueries({ queryKey: ["today-redemption", "project-list"] });
        setLastWinning(prize);
      },
      onError: (e) => {
        toast.error(e.toString());
        clear();
      },
    });
  };

  const handleKey: React.KeyboardEventHandler<HTMLInputElement> = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      redeem();
    } else if (e.key === "Delete" || e.key === "Backspace") {
      if (code.length === 0) {
        e.preventDefault();
        clear();
      }
    }
  };

  return (
    <section className="flex flex-col h-full p-4 gap-6">
      {/* Top input + result */}
      <div className="flex gap-6 items-start flex-wrap">
        <div className="flex flex-row gap-4 w-full items-stretch">
          <Input
            ref={inputRef}
            placeholder={t("redeem.placeholder", {
              defaultValue: "Scan or Enter code",
            })}
            value={code}
            onChange={(e) => setCode(e.target.value)}
            onKeyDown={handleKey}
            className="text-xl py-6"
          />
          <div className="flex gap-2 h-fill">
            <Button className="h-full" onClick={redeem}>
              {t("redeem.redeem", { defaultValue: "Redeem" })}
              <kbd className="bg-muted text-muted-foreground pointer-events-none inline-flex h-5 items-center gap-1 rounded border px-1.5 font-mono text-[10px] font-medium opacity-100 select-none">
                <span className="text-xs">Enter</span>
              </kbd>
            </Button>
            <Button className="h-full" variant="outline" onClick={clear}>
              {t("redeem.clear", { defaultValue: "Clear" })}
              <kbd className="text-muted-foreground pointer-events-none inline-flex h-5 items-center gap-1 rounded border px-1.5 font-mono text-[10px] font-medium opacity-100 select-none">
                <span className="text-xs">Del</span>
              </kbd>
            </Button>
          </div>
        </div>
      </div>

      {/* Winning indicator */}
      <RedeemResultArea lastWinning={lastWinning?.toString() ?? null} />
      {/* Daily record */}
      {getRedemptionRecord.isLoading ? (
        <div className="flex-1 flex items-center justify-center border rounded-md p-8">
          <p className="text-muted-foreground">
            {t("common.loading", { defaultValue: "Loading..." })}
          </p>
        </div>
      ) : getRedemptionRecord.isError ? (
        <div className="flex items-center justify-center border rounded-md p-8">
          <p className="text-red-500">
            {t("common.error", { defaultValue: "Error loading records" })}
          </p>
        </div>
      ) : (
        <DailyRedemptionRecordArea records={getRedemptionRecord.data || []} />
      )}
    </section>
  );
}
