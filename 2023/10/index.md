---
layout: archive
title: "2023年10月文章归档"
permalink: /2023/10/
---

{% for post in site.posts %}
  {% if post.date and post.date | date: "%Y" == "2023" and post.date | date: "%m" == "10" %}
- [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

