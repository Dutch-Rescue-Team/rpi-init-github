#!/bin/bash -e

usage () {
  echo "Usage:"
  echo "  rpi-init-github.sh init <git user name> <git user email>"
  echo "  rpi-init-github.sh get_pub"
  echo "  rpi-init-github.sh clone <github owner/repo> <passphrase>"
}

invalid_usage () {
  echo ""
  echo "ERROR: Invalid usage."
  echo ""
  usage
  echo ""
  exit 1
}

rootfs_cid () {
  local root_partition="$(findmnt / -o source -n)"
  local root_device="$(lsblk -no pkname "$root_partition")"
  local root_cid_file="/sys/block/$root_device/device/cid"
  SDCARD_CID=$(cat /sys/block/mmcblk0/device/cid)
}

init_global () {
  local CURRENT_TIME=$(date +"%g%m%d_%H%M")
  rootfs_cid
  GIT_EMAIL=$(git config user.email)
  KEY_FILE="${HOME}/.ssh/${GIT_EMAIL}@drt.github__sdcard_${SDCARD_CID}_id"
  SSH_CFG_FILE="${HOME}/.ssh/config"
  PUB_TITLE="${GIT_EMAIL}@drt.github__sdcard_${SDCARD_CID}"
  PUB_COMMENT="${PUB_TITLE}__${CURRENT_TIME}"
  PUB_FILE="${KEY_FILE}.pub"
  CLONE_PARENT_DIR="${HOME}/src"
}

ssh_keygen () {
  local passphrase="$1"
  expect << EOF
    spawn ssh-keygen -t ed25519 -C "$PUB_COMMENT" -f ${KEY_FILE}
    expect "Enter passphrase*"
    send -- "${passphrase}\r"
    expect "Enter same passphrase*"
    send -- "${passphrase}\r"
    expect eof
EOF
}

ssh_add () {
  local passphrase="$1"
  eval $(ssh-agent)
  expect << EOF
    spawn ssh-add ${KEY_FILE}
    expect "Enter passphrase*"
    send -- "${passphrase}\r"
    expect eof
EOF
}

get_pub () {
  echo "FEEDBACK[KEY TITLE]: $PUB_TITLE"
  echo "FEEDBACK[PUBLIC KEY]: $(cat "$PUB_FILE")"
}

ssh_config_file () {
  if [ -f "$SSH_CFG_FILE" ]; then
    echo "FEEDBACK[SSH CONFIG DONE]: False"
  else
    echo "Host github.com
    Hostname github.com
    IdentityFile $KEY_FILE
    IdentitiesOnly yes" > $SSH_CFG_FILE
    echo "FEEDBACK[SSH CONFIG DONE]: True"
  fi
}

git_clone() {
  local owner_slash_repo="$1"
  local passphrase="$2"
  local repo=$(echo "$owner_slash_repo" | cut -d "/" -f 2)
  if [[ "$passphrase" != "" ]]; then
    ssh_add "$passphrase"
  fi
  mkdir -p "$CLONE_PARENT_DIR"
  rm -r -f "$CLONE_PARENT_DIR/$repo"
  expect << EOF
    spawn git clone git@github.com:${owner_slash_repo}.git "$CLONE_PARENT_DIR/$repo"
    expect {
	  {Are you sure you want to continue connecting (yes/no/} {
        send -- "yes\r"
		exp_continue
	  }
	  eof
	}
EOF
}

cmd_init () {
  git config --global user.name "$1"
  git config --global user.email "$2"
  local do_no_passphrase="$3"
  local passphrase=""
  echo "FEEDBACK[do_no_passphrase]: $do_no_passphrase"
  init_global
  rm -f "$KEY_FILE"
  rm -f "$PUB_FILE"
  if [[ "$do_no_passphrase" != "True" ]]; then
    passphrase=$(pwgen -s -N 1 48 1)
  fi
  ssh_keygen "$passphrase"
  ssh_config_file
  get_pub
  echo "FEEDBACK[PASSPHRASE]: $passphrase"
}

cmd_get_pub () {
  init_global
  get_pub
}

cmd_clone () {
  init_global
  git_clone "$1" "$2"
}

# Main

command="$1"
echo "COMMAND: $command"
if [[ "$command" == "init" ]]; then
  if [ $# -ne 4 ]; then
    invalid_usage
  fi
  cmd_init "$2" "$3" "$4"
elif [[ "$command" == "get_pub" ]]; then
  if [ $# -ne 0 ]; then
    invalid_usage
  fi
  cmd_get_pub
elif [[ "$command" == "clone" ]]; then
  if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    invalid_usage
  fi
  cmd_clone "$2" "$3"
else
    invalid_usage
fi
echo -e "\nFEEDBACK[NORMAL END]"
