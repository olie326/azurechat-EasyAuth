import { NextRequest, NextResponse } from "next/server";

const requireAdmin: string[] = ["/reporting"];

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  const base64 = request.headers.get("x-ms-client-principal");

  if (pathname === "/") {
  if (base64) {
    const url = request.nextUrl.clone();
    url.pathname = "/chat";
    return NextResponse.redirect(url);
  }
    return NextResponse.next();
  }

  // All other protected routes: require authentication
  if (!base64) {
    return NextResponse.redirect(new URL("/", request.url));
  }

  let user: any = {};
  try {
    user = JSON.parse(atob(base64));
  } catch {
    // malformed header – treat as unauthenticated
    return NextResponse.redirect(new URL("/", origin));
  }

  if (requireAdmin.some((path) => pathname.startsWith(path))) {
    const isAdmin = user?.claims?.some(
      (claim: any) => claim.typ === "role" && claim.val === "admin"
    );

    if (!isAdmin) {
      return NextResponse.redirect(new URL("/unauthorized", request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/",
    "/unauthorized/:path*",
    "/reporting/:path*",
    "/chat/:path*",
    "/api/chat/:path*",
    "/api/images/:path*",
  ],
};
