---
title: "Take the phone on the bed: why good agents ask questions"
date: 2026-11-19
excerpt: "An ambiguous command to a robot and a vague change request to an enterprise assistant are the same problem. Frames, grounding and dialogue plans from my research, and how I turn them into an agent that knows when to ask and what to ask."
tags: [agents, multimodal, hri, llm, framenet]
---

*"Take the phone on the bed."* Say it to a person and they will just do it. Say it to a robot and you
have given it a puzzle. If the phone is already on the bed, *on the bed* tells the robot **which** phone
to pick up. If the phone is on the desk, *on the bed* tells it **where** to bring it. Same words, two
different actions.

{% include project-figure.html dir="blog/why-good-agents-ask-questions" image="two-readings.svg"
   width="680" height="340" class="project-figure--wide"
   alt="Two scenes side by side. Left: the phone lies on the bed; the command means TAKING, with the bed as the Source: pick it up. Right: the phone lies on the desk, with an arrow to the bed; the command means BRINGING, with the bed as the Goal: carry it there."
   source="The same command, two scenes, two actions." %}

I spent my Ph.D. on sentences like this one, and I now spend my days building multi-agent systems that
turn vague business requests into precise documents. The two problems turned out to be the same problem.
This post walks through what my research taught me about it, and ends with a small, tested agent that
models the lesson as a decision graph: **resolve what you can from the context, and ask, well, only what
you must.**

## Where the ambiguity comes from

The command is ambiguous at two levels at once.

- **Lexical:** the verb *take* has several meanings. It can mean *get hold of something* (take the phone
  from the bed) or *carry something somewhere* (take the phone to the bed). Each meaning evokes a
  different *situation*, with different participants.
- **Structural:** the phrase *on the bed* can describe the phone (the phone *that is* on the bed) or
  complete the action (put it *on the bed*). The parser has to decide which role the phrase plays.

The two levels are coupled: choosing the meaning of *take* changes the role of *on the bed*, and the
other way round. People resolve both without noticing, because they look at the room. A system that only
reads the words cannot. To reason about this explicitly I need two tools: a way to write down what an
interpretation *is*, and a way to tie it to the world.

## Interpretations, frames and grounding

### What an interpretation is

For an agent, understanding a request means building an **interpretation**: a structured description of
the action it should carry out, who or what is involved, and in which role. It is the bridge between the
words and a plan the agent can execute. An ambiguous request is simply one that admits more than one
interpretation, so the question "should I ask?" becomes "how many interpretations are still standing?".

### FrameNet in a nutshell

The representation I use comes from **frame semantics** (Fillmore, 1985) and its lexical database,
[FrameNet](https://framenet.icsi.berkeley.edu/) ([Baker, Fillmore and Lowe, 1998](https://aclanthology.org/P98-1013/)),
developed at ICSI in Berkeley. Three ideas are enough to read the rest of this post:

- A **frame** is a schematic situation, such as *Taking* or *Bringing*, with a short definition.
- **Frame elements** are the roles of that situation: *Bringing* has a Theme (what is carried), a Goal
  (where it ends up), a Source, a Path and so on.
- A **lexical unit** is a word in one of its senses, and it *evokes* a frame. *Bring*, *carry* and one
  sense of *take* evoke *Bringing*; another sense of *take* evokes *Taking*.

FrameNet lists more than 1,200 frames and 13,000 lexical units, with annotated example sentences for
each. The task of finding, in a sentence, the word that evokes a frame, the frame itself and the spans
that fill its roles is called **semantic role labelling**
([Gildea and Jurafsky, 2002](https://aclanthology.org/J02-3001/)). Applied to our command, it gives two
annotations:

{% include project-figure.html dir="blog/why-good-agents-ask-questions" image="frames.svg"
   width="680" height="330" class="project-figure--wide"
   alt="The verb take.v points to two frames, TAKING (an Agent takes a Theme from a Source) and BRINGING (an Agent moves a Theme to a Goal). Below, the command annotated twice: once with on the bed as the Source of TAKING, once as the Goal of BRINGING."
   source="One word, two frames, two role assignments for the same phrase." %}

Why this representation, and not free text or a hand-made list of robot actions?

1. **It is executable.** A frame maps naturally onto an action, and its frame elements onto the
   arguments of that action. The [HuRIC corpus](https://github.com/crux82/huric), built in our group,
   annotates hundreds of robot commands this way (Vanzo et al., *Artificial Intelligence*, 2020).
2. **It is readable.** A person can check `BRINGING(Theme: the phone, Goal: the bed)` at a glance, so the
   agent can show what it understood before acting.
3. **It is largely shared across languages.** The situations stay the same when the words change, which
   is why the same representation works for English and Italian in our work.
4. **It makes ambiguity countable.** Each reading is an explicit, finite object. You can list them, test
   them against the world, and see which ones survive.

### What grounding is, and why it matters

A frame on its own is still made of words: *the phone*, *the bed*. **Grounding** links each frame element
to something the agent can act on, the classic *symbol grounding problem*
([Harnad, 1990](https://arxiv.org/abs/cs/9906002)). For a robot, a role can be grounded *visually*, with
the bounding box of the object in the camera image, or *symbolically*, with a tag for things it cannot see:
a known room (`<ROOM>`), the speaker (`<PERSON>`), an object it expects but cannot find (`<MISSING>`).

{% include project-figure.html dir="blog/why-good-agents-ask-questions" image="grounding.svg"
   width="680" height="300" class="project-figure--wide"
   alt="On the left, the BRINGING interpretation with Theme the phone and Goal the bed; arrows link them to the boxes of phone p2 on the desk and of bed b1 in the robot's view. A greyed TAKING reading is discarded because no phone is on the bed. At the bottom, symbolic tags: ROOM, PERSON, MISSING, STATUS."
   source="Grounding links roles to what the robot perceives, and discards the readings that do not fit." %}

Grounding matters for two reasons. It is what makes an interpretation executable: the robot needs *that*
phone, not the word *phone*. And it **filters** the readings: if no phone lies on the bed, the *Taking*
reading has nothing to refer to and disappears, and the ambiguity resolves itself without a single
question. That is the first lesson.

## Lesson 1: resolve what you can from what you see

In our [EMNLP 2025 paper](https://aclanthology.org/2025.emnlp-main.1212/) we framed this as **grounded
semantic role labelling** (G-SRL): given a command and an image, produce the frames, their roles and, for
each role, its grounding. A vision-language model reads both and writes the logical form directly:

```text
Command: "Bring the phone on the bed in the living room"

BRINGING(
  (THEME, "phone",       [170, 541, 852, 940])   # bounding box in the image
  (GOAL,  "living room", <ROOM>)                 # a known place, not visible
)
```

Two details are worth noticing. The bed does not even appear in the output: the box around the phone is
all the robot needs to find it. And **the structure adapts to the scene**: if the phone were already in
the living room, the same command would yield a different logical form, with the bed as the Goal. The
interpretation is not decided by the words alone, but by the words *and* what the robot sees.

{% include project-figure.html image="situated-g-srl-scene.jpg" width="883" height="624"
   alt="A smartphone lying on a bed in a bedroom, marked by a bounding box labelled 'phone'."
   source="A scene from our pipeline: the box around the phone grounds the Theme. Figure from [Hromei et al., EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)." %}

**The data problem.** Teaching a model to do this needs many examples of commands paired with images in
which every role is visible (or deliberately not visible). Collecting them in real homes is slow and
expensive, and 3D simulators look artificial and are hard to control. So we generated them, starting
from the 619 HuRIC commands that can be rendered visually:

1. **Constraints.** From each command and its logical form we derive what the image must satisfy:
   *accessibility* (`visible(phone)`, `¬visible(living room)`), *spatial* relations (`ontop(phone, bed)`)
   and *object states* (`open(door)`). Each command gets several variants: phone and bed both visible,
   only one of them, or neither, so that the model sees genuine perceptual ambiguity.
2. **Prompts.** An LLM (GPT-4o) turns each set of constraints into short scene descriptions, from several
   viewpoints (close-up, wide shot, high angle), including explicit negations such as "no cups".
3. **Images.** A diffusion model (FLUX.1-schnell) renders about 90 candidates per command.
4. **Validation.** An open-vocabulary detector (GroundingDINO) checks that required objects are there and
   forbidden ones are not; a VLM (MiniCPM-V 2.6) answers yes/no questions for spatial relations and
   states. The scores are combined into one consistency score per image.
5. **Ranking.** Instead of hard thresholds, we keep the top-k images per command.

{% include project-figure.html image="situated-g-srl.png" width="506" height="642"
   alt="Flow chart of the data generation pipeline: a command and its logical form give constraints, an LLM writes image prompts, generated images are validated against the constraints by detection and visual question answering, then ranked into the final image set."
   source="The data generation pipeline. Figure from [Hromei et al., EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)." %}

Two annotators then reviewed every one of the top-3 images per command (3,796 images): about 93% passed
all five checks (rendering, anomalies, boxes, states, spatial relations), and only 2.3% of the top-1
images had a wrong bounding box. We used the manually validated images as the test set and fine-tuned
MiniCPM-V 2.6 on the rest:

| Training data | Frame F1 | Frame elements F1 | Full tuples F1 | Box IoU |
|---------------|---------:|------------------:|---------------:|--------:|
| None (zero-shot) | 62.4 | 33.8 | 24.5 | 6.9 |
| Top-1 image per command | 97.7 | 96.1 | 94.8 | 44.7 |
| Top-3 images per command | 96.6 | 94.4 | 93.5 | 52.1 |
| Top-10 images per command, no manual check | | | | 64.7 |

Out of the box, the model recognises the frame but cannot fill the roles or find the objects. A thousand
synthetic examples are enough to make interpretation almost perfect, and grounding keeps improving with
more (noisier) images: about 11,300 images in total, without signs of saturation. Qwen2.5-VL behaved like
MiniCPM in zero-shot, and a general-purpose model like GPT-4 gave inconsistent logical forms, most likely
because it has seen little FrameNet.

**What this means for any agent:** a large share of "ambiguity" is not in the request but in the agent's
ignorance of the context. Before designing a single clarification question, make sure the agent grounds
the request in everything it can perceive or look up.

## Lesson 2: when the context is not enough, plan the questions

Now put **two** phones in the room, one on the bed and one on the desk. Both readings are grounded and
both are plausible: no amount of perception will tell the robot what you meant. It has to ask, and the
interesting question is *how*.

In our [ACL 2025 paper](https://aclanthology.org/2025.findings-acl.837/) we studied this in a
Minecraft-like world ([MM-IGLU](https://aclanthology.org/2024.lrec-main.1000/)): a builder agent sees the
scene and receives instructions such as "add some blocks above the easternmost purple column". Standard
multimodal LLMs, asked to reply turn by turn, tend to repeat questions, forget what was answered, or
invent details instead of asking. Our fix was to make the missing information **explicit**, with a
**dialogue plan**.

A dialogue plan is the ordered list of the *types* of information that are still missing, drawn from a
small, domain-specific set: NUMBER, COLOR, ORIENTATION, DIRECTION, DISPOSITION, POSITION, BLOCK MISSING,
NOT EXECUTABLE and CONFIRMATION. At every turn the same model is prompted twice, from the image and the
dialogue so far: first to write the plan, then to write the next message, conditioned on the first item of
the plan. After each answer it re-plans, so the plan shrinks until only the confirmation is left, with a
recap that the user can check before the agent acts.

{% include project-figure.html dir="blog/why-good-agents-ask-questions" image="dialogue-plan.svg"
   width="680" height="300" class="project-figure--wide"
   alt="For the command add some blocks above the easternmost purple column, plan P1 lists NUMBER, COLOR, DISPOSITION, DIRECTION, CONFIRMATION; the agent asks how many blocks. After the answer three, plan P2 starts with COLOR and the agent asks what colour. The last plan holds only CONFIRMATION, with a recap."
   source="The dialogue plan shrinks as the agent gathers information. Example from [Hromei et al., Findings of ACL 2025](https://aclanthology.org/2025.findings-acl.837/)." %}

{% include project-figure.html image="mm-iglu.png" width="628" height="995"
   alt="A block world scene with purple and orange columns, followed by a chat: the user asks to add blocks above the easternmost purple column and the agent asks how many, which colour, how to arrange them and which direction to face before confirming the plan."
   source="A full clarification dialogue in the block world. Figure from [Hromei et al., Findings of ACL 2025](https://aclanthology.org/2025.findings-acl.837/)." %}

Five annotators wrote 1,136 dialogues on MM-IGLU scenes, 7.5 turns long on average and up to 20, each
available in English and in a manual Italian translation. We fine-tuned LLaVA and MiniCPM with LoRA,
with and without the planning step. A few numbers for MiniCPM (similarity of the generated questions and
recaps to the reference ones, 0 to 1):

| Setting | Questions | Recaps |
|---------|----------:|-------:|
| Zero-shot | 0.55 | 0.71 |
| Fine-tuned on the dialogue history | 0.77 | 0.92 |
| Fine-tuned with the dialogue plan | **0.84** | **0.96** |
| Trained in English, tested in Italian, no plan | 0.66 | 0.86 |
| Trained in English, tested in Italian, with plan | **0.74** | **0.93** |

The plan helps most where it should: on the *questions*, and especially across languages, where a model
that learned *what* to ask transfers better than one that only learned *how* people talk. In 40 live
dialogues with people who had not seen the data, the planned model's questions were judged far more
relevant (4.25 against 3.13 on a 1–5 scale), and the dialogues were slightly shorter.

**What this means for any agent:** don't let the model improvise clarifications turn by turn. Make it
write down what is missing first; then each question has a reason, the agent knows when it is done, and
the plan is something you can inspect, test and measure.

## The same problem, in the enterprise

In my industry work I design multi-agent systems that sit between business and IT. A business user
describes a need in plain language and a team of agents turns it into business, functional and test
documents. Take a made-up but typical request: "we need the tax code in the monthly report". It is a
"phone on the bed":

- *Which* monthly report? There are several.
- The tax code from *which* system? The CRM and the core system may disagree.
- Is this a new column, or a replacement for an existing one?

The two lessons carry over directly. The **frames** are the types of change request; **grounding** links
their roles to the company's reports, systems and documentation; a lot of apparent ambiguity disappears
there (the data dictionary already says which system owns the tax code). What is left goes into a
**dialogue plan**, and the agents ask a few targeted questions. A human expert reviews the result before
it moves on. Get the balance wrong and the system fails in one of two ways: it guesses and produces a
precise document about the wrong report, or it interrogates the user with twenty questions and nobody
wants to use it again.

## Putting it together: a decision graph driven by prompts

How do you build this into an agent? Not with a formula. Decision-theoretic rules ("ask when the expected
cost of an error exceeds the cost of a question") are elegant, but they need probabilities and costs that
nobody has in practice. What works is a division of labour:

- the **graph** fixes the structure: which steps exist and how they connect;
- **prompts** bring the judgment: what the readings are, what is missing, how to phrase a question;
- **code** brings the guarantees: grounding, tools, validation of every model output, and policy.

I wrote a small version of it, [when-to-ask](https://github.com/claudiuhromei/when-to-ask), with the same
graph for the robot and for the change request:

{% include project-figure.html dir="blog/why-good-agents-ask-questions" image="decision-graph.svg"
   width="680" height="380" class="project-figure--wide"
   alt="Decision graph: interpret (LLM) to ground (code) to plan (LLM). From plan: lookup (code), assume, or ask (LLM), each going back to plan; when nothing is missing, recap (LLM) and then execute or human review. From ground, reject when no reading fits. A note lists the policy checks in code."
   source="The clarification graph. Green nodes call the model, grey nodes are plain code." %}

1. **interpret** (LLM) lists *every* reading of the request as frames, using a small inventory written for
   the domain. It is asked not to choose, only to enumerate.
2. **ground** (code) links each role to the context, the objects in view or the catalogue, and drops the
   readings that do not fit. If none fits, the request is rejected.
3. **plan** (LLM) writes the dialogue plan: the missing information, in order, and for each item whether
   it can be resolved from the **context**, safely **assumed**, or must be asked to the **user**.
4. **lookup** (code) resolves an item with a tool, such as the data dictionary, without bothering anyone;
   **assume** records a cheap guess and reports it in the recap; **ask** (LLM) phrases one question with
   the concrete options, then maps the free-text answer back to one of them. All three go back to *plan*.
5. **recap** (LLM) states in one sentence what will be done, including any assumption, and the result is
   executed or, in a high-stakes domain, sent to human review.

The heart of it is the planning prompt. This is the core of it, sent with the context, the candidates
still standing and the dialogue so far:

```text
Write the dialogue plan: the ordered list of missing information that must be resolved before
acting, so that exactly one interpretation remains. For each item choose how to resolve it:
"context" if the context or a lookup in company documentation can answer it, "user" if only the
person can, "assume" if a wrong guess is cheap and easy to undo (give the default).
Return an empty plan if exactly one interpretation remains.
```

And this is why the model never has the last word. Its plan is checked against the domain before the
graph moves on:

```python
for step in proposed_plan:
    if step.category not in domain.categories:           # invented by the model
        continue
    if step.resolve_by == "assume" and domain.high_stakes:
        step = PlanStep(step.category, "user", step.reason)  # policy lives in code
    plan.append(step)
if not plan and len(candidates) > 1:                      # "nothing missing", but they disagree
    plan = [PlanStep(first_disagreeing_category, "user", "candidates still disagree")]
```

Here are two runs. They use the demo's **simulated mode**: the model answers were written by hand and are
replayed, so anyone can run them offline and get the same trace; one flag runs the same graph on Claude
or on any OpenAI-compatible model, local ones included. The traces are lightly abridged.

```text
== Robot, two phones: "take the phone on the bed"
   - 2 reading(s): TAKING(Theme='the phone', Source='the bed'); BRINGING(Theme='the phone', Goal='the bed')
   - 2 grounded candidate(s): TAKING(Theme=p1, Source=b1); BRINGING(Theme=p2, Goal=b1)
   - plan: OBJECT by user
   AGENT  Do you mean the phone that is already on the bed, or the one on the desk that I should bring to the bed?
   USER   The one on the desk, please.
   - ask: OBJECT = p2
   - plan: nothing missing
   path: interpret -> ground -> plan -> ask -> plan -> recap
   RECAP  I will bring the phone from the desk to the bed.
```

With a single phone on the desk, the same graph never asks: grounding leaves one candidate, and the path
is `interpret -> ground -> plan -> recap`. The change request shows the other branches:

```text
== Change request: "we need the tax code in the monthly report"
   - discarded a reading outside the frame inventory: {'frame': 'UPDATE_REPORT', ...}
   - 4 grounded candidate(s): 2 monthly reports x 2 systems that hold the tax code
   - policy: REPORT may not be assumed here, asking instead
   - plan: SOURCE by context, REPORT by user
   - lookup: SOURCE = CORE (from the context, no question)
   AGENT  Which monthly report should show the tax code: the billing report or the risk report?
   USER   The risk one.
   - ask: REPORT = R-RISK
   path: interpret -> ground -> plan -> lookup -> plan -> ask -> plan -> recap
   RECAP  Add the tax code, taken from the core system (the system of record), to the monthly risk report.
   OUTCOME human review
```

The model proposed an extra frame that does not exist in the inventory, and wanted to *assume* the
billing report; the code discarded the first and turned the second into a question, because this domain
is marked high-stakes. The source system never reached the user: the data dictionary answered it.

The graph engine is about thirty lines on purpose. The same nodes and edges map one to one onto
LangGraph, Google ADK or Strands, which add persistence, streaming and parallel branches; the design
decisions (which steps exist, where the model is trusted, where it is checked) are the same.

## Where the field is going

The idea of an agent that knows when it does not know is getting a lot of attention, from robotics to
protocols:

- **Calibrated uncertainty.** [KnowNo](https://arxiv.org/abs/2307.01928) (CoRL 2023) uses conformal
  prediction to give LLM planners a *set* of plausible actions and asks for help only when the set has more
  than one option: the same "how many interpretations are left?" test, with statistical guarantees.
- **Choosing the question.** [ActivAsk](https://www.mdpi.com/2218-6581/15/8/154) (2026) decides when and what
  to ask during robotic grasping with an information-theoretic criterion.
- **Pushing back.** Vision-language-action models are learning to refuse or question instructions that
  cannot be carried out, as in [RationalVLA](https://arxiv.org/abs/2506.10826) and
  [Instruct-Verify-and-Act](https://arxiv.org/abs/2508.16292).
- **Asking as a protocol feature.** The Model Context Protocol added *elicitation* in 2025, so that a tool
  can ask the user for missing input, and the
  [2026-07-28 specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/) lets a server request
  more input in the middle of a call. Clarification is moving from a prompt trick to a first-class part of
  how agents are built.

## What the toy hides

The demo is small on purpose. In production, the hard parts are elsewhere:

1. **The inventory is design work.** Frames and categories of missing information are domain-specific,
   exactly as in the ACL paper. Writing them down with the people who own the process is most of the job,
   and it pays off twice: the same inventory drives the prompts and the validation.
2. **Grounding is where the data lives.** For a robot it is perception; in a company it is search over
   documentation, catalogues and past requests. Its quality bounds everything else.
3. **Evaluate the nodes, not just the chat.** The plan node can be tested like a classifier (did it name
   the right missing information?), and the ask node like a generator, which is how we evaluated the
   dialogue models.
4. **Know when to stop.** The graph caps the number of questions and hands over to a human reviewer:
   some uncertainty is better resolved at review time than with a fifth question.

## Takeaways

- Write interpretations down as frames: ambiguity becomes a list you can count.
- Ground before you ask: context removes most readings for free.
- Make the model plan what is missing before it asks; ask with concrete options.
- Let a graph fix the structure, prompts bring the judgment, and code enforce the guarantees.

The code is on [GitHub](https://github.com/claudiuhromei/when-to-ask). If you work on agents that have
to deal with vague requests, in robotics or in enterprise software, I would be glad to compare notes:
{% include contact-link.html text="write me" %}.

*The research described here was carried out with the [SAG ART group]({{ site.sag_group_url }}) at the
University of Rome Tor Vergata. Read the papers: [EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)
and [Findings of ACL 2025](https://aclanthology.org/2025.findings-acl.837/).*
