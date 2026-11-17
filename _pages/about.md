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
finance sector, and a volunteer postdoctoral researcher at the **University of Rome Tor Vergata**, in the
[SAG ART group]({{ site.sag_group_url }}). Read more
about my [experience]({{ '/experience/' | relative_url }}), my [projects]({{ '/projects/' | relative_url }}) and
my [publications]({{ '/publications/' | relative_url }}).

## Highlights

<ul class="highlights">
  {%- for item in site.data.highlights %}
  <li class="highlights__item">
    <a class="highlights__link" href="{{ item.url | relative_url }}">
      <span class="highlights__figure">{{ item.figure }}</span>
      <span class="highlights__title">{{ item.title }}</span>
      <span class="highlights__text">{{ item.text }}</span>
    </a>
  </li>
  {%- endfor %}
</ul>

## Now

*What I am working on, as of November 2026.*

**In industry.** I design and bring to production multi-agent generative AI systems for large enterprises in
financial services. The problem I focus on is a familiar one: turning a business need into a change of IT
systems usually takes weeks or months of emails and meetings, while ideas get lost along the way. My approach
replaces that path with a guided conversation. The business user describes the need in plain language;
specialised agents ask targeted questions, bring in the company's own knowledge and draft the business,
functional and test documents, comparing the current process with the target one. A human expert reviews the
result before it moves on. The work that used to take months can then be done in hours, and the assistant acts as
a bridge, and a filter, between business and IT. I own these solutions end to end: requirements with
stakeholders, solution architecture, planning, leading the engineering team, and the integration layer that turns
agents into a production system, from back end and user interface to document repositories and enterprise tools.

**In research.** In the [SAG ART group]({{ site.sag_group_url }}) at Tor Vergata I am extending my work on ambiguous instructions
([EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)) beyond text: how an agent can resolve what a
person means by combining everything it perceives in a real environment, including vision, audio, sensor data
and language. Some of this work is on its way to publication, so there will be more to share soon.

**Theses I supervise.**

- **Controllable pixel-art generation:** diffusion models paired with multimodal LLMs that check each image
  against precise requirements. For example, a level-1 wizard holding a fireball, then the same wizard at level 5
  and at level 20, which in classic Dungeons & Dragons is close to a deity: the power must grow visibly while
  the character stays recognisably the same.
- **Human-like visual grounding on grid-selection tasks (CAPTCHA-style):** given an image split into a 4×4 grid,
  select every tile that contains, say, a traffic light. The hard part is behaving like a person on tiles that
  hold only a few pixels of the object, which a strict detector would select but a human would not. Multimodal
  LLMs get reasonably close, though not yet perfectly.

**Open to** research collaborations, talks and thesis co-supervision on these topics.
{% include contact-link.html text="Write me an email" %}, ideally after reading one or two of my recent papers,
so that we can start from common ground.

## Selected publications

{% bibliography --query @*[selected=true] --group_by none %}

[All publications]({{ '/publications/' | relative_url }})

## News

<ul class="news-list">
  {%- for post in site.posts limit: 5 %}
  <li>{% include news-item.html post=post %}</li>
  {%- endfor %}
</ul>

[All news]({{ '/news/' | relative_url }})
