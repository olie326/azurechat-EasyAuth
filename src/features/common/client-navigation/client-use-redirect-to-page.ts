"use client"

import { useRouter } from "next/navigation";
import { useCallback } from "react";

type Page = "extensions" | "persona" | "prompt" | "chat" | "settings";

export const useRedirectToPage = () => {
    const router = useRouter();
    const callback = (path: Page, refresh = true) => {
        if (refresh) {
            router.refresh();
        }
        router.push(`/${path}`);
    }
    return useCallback(callback, [router]);
};
