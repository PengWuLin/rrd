package main

import (
	"fmt"
	"log"
	"math/rand"
	"os/exec"
	"time"

	"github.com/multiplay/go-rrd"
)

func main() {

	create()

	go update()

	fetch()

	c := make(chan struct{})

	<-c
}

func create() {
	c, err := rrd.NewClient("/var/lib/run/rrdcached_limited.sock", rrd.Unix)
	if err != nil {
		log.Fatal(err)
	}
	defer c.Close()
	t := time.Unix(time.Now().Unix()-86400-10, 0)

	if err := c.Create(
		"pengwl.rrd",
		[]rrd.DS{
			rrd.NewGauge("in", time.Minute*5, 0, 24000),
			rrd.NewGauge("out", time.Minute*5, 0, 24000),
		},
		[]rrd.RRA{
			rrd.NewAverage(0.5, 1, 60),
			rrd.NewAverage(0.5, 20, 72),
		},
		rrd.Start(t),
	); err != nil {
		log.Fatal(err)
	}
}

func update() {

	c, err := rrd.NewClient("/var/lib/run/rrdcached_limited.sock", rrd.Unix)
	if err != nil {
		log.Fatal(err)
	}
	defer c.Close()

	step := 86400 / 60
	t := time.Now().Unix() - 86400
	for i := 0; i <= step; i++ {
		a := randInt(0, 100)
		b := randInt(0, 100)
		t1 := time.Unix(t, 0)
		err = c.Update(
			"pengwl.rrd",
			rrd.NewUpdate(t1, a, b),
		)
		t += 60
		if err != nil {
			fmt.Printf("update failed:%s\n", err)
			panic(err)
		}
	}
}

func randInt(min int, max int) int {
	return min + rand.Intn(max-min)
}

func fetch() {
	c, err := rrd.NewClient("/var/lib/run/rrdcached_limited.sock", rrd.Unix)
	if err != nil {
		log.Fatal(err)
	}
	defer c.Close()

	tk := time.NewTicker(time.Second * 3)
	defer tk.Stop()

	for {
		select {
		case <-tk.C:
			fs, err := c.Fetch("pengwl.rrd",
				"AVERAGE",
			)
			if err != nil {
				fmt.Printf("查询失败")
				continue
			}
			fmt.Printf("查询成功\n")

			for _, row := range fs.Rows {
				fmt.Printf("row:%+v\n", row)
			}

			for _, name := range fs.Names {
				fmt.Printf("name:%s\n", name)
			}
		}
	}

}

func createByrrdtool() {
	args := []string{
		"create",
		"/root/pengwl/test.rrd",
		"--start", "1623072920",
		"--step", "60",
		"DS:netinPktRate:GAUGE:120:0:U",
		"DS:netoutPktRate:GAUGE:120:0:U",
		"DS:netinRate:GAUGE:120:0:U",
		"DS:netoutRate:GAUGE:120:0:U",
		"RRA:AVERAGE:0.5:1:60",
		"RRA:AVERAGE:0.5:20:72",
		"RRA:AVERAGE:0.5:720:60",
	}

	obj := exec.Command("/usr/bin/rrdtool", args...)
	out, err := obj.Output()
	if err != nil {
		fmt.Printf("out:%s,err:%s", out, err)
		return
	}
}
