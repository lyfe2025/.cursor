#!/bin/bash

# 🔍 规则文件自动验证脚本
# 用途: 确保所有规则文件格式和内容的一致性

echo "🚀 开始规则文件验证..."
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
total_files=0
passed_files=0
failed_files=0

# 检查函数
check_file_size() {
    local file=$1
    local lines=$(wc -l < "$file")
    local filename=$(basename "$file")
    
    if [ "$lines" -gt 500 ]; then
        echo -e "${RED}❌ $filename 超过500行限制 ($lines 行)${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $filename 符合大小要求 ($lines 行)${NC}"
        return 0
    fi
}

check_yaml_format() {
    local file=$1
    local filename=$(basename "$file")
    
    if head -3 "$file" | grep -q "alwaysApply:"; then
        echo -e "${GREEN}✅ $filename YAML格式正确${NC}"
        return 0
    else
        echo -e "${RED}❌ $filename YAML格式错误${NC}"
        return 1
    fi
}

check_title_format() {
    local file=$1
    local filename=$(basename "$file")
    
    # 检查是否有正确的一级标题
    if sed -n '4,6p' "$file" | grep -q "^# "; then
        echo -e "${GREEN}✅ $filename 标题格式正确${NC}"
        return 0
    else
        echo -e "${RED}❌ $filename 标题格式错误${NC}"
        return 1
    fi
}

# 主验证循环
echo "🔍 检查所有 .mdc 文件..."
echo ""

for file in rules/*.mdc; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "📄 验证文件: $filename"
        echo "----------------------------"
        
        total_files=$((total_files + 1))
        file_passed=true
        
        # 检查文件大小
        if ! check_file_size "$file"; then
            file_passed=false
        fi
        
        # 检查YAML格式
        if ! check_yaml_format "$file"; then
            file_passed=false
        fi
        
        # 检查标题格式
        if ! check_title_format "$file"; then
            file_passed=false
        fi
        
        # 统计结果
        if [ "$file_passed" = true ]; then
            passed_files=$((passed_files + 1))
            echo -e "${GREEN}✅ $filename 验证通过${NC}"
        else
            failed_files=$((failed_files + 1))
            echo -e "${RED}❌ $filename 验证失败${NC}"
        fi
        
        echo ""
    fi
done

# 生成验证摘要
echo "=========================="
echo "🎯 验证摘要报告"
echo "=========================="
echo "📊 总文件数: $total_files"
echo -e "${GREEN}✅ 通过验证: $passed_files${NC}"
echo -e "${RED}❌ 验证失败: $failed_files${NC}"

# 计算通过率
if [ "$total_files" -gt 0 ]; then
    pass_rate=$(( (passed_files * 100) / total_files ))
    echo "📈 通过率: $pass_rate%"
    
    if [ "$pass_rate" -ge 90 ]; then
        echo -e "${GREEN}🎉 规则文件质量优秀！${NC}"
        exit 0
    elif [ "$pass_rate" -ge 70 ]; then
        echo -e "${YELLOW}⚠️ 规则文件质量良好，建议改进${NC}"
        exit 1
    else
        echo -e "${RED}🚨 规则文件质量需要改进${NC}"
        exit 2
    fi
else
    echo -e "${RED}🚨 未找到规则文件${NC}"
    exit 3
fi