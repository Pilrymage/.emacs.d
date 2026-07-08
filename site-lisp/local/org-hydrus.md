模仿 Obsidian 的 Hydrus 支持，为 Emacs 制作一个在 Org Mode 里的相应功能。
像 Obsidian 的 Hydrus 插件，其底层绝不仅仅是拼接一个大图 URL，它高度依赖 Hydrus Client API 的 **`/get_files/file_metadata`** 接口。
Hydrus 本地 API 文档：file:///D:/Hydrus%20Network/lib/help/client_api.html

---

### 一、 插件从 Hydrus API 中获取了什么？

当向接口发送一个图片的哈希值时，Hydrus 返回的不是二进制文件，而是一个内容极度丰富的 **JSON 结构体**。它主要包含以下四个维度的元数据：

#### 1. 完整的标签树（Tags）

* **API 返回**：一个包含所有标签服务的嵌套对象（形如 `{"my tags": ["meme:沙雕", "creator:wlop"], "downloader tags": [...]}`）。
* **笔记用途**：
* **标签同步**：自动将这些标签转化为笔记内的标签（Obsidian 转化为 `#meme/沙雕`）。
* **在 Emacs 中对应的 Org 玩法**：你可以将它们自动解析并写入当前 headline 的 `:PROPERTIES:` 属性里，或者直接转化为文件头部的 `#+filetags:`。



#### 2. 原始来源网址（URLs）

* **API 返回**：一个字符串数组（如 `["[https://pixiv.net/artworks/12345](https://pixiv.net/artworks/12345)", "[https://twitter.com/](https://twitter.com/)..."]`）。
* **笔记用途**：
* **一键溯源**：在图片下方自动生成一个“由 Hydrus 自动提供”的原文链接，点击直接跳转回当初下载这张图的网页。
* **在 Emacs 中对应的 Org 玩法**：直接转化为标准的 Org 链接 `[[[https://pixiv.net/](https://pixiv.net/)...][Pixiv 原作地址]]`。



#### 3. 文件笔记（Notes）

* **API 返回**：我们在上一轮讨论中提到过的自定义笔记（如你在导入时自动保留的原始文件名 `"early foundation of christian theology"`）。
* **笔记用途**：
* **文本上下文补全**：直接将这段有意义的文件名作为图片的 Caption（题注）插入到笔记中。
* **在 Emacs 中对应的 Org 玩法**：自动生成为 `#+caption: early foundation of christian theology`。



#### 4. 媒体物理属性（Width, Height, Mime）

* **API 返回**：图片的宽高像素、文件大小以及 `image/webp` 等格式信息。
* **笔记用途**：
* **智能排版**：如果检测到图片极其狭长（如长截图），插件可以自动在渲染时限制其显示宽度。



---

### 二、 为 Emacs / Org-mode 度身定制的插件设计蓝图

由于 Emacs 本身只是个文本编辑器，如果你直接在文档里写死 `[http://127.0.0.1:45869/](http://127.0.0.1:45869/)...` 这一长串 API 网址，会显得 Org 文档非常臃肿且极不优雅。

你可以利用 Emacs 的 **自定义链接类型（Custom Link Types）**，来实现比 Obsidian 更硬核、更纯粹的体验：

#### 1. 核心设想：定义一个 `hydrus:` 协议链接

在 Emacs 中，你可以注册一个自定义链接，让你的 Org 文档里只需要写：

```org
[[hydrus:fd621808b8e9e...c74][可选的图片描述]]
```

它极其干净，仅仅保留了哈希值。
因为每张图片唯一对应一个哈希值，在 Hydrus 中使用哈希值寻找文件是恰当的。

#### 2. 编写 Elisp 来控制它的行为

通过 `(org-link-set-parameters "hydrus" ...)`，你可以定义当 Emacs 遇到这个链接时的三种行为：

* **行为 A：在文档内预览（Toggle Inline Images）**
当你按下 `M-x org-toggle-inline-images` 时，编写的 Elisp 函数拦截这个链接，在后台用 `url-retrieve`（或 `request.el`）拼接带有 `auth_key` 的 API 地址，把图片下载到 Emacs 的缓存里，然后**直接在 Org 缓冲区内将图片渲染出来**。
* **行为 B：点击跳转（Follow）**
当你的光标在这个链接上敲击 `C-c C-o`（打开链接）时，触发一个自定义函数，直接调用外部浏览器打开对应的 `[http://127.0.0.1...](http://127.0.0.1...)` 地址，或者弹出一个临时的 `*Hydrus Metadata*` 缓冲区，把上面提到的 **Tags, URLs, Notes** 用完美的 Org 语法排版展示出来。
* **行为 C：导出兼容（Export）**
当你把 Org 导出为 HTML 或 PDF 时，导出引擎会自动把 `hydrus:hash` 动态替换为标准的本地 API 图片 URL，让导出的网页也能完美显示图片。

#### 3. 互动联动：配合 `completing-read` 选图

Obsidian 插件还有一个极佳的体验是：在笔记里敲关键词，能直接搜索 Hydrus 里的图并插入。
在 Emacs 里，你可以调用 Hydrus 的 `/get_files/search_files` 接口。结合 **Vertico / Ivy / Helm** 等补全框架：

1. 你在 Emacs 里输入 `M-x my-hydrus-insert-image`。
2. 提示输入标签，你输入 `meme:沙雕`。
3. Emacs 在后台向 Hydrus 索要匹配的图片哈希列表，并把它们的缩略图或 Notes 作为候选项。
4. 你选中一项，回车，完美的 `[[hydrus:hash]]` 链接就自动插入到了你当前的光标所在处。

---

### 💡 结语

开发这样一个 Emacs 插件，技术栈只需要标准的 `json-read`（解析元数据）、`url-retrieve`（异步请求）以及 `org-link-set-parameters`。由于你之前已经把原始文件名作为标签/笔记存进了 Hydrus，一旦你的 Emacs 能够通过哈希读取这些元数据，你的 Org-mode 将会进化成一个全知全能的超级知识网。