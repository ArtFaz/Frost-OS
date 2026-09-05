use std::fs;
use std::os::unix::fs::MetadataExt;

use crate::{CliError, command_exists, run_fixed};

const SNAPSHOT_REF: &str = "/var/lib/frost/last-update-snapshot";
const LOG: &str = "/var/log/frost-update.log";

/// `frost update` — snapshot, one pacman transaction, AUR refresh, verify.
///
/// The privileged half (`/usr/lib/frost/frost-update`, sudoers-gated) takes a
/// mandatory verified pre-update snapshot and runs `pacman -Syu`. The AUR
/// refresh and `frost verify` run as this user, because paru refuses to build
/// as root.
pub(crate) fn update_command(args: &[String]) -> Result<(), CliError> {
    if !args.is_empty() {
        return Err(CliError::Usage("usage: frost update".to_owned()));
    }
    if running_as_root() {
        return Err(CliError::Usage(
            "run frost update as your user, not root — it escalates only where it must".to_owned(),
        ));
    }

    run_fixed("/usr/bin/sudo", &["/usr/lib/frost/frost-update"]).map_err(|_| {
        CliError::Operational(format!(
            "the update transaction failed — see {LOG}; the pre-update snapshot number is in {SNAPSHOT_REF}"
        ))
    })?;

    if command_exists("paru") {
        println!("frost update: refreshing AUR packages");
        if run_fixed("/usr/bin/paru", &["-Syu"]).is_err() {
            eprintln!("frost update: paru -Syu reported an error; re-run it yourself");
        }
    } else {
        println!("frost update: paru not found — AUR packages were not refreshed");
    }

    println!("frost update: verifying");
    run_fixed("/usr/bin/frost", &["verify"]).map_err(|_| {
        CliError::Operational(format!(
            "frost verify failed after the update — restore the pre-update snapshot (number in {SNAPSHOT_REF}) with snapper, or boot it from the Limine menu"
        ))
    })
}

fn running_as_root() -> bool {
    fs::metadata("/proc/self")
        .map(|meta| meta.uid() == 0)
        .unwrap_or(false)
}
