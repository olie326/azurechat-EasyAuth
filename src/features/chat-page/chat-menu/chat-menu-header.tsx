"use client";
import { useRedirectToChatThread } from "@/features/common/client-navigation/client-use-redirect-to-chat-page";
import {
  createChatAction,
  CreateChatResult,
  CreateChatThread,
} from "../chat-services/chat-thread-service";
import { ChatContextMenu } from "./chat-context-menu";
import { NewChat } from "./new-chat";
import { useFormState } from "react-dom";
import { useEffect } from "react";

const initialState: CreateChatResult | undefined = { ok: false };

export const ChatMenuHeader = () => {
  const RedirectToChatThread = useRedirectToChatThread();

  const [state, formAction] = useFormState<CreateChatResult, FormData>(
    createChatAction,
    initialState
  );
  useEffect(() => {
    if (!state) return;

    if (state.ok) {
      RedirectToChatThread(state.id);
    }
  }, [state, RedirectToChatThread]);

  return (
    <div className="flex p-2 px-3 justify-end">
      <form action={formAction} className="flex gap-2 pr-3">
        <NewChat />
        <ChatContextMenu />
      </form>
    </div>
  );
};
