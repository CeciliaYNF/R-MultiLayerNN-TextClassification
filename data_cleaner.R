# 加载必要的包
library(stringr)
library(dplyr)

# 定义数据清洗函数
clean_comments <- function(comments_df) {
  # 复制原始数据框
  cleaned_df <- comments_df
  
  # 定义正则表达式模式：匹配所有中文字符和换行符
  pattern <- "[^\u4e00-\u9fa5\n]"
  
  # 对每条评论应用清洗操作
  cleaned_df$cleaned_comment <- sapply(comments_df$comment, function(x) {
    # 移除所有非中文字符和换行符以外的字符
    cleaned_text <- str_replace_all(x, pattern, "")
    # 合并连续的换行符为单个换行符
    cleaned_text <- str_replace_all(cleaned_text, "\n+", "\n")
    # 移除开头和结尾的空白字符（包括换行符）
    cleaned_text <- str_trim(cleaned_text, side = "both")
    return(cleaned_text)
  })
  
  # 移除清洗后为空的评论
  cleaned_df <- cleaned_df[cleaned_df$cleaned_comment != "", ]
  
  return(cleaned_df)
}