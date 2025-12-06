package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
	"unicode"
)

// 默认 Webhook
const defaultWebhook = "http://in.qyapi.weixin.qq.com/cgi-bin/webhook/send?key=48c3d080-4865-40ad-a677-9eeaf8c72268"
const logTailLines = 10

// WeComMarkdown ...
type WeComMarkdown struct {
	MsgType  string `json:"msgtype"`
	Markdown struct {
		Content string `json:"content"`
	} `json:"markdown"`
}

// --- 新增：文件名清洗函数 ---
func sanitizeFilename(input string) string {
	var result strings.Builder
	input = strings.TrimSpace(input)

	// 1. 只取前 30 个字符，避免文件名过长
	runes := []rune(input)
	if len(runes) > 30 {
		runes = runes[:30]
	}

	// 2. 遍历字符，只保留字母数字，其他的变下划线
	lastIsUnderscore := false
	for _, r := range runes {
		if unicode.IsLetter(r) || unicode.IsDigit(r) || r == '-' || r == '.' {
			result.WriteRune(r)
			lastIsUnderscore = false
		} else {
			// 如果已经是下划线了，就别重复加了，避免出现 tag____xx
			if !lastIsUnderscore {
				result.WriteRune('_')
				lastIsUnderscore = true
			}
		}
	}

	// 去掉首尾的下划线
	s := strings.Trim(result.String(), "_")

	if s == "" {
		return "task"
	}
	return s
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: cmd-notifier <command...>")
		os.Exit(1)
	}

	// 检查是否是子进程（后台执行进程）
	if os.Getenv("_RUNBG_CHILD") == "1" {
		// 这是子进程，执行实际的任务
		runChildProcess()
		return
	}

	// 这是主进程，启动子进程后立即退出
	startBackgroundProcess()
}

// 启动后台子进程
func startBackgroundProcess() {
	// 获取当前可执行文件路径
	execPath, err := os.Executable()
	if err != nil {
		// 如果获取失败，使用 os.Args[0]
		execPath = os.Args[0]
	}

	// 创建子进程命令
	cmd := exec.Command(execPath, os.Args[1:]...)

	// 设置环境变量，标记这是子进程
	cmd.Env = append(os.Environ(), "_RUNBG_CHILD=1")

	// 设置进程属性，让子进程独立运行
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setsid: true, // 创建新的会话，脱离父进程
	}

	// 重定向标准输入输出到 /dev/null，避免占用终端
	cmd.Stdin = nil
	cmd.Stdout = nil
	cmd.Stderr = nil

	// 启动子进程
	err = cmd.Start()
	if err != nil {
		fmt.Printf("Failed to start background process: %v\n", err)
		os.Exit(1)
	}

	// 主进程立即退出，不等待子进程
	fmt.Printf("任务已在后台启动 (PID: %d)，主进程退出\n", cmd.Process.Pid)
	os.Exit(0)
}

// 子进程执行实际任务
func runChildProcess() {
	// 忽略 SIGHUP 信号，避免终端关闭时被杀死
	signal.Ignore(syscall.SIGHUP)

	webhookURL := os.Getenv("WECHAT_WEBHOOK")
	if webhookURL == "" {
		webhookURL = defaultWebhook
	}

	// 重新获取命令参数（因为子进程会重新解析）
	// 注意：子进程的 os.Args 和主进程一样，所以需要跳过 _RUNBG_CHILD 环境变量标记
	fullCommandStr := strings.Join(os.Args[1:], " ")

	// --- 修改点：使用新的清洗函数生成文件名 ---
	// 输入: "tag=xx; echo $tag"
	// 输出: tag_xx_echo_tag
	safeName := sanitizeFilename(fullCommandStr)

	timestamp := time.Now().Format("20060102_150405")
	// 最终文件名: tag_xx_echo_tag_20251120_154723.log
	logFileName := fmt.Sprintf("%s_%s.log", safeName, timestamp)

	logFile, err := os.Create(logFileName)
	if err != nil {
		// 子进程无法打印到终端，所以写入错误日志
		os.WriteFile("runbg_error.log", []byte(fmt.Sprintf("Failed to create log file: %v\n", err)), 0644)
		os.Exit(1)
	}
	defer logFile.Close()

	// 执行命令
	cmd := exec.Command("/bin/bash", "-c", fullCommandStr)
	cmd.Stdout = logFile
	cmd.Stderr = logFile

	startTime := time.Now()
	err = cmd.Run()
	duration := time.Since(startTime)

	tailContent := readLastLines(logFileName, logTailLines)

	var titleColor, statusText string
	if err != nil {
		titleColor = "warning"
		statusText = fmt.Sprintf("❌ 失败 (Exit: %s)", err.Error())
	} else {
		titleColor = "info"
		statusText = "✅ 成功"
	}

	hostname, _ := os.Hostname()

	content := fmt.Sprintf(
		`### 任务执行报告
>**主机**: %s
>**状态**: <font color="%s">%s</font>
>**命令**: %s
>**耗时**: %s
>**日志**: %s
>
>**输出 (Last %d lines)**:
>%s
`,
		hostname,
		titleColor, statusText,
		fullCommandStr,
		duration.Round(time.Millisecond),
		logFileName,
		logTailLines,
		tailContent,
	)

	sendToWeCom(webhookURL, content)

	// 子进程执行完成后自动退出
	if err != nil {
		os.Exit(1)
	}
	os.Exit(0)
}

func readLastLines(filename string, n int) string {
	file, err := os.Open(filename)
	if err != nil {
		return "(无法读取日志)"
	}
	defer file.Close()

	stat, _ := file.Stat()
	fileSize := stat.Size()
	var bufSize int64 = 2048
	if fileSize < bufSize {
		bufSize = fileSize
	}
	startPos := fileSize - bufSize
	if startPos < 0 {
		startPos = 0
	}
	buf := make([]byte, bufSize)
	file.Seek(startPos, 0)
	readBytes, _ := file.Read(buf)

	lines := strings.Split(string(buf[:readBytes]), "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	result := strings.Join(lines, "\n")
	if strings.TrimSpace(result) == "" {
		return "(无输出内容)"
	}
	return result
}

func sendToWeCom(url, content string) {
	msg := WeComMarkdown{MsgType: "markdown"}
	msg.Markdown.Content = content
	jsonData, _ := json.Marshal(msg)
	resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return
	}
	defer resp.Body.Close()
}
