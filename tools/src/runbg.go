package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "os/exec"
    "strings"
    "time"
    "unicode"
)

// 默认 Webhook
const defaultWebhook = "http://in.qyapi.weixin.qq.com/cgi-bin/webhook/send?key=48c3d080-4865-40ad-a677-9eeaf8c72268"
const logTailLines = 10

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

    webhookURL := os.Getenv("WECHAT_WEBHOOK")
    if webhookURL == "" {
        webhookURL = defaultWebhook
    }

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
        fmt.Printf("Failed to create log file: %v\n", err)
        os.Exit(1)
    }
    defer logFile.Close()

    fmt.Printf("Logs will be written to: %s\n", logFileName)

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

    if err != nil {
        os.Exit(1)
    }
}

func readLastLines(filename string, n int) string {
    file, err := os.Open(filename)
    if err != nil { return "(无法读取日志)" }
    defer file.Close()

    stat, _ := file.Stat()
    fileSize := stat.Size()
    var bufSize int64 = 2048
    if fileSize < bufSize { bufSize = fileSize }
    startPos := fileSize - bufSize
    if startPos < 0 { startPos = 0 }
    buf := make([]byte, bufSize)
    file.Seek(startPos, 0)
    readBytes, _ := file.Read(buf)
    
    lines := strings.Split(string(buf[:readBytes]), "\n")
    if len(lines) > n {
        lines = lines[len(lines)-n:]
    }
    result := strings.Join(lines, "\n")
    if strings.TrimSpace(result) == "" { return "(无输出内容)" }
    return result
}

func sendToWeCom(url, content string) {
    msg := WeComMarkdown{MsgType: "markdown"}
    msg.Markdown.Content = content
    jsonData, _ := json.Marshal(msg)
    resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonData))
    if err != nil { return }
    defer resp.Body.Close()
}
