---
title: "2025年04月文章归档"
description: "caritasem 的 2025 年 04 月博客文章归档列表，整理该月份发布的所有技术博文与随笔。"
permalink: /2025/04/
---

<ul>
{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% assign m = post.date | date: "%m" %}
  {% if y == '2025' and m == '04' %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
