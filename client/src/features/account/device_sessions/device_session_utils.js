export function formatDeviceCode(value) {
  const compact = value.replace(/ /g, "");
  if (!/^[0-9]*$/.test(compact)) return value;
  const digits = compact.slice(0, 10);
  return digits.length > 5 ? `${digits.slice(0, 5)} ${digits.slice(5)}` : digits;
}

export function parseDeviceQrPayload(value) {
  let payload;
  try {
    payload = JSON.parse(value);
  } catch {
    throw new Error("This is not a valid MyManger sign-in QR code.");
  }
  if (payload?.type !== "mymanager-login" || payload?.version !== 1 || typeof payload.code !== "string" || !/^[0-9]{10}$/.test(payload.code)) {
    throw new Error("This QR code is not a supported MyManger sign-in request.");
  }
  return payload.code;
}

export function formatDeviceDate(value, timezone) {
  try {
    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
      timeZone: timezone || undefined,
    }).format(new Date(value));
  } catch {
    return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
  }
}
