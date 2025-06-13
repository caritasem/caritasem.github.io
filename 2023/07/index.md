---
layout: archive
title: "2023年07月文章归档"
permalink: /2023/07/
---

{% for post in site.posts %}
  {% if post.date and post.date | date: "%Y" == "2023" and post.date | date: "%m" == "07" %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

