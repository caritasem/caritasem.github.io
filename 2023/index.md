---
layout: archive
title: "2023年文章归档"
permalink: /2023/
---

{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% if y == '2023' %}        
    - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

