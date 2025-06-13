---
layout: archive
title: "2023年07月文章归档"
permalink: /2023/07/
---

{% for post in posts %}
  {% assign y = post.date | date: "%Y" %}
  {% assign m = post.date | date: "%m" %}
  {% if y == '2023' and m == '07' %}
  - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

