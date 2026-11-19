---
title: "Blog"
permalink: /blog/
description: "Technical notes by Claudiu Daniel Hromei on LLMs, multi-agent systems and multimodal AI."
---

{% assign posts = site.blog | sort: "date" | reverse %}
{% for post in posts %}
### [{{ post.title }}]({{ post.url | relative_url }})

*{{ post.date | date: "%B %-d, %Y" }}*{% if post.excerpt %} · {{ post.excerpt | strip_html | truncatewords: 40 }}{% endif %}
{% endfor %}
