{ pkgs, ... }:
{
  config = {

    services.gitea = {
      enable = false;
      appName = "Stel's Gitea";
      stateDir = "/data/gitea";
      database.type = "postgres";
      dump = {
        enable = true;
        interval = "5:00";
      };
      domain = "git.stel.codes";
      rootUrl = "https://git.stel.codes";
      httpPort = 3000;
      cookieSecure = true;
      disableRegistration = true;
      settings = {
        api = {
          ENABLE_SWAGGER = false;
        };
        repository = {
          DISABLE_HTTP_GIT = true;
          DEFAULT_BRANCH = "main";
        };
        ui = {
          DEFAULT_THEME = "arc-green";
        };
        security = {
          INSTALL_LOCK = true;
          SECRET_KEY = "IvDiP5wNKoNkYg7rlmHfQZVxAOCl6xYPorYXV4t746GQ7GNlMYiarqcKCsqUXFNT";
        };
        mail = {
          ENABLES = true;
          FROM = "gitea@git.stel.codes";
          MAILER_TYPE = "smtp";
          HOST = "smtp.mailgun.org:587";
          IS_TLS_ENABLED = true;
          USER = "postmaster@sandbox6b576e2e5db145fa8a2833aebe918517.mailgun.org";
          PASSWORD = "0450caa70c93fe11c7c0b782915954ca-fa6e84b7-0e581df9";
        };
      };
    };
  };
}
