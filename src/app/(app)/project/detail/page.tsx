"use client";

import { useTranslation } from "react-i18next";
import { useEffect, useState, Suspense } from "react";
import { useDatabase } from "@/lib/database/database-provider";
import { useSearchParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { getProjectByIdQueryOptions } from "@/app/(api)/project/query";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

/**
 * 项目详情内容组件 - 包含useSearchParams的实际内容
 */
function ProjectDetailContent() {
  const { t } = useTranslation();
  const { db } = useDatabase();
  const searchParams = useSearchParams();
  const router = useRouter();
  const projectId = searchParams.get("id");

  if (!projectId) {
    router.push("/project");
    return;
  }

  const {
    data: projectData,
    isLoading,
    isError,
  } = useQuery(getProjectByIdQueryOptions(projectId));

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="flex flex-col gap-2 p-4">
      <section className="flex flex-col flex-1">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold tracking-tight">
            {projectData?.name}
          </h1>
          <Button>重命名</Button>
        </div>
      </section>
      <section className="flex flex-row gap-8">
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle className="text-muted-foreground flex items-center gap-1">
              总数
            </CardTitle>
            <p className="text-2xl font-bold">
              {projectData?.total_tickets?.toLocaleString()}{" "}
              <span className="text-muted-foreground text-sm">Tickets</span>
            </p>
          </CardHeader>
        </Card>
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle className="text-muted-foreground flex items-center gap-1">
              已兑换
            </CardTitle>
            <p className="text-2xl font-bold">
              {projectData?.redeemed_tickets?.toLocaleString()}{" "}
              <span className="text-muted-foreground text-sm">Tickets</span>
            </p>
          </CardHeader>
        </Card>
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle className="text-muted-foreground flex items-center gap-1">
              未兑换
            </CardTitle>
            <p className="text-2xl font-bold">
              {(
                projectData?.total_tickets! - projectData?.redeemed_tickets!
              ).toLocaleString()}{" "}
              <span className="text-muted-foreground text-sm">Tickets</span>
            </p>
          </CardHeader>
        </Card>
      </section>
      <section>{/* 兑奖统计 */}</section>
    </div>
  );
}

/**
 * 项目详情页面 - 使用Suspense包装useSearchParams组件
 */
export default function ProjectDetailPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center p-8">
        <div className="text-muted-foreground">加载中...</div>
      </div>
    }>
      <ProjectDetailContent />
    </Suspense>
  );
}
