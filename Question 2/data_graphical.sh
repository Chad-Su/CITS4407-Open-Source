#!/bin/bash

#  Chang Su 22993116
#  First graph is the frequency of cssubmit URL using every one hour per day
#  Second graph is the frequency of cssubmit URL using every one hour per day
#  Can running successfully in Linux
#  Some html code from exercises results referencr:
#  https://teaching.csse.uwa.edu.au/units/CITS4407/exercises/exercise4-soln.php
#  For graph 1, cat the data file, using grep and cut method to get the data and uml address, store in $target_file.
#  compare data file with $storage line by line, match "cssubmit" keywords and count then print the graph in thml.


#  For graph 2, similarly, compare data file with $storage line by line and match the response error "304" and count, then print graph.



# DEFINE AN ENVIRONMENT VARIABLE TO SET THE COLOUR OF OUR HISTOGRAM
# THE VALUE $COLOUR WILL BE EXPANDED IN THE BODY OF THE hereis DOCUMENT
COLOUR="green"

TITLE="304 error frequency for an hour per day"

function output_top_half_digram1() {
cat << THE_END
<html xmlns="http://www.w3.org/1999/xhtml" id="oldcore">
<head>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

<title>$cssubmit</title>

</head>

<body>
<script type='text/javascript'>
  google.charts.load('current', {packages: ['corechart']});
  google.charts.setOnLoadCallback(drawStacked1);
  function drawStacked1() {
    var options = {
      title: 'cssubmit frequency for an hour per day',
      titleTextStyle: {fontSize: 12, bold: false},
      fontSize: 10, pointSize: 2,
      areaOpacity: 0.6,
      bar: { groupWidth: '100%' },
      legend: { position: 'in', maxLines: 1 },
      colors: ['$COLOUR'],
      chartArea: {backgroundColor: '#eee', left: 40, top: 20, bottom: 30},
      hAxis: { format: 'ddMMM', gridlines: {count: 8} },
    };
    var data1 = new google.visualization.DataTable();
    data1.addColumn('date', 'When');
    data1.addColumn('number', 'cssubmit');
    data1.addRows([
THE_END
}

function data_one(){
  get_date='\[.*\]'
  data=secure-access.log-20200510.txt
  target_file=`cat secure-access.log-20200510.txt | grep -o '\[.*\]' | cut -d ":" -f 1,2 | uniq | cut -c2-`
#get the date and the hour

for line in $target_file
  do
  d=`echo $line | cut -d "/" -f 1`
  M=`echo $line | cut -d "/" -f 2`
  y=`echo $line | cut -d "/" -f 3 | cut -d ":" -f 1`
  h=`echo $line | cut -d "/" -f 3 | cut -d ":" -f 2`
  m=`date -d  "$M $d $y" +%m`
  counter=`grep $line < $data | grep "cssubmit" | wc -l`
  echo "[ new Date(" $y, $m, $d, $h "), $counter ],"
  done
}

function output_bottom_half_digram1() {
cat << THE_END
    ]);
    var line_chart = new google.visualization.LineChart(document.getElementById('div_cssubmit'));
    line_chart.draw(data1, options);
  }
THE_END
}


function output_top_half_digram2() {
cat << THE_END
  google.charts.load('current', {packages: ['bar']});
  google.charts.setOnLoadCallback(drawStacked2);
  function drawStacked2() {
    var options = {
      title: '$TITLE',
      titleTextStyle: {fontSize: 12, bold: false},
      fontSize: 10, pointSize: 2,
      areaOpacity: 0.6,
      isStacked: true,
      bar: { groupWidth: '100%' },
      legend: { position: 'in', maxLines: 1 },
      colors: ['$COLOUR'],
      chartArea: {backgroundColor: '#eee', left: 40, top: 20, bottom: 30},
      hAxis: { format: 'ddMMM', gridlines: {count: 8} },
    };
    var data2 = new google.visualization.DataTable();
    data2.addColumn('date', 'When');
    data2.addColumn('number', '304');
    data2.addRows([
THE_END
}

function data_two(){
  data='secure-access.log-20200510.txt'
  get_date=`cat secure-access.log-20200510.txt | grep -o '\[.*\]' | cut -d":" -f 1,2 | uniq | cut -c2-`

  for line in $get_date
  do
    d=`echo $line | cut -d "/" -f 1`
    M=`echo $line | cut -d "/" -f 2`
    y=`echo $line | cut -d "/" -f 3 | cut -d ":" -f 1`
    h=`echo $line | cut -d "/" -f 3 | cut -d ":" -f 2`
    m=`date -d "$M $d $y" +%m`
    counter=`grep $line < $data | grep '304' | wc -l`
    echo "[ new Date(" $y, $m, $d, $h "), $counter ],"
    done

}


function output_bottom_half_digram2() {
cat << THE_END
    ]);
    var bar_chart = new google.visualization.ColumnChart(document.getElementById('div_304'));
    bar_chart.draw(data2, options);
}
</script>

<div id='div_cssubmit' style="width: 800px; height: 300px;"></div>
<div id='div_304' style="width: 800px; height: 300px;"></div>

</body>
</html>
THE_END
}



output_top_half_digram1 > graph.html
data_one >> graph.html    # pass the shellscript's 1st argument to function
output_bottom_half_digram1 >> graph.html

output_top_half_digram2 >> graph.html
data_two >> graph.html    # pass the shellscript's 1st argument to function
output_bottom_half_digram2 >> graph.html
exit 0
