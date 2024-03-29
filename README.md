![alt tag](https://raw.githubusercontent.com/lateralblast/llama/master/llama.jpg)

LLAMA
=====

Lightweight Linux Automated Monitoring Agent

Introduction
------------

This is a simple monitoring tool that will sent a message to Slack via a Slack Webhook or to an email address if a check doesn't return a value

The URL for the Slack Webhook is kept in ~/.llama/slack_hook_file or can be included in the JSON file to provide per alert slack hooks.

The email list for the email alerts is kept in ~/.llama/email_list_file or can be provided in the JSON file to provide per alert email addresses.

The checks are in JSON file (~/.llama/checks.json).

An example JSON checks file:

```
[
  {
    "title": "Check coreaudiod is running",
    "check": "ps -ef |grep -v grep |grep coreaudiod |awk '{print $8}'",
    "value": "/usr/sbin/coreaudiod"
  },
  {
    "title": "Check mDNSResponderHelper is running",
    "check": "ps -ef |grep -v grep |grep mDNSResponderHelper |awk '{print $8}'",
    "value": "/usr/sbin/mDNSResponderHelper"
  }
]
```

By default the function performed will be a equals check, however you can do a greater than or less than check.

An example of a less than check:

```
[
  {
    "title": "Check number of Firefox instances running is less than 10",
    "check": "ps -ef |grep Firefox |grep -v grep |wc -l |sed 's/ //g'",
    "funct": "<",
    "value": "10"
  }
]
```

An example with a slack hook and eail alert address:

```
[
  {
    "title": "Check number of Firefox instances running is less than 10",
    "check": "ps -ef |grep Firefox |grep -v grep |wc -l |sed 's/ //g'",
    "funct": "<",
    "value": "10",
    "email": "alerts@blah.com",
    "slack": "https://hooks.slack.com/services/BLAH"
  }
]
```

Requirements
------------

The following tools are required:

- shell
- curl
- jq
- Slack Webhook (for Slack alerts)
- mailutils (for mail alerts)

You can create Slack Webhooks here:

https://api.slack.com/messaging/webhooks

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode


Setup
-----

Probably the best way to run this is periodically via cron, e.g.:

```
$ crontab -l |grep llama
55 * * * * /home/user/llama/llama.sh -c -s
```

Examples
--------

Getting help:

```
./llama.sh -h
llama (Lightweight Linux Automated Monitoring Agent  0.0.5
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

    V)
       Display Version
    f)
       Create false alerts
    h)
       Display Usage Information
    i)
       Install check
    s)
       Use Slack to post alerts
    m)
       Email alerts
    l)
       List checks
    d)
       Do Dry Run
    c)
       Run checks
    u)
       Check of updated script
    U)
       Update script
    v)
       Run in verbose mode
```

Run checks and send alerts to Slack:

```
./llama.sh -c -s
```

List checks:

```
./llama.sh -l
Title: Check coreaudiod is running
Check: ps -ef |grep -v grep |grep coreaudiod |awk '{print $8}'
Value: /usr/sbin/coreaudiod
Title: Check mDNSResponderHelper is running
Check: ps -ef |grep -v grep |grep mDNSResponderHelper |awk '{print $8}'
Value: /usr/sbin/mDNSResponderHelper
```

Perform a dry run:

```
./llama.sh -c -d
Correct: Check coreaudiod is running returns /usr/sbin/coreaudiod
Correct: Check mDNSResponderHelper is running returns /usr/sbin/mDNSResponderHelper
```

Verbose check example:

```
./llama.sh -c -s -v
Title: Check web server is running on host
Check: curl -I -s -L -k https://webserver.com:8080 |grep 'HTTP' |awk '{print $2}'
Value: 200
Funct: =
Correct: Check web server is running on host returns 200
```
