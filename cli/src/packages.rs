//! `frost packages` — validate a package manifest and resolve it into a
//! reviewable plan. This never calls pacman to install or remove anything and
//! never runs an AUR recipe. Its inputs are the selector's `inventory.json` and
//! an exported `frost-packages.json`; its outputs are a verdict, a plan and an
//! optional AUR lockfile.

use crate::{CliError, capture, json_escape};
use std::collections::{BTreeMap, BTreeSet};
use std::fs;

const JQ: &str = "/usr/bin/jq";
const MANIFEST_MAX_BYTES: u64 = 512 * 1024;
const INVENTORY_MAX_BYTES: u64 = 4 * 1024 * 1024;
const NAME_RE: &str = r"^[a-z0-9][a-z0-9@._+-]*$";
const KEY_RE: &str = r"^[a-z][a-z0-9-]*$";

pub(crate) fn packages_command(args: &[String]) -> Result<(), CliError> {
    let Some((sub, rest)) = args.split_first() else {
        return Err(usage());
    };
    match sub.as_str() {
        "validate" => validate_command(rest),
        "plan" => plan_command(rest),
        other => Err(CliError::Usage(format!(
            "unknown packages subcommand: {other}"
        ))),
    }
}

fn usage() -> CliError {
    CliError::Usage(
        "usage:\n  frost packages validate --inventory PATH MANIFEST [--json]\n  \
         frost packages plan --inventory PATH MANIFEST [--json] [--lockfile PATH] [--donor-base PATH]"
            .to_owned(),
    )
}

struct Options {
    inventory: String,
    manifest: String,
    json: bool,
    lockfile: Option<String>,
    donor_base: Option<String>,
}

fn parse_options(args: &[String], allow_plan_flags: bool) -> Result<Options, CliError> {
    let mut inventory = None;
    let mut manifest = None;
    let mut json = false;
    let mut lockfile = None;
    let mut donor_base = None;
    let mut iter = args.iter();
    while let Some(arg) = iter.next() {
        match arg.as_str() {
            "--json" => json = true,
            "--inventory" => {
                inventory = Some(iter.next().ok_or_else(|| usage())?.clone());
            }
            "--lockfile" if allow_plan_flags => {
                lockfile = Some(iter.next().ok_or_else(|| usage())?.clone());
            }
            "--donor-base" if allow_plan_flags => {
                donor_base = Some(iter.next().ok_or_else(|| usage())?.clone());
            }
            value if value.starts_with("--") => return Err(usage()),
            value => {
                if manifest.replace(value.to_owned()).is_some() {
                    return Err(usage());
                }
            }
        }
    }
    Ok(Options {
        inventory: inventory.ok_or_else(|| usage())?,
        manifest: manifest.ok_or_else(|| usage())?,
        json,
        lockfile,
        donor_base,
    })
}

/* --------------------------------------------------------------------------- */
/* Loading                                                                     */
/* --------------------------------------------------------------------------- */

struct InvPkg {
    name: String,
    source: String,
    category: String,
    default_: String,
    feature: Option<String>,
    depends: Vec<String>,
    conflicts: Vec<String>,
    pkgbase: Option<String>,
    recipe_url: Option<String>,
}

struct Feature {
    key: String,
    default_: bool,
    packages: Vec<String>,
}

struct Profile {
    key: String,
    include_categories: Vec<String>,
    include_packages: Vec<String>,
    exclude_packages: Vec<String>,
}

struct Inventory {
    version: String,
    packages: Vec<InvPkg>,
    features: Vec<Feature>,
    profiles: Vec<Profile>,
    index: BTreeMap<String, usize>,
}

impl Inventory {
    fn get(&self, name: &str) -> Option<&InvPkg> {
        self.index.get(name).map(|&i| &self.packages[i])
    }
    fn feature(&self, key: &str) -> Option<&Feature> {
        self.features.iter().find(|f| f.key == key)
    }
    fn profile(&self, key: &str) -> Option<&Profile> {
        self.profiles.iter().find(|p| p.key == key)
    }
}

fn bounded_json_file(path: &str, limit: u64, label: &str) -> Result<(), CliError> {
    let meta = fs::symlink_metadata(path)
        .map_err(|_| CliError::Usage(format!("{label} not found: {path}")))?;
    if !meta.file_type().is_file() {
        return Err(CliError::Usage(format!(
            "{label} is not a regular file: {path}"
        )));
    }
    if meta.len() > limit {
        return Err(CliError::Usage(format!(
            "{label} is larger than {limit} bytes"
        )));
    }
    capture(JQ, &["-e", "type == \"object\"", path])
        .map_err(|_| CliError::Usage(format!("{label} is not a JSON object: {path}")))?;
    Ok(())
}

fn split_list(field: &str) -> Vec<String> {
    if field.is_empty() {
        Vec::new()
    } else {
        field.split(',').map(str::to_owned).collect()
    }
}

fn load_inventory(path: &str) -> Result<Inventory, CliError> {
    bounded_json_file(path, INVENTORY_MAX_BYTES, "inventory")?;
    let filter = concat!(
        r#""V\t" + .inventoryVersion,"#,
        r#"(.packages[] | "P\t" + .name + "\t" + .source + "\t" + .category + "\t" + .default"#,
        r#" + "\t" + (.feature // "") + "\t" + ((.dependsOn // []) | join(","))"#,
        r#" + "\t" + ((.conflictsWith // []) | join(",")) + "\t" + (.pkgbase // "")"#,
        r#" + "\t" + (.recipeUrl // "")),"#,
        r#"(.features | to_entries[] | "F\t" + .key + "\t" + (.value.default | tostring)"#,
        r#" + "\t" + ((.value.packages // []) | join(","))),"#,
        r#"(.profiles | to_entries[] | "R\t" + .key + "\t" + ((.value.includeCategories // []) | join(","))"#,
        r#" + "\t" + ((.value.includePackages // []) | join(",")) + "\t" + ((.value.excludePackages // []) | join(",")))"#,
    );
    let raw = capture(JQ, &["-r", filter, path])
        .map_err(|_| CliError::Usage(format!("could not read inventory: {path}")))?;
    let text =
        String::from_utf8(raw).map_err(|_| CliError::Usage("inventory is not UTF-8".to_owned()))?;

    let mut version = String::new();
    let mut packages = Vec::new();
    let mut features = Vec::new();
    let mut profiles = Vec::new();
    for line in text.lines() {
        let mut f = line.split('\t');
        match f.next() {
            Some("V") => version = f.next().unwrap_or_default().to_owned(),
            Some("P") => {
                let cols: Vec<&str> = f.collect();
                if cols.len() < 9 {
                    return Err(CliError::Usage("inventory record is malformed".to_owned()));
                }
                packages.push(InvPkg {
                    name: cols[0].to_owned(),
                    source: cols[1].to_owned(),
                    category: cols[2].to_owned(),
                    default_: cols[3].to_owned(),
                    feature: (!cols[4].is_empty()).then(|| cols[4].to_owned()),
                    depends: split_list(cols[5]),
                    conflicts: split_list(cols[6]),
                    pkgbase: (!cols[7].is_empty()).then(|| cols[7].to_owned()),
                    recipe_url: (!cols[8].is_empty()).then(|| cols[8].to_owned()),
                });
            }
            Some("F") => {
                let cols: Vec<&str> = f.collect();
                if cols.len() < 3 {
                    return Err(CliError::Usage("inventory feature is malformed".to_owned()));
                }
                features.push(Feature {
                    key: cols[0].to_owned(),
                    default_: cols[1] == "true",
                    packages: split_list(cols[2]),
                });
            }
            Some("R") => {
                let cols: Vec<&str> = f.collect();
                if cols.len() < 4 {
                    return Err(CliError::Usage("inventory profile is malformed".to_owned()));
                }
                profiles.push(Profile {
                    key: cols[0].to_owned(),
                    include_categories: split_list(cols[1]),
                    include_packages: split_list(cols[2]),
                    exclude_packages: split_list(cols[3]),
                });
            }
            _ => {}
        }
    }
    if version.is_empty() {
        return Err(CliError::Usage(
            "inventory has no inventoryVersion".to_owned(),
        ));
    }
    let index = packages
        .iter()
        .enumerate()
        .map(|(i, p)| (p.name.clone(), i))
        .collect();
    Ok(Inventory {
        version,
        packages,
        features,
        profiles,
        index,
    })
}

struct Manifest {
    schema_version: String,
    inventory_version: String,
    profiles: Vec<String>,
    features: BTreeMap<String, bool>,
    include: Vec<String>,
    exclude: Vec<String>,
    aur: Vec<String>,
    notes: Vec<String>,
}

fn load_manifest(path: &str) -> Result<(Manifest, Vec<String>), CliError> {
    bounded_json_file(path, MANIFEST_MAX_BYTES, "manifest")?;
    let mut shape = Vec::new();

    // Structural shape: the field extraction below relies on these. The value
    // of schemaVersion is a validate() concern, not a parse blocker.
    let clauses = [
        (
            "inventoryVersion is not a string",
            "(.inventoryVersion | type) == \"string\"",
        ),
        (
            "profiles is not an array",
            "(.profiles | type) == \"array\"",
        ),
        (
            "features is not an object",
            "(.features | type) == \"object\"",
        ),
        (
            "packages is not an object",
            "(.packages | type) == \"object\"",
        ),
        (
            "packages.include is not an array",
            "(.packages.include | type) == \"array\"",
        ),
        (
            "packages.exclude is not an array",
            "(.packages.exclude | type) == \"array\"",
        ),
        (
            "packages.aur is not an array",
            "(.packages.aur | type) == \"array\"",
        ),
        (
            "notes is not an object",
            "((.notes // {}) | type) == \"object\"",
        ),
    ];
    for (message, clause) in clauses {
        if capture(JQ, &["-e", clause, path]).is_err() {
            shape.push(message.to_owned());
        }
    }
    // Unknown top-level keys (the schema forbids additions).
    if capture(
        JQ,
        &[
            "-e",
            "[keys[] | select([\"schemaVersion\",\"inventoryVersion\",\"profiles\",\"features\",\"packages\",\"notes\"] | index(.) | not)] | length == 0",
            path,
        ],
    )
    .is_err()
    {
        shape.push("manifest has unknown top-level keys".to_owned());
    }
    if capture(
        JQ,
        &[
            "-e",
            "(.packages | type) != \"object\" or ([.packages | keys[] | select([\"include\",\"exclude\",\"aur\"] | index(.) | not)] | length == 0)",
            path,
        ],
    )
    .is_err()
    {
        shape.push("packages has keys other than include, exclude, aur".to_owned());
    }

    if !shape.is_empty() {
        // A manifest we cannot read stops here; return the shape errors as the
        // problem list with a placeholder Manifest the caller will not resolve.
        return Ok((
            Manifest {
                schema_version: String::new(),
                inventory_version: String::new(),
                profiles: Vec::new(),
                features: BTreeMap::new(),
                include: Vec::new(),
                exclude: Vec::new(),
                aur: Vec::new(),
                notes: Vec::new(),
            },
            shape,
        ));
    }

    let filter = concat!(
        r#""S\t" + (.schemaVersion | tostring),"#,
        r#""V\t" + .inventoryVersion,"#,
        r#"(.profiles[] | "P\t" + .),"#,
        r#"(.features | to_entries[] | "F\t" + .key + "\t" + (.value | tostring)),"#,
        r#"(.packages.include[] | "I\t" + .),"#,
        r#"(.packages.exclude[] | "E\t" + .),"#,
        r#"(.packages.aur[] | "A\t" + .),"#,
        r#"((.notes // {}) | keys[] | "N\t" + .)"#,
    );
    let raw = capture(JQ, &["-r", filter, path])
        .map_err(|_| CliError::Usage("could not read manifest fields".to_owned()))?;
    let text =
        String::from_utf8(raw).map_err(|_| CliError::Usage("manifest is not UTF-8".to_owned()))?;

    let mut m = Manifest {
        schema_version: String::new(),
        inventory_version: String::new(),
        profiles: Vec::new(),
        features: BTreeMap::new(),
        include: Vec::new(),
        exclude: Vec::new(),
        aur: Vec::new(),
        notes: Vec::new(),
    };
    for line in text.lines() {
        let mut f = line.splitn(2, '\t');
        let tag = f.next().unwrap_or_default();
        let value = f.next().unwrap_or_default();
        match tag {
            "S" => m.schema_version = value.to_owned(),
            "V" => m.inventory_version = value.to_owned(),
            "P" => m.profiles.push(value.to_owned()),
            "F" => {
                let mut kv = value.splitn(2, '\t');
                let key = kv.next().unwrap_or_default().to_owned();
                let on = kv.next().unwrap_or_default() == "true";
                m.features.insert(key, on);
            }
            "I" => m.include.push(value.to_owned()),
            "E" => m.exclude.push(value.to_owned()),
            "A" => m.aur.push(value.to_owned()),
            "N" => m.notes.push(value.to_owned()),
            _ => {}
        }
    }
    Ok((m, Vec::new()))
}

/* --------------------------------------------------------------------------- */
/* Validation                                                                  */
/* --------------------------------------------------------------------------- */

fn re(pattern: &str, value: &str) -> bool {
    // Tiny anchored matcher for the two fixed patterns used here. Both are of
    // the form ^[class][class]*$, so a hand check is enough and keeps the crate
    // dependency-free.
    match pattern {
        NAME_RE => {
            let mut chars = value.chars();
            let first =
                matches!(chars.next(), Some(c) if c.is_ascii_lowercase() || c.is_ascii_digit());
            first
                && !value.is_empty()
                && value.chars().all(|c| {
                    c.is_ascii_lowercase()
                        || c.is_ascii_digit()
                        || matches!(c, '@' | '.' | '_' | '+' | '-')
                })
        }
        KEY_RE => {
            let mut chars = value.chars();
            let first = matches!(chars.next(), Some(c) if c.is_ascii_lowercase());
            first
                && value
                    .chars()
                    .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
        }
        _ => false,
    }
}

fn validate(inv: &Inventory, m: &Manifest) -> Vec<String> {
    let mut problems = Vec::new();

    if m.schema_version != "1" {
        problems.push(format!(
            "schemaVersion must be 1, found {}",
            quote(&m.schema_version)
        ));
    }
    if m.inventory_version != inv.version {
        problems.push(format!(
            "inventoryVersion {} does not match the loaded inventory {}",
            quote(&m.inventory_version),
            quote(&inv.version)
        ));
    }
    for p in &m.profiles {
        if !re(KEY_RE, p) {
            problems.push(format!("profile name {} is not lower-case kebab", quote(p)));
        } else if inv.profile(p).is_none() {
            problems.push(format!(
                "profile {} is not defined in the inventory",
                quote(p)
            ));
        }
    }
    for key in m.features.keys() {
        if !re(KEY_RE, key) {
            problems.push(format!(
                "feature key {} is not lower-case kebab",
                quote(key)
            ));
        } else if inv.feature(key).is_none() {
            problems.push(format!(
                "feature {} is not defined in the inventory",
                quote(key)
            ));
        }
    }

    let mut check_list = |label: &str, list: &[String]| {
        for name in list {
            if !re(NAME_RE, name) {
                problems.push(format!(
                    "{label}: {} is not a bare package name",
                    quote(name)
                ));
            } else if inv.get(name).is_none() {
                problems.push(format!("{label}: {name} is not in the inventory"));
            }
        }
    };
    check_list("include", &m.include);
    check_list("exclude", &m.exclude);
    check_list("aur", &m.aur);

    let include: BTreeSet<&String> = m.include.iter().collect();
    for name in &m.exclude {
        if include.contains(name) {
            problems.push(format!("{name} is in both include and exclude"));
        }
    }
    for name in &m.include {
        if let Some(p) = inv.get(name) {
            if p.category == "DROP" {
                problems.push(format!("include: {name} is a DROP package"));
            }
        }
    }
    for name in &m.aur {
        if let Some(p) = inv.get(name) {
            if p.source != "aur" {
                problems.push(format!("aur: {name} is a {} package, not AUR", p.source));
            }
            if matches!(p.category.as_str(), "BOOTSTRAP" | "CORE") {
                problems.push(format!(
                    "aur: {name} is in {}, which may not come from AUR",
                    p.category
                ));
            }
        }
    }
    for name in &m.notes {
        if inv.get(name).is_none() {
            problems.push(format!("notes: {name} is not a package in the inventory"));
        }
    }

    problems
}

fn quote(s: &str) -> String {
    format!("\"{}\"", json_escape(s))
}

/* --------------------------------------------------------------------------- */
/* Resolution                                                                  */
/* --------------------------------------------------------------------------- */

struct Resolution {
    effective_features: BTreeMap<String, bool>,
    resolved: BTreeSet<String>,
    auto_added: BTreeSet<String>,
    ignored_mandatory: Vec<String>,
}

fn feature_on(inv: &Inventory, m: &Manifest, key: &str) -> bool {
    m.features
        .get(key)
        .copied()
        .unwrap_or_else(|| inv.feature(key).map(|f| f.default_).unwrap_or(false))
}

fn active_profiles<'a>(inv: &'a Inventory, m: &Manifest) -> Vec<&'a Profile> {
    m.profiles.iter().filter_map(|k| inv.profile(k)).collect()
}

/// Mirror of the selector's `baseSelected`: default membership before the
/// manifest's explicit include/exclude overrides. A profile's excludePackages
/// wins; then any enabled feature that lists the package pulls it in; then a
/// profile's includePackages or a matched includeCategory (skipping a package
/// whose own `feature` gate is off).
fn base_selected(inv: &Inventory, m: &Manifest, p: &InvPkg, profiles: &[&Profile]) -> bool {
    if p.category == "DROP" {
        return false;
    }
    for pr in profiles {
        if pr.exclude_packages.iter().any(|n| n == &p.name) {
            return false;
        }
    }
    for f in &inv.features {
        if feature_on(inv, m, &f.key) && f.packages.iter().any(|n| n == &p.name) {
            return true;
        }
    }
    for pr in profiles {
        if pr.include_packages.iter().any(|n| n == &p.name) {
            return true;
        }
        if pr.include_categories.contains(&p.category) && p.default_ != "optional" {
            match &p.feature {
                None => return true,
                Some(feat) if feature_on(inv, m, feat) => return true,
                _ => {}
            }
        }
    }
    false
}

fn resolve(inv: &Inventory, m: &Manifest) -> Resolution {
    let profiles = active_profiles(inv, m);
    let include: BTreeSet<&str> = m.include.iter().map(String::as_str).collect();
    let exclude: BTreeSet<&str> = m.exclude.iter().map(String::as_str).collect();

    let mut resolved = BTreeSet::new();
    let mut ignored_mandatory = Vec::new();

    for p in &inv.packages {
        let base = base_selected(inv, m, p, &profiles);
        let locked = p.default_ == "required" && base;
        let eff = if locked {
            if exclude.contains(p.name.as_str()) {
                ignored_mandatory.push(p.name.clone());
            }
            true
        } else if exclude.contains(p.name.as_str()) {
            false
        } else if include.contains(p.name.as_str()) {
            true
        } else {
            base
        };
        if eff {
            resolved.insert(p.name.clone());
        }
    }

    // Pull in inventory-declared dependencies of resolved packages.
    let mut auto_added = BTreeSet::new();
    let mut frontier: Vec<String> = resolved.iter().cloned().collect();
    while let Some(name) = frontier.pop() {
        let Some(p) = inv.get(&name) else { continue };
        for dep in &p.depends {
            if inv.get(dep).is_some() && !resolved.contains(dep) {
                resolved.insert(dep.clone());
                auto_added.insert(dep.clone());
                frontier.push(dep.clone());
            }
        }
    }

    let effective_features = inv
        .features
        .iter()
        .map(|f| (f.key.clone(), feature_on(inv, m, &f.key)))
        .collect();

    Resolution {
        effective_features,
        resolved,
        auto_added,
        ignored_mandatory,
    }
}

/* --------------------------------------------------------------------------- */
/* Commands                                                                    */
/* --------------------------------------------------------------------------- */

fn validate_command(args: &[String]) -> Result<(), CliError> {
    let opts = parse_options(args, false)?;
    let inv = load_inventory(&opts.inventory)?;
    let (manifest, shape) = load_manifest(&opts.manifest)?;
    let mut problems = shape;
    if problems.is_empty() {
        problems = validate(&inv, &manifest);
    }

    if opts.json {
        let list = problems
            .iter()
            .map(|p| format!("\"{}\"", json_escape(p)))
            .collect::<Vec<_>>()
            .join(",");
        println!(
            "{{\"schemaVersion\":1,\"ok\":{},\"inventoryVersion\":\"{}\",\"problems\":[{}]}}",
            problems.is_empty(),
            json_escape(&inv.version),
            list
        );
    } else if problems.is_empty() {
        eprintln!("manifest is valid against inventory {}", inv.version);
    } else {
        eprintln!("manifest has {} problem(s):", problems.len());
        for p in &problems {
            eprintln!("  - {p}");
        }
    }

    if problems.is_empty() {
        Ok(())
    } else {
        Err(CliError::Usage("manifest is not valid".to_owned()))
    }
}

fn plan_command(args: &[String]) -> Result<(), CliError> {
    let opts = parse_options(args, true)?;
    let inv = load_inventory(&opts.inventory)?;
    let (manifest, shape) = load_manifest(&opts.manifest)?;
    let mut problems = shape;
    if problems.is_empty() {
        problems = validate(&inv, &manifest);
    }
    if !problems.is_empty() {
        eprintln!("cannot plan an invalid manifest:");
        for p in &problems {
            eprintln!("  - {p}");
        }
        return Err(CliError::Usage("manifest is not valid".to_owned()));
    }

    let res = resolve(&inv, &manifest);
    let installed = installed_packages();
    let inv_names: BTreeSet<&String> = inv.packages.iter().map(|p| &p.name).collect();

    let (installed_known, install_plan, remove_plan, would_orphan) = match &installed {
        Some(set) => {
            let known: BTreeSet<String> = set
                .iter()
                .filter(|n| inv_names.contains(n))
                .cloned()
                .collect();
            let install: Vec<String> = res
                .resolved
                .iter()
                .filter(|n| !set.contains(*n))
                .cloned()
                .collect();
            let remove: Vec<String> = known
                .iter()
                .filter(|n| !res.resolved.contains(*n))
                .cloned()
                .collect();
            (Some(known), install, remove.clone(), remove)
        }
        None => (None, Vec::new(), Vec::new(), Vec::new()),
    };

    let donor_base = opts.donor_base.as_deref().map(read_name_list).transpose()?;
    let donor_diff = donor_base.as_ref().map(|base| {
        let base_set: BTreeSet<&String> = base.iter().collect();
        let added: Vec<String> = res
            .resolved
            .iter()
            .filter(|n| !base_set.contains(*n))
            .cloned()
            .collect();
        let removed: Vec<String> = base
            .iter()
            .filter(|n| !res.resolved.contains(*n))
            .cloned()
            .collect();
        (added, removed)
    });

    // AUR entries in the resolved set.
    let mut aur_entries = Vec::new();
    for name in &res.resolved {
        if let Some(p) = inv.get(name) {
            if p.source == "aur" {
                let commit = p
                    .recipe_url
                    .as_deref()
                    .and_then(|url| opts.lockfile.as_ref().and(resolve_commit(url)));
                aur_entries.push((
                    name.clone(),
                    p.pkgbase.clone().unwrap_or_default(),
                    p.recipe_url.clone().unwrap_or_default(),
                    commit,
                ));
            }
        }
    }

    let mut risks = Vec::new();
    for name in &res.resolved {
        if let Some(p) = inv.get(name) {
            for c in &p.conflicts {
                if res.resolved.contains(c) && &p.name < c {
                    risks.push(format!("{} conflicts with {}", p.name, c));
                }
            }
            if p.category == "DROP" {
                risks.push(format!("{name} is DROP but resolved as selected"));
            }
        }
    }
    for f in &inv.features {
        if !res.effective_features.get(&f.key).copied().unwrap_or(false) {
            let still: Vec<&String> = f
                .packages
                .iter()
                .filter(|n| res.resolved.contains(*n))
                .collect();
            if !still.is_empty() {
                risks.push(format!(
                    "feature {} is off but its packages are still selected: {}",
                    f.key,
                    still
                        .iter()
                        .map(|s| s.as_str())
                        .collect::<Vec<_>>()
                        .join(", ")
                ));
            }
        }
    }

    if let Some(path) = &opts.lockfile {
        write_lockfile(path, &inv.version, &aur_entries)?;
    }

    if opts.json {
        print_plan_json(
            &inv,
            &res,
            &aur_entries,
            &risks,
            installed_known.as_ref(),
            &install_plan,
            &remove_plan,
            &would_orphan,
            donor_diff.as_ref(),
        );
    } else {
        print_plan_human(
            &inv,
            &manifest,
            &res,
            &aur_entries,
            &risks,
            &installed,
            &install_plan,
            &remove_plan,
            donor_diff.as_ref(),
            opts.lockfile.as_deref(),
        );
    }
    Ok(())
}

/* --------------------------------------------------------------------------- */
/* System queries (read-only)                                                  */
/* --------------------------------------------------------------------------- */

fn installed_packages() -> Option<BTreeSet<String>> {
    let out = capture("/usr/bin/pacman", &["-Qq"]).ok()?;
    let text = String::from_utf8(out).ok()?;
    Some(
        text.lines()
            .map(str::to_owned)
            .filter(|s| !s.is_empty())
            .collect(),
    )
}

fn read_name_list(path: &str) -> Result<Vec<String>, CliError> {
    let meta = fs::symlink_metadata(path)
        .map_err(|_| CliError::Usage(format!("donor list not found: {path}")))?;
    if !meta.file_type().is_file() || meta.len() > 256 * 1024 {
        return Err(CliError::Usage(format!(
            "donor list is not a small regular file: {path}"
        )));
    }
    let text = fs::read_to_string(path)
        .map_err(|_| CliError::Usage(format!("could not read donor list: {path}")))?;
    Ok(text
        .lines()
        .map(|l| l.split('#').next().unwrap_or("").trim())
        .filter(|l| !l.is_empty() && re(NAME_RE, l))
        .map(str::to_owned)
        .collect())
}

/// `git ls-remote` the AUR recipe to pin the current commit. Network is allowed
/// here; the recipe is never fetched, checked out or executed.
fn resolve_commit(recipe_url: &str) -> Option<String> {
    if !recipe_url.starts_with("https://aur.archlinux.org/") || !recipe_url.ends_with(".git") {
        return None;
    }
    let out = capture(
        "/usr/bin/git",
        &["ls-remote", "--exit-code", recipe_url, "HEAD"],
    )
    .ok()?;
    let text = String::from_utf8(out).ok()?;
    let hash = text.split_whitespace().next()?.to_owned();
    (hash.len() == 40 && hash.chars().all(|c| c.is_ascii_hexdigit())).then_some(hash)
}

type AurEntry = (String, String, String, Option<String>);

fn write_lockfile(path: &str, inv_version: &str, entries: &[AurEntry]) -> Result<(), CliError> {
    let mut items = Vec::new();
    for (name, pkgbase, url, commit) in entries {
        let commit_json = match commit {
            Some(c) => format!("\"{}\"", json_escape(c)),
            None => "null".to_owned(),
        };
        items.push(format!(
            "    {{\"name\":\"{}\",\"pkgbase\":\"{}\",\"recipeUrl\":\"{}\",\"commit\":{}}}",
            json_escape(name),
            json_escape(pkgbase),
            json_escape(url),
            commit_json
        ));
    }
    let body = format!(
        "{{\n  \"schemaVersion\": 1,\n  \"inventoryVersion\": \"{}\",\n  \"packages\": [\n{}\n  ]\n}}\n",
        json_escape(inv_version),
        items.join(",\n")
    );
    let tmp = format!("{path}.tmp");
    fs::write(&tmp, body)
        .map_err(|e| CliError::Operational(format!("could not write lockfile: {e}")))?;
    fs::rename(&tmp, path)
        .map_err(|e| CliError::Operational(format!("could not place lockfile: {e}")))?;
    Ok(())
}

/* --------------------------------------------------------------------------- */
/* Reporting                                                                   */
/* --------------------------------------------------------------------------- */

fn section(title: &str, items: &[String]) {
    println!("\n{title} ({})", items.len());
    if items.is_empty() {
        println!("  (none)");
    }
    for i in items {
        println!("  {i}");
    }
}

#[allow(clippy::too_many_arguments)]
fn print_plan_human(
    inv: &Inventory,
    m: &Manifest,
    res: &Resolution,
    aur: &[AurEntry],
    risks: &[String],
    installed: &Option<BTreeSet<String>>,
    install_plan: &[String],
    remove_plan: &[String],
    donor_diff: Option<&(Vec<String>, Vec<String>)>,
    lockfile: Option<&str>,
) {
    let resolved: Vec<String> = res.resolved.iter().cloned().collect();
    eprintln!(
        "plan for manifest against inventory {} — profiles: [{}]",
        inv.version,
        m.profiles.join(", ")
    );
    eprintln!("this plan installs and removes nothing; it is for review only");

    let features_on: Vec<String> = res
        .effective_features
        .iter()
        .filter(|(_, on)| **on)
        .map(|(k, _)| k.clone())
        .collect();
    println!("\nfeatures on: [{}]", features_on.join(", "));
    println!("resolved packages: {}", resolved.len());

    let by_source = |src: &str| {
        resolved
            .iter()
            .filter(|n| inv.get(n).is_some_and(|p| p.source == src))
            .count()
    };
    println!(
        "  arch {} · frost {} · aur {}",
        by_source("arch"),
        by_source("frost"),
        by_source("aur")
    );

    section("automatically added dependencies", &sorted(&res.auto_added));
    section(
        "excluded but kept because required",
        &res.ignored_mandatory.clone(),
    );

    match installed {
        Some(_) => {
            section("would install (not currently present)", install_plan);
            section(
                "would remove (present, no longer selected) — NOT executed",
                remove_plan,
            );
            println!(
                "\n  every line above that pacman pulled in only as a dependency\n  \
                 would also become orphaned; true orphan analysis needs the full\n  \
                 dependency graph and lands with the Phase 6 backend"
            );
        }
        None => println!("\npacman unavailable: install / remove / orphan diff skipped"),
    }

    if let Some((added, removed)) = donor_diff {
        section("added versus the donor base list", added);
        section("dropped versus the donor base list", removed);
    } else {
        println!("\ndonor base diff skipped (pass --donor-base PATH)");
    }

    let aur_lines: Vec<String> = aur
        .iter()
        .map(|(name, base, url, commit)| {
            format!(
                "{name}  pkgbase={base}  {url}  commit={}",
                commit.as_deref().unwrap_or("unresolved")
            )
        })
        .collect();
    section("AUR selections", &aur_lines);
    if let Some(path) = lockfile {
        println!("  lockfile written: {path}");
    } else if !aur.is_empty() {
        println!("  pass --lockfile PATH to pin pkgbase and commit");
    }

    section("risks and lost features", &risks.to_vec());
    section("final resolved list", &resolved);
}

#[allow(clippy::too_many_arguments)]
fn print_plan_json(
    inv: &Inventory,
    res: &Resolution,
    aur: &[AurEntry],
    risks: &[String],
    installed_known: Option<&BTreeSet<String>>,
    install_plan: &[String],
    remove_plan: &[String],
    would_orphan: &[String],
    donor_diff: Option<&(Vec<String>, Vec<String>)>,
) {
    let arr = |items: &[String]| {
        items
            .iter()
            .map(|i| format!("\"{}\"", json_escape(i)))
            .collect::<Vec<_>>()
            .join(",")
    };
    let resolved: Vec<String> = res.resolved.iter().cloned().collect();
    let features = res
        .effective_features
        .iter()
        .map(|(k, on)| format!("\"{}\":{}", json_escape(k), on))
        .collect::<Vec<_>>()
        .join(",");
    let aur_json = aur
        .iter()
        .map(|(name, base, url, commit)| {
            let c = commit
                .as_deref()
                .map(|c| format!("\"{}\"", json_escape(c)))
                .unwrap_or_else(|| "null".to_owned());
            format!(
                "{{\"name\":\"{}\",\"pkgbase\":\"{}\",\"recipeUrl\":\"{}\",\"commit\":{}}}",
                json_escape(name),
                json_escape(base),
                json_escape(url),
                c
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    let (donor_added, donor_removed) = match donor_diff {
        Some((a, r)) => (arr(a), arr(r)),
        None => (String::new(), String::new()),
    };
    let installed_present = installed_known.is_some();
    print!("{{");
    print!("\"schemaVersion\":1,");
    print!("\"inventoryVersion\":\"{}\",", json_escape(&inv.version));
    print!("\"resolved\":[{}],", arr(&resolved));
    print!("\"autoAdded\":[{}],", arr(&sorted(&res.auto_added)));
    print!("\"ignoredMandatory\":[{}],", arr(&res.ignored_mandatory));
    print!("\"pacmanAvailable\":{installed_present},");
    print!("\"installPlan\":[{}],", arr(install_plan));
    print!("\"removePlan\":[{}],", arr(remove_plan));
    print!("\"wouldOrphan\":[{}],", arr(would_orphan));
    print!("\"donorBaseAdded\":[{donor_added}],");
    print!("\"donorBaseRemoved\":[{donor_removed}],");
    print!("\"aur\":[{aur_json}],");
    print!("\"features\":{{{features}}},");
    print!("\"risks\":[{}]", arr(risks));
    println!("}}");
}

fn sorted(set: &BTreeSet<String>) -> Vec<String> {
    set.iter().cloned().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn inv() -> Inventory {
        let packages = vec![
            InvPkg {
                name: "base".into(),
                source: "arch".into(),
                category: "BOOTSTRAP".into(),
                default_: "required".into(),
                feature: None,
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
            InvPkg {
                name: "hyprland".into(),
                source: "arch".into(),
                category: "CORE".into(),
                default_: "required".into(),
                feature: None,
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
            InvPkg {
                name: "bluez".into(),
                source: "arch".into(),
                category: "CORE".into(),
                default_: "required".into(),
                feature: Some("bluetooth".into()),
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
            InvPkg {
                name: "obsidian".into(),
                source: "arch".into(),
                category: "DESKTOP".into(),
                default_: "optional".into(),
                feature: None,
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
            InvPkg {
                name: "ripgrep".into(),
                source: "arch".into(),
                category: "DESKTOP".into(),
                default_: "recommended".into(),
                feature: None,
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
            InvPkg {
                name: "paru".into(),
                source: "aur".into(),
                category: "OPTIONAL".into(),
                default_: "recommended".into(),
                feature: Some("aur".into()),
                depends: vec![],
                conflicts: vec![],
                pkgbase: Some("paru".into()),
                recipe_url: Some("https://aur.archlinux.org/paru.git".into()),
            },
            InvPkg {
                name: "aether".into(),
                source: "arch".into(),
                category: "DROP".into(),
                default_: "optional".into(),
                feature: None,
                depends: vec![],
                conflicts: vec![],
                pkgbase: None,
                recipe_url: None,
            },
        ];
        let index = packages
            .iter()
            .enumerate()
            .map(|(i, p)| (p.name.clone(), i))
            .collect();
        Inventory {
            version: "2026-08-29.1".into(),
            packages,
            features: vec![
                Feature {
                    key: "bluetooth".into(),
                    default_: true,
                    packages: vec!["bluez".into()],
                },
                Feature {
                    key: "aur".into(),
                    default_: true,
                    packages: vec!["paru".into()],
                },
            ],
            profiles: vec![Profile {
                key: "desktop".into(),
                include_categories: vec!["BOOTSTRAP".into(), "CORE".into(), "DESKTOP".into()],
                include_packages: vec![],
                exclude_packages: vec![],
            }],
            index,
        }
    }

    fn manifest(profiles: &[&str], include: &[&str], exclude: &[&str], aur: &[&str]) -> Manifest {
        Manifest {
            schema_version: "1".into(),
            inventory_version: "2026-08-29.1".into(),
            profiles: profiles.iter().map(|s| s.to_string()).collect(),
            features: BTreeMap::new(),
            include: include.iter().map(|s| s.to_string()).collect(),
            exclude: exclude.iter().map(|s| s.to_string()).collect(),
            aur: aur.iter().map(|s| s.to_string()).collect(),
            notes: vec![],
        }
    }

    #[test]
    fn valid_manifest_has_no_problems() {
        let problems = validate(
            &inv(),
            &manifest(&["desktop"], &["obsidian"], &[], &["paru"]),
        );
        assert!(problems.is_empty(), "{problems:?}");
    }

    #[test]
    fn rejects_unknown_inventory_version() {
        let mut m = manifest(&["desktop"], &[], &[], &[]);
        m.inventory_version = "1999-01-01.1".into();
        assert!(
            validate(&inv(), &m)
                .iter()
                .any(|p| p.contains("inventoryVersion"))
        );
    }

    #[test]
    fn rejects_dropped_package_in_include() {
        let problems = validate(&inv(), &manifest(&["desktop"], &["aether"], &[], &[]));
        assert!(problems.iter().any(|p| p.contains("DROP")), "{problems:?}");
    }

    #[test]
    fn rejects_arch_package_in_aur_list() {
        let problems = validate(&inv(), &manifest(&["desktop"], &[], &[], &["ripgrep"]));
        assert!(
            problems.iter().any(|p| p.contains("not AUR")),
            "{problems:?}"
        );
    }

    #[test]
    fn rejects_include_exclude_overlap() {
        let problems = validate(
            &inv(),
            &manifest(&["desktop"], &["obsidian"], &["obsidian"], &[]),
        );
        assert!(
            problems
                .iter()
                .any(|p| p.contains("both include and exclude"))
        );
    }

    #[test]
    fn rejects_executable_looking_name() {
        let problems = validate(
            &inv(),
            &manifest(&["desktop"], &["ripgrep; rm -rf /"], &[], &[]),
        );
        assert!(problems.iter().any(|p| p.contains("bare package name")));
    }

    #[test]
    fn resolve_takes_profile_categories_but_not_optional() {
        let res = resolve(&inv(), &manifest(&["desktop"], &[], &[], &[]));
        assert!(res.resolved.contains("hyprland"));
        assert!(res.resolved.contains("ripgrep"));
        assert!(
            !res.resolved.contains("obsidian"),
            "optional stays off by default"
        );
    }

    #[test]
    fn resolve_honours_include_and_exclude() {
        let res = resolve(
            &inv(),
            &manifest(&["desktop"], &["obsidian"], &["ripgrep"], &[]),
        );
        assert!(res.resolved.contains("obsidian"));
        assert!(!res.resolved.contains("ripgrep"));
    }

    #[test]
    fn resolve_keeps_required_despite_exclude() {
        let res = resolve(&inv(), &manifest(&["desktop"], &[], &["hyprland"], &[]));
        assert!(res.resolved.contains("hyprland"));
        assert!(res.ignored_mandatory.contains(&"hyprland".to_string()));
    }

    #[test]
    fn feature_off_drops_its_gated_package() {
        let mut m = manifest(&["desktop"], &[], &[], &[]);
        m.features.insert("bluetooth".into(), false);
        let res = resolve(&inv(), &m);
        assert!(
            !res.resolved.contains("bluez"),
            "bluez is gated by the bluetooth feature"
        );
    }

    #[test]
    fn name_matcher_matches_pattern() {
        assert!(re(NAME_RE, "ttf-jetbrains-mono"));
        assert!(re(NAME_RE, "lib32-nvidia-utils"));
        assert!(!re(NAME_RE, "-leading-dash"));
        assert!(!re(NAME_RE, "has space"));
        assert!(!re(NAME_RE, "$(id)"));
        assert!(re(KEY_RE, "input-method"));
        assert!(!re(KEY_RE, "Input-Method"));
    }
}
