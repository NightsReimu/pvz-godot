# 媒体素材与第三方内容声明

## 适用范围

根目录 [LICENSE](LICENSE) 中的 MIT License 仅适用于本项目原创源代码。仓库中的媒体素材、角色、名称、音乐、字体和第三方知识产权 **not covered by the MIT License**，除非对应文件旁另有明确的许可文件。

本声明主要覆盖：

- `art/` 中的 PNG、SVG、Boss 动画帧、UI、字体和生成式素材。
- `audio/` 中的背景音乐与音效。
- 以 Plants vs. Zombies、Touhou Project 或其他第三方作品为基础的名称、角色、设定和视觉元素。
- 仓库内未由 MIT 源码许可明确涵盖的其他媒体文件。

克隆、Fork 或下载本仓库，不代表获得上述内容的所有权、商业使用权或再许可权。不要把本仓库当作可自由取用的素材库。

## 东方 Project 二次创作素材

东方 Boss 角色图、动画帧、场景元素和相关表现属于基于 **Touhou Project** 的同人/二次创作内容。其使用应遵循上海爱丽丝幻乐团发布的 [Touhou Project derivative-work guidelines](https://touhou-project.news/guidelines_en/)，同时尊重每个具体素材作者、生成者和后处理贡献者保留的权利。

官方二创规则并不意味着所有第三方同人图片都具有相同许可，也不自动允许将原作素材重新打包。计划复用某一张图或某组 Boss 帧时，仍需核对该文件的具体来源、作者和授权。当前仓库的部分历史素材来源记录不完整，在完成来源审计前不得视为可独立再分发素材。

## 东方原曲与其他音乐

仓库 `audio/` 中包含来自东方原作的音乐。对于这些 **original Touhou music**，本仓库目前 **no verified redistribution license**，也没有权利将它们纳入 MIT License、公共领域或“免版权音乐”。音乐来源于互联网并不能构成复制、上传、镜像、再发行或商业使用的授权。

因此：

1. 源码可以依照 MIT License 阅读、修改和再分发，但该许可不延伸到这些音乐文件。
2. 任何准备公开发行、建立镜像、制作衍生版本或在应用商店分发的人，都应先从相关权利人取得明确许可，或者 **replace the music** with tracks that have a documented redistribution license.
3. 贡献者不得再提交来源不明、从流媒体或下载站提取、或仅以“网上可找到”为依据的音乐。
4. 删除或替换音乐时，应同步更新 `scripts/data`、Boss BGM 路由、导入文件和对应测试，避免运行时引用缺失。

战斗音效和其他非东方音乐也不自动获得统一许可；应按文件逐项核对来源。后续将通过第三方素材清单记录作者、来源、许可和替换状态。

## 字体、生成图与其他媒体

- 字体的版权与许可归字体作者或发行方所有。即使字体可免费使用，也不等于受本项目 MIT License 覆盖。
- Image2 或其他生成工具产生的素材应保留生成记录，并继续接受商标、角色权利、训练服务条款和人工后处理来源审查。
- Plants vs. Zombies 相关名称、角色与概念归其各自权利人所有，本项目无权对其授予许可。
- 未附独立许可或来源记录的媒体文件，默认不得从项目中拆出后单独使用或再发布。

## 项目性质

这是非官方、非商业的同人项目，不代表上海爱丽丝幻乐团、Plants vs. Zombies 的权利人或任何素材作者，也不暗示得到他们的授权、认可或背书。

项目维护者会尽力遵守二次创作规则并改善素材来源记录，但本声明不是法律意见。下游使用者必须根据自己的地区、用途和发行平台独立完成权利审核。

## 贡献与权利问题

提交媒体素材的贡献者必须在 Pull Request 中说明：

- 文件作者和原始来源。
- 允许修改和再分发的许可或书面授权。
- 是否使用生成式工具，以及生成和后处理方式。
- 必须保留的署名、通知或使用限制。

如你是权利人或发现某个文件存在归属、署名或授权问题，请在 [NightsReimu/pvz-godot Issues](https://github.com/NightsReimu/pvz-godot/issues) 中提供文件路径和权利依据。维护者将优先停止分发、移除或替换争议内容。

## English Notice

The MIT License applies to original source code only. Media assets are excluded. Touhou Project character art and boss assets are derivative fan works and remain subject to the official fan-content guidelines and any creator-specific terms. Original Touhou music bundled in this repository has no verified redistribution license; obtain permission or replace it before publishing a mirror, release, or derivative distribution. All third-party names, characters, music, and artwork remain the property of their respective rights holders.
