function exactKeys(object, allowed) {
  if (object === null || typeof object !== "object" || Array.isArray(object)) return false
  const keys = Object.keys(object)
  for (let index = 0; index < keys.length; index++) {
    if (allowed.indexOf(keys[index]) === -1) return false
  }
  return true
}

function boundedString(value, maxLength) {
  return typeof value === "string" && value.length <= maxLength
}

function parsePayload(raw) {
  if (typeof raw !== "string" || raw.length === 0 || raw.length > 4096) return null

  let payload
  try {
    payload = JSON.parse(raw)
  } catch (error) {
    return null
  }

  if (!exactKeys(payload, ["icon", "message", "value", "max", "duration"])) return null
  if (!boundedString(payload.icon || "", 32)) return null
  if (!boundedString(payload.message || "", 120)) return null

  const max = payload.max === undefined ? 100 : Number(payload.max)
  const value = payload.value === undefined ? 0 : Number(payload.value)
  const duration = payload.duration === undefined ? 1200 : Number(payload.duration)
  if (!isFinite(max) || max <= 0 || max > 100000) return null
  if (!isFinite(value)) return null
  if (!Number.isInteger(duration) || duration < 0 || duration > 5000) return null

  return {
    icon: payload.icon || "status",
    message: payload.message || "",
    value: Math.max(0, Math.min(max, value)),
    max: max,
    duration: duration
  }
}

function labelFor(icon) {
  switch (icon) {
    case "volume-muted": return "MUTE"
    case "volume": return "VOL"
    case "brightness": return "SUN"
    default: return "FROST"
  }
}

function stateForPayload(raw) {
  const payload = parsePayload(raw)
  if (payload === null) return null
  return {
    icon: payload.icon,
    label: labelFor(payload.icon),
    message: payload.message,
    value: payload.value,
    max: payload.max,
    percent: Math.round(payload.value * 100 / payload.max),
    duration: payload.duration
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    exactKeys: exactKeys,
    parsePayload: parsePayload,
    labelFor: labelFor,
    stateForPayload: stateForPayload
  }
}
