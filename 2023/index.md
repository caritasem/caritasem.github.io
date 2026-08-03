---
title: "2023年文章归档"
description: "caritasem 的 2023 年博客文章归档列表，记录该年度的技术积累与思考。"
permalink: /2023/
---

<ul>
{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% if y == '2023' %}        
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
