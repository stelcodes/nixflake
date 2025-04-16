# REKEY ALL SECRETS AFTER ADDING OR REMOVING KEYS!
# cd ~/.config/nixflake/secrets && agenix --rekey
rec {
  adminKeys = {
    yuffie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMoyiraMgUblF095KJA1l3h1sHTwjLiIOe5GHy36Hk7 stel@yuffie";
    marlene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUIrkV61xmxSAGQLMatmK0hzPvp+Iekq74pW/Weep9a";
  };
  systemKeys = {
    yuffie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDf8xRlLjwAln+oiJJ0xAiKjIsRauL/kqn044L5atIw";
    aerith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHq8GNrmE18CJia7L0vZdTFEBEk2+XSzGp44wQYvH/TG";
  };
  allAdminKeys = builtins.attrValues adminKeys;
  allSystemKeys = builtins.attrValues systemKeys;
  allKeys = allAdminKeys ++ allSystemKeys;
}
