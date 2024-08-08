#!/bin/bash

# 提示用户输入音频文件名
echo "请输入音频文件的完整路径："
read input_file

# 检查输入是否为空
if [ -z "$input_file" ]; then
    echo "输入的文件路径为空，请重新输入。"
    exit 1
fi

# 获取输入文件的目录路径和基本文件名（不含扩展名）
input_dir=$(dirname "$input_file")
filename_noext=$(basename "$input_file" .m4a) # 去掉.m4a扩展名

# 每段音频的时长（单位：秒）
segment_length=255

# 确保文件存在
if [ ! -f "$input_file" ]; then
    echo "错误：文件不存在，请检查路径。"
    exit 1
fi

# 使用 ffprobe 获取音频的总时长（转换为秒）
total_duration=$(ffprobe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

# 使用 bc 来计算需要的段数和剩余时长
full_segments=$(echo "scale=0; $total_duration / $segment_length" | bc)
remaining_duration=$(echo "scale=0; $total_duration % $segment_length" | bc)

# 确保不会使用0秒作为起始时间
start_time=0

# 循环分割音频
for ((i=1; i<=full_segments; i++)); do
    # 构造输出文件名（原文件名+part(i).扩展名）
    output_file="${input_dir}/${filename_noext}_part${i}.m4a"
    
    # 使用 FFmpeg 分割音频
    ffmpeg -i "$input_file" -ss "$start_time" -t "$segment_length" -c copy "$output_file"
    
    # 更新下一个片段的起始时间
    start_time=$(echo "$start_time + $segment_length" | bc)
done

# 如果剩余时长大于0，分割最后一个部分
if [ "$remaining_duration" -gt 0 ]; then
    # 构造输出文件名（原文件名+remaining.扩展名）
    output_file="${input_dir}/${filename_noext}_remaining.m4a"
    
    # 使用 FFmpeg 分割剩余部分
    ffmpeg -i "$input_file" -ss "$start_time" -c copy "$output_file"
fi

echo "音频分割完成。"