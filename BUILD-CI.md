# 用 GitHub 打包（无需 Mac）

## 一、建仓库 + 推代码

1. GitHub 上新建一个**公开**仓库（比如叫 `wenkong120hz`）。
   - 必须公开：GitHub 免费 macOS runner 额度只对公开仓库开放（每月几千分钟，够个人用）。
2. 把本目录整个内容推上去（含隐藏目录 `.github`）：
   ```bash
   cd insulation-main
   git init
   git add -A            # 注意 -A 会把 .github/workflows/build.yml 带上
   git commit -m "build on GitHub Actions"
   git remote add origin https://github.com/<你的用户名>/wenkong120hz.git
   git branch -M main
   git push -u origin main
   ```
   （嫌命令行麻烦就在 GitHub 网页上直接 Upload files 也行，但记得 `.github` 这种隐藏目录网页上传不方便，命令行最稳）

## 二、触发构建

push 后打开仓库 → **Actions** 标签 → 「Build」工作流会自动跑（也可以手动点 Run workflow）。
流程：装 Theos → 装 Orion（theos/orion，vendor 进 Theos）→ `make spm` → `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`。
成功后 → 该次 run 的 **Artifacts** 里下载 `wenkong120hz-rootless`（里面是 .deb）。

## 三、装到机器上

1. 下载 artifact 里的 .deb。
2. 设备端要能装 `dev.theos.orion`（Orion Runtime）：
   - Sileo/Filza 加源 `https://repo.chariz.com`，装 **Orion Runtime**（iOS 14-16 选对应的包）；
   - 没装过的话这是所有 be-huge 插件（包括原版 insulation）的硬依赖。
3. 这个 CI 打出来的是 **rootless** 包。roothide 环境用之前按老规矩发给 Minis 转成隐根格式再装；
   rootless / Dopamine 环境直接装。

## 四、改了代码再打包

改完 push，Actions 自动重新构建，下载新 artifact 即可。
编译报错就把 Actions 日志（红字那段）发过来。
