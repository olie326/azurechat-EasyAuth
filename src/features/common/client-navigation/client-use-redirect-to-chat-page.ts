"use client"

import { useRouter } from "next/navigation";
import { useCallback } from "react";

export const useRedirectToChatThread = () => {
    const router = useRouter();
    const callback = (chatThreadId: string, refresh = true) => {
        if (refresh) {
            router.refresh();
        }
        router.push(`/chat/${chatThreadId}`);
    }
    return useCallback(callback, [router]);
};
