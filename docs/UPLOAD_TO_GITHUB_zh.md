# 上传到 GitHub 与连接个人网站

建议仓库名：`ISPY2-Bayesian-Treatment-Response`。下面的地址是创建仓库后的预期地址，目前并不代表仓库已发布。

1. 解压 ZIP，进入最里面包含 `README.md` 的目录。
2. 在 GitHub 新建 `ISPY2-Bayesian-Treatment-Response` 仓库。网页上传时选择 **Add file → Upload files**，
   拖入该目录内的文件及文件夹；不要直接上传整个 ZIP，也不要多套一层同名目录。
3. 提交后确认仓库首页能显示 README，并能打开报告和代码。
4. 原始患者数据仅放在本机。此上传包未包含这些数据；不要再把它们加入网页上传列表。

如使用 Git，可在解压后的仓库根目录执行（先在 GitHub 创建空仓库）：

```bash
git init
git add .
git commit -m "Prepare portfolio project"
git branch -M main
git remote add origin https://github.com/jengithubb/ISPY2-Bayesian-Treatment-Response.git
git push -u origin main
```

网站按钮建议：

| 按钮 | 链接 |
|---|---|
| View Code | `https://github.com/jengithubb/ISPY2-Bayesian-Treatment-Response` |
| Read Report | `https://github.com/jengithubb/ISPY2-Bayesian-Treatment-Response/blob/main/reports/bayesian-treatment-response-report.pdf` |

`View Code` 先链接仓库首页，读者能先看到项目说明，再打开 `scripts/run_analysis.R`。
`Read Report` 直接链接 PDF。若默认分支叫 `master`，把报告地址中的 `main` 改为 `master`。
不需要额外增加简历下载按钮。

如继续使用现有 BloodMNIST 仓库，也可以直接更新该仓库，并把按钮链接改为它的实际地址。
本包不自动修改网站、不创建远程仓库；上述链接应在上传完成后再用于网站。
