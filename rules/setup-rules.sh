#!/bin/bash

# .cursor 项目规则配置 - 一键安装脚本
# =====================================
# 
# 使用方法：
#   一键安装命令：
#   bash <(curl -s https://raw.githubusercontent.com/lyfe2025/.cursor/main/rules/setup-rules.sh)
#   
# 或者：
#   curl -fsSL https://raw.githubusercontent.com/lyfe2025/.cursor/main/rules/setup-rules.sh | bash

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 分隔线
print_separator() {
    echo -e "${CYAN}=================================================${NC}"
}

# 显示欢迎信息
show_welcome() {
    clear
    print_separator
    echo -e "${CYAN}🚀 .cursor 项目规则配置 - 一键安装脚本${NC}"
    echo -e "${CYAN}   为你的项目自动配置 Cursor IDE 开发规则${NC}"
    print_separator
    echo ""
}

# 检查并安装Git
check_and_install_git() {
    log_step "检查Git环境..."
    
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version)
        log_success "Git已安装: $git_version"
        return 0
    fi
    
    log_warning "Git未安装，正在自动安装..."
    
    # 检测操作系统并安装Git
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            log_info "使用Homebrew安装Git..."
            brew install git
        else
            log_info "请手动安装Git或Homebrew"
            echo "  方法1: 安装Xcode命令行工具: xcode-select --install"
            echo "  方法2: 下载Git: https://git-scm.com/download/mac"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get >/dev/null 2>&1; then
            log_info "使用apt安装Git..."
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum >/dev/null 2>&1; then
            log_info "使用yum安装Git..."
            sudo yum install -y git
        elif command -v dnf >/dev/null 2>&1; then
            log_info "使用dnf安装Git..."
            sudo dnf install -y git
        elif command -v pacman >/dev/null 2>&1; then
            log_info "使用pacman安装Git..."
            sudo pacman -S --noconfirm git
        else
            log_error "无法自动安装Git，请手动安装"
            echo "  请访问: https://git-scm.com/download/linux"
            exit 1
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash/Cygwin)
        log_error "请手动安装Git for Windows"
        echo "  下载地址: https://git-scm.com/download/win"
        exit 1
    else
        log_error "未识别的操作系统，请手动安装Git"
        exit 1
    fi
    
    # 验证安装
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version)
        log_success "Git安装成功: $git_version"
    else
        log_error "Git安装失败"
        exit 1
    fi
}

# 初始化或检查当前项目Git仓库
init_or_check_git_repo() {
    log_step "检查当前项目Git状态..."
    
    if [ -d ".git" ]; then
        # 已经是Git仓库
        local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "no remote")
        
        log_success "当前目录已是Git仓库"
        log_info "分支: $current_branch"
        log_info "远程: $remote_url"
    else
        # 不是Git仓库，需要初始化
        log_info "当前目录不是Git仓库，正在初始化..."
        git init
        log_success "Git仓库初始化完成"
        
        # 创建初始提交（如果目录不为空）
        if [ "$(ls -A . 2>/dev/null)" ]; then
            echo "# $(basename "$(pwd)")" > README.md
            git add .
            git commit -m "Initial commit"
            log_info "已创建初始提交"
        fi
    fi
}

# 克隆.cursor配置项目
clone_cursor_config() {
    log_step "获取.cursor规则配置..."
    
    if [ -d ".cursor" ]; then
        log_info ".cursor目录已存在，检查内容..."
        if [ -f ".cursor/rules/common-rules.mdc" ]; then
            log_success ".cursor配置已存在且完整"
            return 0
        else
            log_warning ".cursor目录存在但不完整，重新获取..."
            rm -rf ".cursor"
        fi
    fi
    
    log_info "正在克隆.cursor规则配置项目..."
    if git clone https://github.com/lyfe2025/.cursor.git; then
        log_success ".cursor规则配置获取成功"
    else
        log_error ".cursor规则配置获取失败"
        log_info "请检查网络连接或手动克隆："
        echo "  git clone https://github.com/lyfe2025/.cursor.git"
        exit 1
    fi
    
    # 验证关键文件
    if [ ! -f ".cursor/rules/common-rules.mdc" ]; then
        log_error ".cursor配置不完整，缺少关键文件"
        exit 1
    fi
    
    log_success ".cursor配置验证通过"
}

# 显示当前项目信息
show_project_info() {
    log_step "当前项目信息..."
    
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "no remote")
    local last_commit=$(git log -1 --pretty=format:"%h %s" 2>/dev/null || echo "no commits")
    
    log_info "项目详情："
    echo "  📁 目录: $(pwd)"
    echo "  🌿 分支: $current_branch"
    echo "  🔗 远程: $remote_url"
    echo "  💾 最后提交: $last_commit"
    echo ""
}

# 检查是否为.cursor项目本身
check_cursor_project() {
    log_step "检查项目类型..."
    
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ "$remote_url" == *".cursor"* ]] || [[ "$remote_url" == *"lyfe2025/.cursor"* ]]; then
        log_error "检测到你当前在 .cursor 规则项目本身的目录中！"
        log_info "正确的使用方式："
        echo "  1. 进入你的目标项目目录: cd /path/to/your-project"
        echo "  2. 执行一键安装命令"
        echo ""
        exit 1
    fi
    
    log_success "项目类型检查通过"
}

# 验证.cursor配置完整性
verify_cursor_config() {
    log_step "验证.cursor配置完整性..."
    
    if [ ! -d ".cursor" ]; then
        log_error ".cursor 目录不存在！"
        exit 1
    fi
    
    if [ ! -f ".cursor/rules/common-rules.mdc" ]; then
        log_error ".cursor/rules/common-rules.mdc 文件不存在！"
        exit 1
    fi
    
    if [ ! -f ".cursor/rules/rule-file-management.mdc" ]; then
        log_error ".cursor/rules/rule-file-management.mdc 文件不存在！"
        exit 1
    fi
    
    log_success ".cursor 配置验证通过"
}

# 移除.cursor目录中的git信息和README.md文件
remove_cursor_git() {
    log_step "处理 .cursor 目录的版本控制..."
    
    if [ -d ".cursor/.git" ]; then
        log_info "移除 .cursor/.git 目录（转交版本控制权给你的项目）"
        rm -rf ".cursor/.git"
        log_success "已移除 .cursor/.git 目录"
    else
        log_info ".cursor/.git 目录不存在，跳过"
    fi
    
    # 删除README.md文件，避免影响用户项目根目录
    if [ -f "README.md" ] && [ -f ".cursor/rules/README.md" ]; then
        # 检查是否是.cursor项目的README.md（通过内容特征判断）
        if grep -q ".cursor 项目规则配置" README.md 2>/dev/null; then
            log_info "移除 .cursor 项目的 README.md 文件（避免影响用户项目）"
            rm -f "README.md"
            log_success "已移除项目根目录的 README.md"
        else
            log_info "检测到用户自己的 README.md，保留不删除"
        fi
    elif [ -f "README.md" ]; then
        # 只有根目录的README.md存在，检查是否为.cursor项目的
        if grep -q ".cursor 项目规则配置" README.md 2>/dev/null; then
            log_info "移除 .cursor 项目的 README.md 文件"
            rm -f "README.md"
            log_success "已移除项目根目录的 README.md"
        fi
    fi
}

# 创建标准项目目录结构
create_standard_directories() {
    log_step "创建标准项目目录结构..."
    
    local directories=(
        "logs"
        "scripts"
        "scripts/deployment"
        "scripts/tools"
        "scripts/database"
        "backups"
        "docs"
        "docs/架构文档"
        "docs/开发指南"
        "docs/部署运维"
        "docs/API文档"
        "docs/用户手册"
        "docs/项目管理"
        "docs/问题解决"
        "docs/团队协作"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
            
            # 为每个目录创建README.md文件
            local readme_file="$dir/README.md"
            if [ ! -f "$readme_file" ]; then
                case "$dir" in
                    "logs")
                        echo "# 项目日志目录

此目录用于存放项目相关的日志文件：
- 应用日志
- 错误日志  
- 访问日志
- 调试记录

## 注意事项
- 支持日志轮转和自动清理
- 日志格式保持统一
- 重要问题的调试记录要归档到此目录" > "$readme_file"
                        ;;
                    "scripts")
                        echo "# 项目脚本目录

此目录用于存放项目相关的脚本文件：
- deployment/ - 部署相关脚本
- tools/ - 工具脚本
- database/ - 数据库相关脚本

## 使用方式
通过根目录的 \`scripts.sh\` 交互式脚本来调用各种脚本功能。

## 脚本规范
- 每个脚本必须有清晰的注释和使用说明
- 按功能分类存放在对应子目录中" > "$readme_file"
                        ;;
                    "backups")
                        echo "# 项目备份目录

此目录用于存放项目备份文件：
- 按时间和类型分类存放
- 重要变更前的数据备份
- 配置文件备份

## 使用方式
- 通过 scripts.sh 调用自动备份脚本
- 支持自动备份和恢复功能" > "$readme_file"
                        ;;
                    "docs")
                        echo "# 项目文档目录

项目文档统一存放和管理目录。

## 文档分类
- **架构文档/** - 系统架构、技术选型、设计方案
- **开发指南/** - 开发规范、编码标准、最佳实践  
- **部署运维/** - 部署文档、运维手册、环境配置
- **API文档/** - 接口文档、数据格式、调用示例
- **用户手册/** - 使用指南、功能说明、常见问题
- **项目管理/** - 需求文档、测试计划、版本记录
- **问题解决/** - 故障排查、解决方案、经验总结
- **团队协作/** - 团队规范、工作流程、沟通机制

## 文档规范
- 支持多种格式（Markdown、PDF等）
- 优先使用Mermaid语法绘制图表
- 确保移动端友好和平台兼容性" > "$readme_file"
                        ;;
                    "docs/"*)
                        local dir_name=$(basename "$dir")
                        echo "# $dir_name

## 目录用途
此目录用于存放【$dir_name】相关的文档。

## 文档规范
- 使用Markdown格式编写文档
- 重要流程使用Mermaid图表展示
- 确保文档的及时更新和维护
- 新增文档请更新本README的索引

## 文档索引
<!-- 请在此处添加文档索引 -->
- 待补充..." > "$readme_file"
                        ;;
                    *)
                        if [[ "$dir" == scripts/* ]]; then
                            local script_type=$(basename "$dir")
                            echo "# $script_type 脚本目录

此目录用于存放 $script_type 相关的脚本文件。

## 脚本规范
- 每个脚本必须包含使用说明
- 添加适当的错误处理
- 确保跨平台兼容性
- 通过根目录的 scripts.sh 统一调用

## 脚本索引  
<!-- 请在此处添加脚本索引 -->
- 待补充..." > "$readme_file"
                        fi
                        ;;
                esac
            fi
        else
            log_info "目录已存在: $dir"
        fi
    done
    
    log_success "标准目录结构创建完成"
}

# 创建scripts.sh交互式脚本
create_scripts_entry() {
    log_step "创建 scripts.sh 交互式脚本入口..."
    
    if [ ! -f "scripts.sh" ]; then
        cat > scripts.sh << 'EOF'
#!/bin/bash

# 项目脚本交互式入口
# ===================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示主菜单
show_menu() {
    clear
    echo -e "${CYAN}🛠️  项目脚本管理中心${NC}"
    echo -e "${CYAN}========================${NC}"
    echo ""
    echo -e "${BLUE}请选择要执行的操作：${NC}"
    echo ""
    echo "  1) 部署相关脚本"
    echo "  2) 工具脚本"  
    echo "  3) 数据库脚本"
    echo "  4) 备份与恢复"
    echo "  5) 系统检查"
    echo "  0) 退出"
    echo ""
    echo -n -e "${YELLOW}请输入选项 [0-5]: ${NC}"
}

# 部署脚本菜单
deployment_menu() {
    clear
    echo -e "${PURPLE}🚀 部署相关脚本${NC}"
    echo -e "${PURPLE}===============${NC}"
    echo ""
    echo "  1) 开发环境部署"
    echo "  2) 测试环境部署"
    echo "  3) 生产环境部署" 
    echo "  4) 回滚部署"
    echo "  0) 返回主菜单"
    echo ""
    echo -n -e "${YELLOW}请输入选项 [0-4]: ${NC}"
}

# 工具脚本菜单
tools_menu() {
    clear
    echo -e "${GREEN}🔧 工具脚本${NC}"
    echo -e "${GREEN}==========${NC}"
    echo ""
    echo "  1) 代码格式化"
    echo "  2) 依赖检查"
    echo "  3) 性能分析"  
    echo "  4) 日志清理"
    echo "  0) 返回主菜单"
    echo ""
    echo -n -e "${YELLOW}请输入选项 [0-4]: ${NC}"
}

# 数据库脚本菜单
database_menu() {
    clear
    echo -e "${BLUE}💾 数据库脚本${NC}"
    echo -e "${BLUE}============${NC}"
    echo ""
    echo "  1) 数据备份"
    echo "  2) 数据恢复"
    echo "  3) 数据迁移"
    echo "  4) 数据库优化"
    echo "  0) 返回主菜单" 
    echo ""
    echo -n -e "${YELLOW}请输入选项 [0-4]: ${NC}"
}

# 备份恢复菜单
backup_menu() {
    clear
    echo -e "${CYAN}💼 备份与恢复${NC}"
    echo -e "${CYAN}============${NC}"
    echo ""
    echo "  1) 项目完整备份"
    echo "  2) 配置文件备份"
    echo "  3) 恢复备份"
    echo "  4) 清理旧备份"
    echo "  0) 返回主菜单"
    echo ""
    echo -n -e "${YELLOW}请输入选项 [0-4]: ${NC}"
}

# 系统检查
system_check() {
    clear
    echo -e "${GREEN}🔍 系统环境检查${NC}"
    echo -e "${GREEN}===============${NC}"
    echo ""
    
    echo -e "${BLUE}Node.js 版本:${NC}"
    node --version 2>/dev/null || echo "未安装"
    echo ""
    
    echo -e "${BLUE}Git 版本:${NC}"
    git --version 2>/dev/null || echo "未安装"
    echo ""
    
    echo -e "${BLUE}项目信息:${NC}"
    echo "目录: $(pwd)"
    if [ -f "package.json" ]; then
        echo "项目名: $(cat package.json | grep '"name"' | head -1 | cut -d'"' -f4)"
        echo "版本: $(cat package.json | grep '"version"' | head -1 | cut -d'"' -f4)"
    fi
    echo ""
    
    echo -e "${BLUE}磁盘空间:${NC}"
    df -h . | tail -1
    echo ""
    
    echo -n -e "${YELLOW}按任意键返回主菜单...${NC}"
    read -n 1
}

# 执行脚本的通用函数
execute_script() {
    local script_path="$1"
    local script_name="$2"
    
    if [ -f "$script_path" ]; then
        echo -e "${GREEN}执行: $script_name${NC}"
        bash "$script_path"
    else
        echo -e "${RED}脚本不存在: $script_path${NC}"
        echo -e "${YELLOW}你可以创建这个脚本来实现对应功能${NC}"
    fi
    
    echo ""
    echo -n -e "${YELLOW}按任意键继续...${NC}"
    read -n 1
}

# 主循环
main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                while true; do
                    deployment_menu
                    read deploy_choice
                    case $deploy_choice in
                        1) execute_script "scripts/deployment/dev-deploy.sh" "开发环境部署" ;;
                        2) execute_script "scripts/deployment/test-deploy.sh" "测试环境部署" ;;
                        3) execute_script "scripts/deployment/prod-deploy.sh" "生产环境部署" ;;
                        4) execute_script "scripts/deployment/rollback.sh" "回滚部署" ;;
                        0) break ;;
                        *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            2)
                while true; do
                    tools_menu
                    read tools_choice
                    case $tools_choice in
                        1) execute_script "scripts/tools/format-code.sh" "代码格式化" ;;
                        2) execute_script "scripts/tools/check-deps.sh" "依赖检查" ;;
                        3) execute_script "scripts/tools/performance.sh" "性能分析" ;;
                        4) execute_script "scripts/tools/clean-logs.sh" "日志清理" ;;
                        0) break ;;
                        *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            3)
                while true; do
                    database_menu  
                    read db_choice
                    case $db_choice in
                        1) execute_script "scripts/database/backup.sh" "数据备份" ;;
                        2) execute_script "scripts/database/restore.sh" "数据恢复" ;;
                        3) execute_script "scripts/database/migrate.sh" "数据迁移" ;;
                        4) execute_script "scripts/database/optimize.sh" "数据库优化" ;;
                        0) break ;;
                        *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            4)
                while true; do
                    backup_menu
                    read backup_choice
                    case $backup_choice in
                        1) execute_script "scripts/tools/full-backup.sh" "项目完整备份" ;;
                        2) execute_script "scripts/tools/config-backup.sh" "配置文件备份" ;;
                        3) execute_script "scripts/tools/restore-backup.sh" "恢复备份" ;;
                        4) execute_script "scripts/tools/clean-backups.sh" "清理旧备份" ;;
                        0) break ;;
                        *) echo -e "${RED}无效选项${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            5)
                system_check
                ;;
            0)
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 检查参数，支持直接调用特定功能
if [ $# -gt 0 ]; then
    case "$1" in
        "check") system_check; exit 0 ;;
        "help") 
            echo "用法: $0 [check|help]"
            echo "  check - 执行系统检查"
            echo "  help  - 显示此帮助"
            echo "  无参数 - 启动交互式菜单"
            exit 0
            ;;
    esac
fi

# 启动主程序
main
EOF
        chmod +x scripts.sh
        log_success "已创建 scripts.sh 交互式脚本入口"
    else
        log_info "scripts.sh 已存在，跳过创建"
    fi
}

# 检测技术栈
detect_tech_stack() {
    log_step "检测项目技术栈..."
    
    local tech_stack=()
    
    # 检测前端框架
    if [ -f "package.json" ]; then
        local package_content=$(cat package.json)
        
        if echo "$package_content" | grep -q '"react"'; then
            tech_stack+=("React")
        fi
        
        if echo "$package_content" | grep -q '"next"'; then
            tech_stack+=("Next.js")
        fi
        
        if echo "$package_content" | grep -q '"vue"'; then
            tech_stack+=("Vue.js")
        fi
        
        if echo "$package_content" | grep -q '"angular"'; then
            tech_stack+=("Angular")
        fi
        
        if echo "$package_content" | grep -q '"typescript"'; then
            tech_stack+=("TypeScript")
        fi
        
        log_info "检测到 Node.js 项目"
        tech_stack+=("Node.js")
    fi
    
    # 检测Python项目
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        log_info "检测到 Python 项目"
        tech_stack+=("Python")
    fi
    
    # 检测Java项目
    if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        log_info "检测到 Java 项目"
        tech_stack+=("Java")
    fi
    
    # 检测Go项目
    if [ -f "go.mod" ]; then
        log_info "检测到 Go 项目"
        tech_stack+=("Go")
    fi
    
    # 检测PHP项目
    if [ -f "composer.json" ]; then
        log_info "检测到 PHP 项目"
        tech_stack+=("PHP")
    fi
    
    # 检测Docker
    if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
        log_info "检测到 Docker 配置"
        tech_stack+=("Docker")
    fi
    
    if [ ${#tech_stack[@]} -eq 0 ]; then
        log_warning "未能自动检测到技术栈"
        log_info "Cursor AI 将在使用时自动识别并生成对应规则文件"
    else
        log_success "检测到技术栈: ${tech_stack[*]}"
        log_info "Cursor AI 将基于这些技术栈生成专用规则文件"
    fi
    
    echo ""
}

# 更新已存在的.gitignore文件（不创建新文件）
update_gitignore() {
    log_step "检查 .gitignore 配置..."
    
    # 只有在.gitignore文件已经存在时才进行更新
    if [ -f ".gitignore" ]; then
        # 检查是否已经包含.cursor相关配置
        if ! grep -q ".cursor" .gitignore; then
            echo "" >> .gitignore
            echo "# Cursor IDE 规则配置（可选：如果团队共享规则则注释掉下面的行）" >> .gitignore
            echo "# .cursor/" >> .gitignore
            log_success "已更新现有 .gitignore（.cursor 配置默认被提交到版本控制）"
            log_info "如果不希望提交 .cursor 配置，请取消注释 .gitignore 中的相关行"
        else
            log_info ".gitignore 已包含 .cursor 配置，跳过"
        fi
    else
        log_info "未发现 .gitignore 文件，跳过配置（.cursor 配置将正常提交到版本控制）"
    fi
}

# 显示完成信息和后续步骤
show_completion() {
    print_separator
    log_success "🎉 .cursor 项目规则配置安装完成！"
    print_separator
    echo ""
    
    echo -e "${CYAN}📋 安装摘要：${NC}"
    echo "  ✅ 移除了 .cursor 目录的版本控制"
    echo "  ✅ 清理了 .cursor 项目的 README.md（避免影响用户项目）"
    echo "  ✅ 创建了标准项目目录结构" 
    echo "  ✅ 生成了 scripts.sh 交互式脚本入口"
    echo "  ✅ 检测了项目技术栈"
    echo "  ✅ 检查了 .gitignore 配置（仅在文件已存在时更新）"
    echo ""
    
    echo -e "${YELLOW}🚀 后续步骤：${NC}"
    echo "  1. 重启 Cursor IDE 以应用新规则"
    echo "  2. Cursor AI 将自动识别技术栈并生成专用规则文件"
    echo "  3. 开始享受智能化的开发体验！"
    echo ""
    
    echo -e "${BLUE}💡 常用命令：${NC}"
    echo "  • 运行脚本管理: ${GREEN}./scripts.sh${NC}"
    echo "  • 系统检查: ${GREEN}./scripts.sh check${NC}"
    echo "  • 查看帮助: ${GREEN}./scripts.sh help${NC}"
    echo ""
    
    echo -e "${PURPLE}📚 规则文件位置：${NC}"
    echo "  • 通用规则: ${GREEN}.cursor/rules/common-rules.mdc${NC}"
    echo "  • 管理策略: ${GREEN}.cursor/rules/rule-file-management.mdc${NC}"
    echo "  • 项目文档: ${GREEN}README.md${NC} (项目根目录)"
    echo ""
    
    print_separator
}

# 主函数
main() {
    show_welcome
    
    # 执行安装步骤
    check_and_install_git           # 检查并安装Git
    init_or_check_git_repo          # 初始化或检查Git仓库
    check_cursor_project            # 检查是否在.cursor项目中
    clone_cursor_config             # 获取.cursor配置
    verify_cursor_config            # 验证配置完整性
    show_project_info               # 显示项目信息
    remove_cursor_git               # 移除.cursor/.git
    create_standard_directories     # 创建标准目录结构
    create_scripts_entry            # 创建脚本管理入口
    detect_tech_stack               # 检测技术栈
    update_gitignore                # 更新.gitignore
    
    # 显示完成信息
    show_completion
}

# 运行主函数
main "$@"