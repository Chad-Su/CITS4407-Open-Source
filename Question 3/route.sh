#!/bin/bash
#Chang Su 22993116
# constants definition
ONE_KILOMETER=1000                  # 1 kilometer = 1000 m
SPEED=50                            # speed per minute using 20minutes/1km, so 1 minutes walk 50 meters
MIN_TO_FERRY=5                      # from the Fremantle station take 5 minutes walk to the ferry
LAST_FERRY_LEAVE="15:30"            # last ferry departure time
LAST_FERRY_LEAVE_2="15:33"          # if you run, you can reduce 3 minutes
LATEST_TO_ARRIVE_FREMANTLE="15:25"  # the latest time to arrive at fremantle train station


#---------------------functions------------------------------------------#
# transfer, input two stop_id, return the minutes required, ceil value
# 2 features: transfer inside the parent station (use the transfers.txt)
#             transfer from perth underground stn to perth stn
# return either "minutes", or "distance(m) minutes"

test_file(){
    if test ! -e "$1"; then
        echo "File $1 does not exist, please put in the same directory as this shell script"
        exit 1
    fi
    
}

transfer(){
    if test "$#" -ne 2; then
        echo "wrong input numbers in $0"
        exit 1
    fi

    find_count=$(cat transfers.txt | grep ^"$1" | cut -d',' -f2,4 | grep -c ^"$2")
    if test $find_count -ge 1; then
        # there is record on the table, use the table
        seconds=$(cat transfers.txt | grep ^"$1" | cut -d',' -f2,4 | grep ^"$2" | cut -d',' -f2 | head -1 | tr -d '\r')
        ((min=(seconds+60-1)/60))
        echo "$min"
    else
        # no record, use the stop id to find the longitude and latitude
        lat_1=$(cat stops.txt | cut -d',' -f3,7 | grep ^"$1" | cut -d',' -f2)
        long_1=$(cat stops.txt | cut -d',' -f3,8 | grep ^"$1"| cut -d',' -f2)
    
        lat_2=$(cat stops.txt | cut -d',' -f3,7 | grep ^"$2"| cut -d',' -f2)
        long_2=$(cat stops.txt | cut -d',' -f3,8 | grep ^"$2"| cut -d',' -f2)

        # distance in meters, time in minutes
        dist=$(./haversine "$lat_1" "$long_1" "$lat_2" "$long_2")
        ((min = (dist + SPEED - 1) / SPEED))

        echo "$dist,$min"
    fi
}


#function to get the available service id on that day
# input $1: service id
#  variable: this_date is in the main program
get_avail_service_id(){
    
    day_col=$(date -d "$this_date" +%u)
    # echo "$day_col"
    # change to column number, add 1, to check the calender.txt
    ((day_col = day_col + 1))

    this_date_no_dash=$(echo "$this_date" | tr -d '-')

    echo "$1" | while read line;
    do
        calendar_value=$(cat calendar.txt | egrep ^"$line" | cut -d',' -f"$day_col")
        calendar_date_value_count=$(cat calendar_dates.txt | egrep ^"$line" | egrep -c "$this_date_no_dash" )
        calendar_date_value=$(cat calendar_dates.txt | egrep ^"$line" | egrep "$this_date_no_dash" | cut -d',' -f3)

        if test $calendar_value -eq 1; then
            if test $calendar_date_value_count -eq 0; then
                echo "$line"
            elif test $calendar_date_value -eq 1; then
                echo "$line"
            fi

        # no normal service on that day
        elif test $calendar_date_value_count -eq 1; then
            if test $calendar_date_value -eq 1; then
                echo "$line"
            fi
        fi
    done
}


# if you arriva or close to any stn near the fremantle route,
# use this function to finish the remaining trip
# usage: fremantle_route "start stop id (just the id)" "time of arrival at the stn"
fremantle_route(){

    this_stop_id=$(echo "$1")
    # echo "$this_stop_id"

    # now need to go back to find the service id and check if it has train service today
    this_stop_id_get_trip_id=$(echo "$fremantle_trip_info" | egrep "$this_stop_id"$ | cut -d',' -f1 | sort | uniq)
    # echo "$this_stop_id_get_trip_id"


    this_stop_service_id=$(echo "$fremantle_trip_id_service_id" | egrep "$this_stop_id_get_trip_id" | cut -d',' -f1 | sort | uniq)
    # echo "$this_stop_service_id"

    # use the function get_avail_service_id
    avail_service_id=$(get_avail_service_id "$this_stop_service_id")

    # now go back to the trips.txt, use the avail_service_id and fremantle_trip_id_service_id, filter all avail_trip_id
    avail_trip_id=$(echo "$fremantle_trip_id_service_id" | egrep ^"$avail_service_id" | cut -d',' -f2)
    # echo "$avail_trip_id"

    # now go back to the stop_times.txt, use the avail_trip_id and this_stop_id, find the earliest departure time after my arrival at the station
    # info include (trip_id, arrival, departure)
    avail_trip_info=$(echo "$fremantle_trip_info" | egrep "$avail_trip_id" | egrep "$this_stop_id" | cut -d',' -f1,2,3)
    # echo "$avail_trip_info"
    
    # cut the arrival time, and sort
    avail_trip_info_time_only=$(echo "$avail_trip_info" | cut -d',' -f2 | sort)
    

    # the trip info is sorted already, with increasing trip id number, the arrival time and depart time increases
    # so read line by line, once find a time after my arrival, then use this trip id
    arrival1_in_sec=$(date -d "$this_date $2" +%s)
    # echo "$arrival1_in_sec"

    final_trip_time=$(
        echo "$avail_trip_info_time_only" | while read line;
        do
            trip_arr=$(echo "$line")
            trip_arr_in_sec=$(date -d "$this_date $trip_arr" +%s)

            if test $arrival1_in_sec -le $trip_arr_in_sec; then
                echo "$line"
                break
            fi
        done
    )

    final_trip_info=$(echo "$avail_trip_info" | egrep "$final_trip_time")
    # so this is the final trip infor, include (trip id, arrival, departure)
    # echo "$final_trip_info"

    # use this trip id to find the last arrival time: the last line
    final_trip_start_time=$(echo "$final_trip_info" | cut -d',' -f3)
    final_trip_id=$(echo "$final_trip_info" | cut -d',' -f1)

    # this is the time arrive at the fremantle stn
    final_arr_stn_time=$(echo "$fremantle_trip_info" | grep ^"$final_trip_id" | tail -1 | cut -d',' -f2)
    # echo "$final_arr_stn_time"

    # time to arrive at the ferry, add 5 minutes
    final_arr_ferry_time=$(date -d "$final_arr_stn_time $MIN_TO_FERRY minutes" +%R)
    final_arr_ferry_time_in_sec=$(date -d "$this_date $final_arr_ferry_time" +%s)
    last_ferry_leave_in_second=$(date -d "$this_date $LAST_FERRY_LEAVE" +%s)

   # reveal results
    if test $final_arr_ferry_time_in_sec -le $last_ferry_leave_in_second; then
        # yes, can catch the ferry (don't consider run time here, make it simple)
        # detail the trip plan, use final_arr_ferry_time, final_trip_start_time, arrival1, this_stop

        echo "Catch the train leaves at $final_trip_start_time towards Fremantle Stn" >> result.html
        echo "Arrive Fremantle Stn at: $final_arr_stn_time" >> result.html
        echo "Walk $MIN_TO_FERRY minutes to Rottnest Island B-shed ferry terminal" >> result.html
        echo "Arrive ferry terminal at: $final_arr_ferry_time" >> result.html
        echo "You have plenty of time to catch the ferry, the last ferry leaves at $LAST_FERRY_LEAVE" >> result.html
        echo "Trip success !!"  >> result.html

    else

        echo "Catch the train leaves at $final_trip_start_time towards Fremantle Stn" >> result.html
        echo "Arrive Fremantle stn at: $final_arr_stn_time" >> result.html
        echo "Walk $MIN_TO_FERRY minutes to Rottnest Island B-shed ferry terminal" >> result.html
        echo "Arrive ferry terminal at: $final_arr_ferry_time" >> result.html
        echo "The last ferry leaves at $LAST_FERRY_LEAVE, you miss the last ferry !!"  >> result.html
        echo "Trip Fail Fail !!" >> result.html
    fi

    echo "</body>" >> result.html
    echo "</html>" >> result.html
    echo "The output is in result.html file"

}


#---------------------input check------------------------------------------#
usage="Usage: $0 <latitude:float> <longitude:float>"

# 1. check the number of inputs
if (($# != 2));
then
    echo "$usage"
    exit 1
fi

# 2. check if longitude and latitude are both floats
latitude=`echo "$1" | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
longitude=`echo "$2" | egrep '^[-+]?[0-9]*\.?[0-9]+$'`

if test "$latitude" != "$1" -o "$longitude" != "$2";
then
    echo "Coordinates are floating point numbers"
    echo "$usage"
    exit 1
fi

# 3. check if both floats are in the valid range
# -90.0 <= latitude <= 90.0
# -180.0 <= longitude <= 180.0
# floating point use bc!!!!!!
check_range="$latitude >= -90.0 && $latitude <= 90.0 && $longitude >= -180.0 && $longitude <= 180.0"
check_range_result=`echo "$check_range" | bc`
if ((check_range_result == 1))
then
    # get the date and time into variables
    this_date=$(date +%F)
    this_time=$(date +%R)

    # echo for the current information
    echo "<!DOCTYPE html>" > "result.html"
    echo "<html>" >> "result.html"
    echo "<body>" >> "result.html"
    echo "Your current position is coordinate ($1, $2)" >> "result.html"
    echo "You are leaving at: {$this_date} {$this_time}" >> "result.html"

else
    echo "Coordinates are not in valid range"
    echo "$usage"
    exit 1
fi


# check all files exist
test_file "calendar.txt"
test_file "calendar_dates.txt"
test_file "routes.txt"
test_file "stop_times.txt"
test_file "stops.txt"
test_file "transfers.txt"
test_file "trips.txt"
test_file "haversine.c"


#---------------------------------------------------------------#
# now we have the location and time
# now find the nearest train station with distance <= 1km
# only find the train station
# use the stops.txt
# use column 10 to find supported_modes contain rail

# compile the c file
cc -std=c99 -Wall -Werror -o haversine haversine.c -lm > /dev/null

# find the station detial
# use awk to filter the last column contains Rail
ok_stations=$(
    awk -F"," '{if($10 ~ /Rail/){print}}' stops.txt | while read line;
    do
        if test -n;
        then
            # extract the stops' longitude and latitude
            stop_lat=`echo "$line" | cut -d',' -f7`
            stop_lon=`echo "$line" | cut -d',' -f8`
            
            # calculate the distance using the supplied files
            dist=`./haversine "$stop_lat" "$stop_lon" "$latitude" "$longitude"`

            if test $dist -le $ONE_KILOMETER;
            then
                # extract the following information: paren_station, stop_id, stop_name and the distance
                info=`echo "$line" | cut -d',' -f2,3,5`
                echo "$info,$dist"
            fi
        fi
    done
)

# first check if there are any results: use -z to check instead of "wc -l"
# note the double quote around ok_stations, otherwise get error: too many arguments
if test -z "$ok_stations";
then
    echo "No stations are within 1km of your location. Trip fail" >> "result.html"
    echo "</body>" >> result.html
    echo "</html>" >> result.html
    echo "The output is in result.html file"
    exit 0
fi

# sort based on the distance first
ok_stations=`echo "$ok_stations" | sort --field-separator=',' -k4 -n`


#-------------------------------------------------------------------------#
# the variable ok_stations contain: (parent_station, stop_id, stop_name, distance)
# now determine the strategy:
# 1. catch ferry directly
# 2. catch Fremantle Route to ferry station
# 3. Catch train and transfer at id=56/64 then do step 2


#-------------------------------------------------------------------------#
# method 1:
# grep if can find parent_station=87, if yes, arrange the boat
# if not, find 56 64, if yes, choose the nearest platform
# if not, sort and find the closest station
count=`echo "$ok_stations" | egrep -c '^87,.*$'`
if test $count -ge 1;
then
    dist1=$(echo "$ok_stations" | head -1 | cut -d',' -f4)        # distance from you to the train station

    # simply walking, walking time is around 20min/1000m, ie 1min/50m.
    # add 50 then minus 1, to get the ceiling integer of the division
    # from teacher's comment, the walk to ferry is around 5 minutes
    ((total_time = (dist1 + SPEED - 1) / SPEED + MIN_TO_FERRY))
    arrival_time=$(date -d "$this_time $total_time minutes" +%R)

    echo "Trip method: walking"
    echo "Assumption: walking speed 20min/km, and 5 minutes walk from the station to ferry"
    echo "Walk $dist1 meters to the Fremantle Train Station"
    echo "Walk 5 minutes to the Rottnest Island B-shed ferry terminal"
    echo "Arrival at: $arrival_time"
    echo

    # now check if you can catch the ferry
    last_ferry_in_second=$(date -d "$this_date $LAST_FERRY_LEAVE" +%s)
    last_ferry_if_run_in_second=$(date -d "$this_date $LAST_FERRY_LEAVE_2" +%s)
    arrival_time_in_second=$(date -d "$this_date $arrival_time" +%s)

    if test $arrival_time_in_second -gt $last_ferry_if_run_in_second; then
        echo "Unfortunately you miss the last ferry at 15:30. Trip fail"

    elif test $arrival_time_in_second -gt $last_ferry_in_second; then
        echo "Your arrival time is 3 minutes later then the last ferry's departure" >> result.html
        echo "But if you run quickly, you may still have a chance!!" >> result.html
        echo "Good luck" >> result.html
    else
        echo "Yes you can definitely catch the ferry!!" >> result.html
        echo "The last ferry leaves at 15:30. You have plenty of time!!" >> result.html
    fi

    echo "</body>" >> result.html
    echo "</html>" >> result.html
    echo "The output is in result.html file"

    exit 0
fi


# if later than LATEST_TO_ARRIVE_FREMANTLE, then definitely do not need to consider
# since you have more than 5 minutes to reach the portal
last_check_out_from_station=$(date -d "$this_date $LATEST_TO_ARRIVE_FREMANTLE" +%s)
current_time=$(date -d "$this_date $this_time" +%s)

if test $current_time -ge $last_check_out_from_station; then
    echo "Since you are not near the Fremantle Station, and it needs 5 minutes to get you from the station to terminal" >> result.html
    echo "You definitely cannot catch the latest ferry at 15:30." >> result.html
    echo "Trip Fail Fail!!" >> result.html
    
    echo "</body>" >> result.html
    echo "</html>" >> result.html
    echo "The output is in result.html file"
    
    exit 0
fi


# now check if he is close to any stations on the fremantle route,
# if yes, then the person travel to the end of the route, and walk to the ferry
# the route starts from perth stn, and go through total 16 stations

# first find the route id, only one train route
routes=$(cat routes.txt | awk -F"," '{if ($6 == 2 && $4 ~/Fremantle/) {print}}')
fremantle_route_id=$(echo "$routes" | cut -d',' -f1)
# echo "$route_id"

# use the trips.txt, grep the route_id, and head_sign mentions "fremantle" since it is the destination of the route
# direction_id can be omitted. I think the head_sign is enough
fremantle_trip_id_service_id=$(cat trips.txt | grep "$fremantle_route_id" | awk -F"," '{if ($5 ~ /Fremantle/) {print}}' | cut -d',' -f2,3)
fremantle_service_id=$(echo "$fremantle_trip_id_service_id" | cut -d',' -f1 | sort | uniq)
fremantle_trip_id=$(echo "$fremantle_trip_id_service_id" | cut -d',' -f2 | sort | uniq)
# echo "$fremantle_trip_id" | head
# echo "$fremantle_service_id" | head

# use the stop_times.txt, use the trip_id, find all the unique stop_id.
# total 16 stations, same as the web link https://www.transperth.wa.gov.au/timetables/details?Train=Fremantle%20Line
# extract info (trip_id, arrival_time, departure_time, stop_id, stop_sequence)
fremantle_trip_info=$(cat stop_times.txt | egrep ^"$fremantle_trip_id" | cut -d',' -f1,2,3,4,5)
fremantle_stop_id=$(echo "$fremantle_trip_info" | cut -d',' -f4 | sort | uniq)
# echo "$fremantle_trip_info"

# finally, find all the stops on the fremantle train route, 16 stops with specified platform number
# variable has similar structure as the ok_stations, but without the distance
fremantle_stops=$(cat stops.txt | cut -d',' -f2,3,5 | egrep "$fremantle_stop_id")
# echo "$fremantle_stops"   # output ex: 42,99262,"Loch Street Stn Platform 2"

# count if your 1km radius intersect any fremantle route stops
count_meet_fremantle_line_at_stop=$(echo "$ok_stations" | egrep -c "$fremantle_stops")

if test $count_meet_fremantle_line_at_stop -ge 1;
then
    # close to one station on the fremantle train route, (parent_station, stop_id, stop_name, distance)
    # the distance is included !!!
    this_stop=$(echo "$ok_stations" | egrep "$fremantle_stops" | head -1)
    # echo "$this_stop"

    # calculate the time to the station
    dist1=$(echo "$this_stop" | cut -d',' -f4)
    ((time1 = (dist1 + SPEED - 1) / SPEED ))        # return the ceil value

    # now you are at the train station, check the next train
    arrival_at_station_time=`date -d "$this_time $time1 minutes" +%R`

    # get the station name
    stn=$(echo "$this_stop" | cut -d',' -f3 | tr -d '"')

    echo "Walk $dist1 meters to the $stn"  >> result.html
    echo "Arrive at: $arrival_at_station_time" >> result.html

    # call the function, given the (parent_station, stop_id, stop_name, distance) and the arrival time
    this_stop_id=$(echo "$this_stop" | cut -d',' -f2)
    fremantle_route "$this_stop_id" "$arrival_at_station_time"
 
    exit 0
fi


# find the starting position of the fermantle route: the perth stn stop_id
perth_stn_stop_id=$(echo "$fremantle_stops" | cut -d',' -f2 | sort | head -1 | tr -d '\r')
perth_stn_stop_name=$(cat stops.txt | cut -d',' -f3,5 | egrep "$perth_stn_stop_id" | cut -d',' -f2 | tr -d '"')
# echo "$perth_stn_stop_id"

# perth stn parent_id = 56, perth underground stn partent_id = 64, use grep . to remove empty entry
# check if 64 is near my location
count_if_near_underground=$(echo "$ok_stations" | grep -c '^64,.*$')
if test $count_if_near_underground -ge 1; then
    
    # you are near the perth unerground station
    # go to the closest underground station stop_id, then use function "transfer" to reach perth stn, then fremantle_route

    stop_info=$(echo "$ok_stations" | grep '^64,.*$' | head -1)
    stop_id=$(echo "$stop_info" | cut -d',' -f2)
    stop_name=$(echo "$stop_info" | cut -d',' -f2 | tr -d '"')
    stop_dist=$(echo "$stop_info" | cut -d',' -f4)
    
    ((time_gap = (stop_dist + SPEED - 1) / SPEED))
    time1=$(date -d "$this_time $time_gap minutes" +%R)

    echo "Walk $stop_dist meters to $stop_name" >> result.html
    echo "Arrive at: $time1" >> result.html

    transfer_dist_time=$(transfer $stop_id $perth_stn_stop_id)       # not on the record, so return "dist,min"
    transfer_dist=$(echo $transfer_dist_time | cut -d',' -f1)
    transfer_time=$(echo $transfer_dist_time | cut -d',' -f2)

    time2=$(date -d "$time1 $transfer_time minutes" +%R)

    echo "Walk $transfer_dist meters to xxxxx" >> result.html
    echo "Arrive at: $time2" >> result.html

    # call the function, finish the rest
    fremantle_route "$perth_stn_stop_id" "$time2"

    exit 0

fi


# now the last part:
# the person is near a station, but he needs to take train to either id=56/64,
# then probably transfer (if arrive at perth underground)
# then the fremantle line

# find stop_id and platform name set for 56 and 64
perth_stn_stop_id_name_set=$(cat stops.txt | cut -d',' -f2,3,5 | grep '^56,.*$' | cut -d',' -f2,3)
perth_und_stop_id_name_set=$(cat stops.txt | cut -d',' -f2,3,5 | grep '^64,.*$' | cut -d',' -f2,3)
#echo "$perth_stn_stop_id_name_set"
#echo "$perth_und_stop_id_name_set"

perth_id=$(echo $perth_stn_stop_id_name_set | cut -d',' -f1)
perth_und_id=$(echo $perth_und_stop_id_name_set | cut -d',' -f1)


# find the nearest stn parent id
stn_stop_id=$(echo "$ok_stations" | egrep '^[0-9]' | cut -d',' -f2 | sort | uniq)
stn_stop_id_name_set=$(cat stops.txt | cut -d',' -f3,5 | grep ^"$stn_stop_id")

# find all the trip id through this station
trip_id_through_stn=$(cat stop_times.txt | cut -d',' -f1,4 | egrep "$stn_stop_id"$ | cut -d',' -f1 | sort | uniq)
# echo "$trip_id_through_stn"

# go to trips.txt, use these trip_id, to find the unique route_id and service_id with headsign "Perth Stn" or "Perth Underground Stn"
# give priority to Perth Stn, then easier
# store the oute_id and service_id, trip id and trip headsign
trip_info=$(cat trips.txt | cut -d',' -f1,2,3,5 | egrep "$trip_id_through_stn" | egrep "(Perth Stn|Perth Underground Stn|Elizabeth Quay Train Stn)$")
route_id=$(echo "$trip_info" | cut -d',' -f1 | sort | uniq)
service_id=$(echo "$trip_info" | cut -d',' -f2 | sort | uniq)

# so now, find all routes and services towards either perth stn or perth underground stn

# check which service is available today
avail_service_id=$(get_avail_service_id "$service_id")
#echo $avail_service_id

# use the available service id to find the available trip id
avail_trip_id=$(echo "$trip_info" | cut -d',' -f2,3 | grep ^"$avail_service_id" | cut -d',' -f2)
# echo "$avail_trip_id"

# go back to the stop_times.txt, use the avail_trip_id
# return all the trip info (trip_id, arrival, departure)
avail_stop_time_info=$(cat stop_times.txt | cut -d',' -f1,2,3,4 | grep "$stn_stop_id"$ | egrep ^"$avail_trip_id" | sort)

# (trip id, arrival, departure, stop_id)
# for multiple stop id, use the first one, but usually just 1 stop id
initial_stop_id=$(echo "$avail_stop_time_info" | cut -d',' -f4 | sort | uniq | head -1 | tr -d '\r')
initial_stop_name=$(echo "$stn_stop_id_name_set" | grep "$initial_stop_id" | cut -d',' -f2 | tr -d '"')
# echo "$initial_stop_name"

# use ok_stations to find the distance
dist_to_initial_stop=$(echo "$ok_stations" | egrep "$initial_stop_id" | cut -d',' -f4)
# echo "$dist_to_initial_stop"

((time_to_initial_stop = (dist_to_initial_stop + SPEED - 1) / SPEED))
time1=$(date -d "$this_time $time_to_initial_stop minutes" +%R)
time1_in_second=$(date -d "$this_date $time1" +%s)

echo "Walk $dist_to_initial_stop meters to $initial_stop_name" >> result.html
echo "Arrive at: $time1" >> result.html

# now arrive at the station, catch the first train to either perth or perth underground
avail_stop_time_only=$(echo "$avail_stop_time_info" | cut -d',' -f2 | sort)

final_trip_stop_time=$(
    echo "$avail_stop_time_only" | while read line;
    do
        trip_arr=$(echo "$line")
        trip_arr_in_sec=$(date -d "$this_date $trip_arr" +%s)

        if test $time1_in_second -le $trip_arr_in_sec; then
            echo "$line"
            break
        fi
    done
)

# so this is the final trip info: example: 2342575,15:06:00,15:06:00,99041
final_trip_info=$(echo "$avail_stop_time_info" | grep "$final_trip_stop_time")
# echo "$final_trip_info"

# use the trip id to find the last destination
final_trip_id=$(echo "$final_trip_info" | cut -d',' -f1)

# 2342575,15:13:00,15:13:00,99004
dest_info=$(cat stop_times.txt | egrep ^"$final_trip_id" | tail -1 | cut -d',' -f1,2,3,4)

dest_stop_id=$(echo "$dest_info" | cut -d',' -f4)
dest_stop_arr_time=$(echo "$dest_info" | cut -d',' -f2)

dest_stop_name=$(cat stops.txt | cut -d',' -f3,5 | egrep ^"$dest_stop_id" | cut -d',' -f2 | tr -d '"')

# echo "$dest_stop_name"

echo "Catch train towards $dest_stop_name" >> result.html
echo "Arrive at: $dest_stop_arr_time" >> result.html

# consider transfer
result=$(transfer "$dest_stop_id" "$perth_stn_stop_id")       # need to check if is minutes, or dist,min
count_comma=$(echo "$result" | egrep -c ',')

if test $count_comma -eq 0; then
    echo "Walk $result minutes towards $perth_stn_stop_name"
    time3=$(date -d "$dest_stop_arr_time $result minutes" +%R)
    echo "Arrive at: $time3"
else
    dist=$(echo "$result" | cut -d',' -f1)
    time=$(echo "$result" | cut -d',' -f2)
    time3=$(date -d "$dest_stop_arr_time $time minutes" +%R)
    echo "Walk $dist meters towards $perth_stn_stop_name" >> result.html
    echo "Arrive at: $time3" >> result.html
fi

fremantle_route "$perth_stn_stop_id" "$time3"
exit 0
