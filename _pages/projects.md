---
title: "Projects"
permalink: /projects/
description: "Open source projects and research software by Claudiu Daniel Hromei."
---

Open source code and models from my research. The models are published on the
[SAG group page on Hugging Face](https://huggingface.co/sag-uniroma2/models).

## Situated G-SRL & synthetic data generation

Official code for the EMNLP 2025 paper. A pipeline that uses diffusion models and LLMs to generate more than
11,000 synthetic grounded commands for training robots.

A command such as *"take the phone on the bed"* is ambiguous. If the phone is already on the bed, as in the
picture below, the robot only has to pick it up. If it is somewhere else, the robot has to fetch it and bring
it to the bed. To tell the two apart, the model links the words of the command to what the robot sees.

{% include project-figure.html image="situated-g-srl-scene.jpg" width="883" height="624"
   alt="A smartphone lying on a bed in a bedroom, marked by a bounding box labelled 'phone'."
   source="The phone of the command, located in the robot's view. Figure from [Hromei et al., EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)." %}

{% include project-figure.html image="situated-g-srl.png" width="506" height="642"
   alt="Flow chart of the data generation pipeline: a command and its logical form give constraints, an LLM writes image prompts, generated images are validated against the constraints by detection and visual question answering, then ranked into the final image set."
   source="Data generation pipeline. Figure from [Hromei et al., EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)." %}

[Code on GitHub](https://github.com/crux82/GroundedSRL4HRI)

## MM-IGLU

*Multi-Modal Interactive Grounded Language Understanding.* A benchmark and a model for robotic agents in
Minecraft-like environments, featuring a "Builder" agent capable of clarification dialogues and visual
grounding.

{% include project-figure.html image="mm-iglu.png" width="628" height="995"
   alt="A block world scene with purple and orange columns, followed by a chat: the user asks to add blocks above the easternmost purple column and the agent asks how many, which colour, how to arrange them and which direction to face before confirming the plan."
   source="The agent asks clarification questions before acting. Figure from [Hromei et al., Findings of ACL 2025](https://aclanthology.org/2025.findings-acl.837/)." %}

[Code on GitHub](https://github.com/crux82/MM-IGLU-Dialogues)

## ExtremITA

A unified multi-task Large Language Model for Italian that reached state-of-the-art performance across seven
different NLP tasks in the EVALITA 2023 campaign, winning 41% of the tracks.

{% include project-figure.html image="extremita.png" width="148" height="149" class="project-figure--logo"
   alt="ExtremITA logo: a llama wearing sunglasses in front of the Italian flag."
   source="Project logo, from the [ExtremITA repository](https://github.com/crux82/ExtremITA)." %}

[Code on GitHub](https://github.com/crux82/ExtremITA)

## U-DepPLLaMA

Universal Dependency parsing with auto-regressive LLMs, showing that standard LLMs can perform complex
syntactic parsing without specialised heads.

{% include project-figure.html image="u-deppllama.png" width="1111" height="180"
   alt="Dependency graph of the Italian sentence 'Tutti gli esseri umani hanno capacità non sfruttate, non utilizzate', with labelled arcs such as ROOT, NSUBJ, OBJ, ACL and CONJ."
   source="A dependency graph of the kind the model predicts. Figure from [Hromei et al., CLiC-it 2023](https://aclanthology.org/2023.clicit-1.30/)." %}

[Code on GitHub](https://github.com/crux82/u-deppllama)

## GrUT

*Grounded language Understanding via Transformers.* A neural architecture that interprets spoken robotic
commands through Grounded Semantic Role Labelling. It pre-dates the ChatGPT era and applies Transformer-based
sequence-to-sequence models to situated Human-Robot Interaction.

[Code on GitHub](https://github.com/crux82/grut)

## HeAL9000

A robotic platform for patient rehabilitation, for which I integrated the speech-to-text, text-to-speech and
natural language understanding modules.

{% include project-figure.html image="heal9000.png" width="924" height="587"
   alt="Architecture diagram: a central controller with shared storage and an admin console connects a speech-to-text module, a patients and exercises repository, a cognitive component (NLU, dialogue manager, NLG, knowledge base) and a robotic component (service robot, RGB-D camera, wearable sensors) that interacts with the patient."
   source="System architecture. Figure from [Cristofori et al., 2021](https://ceur-ws.org/Vol-3060/paper-4.pdf)." %}
