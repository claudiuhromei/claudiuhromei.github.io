---
title: "News"
permalink: /news/
description: "News and milestones from the work of Claudiu Daniel Hromei: papers, awards, talks and career updates."
---

{% assign posts_by_year = site.posts | group_by_exp: "post", "post.date | date: '%Y'" %}
{% for year in posts_by_year %}
## {{ year.name }}

<ul class="news-list">
  {%- for post in year.items %}
  <li>{% include news-item.html post=post %}</li>
  {%- endfor %}
</ul>
{% endfor %}
