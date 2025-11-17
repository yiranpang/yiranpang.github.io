# Google Scholar 引用数手动缓存使用说明

## 功能说明

当 Google Scholar 在线抓取失败时，系统会自动使用 `_data/scholar_citations.yml` 文件中手动维护的引用数作为备用数据源。

## 自动更新（推荐）

使用提供的脚本自动批量更新所有文章的引用数：

```bash
# 基本使用
ruby bin/update_citations.rb

# 强制更新所有文章（包括已缓存的）
ruby bin/update_citations.rb --force
```

脚本会：

1. 从 `_bibliography/papers.bib` 中自动提取所有文章的 `google_scholar_id`
2. 从 `_config.yml` 中读取你的 Google Scholar user ID
3. 逐个访问文章页面抓取最新引用数
4. 自动更新 `_data/scholar_citations.yml` 文件
5. 创建备份文件（`.backup`）以防数据丢失

**注意：**

- 确保你的 BibTeX 文件中包含 `google_scholar_id` 字段
- 脚本会自动添加随机延迟（2-4秒），避免被 Google Scholar 屏蔽
- 首次运行可能需要较长时间，取决于文章数量

## 手动更新

如果需要手动添加或修改引用数：

### 1. 找到文章的 Article ID

Article ID 可以从 Google Scholar 的文章页面 URL 中获取。例如：

```
https://scholar.google.com/citations?view_op=view_citation&hl=en&user=YOUR_USER_ID&citation_for_view=YOUR_USER_ID:u5HHmVD_uO8C
```

其中 `u5HHmVD_uO8C` 就是 article_id。

### 2. 获取引用数

访问对应的 Google Scholar 文章页面，查看 "Cited by XXX" 的数字。

### 3. 更新缓存文件

编辑 `_data/scholar_citations.yml` 文件，按照以下格式添加或更新引用数：

```yaml
# 手动维护的 Google Scholar 引用数缓存
# 格式: article_id: citation_count

u5HHmVD_uO8C: 150
9yKSN-GCB0IC: 45
IjCSPb-OGe4C: 1200
```

**注意：**

- 直接填写数字即可，不需要添加 K、M 等单位
- 系统会自动将大数字格式化（如 1200 会显示为 1.2K）
- 确保 article_id 和引用数之间用冒号加空格分隔

### 4. 测试

提交更改后，重新构建网站：

```bash
bundle exec jekyll serve
```

查看日志输出，应该能看到：

```
Loaded manual citations cache with X entries
```

如果某个文章的在线抓取失败，日志会显示：

```
Using manual citation count for [article_id]: [count] (from cache)
```

## 工作原理

1. 系统首先尝试从 Google Scholar 在线抓取引用数
2. 如果抓取成功，使用在线数据
3. 如果抓取失败（返回异常）：
   - 检查 `_data/scholar_citations.yml` 中是否有该 article_id 的缓存
   - 如果有缓存，使用缓存的引用数
   - 如果没有缓存，显示 "N/A"

## 维护建议

- 定期（如每月）手动更新引用数，保持数据的时效性
- 优先更新重要文章的引用数
- 在 Git 中提交 `_data/scholar_citations.yml` 文件，确保部署时能使用这些数据

## 故障排查

如果缓存不生效：

1. 检查 `_data/scholar_citations.yml` 文件格式是否正确（YAML 语法）
2. 检查 article_id 是否准确
3. 查看 Jekyll 构建日志，确认是否正确加载了缓存文件
4. 确保引用数是纯数字，不包含逗号或其他字符
