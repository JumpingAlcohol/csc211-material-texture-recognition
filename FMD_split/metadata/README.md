# CSC211 FMD split / 数据切分说明

This split contains only five material classes: `leather`, `metal`, `stone`, `water`, and `wood`.

此切分仅包含五个材质类别：`leather`（皮革）、`metal`（金属）、`stone`（石材）、`water`（水）和 `wood`（木材）。

## Layout / 文件结构

- `train/image/<class>/`: 95 training images per class.
- `train/mask/<class>/`: matching masks; each mask has exactly the same filename as its image.
- `test/image/`: 25 anonymous test images, named `test_001.jpg` through `test_025.jpg`.
- `test/mask/`: matching anonymous masks with the same filenames as the test images.

- `train/image/<class>/`：每类 95 张训练图片。
- `train/mask/<class>/`：对应的遮罩；每张 mask 与图片文件名完全相同。
- `test/image/`：25 张匿名测试图片，命名为 `test_001.jpg` 至 `test_025.jpg`。
- `test/mask/`：与测试图片同名、逐一对应的匿名 mask。

## Metadata / 元数据

- `split_manifest.csv`: complete record of the fixed split.
- `test_labels_private.csv`: ground-truth test labels. Do not open before both human baselines are complete.
- `human_predictions_yuxiang.csv` and `human_predictions_ivans.csv`: independent human-baseline worksheets.

- `split_manifest.csv`：固定切分的完整记录。
- `test_labels_private.csv`：测试集真实标签。两位成员均完成独立人类预测前，请勿打开。
- `human_predictions_yuxiang.csv` 和 `human_predictions_ivans.csv`：两位成员独立填写的人类基线表。
