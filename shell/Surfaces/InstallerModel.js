function validateInventory(value) {
    if (!value || value.schemaVersion !== 1 || !Array.isArray(value.items))
        return [];
    const ids = {};
    const output = [];
    for (let index = 0; index < value.items.length; index++) {
        const item = value.items[index];
        if (!item || typeof item.id !== "string" || !/^[a-z0-9-]+$/.test(item.id) || ids[item.id])
            continue;
        if (typeof item.name !== "string" || typeof item.summary !== "string" || typeof item.category !== "string")
            continue;
        if (["arch", "frost", "aur"].indexOf(item.source) < 0 || typeof item.package !== "string" || !/^[a-z0-9@._+-]+$/.test(item.package))
            continue;
        ids[item.id] = true;
        output.push(item);
    }
    return output;
}

function planFor(items, selected) {
    const packages = [];
    const counts = {arch: 0, frost: 0, aur: 0};
    for (let index = 0; index < items.length; index++) {
        const item = items[index];
        if (!selected[item.id])
            continue;
        packages.push({id: item.id, package: item.package, source: item.source});
        counts[item.source]++;
    }
    return {schemaVersion: 1, packages: packages, counts: counts};
}

if (typeof module !== "undefined")
    module.exports = {validateInventory: validateInventory, planFor: planFor};
