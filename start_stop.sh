
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
---
  ## For stop/start EC2 Instances in AWS using Tags
  #
  # Usage:
  #
  # For Starting
  # ansible-playbook -i /inventory/path/ec2.py /playbook_path.yml --tags=start
  #
  # For Stopping
  # ansible-playbook -i /inventory/path/ec2.py /playbook_path.yml --tags=stop
  # Note: Ignore the skipped output because it's skiping nodes which doesnot belong to the Env (Environment) that you want to use
  # To suppress skipped use env export DISPLAY_SKIPPED_HOSTS=0
  #
  ####
 
  - hosts: localhost
    gather_facts: false
    vars:
        env: 'UAT'
        aws_id: "AWS_ACCESS_ID"
        aws_key: "AWS_ACCESS_KEY"
        region: "REGION"
        email_id: "EMAIL_ID1,EMAIL_ID2"
        from_id: "no-reply@abc.com"
        cc: "CC_EMAIL_ID"
        nagios: true
        monitoring_server: 'NAGIOS_SERVER_IP'
        smtp_server_ip: '127.0.0.1'
        smtp_server_port: '25'
        servers:
           - '{{ groups.tag_Name_Web }}'
           - '{{ groups.tag_Name_Appp }}'
           - '{{ groups.tag_Name_Mongo }}'
 
    tasks:
         - fail: msg='Please use to args --tags=start or --tags=stop'
           tags:
              - untagged
 
         - name: "Starting Infra"
           set_fact: action='running' msg='Started' tag='start'
           tags:
              - start
 
         - name: "Stoping Infra"
           set_fact: action='stopped' msg='Stopped' tag='stop'
           tags:
              - stop
 
         - name: Disabling alerts
           nagios: action=disable_alerts service=host  host='{% for ip in item %}{{ip}}{% if not loop.last%},{%endif%}{% endfor %}'
           delegate_to: "{{ monitoring_server }}"
           with_items:
                 - "{{ servers }}"
           when: "{{ nagios }}"
           tags:
             - stop
 
         - ec2:
              aws_access_key: "{{ aws_id }}"
              aws_secret_key: "{{ aws_key }}"
              instance_ids:  '{% for i in item %}{{ hostvars[i]["ec2_id"] }}{% if not loop.last%},{%endif%}{% endfor %}'
              state: '{{ action }}'
              region: '{{ region }}'
              wait: false
           with_items:
               - '{{ servers }}'
           register: status
           ignore_errors: true
           tags:
              - start
              - stop
 
         - mail:
               host="{{ smtp_server_ip }}"
               port="{{ smtp_server_port }}"
               subject="{{ env }} Infra has been {{ msg }}"
               body="{{ env }} Infra has been {{ msg }}"
               from="{{ from_id }}"
               to="{{ email_id }}"
               cc="{{ cc }}"
               charset=utf8
           when: "{{ status | changed }}"
           tags:
              - start
              - stop
