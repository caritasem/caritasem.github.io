---
layout: archive
title: "2023年11月文章归档"
permalink: /2023/11/
---

{% assign posts = site.posts | where_exp: "post", "post.date | date: '%Y' == '2023' and post.date | date: '%m' == '11'" %}
{% for post in posts %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
{% endfor %}
