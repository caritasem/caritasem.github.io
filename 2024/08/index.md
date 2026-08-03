---
title: "2024年08月文章归档"
description: "caritasem 的 2024 年 08 月博客文章归档列表，整理该月份发布的所有技术博文与随笔。"
permalink: /2024/08/
---

<ul>
{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% assign m = post.date | date: "%m" %}
  {% if y == '2024' and m == '08' %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
