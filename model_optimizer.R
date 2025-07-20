# 加载必要的包
library(caret)
library(neuralnet)
library(pROC)
library(ggplot2)

# 优化模型参数
optimize_neural_network <- function(train_nn, test_nn, top_features) {
  # 构建神经网络公式
  formula_nn <- as.formula(paste("category ~", paste(top_features, collapse = " + ")))
  
  # 定义要测试的隐藏层配置
  hidden_configs <- list(
    c(5),    # 1个隐藏层，5个神经元
    c(20),   # 1个隐藏层，20个神经元
    c(50),   # 1个隐藏层，50个神经元
    c(100),  # 1个隐藏层，100个神经元
    c(5, 5),    # 2个隐藏层，每层5个神经元
    c(20, 20),  # 2个隐藏层，每层20个神经元
    c(50, 50),  # 2个隐藏层，每层50个神经元
    c(100, 100),# 2个隐藏层，每层100个神经元
    c(5, 5, 5),    # 3个隐藏层，每层5个神经元
    c(20, 20, 20),  # 3个隐藏层，每层20个神经元
    c(50, 50, 50),  # 3个隐藏层，每层50个神经元
    c(100, 100, 100) # 3个隐藏层，每层100个神经元
  )
  
  # 创建结果存储数据框
  results <- data.frame(
    config = character(length(hidden_configs)),
    accuracy = numeric(length(hidden_configs)),
    sensitivity = numeric(length(hidden_configs)),
    specificity = numeric(length(hidden_configs)),
    auc = numeric(length(hidden_configs)),
    stringsAsFactors = FALSE
  )
  
  # 循环测试不同的隐藏层配置
  for (i in seq_along(hidden_configs)) {
    config <- hidden_configs[[i]]
    config_str <- paste(config, collapse = ",")
    
    cat("\n正在训练配置:", config_str, "\n")
    
    # 设置随机种子以确保结果可重现
    set.seed(123)
    
    # 构建并训练神经网络
    nn_model <- neuralnet(
      formula = formula_nn,
      data = train_nn,
      hidden = config,
      act.fct = "logistic",
      linear.output = FALSE,
      threshold = 0.01,
      stepmax = 1e6,
      lifesign = "minimal"  # 减少输出信息
    )
    
    # 在测试集上进行预测
    nn_pred_prob <- compute(nn_model, test_nn[, -ncol(test_nn)])$net.result
    nn_pred_class <- ifelse(nn_pred_prob > 0.5, 1, 0)
    
    # 评估模型性能
    conf_matrix <- confusionMatrix(factor(nn_pred_class), factor(test_nn$category), positive = "1")
    
    # 计算AUC
    roc_obj <- roc(test_nn$category, nn_pred_prob)
    
    # 存储结果
    results[i, "config"] <- paste("隐藏层:", length(config), " 神经元:", config_str)
    results[i, "accuracy"] <- conf_matrix$overall["Accuracy"]
    results[i, "sensitivity"] <- conf_matrix$byClass["Sensitivity"]
    results[i, "specificity"] <- conf_matrix$byClass["Specificity"]
    results[i, "auc"] <- pROC::auc(roc_obj)
    
    cat("配置", config_str, "训练完成\n")
  }
  
  # 按准确率排序结果
  results <- results[order(-results$accuracy), ]
  
  # 找出最佳配置
  best_config_idx <- which.max(results$accuracy)
  best_config <- hidden_configs[[best_config_idx]]
  
  # 使用最佳配置重新训练模型
  set.seed(123)
  best_nn_model <- neuralnet(
    formula = formula_nn,
    data = train_nn,
    hidden = best_config,
    act.fct = "logistic",
    linear.output = FALSE,
    threshold = 0.01,
    stepmax = 1e6
  )
  
  return(list(
    best_model = best_nn_model,
    best_config = results$config[best_config_idx],
    all_results = results
  ))
}

# 可视化优化结果
visualize_optimization_results <- function(results) {
  # 准确率对比图
  p1 <- ggplot(results, aes(x = reorder(config, accuracy), y = accuracy)) +
    geom_bar(stat = "identity", fill = "skyblue") +
    coord_flip() +
    labs(title = "不同隐藏层配置的模型准确率对比",
         x = "隐藏层配置",
         y = "准确率") +
    theme_minimal()
  
  # AUC对比图
  p2 <- ggplot(results, aes(x = reorder(config, auc), y = auc)) +
    geom_bar(stat = "identity", fill = "lightgreen") +
    coord_flip() +
    labs(title = "不同隐藏层配置的模型AUC对比",
         x = "隐藏层配置",
         y = "AUC值") +
    theme_minimal()
  
  return(list(accuracy_plot = p1, auc_plot = p2))
}