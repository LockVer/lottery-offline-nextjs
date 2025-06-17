"use client";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { getSoftwareActivationQueryOptions } from "./(api)/activate/query";

export default function Home() {
  const { data: isSoftwareActivated, isLoading, isPending } = useQuery(getSoftwareActivationQueryOptions);
  const router = useRouter();

  useEffect(() => {
    if (!isPending && !isSoftwareActivated) {
      router.push("/activate");
    }
    if (!isPending && isSoftwareActivated) {
      router.push("/dashboard");
    }
  }, [isPending, isSoftwareActivated, router]);

  if (isPending) return null; // or a spinner component

  return (
    <></>
  )
}
