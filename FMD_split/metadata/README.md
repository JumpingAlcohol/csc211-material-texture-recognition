# CSC211 FMD split / 数据切分说明

This split contains only five material classes: `leather`, `metal`, `stone`, `water`, and `wood`.

此切分仅包含五个材质类别：`leather`（皮革）、`metal`（金属）、`stone`（石材）、`water`（水）和 `wood`（木材）。

## Layout / 文件结构

- `train/image/<class>/`: 85 training images per class (425 total).
- `train/mask/<class>/`: matching masks; each mask has exactly the same filename as its image.
- `validation/image/<class>/`: 10 validation images per class (50 total), selected only from the former training set.
- `validation/mask/<class>/`: matching masks with identical filenames.
- `test/image/`: 25 anonymously named, globally shuffled test images.
- `test/mask/`: matching anonymous masks with the same filenames as the test images.

- `train/image/<class>/`：每类 85 张训练图片，共 425 张。
- `train/mask/<class>/`：对应的遮罩；每张 mask 与图片文件名完全相同。
- `validation/image/<class>/`：每类 10 张验证图片，共 50 张，仅从原训练集中选取。
- `validation/mask/<class>/`：与验证图片同名、一一对应的 mask。
- `test/image/`：25 张全局打乱、匿名命名的测试图片。
- `test/mask/`：与测试图片同名、逐一对应的匿名 mask。

## Metadata / 元数据

Validation is for model selection and tuning. Test membership, anonymous IDs, masks, labels and existing human predictions are preserved. If training already used these validation images, retrain from an initialization that has not used them before reporting validation results.

验证集用于选择模型和调参。本次调整保留测试集成员、匿名编号、mask、标签和已有的人类预测。如果模型已使用这些验证图片训练过，需从未使用它们的初始状态重新训练，再报告验证结果。

For an existing 95/5 split, `add_validation_split.ps1` adds validation without resetting human predictions. `split_fmd.ps1` creates the same 85/10/5 split from scratch into a new directory and creates blank human worksheets. Do not delete completed worksheets to rerun it.

已有的 95/5 切分可用 `add_validation_split.ps1` 添加验证集，保留人类预测。`split_fmd.ps1` 用于在新目录中从头生成相同的 85/10/5 切分及空白预测表；不要为重跑脚本而删除已填写的预测表。

- `split_manifest.csv`: complete record of the fixed split.
- `test_labels_private.csv`: ground-truth test labels. Do not open before both human baselines are complete.
- `human_predictions_yuxiang.csv` and `human_predictions_ivans.csv`: independent human-baseline worksheets.

- `split_manifest.csv`：固定切分的完整记录。
- `test_labels_private.csv`：测试集真实标签。两位成员均完成独立人类预测前，请勿打开。
- `human_predictions_yuxiang.csv` 和 `human_predictions_ivans.csv`：两位成员独立填写的人类基线表。
