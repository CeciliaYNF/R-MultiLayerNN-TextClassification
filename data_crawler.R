# 加载必要的包
library(RCurl)
library(XML)
library(rvest)
library(RSelenium)
library(stringr)

# 定义爬取函数
scrape_comments <- function(url, output_file) {
  # 启动Selenium驱动
  remdr <- remoteDriver(browserName = "chrome")
  remdr$open()
  remdr$navigate(url)
  
  # 初始化评论容器
  all_comments <- character()
  
  # 循环提取评论直到达到500条或无法加载更多
  tryCatch({
    while(length(all_comments) < 500) {
      # 获取当前页面源代码
      m <- remdr$getPageSource()
      webpage <- read_html(m[[1]])
      
      # 提取评论内容
      comments <- webpage %>% 
        html_nodes(".comment-item .short") %>% 
        html_text()
      
      # 添加到总评论集
      all_comments <- c(all_comments, comments)
      
      # 打印进度
      cat("已提取", length(all_comments), "条评论\n")
      
      # 如果已经达到或超过500条，跳出循环
      if(length(all_comments) >= 500) {
        break
      }
      
      # 尝试点击"下一页"按钮
      next_button <- remdr$findElement(using = "css selector", ".next")
      button_status <- next_button$getElementAttribute("class")
      
      # 如果按钮不可用，退出循环
      if(grepl("disabled", button_status[[1]])) {
        cat("已到达最后一页，无法加载更多评论\n")
        break
      } else {
        # 点击下一页
        next_button$clickElement()
        # 等待页面加载
        Sys.sleep(2)
      }
    }
  }, error = function(e) {
    cat("发生错误:", e$message, "\n")
  }, finally = {
    # 关闭浏览器
    remdr$close()
  })
  
  # 截取前500条评论
  if(length(all_comments) > 500) {
    all_comments <- all_comments[1:500]
  }
  
  # 保存结果到数据框
  comments_df <- data.frame(
    comment = all_comments,
    stringsAsFactors = FALSE
  )
  
  # 保存到CSV文件
  write.csv(comments_df, output_file, row.names = FALSE, fileEncoding = "UTF-8")
  
  # 打印完成信息
  cat("成功提取", nrow(comments_df), "条评论并保存到", output_file, "\n")
  
  return(comments_df)
}