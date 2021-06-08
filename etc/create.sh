#! /bin/bash

starttime=`date +%s`
starttime=`expr $starttime - 86400`

filePath=/root/pengwl/db/test11.rrd

rm -f  $filePath

## 创建一个rrd文件
rrdtool create $filePath \
--start $starttime \
--step 60 \
DS:eth0_in:GAUGE:120:U:U \
DS:eth0_out:GAUGE:120:U:U \
RRA:AVERAGE:0.5:1:60 \
RRA:AVERAGE:0.5:20:72

## 写rrd数据
total_input_traffic=0
total_output_traffic=0
endtime=`echo "$starttime+86400"|bc`
echo "starttime: ${starttime}"

start=${starttime}

##先制造一天的数据
echo "较当前时间，往后制造一天的假数据"
step=`expr 86400 / 60`
echo "step:  ${step}"
int=1
while(( $int<$step ))
do
    let "int++"
    starttime=`expr ${starttime} + 60`
    total_input_traffic=$RANDOM
    total_output_traffic=$RANDOM
    ##echo "int:  ${int} ,starttime: ${starttime} ,${total_input_traffic} ,${total_output_traffic}"
    /usr/bin/rrdtool update $filePath  $starttime:$total_input_traffic:$total_output_traffic
done
echo "数据制造完成"
echo "starttime: ${starttime}"
end=${starttime}

##数据落盘
sync

## 测试查询
while :
do
   t=`date`
   echo "当前时间 $t"
   echo "开始查询------------------------------------------------------------------"
   echo "/usr/bin/rrdtool fetch $filePath AVERAGE --start $start --end $end |tail -5"
   /usr/bin/rrdtool fetch $filePath AVERAGE --start $start --end $end |tail -5
   echo "查询结束------------------------------------------------------------------"
   echo "开始使用当前时间戳写入数据----------------------------------------------------"
   total_input_traffic=$RANDOM
   total_output_traffic=$RANDOM
   echo "/usr/bin/rrdtool update $filePath  N:$total_input_traffic:$total_output_traffic"
   /usr/bin/rrdtool update $filePath  N:$total_input_traffic:$total_output_traffic
   echo "写入数据结束------------------------------------------------------------------"
   sleep 10
done

