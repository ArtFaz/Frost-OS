use crate::CliError;
use std::collections::{BTreeMap, BTreeSet};
use std::env;
use std::fs;
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};

const DEFAULT_THEME: &str = "gruvbox";
const MAX_THEME_BYTES: u64 = 64 * 1024;
/// Semantic roles the shell binds to. Every theme must define all of them, and
/// they carry the contrast guarantees.
const COLOR_KEYS: [&str; 8] = [
    "background",
    "foreground",
    "muted",
    "accent",
    "urgent",
    "highlight",
    "success",
    "warning",
];

/// Palette entries a theme may also supply. They exist so terminals, btop and
/// the compositor can be themed from the same file; the shell does not bind to
/// them and they are exempt from the contrast gates, because an ANSI palette
/// legitimately contains colours that are unreadable against the background.
const PALETTE_KEYS: [&str; 19] = [
    "selection",
    "dark_background",
    "darker_background",
    "lighter_background",
    "dark_foreground",
    "light_foreground",
    "bright_foreground",
    "red",
    "yellow",
    "orange",
    "green",
    "cyan",
    "blue",
    "magenta",
    "brown",
    "bright_red",
    "bright_yellow",
    "bright_green",
    "bright_blue",
];

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Theme {
    pub name: String,
    pub mode: String,
    pub colors: BTreeMap<String, String>,
}

fn home_dir() -> Result<PathBuf, CliError> {
    env::var_os("HOME")
        .map(PathBuf::from)
        .ok_or_else(|| CliError::Operational("HOME is unavailable".to_owned()))
}

fn config_home() -> Result<PathBuf, CliError> {
    Ok(env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or(home_dir()?.join(".config")))
}

fn runtime_dir() -> Result<PathBuf, CliError> {
    env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .ok_or_else(|| CliError::Operational("XDG_RUNTIME_DIR is unavailable".to_owned()))
}

fn selection_path() -> Result<PathBuf, CliError> {
    Ok(config_home()?.join("frost/theme.json"))
}

fn effective_dir() -> Result<PathBuf, CliError> {
    Ok(runtime_dir()?.join("frost/theme"))
}

fn theme_roots() -> Result<Vec<PathBuf>, CliError> {
    let mut roots = vec![config_home()?.join("frost/themes")];
    // Set only by the worktree preview, so a developer sees the tree's themes
    // rather than whichever set happens to be installed.
    if let Some(source) = env::var_os("FROST_SOURCE_ROOT").map(PathBuf::from) {
        roots.push(source.join("themes"));
    }
    roots.push(PathBuf::from("/etc/frost/themes"));
    roots.push(PathBuf::from("/usr/share/frost/themes"));
    Ok(roots)
}

fn valid_name(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 64
        && value
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
}

fn json_escape(value: &str) -> String {
    value
        .chars()
        .flat_map(|character| match character {
            '"' => "\\\"".chars().collect::<Vec<_>>(),
            '\\' => "\\\\".chars().collect::<Vec<_>>(),
            '\n' => "\\n".chars().collect::<Vec<_>>(),
            '\r' => "\\r".chars().collect::<Vec<_>>(),
            '\t' => "\\t".chars().collect::<Vec<_>>(),
            other if other.is_control() => format!("\\u{:04x}", other as u32).chars().collect(),
            other => vec![other],
        })
        .collect()
}

fn unquote(value: &str) -> Option<String> {
    let trimmed = value.trim();
    if trimmed.len() < 2 || !trimmed.starts_with('"') || !trimmed.ends_with('"') {
        return None;
    }
    let inner = &trimmed[1..trimmed.len() - 1];
    if inner.contains(['"', '\n', '\r', '\0']) {
        return None;
    }
    Some(inner.to_owned())
}

fn parse_hex(value: &str) -> Option<(u8, u8, u8)> {
    if value.len() != 7 || !value.starts_with('#') {
        return None;
    }
    Some((
        u8::from_str_radix(&value[1..3], 16).ok()?,
        u8::from_str_radix(&value[3..5], 16).ok()?,
        u8::from_str_radix(&value[5..7], 16).ok()?,
    ))
}

fn channel(value: u8) -> f64 {
    let normalized = f64::from(value) / 255.0;
    if normalized <= 0.04045 {
        normalized / 12.92
    } else {
        ((normalized + 0.055) / 1.055).powf(2.4)
    }
}

fn luminance(value: &str) -> f64 {
    let (red, green, blue) = parse_hex(value).expect("validated theme color");
    0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
}

fn contrast(left: &str, right: &str) -> f64 {
    let left = luminance(left);
    let right = luminance(right);
    (left.max(right) + 0.05) / (left.min(right) + 0.05)
}

pub(crate) fn parse_theme(raw: &str) -> Result<Theme, CliError> {
    let mut section = String::new();
    let mut root = BTreeMap::new();
    let mut colors = BTreeMap::new();
    for raw_line in raw.lines() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if line.starts_with('[') && line.ends_with(']') {
            section = line[1..line.len() - 1].to_owned();
            if section != "colors" {
                return Err(CliError::Usage(format!(
                    "unsupported theme section: {section}"
                )));
            }
            continue;
        }
        let (key, value) = line
            .split_once('=')
            .ok_or_else(|| CliError::Usage("invalid theme assignment".to_owned()))?;
        let key = key.trim();
        if key.is_empty() {
            return Err(CliError::Usage("empty theme key".to_owned()));
        }
        let target = if section == "colors" {
            &mut colors
        } else {
            &mut root
        };
        if target.contains_key(key) {
            return Err(CliError::Usage(format!("duplicate theme key: {key}")));
        }
        target.insert(key.to_owned(), value.trim().to_owned());
    }

    let expected_root = BTreeSet::from(["schemaVersion", "name", "mode"]);
    let actual_root = root.keys().map(String::as_str).collect::<BTreeSet<_>>();
    if actual_root != expected_root {
        return Err(CliError::Usage(
            "theme root must contain exactly schemaVersion, name and mode".to_owned(),
        ));
    }
    if root.get("schemaVersion").map(String::as_str) != Some("1") {
        return Err(CliError::Usage("theme schemaVersion must be 1".to_owned()));
    }
    let name = unquote(root.get("name").expect("checked key"))
        .filter(|value| !value.trim().is_empty() && value.len() <= 80)
        .ok_or_else(|| CliError::Usage("invalid theme name".to_owned()))?;
    let mode = unquote(root.get("mode").expect("checked key"))
        .filter(|value| value == "dark" || value == "light")
        .ok_or_else(|| CliError::Usage("theme mode must be dark or light".to_owned()))?;

    let actual_colors = colors.keys().map(String::as_str).collect::<BTreeSet<_>>();
    let required_colors = COLOR_KEYS.into_iter().collect::<BTreeSet<_>>();
    if !required_colors.is_subset(&actual_colors) {
        return Err(CliError::Usage(format!(
            "theme colors must contain at least {}",
            COLOR_KEYS.join(", ")
        )));
    }
    let allowed_colors = COLOR_KEYS
        .into_iter()
        .chain(PALETTE_KEYS)
        .collect::<BTreeSet<_>>();
    if let Some(unknown) = actual_colors.difference(&allowed_colors).next() {
        return Err(CliError::Usage(format!(
            "unsupported theme color: {unknown}"
        )));
    }
    let mut normalized = BTreeMap::new();
    for key in COLOR_KEYS.into_iter().chain(PALETTE_KEYS) {
        let Some(raw) = colors.get(key) else {
            continue;
        };
        let value = unquote(raw)
            .filter(|value| parse_hex(value).is_some())
            .ok_or_else(|| CliError::Usage(format!("invalid color: {key}")))?;
        normalized.insert(key.to_owned(), value.to_ascii_lowercase());
    }
    let background = normalized.get("background").expect("required color");
    let foreground = normalized.get("foreground").expect("required color");
    if contrast(background, foreground) < 4.5 {
        return Err(CliError::Usage(
            "foreground/background contrast must be at least 4.5:1".to_owned(),
        ));
    }
    for role in ["accent", "urgent", "success", "warning"] {
        if contrast(background, normalized.get(role).expect("required color")) < 2.0 {
            return Err(CliError::Usage(format!(
                "{role}/background contrast must be at least 2:1"
            )));
        }
    }
    Ok(Theme {
        name,
        mode,
        colors: normalized,
    })
}

fn theme_file_is_safe(path: &Path) -> bool {
    fs::symlink_metadata(path).is_ok_and(|metadata| {
        metadata.file_type().is_file()
            && metadata.mode() & 0o111 == 0
            && metadata.len() <= MAX_THEME_BYTES
    })
}

fn read_theme(path: &Path) -> Result<Theme, CliError> {
    if !theme_file_is_safe(path) {
        return Err(CliError::Usage(format!(
            "theme is not a safe regular data file: {}",
            path.display()
        )));
    }
    let raw = fs::read_to_string(path)
        .map_err(|error| CliError::Operational(format!("could not read theme: {error}")))?;
    parse_theme(&raw)
}

fn resolve_theme(name: &str) -> Result<(Theme, PathBuf), CliError> {
    if !valid_name(name) {
        return Err(CliError::Usage("invalid theme name".to_owned()));
    }
    for root in theme_roots()? {
        let directory = root.join(name);
        if fs::symlink_metadata(&directory).is_ok_and(|metadata| metadata.file_type().is_dir()) {
            let path = directory.join("theme.toml");
            if theme_file_is_safe(&path) {
                return Ok((read_theme(&path)?, path));
            }
        }
    }
    Err(CliError::Usage(format!("unknown theme: {name}")))
}

fn selected_name() -> Result<String, CliError> {
    let path = selection_path()?;
    if fs::symlink_metadata(&path).is_ok_and(|metadata| {
        !metadata.file_type().is_file()
            || metadata.mode() & 0o111 != 0
            || metadata.len() > MAX_THEME_BYTES
    }) {
        return Err(CliError::Usage(
            "theme selection is not a safe regular data file".to_owned(),
        ));
    }
    let Ok(raw) = fs::read_to_string(path) else {
        return Ok(DEFAULT_THEME.to_owned());
    };
    let compact = raw
        .chars()
        .filter(|value| !value.is_whitespace())
        .collect::<String>();
    let prefix = "{\"schemaVersion\":1,\"name\":\"";
    let suffix = "\"}";
    if !compact.starts_with(prefix) || !compact.ends_with(suffix) {
        return Err(CliError::Usage("invalid Frost theme selection".to_owned()));
    }
    let name = &compact[prefix.len()..compact.len() - suffix.len()];
    if !valid_name(name) {
        return Err(CliError::Usage("invalid selected theme name".to_owned()));
    }
    Ok(name.to_owned())
}

fn normalized_theme(theme: &Theme) -> String {
    let mut output = format!(
        "schemaVersion = 1\nname = \"{}\"\nmode = \"{}\"\n\n[colors]\n",
        theme.name, theme.mode
    );
    for key in COLOR_KEYS {
        output.push_str(&format!(
            "{key} = \"{}\"\n",
            theme.colors.get(key).expect("required color")
        ));
    }
    output
}

fn atomic_write(path: &Path, contents: &str, mode: u32) -> Result<(), CliError> {
    let parent = path
        .parent()
        .ok_or_else(|| CliError::Operational("output path has no parent".to_owned()))?;
    fs::create_dir_all(parent).map_err(|error| {
        CliError::Operational(format!("could not create theme directory: {error}"))
    })?;
    fs::set_permissions(parent, fs::Permissions::from_mode(0o700)).map_err(|error| {
        CliError::Operational(format!("could not secure theme directory: {error}"))
    })?;
    let temporary = path.with_extension("tmp");
    fs::write(&temporary, contents)
        .map_err(|error| CliError::Operational(format!("could not write theme state: {error}")))?;
    fs::set_permissions(&temporary, fs::Permissions::from_mode(mode))
        .map_err(|error| CliError::Operational(format!("could not secure theme state: {error}")))?;
    fs::rename(&temporary, path)
        .map_err(|error| CliError::Operational(format!("could not publish theme state: {error}")))
}

fn rgba(theme: &Theme, role: &str, alpha: &str) -> String {
    format!(
        "{}{}",
        theme
            .colors
            .get(role)
            .expect("required color")
            .trim_start_matches('#'),
        alpha
    )
}

/// Package-owned templates only. There is no user template directory on
/// purpose: a rendered template becomes a config another program reads, so an
/// extension point here would be an extension point into those programs.
fn template_source(name: &str) -> Option<PathBuf> {
    if let Some(root) = env::var_os("FROST_SOURCE_ROOT").map(PathBuf::from) {
        let candidate = root.join("default/templates").join(name);
        if candidate.is_file() {
            return Some(candidate);
        }
    }
    [
        PathBuf::from("/etc/frost/templates"),
        PathBuf::from("/usr/share/frost/templates"),
    ]
    .into_iter()
    .map(|root| root.join(name))
    .find(|candidate| candidate.is_file())
}

/// Substitution only — no conditionals, no loops, no shelling out. An unknown
/// token is left untouched rather than erroring, so a template naming a palette
/// entry a theme omits degrades to a literal instead of failing the whole sync.
fn render_template(source: &str, theme: &Theme) -> String {
    let mut values: BTreeMap<String, String> = BTreeMap::new();
    values.insert("name".to_owned(), theme.name.clone());
    values.insert("mode".to_owned(), theme.mode.clone());
    let light = theme.mode == "light";
    values.insert(
        "surface_alpha".to_owned(),
        if light { "e0" } else { "cc" }.to_owned(),
    );
    values.insert(
        "border_alpha".to_owned(),
        if light { "24" } else { "33" }.to_owned(),
    );
    // A theme only has to define the eight semantic roles. Palette entries it
    // omits fall back to the nearest role so a template always resolves — an
    // unresolved token would land in a config file another program then rejects.
    let mut resolved: BTreeMap<&str, String> = BTreeMap::new();
    for (key, value) in &theme.colors {
        resolved.insert(key.as_str(), value.clone());
    }
    let role = |name: &str| -> String {
        theme
            .colors
            .get(name)
            .cloned()
            .unwrap_or_else(|| "#000000".to_owned())
    };
    for (key, fallback) in [
        ("selection", "accent"),
        ("dark_background", "background"),
        ("darker_background", "background"),
        ("lighter_background", "muted"),
        ("dark_foreground", "muted"),
        ("light_foreground", "foreground"),
        ("bright_foreground", "foreground"),
        ("red", "urgent"),
        ("yellow", "warning"),
        ("orange", "warning"),
        ("green", "success"),
        ("cyan", "accent"),
        ("blue", "accent"),
        ("magenta", "highlight"),
        ("brown", "muted"),
        ("bright_red", "urgent"),
        ("bright_yellow", "highlight"),
        ("bright_green", "success"),
        ("bright_blue", "accent"),
    ] {
        resolved.entry(key).or_insert_with(|| role(fallback));
    }

    for (key, value) in resolved {
        values.insert(
            format!("{key}_strip"),
            value.trim_start_matches('#').to_owned(),
        );
        if let Some((red, green, blue)) = parse_hex(&value) {
            values.insert(format!("{key}_rgb"), format!("{red},{green},{blue}"));
        }
        values.insert(key.to_owned(), value);
    }

    let mut rendered = String::with_capacity(source.len());
    let mut rest = source;
    while let Some(start) = rest.find("{{") {
        rendered.push_str(&rest[..start]);
        let after = &rest[start + 2..];
        let Some(end) = after.find("}}") else {
            rendered.push_str(&rest[start..]);
            return rendered;
        };
        match values.get(after[..end].trim()) {
            Some(value) => rendered.push_str(value),
            None => {
                rendered.push_str("{{");
                rendered.push_str(&after[..end]);
                rendered.push_str("}}");
            }
        }
        rest = &after[end + 2..];
    }
    rendered.push_str(rest);
    rendered
}

fn mako_config(theme: &Theme) -> String {
    let light = theme.mode == "light";
    format!(
        // The dnd mode must exist here, not only be switched on by makoctl: a mode
        // with no criteria attached is registered successfully and changes nothing,
        // which is exactly how do-not-disturb silently did nothing before.
        "font=JetBrains Mono 11\nbackground-color=#{}\ntext-color=#{}ff\nborder-color=#{}\nborder-size=1\nborder-radius=14\ndefault-timeout=5000\nignore-timeout=0\nanchor=top-right\nlayer=overlay\nmargin=12\npadding=14\nwidth=390\nheight=140\nmax-visible=5\nicons=1\nmax-icon-size=48\n\n[mode=dnd]\ninvisible=1\n",
        rgba(theme, "background", if light { "e0" } else { "cc" }),
        theme.colors["foreground"].trim_start_matches('#'),
        rgba(theme, "foreground", if light { "24" } else { "33" }),
    )
}

fn hyprlock_config(theme: &Theme) -> String {
    format!(
        "general {{\n    hide_cursor = true\n    ignore_empty_input = false\n}}\n\nauth {{\n    pam {{\n        enabled = true\n        module = hyprlock\n    }}\n    fingerprint {{ enabled = false }}\n}}\n\nbackground {{\n    monitor =\n    path = screenshot\n    blur_passes = 3\n    blur_size = 8\n    brightness = 0.90\n    contrast = 0.97\n}}\n\nlabel {{\n    monitor =\n    text = $TIME\n    color = rgba({})\n    font_family = JetBrains Mono\n    font_size = 72\n    position = 0, 90\n    halign = center\n    valign = center\n}}\n\ninput-field {{\n    monitor =\n    size = 381, 56\n    outline_thickness = 1\n    rounding = 14\n    dots_size = 0.22\n    dots_spacing = 0.28\n    outer_color = rgba({})\n    inner_color = rgba({})\n    font_color = rgba({})\n    fade_on_empty = false\n    placeholder_text = <span foreground=\"##{}\">Password</span>\n    fail_text = <span foreground=\"##{}\">Failed ($ATTEMPTS)</span>\n    position = 0, -100\n    halign = center\n    valign = center\n}}\n",
        rgba(theme, "foreground", "ff"),
        rgba(theme, "accent", "ff"),
        rgba(
            theme,
            "background",
            if theme.mode == "light" { "e6" } else { "d6" }
        ),
        rgba(theme, "foreground", "ff"),
        theme.colors["muted"].trim_start_matches('#'),
        theme.colors["urgent"].trim_start_matches('#'),
    )
}

fn sync_theme() -> Result<(Theme, PathBuf), CliError> {
    let selected = selected_name()?;
    let (theme, source) = resolve_theme(&selected).or_else(|_| resolve_theme(DEFAULT_THEME))?;
    let output = effective_dir()?;
    atomic_write(&output.join("theme.toml"), &normalized_theme(&theme), 0o600)?;
    // The built-in string stays as the fallback for a machine whose template
    // tree is missing, so a broken install still gets a themed notifier.
    let mako = match template_source("mako.conf.tpl") {
        Some(path) => fs::read_to_string(path)
            .map(|source| render_template(&source, &theme))
            .unwrap_or_else(|_| mako_config(&theme)),
        None => mako_config(&theme),
    };
    atomic_write(&output.join("mako.conf"), &mako, 0o600)?;
    for (template, destination) in [("ghostty.conf.tpl", "ghostty.conf")] {
        let Some(path) = template_source(template) else {
            continue;
        };
        let Ok(source) = fs::read_to_string(path) else {
            continue;
        };
        atomic_write(
            &output.join(destination),
            &render_template(&source, &theme),
            0o600,
        )?;
    }
    atomic_write(
        &output.join("hyprlock.conf"),
        &hyprlock_config(&theme),
        0o600,
    )?;
    atomic_write(
        &output.join("origin.json"),
        &format!(
            "{{\"schemaVersion\":1,\"name\":\"{}\",\"mode\":\"{}\",\"source\":\"{}\"}}\n",
            json_escape(&theme.name),
            theme.mode,
            json_escape(&source.display().to_string())
        ),
        0o600,
    )?;
    Ok((theme, source))
}

pub(crate) fn current_theme() -> Option<Theme> {
    effective_dir()
        .ok()
        .and_then(|path| read_theme(&path.join("theme.toml")).ok())
        .or_else(|| {
            selected_name()
                .ok()
                .and_then(|name| resolve_theme(&name).ok().map(|value| value.0))
        })
}

fn installed_names() -> Result<BTreeSet<String>, CliError> {
    let mut names = BTreeSet::new();
    for root in theme_roots()? {
        let Ok(entries) = fs::read_dir(root) else {
            continue;
        };
        for entry in entries.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            if valid_name(&name) && theme_file_is_safe(&entry.path().join("theme.toml")) {
                names.insert(name);
            }
        }
    }
    Ok(names)
}

fn list_themes() -> Result<(), CliError> {
    let current = selected_name().unwrap_or_else(|_| DEFAULT_THEME.to_owned());
    for name in installed_names()? {
        println!("{}{}", if name == current { "* " } else { "  " }, name);
    }
    Ok(())
}

// The shell used to carry three hardcoded palette rows, so the other themes on
// disk were unreachable from the launcher. A theme is data, and which themes
// exist is a property of the filesystem, not of the interface.
pub(crate) fn themes_json() -> Result<String, CliError> {
    let current = selected_name().unwrap_or_else(|_| DEFAULT_THEME.to_owned());
    let entries = installed_names()?
        .into_iter()
        .filter_map(|name| resolve_theme(&name).ok().map(|(theme, _)| (name, theme)))
        .map(|(name, theme)| {
            format!(
                "{{\"name\":\"{}\",\"label\":\"{}\",\"mode\":\"{}\",\"current\":{}}}",
                json_escape(&name),
                json_escape(&theme.name),
                json_escape(&theme.mode),
                name == current
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    Ok(format!("{{\"schemaVersion\":1,\"items\":[{entries}]}}"))
}

fn validate_target(target: &str) -> Result<(), CliError> {
    let (theme, source) = if valid_name(target) {
        resolve_theme(target)?
    } else {
        let path = PathBuf::from(target);
        (read_theme(&path)?, path)
    };
    println!("ok: {} ({}, {})", theme.name, theme.mode, source.display());
    Ok(())
}

fn set_theme(name: &str) -> Result<(), CliError> {
    let (theme, _) = resolve_theme(name)?;
    let selection = selection_path()?;
    atomic_write(
        &selection,
        &format!("{{\"schemaVersion\":1,\"name\":\"{}\"}}\n", name),
        0o600,
    )?;
    sync_theme()?;
    println!("theme: {}", theme.name);
    Ok(())
}

pub(crate) fn activate_theme(name: &str) -> Result<(), CliError> {
    set_theme(name)
}

pub(crate) fn theme_command(args: &[String]) -> Result<(), CliError> {
    match args {
        [command] if command == "list" => list_themes(),
        [command] if command == "current" => {
            let (theme, source) = sync_theme()?;
            println!("{}\t{}\t{}", theme.name, theme.mode, source.display());
            Ok(())
        }
        [command] if command == "sync" => {
            sync_theme()?;
            Ok(())
        }
        [command, target] if command == "validate" => validate_target(target),
        [command, name] if command == "set" => set_theme(name),
        _ => Err(CliError::Usage(
            "usage: frost theme <list|current|validate TARGET|set NAME|sync>".to_owned(),
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const VALID: &str = r##"schemaVersion = 1
name = "Test"
mode = "dark"

[colors]
background = "#101214"
foreground = "#f0ede8"
muted = "#928f89"
accent = "#7daea3"
urgent = "#ea6962"
highlight = "#d8a657"
success = "#a9b665"
warning = "#d8a657"
"##;

    #[test]
    fn parses_strict_theme() {
        let theme = parse_theme(VALID).unwrap();
        assert_eq!(theme.name, "Test");
        assert_eq!(theme.mode, "dark");
        assert_eq!(theme.colors["accent"], "#7daea3");
    }

    #[test]
    fn rejects_theme_code_and_unknown_fields() {
        assert!(parse_theme(&format!("{VALID}\nscript = \"bad\"\n")).is_err());
        assert!(parse_theme(&VALID.replace("mode = \"dark\"", "mode = \"auto\"")).is_err());
    }

    #[test]
    fn rejects_low_contrast_theme() {
        assert!(parse_theme(&VALID.replace("#f0ede8", "#181818")).is_err());
    }

    #[test]
    fn validates_theme_names() {
        assert!(valid_name("tokyo-night"));
        assert!(!valid_name("../escape"));
        assert!(!valid_name("bad/name"));
    }
}
