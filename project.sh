#!/bin/bash
 
# Purpose :: Auto shutdown trigger based on  memory and Java process
# Date    :: Tue Dec  4 12:36:22 IST 2015
 
memory_threshold=80      # if 80 percent and more than momory is free
process_threshold=0      # if 0  java process running
server_ip=`hostname`     # will be configure by ansible
email_ids=admin@xyz.com
project='{{ project }}'
 
max_tries=12  # try max 12 times with wait time interval
wait_time=5m  # wait for 5 min then check again
wait_count=0
# make sure script should be run twice
lock_file=/tmp/auto_shutdown.lock
 
check_momory(){
 
      free -m | awk 'FNR == 3 {print int($4/($3+$4)*100)}'
 
}
 
check_java_process(){
 
     ps -ef | awk '{$8 ~ /java/&& n++} END{ print n}'
 
}
 
alert(){
   local level=$1
   [[ $# -eq 1 ]] && level=INFO
   local msg=${@//$level/}
 
   if [[ $level == INFO ]]
   then
         echo "$( date ) :: $level ${msg}"
   else
         echo "$( date ) :: $level ${msg}" | tee >( mail -s "Crawl-v1 auto shutdown alert for $server_ip" $email_ids )
   fi
 
}
 
## Check script is already running or not
 
lockfile -r 0 $lock_file || exit 1
trap " [ -f $lock_file ] && /bin/rm -f $lock_file" 0 1 2 3 13 15
 
while true
do
 
   # if momory is less than 5% then check java process
 
   if [[ $(check_momory) -ge $memory_threshold  ]]
   then
        # if process are running less than $process_threshold then send alert
        if [[ $(check_java_process) -le $process_threshold ]]
        then
            # increment counter
            (( n++ ))
 
            # check max retries
            if [[ $n -ge $max_tries ]]
            then
                 alert CRITICAL "No Utilization since page 1 hour | Momory $(check_momory)% free | Java Process $(check_java_process)| ServerIP :: $server_ip | Project :: $project"
                 shutdown -h now
                 exit 0
            else
                 alert "Try #$n | Max retry $max_tries"
                 sleep $wait_time
            fi
        else
            alert "$(check_java_process) Java Proccess running | ServerIP :: $server_ip | Project :: $project"
            alert "Loop terminated with #$n retry, because Memory $(check_momory) and Java Process $(check_java_process)"
            exit 0
        fi
   else
        alert "Memory Utilized :: $( check_momory )% | ServerIP :: $server_ip | Project :: $project"
        break
   fi
done
