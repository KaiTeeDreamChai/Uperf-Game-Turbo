#!/system/bin/sh
#
# Uperf-Game-Turbo 专属低电量监控守护进程 (一加13T / sdm8e 定制版)
# 每 180 秒（3分钟）检测一次系统电量，仅在状态变化时写入与通知
#

BASEDIR="$(dirname $(readlink -f "$0"))"
. "$BASEDIR/pathinfo.sh"
. "$BASEDIR/libcommon.sh"

notify_user() {
    local title="$1"
    local text="$2"
    # 发送系统横幅通知
    cmd notification post -S bigtext -t "$title" "uperf_battery" "$text" 2>/dev/null
    # 记录系统日志
    log -t "Uperf-Battery" "$title: $text" 2>/dev/null
}

get_battery_level() {
    local val=""
    if [ -f /sys/class/power_supply/battery/capacity ]; then
        val="$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)"
    fi
    if [ -z "$val" ]; then
        val="$(dumpsys battery 2>/dev/null | grep '  level:' | head -n1 | tr -d ' ' | cut -d: -f2)"
    fi
    echo "$val"
}

is_power_connected() {
    # 检查是否连接电源或处于充电状态
    if dumpsys battery 2>/dev/null | grep -iE 'powered: true|status: 2' >/dev/null 2>&1; then
        echo "1"
    else
        echo "0"
    fi
}

# 等待开机并解密 /sdcard
wait_until_login
sleep 15

# 状态记录: 0=正常智能调度(auto), 1=低电量锁定省电(powersave)
locked_powersave=0

while true; do
    level="$(get_battery_level)"
    charging="$(is_power_connected)"

    if [ -n "$level" ] && [ "$level" -gt 0 ] 2>/dev/null; then
        if [ "$level" -le 20 ] && [ "$charging" != "1" ]; then
            # 条件满足: 电量 <= 20% 且未接电源
            if [ "$locked_powersave" -eq 0 ]; then
                echo "powersave" > "$USER_PATH/cur_powermode.txt"
                locked_powersave=1
                notify_user "Uperf 智能调度" "🔋 电量不足20%（当前${level}%），已锁定省电模式"
            fi
        else
            # 条件满足: 接入充电器 或 电量回升 > 20%
            if [ "$locked_powersave" -eq 1 ]; then
                echo "auto" > "$USER_PATH/cur_powermode.txt"
                locked_powersave=0
                notify_user "Uperf 智能调度" "⚡ 接入电源/电量恢复（当前${level}%），已恢复智能调度"
            fi
        fi
    fi

    # 间隔 3 分钟 (180 秒) 轮询一次
    sleep 180
done
