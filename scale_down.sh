#!/bin/bash
# Script for reducing mp4 video quality, reduces filesize by roughly 1 order of magnitude.
# The small file will be generated one directory up the path with the same filename. The argument is the path to the video files.
# There are two attempts to process the file, after which the file is skipped.
# Log file is created to track file processing and failures, it will be created where the video files are located.
# Verson 1.0.

###### Sample crontab ######
# Downsize video files
#0 7 * * * <path to script>/scale_down.sh <path to destination directory containing video files>
###########################

if [ $# -eq 1 ];
then
    cd "$1"
fi

ls *.mp4 &> /dev/null
if [ $? -eq 2 ];
then
	echo "$(date) No files to process now in path $(pwd)" >> log.txt
    exit 0
fi


for FILE in *.mp4
do
   ffmpeg -n -i $FILE -vf "scale=trunc(iw/4)*2:trunc(ih/4)*2" -c:v libx265 -crf 28 ../$FILE &> /dev/null
   if [ $? -eq 0 ]; 
   then
       echo "$(date) Processing completed successfully for $FILE" >> log.txt
       rm $FILE
   elif [ $? -eq 1 ]; 
   then
       echo "$(date) Processing failed for $FILE, trying again" >> log.txt
       ffmpeg -n -i $FILE -vf "scale=trunc(iw/4)*2:trunc(ih/4)*2" -c:v libx265 -crf 28 ../$FILE &> /dev/null
       if [ $? -eq 0 ]; 
       then
           echo "$(date) Processing completed successfully for $FILE on second attempt" >> log.txt
	   rm $FILE
       elif [ $? -eq 1 ]; 
       then
           echo "$(date) Processing failed on second attempt for $FILE: file skipped" >> log.txt
       else
           echo "$(date) Processing second attempt for $FILE: forbidden else: $?" >> log.txt
       fi
   else
       echo "$(date) Processing first attempt for $FILE: forbidden else: $?" >> log.txt
   fi

done
exit 0
