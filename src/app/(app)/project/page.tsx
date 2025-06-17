"use client";

import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Button } from "@/components/ui/button";

import { listProjectsQueryOptions } from "../../(api)/project/query";
import { ProjectTable } from "@/app/(app)/project/project-table";
import type { Project } from "@/types/project";
import { useTranslation } from "react-i18next";

export default function ProjectPage() {
  const { t } = useTranslation();
  const {
    data: projects,
    isLoading,
    isError,
  } = useQuery<Project[]>(listProjectsQueryOptions);

  const hasProjects = (projects?.length ?? 0) > 0;

  return (
    <section className="flex flex-col flex-1 gap-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">{t("page.project.title")}</h1>
        <Link href="/project/import">
          <Button size="sm">{t("page.project.importCsv")}</Button>
        </Link>
      </div>

      {isLoading ? (
        <div className="flex flex-1 items-center justify-center">{t("page.project.loading")}</div>
      ) : isError || !projects ? (
        <div className="flex flex-1 items-center justify-center text-red-500">
          {t("page.project.loadFailed")}
        </div>
      ) : hasProjects ? (
        <ProjectTable data={projects} />
      ) : (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 text-center">
          <p className="text-muted-foreground">{t("page.project.noProjects")}</p>
          <Link href="/project/import">
            <Button>{t("page.project.noProjectsImportCsv")}</Button>
          </Link>
        </div>
      )}
    </section>
  );
}
