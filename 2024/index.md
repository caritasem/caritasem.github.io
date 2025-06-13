---
title: "2024年文章归档"
permalink: /2024/
---

{% for post in site.posts %}
  {% assign y = post.date | date: "%Y" %}
  {% if y == '2024' %}        
    - [{{ post.title }}]({{ post.url }}) <span>{{ post.date | date: "%Y-%m-%d" }}</span>
  {% endif %}
{% endfor %}

