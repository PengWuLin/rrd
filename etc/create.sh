#! /bin/bash

starttime=`date +%s`
starttime=`expr $starttime - 86400`

filePath=/root/pengwl/db/test11.rrd

rm -f  $filePath

## ����һ��rrd�ļ�
rrdtool create $filePath \
--start $starttime \
--step 60 \
DS:eth0_in:GAUGE:120:U:U \
DS:eth0_out:GAUGE:120:U:U \
RRA:AVERAGE:0.5:1:60 \
RRA:AVERAGE:0.5:20:72

## дrrd����
total_input_traffic=0
total_output_traffic=0
endtime=`echo "$starttime+86400"|bc`
echo "starttime: ${starttime}"

start=${starttime}

##������һ�������
echo "�ϵ�ǰʱ�䣬��������һ��ļ�����"
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
echo "�����������"
echo "starttime: ${starttime}"
end=${starttime}

##��������
sync

## ���Բ�ѯ
while :
do
   t=`date`
   echo "��ǰʱ�� $t"
   echo "��ʼ��ѯ------------------------------------------------------------------"
   echo "/usr/bin/rrdtool fetch $filePath AVERAGE --start $start --end $end |tail -5"
   /usr/bin/rrdtool fetch $filePath AVERAGE --start $start --end $end |tail -5
   echo "��ѯ����------------------------------------------------------------------"
   echo "��ʼʹ�õ�ǰʱ���д������----------------------------------------------------"
   total_input_traffic=$RANDOM
   total_output_traffic=$RANDOM
   echo "/usr/bin/rrdtool update $filePath  N:$total_input_traffic:$total_output_traffic"
   /usr/bin/rrdtool update $filePath  N:$total_input_traffic:$total_output_traffic
   echo "д�����ݽ���------------------------------------------------------------------"
   sleep 10
done

