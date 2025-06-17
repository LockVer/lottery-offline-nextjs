"use client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LocaleSwitcher } from "@/lib/i18n/locale-switcher";
import { Label } from "@radix-ui/react-label";

import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";

import { useEffect, useState } from "react";
import Image from "next/image";

import backgroundImage from "@/assets/activate-background.jpg";
import { toast } from "sonner";
import { useMutation, useQuery } from "@tanstack/react-query";
import { activateSoftwareMutationOptions, getMachineCodeQueryOptions } from "../(api)/activate/query";
import { useForm } from "react-hook-form";
import {
  ActivateSoftwareRequest,
  ActivateSoftwareRequestSchema,
} from "../(api)/activate/type";
import { Form, FormField } from "@/components/ui/form";
import { IconTicket } from "@tabler/icons-react";

export default function LoginPage() {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);

  const { data: machineCode } = useQuery(getMachineCodeQueryOptions);
  const activateMutation = useMutation({
    ...activateSoftwareMutationOptions,
    onSuccess: () => {
      toast.success(t("page.activate.activateSuccess"));
      setLoading(false);
    },
    onError: (err: unknown) => {
      console.error(err);
      toast.error(t("page.activate.activateFailed") + ": " + err);
      setLoading(false);
    },
  });

  const form = useForm<ActivateSoftwareRequest>({
    resolver: zodResolver(ActivateSoftwareRequestSchema),
    defaultValues: {
      license: "",
      machineCode: t("page.activate.machineCodeLoading"),
    },
  });

  // 当 machineCode 数据加载完成后，更新表单值
  useEffect(() => {
    if (machineCode) {
      form.setValue("machineCode", machineCode);
    }
  }, [machineCode, form]);

  const handleCopyMachineCode = () => {
    if (machineCode) {
      navigator.clipboard.writeText(machineCode);
      toast.success(t("page.activate.copyMachineCodeSuccess"));
    }
  };

  const onSubmit = (data: ActivateSoftwareRequest) => {
    setLoading(true);
    activateMutation.mutate(data);
  };

  return (
    <div className="grid min-h-svh lg:grid-cols-2">
      <div className="flex flex-col gap-4 p-6 md:p-10">
        {/* Logo */}
        <div className="flex flex-row items-center justify-between w-full gap-2">
          <a href="#" className="flex items-center gap-2 font-medium">
            <div className="bg-primary text-primary-foreground flex size-6 items-center justify-center rounded-md">
              <IconTicket className="size-4" />
            </div>
            {t("meta.softwareName")}
          </a>
          <LocaleSwitcher />
        </div>
        {/* Form */}
        <div className="flex flex-col flex-1 items-center justify-center gap-4">
          <div className="flex flex-col w-full max-w-xs ">
            <h1 className="text-2xl font-bold">
              {t("page.activate.titleRequestActive")}
            </h1>
            <p className="text-muted-foreground text-sm">
              {t("page.activate.descriptionRequestActive")}
            </p>
          </div>
          <Form {...form}>
            <form
              className="w-full max-w-xs flex flex-col gap-6"
              onSubmit={form.handleSubmit(onSubmit)}
            >
              <FormField
                control={form.control}
                name="machineCode"
                render={({ field }) => (
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="machine-code">
                      {t("page.activate.machineCode")}
                    </Label>
                    <div className="flex w-full max-w-sm items-center gap-2">
                      <Input
                        id="machine-code"
                        value={field.value}
                        disabled
                        readOnly
                        className="font-mono"
                      />
                      <Button
                        onClick={handleCopyMachineCode}
                        type="button"
                        variant="outline"
                      >
                        {t("page.activate.copyMachineCode")}
                      </Button>
                    </div>
                  </div>
                )}
              />
              <FormField
                control={form.control}
                name="license"
                render={({ field }) => (
                  <div>
                    <Label htmlFor="license">
                      {t("page.activate.licenseCode")}
                    </Label>
                    <Input
                      id="license"
                      value={field.value}
                      onChange={field.onChange}
                      placeholder={t("page.activate.licenseCodePlaceholder")}
                      className="mt-2"
                      autoComplete="off"
                    />
                  </div>
                )}
              />

              <Button
                type="submit"
                disabled={loading}
                className="w-full"
              >
                {loading ? t("page.activate.submitLoading") : t("page.activate.submit")}
              </Button>
            </form>
          </Form>
        </div>
      </div>
      <div className="bg-muted relative hidden lg:block">
        <Image
          src={backgroundImage}
          alt="Image"
          className="absolute inset-0 h-full w-full object-cover dark:brightness-[0.2] grayscale"
        />
      </div>
    </div>
  );
}
