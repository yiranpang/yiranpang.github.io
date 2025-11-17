# Citation Updater Script - 使用示例

## 快速开始

```bash
# 更新所有文章的引用数
ruby bin/update_citations.rb
```

## 输出示例

```
============================================================
Google Scholar Citation Updater
============================================================

📚 Scholar ID: YOUR_SCHOLAR_ID
📁 Cache file: /path/to/_data/scholar_citations.yml

Found 5 article(s) to update

[1/5] Fetching u-x6o8ySG0sC... ✓ 42 citations
[2/5] Fetching d1gkVwhDpl0C... ✓ 128 citations
[3/5] Fetching abc123def456... ✓ 0 citations
[4/5] Fetching xyz789uvw012... ✓ (cached: 85)
[5/5] Fetching qwe456rty789... ❌ Error: Not found

💾 Cache file updated: _data/scholar_citations.yml

============================================================
Summary
============================================================
✓ Successfully updated: 3
❌ Failed: 1
📊 Total entries in cache: 5

✨ Done! Your citation cache has been updated.
   Run 'bundle exec jekyll serve' to see the changes.
```

## 命令选项

### 基本用法

```bash
# 只更新新文章（已缓存的文章会跳过）
ruby bin/update_citations.rb
```

### 强制更新

```bash
# 更新所有文章，包括已经缓存的
ruby bin/update_citations.rb --force

# 或使用简写
ruby bin/update_citations.rb -f
```

## 前置要求

### 1. 配置 Scholar ID

确保 `_data/socials.yml` 中配置了你的 Google Scholar user ID：

```yaml
scholar_userid: YOUR_SCHOLAR_ID
```

### 2. 配置 BibTeX

在 `_bibliography/papers.bib` 中，每个文献条目需要包含 `google_scholar_id` 字段：

```bibtex
@ARTICLE{example2023,
  author={Author Name},
  title={Paper Title},
  year={2023},
  google_scholar_id={u-x6o8ySG0sC},
  ...
}
```

**如何获取 google_scholar_id：**

访问你的 Google Scholar 个人主页，点击某篇文章，URL 格式如下：

```
https://scholar.google.com/citations?view_op=view_citation&user=YOUR_USER_ID&citation_for_view=YOUR_USER_ID:u-x6o8ySG0sC
```

其中 `u-x6o8ySG0sC` 就是该文章的 `google_scholar_id`。

## 工作原理

1. **读取配置**：从 `_data/socials.yml` 读取 Scholar ID
2. **解析 BibTeX**：从 `_bibliography/papers.bib` 提取所有 `google_scholar_id`
3. **加载缓存**：读取现有的 `_data/scholar_citations.yml`
4. **抓取数据**：逐个访问 Google Scholar 获取引用数
   - 自动添加 2-4 秒随机延迟
   - 使用浏览器 User-Agent
5. **保存结果**：更新 YAML 文件，创建备份

## 故障排查

### 错误：Could not find scholar_userid

**原因**：`_data/socials.yml` 中没有配置 Scholar ID

**解决**：在 `_data/socials.yml` 中添加：

```yaml
scholar_userid: YOUR_SCHOLAR_ID
```

### 警告：No article IDs found

**原因**：BibTeX 文件中没有 `google_scholar_id` 字段

**解决**：为每个文献条目添加 `google_scholar_id` 字段

### 错误：403 Forbidden 或被屏蔽

**原因**：请求过于频繁，被 Google Scholar 临时屏蔽

**解决**：

- 等待几分钟后重试
- 脚本已内置随机延迟，但大量文章时仍可能触发
- 考虑分批更新

### 某些文章显示 "Not found"

**原因**：

- Article ID 不正确
- 文章在 Google Scholar 上不可见
- 网络问题

**解决**：

- 检查 BibTeX 中的 `google_scholar_id` 是否正确
- 手动访问文章页面确认
- 可以手动编辑 `_data/scholar_citations.yml` 添加引用数

## 最佳实践

### 定期更新

建议设置定期任务（如每月）更新引用数：

```bash
# 添加到 crontab（每月1号凌晨3点执行）
0 3 1 * * cd /path/to/your/site && ruby bin/update_citations.rb
```

### 备份管理

脚本会自动创建 `scholar_citations.yml.backup` 备份文件。如需恢复：

```bash
cp _data/scholar_citations.yml.backup _data/scholar_citations.yml
```

### Git 管理

建议将更新的缓存文件提交到 Git：

```bash
git add _data/scholar_citations.yml
git commit -m "Update citation counts"
git push
```

### 混合使用

- 使用脚本批量更新大部分文章
- 对于抓取失败的文章，手动编辑 YAML 文件补充

## 文件说明

- **`bin/update_citations.rb`** - 更新脚本
- **`_data/scholar_citations.yml`** - 引用数缓存文件
- **`_data/scholar_citations.yml.backup`** - 自动备份文件
- **`_bibliography/papers.bib`** - BibTeX 文献库
- **`_data/socials.yml`** - 社交媒体配置文件（包含 Scholar ID）

## 性能提示

- **首次运行**：可能需要较长时间（取决于文章数量）
- **增量更新**：默认只更新新文章，速度较快
- **强制更新**：使用 `--force` 选项会更新所有文章
- **并发限制**：为避免被屏蔽，未实现并发抓取

## 进阶用法

### 只更新特定文章

手动编辑脚本或直接编辑 YAML 文件：

```bash
# 编辑 _data/scholar_citations.yml
vim _data/scholar_citations.yml

# 添加或修改引用数
u-x6o8ySG0sC: 150
```

### 查看详细日志

脚本已包含详细的进度和错误信息，无需额外配置。

### 自定义延迟

如果需要调整延迟时间，编辑 `bin/update_citations.rb`：

```ruby
# 将这行
sleep(rand(2.0..4.0))

# 改为自定义范围（单位：秒）
sleep(rand(3.0..6.0))
```
