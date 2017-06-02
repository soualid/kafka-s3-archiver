#!/bin/bash
echo "Command line:" 
echo $0 $*
set -euo pipefail
args=$(getopt -l "server:" -l "workDir:" -l "remoteBucket:" -l "kafkaGroup:" -l "kafkaTopic:" -o "s:w:r:g:t:"  -- "$@")
eval set -- "$args"

while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                -s|--server)
                        server="$2"
                        shift
                        ;;
                -w|--workDir)
                        workDir="$2"
                        shift
                        ;;    
                -g|--kafkaGroup)
                        kafkaGroup="$2"
                        shift
                        ;;    
                -t|--kafkaTopic)
                        kafkaTopic="$2"
                        shift
                        ;;    
                -r|--remoteBucket)
                        remoteBucket="$2"
                        shift
                        ;;    
        esac

        shift
done

if [ -z ${server} ] || [ -z ${workDir} ] || [ -z ${remoteBucket} ] || [ -z ${kafkaGroup} ] || [ -z ${kafkaTopic} ]; then
  echo Please specify --workDir, --remoteBucket, --kafkaTopic, --kafkaGroup and --server
  exit 1
fi

echo "workDir: $workDir"
echo "server: $server"
echo "remoteBucket: $remoteBucket"
echo "kafkaTopic: $kafkaTopic"
echo "kafkaGroup: $kafkaGroup"

if [ -f ${workDir}.lock ]; then
    echo "Lock file found, we do not allow multiple process running at the same time, manually delete the lock file if needed."
    exit 1
fi

touch ${workDir}.lock

echo "starting..."

LANG=en_US
kafkacat -q -C -b $server -f '%o|%s' -e -G ${kafkaGroup} ${kafkaTopic} | while read line; do
  touch ${workDir}.lock
  offset=$(cut -d '|' -f 1 <<< $line)
  data=$(cut -d '|' -f 2 <<< $line)
  datetime=$(echo $data | awk '{print $7}' | cut -d '.' -f 1)
  suffix=$(date -D '[%d/%b/%Y:%H:%M:%S' -d $datetime +%Y-%m-%d 2> /dev/null)                
  result=$?
  if [ "$result" == "0" ]; then
    echo $data >> ${workDir}data-$suffix.log
    echo -ne '#'
  else 
    #echo [warn] not an access log, ignoring ...
    #echo $data 
    echo -ne '!'
  fi
done
                                                                                                             
echo "will archive old files (starting from yesterday)"
# find all log file to zip and push old ones on S3
cd ${workDir} && ls -1 *.log | while read line; do
  echo $line        
  date=$(echo $line | egrep -o "[0-9]+-[0-9]+-[0-9]+")
  currentDate=$(date +%Y-%m-%d)            
  echo $date $currentDate
  if [ "$currentDate" != "$date" ]; then
    echo Archiving and backuping: $line
    tar cfz $line.tar.gz $line
    rm $line                       
    aws s3 cp $line.tar.gz $remoteBucket
    rm $line.tar.gz       
  fi                         
done                                
cd -   
rm ${workDir}.lock