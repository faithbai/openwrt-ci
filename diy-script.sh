#!/bin/bash

# --------------------------------------------------------------------
# 1. 基础修改 (保留默认设置 192.168.1.1 / root/root)
# --------------------------------------------------------------------
# 修改默认IP (注意: 保持注释，以保留默认的 192.168.1.1)
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh (如果不需要，保持注释)
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录 (如果不需要，保持注释)
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# --------------------------------------------------------------------
# 2. 移除冲突/不兼容的包
# --------------------------------------------------------------------
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns       # 移除旧的smartdns包，准备克隆新的git版
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan
# 移除旧的argon主题，确保克隆的是新版
rm -rf feeds/luci/themes/luci-theme-argon 

# Git稀疏克隆函数定义
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# --------------------------------------------------------------------
# 3. 添加需要的第三方插件 (精简版)
# --------------------------------------------------------------------

# 功能性插件
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server 
git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos

# 微信推送 (ServerChan替换)
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-serverchan

# ikoolproxy
git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy

# 保持注释：科学上网插件 (根据需要自行取消注释)
#git clone --depth=1 -b main https://github.com/fw876/helloworld package/luci-app-ssr-plus
#... (其他科学上网包保持注释)

# Themes (仅保留 Argon 和其配置)
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
# 其它主题保持移除/注释

# 更改 Argon 主题背景 (如果 $GITHUB_WORKSPACE 可用，否则删除此行)
cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 晶晨宝盒 (保留为注释，仅在 Amlogic 架构时取消注释)
#git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic

# --------------------------------------------------------------------
# 4. DNS 插件 (保留 SmartDNS)
# --------------------------------------------------------------------
# SmartDNS (保留)
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# msd_lite 和 MosDNS (关闭，因为您选择了 SmartDNS)
#git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
#git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite
#git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Alist (按需决定，保持注释)
# git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

# DDNS.to (保持注释，因为它依赖于特定的生态，除非您确认需要它)
#git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
#git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# iStore (保持注释)
#git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
#git_sparse_clone main https://github.com/linkease/istore luci

# 在线用户 (按需保留)
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# x86 型号只显示 CPU 型号 (如果不是x86架构可以删除)
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# 修改 Makefile (兼容性修复)
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

./scripts/feeds update -a
./scripts/feeds install -a
