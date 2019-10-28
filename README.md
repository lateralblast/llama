![alt tag](https://raw.githubusercontent.com/lateralblast/llama/master/llama.jpg)

LLAMA
=====

Lightweight Linux Automated Monitoring Agent

Introduction
------------

This is a simple monitoring tool that will sent a message to Slack via a Slack Webhook or to an email address if a check doesn't return a value

The URL for the Slack Webhook is kept in ~/.llama/slack_hook_file

The email list for the email alerts is kept in ~/.llama/email_list_file

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


Examples
--------

Getting help:

```
./llama.sh -h
llama (Lightweight Linux Automated Monitoring Agent  0.0.1
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

    V)
       Display Version
    f)
       Create false alerts
    h)
       Display Usage Information
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
