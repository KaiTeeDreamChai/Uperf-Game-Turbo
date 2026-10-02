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

install_corp() {
    if [ -d "/data/adb/modules/unity_affinity_opt" ] || [ -d "/data/adb/modules_update/unity_affinity_opt" ]; then
        rm -rf /data/adb/modules*/unity_affinity_opt
    fi
    CUR_ASOPT_VERSIONCODE="$(get_value ASOPT_VERSIONCODE "$MODULE_PATH"/module.prop)"
    asopt_module_version="0"
    if [ -f "/data/adb/modules/asoul_affinity_opt/module.prop" ]; then
        asopt_module_version="$(get_value versionCode /data/adb/modules/asoul_affinity_opt/module.prop)"
        echo "- AsoulOpt 当前版本: $asopt_module_version, 内置版本: $CUR_ASOPT_VERSIONCODE"
        if [ "$CUR_ASOPT_VERSIONCODE" -gt "$asopt_module_version" ]; then
            echo "* 正在将 A-SOUL 线程放置模块更新至最新版本..."
            killall -9 AsoulOpt 2>/dev/null
            rm -rf /data/adb/modules*/asoul_affinity_opt
            if [ -x "$(command -v magisk)" ]; then
                magisk --install-module "$MODULE_PATH"/modules/asoulopt.zip
            elif [ -x "/data/adb/ksu/bin/ksud" ]; then
                /data/adb/ksu/bin/ksud module install "$MODULE_PATH"/modules/asoulopt.zip
            fi
        else
            echo "* A-SOUL 线程放置模块已是最新版本，无需重复安装"
        fi
    else
        echo "* 正在静默安装 A-SOUL 游戏线程放置优化模块..."
        killall -9 AsoulOpt 2>/dev/null
        rm -rf /data/adb/modules*/asoul_affinity_opt
        if [ -x "$(command -v magisk)" ]; then
            magisk --install-module "$MODULE_PATH"/modules/asoulopt.zip
        elif [ -x "/data/adb/ksu/bin/ksud" ]; then
            /data/adb/ksu/bin/ksud module install "$MODULE_PATH"/modules/asoulopt.zip
        fi
    fi
    rm -rf "$MODULE_PATH"/modules/asoulopt.zip
}

fix_module_prop() {
    mkdir -p /data/adb/modules/uperf/
    cp -f "$MODULE_PATH/module.prop" /data/adb/modules/uperf/module.prop
}

echo "====================================================="
echo "  Uperf Game Turbo (sdm8e 一加13T 专属定制版)"
echo "  基准: Uperf Game Turbo 1.51 + EAS 2+6 Oryon 能量模型"
echo "  优化: 触屏响应 2.0s | 三级分档调度 | 熄屏省电 | 纯净精简"
echo "====================================================="

install_uperf
fix_module_prop
install_corp

echo "- 安装与初始化完成！重启手机后自动生效。"
