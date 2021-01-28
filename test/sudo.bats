#!/usr/bin/env bats

# https://ubuntu.com/security/CVE-2021-3156

@test "It should install a sudo version protected from CVE-2021-3156" {
  actual_version="$(dpkg-query --showformat='${Version}' --show sudo)"
  echo "Installed sudo: $actual_version"
  echo "Desired sudo:   $SUDO_MIN"
  dpkg --compare-versions "$actual_version" "ge" "$SUDO_MIN"
}
