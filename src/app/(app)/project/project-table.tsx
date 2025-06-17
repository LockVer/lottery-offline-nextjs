"use client";

import * as React from "react";
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { ChevronDown } from "lucide-react";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Project } from "@/types/project";
import { useTranslation } from "react-i18next";
import { deleteProjectMutationOption } from "@/app/(api)/project/query";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Progress } from "@/components/ui/progress";
import { toast } from "sonner";

export function actionsGroup(id: number) {
  const { t } = useTranslation();
  const { mutate } = useMutation(deleteProjectMutationOption);
  const queryClient = useQueryClient();
  const onDeleteProject = () => {
    mutate({ id }, {
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ["project-list"] });
        toast.success("删除成功");
      },
      onError: (e) => {
        toast.error(e.toString());
      }
    });
  };
  return (
    <div className="flex gap-2">



      <Button variant="link" className="p-0 h-4 leading-0">
        <p>{t("page.project.exportExemptions")}</p>
      </Button>
      <Button
        variant="link"
        className="p-0 h-4 leading-0 text-red-500"
        onClick={onDeleteProject}
      >
        <p>{t("page.project.delete")}</p>
      </Button>
    </div>
  );
}

export function projectColumns(
  t: (key: string) => string
): ColumnDef<Project>[] {
  return [
    {
      accessorKey: "name",
      header: t("page.project.name"),
      cell: ({ row }) => (
        <Link
          href={`/project/detail?id=${row.original.id}`}
          className="font-medium underline-offset-2 hover:underline"
        >
          {row.getValue("name")}
        </Link>
      ),
    },
    {
      accessorKey: "redeemed_tickets",
      header: t("page.project.redeemed_tickets"),
      cell: ({ row }) => row.getValue("redeemed_tickets"),
    },
    {
      accessorKey: "total_tickets",
      header: t("page.project.total_tickets"),
      cell: ({ row }) => row.getValue("total_tickets"),
    },
    {
      accessorKey: "redeemed_progress_bar",
      header: t("page.project.redeemed_progress_bar"),
      cell: ({ row }) => {
        const percentage =
          row.original.total_tickets > 0
            ? (row.original.redeemed_tickets / row.original.total_tickets) * 100
            : 0;

        return (
          <div className="flex flex-row gap-2 items-center max-w-fit">
            <Progress className="h-2 w-[200px]" value={percentage} />{" "}
            <span className="italic">{percentage.toFixed(2)}%</span>
          </div>
        );
      },
    },
    { 
      accessorKey: "created_at",
      header: t("page.project.created_at"),
      cell: ({ row }) => new Date(row.getValue("created_at")).toLocaleString(),
    },
    {
      accessorKey: "updated_at",
      header: t("page.project.updated_at"),
      cell: ({ row }) => new Date(row.getValue("updated_at")).toLocaleString(),
    },
    {
      accessorKey: "actions",
      header: t("page.project.actions"),
      cell: ({ row }) => actionsGroup(row.original.id),
    },
  ];
}

interface ProjectTableProps {
  data: Project[];
}

export function ProjectTable({ data }: ProjectTableProps) {
  const { t } = useTranslation();
  const columns = React.useMemo(() => projectColumns(t), [t]);
  const [sorting, setSorting] = React.useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>(
    []
  );
  const [columnVisibility, setColumnVisibility] =
    React.useState<VisibilityState>({});
  const [rowSelection, setRowSelection] = React.useState({});

  const table = useReactTable({
    data,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    onColumnVisibilityChange: setColumnVisibility,
    onRowSelectionChange: setRowSelection,
    state: {
      sorting,
      columnFilters,
      columnVisibility,
      rowSelection,
    },
  });

  return (
    <div className="w-full">
      <div className="flex items-center py-2 gap-2">
        <Input
          placeholder={t("page.project.filterPlaceholder")}
          value={(table.getColumn("name")?.getFilterValue() as string) ?? ""}
          onChange={(event) =>
            table.getColumn("name")?.setFilterValue(event.target.value)
          }
          className="max-w-sm"
        />
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" className="ml-auto">
              {t("page.project.columns")}{" "}
              <ChevronDown className="ml-2 h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            {table
              .getAllColumns()
              .filter((column) => column.getCanHide())
              .map((column) => (
                <DropdownMenuCheckboxItem
                  key={column.id}
                  className="capitalize"
                  checked={column.getIsVisible()}
                  onCheckedChange={(value) => column.toggleVisibility(!!value)}
                >
                  {t(`page.project.${column.id}`)}
                </DropdownMenuCheckboxItem>
              ))}
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && "selected"}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  {t("page.project.noResults")}
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-end space-x-2 py-4">
        <div className="space-x-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
          >
            {t("page.project.previous")}
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
          >
            {t("page.project.next")}
          </Button>
        </div>
      </div>
    </div>
  );
}
