{
  description = "LinuxPods - AirPods support for Linux (daemon, CLI and KDE Plasma 6 widget)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        linuxpods = pkgs.callPackage ./package.nix { };
        default = linuxpods;
      });

      overlays.default = final: _prev: {
        linuxpods = final.callPackage ./package.nix { };
      };

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.linuxpods;
        in
        {
          options.programs.linuxpods = {
            enable = lib.mkEnableOption "LinuxPods, AirPods support for Linux";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "linuxpods.packages.\${system}.default";
              description = "The LinuxPods package to use. Must have a `plasmoid` output.";
            };

            plasmoid.enable = lib.mkEnableOption "the LinuxPods KDE Plasma 6 system tray widget";
          };

          config = lib.mkIf cfg.enable {
            hardware.bluetooth.enable = lib.mkDefault true;

            environment.systemPackages = [
              cfg.package
            ] ++ lib.optional cfg.plasmoid.enable cfg.package.plasmoid;

            # D-Bus session activation file + systemd user unit
            services.dbus.packages = [ cfg.package ];
            systemd.packages = [ cfg.package ];
            systemd.user.services.linuxpods-daemon.wantedBy = [ "default.target" ];

            environment.pathsToLink = lib.mkIf cfg.plasmoid.enable [ "/share/plasma" ];
          };
        };
    };
}
