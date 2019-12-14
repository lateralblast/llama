#!/bin/sh

# Name:         llama (Lightweight Linux Automated Monitoring Agent
# Version:      0.0.7
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
do_update="no"

# Check to see if we're using a user copy of jq in ~/bin

if [ -f "$HOME/bin/jq" ] ; then
  jq_bin="$HOME/bin/jq"
else
  jq_bin="$(command -v jq)"
  if [ "$jq_bin" = "" ] ; then
    os_name="$(uname -s)"
    if [ "$os_name" = "Darwin" ] ; then
      brew_bin="(command -v brew)"
      if [ ! "$brew_bin" = "" ] ; then
        brew install jq
      fi
      jq_bin="(command -v jq)"
      if [ "$jq_bin" = "" ] ; then
        echo "Warning: Could not find jq" 
        exit
      fi
    else
      echo "Warning: Could not find jq" 
      exit
    fi
  fi 
fi

# Get the path the script starts from

app_file="$0"
app_path=$(dirname "$app_file")
app_base=$(basename "$app_file")

# Get the script info from the script itself

app_vers=$(grep "^# Version" "$0" |awk '{print $3}')
app_name=$(grep "^# Name" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}' |sed 's/ $//g')
app_same=$(grep "^# Name" "$0" |awk '{print $3}')
app_pkgr=$(grep "^# Packager" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}')
app_help=$(grep -A1 " [A-Z,a-z])$" "$0" |sed "s/[#,\-\-]//g" |sed '/^\s*$/d')

# Code to handle updates

handle_vers() {
  echo "$@" |awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

check_update() {
  do_update=$1
  rem_vers_url="https://raw.githubusercontent.com/lateralblast/$app_same/master/version"
  rem_app_url="https://raw.githubusercontent.com/lateralblast/$app_same/master/$app_base"
  rem_vers_dir="/tmp/$app_same"
  if [ ! -d "$rem_vers_dir" ] ; then
    mkdir "$rem_vers_dir"
  fi
  rem_vers_file="$rem_vers_dir/version"
  printf "Checking %s is up to date... " "$app_same"
  if [ -f "$rem_vers_file" ] ; then
    rm "$rem_vers_file"
  fi
  curl -s -o "$rem_vers_file" "$rem_vers_url"
  if [ -f "$rem_vers_file" ] ; then
    rem_vers=$(cat "$rem_vers_file")
    if [ "$(handle_vers "$rem_vers")" -gt "$(handle_vers "$app_vers")" ]; then
      printf "Newer version of %s exists\n" "$app_same"
      if [ "$do_update" = "yes" ] ; then
        echo "Updating $app_same"
        curl -s -o "$app_file" "$rem_app_url"
      fi
    else
      printf "%s is up to date\n" "$app_same"
    fi
  fi
}

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
  email=$3
  slack=$4
  if [ "$do_false" = "yes" ]; then
    message="Testing"
  else
    message="Warning"
  fi
  if [ "$do_slack" = "yes" ] && [ ! "$slack" = "none" ] ; then
    if [ "$verbose" = "yes" ] ; then
      echo "Slack Alert: $message $title on $host_name does not return $value"
    fi
    curl -X POST -H 'Content-type: application/json' --data "{'text':'$message $title on $host_name does not return $value'}" "$slack"
  fi
  if [ "$do_email" = "yes" ] && [ ! "$email" = "none" ] ; then
    if [ "$verbose" = "yes" ] ; then
      echo "Email Alert: $message $title on $host_name does not return $value"
    fi
    echo "Warning $title on $host_name does not return $value" | mail -s "$message $title on $host_name does not return $value" "$email"
  fi
  return
}

# Do checks

do_checks() {
  f_email=$1
  f_slack=$2
  correct="no"
  length=$($jq_bin length "$check_file")
  length=$(expr "$length" - 1)
  for counter in $(seq 0 "$length") ; do  
    title=$($jq_bin -r ".[$counter].title" "$check_file")
    check=$($jq_bin -r ".[$counter].check" "$check_file")
    value=$($jq_bin -r ".[$counter].value" "$check_file")
    j_email=$($jq_bin -r ".[$counter].email" "$check_file")
    j_slack=$($jq_bin -r ".[$counter].slack" "$check_file")
    funct=$($jq_bin -r ".[$counter].funct" "$check_file")
    if [ ! "$j_email" = "" ] ; then
      email="$j_email"
    else
      email="$f_email"
    fi
    if [ ! "$j_slack" = "" ] ; then
      slack="$j_slack"
    else
      slack="$f_slack"
    fi
    funct=$(echo "$funct" |sed 's/ //g' |tr '[:upper:]' '[:lower:]')
    if [ "$funct" = "null" ] ; then
      funct="="
    fi
    case $funct in
      "null")
        funct="="
        ;;
      "<"|"lt"|"lessthan")
        funct="-lt"
        ;;
      "<="|"le"|"lessthanequalto")
        funct="-le"
        ;;
      ">"|"gt"|"greaterthan")
        funct="-gt"
        ;;
      ">="|"ge"|"greaterthanorequalto")
        funct="-ge"
        ;;
      "ne"|"notequal")
        funct="!="
        ;;
      *|"equals")
        funct="="
        ;;
    esac
    if [ "$do_list" = "yes" ] ; then
      echo "Title: $title"
      echo "Check: $check"
      echo "Value: $value"
      echo "Funct: $funct"
      echo "Email: $email"
      echo "Slack: $slack"
    else
      if [ "$do_verbose" = "yes" ] ; then
        echo "Title: $title"
        echo "Check: $check"
        echo "Value: $value"
        echo "Funct: $funct"
        echo "Email: $email"
        echo "Slack: $slack"
      fi
      output=$(eval $check)
      if [ "$output" $funct "$value" ] ; then
        if [ "$do_dryrun" = "yes" ] || [ "$do_verbose" = "yes" ] ; then
          echo "Correct: $title returns $value"
        fi
        if [ "$do_false" = "yes" ] ; then
          handle_alert "$title" "$value" "$email" "$slack" 
        fi
      else
        if [ "$do_dryrun" = "yes" ] || [ "$do_verbose" = "yes" ] ; then
          echo "Warning: $title does not return $value"
        else
          handle_alert "$title" "$value" "$email" "$slack" 
        fi
      fi
    fi
  done
  return
}

# Handle command line arguments

while getopts "VvhsmlfcdUui" opt; do
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
    i)
      # Install check
      install_check
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
    u)
      # Check of updated script
      do_update="no"
      check_update $do_update
      exit
      ;;
    U)
      # Update script
      do_update="yes"
      check_update $do_update
      exit
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
    f_slack=$(cat "$slack_file")
  else
    f_slack="none"
  fi
else
  f_slack="none"
fi

#Handle alert email address

if [ "$do_email" = "yes" ]; then
  if [ -f "$email_file" ] ; then
    f_email=$(cat "$email_file")
  else
    f_email="none"
  fi
else
  f_email="none"
fi

# Handle checks

if [ "$do_list" = "yes" ] || [ "$do_check" = "yes" ]; then
  if [ ! -e "$check_file" ]; then
    echo "Check file: $check_file does not exist" 
    exit
  fi
  do_checks "$f_email" "$f_slack"
  exit
else
  print_help
fi
