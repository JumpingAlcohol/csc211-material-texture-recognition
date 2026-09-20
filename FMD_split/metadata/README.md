# CSC211 FMD split metadata / 元数据说明

This folder documents the fixed, class-balanced data split for our CSC211 Material & Texture Recognition project. The original FMD dataset has not been modified.

本文件夹记录 CSC211「材质与纹理识别」项目所使用的固定、按类别平衡的数据切分。原始 FMD 数据集未被修改。

## Split summary / 切分概要

| Split / 部分 | Images per class / 每类图片数 | Total / 总数 | Purpose / 用途 |
|---|---:|---:|---|
| `train` | 85 | 850 | Model development and deep-learning training / 模型开发与深度学习训练 |
| `validation` | 10 | 100 | Hyperparameter tuning and model selection / 调参与模型选择 |
| `test_blinded` | 5 | 50 | Final comparison of all four approaches / 四种方法的最终比较 |

The ten labels are `fabric`, `foliage`, `glass`, `leather`, `metal`, `paper`, `plastic`, `stone`, `water`, and `wood`.

十个类别为：`fabric`（织物）、`foliage`（植物）、`glass`（玻璃）、`leather`（皮革）、`metal`（金属）、`paper`（纸）、`plastic`（塑料）、`stone`（石材）、`water`（水）和 `wood`（木材）。

## Files / 文件

### `split_manifest.csv`

Complete record of every original image and its assigned split. It contains the split name, ground-truth label, original filename, and output filename. Use it to reproduce, audit, or trace the split. Do not use test labels while making human predictions.

记录所有原始图片及其分配结果的完整清单，包含切分名称、真实标签、原文件名和输出文件名。可用于复核、追溯数据来源。进行人类基线预测时，请不要查看测试集相关标签。

### `test_labels_private.csv`

Maps the anonymous files in `../test_blinded/` (for example, `test_001.jpg`) to their ground-truth labels. **Do not open this file until both Yuxiang and Ivans have independently completed their human-prediction CSV files.**

将 `../test_blinded/` 中匿名图片（例如 `test_001.jpg`）对应到真实标签。**在 Yuxiang 和 Ivans 都独立完成各自的人类预测 CSV 前，请勿打开此文件。**

### `human_predictions_yuxiang.csv`

Yuxiang's human-baseline worksheet. It contains all 50 anonymous example IDs. Fill in `human_prediction` using exactly one of the ten labels; optionally write a brief reason in `notes`.

Yuxiang 的人类基线预测表，已包含 50 个匿名样本 ID。请在 `human_prediction` 中填写十个固定类别之一；可在 `notes` 中写下简短判断理由。

### `human_predictions_ivans.csv`

Ivans's independent human-baseline worksheet. Complete it without viewing Yuxiang's predictions or the true labels.

Ivans 的独立人类基线预测表。填写时请勿查看 Yuxiang 的预测或真实标签。

## Human-baseline procedure / 人类基线流程

1. Each partner views only `../test_blinded/` and fills in their own CSV independently.
2. Do not discuss individual predictions or view either the other person's prediction file or `test_labels_private.csv`.
3. After both files are complete, compare them with `test_labels_private.csv` and calculate the results.

1. 两位成员只查看 `../test_blinded/`，并独立填写自己的 CSV。
2. 不要讨论单张图片的预测，也不要查看对方的预测文件或 `test_labels_private.csv`。
3. 两份预测均完成后，才可与 `test_labels_private.csv` 对照并计算结果。

## Important / 重要提醒

The fixed split must be used by the human, algorithmic, deep-learning, and LLM approaches so that their results are comparable. Do not move images between split folders or change the anonymous test filenames.

人类、算法、深度学习和 LLM 四种方法都必须使用这份固定切分，结果才可以公平比较。请勿在不同切分文件夹间移动图片，也不要更改匿名测试图片的文件名。
