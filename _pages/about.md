---
title: "About"
permalink: /
---

I am a **Senior AI Scientist** and **AI researcher** with a Ph.D. in Artificial Intelligence. My work bridges
cutting-edge research in Natural Language Processing and Large Language Models with enterprise-grade AI solutions.

My main interests are:

- **Generative AI agents** and multi-agent systems
- **Multimodal Large Language Models** and grounded language understanding
- **Human-Robot Interaction** and situated natural language understanding
- **Efficient adaptation of LLMs** to real-world and domain-specific applications

I am currently a Senior AI Scientist at **BIP**, where I lead the development of multi-agent systems for the
finance sector, and a volunteer postdoctoral researcher at the **University of Rome Tor Vergata**. Read more
about my [experience]({{ '/experience/' | relative_url }}), my [projects]({{ '/projects/' | relative_url }}) and
my [publications]({{ '/publications/' | relative_url }}).

## News

<ul class="news-list">
  {%- for post in site.posts limit: 5 %}
  <li>{% include news-item.html post=post %}</li>
  {%- endfor %}
</ul>

[All news]({{ '/news/' | relative_url }})
