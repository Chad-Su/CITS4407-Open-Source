#!/bin/bash
# Chang Su 22993116
# using two for loop
# the first for loop is used to whether the contents and version number of files are correct
# the second for loop is used to modify the version number of each file
folder=$(ls)
pre_version=0
count=0
for fn in $folder
do
    tmp=${fn##*.}
    if [ "$tmp" == "c" -o "$tmp" == "h" -o "$fn" == "Makefile" ]
    then
        prev_filename=$(cat $fn | grep 'version' | grep $1 | wc -l)
        if [ $prev_filename -eq 0 ]
        then
            echo "The project name or version different"
            exit
        fi
        cur_version=$(cat $fn | grep 'version' | sed 's/.*version \([0-9]\).*/\1/g')
        if [ $count -eq 0 -o $cur_version -eq $pre_version  ]
        then
            let count++
            pre_version=$cur_version
        else
            echo "The project name or version different"
            exit
        fi
    fi
done
for fn in $folder
do
    tmp=${fn##*.}
    if [ "$tmp" == "c" -o "$tmp" == "h" -o "$fn" == "Makefile" ]
    then
        prev_version=$(cat $fn | grep 'version' | sed 's/.*version \([0-9]\).*/\1/g')
        curr_date=$(date "+%a %b %d %H:%M:%S %Z %Y")
        new_version=$(($pre_version+1))
        sed -i "s/version.*/version ${new_version}, released ${curr_date}/g" $fn
    fi
done
