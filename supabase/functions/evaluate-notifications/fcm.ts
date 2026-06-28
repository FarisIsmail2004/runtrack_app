// FCM HTTP v1 message builder + sender. The access token is obtained by the
// caller (index.ts) from the service-account credential.

export function buildFcmMessage(
  token: string, title: string, body: string, data: Record<string, string>,
): object {
  return {
    message: {
      token,
      notification: { title, body },
      data,
      android: { priority: "high" },
    },
  };
}

export function makeFcmSender(projectId: string, accessToken: string) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  return async (
    token: string, title: string, body: string, data: Record<string, string>,
  ): Promise<boolean> => {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(buildFcmMessage(token, title, body, data)),
    });
    if (!res.ok) {
      console.error(`FCM send failed ${res.status}: ${await res.text()}`);
      return false;
    }
    return true;
  };
}
