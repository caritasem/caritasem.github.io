---
title: "2023年10月文章归档"
description: "caritasem 的 2023 年 10 月博客文章归档列表，整理该月份发布的所有技术博文与随笔。"
permalink: /2023/10/
---

<ul>
{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% assign m = post.date | date: "%m" %}
  {% if y == '2023' and m == '10' %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
