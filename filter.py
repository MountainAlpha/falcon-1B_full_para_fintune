import json
import os
import glob
import sys
# input_path = "/data/home/81054062/studyplace/competition/baichuan2fintune/Baichuan2/fine-tune/data/data/raw_data/raw_data_en_processed.jsonl"  # 替换为你的JSON文件所在的文件夹路径
# output_path = "/data/home/81054062/studyplace/competition/baichuan2fintune/Baichuan2/fine-tune/data/data/raw_data/raw_data_en_processed_99.jsonl"  # 输出的JSONL文件名
# 检查是否提供了正确数量的参数
if len(sys.argv) != 3:
    print("使用方式: python script.py <input_path> <output_path>")
    sys.exit(1)

# 使用命令行参数
input_path = sys.argv[1]
output_path = sys.argv[2]

# 获取指定目录下的所有json文件
json_files = glob.glob(os.path.join(input_path, '*.json'))

# 存储转换后的数据
transformed_data = []
scores=[]
length=[]
for json_file in json_files:
    with open(json_file, 'r', encoding='utf-8') as f:
        # 逐行读取并加载json数据
        for line in f:
            data = json.loads(line)
            
            # 转换数据格式
            transformed_entry = {
                "meta": data["meta"],
                "text": data["text"],
                "input": data["input"],
                "output": data["output"],
                "instruction": data["instruction"]
            }
            
            # 将转换后的数据添加到列表中
            if data['doc_score']>0.99:
                transformed_data.append(transformed_entry)
                scores.append(data['doc_score'])
#                 length.append(data['__dj__stats__']['text_len'])
#将转换后的数据保存到jsonl文件
def flatten_dict(d, parent_key='', sep='_'):
    items = {}
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if isinstance(v, dict):
            items.update(flatten_dict(v, new_key, sep=sep))
        else:
            items[new_key] = v
    return items

def sort_key(item):
    flat_dict = flatten_dict(item)
    sorted_items = sorted(flat_dict.items())  # 排序是为了确保键和值的顺序是一致的
    return str(sorted_items)  # 转换为字符串以进行比较

transformed_data = sorted(transformed_data, key=sort_key)


with open(output_path, 'w', encoding='utf-8') as f:
    for entry in transformed_data:
        json.dump(entry, f, ensure_ascii=False)
        f.write('\n')

