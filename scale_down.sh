#!/bin/bash
# Script for reducing mp4 video quality, reduces filesize by roughly 1 order of magnitude.
# The small file will be generated one directory up the path with the same filename. The argument is the path to the video files.
# There are two attempts to process the file, after which the file is skipped.
# Log file is created to track file processing and failures (in the location where this script is run)
# Verson 2.0.

###### Sample crontab ######
# Downsize video files
#0 7 * * * <path to script>/scale_down.sh <path to destination directory containing video files>
###########################


log_file="scale_down_log.txt"

echo "---------------------------------------" >> $log_file
echo "$(date) Script starting" >> $log_file


if [ $# -ne 2 ];
then
    echo "Inaccurate number of arguments, 2 expected."
    exit 1
fi


# Check for "ffmpeg"

ffmpeg --help > /dev/null 2>&1

if [ $? -eq 127 ];
   then
       echo "ffmpeg is missing, aborting." >> $log_file
       echo "The rsync program is required to use this script."
       exit 1
fi


echo "Input file path provided: $1" >> $log_file
echo "Output file path provided: $2" >> $log_file


ls $1*.mp4 &> /dev/null 2>&1
if [ $? -eq 2 ];
then
	echo "$(date) No files to process now in path $1" >> $log_file
    exit 0
fi


for INPUT_FILE in $1*.mp4
do
        # Strip input dir from file
	BASE_FILE=$(basename "$INPUT_FILE")
	# Create output file with output path
	OUTPUT_FILE=$2$BASE_FILE
	ffmpeg -n -i $INPUT_FILE -vf "scale=trunc(iw/4)*2:trunc(ih/4)*2" -c:v libx265 -crf 28 $OUTPUT_FILE &> /dev/null
   if [ $? -eq 0 ]; 
   then
       rm $INPUT_FILE
       echo "$(date) Processing completed successfully for $BASE_FILE". Deleted from source and output file in target directory >> $log_file
   elif [ $? -eq 1 ]; 
   then
       echo "$(date) Processing failed for $INPUT_FILE, trying again" >> $log_file
       ffmpeg -n -i $INPUT_FILE -vf "scale=trunc(iw/4)*2:trunc(ih/4)*2" -c:v libx265 -crf 28 $OUTPUT_FILE &> /dev/null
       if [ $? -eq 0 ]; 
       then
           echo "$(date) Processing completed successfully for $BASE_FILE on second attempt. Deleted from source and output file in target directory" >> $log_file
	   rm $INPUT_FILE
       elif [ $? -eq 1 ]; 
       then
           echo "$(date) Processing failed on second attempt for $INPUT_FILE: file skipped" >> $log_file
       else
           echo "$(date) Processing second attempt for $INPUT_FILE: forbidden else: $?" >> $log_file
       fi
   else
       echo "$(date) Processing first attempt for $INPUT_FILE: forbidden else: $?" >> $log_file
   fi

done
exit 0
