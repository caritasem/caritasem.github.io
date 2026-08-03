---
title: "2025年文章归档"
description: "caritasem 的 2025 年博客文章归档列表，记录该年度的技术积累与思考。"
permalink: /2025/
---

<ul>
{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% if y == '2025' %}        
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
