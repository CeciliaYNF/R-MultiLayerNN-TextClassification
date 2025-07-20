# 加载必要的包
library(Rwordseg)
library(dplyr)

# 定义分词函数
segment_comments <- function(comments_df) {
  # 复制原始数据框
  segmented_df <- comments_df
  
  # 对每条清洗后的评论进行分词
  segmented_df$segmented_comment <- sapply(comments_df$cleaned_comment, function(x) {
    # 使用segmentCN函数进行分词
    words <- segmentCN(x)
    # 将分词结果连接成字符串，用空格分隔
    paste(words, collapse = " ")
  })
  
  return(segmented_df)
}

# 定义读取停用词表的函数
read_stopwords <- function(file_path) {
  # 尝试读取CSV格式的停用词表
  tryCatch({
    stopwords <- read.csv(file_path, header = FALSE, stringsAsFactors = FALSE)
    # 确保返回的是字符向量
    if(ncol(stopwords) >= 1) {
      return(as.character(stopwords[, 1]))
    } else {
      warning("停用词表格式不正确，返回空向量")
      return(character(0))
    }
  }, error = function(e) {
    warning(paste("读取停用词表时出错:", e$message))
    return(character(0))
  })
}

# 定义停用词过滤函数
filter_stopwords <- function(segmented_df, stopwords) {
  # 复制原始数据框
  filtered_df <- segmented_df
  
  # 对每条分词后的评论进行停用词过滤
  filtered_df$filtered_comment <- sapply(segmented_df$segmented_comment, function(x) {
    # 分割成单个词语
    words <- unlist(strsplit(x, " "))
    # 过滤掉停用词和空字符串
    filtered_words <- words[!(words %in% stopwords | words == "")]
    # 将过滤后的词语重新连接成字符串
    paste(filtered_words, collapse = " ")
  })
  
  # 移除过滤后为空的评论
  filtered_df <- filtered_df[filtered_df$filtered_comment != "", ]
  
  return(filtered_df)
}