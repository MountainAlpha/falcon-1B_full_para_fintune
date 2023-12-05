#!/bin/bash

# 检查参数数量
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <config_file.yaml>"
    exit 1
fi

# 获取输入参数
config_file=$1

# 定义目录变量
base_dir="/data/home/81054062/studyplace/competition/baichuan2fintune/competition_kit"
process_dir="$base_dir/process"
data_juicer_dir="$base_dir/data-juicer"
lm_training_dir="$base_dir/lm-training"
lm_evaluation_harness_dir="$base_dir/lm-evaluation-harness"

echo "Step 1: Finding the maximum folder number..."
# 找到最大的文件夹名字
max_num=0
cd "$process_dir"  # 进入 process_dir 目录
for dir in *; do
    if [[ -d $dir ]]; then  # 如果是目录
        # 检查是否为数字
        if [[ $dir =~ ^[0-9]+$ ]]; then
            if ((dir > max_num)); then
                max_num=$dir
            fi
        fi
    fi
done

echo "Step 2: Creating a new directory..."
# 计算新的文件夹名字
new_dir_num=$((max_num + 1))
new_process_dir="$process_dir/$new_dir_num"
# 在目标目录下创建新的文件夹
mkdir "$new_process_dir"

echo "Step 3: Modifying the config file..."
# 修改配置文件中的 dataset_path 和 export_path
sed -i "s|dataset_path:.*|dataset_path: '$new_process_dir/data_en_22.jsonl'|" $config_file
sed -i "s|export_path:.*|export_path: '$new_process_dir/data_en_31.jsonl'|" $config_file

echo "Step 4: Running predict.py..."
# 进入指定目录并执行python命令
cd "$data_juicer_dir/tools/quality_classifier"
python predict.py \
"/data/home/81054062/studyplace/competition/baichuan2fintune/competition_kit/data/raw_data/raw_data_en.jsonl" \
"$new_process_dir/data_en_21.jsonl"

echo "Step 5: Running filter.py..."
cd "$base_dir"  # 进入 base_dir 目录
# 运行 filter.py 文件
python "$base_dir/filter.py" \
"$new_process_dir/data_en_21.jsonl" \
"$new_process_dir/data_en_22.jsonl"

echo "Step 6: Running process_data.py..."
# 进入 data_juicer_dir 目录并运行 process_data.py
cd "$data_juicer_dir"
python tools/process_data.py --config "$config_file"

echo "Step 7: Running get_train_dataset_1b.py..."
# 进入 lm_training_dir 目录并运行 get_train_dataset_1b.py
cd "$lm_training_dir"
python get_train_dataset_1b.py  \
"$new_process_dir/data_en_31.jsonl" \
'' \
"$new_process_dir/data_en_32.jsonl"

echo "Step 8: Creating model directory..."
# 创建 model 文件夹
mkdir -p "$new_process_dir/model"

# PROCESS_IDS=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader,nounits)
# for ID in $PROCESS_IDS; do
#     kill -9 $ID
# done


echo "Step 9: Running deepspeed_train_1b.sh..."
# 进入 lm-training 目录并运行训练脚本
cd "$lm_training_dir"
sh train_scripts/deepspeed_train_1b.sh \
/data/home/81054062/studyplace/competition/baichuan2fintune/competition_kit/data/models/falcon-rw-1b   \
"$new_process_dir/data_en_32.jsonl" \
"$new_process_dir/model"

echo "Step 10: Creating submit directory..."
# 创建 submit 文件夹
mkdir -p "$new_process_dir/submit"



echo "Step 11: Running challenge-1B-stage1.sh..."
# 进入 lm-evaluation-harness 目录并运行评估脚本
cd "$lm_evaluation_harness_dir"
sh examples/challenge-1B-stage1.sh \
  board \
"$new_process_dir/model" \
/home/81054062/studyplace/competition/baichuan2fintune/competition_kit/data/challenge-data \
"$new_process_dir/submit"



echo "Step 12: Creating submit.zip..."
# 打包 submit 文件夹为 submit.zip
cd "$new_process_dir"
zip -r submit.zip submit

echo "All steps completed successfully!"

