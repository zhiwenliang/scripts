package main

import (
	"math/rand"
	"strings"
	"time"

	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
)

func main() {
	var inTE, outTE *walk.TextEdit
	var count *walk.NumberEdit
	var button *walk.PushButton

	MainWindow{
		Title:   "抓阄工具",
		MinSize: Size{Width: 400, Height: 248},
		Layout:  VBox{},
		Children: []Widget{
			HSplitter{
				Children: []Widget{
					TextEdit{
						AssignTo: &inTE,
						VScroll:  true,
						Font:     Font{Family: "Microsoft YaHei", PointSize: 10},
					},
					TextEdit{
						AssignTo: &outTE,
						ReadOnly: true,
						VScroll:  true,
						Font:     Font{Family: "Microsoft YaHei", PointSize: 20},
					},
				},
			},
			GroupBox{
				Layout: HBox{},
				Children: []Widget{
					Label{
						Font: Font{Family: "Microsoft YaHei", PointSize: 20},
						Text: "抽取人数",
					},
					NumberEdit{
						AssignTo: &count,
						Font:     Font{Family: "Microsoft YaHei", PointSize: 20},
					},
					PushButton{
						AssignTo: &button,
						Text:     "开始抽取",
						Font:     Font{Family: "Microsoft YaHei", PointSize: 20},
						OnClicked: func() {
							outTE.SetText(lottery(inTE.Text(), int(count.Value())))
						},
					},
				},
			},
		},
	}.Run()
}

func lottery(text string, count int) string {
	arrs := strings.Split(text, "\n")
	length := len(arrs)
	indexs := generateRandomNumber(0, length, count)
	var resultArr []string
	for i := 0; i < count; i++ {
		index := indexs[i]
		value := string(rune(index)) + "--" + arrs[index]
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
