---
layout: archive
title: "2024年文章归档"
permalink: /2024/
---

{% assign posts = site.posts | where_exp: "post", "post.date and post.date | date: '%Y' == '2024'" %}

{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
{% endfor %}

