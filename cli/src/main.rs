use std::env;
use std::fs;
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};

const VERSION: &str = env!("CARGO_PKG_VERSION");
const SHARE_DIR: &str = "/usr/share/frost";
const ADMIN_CONFIG_DIR: &str = "/etc/frost";
const HYPRLAND_CONFIG: &str = "/usr/share/frost/default/hypr/hyprland.lua";

#[derive(Debug)]
enum CliError {
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
        other => return Err(CliError::Usage(format!("unknown command: {other}"))),
    }
    Ok(())
}

fn print_help() {
    println!(
        "Frost control and diagnostics\n\n\
Usage:\n  frost status [--json]\n  frost doctor [--json]\n  \
frost verify [--json]\n  frost version"
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
        println!("share: {}", present(status.share_dir));
        println!("admin config: {}", present(status.admin_config_dir));
        println!("user config: {}", present(status.user_config_dir));
        println!("user state: {}", present(status.user_state_dir));
    }
    Ok(())
}

fn status_json(status: &RuntimeStatus) -> String {
    format!(
        "{{\"schemaVersion\":1,\"version\":\"{}\",\"frostSession\":{},\"hyprlandConfig\":{},\"paths\":{{\"share\":{},\"adminConfig\":{},\"userConfig\":{},\"userState\":{}}},\"services\":{{\"sessionTarget\":\"{}\",\"shell\":\"{}\",\"notifications\":\"{}\",\"polkit\":\"{}\",\"idle\":\"{}\",\"lock\":\"{}\"}}}}",
        json_escape(VERSION),
        status.frost_session,
        status
            .hyprland_config
            .as_ref()
            .map(|path| format!("\"{}\"", json_escape(path)))
            .unwrap_or_else(|| "null".to_owned()),
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
        "wl-paste",
        "cliphist",
        "systemctl",
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
}
