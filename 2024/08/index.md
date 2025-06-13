---
layout: archive
title: "2024年08月文章归档"
permalink: /2024/08/
---

{% assign posts = site.posts | where_exp: "post", "post.date and post.date | date: '%Y' == '2024' and post.date | date: '%m' == '08'" %}
{% for post in posts %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
{% endfor %}

