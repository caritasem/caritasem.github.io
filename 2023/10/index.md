---
layout: archive
title: "2023年10月文章归档"
permalink: /2023/10/
---

{% for post in posts %}
  {% assign y = post.date | date: "%Y" %}
  {% assign m = post.date | date: "%m" %}
  {% if y == '2023' and m == '10' %}
  - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

