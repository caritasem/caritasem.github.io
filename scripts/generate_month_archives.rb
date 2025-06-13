require 'fileutils'
require 'yaml'

POSTS_DIR = "_posts"
ARCHIVE_DIR = "."

# 获取所有文章的年月
months = Dir.glob("#{POSTS_DIR}/*.md").map do |file|
  if File.basename(file) =~ /^(\d{4})-(\d{2})-\d{2}-/
    [$1, $2]
  end
end.compact.uniq

months.each do |year, month|
  dir = File.join(ARCHIVE_DIR, year, month)
  FileUtils.mkdir_p(dir)
  index_md = File.join(dir, "index.md")
  next if File.exist?(index_md) # 已存在则跳过

  File.open(index_md, "w") do |f|
    f.puts <<~MARKDOWN
      ---
      title: "#{year}年#{month}月文章归档"
      permalink: /#{year}/#{month}/
      ---

      {% for post in posts %}
        {% assign y = post.date | date: "%Y" %}
        {% assign m = post.date | date: "%m" %}
        {% if y == '#{year}' and m == '#{month}' %}
        - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
        {% endif %}
      {% endfor %}

    MARKDOWN
  end
  puts "Generated #{index_md}"
end


# 获取所有文章的年
years = Dir.glob("#{POSTS_DIR}/*.md").map do |file|
  if File.basename(file) =~ /^(\d{4})-(\d{2})-\d{2}-/
    $1
  end
end.compact.uniq

years.each do |year|
  dir = File.join(ARCHIVE_DIR, year)
  FileUtils.mkdir_p(dir)
  index_md = File.join(dir, "index.md")
  next if File.exist?(index_md) # 已存在则跳过

  File.open(index_md, "w") do |f|
    f.puts <<~MARKDOWN
      ---
      title: "#{year}年文章归档"
      permalink: /#{year}/
      ---

      {% for post in site.posts %}
        {% assign y = post.date | date: "%Y" %}
        {% if y == '#{year}' %}        
          - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
        {% endif %}
      {% endfor %}

    MARKDOWN
  end
  puts "Generated #{index_md}"
end
