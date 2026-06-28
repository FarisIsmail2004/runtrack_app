import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildFcmMessage } from "./fcm.ts";

Deno.test("buildFcmMessage: v1 shape with data strings", () => {
  const msg = buildFcmMessage("tok123", "Hi", "There", { type: "streak" });
  assertEquals(msg, {
    message: {
      token: "tok123",
      notification: { title: "Hi", body: "There" },
      data: { type: "streak" },
      android: { priority: "high" },
    },
  });
});
