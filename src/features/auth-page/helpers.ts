import { createHash } from "crypto";
import { getServerSession } from "next-auth";
import { RedirectToPage } from "../common/navigation-helpers";
import { options } from "./auth-api";
import { headers } from "next/headers";

export const userSession = async (): Promise<UserModel | null> => {
  const user = await getUser();
  if (user) {
    return {
      name: user.name!,
      image: user.image!,
      email: user.email!,
      isAdmin: user.isAdmin!,
    };
  }

  return null;
};

export const getServerUser = async (): Promise<UserModel> => {
  const header = headers();

  const principal = header.get("x-ms-client-principal");
  if (!principal) {
    console.log("getServerUser Error: No x-ms-client-principal header");
    throw new Error("Unauthorized: No x-ms-client-principal header");
  }
  const user = decodePrincipalHeader(principal as string);
  return user as UserModel;
}

export const getUser = async (): Promise<UserModel | null> => {
  try {
    const res = await fetch("/api/auth/me",
      {
        method: "GET",
        credentials: "include", 
        headers: {
          "Content-Type": "application/json",
      }
    });
    if (!res.ok) {
      console.log("getUser Error: ", res);
      throw new Error("Failed to fetch user data");
    }
    const data = await res.json();
    console.log("User data:", data);
    return {
      name: data.name,
      image: data.image,
      email: data.email,
      isAdmin: data.isAdmin,
    } as UserModel;
  } catch (error) {
    console.log("getUser Error: ", error);
    return null;
  }
};

export const getCurrentUser = async (): Promise<UserModel> => {
  const user = await getServerUser();
  if (user) {
    return user;
  }
  throw new Error("getCurrentUser: User not found");
};

export const userHashedId = async (): Promise<string> => {
  const user = await getServerUser();
  if (user) {
    return hashValue(user.email);
  }

  throw new Error("userHashedId: User not found");
};

export const hashValue = (value: string): string => {
  const hash = createHash("sha256");
  hash.update(value);
  return hash.digest("hex");
};

export const redirectIfAuthenticated = async () => {
  const user = await getServerUser();
  console.log("User in redirectIfAuthenticated:", user);
  if (user) {
    RedirectToPage("chat");
  }
};

export const decodePrincipalHeader = (header: string): UserModel => {
  const principalData = JSON.parse(
        Buffer.from(header, "base64").toString("utf-8")
    )['claims'];

    const claimsMap = {
        'name': 'name',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress': 'email',
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'isAdmin'
    }

    const userData = principalData.reduce((acc: any, claim: claim) => {
        const key = claim.typ as keyof typeof claimsMap;
        if (!key) return acc;

        if (key === 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role') {
            if(claim.val === 'admin') {
                acc[claimsMap[key]] = true
            }
        } else {
            acc[claimsMap[key]] = claim.val
        }
        return acc;
    }, {});
    
    return {
        name: userData['name'] ?? 'name',
        email: userData['email'] ?? 'email',
        image: '', 
        isAdmin: userData['isAdmin'] ?? false
    } as UserModel

}

export type UserModel = {
  name: string;
  image: string;
  email: string;
  isAdmin: boolean;
};

export type claim = {
    typ: string;
    val: string;
}