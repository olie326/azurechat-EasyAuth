"use client";
import { SessionProvider } from "next-auth/react";
import { UserModel } from "../auth-page/helpers";
import { createContext, useContext } from "react";

const UserContext = createContext<UserModel | null>(null);

export const useUser = () => useContext(UserContext);

export const AuthenticatedProviders = ({
  user,
  children,
}: {
  user: UserModel | null;
  children: React.ReactNode;
}) => {
  return <UserContext.Provider value={user}>{children}</UserContext.Provider>;
};
