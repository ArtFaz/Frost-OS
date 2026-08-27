const assert = require("node:assert/strict");
const installer = require("../shell/Surfaces/InstallerModel.js");
const notifications = require("../shell/Surfaces/NotificationModel.js");

const inventory = installer.validateInventory({
  schemaVersion: 1,
  items: [
    {id: "editor", name: "Editor", summary: "Text", category: "Work", source: "arch", package: "editor"},
    {id: "editor", name: "Duplicate", summary: "Bad", category: "Work", source: "aur", package: "duplicate"},
    {id: "bad", name: "Bad", summary: "Bad", category: "Work", source: "remote", package: "bad"}
  ]
});
assert.equal(inventory.length, 1);
const plan = installer.planFor(inventory, {editor: true});
assert.deepEqual(plan.counts, {arch: 1, frost: 0, aur: 0});
assert.deepEqual(plan.packages, [{id: "editor", package: "editor", source: "arch"}]);

const rows = notifications.normalize({
  schemaVersion: 1,
  active: [{id: 7, "app-name": "Mail", summary: "Hello", body: "<b>World</b>"}],
  history: {groups: [[{id: 7, "app-name": "Mail", summary: "Hello", body: "<b>World</b>"}], [{id: 8, app: "System", title: "Done"}]]}
});
assert.equal(rows.length, 2);
assert.equal(rows[0].active, true);
assert.equal(rows[0].body, "World");
assert.equal(rows[1].summary, "Done");

console.log("phase4 models: ok");
