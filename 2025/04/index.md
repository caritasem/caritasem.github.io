---
layout: archive
title: "2025年04月文章归档"
permalink: /2025/04/
---

{% for post in site.posts %}
  {% if post.date and post.date | date: "%Y" == "2025" and post.date | date: "%m" == "04" %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

