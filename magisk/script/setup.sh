#!/system/bin/sh
#
# Copyright (C) 2021-2022 Matt Yang & yinwanxi
# Customized for OnePlus 13T (sdm8e / SM8750) by KaiTeeDreamChai
#

BASEDIR="$(dirname $(readlink -f "$0"))"
. "$BASEDIR/pathinfo.sh"

abort() {
    echo "$1"
    echo "! Uperf Game Turbo (sdm8e Custom) 安装失败。"
    exit 1
}

set_perm() {
    chown $2:$3 "$1"
    chmod $4 "$1"
    chcon $5 "$1"
}

set_perm_recursive() {
    find "$1" -type d 2>/dev/null | while read dir; do
        set_perm "$dir" $2 $3 $4 $6
    done
    find "$1" -type f -o -type l 2>/dev/null | while read file; do
        set_perm "$file" $2 $3 $5 $6
    done
}

get_value() {
   echo "$(grep -E "^$1=" "$2" | head -n 1 | cut -d= -f2)"
}

install_uperf() {
    echo "- 目标平台: 骁龙8至尊版 Snapdragon 8 Elite (sdm8e / SM8750)"
    echo "- 部署专属 EAS+ContextScheduler 调度配置与分应用策略..."
    mkdir -p "$USER_PATH"
    
    # 备份既有配置
    [ -f "$USER_PATH/uperf.json" ] && mv -f "$USER_PATH/uperf.json" "$USER_PATH/uperf.json.bak"
    [ -f "$USER_PATH/perapp_powermode.txt" ] && mv -f "$USER_PATH/perapp_powermode.txt" "$USER_PATH/perapp_powermode.txt.bak"
    
    # 写入专属定制配置
    cp -f "$MODULE_PATH/config/sdm8e.json" "$USER_PATH/uperf.json"
    cp -f "$MODULE_PATH/config/perapp_powermode.txt" "$USER_PATH/perapp_powermode.txt"
    echo "auto" > "$USER_PATH/cur_powermode.txt"
    
    set_perm_recursive "$BIN_PATH" 0 0 0755 0755 u:object_r:system_file:s0
    set_perm_recursive "$MODULE_PATH/script" 0 0 0755 0755 u:object_r:system_file:s0
    echo "- 核心调度文件与策略配置部署完成"
}

check_compatibility() {
    # 清理历史冲突模块残留
    if [ -d "/data/adb/modules/unity_affinity_opt" ] || [ -d "/data/adb/modules_update/unity_affinity_opt" ]; then
        rm -rf /data/adb/modules*/unity_affinity_opt
    fi

    # 针对 AsoulOpt 模块在特定 ROM 下死机重启的兼容性警示
    if [ -d "/data/adb/modules/asoul_affinity_opt" ] || [ -d "/data/adb/modules_update/asoul_affinity_opt" ]; then
        echo "-----------------------------------------------------"
        echo "! [兼容性提示] 检测到已安装 A-SOUL 优化模块 (asoul_affinity_opt)"
        echo "! 在一加 13T（骁龙8至尊版）某些特定 ROM（如 crDroid 17.0 等）下："
        echo "! AsoulOpt 锁定 core_ctl 会干扰 CPU 息屏睡眠，易导致黑屏死机、发热与重启！"
        echo "! 本版本 (1.51.2) 已彻底剥离内置 AsoulOpt；若遇到息屏假死，建议停用该模块。"
        echo "-----------------------------------------------------"
    fi
}

fix_module_prop() {
    mkdir -p /data/adb/modules/uperf/
    cp -f "$MODULE_PATH/module.prop" /data/adb/modules/uperf/module.prop
}

echo "====================================================="
echo "  Uperf Game Turbo (sdm8e 一加13T 专属定制版 v1.51.2)"
echo "  基准: Uperf Game Turbo 1.51 + EAS 2+6 Oryon 能量模型"
echo "  优化: 触屏响应 2.0s | 三级分档调度 | 熄屏省电 | 纯净无AsoulOpt"
echo "====================================================="

install_uperf
fix_module_prop
check_compatibility

echo "- 安装与初始化完成！重启手机后自动生效。"
