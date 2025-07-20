# 加载必要的包
library(caret)
library(neuralnet)
library(e1071)
library(ROSE)
library(pROC)

# 准备数据
prepare_data <- function(tf_idf_df) {
  # 将类别转换为数值（0和1）
  tf_idf_df$category <- ifelse(tf_idf_df$category == "positive", 1, 0)
  
  # 数据划分（70%训练集，30%测试集）
  set.seed(123)
  train_indices <- createDataPartition(tf_idf_df$category, p = 0.7, list = FALSE)
  train_data <- tf_idf_df[train_indices, ]
  test_data <- tf_idf_df[-train_indices, ]
  
  # 特征选择：选择前100个最具区分性的特征
  feature_importance <- sapply(colnames(train_data)[-ncol(train_data)], function(feature) {
    mean_pos <- mean(train_data[train_data$category == 1, feature])
    mean_neg <- mean(train_data[train_data$category == 0, feature])
    return(abs(mean_pos - mean_neg))
  })
  
  # 选择前100个最重要的特征
  top_features <- names(sort(feature_importance, decreasing = TRUE)[1:100])
  
  # 构建用于神经网络的数据集
  train_nn <- train_data[, c(top_features, "category")]
  test_nn <- test_data[, c(top_features, "category")]
  
  # 数据标准化
  preProc <- preProcess(train_nn[, -ncol(train_nn)], method = c("center", "scale"))
  train_nn[, -ncol(train_nn)] <- predict(preProc, train_nn[, -ncol(train_nn)])
  test_nn[, -ncol(test_nn)] <- predict(preProc, test_nn[, -ncol(test_nn)])
  
  return(list(train_nn = train_nn, test_nn = test_nn, top_features = top_features))
}

# 构建神经网络模型
build_neural_network <- function(train_nn, top_features) {
  # 构建神经网络公式
  formula_nn <- as.formula(paste("category ~", paste(top_features, collapse = " + ")))
  
  # 构建神经网络模型
  set.seed(123)
  nn_model <- neuralnet(
    formula = formula_nn,
    data = train_nn,
    hidden = 5,  # 1个隐藏层，包含5个神经元
    act.fct = "logistic",  # 逻辑激活函数
    linear.output = FALSE,  # 分类问题
    threshold = 0.01,  # 误差阈值
    stepmax = 1e6  # 最大迭代步数
  )
  
  return(nn_model)
}

# 评估模型
evaluate_model <- function(nn_model, test_nn) {
  # 在测试集上进行预测
  nn_pred_prob <- compute(nn_model, test_nn[, -ncol(test_nn)])$net.result
  nn_pred_class <- ifelse(nn_pred_prob > 0.5, 1, 0)
  
  # 评估模型性能
  conf_matrix <- confusionMatrix(factor(nn_pred_class), factor(test_nn$category), positive = "1")
  
  # 计算AUC
  roc_obj <- roc(test_nn$category, nn_pred_prob)
  
  return(list(conf_matrix = conf_matrix, roc_obj = roc_obj, pred_prob = nn_pred_prob))
}