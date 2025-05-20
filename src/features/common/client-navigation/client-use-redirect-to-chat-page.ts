"use client";

import { useRouter } from "next/navigation";
import { useCallback } from "react";

export const useRedirectToChatThread = () => {
  const router = useRouter();
  const callback = (chatThreadId: string, refresh = true) => {
    router.push(`/chat/${chatThreadId}`);
    if (refresh) {
      router.refresh();
    }
  };
  return useCallback(callback, [router]);
};
