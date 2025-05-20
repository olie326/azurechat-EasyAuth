import { UserModel, claim, decodePrincipalHeader } from "@/features/auth-page/helpers";

export async function GET(req: Request) {
    console.log('API route hit');
    const headersList = req.headers;
    const principal = headersList.get("x-ms-client-principal");

    if (!principal) {
        return new Response("Unauthorized: No x-ms-client-principal header", { status: 401 });
    }

    const user = decodePrincipalHeader(principal);

    return new Response(JSON.stringify(user), {
        status: 200,
        headers: {
            "Content-Type": "application/json",
        },
    });
}
