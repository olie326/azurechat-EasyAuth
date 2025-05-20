"use client";

import { useRouter } from "next/navigation";
import { useCallback } from "react";

type Page = "extensions" | "persona" | "prompt" | "chat" | "settings";

export const useRedirectToPage = () => {
  const router = useRouter();
  const callback = (path: Page, refresh = true) => {
    router.push(`/${path}`);
    if (refresh) {
      router.refresh();
    }
  };
  return useCallback(callback, [router]);
};
