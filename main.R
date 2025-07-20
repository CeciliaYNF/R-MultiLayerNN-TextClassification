source("data_crawler.R")
source("data_cleaner.R")
source("text_preprocessor.R")
source("feature_extractor.R")
source("model_builder.R")
source("model_optimizer.R")

# 1. 数据爬取
cat("开始爬取评论数据...\n")
base_url <- "https://movie.douban.com/subject/26925611/comments"

# 爬取好评
positive_params <- "?percent_type=h&limit=20&status=P&sort=new_score"
positive_url <- paste0(base_url, positive_params)
positive_comments <- scrape_comments(positive_url, "douban_positive_comments.csv")

# 爬取差评
negative_params <- "?percent_type=l&limit=20&status=P&sort=new_score"
negative_url <- paste0(base_url, negative_params)
negative_comments <- scrape_comments(negative_url, "douban_negative_comments.csv")

# 2. 数据清洗
cat("\n开始清洗评论数据...\n")
cleaned_positive <- clean_comments(positive_comments)
cleaned_negative <- clean_comments(negative_comments)

# 保存清洗后的数据
write.csv(cleaned_positive, "douban_positive_comments_cleaned.csv", 
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(cleaned_negative, "douban_negative_comments_cleaned.csv", 
          row.names = FALSE, fileEncoding = "UTF-8")

# 3. 特征工程
cat("\n开始特征工程...\n")
# 分词（使用text_preprocessor模块）
segmented_positive <- segment_comments(cleaned_positive)
segmented_negative <- segment_comments(cleaned_negative)

# 读取停用词表（使用text_preprocessor模块）
stopwords_path <- "stopwords.csv"
stopwords <- read_stopwords(stopwords_path)

# 过滤停用词（使用text_preprocessor模块）
filtered_positive <- filter_stopwords(segmented_positive, stopwords)
filtered_negative <- filter_stopwords(segmented_negative, stopwords)

# 为评论添加类别标签
filtered_positive$category <- "positive"
filtered_negative$category <- "negative"

# 合并好评和差评数据
all_comments <- rbind(filtered_positive, filtered_negative)

# 构建文本稀疏矩阵（使用feature_extractor模块）
tf_idf_df <- build_sparse_matrix(all_comments)
write.csv(tf_idf_df, "douban_comments_tf_idf.csv", row.names = FALSE, fileEncoding = "UTF-8")

# 4. 模型构建
cat("\n开始构建模型...\n")
data_prep <- prepare_data(tf_idf_df)
train_nn <- data_prep$train_nn
test_nn <- data_prep$test_nn
top_features <- data_prep$top_features

# 构建基础神经网络模型
base_model <- build_neural_network(train_nn, top_features)
base_evaluation <- evaluate_model(base_model, test_nn)

cat("\n基础模型性能评估:\n")
print(base_evaluation$conf_matrix)
cat("\nAUC值:", pROC::auc(base_evaluation$roc_obj), "\n")

# 5. 模型优化
cat("\n开始优化模型...\n")
optimization_results <- optimize_neural_network(train_nn, test_nn, top_features)

cat("\n最佳模型配置:", optimization_results$best_config, "\n")

# 可视化优化结果
plots <- visualize_optimization_results(optimization_results$all_results)
print(plots$accuracy_plot)
print(plots$auc_plot)

# 保存最佳模型
save(optimization_results$best_model, file = "douban_best_sentiment_nn_model.RData")
cat("\n最佳神经网络模型已保存到 douban_best_sentiment_nn_model.RData\n")