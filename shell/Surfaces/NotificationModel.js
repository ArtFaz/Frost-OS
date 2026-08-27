function firstValue(value, keys, fallback) {
    for (let index = 0; index < keys.length; index++) {
        if (value[keys[index]] !== undefined && value[keys[index]] !== null)
            return value[keys[index]];
    }
    return fallback;
}

function flatten(value, output, active) {
    if (Array.isArray(value)) {
        for (let index = 0; index < value.length; index++)
            flatten(value[index], output, active);
        return;
    }
    if (!value || typeof value !== "object")
        return;
    const summary = firstValue(value, ["summary", "title"], "");
    const body = firstValue(value, ["body", "message"], "");
    const id = Number(firstValue(value, ["id", "notification-id", "notification_id"], 0));
    if (summary || body || id > 0) {
        output.push({
            id: isFinite(id) ? id : 0,
            app: String(firstValue(value, ["app-name", "app_name", "appName", "app"], "System")),
            summary: String(summary || "Notification"),
            body: String(body || "").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim(),
            active: active === true
        });
        return;
    }
    const keys = Object.keys(value);
    for (let index = 0; index < keys.length; index++)
        flatten(value[keys[index]], output, active);
}

function normalize(payload) {
    if (!payload || payload.schemaVersion !== 1)
        return [];
    const output = [];
    flatten(payload.active, output, true);
    flatten(payload.history, output, false);
    const seen = {};
    return output.filter(item => {
        const key = item.id + "|" + item.app + "|" + item.summary + "|" + item.body;
        if (seen[key])
            return false;
        seen[key] = true;
        return true;
    }).slice(0, 100);
}

if (typeof module !== "undefined")
    module.exports = {normalize: normalize};
