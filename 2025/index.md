---
layout: archive
title: "2025年文章归档"
permalink: /2025/
---

{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% if y == '2025' %}        
    - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

