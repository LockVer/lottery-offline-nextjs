"use client";

import i18n from 'i18next';
import { I18nextProvider, initReactI18next } from "react-i18next";
import { ReactNode, useEffect, useState } from "react";
import LanguageDetector from 'i18next-browser-languagedetector';
import en from "./locale/en.json"
import zh from "./locale/zh.json"

const resources = {
  en: {
    translation: en
  },
  zh: {
    translation: zh
  }
}

const i18nInstance = i18n.createInstance();

i18nInstance
  .use(initReactI18next)
  .init({
    debug: false,
    fallbackLng: "en",
    lng: "en",
    interpolation: {
      escapeValue: false,
    },
    resources,
    detection: {
      order: ['localStorage', 'cookie', 'navigator'],
    },
  });

if (typeof window !== 'undefined') {
  i18nInstance.use(LanguageDetector);
}

interface I18nProviderProps {
  children: ReactNode;
}

export function I18nProvider({ children }: I18nProviderProps) {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    
    if (typeof window !== 'undefined') {
      const detectedLng = localStorage.getItem('i18nextLng') || navigator.language;
      if (detectedLng) {
        i18nInstance.changeLanguage(detectedLng);
      }
    }
  }, []);

  return <I18nextProvider i18n={i18nInstance}>{isClient ? children : children}</I18nextProvider>;
}
