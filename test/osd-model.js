const assert = require("node:assert/strict")
const model = require("../shell/Osd/OsdModel.js")

const volume = model.stateForPayload(JSON.stringify({
  icon: "volume",
  value: 57,
  max: 100,
  duration: 1200
}))
assert.equal(volume.label, "VOL")
assert.equal(volume.percent, 57)
assert.equal(volume.duration, 1200)

const clamped = model.stateForPayload(JSON.stringify({
  icon: "brightness",
  value: 150,
  max: 100
}))
assert.equal(clamped.label, "SUN")
assert.equal(clamped.percent, 100)

assert.equal(model.stateForPayload("not-json"), null)
assert.equal(model.stateForPayload(JSON.stringify({ icon: "volume", command: "no" })), null)
assert.equal(model.stateForPayload(JSON.stringify({ icon: "volume", duration: 5001 })), null)
assert.equal(model.stateForPayload(JSON.stringify({ icon: "volume", max: 0 })), null)
assert.equal(model.stateForPayload(JSON.stringify({ icon: "x".repeat(33) })), null)

process.stdout.write("osd model: ok\n")
