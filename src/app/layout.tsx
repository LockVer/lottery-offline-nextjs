"use client";
import { Geist, Geist_Mono } from "next/font/google";
import "@/styles/globals.css";
import { I18nProvider } from "@/lib/i18n/i18n-provider";
import { TanstackProvider } from "@/lib/tanstack-query/tanstack-provider";
import { DatabaseProvider } from "@/lib/database/database-provider";
import { Toaster } from "sonner";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <DatabaseProvider>
          <TanstackProvider>
            <I18nProvider>{children}</I18nProvider>
            <Toaster />
          </TanstackProvider>
        </DatabaseProvider>
      </body>
    </html>
  );
}
