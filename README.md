## 核心方法

1. 先使用自带的质量分类器（`data-juicer/tools/quality_classifier/predict.py`）对训练集进行打分，编写脚本（`./filter.py`）保留得分高于0.99的样本。
2. 保留得分高于0.99的样本后，对该样本用 `data-juicer/tools/process_data.py` 进行数据清洗。
3. 清洗后的数据利用 `lm-training/get_train_dataset_1b.py` 进行采样。
4. 采样后的数据进行训练（`lm-training/train_scripts/deepspeed_train_1b.sh`）和测试（`lm-evaluation-harness/examples/challenge-1B-stage1.sh`）

## 文件解释

- `alpaca-cot-en-refine2.yaml`: `data-juicer/tools/process_data.py` 进行数据清洗的配置文件
- `data_en_32.jsonl`: 采样后用于模型训练的数据集（即 Dprocess）
- `model`: 训练后保存的模型
- `submit.zip`: 最优结果的结果文件
- **`run.sh`**: 全流程脚本文件

## 运行方式1（自动化脚本）
- 我们编写了全流程脚本 `run.sh`，该脚本可实现数据质量分类->保留得分高于0.99的样本->数据清洗->数据采样->模型训练->模型测试->结果打包。

- 运行代码
```bash
sh ./run.sh ./alpaca-cot-en-refine2.yaml
```
- 注意：  
1. 请预先修改run.sh本项目涉及到的绝对路径问题（`run.sh`的第13行（项目路径）、50行（raw_data路径）、87行（模型路径）、103行（challenge-data路径））  
2. 运行时指定配置文件路径，如：` sh ./run.sh ./alpaca-cot-en-refine2.yaml ` 
3. 运行的所有中间结果（中间数据、模型、结果等）会保留在./process/的新建文件下如./process/02/。

## 运行方式2（手动操作）  
1. 激活环境 
`conda activate dj_comp`

2. 路径声明（非必要）  
`export PYTHONPATH=/home/vot/votssd/code/ChenHu/HLLY/competition_kit/data-juicer/:$PYTHONPATH`  
`export PYTHONPATH=/home/vot/votssd/code/ChenHu/HLLY/competition_kit/:$PYTHONPATH`

3. 质量得分分类及依据得分过滤数据  
`cd data-juicer`  
`cd tools`  
`cd quality_classifier/`  
`python predict.py "/home/vot/votssd/code/ChenHu/HLLY/competition_kit/data/raw_data/raw_data_en.jsonl" "/home/vot/votssd/code/ChenHu/HLLY/competition_kit/data/quality_classifier/01/classfier_data.jsonl"`  
`cd ..`  
`python filter_based_quality_classifier.py`  (修改英文input_path 和 output_path、修改阈值0.99）（此处也可使用./filter.py）  

3. 数据清洗  
`cd data-juicer`  
`python tools/process_data.py --config ./alpaca-cot-en-refine2.yaml` （修改dataset_path、export_path）  

4. 数据采样  
`cd lm-training`
`python get_train_dataset_1b.py`（修改EN_DATA_DIR、ZH_DATA_DIR、OUTPUT_FILES）  

5. 训练  
`cd lm-training`
`sh train_scripts/deepspeed_train_1b.sh {model_path} {data_path} {output_path}`

6. 评估  
`cd lm-evaluation-harness`
`sh examples/challenge-1B-stage1.sh{mode} {model_path} {output_path}`

## 注意事项
利用质量分类器进行数据打分和利用得分过滤数据集的时候，该步骤本身不具有随机性，但数据集内的数据顺序会发生变化，该步骤可能会导致最终训练得分的少量波动。如若想完整复现最优模型，可参考data_en_32.jsonl内的键值对顺序重新排序。
