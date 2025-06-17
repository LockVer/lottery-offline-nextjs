"use client";

import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Check, ChevronDown, Globe } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export function LocaleSwitcher() {
  const { i18n } = useTranslation();
  const [mounted, setMounted] = useState(false);
  
  // 语言列表
  const languages = [
    { code: "en", label: "English" },
    { code: "zh", label: "中文" }
  ];

  // 确保组件挂载后渲染，避免hydration问题
  useEffect(() => {
    setMounted(true);
  }, []);

  // 切换语言
  const changeLanguage = (lng: string) => {
    void i18n.changeLanguage(lng);
  };

  // 判断当前语言是否匹配给定代码（支持 zh-CN, en-US 等）
  const langMatches = (code: string) => i18n.language?.startsWith(code);

  // 获取当前语言标签（如果找不到则返回第一个语言）
  const getCurrentLanguageLabel = () => {
    const current = languages.find(lang => langMatches(lang.code));
    return current?.label || languages[0].label;
  };

  // 不渲染直到挂载后，避免hydration问题
  if (!mounted) return null;

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="sm" className="flex items-center gap-2">
          <Globe className="h-4 w-4" />
          <span>{getCurrentLanguageLabel()}</span>
          <ChevronDown className="h-3 w-3 opacity-50" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {languages.map((lang) => (
          <DropdownMenuItem
            key={lang.code}
            onClick={() => changeLanguage(lang.code)}
            className="flex items-center justify-between"
          >
            <span>{lang.label}</span>
            {langMatches(lang.code) && (
              <Check className="h-4 w-4 ml-2" />
            )}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}