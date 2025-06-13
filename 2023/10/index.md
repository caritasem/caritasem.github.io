---
layout: archive
title: "2023年10月文章归档"
permalink: /2023/10/
---

{% assign posts = site.posts | where_exp: "post", "post.date | date: '%Y' == '2023' and post.date | date: '%m' == '10'" %}
{% for post in posts %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
{% endfor %}
