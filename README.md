# Using R Language to Crawl Text and Train Text Classification Models

This is my course assignment, which is still quite rough. Comments and corrections are welcome!
[中文](README-ZH.md) | [English](README.md)


## Overall Training思路

- **Research Background**: Sentiment analysis
- **Data Acquisition**: Crawling Douban short reviews
- **Data Preprocessing**: Text cleaning, Chinese word segmentation, stopword filtering, word frequency analysis
- **Feature Engineering**: Word frequency matrix and TF-IDF matrix
- **Model Building**: Neural network model
- **Model Optimization**: Optimal network structure


## R Language Web Crawling

During my first-year Python course, my personal curiosity drove me to try crawling data with Python, but for this assignment, the teacher required using R language.


There are not many tutorials on R language web crawling online, and none of them are very authoritative. It took me a long time to search for information initially.


Most tutorials use the `rvest` package, but no matter how I adjusted it, I would be blocked by Douban's anti-crawling mechanisms.


So I switched to using `RSelenium` for crawling, referring to the notes of a Bilibili uploader for environment configuration: [https://www.bilibili.com/opus/653824890129874965?spm_id_from=333.1007.0.0](https://www.bilibili.com/opus/653824890129874965?spm_id_from=333.1007.0.0).


Java needs to be installed, and each time you run it, you need to enter this code in cmd:
<img width="1475" height="379" alt="image" src="https://github.com/user-attachments/assets/ab4e32ba-f458-4ed8-bf51-060faa8410ff" />


- Define a comment scraping function `scrape_comments(url, output_file)` to cyclically extract comments until 500 are collected or no more can be obtained.
- Get the page source code and read it as HTML code, find the `short` class under `comment-item` from the HTML, read it as text, and add it to the total comment set.
- Due to the display limit per page, find the `next` element and click it; if it cannot be clicked, exit the loop.
- Save the results to a data frame and a CSV file.


## Data Cleaning and Feature Engineering

- Retain Chinese characters and line breaks, remove all other characters (such as English, numbers, punctuation, etc.), and remove blank lines and empty comments. An anonymous function `function(x)` was used to iterate through the comments.
- Use `Rwordseg` for word segmentation (initially wanted to use the `jieba` package, but couldn't install it properly; will try again another day). Filter using a stopword list (I randomly grabbed this list from GitHub, which I think is not rigorous and will be optimized later).
- Perform word frequency statistics and sort high-frequency words before and after filtering. This sorting can be used to modify the stopword list and remove some invalid information (but how to define invalid information? This is a problem).
- Construct a text sparse matrix (TF-IDF). When learning large models, I found that others seem to have other construction methods.


## Model Construction and Optimization

- Convert data categories to 0 or 1, and split the data into training and test sets (7:3 ratio. Why is there no validation set? Read on!).
- Here, the top 100 most discriminative features (indicator: the larger the difference between positive and negative TF-IDF values, the more discriminative) were directly selected to build the dataset for the neural network (meaning there are 100 variables), and data standardization was performed.
- Then use `neuralnet` to build a neural network model. Test and evaluate performance (accuracy, sensitivity, specificity, AUC value).
- Optimize the model starting from the hidden layer configuration: define multiple hidden layer configurations, test each, and make predictions on the test set.
- Sort by accuracy to get the best configuration, retrain the model, and visualize the optimization results (histograms, ROC curves).


Later, when learning DataWhale's fine-tuning at [https://www.datawhale.cn/learn/content/72/2928](https://www.datawhale.cn/learn/content/72/2928), I realized that the data should be divided into training, validation, and test sets; otherwise, the generalization ability of the model cannot be evaluated. This can be optimized later!
