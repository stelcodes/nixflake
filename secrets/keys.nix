# REKEY ALL SECRETS AFTER ADDING OR REMOVING KEYS!
# cd ~/.config/nixflake/secrets && agenix --rekey
rec {
  adminKeys = {
    yuffie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMoyiraMgUblF095KJA1l3h1sHTwjLiIOe5GHy36Hk7 stel@yuffie";
    marlene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUIrkV61xmxSAGQLMatmK0hzPvp+Iekq74pW/Weep9a";
    universal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKCjwHHrbo1Mn0wlsw3xh0g4NjIVkPeykQLyZr8AjU9";
  };
  systemKeys = {
    yuffie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDf8xRlLjwAln+oiJJ0xAiKjIsRauL/kqn044L5atIw";
    aerith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0gcrRzwgxftyr8HS1slRhsB5TadtFkWm8FVc20xpKw";
    sora = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILehD91ViQ62nG/Fsucel1Evy9wzjhW8IJ+AkR6PQqs3";
  };
  allAdminKeys = builtins.attrValues adminKeys;
  allSystemKeys = builtins.attrValues systemKeys;
  allKeys = allAdminKeys ++ allSystemKeys;
}
