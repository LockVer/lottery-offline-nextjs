"use client";

import { useForm } from "react-hook-form";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { open } from "@tauri-apps/plugin-dialog";
import { useRouter } from "next/navigation";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { importProjectMutationOptions } from "../../../(api)/project/query";
import { toast } from "sonner";

interface FormValues {
  name: string;
  path: string;
}

export default function ImportProjectPage() {
  const { register, handleSubmit, setValue, watch } = useForm<FormValues>({
    defaultValues: { name: "", path: "" },
  });
  const queryClient = useQueryClient();
  const router = useRouter();

  const { mutateAsync, isPending } = useMutation(importProjectMutationOptions);

  const onSelectFile = async () => {
    const selected = await open({
      title: "选择 dat 文件",
      filters: [{ name: "dat", extensions: ["dat"] }],
    });
    if (typeof selected === "string") {
      setValue("path", selected);
      if (!watch("name")) {
        // 默认项目名用文件名
        const fname =
          selected
            .split(/[/\\]/)
            .pop()
            ?.replace(/\.dat$/i, "") || "";
        setValue("name", fname);
      }
    }
  };

  const onSubmit = async (data: FormValues) => {
    if (!data.path) {
      toast.error("请选择 CSV 文件");
      return;
    }
    try {
      await mutateAsync({ path: data.path, name: data.name });
      toast.success("导入成功");
      queryClient.invalidateQueries({ queryKey: ["project-list"] });
      router.push("/project");
    } catch (e: any) {
      toast.error(e.toString());
    }
  };

  return (
    <div className="flex flex-col gap-4 p-4 max-w-lg mx-auto">
      <h1 className="text-3xl font-bold tracking-tight">Import CSV</h1>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div className="space-y-2">
          <label className="block text-sm font-medium">Project Name</label>
          <Input
            {...register("name", { required: true })}
            placeholder="June Lottery Batch"
          />
        </div>
        <div className="space-y-2">
          <label className="block text-sm font-medium">CSV File</label>
          <div className="flex gap-2">
            <Input value={watch("path")} readOnly placeholder="请选择文件" />
            <Button type="button" variant="outline" onClick={onSelectFile}>
              Browse
            </Button>
          </div>
        </div>
        <Button type="submit" disabled={isPending || !watch("path")}>
          Import
        </Button>
      </form>
    </div>
  );
}
