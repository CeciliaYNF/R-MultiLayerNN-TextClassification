# 加载必要的包
library(tm)
library(Matrix)
library(dplyr)

# 生成词频统计函数
generate_word_frequency <- function(segmented_df, top_n = 30) {
  # 将所有评论的分词结果合并为一个大字符串
  all_words <- paste(segmented_df$segmented_comment, collapse = " ")
  # 分割成单词列表
  word_list <- unlist(strsplit(all_words, " "))
  # 过滤掉空字符串
  word_list <- word_list[word_list != ""]
  # 计算词频
  word_freq <- table(word_list)
  # 转换为数据框
  freq_df <- data.frame(
    word = names(word_freq),
    frequency = as.numeric(word_freq),
    stringsAsFactors = FALSE
  )
  # 按词频排序
  freq_df <- freq_df[order(freq_df$frequency, decreasing = TRUE), ]
  # 重置索引
  rownames(freq_df) <- NULL
  # 返回前top_n个词
  return(freq_df[1:min(top_n, nrow(freq_df)), ])
}

# 生成过滤后的词频统计函数
generate_filtered_word_frequency <- function(filtered_df, top_n = 30) {
  # 将所有评论的过滤后结果合并为一个大字符串
  all_words <- paste(filtered_df$filtered_comment, collapse = " ")
  # 分割成单词列表
  word_list <- unlist(strsplit(all_words, " "))
  # 过滤掉空字符串
  word_list <- word_list[word_list != ""]
  # 计算词频
  word_freq <- table(word_list)
  # 转换为数据框
  freq_df <- data.frame(
    word = names(word_freq),
    frequency = as.numeric(word_freq),
    stringsAsFactors = FALSE
  )
  # 按词频排序
  freq_df <- freq_df[order(freq_df$frequency, decreasing = TRUE), ]
  # 重置索引
  rownames(freq_df) <- NULL
  # 返回前top_n个词
  return(freq_df[1:min(top_n, nrow(freq_df)), ])
}

# 构建文本稀疏矩阵
build_sparse_matrix <- function(all_comments) {
  # 创建语料库
  corpus <- Corpus(VectorSource(all_comments$filtered_comment))
  
  # 转换为文档术语矩阵(稀疏矩阵)
  dtm <- DocumentTermMatrix(corpus)
  
  # 使用TF-IDF进行标准化
  dtm_tf_idf <- weightTfIdf(dtm)
  
  # 转换为普通稀疏矩阵
  dtm_sparse_tf_idf <- as.matrix(dtm_tf_idf) %>% as("dgCMatrix")
  
  # 将TF-IDF矩阵转换为数据框
  tf_idf_df <- as.data.frame(as.matrix(dtm_tf_idf))
  
  # 添加评论类别列
  tf_idf_df$category <- all_comments$category
  
  return(tf_idf_df)
}