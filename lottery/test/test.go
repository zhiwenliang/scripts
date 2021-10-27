package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"time"
)

func main() {
	names := "袁星\n阿道夫1\n阿道夫2\n阿道夫3\n阿道夫4\n阿道夫5\n阿道夫6\n阿道夫7\n阿道夫8\n阿道夫9\n阿道夫10\n阿道夫11\n阿道夫12\n阿道夫13\n阿道夫14\n阿道夫15\n阿道夫16\n阿道夫17\n阿道夫18\n阿道夫19\n阿道夫20\n阿道夫21\n阿道夫22\n阿道夫23\n阿道夫24\n阿道夫25\n阿道夫26\n阿道夫27\n阿道夫28\n阿道夫29\n"
	arrs := strings.Split(names, "\n")
	fmt.Println(findEle(arrs, "袁星"))
}

func findEle(list []string, target string) int {
	for _, value := range list {
		if value == target {
			return 1
		}
	}
	return 0
}

func lottery(text string, count int) string {
	arrs := strings.Split(text, "\n")
	length := len(arrs)
	indexs := generateRandomNumber(0, length-1, count)
	var resultArr []string
	for i := 0; i < count; i++ {
		index := indexs[i]
		value := strconv.Itoa(i) + "---" + strconv.Itoa(index) + "--" + arrs[index]
		resultArr = append(resultArr, value)
	}
	result := strings.Join(resultArr, "\n")
	return result
}

//生成count个[start,end)结束的不重复的随机数
func generateRandomNumber(start int, end int, count int) []int {
	//范围检查
	if end < start || (end-start) < count {
		return nil
	}

	//存放结果的slice
	nums := make([]int, 0)
	//随机数生成器，加入时间戳保证每次生成的随机数不一样
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for len(nums) < count {
		//生成随机数
		num := r.Intn((end - start)) + start

		//查重
		exist := false
		for _, v := range nums {
			if v == num {
				exist = true
				break
			}
		}

		if !exist {
			nums = append(nums, num)
		}
	}

	return nums
}
