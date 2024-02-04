/// The canonical name of the repository containing the current target, without
/// any leading at-signs (@).
pub const current_repository: []const u8 = "{current_repository}";

/// The name of the package containing the current target, without the
/// repository name.
pub const current_package: []const u8 = "{current_package}";

/// The name of the current target, without the repository name or package.
pub const current_target: []const u8 = "{current_target}";
