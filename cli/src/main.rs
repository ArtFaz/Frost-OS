use std::env;
use std::fs;
use std::io::{Read, Write};
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::{Duration, SystemTime};

mod theme;

const VERSION: &str = env!("CARGO_PKG_VERSION");
const SHARE_DIR: &str = "/usr/share/frost";
const ADMIN_CONFIG_DIR: &str = "/etc/frost";
const HYPRLAND_CONFIG: &str = "/usr/share/frost/default/hypr/hyprland.lua";

#[derive(Debug)]
pub(crate) enum CliError {
    Operational(String),
    Usage(String),
}

impl CliError {
    fn message(&self) -> &str {
        match self {
            Self::Operational(message) | Self::Usage(message) => message,
        }
    }

    fn exit_code(&self) -> u8 {
        match self {
            Self::Operational(_) => 1,
            Self::Usage(_) => 2,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum ServiceState {
    Active,
    Inactive,
    Unavailable,
}

impl ServiceState {
    fn as_str(self) -> &'static str {
        match self {
            Self::Active => "active",
            Self::Inactive => "inactive",
            Self::Unavailable => "unavailable",
        }
    }
}

#[derive(Debug)]
struct RuntimeStatus {
    frost_session: bool,
    hyprland_config: Option<String>,
    share_dir: bool,
    admin_config_dir: bool,
    user_config_dir: bool,
    user_state_dir: bool,
    shell: ServiceState,
    session_target: ServiceState,
    notifications: ServiceState,
    polkit: ServiceState,
    idle: ServiceState,
    lock: ServiceState,
    theme_name: String,
    theme_mode: String,
}

#[derive(Debug)]
struct Check {
    name: String,
    ok: bool,
    detail: String,
}

fn main() -> ExitCode {
    match run(env::args().skip(1).collect()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("frost: {}", error.message());
            ExitCode::from(error.exit_code())
        }
    }
}

fn run(args: Vec<String>) -> Result<(), CliError> {
    let Some(command) = args.first().map(String::as_str) else {
        print_help();
        return Ok(());
    };
    let rest = &args[1..];

    match command {
        "help" | "-h" | "--help" => {
            require_no_args(rest, "frost help")?;
            print_help();
        }
        "version" | "-V" | "--version" => {
            require_no_args(rest, "frost version")?;
            println!("frost {VERSION}");
        }
        "status" => status_command(rest)?,
        "doctor" => doctor_command(rest, false)?,
        "verify" => doctor_command(rest, true)?,
        "theme" => theme::theme_command(rest)?,
        "weather" => weather_command(rest)?,
        "session-lock" => session_program(rest, "hyprlock")?,
        "session-notifications" => session_program(rest, "mako")?,
        "shell-data" => shell_data_command(rest)?,
        "shell-action" => shell_action_command(rest)?,
        other => return Err(CliError::Usage(format!("unknown command: {other}"))),
    }
    Ok(())
}

fn session_program(args: &[String], program: &str) -> Result<(), CliError> {
    require_no_args(args, &format!("frost session-{program}"))?;
    let runtime_config = env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .map(|root| root.join(format!("frost/theme/{program}.conf")));
    let fallback = PathBuf::from(format!("/usr/share/frost/default/{program}/config"));
    let fallback = if program == "hyprlock" {
        PathBuf::from("/usr/share/frost/default/hypr/hyprlock.conf")
    } else {
        fallback
    };
    let config = runtime_config
        .filter(|path| {
            fs::symlink_metadata(path).is_ok_and(|metadata| {
                metadata.file_type().is_file()
                    && metadata.mode() & 0o111 == 0
                    && metadata.len() <= 256 * 1024
            })
        })
        .unwrap_or(fallback);
    let executable = format!("/usr/bin/{program}");
    let error = Command::new(&executable).arg("--config").arg(config).exec();
    Err(CliError::Operational(format!(
        "could not start {program}: {error}"
    )))
}

fn print_help() {
    println!(
        "Frost control and diagnostics\n\n\
Usage:\n  frost status [--json]\n  frost doctor [--json]\n  \
frost verify [--json]\n  frost theme <list|current|validate|set|sync>\n  frost weather <current|set CITY|clear>\n  frost version\n\nInternal typed shell interface:\n  \
frost shell-data <brightness|clipboard|images|indicators|notifications|weather>\n  \
frost shell-action ACTION [VALUE]"
    );
}

fn require_no_args(args: &[String], usage: &str) -> Result<(), CliError> {
    if args.is_empty() {
        Ok(())
    } else {
        Err(CliError::Usage(format!("usage: {usage}")))
    }
}

fn json_flag(args: &[String], usage: &str) -> Result<bool, CliError> {
    match args {
        [] => Ok(false),
        [flag] if flag == "--json" => Ok(true),
        _ => Err(CliError::Usage(format!("usage: {usage} [--json]"))),
    }
}

fn home_dir() -> Option<PathBuf> {
    env::var_os("HOME").map(PathBuf::from)
}

fn config_home() -> Option<PathBuf> {
    env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| home_dir().map(|home| home.join(".config")))
}

fn state_home() -> Option<PathBuf> {
    env::var_os("XDG_STATE_HOME")
        .map(PathBuf::from)
        .or_else(|| home_dir().map(|home| home.join(".local/state")))
}

fn service_state(unit: &str) -> ServiceState {
    if !command_exists("systemctl") {
        return ServiceState::Unavailable;
    }
    let result = Command::new("systemctl")
        .args(["--user", "is-active", "--quiet", unit])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
    match result {
        Ok(status) if status.success() => ServiceState::Active,
        Ok(_) => ServiceState::Inactive,
        Err(_) => ServiceState::Unavailable,
    }
}

fn collect_status() -> RuntimeStatus {
    let frost_session = frost_session_environment();
    let active_theme = theme::current_theme();
    RuntimeStatus {
        frost_session,
        hyprland_config: frost_session
            .then(|| env::var("FROST_HYPRLAND_CONFIG").unwrap_or_else(|_| HYPRLAND_CONFIG.into())),
        share_dir: Path::new(SHARE_DIR).is_dir(),
        admin_config_dir: Path::new(ADMIN_CONFIG_DIR).is_dir(),
        user_config_dir: config_home().is_some_and(|path| path.join("frost").is_dir()),
        user_state_dir: state_home().is_some_and(|path| path.join("frost").is_dir()),
        shell: service_state("frost-shell.service"),
        session_target: service_state("frost-session.target"),
        notifications: service_state("frost-notifications.service"),
        polkit: service_state("frost-polkit.service"),
        idle: service_state("frost-idle.service"),
        lock: service_state("frost-lock.service"),
        theme_name: active_theme
            .as_ref()
            .map_or_else(|| "unavailable".to_owned(), |value| value.name.clone()),
        theme_mode: active_theme
            .as_ref()
            .map_or_else(|| "unknown".to_owned(), |value| value.mode.clone()),
    }
}

fn frost_session_environment() -> bool {
    if env::var_os("FROST_SESSION").is_some_and(|value| value == "1") {
        return true;
    }

    env::var("XDG_CURRENT_DESKTOP").is_ok_and(|desktops| {
        desktops
            .split(':')
            .any(|desktop| desktop.eq_ignore_ascii_case("frost"))
    })
}

fn status_command(args: &[String]) -> Result<(), CliError> {
    let json = json_flag(args, "frost status")?;
    let status = collect_status();
    if json {
        println!("{}", status_json(&status));
    } else {
        println!("Frost {}", VERSION);
        println!(
            "session: {}",
            if status.frost_session {
                "frost"
            } else {
                "other"
            }
        );
        println!(
            "hyprland config: {}",
            status
                .hyprland_config
                .as_deref()
                .unwrap_or("not a Frost session")
        );
        println!("session target: {}", status.session_target.as_str());
        println!("shell: {}", status.shell.as_str());
        println!("notifications: {}", status.notifications.as_str());
        println!("polkit: {}", status.polkit.as_str());
        println!("idle: {}", status.idle.as_str());
        println!("lock: {}", status.lock.as_str());
        println!("theme: {} ({})", status.theme_name, status.theme_mode);
        println!("share: {}", present(status.share_dir));
        println!("admin config: {}", present(status.admin_config_dir));
        println!("user config: {}", present(status.user_config_dir));
        println!("user state: {}", present(status.user_state_dir));
    }
    Ok(())
}

fn status_json(status: &RuntimeStatus) -> String {
    format!(
        "{{\"schemaVersion\":1,\"version\":\"{}\",\"frostSession\":{},\"hyprlandConfig\":{},\"theme\":{{\"name\":\"{}\",\"mode\":\"{}\"}},\"paths\":{{\"share\":{},\"adminConfig\":{},\"userConfig\":{},\"userState\":{}}},\"services\":{{\"sessionTarget\":\"{}\",\"shell\":\"{}\",\"notifications\":\"{}\",\"polkit\":\"{}\",\"idle\":\"{}\",\"lock\":\"{}\"}}}}",
        json_escape(VERSION),
        status.frost_session,
        status
            .hyprland_config
            .as_ref()
            .map(|path| format!("\"{}\"", json_escape(path)))
            .unwrap_or_else(|| "null".to_owned()),
        json_escape(&status.theme_name),
        json_escape(&status.theme_mode),
        status.share_dir,
        status.admin_config_dir,
        status.user_config_dir,
        status.user_state_dir,
        status.session_target.as_str(),
        status.shell.as_str(),
        status.notifications.as_str(),
        status.polkit.as_str(),
        status.idle.as_str(),
        status.lock.as_str()
    )
}

fn present(value: bool) -> &'static str {
    if value { "present" } else { "missing" }
}

fn collect_checks(strict: bool) -> Vec<Check> {
    let mut checks = Vec::new();
    for command in [
        "Hyprland",
        "uwsm",
        "ghostty",
        "mako",
        "hyprlock",
        "hypridle",
        "quickshell",
        "wpctl",
        "brightnessctl",
        "curl",
        "jq",
        "notify-send",
        "wl-paste",
        "cliphist",
        "systemctl",
        "systemd-inhibit",
    ] {
        checks.push(Check {
            name: format!("command:{command}"),
            ok: command_exists(command),
            detail: command.to_owned(),
        });
    }

    let polkit_agent = PathBuf::from("/usr/lib/hyprpolkitagent/hyprpolkitagent");
    checks.push(Check {
        name: "command:hyprpolkitagent".to_owned(),
        ok: executable_regular_file(&polkit_agent),
        detail: polkit_agent.display().to_string(),
    });

    for (name, path) in [
        ("path:share", PathBuf::from(SHARE_DIR)),
        ("path:admin-config", PathBuf::from(ADMIN_CONFIG_DIR)),
    ] {
        checks.push(Check {
            name: name.to_owned(),
            ok: path.is_dir(),
            detail: path.display().to_string(),
        });
    }

    if strict {
        for (name, relative_path) in [
            ("file:shell-defaults", "config/shell.json"),
            ("file:shell-root", "shell/shell.qml"),
            ("file:hyprland-config", "default/hypr/hyprland.lua"),
            ("file:hypridle-config", "default/hypr/hypridle.conf"),
            ("file:hyprlock-config", "default/hypr/hyprlock.conf"),
            ("file:mako-config", "default/mako/config"),
        ] {
            let defaults = Path::new(SHARE_DIR).join(relative_path);
            checks.push(Check {
                name: name.to_owned(),
                ok: regular_non_executable_file(&defaults),
                detail: defaults.display().to_string(),
            });
        }
    }
    checks
}

fn doctor_command(args: &[String], strict: bool) -> Result<(), CliError> {
    let usage = if strict {
        "frost verify"
    } else {
        "frost doctor"
    };
    let json = json_flag(args, usage)?;
    let checks = collect_checks(strict);
    let ok = checks.iter().all(|check| check.ok);

    if json {
        println!("{}", checks_json(&checks, ok));
    } else {
        for check in &checks {
            println!(
                "{}: {} ({})",
                if check.ok { "ok" } else { "fail" },
                check.name,
                check.detail
            );
        }
    }

    if ok {
        Ok(())
    } else {
        Err(CliError::Operational(format!(
            "{} check(s) failed",
            checks.iter().filter(|check| !check.ok).count()
        )))
    }
}

fn checks_json(checks: &[Check], ok: bool) -> String {
    let entries = checks
        .iter()
        .map(|check| {
            format!(
                "{{\"name\":\"{}\",\"ok\":{},\"detail\":\"{}\"}}",
                json_escape(&check.name),
                check.ok,
                json_escape(&check.detail)
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    format!(
        "{{\"schemaVersion\":1,\"ok\":{},\"checks\":[{}]}}",
        ok, entries
    )
}

fn regular_non_executable_file(path: &Path) -> bool {
    fs::symlink_metadata(path)
        .is_ok_and(|metadata| metadata.file_type().is_file() && metadata.mode() & 0o111 == 0)
}

fn executable_regular_file(path: &Path) -> bool {
    fs::symlink_metadata(path)
        .is_ok_and(|metadata| metadata.file_type().is_file() && metadata.mode() & 0o111 != 0)
}

fn command_exists(program: &str) -> bool {
    let Some(path) = env::var_os("PATH") else {
        return false;
    };
    env::split_paths(&path).any(|directory| {
        let candidate = directory.join(program);
        fs::metadata(candidate)
            .is_ok_and(|metadata| metadata.is_file() && metadata.mode() & 0o111 != 0)
    })
}

fn json_escape(value: &str) -> String {
    let mut escaped = String::with_capacity(value.len());
    for character in value.chars() {
        match character {
            '"' => escaped.push_str("\\\""),
            '\\' => escaped.push_str("\\\\"),
            '\n' => escaped.push_str("\\n"),
            '\r' => escaped.push_str("\\r"),
            '\t' => escaped.push_str("\\t"),
            character if character.is_control() => {
                escaped.push_str(&format!("\\u{:04x}", character as u32));
            }
            character => escaped.push(character),
        }
    }
    escaped
}

fn shell_data_command(args: &[String]) -> Result<(), CliError> {
    let [kind] = args else {
        return Err(CliError::Usage(
            "usage: frost shell-data <brightness|wifi|wifi-scan|power|battery-threshold|privacy|indicators|notifications|clipboard|images|wallpapers|themes|weather>"
                .to_owned(),
        ));
    };
    let json = match kind.as_str() {
        "brightness" => brightness_json()?,
        "wifi" => wifi_json(false)?,
        "wifi-scan" => wifi_json(true)?,
        "power" => power_json()?,
        "battery-threshold" => battery_threshold_json()?,
        "privacy" => privacy_json(),
        "clipboard" => clipboard_json()?,
        "images" => images_json()?,
        "wallpapers" => wallpapers_json()?,
        "themes" => theme::themes_json()?,
        "indicators" => indicators_json(),
        "notifications" => notifications_json()?,
        "weather" => weather_json()?,
        _ => {
            return Err(CliError::Usage(format!(
                "unsupported shell data source: {kind}"
            )));
        }
    };
    println!("{json}");
    Ok(())
}

fn capture(program: &str, args: &[&str]) -> Result<Vec<u8>, CliError> {
    let output = Command::new(program)
        .args(args)
        .output()
        .map_err(|error| CliError::Operational(format!("could not run {program}: {error}")))?;
    if !output.status.success() {
        return Err(CliError::Operational(format!(
            "{program} returned an error"
        )));
    }
    if output.stdout.len() > 4 * 1024 * 1024 {
        return Err(CliError::Operational(format!(
            "{program} output is too large"
        )));
    }
    Ok(output.stdout)
}

/// A backlight device name is a kernel object name, so it may only contain the
/// characters the sysfs path is allowed to carry. Anything else is treated as
/// no device rather than being interpolated into a path.
fn valid_backlight_device(name: &str) -> bool {
    !name.is_empty()
        && name.len() <= 64
        && name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '_' | '-' | '.' | ':'))
}

/// Session actions are scheduled a couple of seconds out rather than run
/// immediately, so the shell has time to draw its on-screen notice before the
/// session goes away. The transient unit is what actually performs the action,
/// which means it survives the shell exiting.
fn schedule_session_action(command: &[&str]) -> Result<(), CliError> {
    let mut arguments = vec![
        "--user",
        "--collect",
        "--quiet",
        "--on-active=2s",
        "--timer-property=AccuracySec=100ms",
    ];
    arguments.extend_from_slice(command);
    run_fixed("/usr/bin/systemd-run", &arguments)
}

fn brightness_json() -> Result<String, CliError> {
    let raw = capture("/usr/bin/brightnessctl", &["-m"])?;
    let text = String::from_utf8_lossy(&raw);
    let line = text.trim();
    let percent = line
        .split(',')
        .nth(3)
        .and_then(|value| value.trim_end_matches('%').parse::<u8>().ok())
        .filter(|value| *value <= 100)
        .ok_or_else(|| CliError::Operational("invalid brightness response".to_owned()))?;
    // The shell polls the sysfs attribute directly so the OSD reacts to any tool
    // that changes brightness, not only to frost-osd. It cannot glob for the
    // device, so the resolved path is reported here.
    let device = line.split(',').next().unwrap_or("").trim();
    let path = if valid_backlight_device(device) {
        format!("/sys/class/backlight/{device}")
    } else {
        String::new()
    };
    Ok(format!(
        "{{\"schemaVersion\":1,\"available\":true,\"percent\":{percent},\"devicePath\":\"{path}\"}}"
    ))
}

fn split_nmcli_line(line: &str) -> Vec<String> {
    let mut fields = Vec::new();
    let mut field = String::new();
    let mut escaped = false;
    for character in line.chars() {
        if escaped {
            field.push(character);
            escaped = false;
        } else if character == '\\' {
            escaped = true;
        } else if character == ':' {
            fields.push(field);
            field = String::new();
        } else {
            field.push(character);
        }
    }
    if escaped {
        field.push('\\');
    }
    fields.push(field);
    fields
}

fn wifi_json(rescan: bool) -> Result<String, CliError> {
    let radio =
        String::from_utf8_lossy(&capture("/usr/bin/nmcli", &["-t", "-f", "WIFI", "radio"])?)
            .trim()
            .to_owned();
    let raw = capture(
        "/usr/bin/nmcli",
        &[
            "-t",
            "-f",
            "active,ssid,signal,security",
            "dev",
            "wifi",
            "list",
            "--rescan",
            if rescan { "yes" } else { "no" },
        ],
    )?;
    // Which SSIDs NetworkManager already holds a profile for. Without this the
    // shell has to discover it by attempting a connection and watching it fail,
    // which costs a real association attempt on every new secured network.
    let saved_raw = capture(
        "/usr/bin/nmcli",
        &["-t", "-f", "NAME,TYPE", "connection", "show"],
    )
    .unwrap_or_default();
    let saved_text = String::from_utf8_lossy(&saved_raw);
    let mut saved_profiles = std::collections::HashSet::new();
    for line in saved_text.lines().take(512) {
        let parts = split_nmcli_line(line);
        if parts.len() < 2 || parts[1].trim() != "802-11-wireless" {
            continue;
        }
        let name = parts[0].trim();
        if !name.is_empty() {
            saved_profiles.insert(name.to_owned());
        }
    }

    let text = String::from_utf8_lossy(&raw);
    let mut network_order = Vec::new();
    let mut network_state = std::collections::HashMap::new();
    let mut active_ssid = String::new();
    let mut active_signal = 0_u8;
    for line in text.lines().take(256) {
        let parts = split_nmcli_line(line);
        if parts.len() < 4 {
            continue;
        }
        let ssid = parts[1].trim();
        if ssid.is_empty() {
            continue;
        }
        let active = parts[0] == "yes";
        let signal = parts[2].parse::<u8>().unwrap_or(0).min(100);
        let security = parts[3..].join(":");
        let secured = !security.trim().is_empty() && security.trim() != "--";
        if !network_state.contains_key(ssid) {
            network_order.push(ssid.to_owned());
        }
        let state = network_state
            .entry(ssid.to_owned())
            .or_insert((0_u8, secured, false));
        if active || signal > state.0 {
            state.0 = signal;
            state.1 = secured;
        }
        state.2 = state.2 || active;
        if active {
            active_ssid = ssid.to_owned();
            active_signal = signal;
        }
    }
    let networks = network_order
        .iter()
        .filter_map(|ssid| {
            network_state.get(ssid).map(|(signal, secured, active)| {
                format!(
                    "{{\"ssid\":\"{}\",\"signal\":{},\"secured\":{},\"active\":{},\"saved\":{}}}",
                    json_escape(ssid),
                    signal,
                    secured,
                    active,
                    saved_profiles.contains(ssid)
                )
            })
        })
        .collect::<Vec<_>>();
    Ok(format!(
        "{{\"schemaVersion\":1,\"radioEnabled\":{},\"activeSsid\":\"{}\",\"activeSignal\":{},\"networks\":[{}]}}",
        radio == "enabled",
        json_escape(&active_ssid),
        active_signal,
        networks.join(",")
    ))
}

fn power_json() -> Result<String, CliError> {
    let active = String::from_utf8_lossy(&capture("/usr/bin/powerprofilesctl", &["get"])?)
        .trim()
        .to_owned();
    let list_raw = capture("/usr/bin/powerprofilesctl", &["list"])?;
    let list = String::from_utf8_lossy(&list_raw).into_owned();
    let profiles = ["power-saver", "balanced", "performance"]
        .into_iter()
        .filter(|profile| list.contains(profile))
        .map(|profile| format!("\"{profile}\""))
        .collect::<Vec<_>>();
    Ok(format!(
        "{{\"schemaVersion\":1,\"available\":{},\"activeProfile\":\"{}\",\"profiles\":[{}]}}",
        !profiles.is_empty()
            && profiles
                .iter()
                .any(|profile| profile == &format!("\"{active}\"")),
        json_escape(&active),
        profiles.join(",")
    ))
}

fn upower_battery_path() -> Result<Option<String>, CliError> {
    let raw = capture("/usr/bin/upower", &["-e"])?;
    Ok(String::from_utf8_lossy(&raw)
        .lines()
        .find(|line| line.contains("/battery_"))
        .map(str::to_owned))
}

fn battery_threshold_json() -> Result<String, CliError> {
    let Some(path) = upower_battery_path()? else {
        return Ok(
            "{\"schemaVersion\":1,\"supported\":false,\"enabled\":false,\"start\":-1,\"end\":-1}"
                .to_owned(),
        );
    };
    let output = Command::new("/usr/bin/busctl")
        .args([
            "get-property",
            "org.freedesktop.UPower",
            &path,
            "org.freedesktop.UPower.Device",
            "ChargeStartThreshold",
            "ChargeEndThreshold",
            "ChargeThresholdEnabled",
            "ChargeThresholdSupported",
        ])
        .output()
        .map_err(|error| {
            CliError::Operational(format!("could not query battery threshold: {error}"))
        })?;
    if !output.status.success() {
        return Ok(
            "{\"schemaVersion\":1,\"supported\":false,\"enabled\":false,\"start\":-1,\"end\":-1}"
                .to_owned(),
        );
    }
    let values = String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|line| {
            line.split_once(' ')
                .map(|(_, value)| value.trim().to_owned())
        })
        .collect::<Vec<_>>();
    if values.len() < 4 {
        return Err(CliError::Operational(
            "invalid battery threshold response".to_owned(),
        ));
    }
    Ok(format!(
        "{{\"schemaVersion\":1,\"supported\":{},\"enabled\":{},\"start\":{},\"end\":{}}}",
        values[3] == "true",
        values[2] == "true",
        values[0].parse::<i16>().unwrap_or(-1),
        values[1].parse::<i16>().unwrap_or(-1)
    ))
}

fn privacy_json() -> String {
    let mut camera = false;
    if let Ok(processes) = fs::read_dir("/proc") {
        'processes: for process in processes.flatten().take(32768) {
            if !process
                .file_name()
                .to_string_lossy()
                .bytes()
                .all(|byte| byte.is_ascii_digit())
            {
                continue;
            }
            let Ok(descriptors) = fs::read_dir(process.path().join("fd")) else {
                continue;
            };
            for descriptor in descriptors.flatten().take(4096) {
                if fs::read_link(descriptor.path())
                    .is_ok_and(|path| path.to_string_lossy().starts_with("/dev/video"))
                {
                    camera = true;
                    break 'processes;
                }
            }
        }
    }
    format!("{{\"schemaVersion\":1,\"camera\":{camera}}}")
}

fn clipboard_json() -> Result<String, CliError> {
    let raw = capture("/usr/bin/cliphist", &["list"])?;
    let text = String::from_utf8_lossy(&raw);
    let entries = text
        .lines()
        .take(100)
        .filter_map(|line| {
            let (id, preview) = line.split_once('\t')?;
            if id.is_empty() || !id.bytes().all(|byte| byte.is_ascii_digit()) {
                return None;
            }
            if preview.trim_start().starts_with("[[ binary data") {
                return None;
            }
            Some(format!(
                "{{\"id\":{},\"preview\":\"{}\"}}",
                id,
                json_escape(preview)
            ))
        })
        .collect::<Vec<_>>()
        .join(",");
    Ok(format!("{{\"schemaVersion\":1,\"items\":[{entries}]}}"))
}

fn picture_roots() -> Vec<PathBuf> {
    let Some(home) = home_dir() else {
        return Vec::new();
    };
    [home.join("Pictures"), home.join("Imagens")]
        .into_iter()
        .filter_map(|path| path.canonicalize().ok())
        .filter(|path| path.is_dir())
        .collect()
}

fn image_extension(path: &Path) -> Option<&'static str> {
    match path.extension()?.to_str()?.to_ascii_lowercase().as_str() {
        "png" => Some("image/png"),
        "jpg" | "jpeg" => Some("image/jpeg"),
        "webp" => Some("image/webp"),
        _ => None,
    }
}

fn collect_images(directory: &Path, depth: u8, output: &mut Vec<(u64, PathBuf)>) {
    if depth > 2 || output.len() >= 200 {
        return;
    }
    let Ok(entries) = fs::read_dir(directory) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let Ok(metadata) = fs::symlink_metadata(&path) else {
            continue;
        };
        if metadata.file_type().is_symlink() {
            continue;
        }
        if metadata.is_dir() {
            collect_images(&path, depth + 1, output);
        } else if metadata.is_file() && image_extension(&path).is_some() {
            let modified = metadata
                .modified()
                .ok()
                .and_then(|time| time.duration_since(std::time::UNIX_EPOCH).ok())
                .map_or(0, |duration| duration.as_secs());
            output.push((modified, path));
        }
        if output.len() >= 200 {
            break;
        }
    }
}

fn images_json() -> Result<String, CliError> {
    let mut images = Vec::new();
    for root in picture_roots() {
        collect_images(&root, 0, &mut images);
    }
    images.sort_by(|left, right| right.0.cmp(&left.0));
    let entries = images
        .into_iter()
        .take(100)
        .map(|(_, path)| {
            let name = path
                .file_name()
                .and_then(|value| value.to_str())
                .unwrap_or("Image");
            format!(
                "{{\"path\":\"{}\",\"name\":\"{}\"}}",
                json_escape(&path.display().to_string()),
                json_escape(name)
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    Ok(format!("{{\"schemaVersion\":1,\"items\":[{entries}]}}"))
}

fn json_value_or_empty(raw: Vec<u8>) -> String {
    let value = String::from_utf8_lossy(&raw).trim().to_owned();
    if value.starts_with('[') || value.starts_with('{') {
        value
    } else {
        "[]".to_owned()
    }
}

/// Mako owns notifications; Frost only ever reads and acts through makoctl.
/// A mode lookup that fails must not take the whole panel down with it, so the
/// do-not-disturb flag degrades to false instead of erroring.
fn mako_dnd_enabled() -> bool {
    let Ok(raw) = capture("/usr/bin/makoctl", &["mode"]) else {
        return false;
    };
    String::from_utf8_lossy(&raw)
        .lines()
        .any(|line| line.trim() == "dnd")
}

fn notifications_json() -> Result<String, CliError> {
    let active = json_value_or_empty(capture("/usr/bin/makoctl", &["list", "-j"])?);
    let history = json_value_or_empty(capture("/usr/bin/makoctl", &["history", "-j"])?);
    let dnd = mako_dnd_enabled();
    Ok(format!(
        "{{\"schemaVersion\":1,\"dnd\":{dnd},\"active\":{active},\"history\":{history}}}"
    ))
}

fn user_unit_active(unit: &str) -> bool {
    Command::new("/usr/bin/systemctl")
        .args(["--user", "is-active", "--quiet", unit])
        .status()
        .is_ok_and(|status| status.success())
}

fn indicators_json() -> String {
    format!(
        "{{\"schemaVersion\":1,\"reminder\":{},\"stayAwake\":{}}}",
        user_unit_active("frost-reminder.timer"),
        user_unit_active("frost-stay-awake.service")
    )
}

fn reminder_set(value: &str, message: Option<&str>) -> Result<(), CliError> {
    let minutes = value
        .parse::<u16>()
        .ok()
        .filter(|minutes| (1..=1440).contains(minutes))
        .ok_or_else(|| CliError::Usage("reminder must be between 1 and 1440 minutes".to_owned()))?;
    let message = message.unwrap_or("Your Frost reminder is due.").trim();
    if !valid_reminder_message(message) {
        return Err(CliError::Usage(
            "reminder message must contain 1 to 120 printable characters".to_owned(),
        ));
    }
    if user_unit_active("frost-reminder.timer") {
        run_fixed(
            "/usr/bin/systemctl",
            &["--user", "stop", "frost-reminder.timer"],
        )?;
    }
    let delay = format!("{minutes}m");
    run_fixed(
        "/usr/bin/systemd-run",
        &[
            "--user",
            "--quiet",
            "--unit=frost-reminder",
            "--on-active",
            &delay,
            "--timer-property=AccuracySec=1s",
            "/usr/bin/notify-send",
            "--app-name=Frost",
            "--icon=alarm-symbolic",
            "Frost reminder",
            message,
        ],
    )
}

fn valid_reminder_message(value: &str) -> bool {
    let value = value.trim();
    !value.is_empty() && value.chars().count() <= 120 && !value.chars().any(char::is_control)
}

fn stay_awake_toggle() -> Result<(), CliError> {
    run_fixed(
        "/usr/bin/systemctl",
        &[
            "--user",
            if user_unit_active("frost-stay-awake.service") {
                "stop"
            } else {
                "start"
            },
            "frost-stay-awake.service",
        ],
    )
}

fn valid_weather_city(value: &str) -> bool {
    let trimmed = value.trim();
    (2..=80).contains(&trimmed.chars().count())
        && trimmed.chars().all(|character| {
            character.is_alphanumeric()
                || character.is_whitespace()
                || [',', '.', '-', '\'', '(', ')'].contains(&character)
        })
        && !trimmed.chars().any(char::is_control)
}

fn weather_config_path() -> Option<PathBuf> {
    config_home().map(|root| root.join("frost/weather.json"))
}

fn selected_weather_city() -> Result<Option<String>, CliError> {
    let Some(path) = weather_config_path() else {
        return Ok(None);
    };
    if fs::symlink_metadata(&path).is_ok_and(|metadata| {
        !metadata.file_type().is_file() || metadata.mode() & 0o111 != 0 || metadata.len() > 4096
    }) {
        return Err(CliError::Usage(
            "weather configuration is not a safe regular data file".to_owned(),
        ));
    }
    let Ok(raw) = fs::read_to_string(path) else {
        return Ok(None);
    };
    let raw = raw.trim();
    let prefix = "{\"schemaVersion\":1,\"city\":\"";
    let suffix = "\"}";
    if !raw.starts_with(prefix) || !raw.ends_with(suffix) {
        return Err(CliError::Usage(
            "invalid Frost weather configuration".to_owned(),
        ));
    }
    let city = &raw[prefix.len()..raw.len() - suffix.len()];
    if !valid_weather_city(city) {
        return Err(CliError::Usage(
            "invalid configured weather city".to_owned(),
        ));
    }
    Ok(Some(city.to_owned()))
}

fn weather_cache_path() -> Option<PathBuf> {
    env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| home_dir().map(|home| home.join(".cache")))
        .map(|root| root.join("frost/weather.json"))
}

fn atomic_user_write(path: &Path, contents: &[u8]) -> Result<(), CliError> {
    let parent = path
        .parent()
        .ok_or_else(|| CliError::Operational("state path has no parent".to_owned()))?;
    fs::create_dir_all(parent)
        .map_err(|error| CliError::Operational(format!("could not create state path: {error}")))?;
    fs::set_permissions(parent, fs::Permissions::from_mode(0o700))
        .map_err(|error| CliError::Operational(format!("could not secure state path: {error}")))?;
    let temporary = path.with_extension("tmp");
    fs::write(&temporary, contents)
        .map_err(|error| CliError::Operational(format!("could not write state: {error}")))?;
    fs::set_permissions(&temporary, fs::Permissions::from_mode(0o600))
        .map_err(|error| CliError::Operational(format!("could not secure state: {error}")))?;
    fs::rename(&temporary, path)
        .map_err(|error| CliError::Operational(format!("could not publish state: {error}")))
}

fn percent_encode(value: &str) -> String {
    let mut encoded = String::new();
    for byte in value.as_bytes() {
        if byte.is_ascii_alphanumeric() || [b'-', b'_', b'.', b'~'].contains(byte) {
            encoded.push(char::from(*byte));
        } else {
            encoded.push_str(&format!("%{byte:02X}"));
        }
    }
    encoded
}

fn capture_with_input(program: &str, args: &[&str], input: &[u8]) -> Result<Vec<u8>, CliError> {
    let mut child = Command::new(program)
        .args(args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|error| CliError::Operational(format!("could not run {program}: {error}")))?;
    child
        .stdin
        .take()
        .ok_or_else(|| CliError::Operational("could not open process input".to_owned()))?
        .write_all(input)
        .map_err(|error| {
            CliError::Operational(format!("could not write process input: {error}"))
        })?;
    let output = child
        .wait_with_output()
        .map_err(|error| CliError::Operational(format!("could not wait for {program}: {error}")))?;
    if !output.status.success() || output.stdout.len() > 256 * 1024 {
        return Err(CliError::Operational(format!(
            "{program} returned invalid output"
        )));
    }
    Ok(output.stdout)
}

fn weather_fetch(city: &str) -> Result<String, CliError> {
    let geocoding_url = format!(
        "https://geocoding-api.open-meteo.com/v1/search?name={}&count=1&language=en&format=json",
        percent_encode(city)
    );
    let geocoding = capture(
        "/usr/bin/curl",
        &[
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--proto",
            "=https",
            "--proto-redir",
            "=https",
            "--max-time",
            "6",
            "--max-filesize",
            "131072",
            &geocoding_url,
        ],
    )?;
    let coordinates = capture_with_input(
        "/usr/bin/jq",
        &["-r", ".results[0] | \"\\(.latitude) \\(.longitude)\""],
        &geocoding,
    )?;
    let coordinates = String::from_utf8_lossy(&coordinates);
    let mut coordinates = coordinates.split_whitespace();
    let latitude = coordinates
        .next()
        .and_then(|value| value.parse::<f64>().ok())
        .filter(|value| (-90.0..=90.0).contains(value))
        .ok_or_else(|| CliError::Operational("weather city was not found".to_owned()))?;
    let longitude = coordinates
        .next()
        .and_then(|value| value.parse::<f64>().ok())
        .filter(|value| (-180.0..=180.0).contains(value))
        .ok_or_else(|| CliError::Operational("weather city was not found".to_owned()))?;
    if coordinates.next().is_some() {
        return Err(CliError::Operational(
            "invalid weather coordinate response".to_owned(),
        ));
    }
    let forecast_url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=5&timezone=auto"
    );
    let forecast = capture(
        "/usr/bin/curl",
        &[
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--proto",
            "=https",
            "--proto-redir",
            "=https",
            "--max-time",
            "6",
            "--max-filesize",
            "131072",
            &forecast_url,
        ],
    )?;
    let filter = r#"{schemaVersion:1,configured:true,city:$city,current:{temperature:(.current.temperature_2m // null),apparent:(.current.apparent_temperature // null),humidity:(.current.relative_humidity_2m // null),code:(.current.weather_code // null),isDay:(.current.is_day // null)},daily:[range(0;([((.daily.time // [])|length),5]|min)) as $i|{date:.daily.time[$i],code:.daily.weather_code[$i],minimum:.daily.temperature_2m_min[$i],maximum:.daily.temperature_2m_max[$i],precipitation:.daily.precipitation_probability_max[$i]}]}"#;
    let normalized = capture_with_input(
        "/usr/bin/jq",
        &["-c", "--arg", "city", city, filter],
        &forecast,
    )?;
    let normalized = String::from_utf8(normalized)
        .map_err(|_| CliError::Operational("weather output is not UTF-8".to_owned()))?;
    let normalized = normalized.trim();
    if normalized.len() > 64 * 1024 || !normalized.starts_with('{') || !normalized.ends_with('}') {
        return Err(CliError::Operational(
            "weather output is not bounded JSON".to_owned(),
        ));
    }
    Ok(normalized.to_owned())
}

fn weather_json() -> Result<String, CliError> {
    let Some(city) = selected_weather_city()? else {
        return Ok("{\"schemaVersion\":1,\"configured\":false}".to_owned());
    };
    if let Some(cache) = weather_cache_path() {
        if let Ok(metadata) = fs::symlink_metadata(&cache) {
            let fresh = metadata.file_type().is_file()
                && metadata.mode() & 0o111 == 0
                && metadata.len() <= 64 * 1024
                && metadata.modified().is_ok_and(|modified| {
                    SystemTime::now()
                        .duration_since(modified)
                        .unwrap_or(Duration::MAX)
                        < Duration::from_secs(15 * 60)
                });
            if fresh {
                if let Ok(value) = fs::read_to_string(&cache) {
                    let value = value.trim();
                    let expected_city = format!("\"city\":\"{}\"", city);
                    if value.starts_with('{')
                        && value.ends_with('}')
                        && value.contains(&expected_city)
                    {
                        return Ok(value.to_owned());
                    }
                }
            }
        }
        let value = weather_fetch(&city)?;
        atomic_user_write(&cache, value.as_bytes())?;
        return Ok(value);
    }
    weather_fetch(&city)
}

fn weather_command(args: &[String]) -> Result<(), CliError> {
    match args {
        [command] if command == "current" => {
            println!(
                "{}",
                selected_weather_city()?.as_deref().unwrap_or("disabled")
            );
            Ok(())
        }
        [command, city] if command == "set" && valid_weather_city(city) => {
            let path = weather_config_path().ok_or_else(|| {
                CliError::Operational("weather config home is unavailable".to_owned())
            })?;
            atomic_user_write(
                &path,
                format!("{{\"schemaVersion\":1,\"city\":\"{}\"}}\n", city.trim()).as_bytes(),
            )?;
            if let Some(cache) = weather_cache_path() {
                let _ = fs::remove_file(cache);
            }
            println!("weather city: {}", city.trim());
            Ok(())
        }
        [command] if command == "clear" => {
            if let Some(path) = weather_config_path() {
                match fs::remove_file(path) {
                    Ok(()) => {}
                    Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
                    Err(error) => {
                        return Err(CliError::Operational(format!(
                            "could not clear weather city: {error}"
                        )));
                    }
                }
            }
            if let Some(cache) = weather_cache_path() {
                let _ = fs::remove_file(cache);
            }
            println!("weather city: disabled");
            Ok(())
        }
        _ => Err(CliError::Usage(
            "usage: frost weather <current|set CITY|clear>".to_owned(),
        )),
    }
}

fn shell_action_command(args: &[String]) -> Result<(), CliError> {
    let Some(action) = args.first().map(String::as_str) else {
        return Err(CliError::Usage(
            "usage: frost shell-action ACTION [VALUE]".to_owned(),
        ));
    };
    if env::var_os("FROST_PREVIEW").is_some_and(|value| value == "1")
        && ["lock", "logout", "poweroff", "reboot", "suspend"].contains(&action)
    {
        return Err(CliError::Operational(format!(
            "{action} is blocked during a Frost shell preview"
        )));
    }
    if action == "reminder-set" {
        return match args {
            [_, value] => reminder_set(value, None),
            [_, value, message] => reminder_set(value, Some(message)),
            _ => Err(CliError::Usage(
                "usage: frost shell-action reminder-set MINUTES [MESSAGE]".to_owned(),
            )),
        };
    }
    if action == "wifi-connect" {
        let [_, ssid] = args else {
            return Err(CliError::Usage(
                "usage: frost shell-action wifi-connect SSID".to_owned(),
            ));
        };
        return wifi_connect(ssid);
    }
    let argument = args.get(1).map(String::as_str);
    if args.len() > 2 {
        return Err(CliError::Usage(
            "usage: frost shell-action ACTION [VALUE]".to_owned(),
        ));
    }
    match (action, argument) {
        ("brightness-down", None) => run_fixed("/usr/lib/frost/frost-osd", &["brightness-down"]),
        ("brightness-up", None) => run_fixed("/usr/lib/frost/frost-osd", &["brightness-up"]),
        ("brightness-set", Some(value)) => set_brightness(value),
        ("wifi-radio", Some(value @ ("on" | "off"))) => {
            run_fixed("/usr/bin/nmcli", &["radio", "wifi", value])
        }
        ("bluetooth-radio", Some("on")) => run_fixed("/usr/bin/rfkill", &["unblock", "bluetooth"]),
        ("bluetooth-radio", Some("off")) => run_fixed("/usr/bin/rfkill", &["block", "bluetooth"]),
        ("wifi-disconnect", Some(ssid)) if valid_ssid(ssid) => {
            run_fixed("/usr/bin/nmcli", &["con", "down", "id", ssid])
        }
        ("wifi-forget", Some(ssid)) if valid_ssid(ssid) => {
            run_fixed("/usr/bin/nmcli", &["con", "delete", "id", ssid])
        }
        ("power-profile", Some(profile @ ("power-saver" | "balanced" | "performance"))) => {
            run_fixed("/usr/bin/powerprofilesctl", &["set", profile])
        }
        ("battery-threshold", Some(value @ ("on" | "off"))) => set_battery_threshold(value == "on"),
        ("clipboard-copy", Some(id)) => copy_clipboard_entry(id),
        ("image-copy", Some(path)) => copy_image(Path::new(path)),
        ("wallpaper-set", Some(path)) => set_wallpaper(Path::new(path)),
        ("lock", None) => run_fixed(
            "/usr/bin/systemctl",
            &["--user", "start", "frost-lock.service"],
        ),
        ("logout", None) => schedule_session_action(&["/usr/bin/uwsm", "stop"]),
        ("open-terminal", None) => spawn_fixed("/usr/bin/uwsm", &["app", "--", "/usr/bin/ghostty"]),
        ("notification-clear", None) => run_fixed("/usr/bin/makoctl", &["dismiss", "--all"]),
        ("notification-dnd", Some("on")) => run_fixed("/usr/bin/makoctl", &["mode", "-a", "dnd"]),
        ("notification-dnd", Some("off")) => run_fixed("/usr/bin/makoctl", &["mode", "-r", "dnd"]),
        ("notification-dismiss", Some(id)) if valid_numeric(id, u32::MAX) => {
            run_fixed("/usr/bin/makoctl", &["dismiss", "-n", id])
        }
        ("notification-invoke", Some(id)) if valid_numeric(id, u32::MAX) => {
            run_fixed("/usr/bin/makoctl", &["invoke", "-n", id])
        }
        ("theme-set", Some(name)) => theme::activate_theme(name),
        ("reminder-clear", None) => run_fixed(
            "/usr/bin/systemctl",
            &["--user", "stop", "frost-reminder.timer"],
        ),
        ("stay-awake-toggle", None) => stay_awake_toggle(),
        ("poweroff", None) => schedule_session_action(&["/usr/bin/systemctl", "poweroff"]),
        ("reboot", None) => schedule_session_action(&["/usr/bin/systemctl", "reboot"]),
        ("suspend", None) => run_fixed("/usr/bin/systemctl", &["suspend"]),
        _ => Err(CliError::Usage(format!(
            "unsupported or invalid shell action: {action}"
        ))),
    }
}

fn valid_ssid(value: &str) -> bool {
    let bytes = value.as_bytes();
    !bytes.is_empty() && bytes.len() <= 32 && !value.chars().any(char::is_control)
}

fn valid_wifi_password(value: &str) -> bool {
    value.is_empty()
        || ((8..=63).contains(&value.as_bytes().len())
            && value.is_ascii()
            && !value.chars().any(char::is_control))
}

fn wifi_connect(ssid: &str) -> Result<(), CliError> {
    if !valid_ssid(ssid) {
        return Err(CliError::Usage("invalid Wi-Fi SSID".to_owned()));
    }
    let mut password = String::new();
    std::io::stdin()
        .take(128)
        .read_to_string(&mut password)
        .map_err(|error| CliError::Operational(format!("could not read Wi-Fi secret: {error}")))?;
    let password = password.trim_end_matches(['\r', '\n']);
    if !valid_wifi_password(password) {
        return Err(CliError::Usage(
            "Wi-Fi password must be empty or 8 to 63 printable ASCII bytes".to_owned(),
        ));
    }
    if password.is_empty() {
        return run_fixed("/usr/bin/nmcli", &["dev", "wifi", "connect", ssid]);
    }
    let mut child = Command::new("/usr/bin/nmcli")
        .args(["--ask", "dev", "wifi", "connect", ssid])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|error| CliError::Operational(format!("could not start nmcli: {error}")))?;
    child
        .stdin
        .take()
        .ok_or_else(|| CliError::Operational("nmcli stdin is unavailable".to_owned()))?
        .write_all(format!("{password}\n").as_bytes())
        .map_err(|error| CliError::Operational(format!("could not send Wi-Fi secret: {error}")))?;
    if child.wait().is_ok_and(|status| status.success()) {
        Ok(())
    } else {
        Err(CliError::Operational(
            "nmcli could not connect to the network".to_owned(),
        ))
    }
}

fn set_battery_threshold(enabled: bool) -> Result<(), CliError> {
    let path = upower_battery_path()?
        .ok_or_else(|| CliError::Operational("battery is unavailable".to_owned()))?;
    run_fixed(
        "/usr/bin/busctl",
        &[
            "call",
            "org.freedesktop.UPower",
            &path,
            "org.freedesktop.UPower.Device",
            "EnableChargeThreshold",
            "b",
            if enabled { "true" } else { "false" },
        ],
    )
}

fn valid_numeric(value: &str, maximum: u32) -> bool {
    !value.is_empty()
        && value.bytes().all(|byte| byte.is_ascii_digit())
        && value.parse::<u32>().is_ok_and(|number| number <= maximum)
}

fn run_fixed(program: &str, args: &[&str]) -> Result<(), CliError> {
    let status = Command::new(program)
        .args(args)
        .status()
        .map_err(|error| CliError::Operational(format!("could not run {program}: {error}")))?;
    if status.success() {
        Ok(())
    } else {
        Err(CliError::Operational(format!(
            "{program} returned an error"
        )))
    }
}

fn spawn_fixed(program: &str, args: &[&str]) -> Result<(), CliError> {
    Command::new(program)
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map(|_| ())
        .map_err(|error| CliError::Operational(format!("could not start {program}: {error}")))
}

fn set_brightness(value: &str) -> Result<(), CliError> {
    if !valid_numeric(value, 100) {
        return Err(CliError::Usage(
            "brightness must be between 0 and 100".to_owned(),
        ));
    }
    let percent = format!("{value}%");
    run_fixed("/usr/bin/brightnessctl", &["set", &percent])
}

fn copy_clipboard_entry(id: &str) -> Result<(), CliError> {
    if !valid_numeric(id, u32::MAX) {
        return Err(CliError::Usage("invalid clipboard entry id".to_owned()));
    }
    let decoded = capture("/usr/bin/cliphist", &["decode", id])?;
    write_to_clipboard(&decoded, None)
}

/// Roots a wallpaper may come from. Wider than the clipboard's picture roots
/// because the packaged theme backgrounds live under /usr/share.
fn wallpaper_roots() -> Vec<PathBuf> {
    let mut roots = picture_roots();
    roots.push(PathBuf::from("/usr/share/frost/backgrounds"));
    roots
}

fn wallpapers_json() -> Result<String, CliError> {
    let mut images = Vec::new();
    collect_images(
        &PathBuf::from("/usr/share/frost/backgrounds"),
        0,
        &mut images,
    );
    if let Some(source) = env::var_os("FROST_SOURCE_ROOT").map(PathBuf::from) {
        collect_images(&source.join("backgrounds"), 0, &mut images);
    }
    images.sort_by(|left, right| left.1.cmp(&right.1));
    let entries = images
        .into_iter()
        .take(200)
        .map(|(_, path)| {
            let name = path
                .file_stem()
                .and_then(|value| value.to_str())
                .unwrap_or("Wallpaper");
            format!(
                "{{\"path\":\"{}\",\"name\":\"{}\"}}",
                json_escape(&path.display().to_string()),
                json_escape(name)
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    Ok(format!("{{\"schemaVersion\":1,\"items\":[{entries}]}}"))
}

fn set_wallpaper(path: &Path) -> Result<(), CliError> {
    let canonical = path
        .canonicalize()
        .map_err(|_| CliError::Usage("wallpaper path does not exist".to_owned()))?;
    if !wallpaper_roots()
        .iter()
        .any(|root| canonical.starts_with(root))
    {
        return Err(CliError::Usage(
            "wallpaper path is outside the permitted roots".to_owned(),
        ));
    }
    if image_extension(&canonical).is_none() {
        return Err(CliError::Usage("unsupported image type".to_owned()));
    }
    let metadata = fs::symlink_metadata(&canonical)
        .map_err(|_| CliError::Usage("wallpaper path is not readable".to_owned()))?;
    if !metadata.is_file() || metadata.mode() & 0o111 != 0 {
        return Err(CliError::Usage(
            "wallpaper is not a safe regular file".to_owned(),
        ));
    }

    let home = env::var_os("HOME")
        .map(PathBuf::from)
        .ok_or_else(|| CliError::Operational("HOME is unavailable".to_owned()))?;
    let state = home.join(".local/state/frost");
    fs::create_dir_all(&state).map_err(|error| {
        CliError::Operational(format!("could not create state directory: {error}"))
    })?;
    // A JSON pointer rather than the donor's symlink: the shell reads state as
    // validated data everywhere else, and the contracts reject symlinks.
    let body = format!(
        "{{\"schemaVersion\":1,\"path\":\"{}\"}}\n",
        json_escape(&canonical.display().to_string())
    );
    let temporary = state.join("background.json.tmp");
    fs::write(&temporary, body)
        .map_err(|error| CliError::Operational(format!("could not write selection: {error}")))?;
    fs::rename(&temporary, state.join("background.json"))
        .map_err(|error| CliError::Operational(format!("could not publish selection: {error}")))
}

fn copy_image(path: &Path) -> Result<(), CliError> {
    let canonical = path
        .canonicalize()
        .map_err(|_| CliError::Usage("image path does not exist".to_owned()))?;
    if !picture_roots()
        .iter()
        .any(|root| canonical.starts_with(root))
    {
        return Err(CliError::Usage(
            "image path is outside the Pictures directories".to_owned(),
        ));
    }
    let mime = image_extension(&canonical)
        .ok_or_else(|| CliError::Usage("unsupported image type".to_owned()))?;
    let metadata = fs::metadata(&canonical)
        .map_err(|_| CliError::Usage("image path is not readable".to_owned()))?;
    if !metadata.is_file() || metadata.len() > 32 * 1024 * 1024 {
        return Err(CliError::Usage(
            "image is not a safe regular file".to_owned(),
        ));
    }
    let data = fs::read(canonical)
        .map_err(|error| CliError::Operational(format!("could not read image: {error}")))?;
    write_to_clipboard(&data, Some(mime))
}

fn write_to_clipboard(data: &[u8], mime: Option<&str>) -> Result<(), CliError> {
    let mut command = Command::new("/usr/bin/wl-copy");
    if let Some(mime) = mime {
        command.args(["--type", mime]);
    }
    let mut child = command
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|error| CliError::Operational(format!("could not start wl-copy: {error}")))?;
    child
        .stdin
        .take()
        .ok_or_else(|| CliError::Operational("wl-copy stdin is unavailable".to_owned()))?
        .write_all(data)
        .map_err(|error| CliError::Operational(format!("could not write clipboard: {error}")))?;
    let status = child
        .wait()
        .map_err(|error| CliError::Operational(format!("could not wait for wl-copy: {error}")))?;
    if status.success() {
        Ok(())
    } else {
        Err(CliError::Operational(
            "wl-copy returned an error".to_owned(),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_json_flag_strictly() {
        assert_eq!(json_flag(&[], "frost status").unwrap(), false);
        assert_eq!(
            json_flag(&["--json".to_owned()], "frost status").unwrap(),
            true
        );
        assert!(json_flag(&["--other".to_owned()], "frost status").is_err());
        assert!(json_flag(&["--json".to_owned(), "extra".to_owned()], "frost status").is_err());
    }

    #[test]
    fn escapes_json_control_characters() {
        assert_eq!(json_escape("a\"b\\c\n"), "a\\\"b\\\\c\\n");
    }

    #[test]
    fn status_json_is_machine_readable_shape() {
        let status = RuntimeStatus {
            frost_session: true,
            hyprland_config: Some(HYPRLAND_CONFIG.to_owned()),
            share_dir: true,
            admin_config_dir: false,
            user_config_dir: true,
            user_state_dir: false,
            shell: ServiceState::Active,
            session_target: ServiceState::Active,
            notifications: ServiceState::Inactive,
            polkit: ServiceState::Unavailable,
            idle: ServiceState::Active,
            lock: ServiceState::Inactive,
            theme_name: "Gruvbox".to_owned(),
            theme_mode: "dark".to_owned(),
        };
        let json = status_json(&status);
        assert!(json.starts_with("{\"schemaVersion\":1,"));
        assert!(json.contains("\"frostSession\":true"));
        assert!(json.contains("\"hyprlandConfig\":\"/usr/share/frost/default/hypr/hyprland.lua\""));
        assert!(json.contains("\"sessionTarget\":\"active\""));
        assert!(json.contains("\"shell\":\"active\""));
    }

    #[test]
    fn usage_errors_exit_with_two() {
        let error = CliError::Usage("bad input".to_owned());
        assert_eq!(error.exit_code(), 2);
    }

    #[test]
    fn validates_typed_numeric_arguments() {
        assert!(valid_numeric("0", 100));
        assert!(valid_numeric("100", 100));
        assert!(!valid_numeric("101", 100));
        assert!(!valid_numeric("1;reboot", 100));
        assert!(!valid_numeric("", 100));
    }

    #[test]
    fn parses_nmcli_escaped_fields() {
        assert_eq!(
            split_nmcli_line(r"yes:Cafe\: Office:87:WPA2"),
            ["yes", "Cafe: Office", "87", "WPA2"]
        );
        assert_eq!(split_nmcli_line(r"no:Lab\\AP:41:--")[1], r"Lab\AP");
    }

    #[test]
    fn validates_wifi_credentials_as_bounded_data() {
        assert!(valid_ssid("Frost Lab"));
        assert!(!valid_ssid(""));
        assert!(!valid_ssid("network\n--ask"));
        assert!(!valid_ssid(&"x".repeat(33)));
        assert!(valid_wifi_password(""));
        assert!(valid_wifi_password("ice-cold"));
        assert!(!valid_wifi_password("short"));
        assert!(!valid_wifi_password("password\ncommand"));
        assert!(!valid_wifi_password("senha-com-acentuação"));
    }

    #[test]
    fn accepts_only_supported_image_types() {
        assert_eq!(image_extension(Path::new("image.png")), Some("image/png"));
        assert_eq!(image_extension(Path::new("photo.JPEG")), Some("image/jpeg"));
        assert_eq!(image_extension(Path::new("vector.svg")), None);
        assert_eq!(image_extension(Path::new("script.sh")), None);
    }

    #[test]
    fn rejects_non_json_process_output() {
        assert_eq!(json_value_or_empty(b"warning".to_vec()), "[]");
        assert_eq!(
            json_value_or_empty(b"[{\"id\":1}]".to_vec()),
            "[{\"id\":1}]"
        );
    }

    #[test]
    fn validates_weather_city_as_data() {
        assert!(valid_weather_city("São Paulo, Brazil"));
        assert!(valid_weather_city("St. John's"));
        assert!(!valid_weather_city("x"));
        assert!(!valid_weather_city("City\n--config"));
        assert!(!valid_weather_city("City\" --data"));
    }

    #[test]
    fn validates_reminder_messages_as_bounded_data() {
        assert!(valid_reminder_message("Take a break"));
        assert!(!valid_reminder_message(""));
        assert!(!valid_reminder_message("message\nsecond command"));
        assert!(!valid_reminder_message(&"x".repeat(121)));
    }

    #[test]
    fn percent_encodes_weather_queries() {
        assert_eq!(
            percent_encode("São Paulo, Brazil"),
            "S%C3%A3o%20Paulo%2C%20Brazil"
        );
    }
}
