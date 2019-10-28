#!/bin/sh

# Name:         llama (Lightweight Linux Automated Monitoring Agent
# Version:      0.0.1
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script for monitoring and sending Slack Webhooks and Email alerts
#               Written in bash so it can be run on different releases

# Set some defaults

host_name=$(hostname)
do_slack="no"
do_list="no"
do_email="no"
do_false="no"
do_dryrun="no"
do_verbose="no"

# Get the path the script starts from

start_path=$(pwd)

# Get the script info from the script itself

app_vers=$(cd "$start_path" || exit ; grep "^# Version" "$0" |awk '{print $3}')
app_name=$(cd "$start_path" || exit ; grep "^# Name" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}')
app_pkgr=$(cd "$start_path" || exit ; grep "^# Packager" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}')
app_help=$(cd "$start_path" || exit ; grep -A1 " [A-Z,a-z])$" "$0" |sed "s/[#,\-\-]//g" |sed '/^\s*$/d')

# Set up directory for storing Slack hook etc

home_dir=$HOME
llama_dir="$home_dir/.llama"
slack_file="$llama_dir/slack_hook_file"
email_file="$llama_dir/email_list_file"
check_file="$llama_dir/checks.json"
os_name=$(uname)

# Create config directory if not present

if [ ! -d "$llama_dir" ]; then
  mkdir -p "$llama_dir"
fi

# Work out which package manager to use

if [ -f "/etc/redhat-release" ]; then
  pkg_bin="yum"
else
  pkg_bin="apt-get"
fi

# Check we are running on a supported OS

os_check() {
  if [ ! "$os_name" = "Linux" ] ; then
    echo "Currently only Linux is supported"
    exit
  fi
  return
}

# Print some help

print_help() {
  echo "$app_name $app_vers"
  echo "$app_pkgr"
  echo ""
  echo "Usage Information:"
  echo ""
  echo "$app_help"
  echo ""
  return
}

# Install check

install_check() {
  os_check
  if [ -z "$(command -v mail)" ]; then
    sudo $pkg_bin install -y mailutils
  fi
  if [ -z "$(command -v jq)" ]; then
    sudo $pkg_bin install -y jq
  fi
  return
}

# Handle alert

handle_alert() {
  title=$1
  value=$2
  do_false=$3
  if [ "$do_false" = "yes" ]; then
    message="Testing"
  else
    message="Warning"
  fi
  if [ "$do_slack" = "yes" ]; then
    curl -X POST -H 'Content-type: application/json' --data "{'text':'$message $title on $host_name does not return $value'}" "$slack_hook"

  fi
  if [ "$do_email" = "yes" ]; then
    echo "Warning $title on $host_name does not return $value" | mail -s "$message $title on $host_name does not return $value" "$alert_email"
  fi
  return
}

# Do checks

do_checks() {
  do_list=$1
  do_check=$2
  do_dryrun=$3
  do_false=$4
  do_verbose=$5
  length=$(jq length "$check_file")
  length=$(expr "$length" - 1)
  for counter in $(seq 0 "$length") ; do  
    title=$(jq -r ".[$counter].title" "$check_file")
    check=$(jq -r ".[$counter].check" "$check_file")
    value=$(jq -r ".[$counter].value" "$check_file")
    if [ "$do_list" = "yes" ] ; then
      echo "Title: $title"
      echo "Check: $check"
      echo "Value: $value"
    else
      if [ "$do_verbose" = "yes" ] ; then
        echo "Title: $title"
        echo "Check: $check"
        echo "Value: $value"
      fi
      output=$(eval $check)
      if [ "$output" != "$value" ] || [ "$do_false" = "yes" ]; then
        if [ "$do_dryrun" = "yes" ] ; then
          echo "Warning: $title does not return $value"
        else
          handle_alert "$title" "$value" "$do_false"
        fi
      else
        if [ "$do_dryrun" = "yes" ] ; then
          echo "Correct: $title returns $value"
        fi
      fi
    fi
  done
  return
}

# Handle command line arguments

while getopts "Vvhsmlfcd" opt; do
  case $opt in
    V)
      # Display Version
      echo "$app_vers"
      exit
      ;;
    f)
      # Create false alerts
      do_false="yes"
      ;;
    h)
      # Display Usage Information
      print_help
      exit
      ;;
    s)
      # Use Slack to post alerts
      do_slack="yes"
      ;;
    m)
      # Email alerts
      do_email="yes"
      ;;
    l)
      # List checks
      do_list="yes"
      ;;
    d)
      # Do Dry Run
      do_dryrun="yes"
      ;;
    c)
      # Run checks 
      do_check="yes"
      ;;
    v)
      # Run in verbose mode
      do_verbose="yes"
      ;;
    *)
      print_help
      exit
      ;;
  esac
done

# Handle Slack hook

if [ "$do_slack" = "yes" ]; then
  if [ -f "$slack_file" ] ; then
    slack_hook=$(cat "$slack_file")
  else
    echo "Warning Slack hook file $slack_file does not exist"
    exit
  fi
fi

#Handle alert email address

if [ "$do_email" = "yes" ]; then
  if [ -f "$email_file" ] ; then
    alert_email=$(cat "$email_file")
  else
    echo "Warning email alert list file $email_file does not exist"
    exit
  fi
fi

# Handle checks

if [ "$do_list" = "yes" ] || [ "$do_check" = "yes" ]; then
  if [ ! -e "$check_file" ]; then
    echo "Check file: $check_file does not exist" 
    exit
  fi
  do_checks "$do_list" "$do_check" "$do_dryrun" "$do_false"
  exit
fi

# If given no command line arguments print usage information

if expr "$opt" : "\-" != 1; then
  print_help
  exit
fi
