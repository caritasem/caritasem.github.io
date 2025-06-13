---
layout: archive
title: "2025年04月文章归档"
permalink: /2025/04/
---

{% assign posts = site.posts | where_exp: "post", "post.date | date: '%Y' == '2025' and post.date | date: '%m' == '04'" %}
{% for post in posts %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
{% endfor %}
