---
title: "Take the phone on the bed: why good agents ask questions"
date: 2026-11-19
excerpt: "An ambiguous command to a robot and a vague change request to an enterprise assistant are the same problem. What my research on robots taught me about when an agent should act, when it should ask, and which question it should ask."
tags: [agents, multimodal, hri, llm]
published: false
---

*"Take the phone on the bed."* Say it to a person and they will just do it. Say it to a robot and you have
given it a puzzle. If the phone is already on the bed, *on the bed* tells the robot **which** phone to pick
up. If the phone is on the desk, *on the bed* tells it **where** to bring it. Same words, two different
actions.

I spent a good part of my Ph.D. on sentences like this one, and I now spend my days building multi-agent
systems that turn vague business requests into precise documents. The two problems turned out to be the same
problem, and this post is about the lesson they share: **a good agent knows when to ask, and what to ask.**
At the end there is a small, tested piece of code that makes the idea concrete.

## Lesson 1: resolve what you can from what you see

Most ambiguity disappears once language meets context. In our
[EMNLP 2025 paper](https://aclanthology.org/2025.emnlp-main.1212/) a vision-language model reads the command
together with an image of the scene and produces a *grounded* logical form: not just "TAKING a phone", but
"TAKING the phone **p1**, the one you can see on the bed". The model links words to objects, so the robot
does not have to guess what *the phone* refers to.

The hard part was data. Annotated image–command pairs for robots are expensive, so we built a pipeline that
writes image prompts from the logical forms with an LLM, generates photorealistic scenes with diffusion
models, and keeps only the images that pass object detection and visual question answering checks. It produced
more than 11,000 image–command pairs, of which more than 3,500 were checked by hand, at a fraction of the
cost of collecting them. (I will write about what that validator caught in a separate post.)

The lesson carries over to any agent: **before asking anything, use the context you already have.** For a
robot that is the camera. For an enterprise assistant it is the documentation, the data catalogue and the
history of similar requests. An agent that asks what it could have looked up is not careful; it is lazy.

## Lesson 2: when the context is not enough, ask, and plan the question

Now put **two** phones in the room, one on the bed and one on the desk. Both readings are perfectly grounded
and perfectly plausible. No amount of perception will tell the robot what you meant: it has to ask.

This is what we studied in our [ACL 2025 paper](https://aclanthology.org/2025.findings-acl.837/). In a
Minecraft-like world, a builder agent receives instructions such as "add blocks above the easternmost purple
column" and, instead of building straight away, it first *plans* the dialogue: what is still unknown (how
many blocks? which colour? facing where?) and which questions will settle it. We released more than 1,100
annotated dialogues in English and Italian. Adding an explicit planning step improved the accuracy and
quality of the answers, and it helped the model transfer from one language to the other.

Asking is not a failure mode. For an embodied agent a wrong action can break something; a short question
costs a few seconds.

## The same problem, in the enterprise

In my industry work I design multi-agent systems that sit between business and IT. A business user describes
a need in plain language and a team of agents turns it into business, functional and test documents. Take a
made-up but typical request: "we need the tax code in the monthly report". It is a "phone on the bed":

- *Which* monthly report? There are several.
- The tax code from *which* system? The CRM and the core system may disagree.
- Is this a new column, or a replacement for an existing one?

The agents face exactly the two lessons above. First they look things up: the company's documentation and
past requests answer most of these questions without bothering anyone. Then they ask a few targeted
questions about what is left, and a human expert reviews the result before it moves on. Get the balance
wrong and the system fails in one of two ways: it guesses and produces a precise document about the wrong
report, or it interrogates the user with twenty questions and nobody wants to use it again.

## When to ask: a small decision rule

So how does an agent decide? Here is the simplest rule I know that captures the trade-off, and it is the one
I keep coming back to.

The agent keeps a set of candidate interpretations, each with a probability. Acting on the most likely one is
wrong with probability `1 - p_best`, and a wrong action costs `cost_of_error`. A question always costs
`cost_of_asking`: the user's time and patience. So:

- **act** if `(1 - p_best) × cost_of_error ≤ cost_of_asking`;
- otherwise **ask the question with the highest expected information gain**, the one whose answer is
  expected to remove the most uncertainty, update the candidates with the answer, and decide again.

Two things follow directly. The same uncertainty can lead to different behaviour: an agent should guess on
a low-stakes request and ask on a regulated one. And the agent never asks a question that does not split the
candidates, however uncertain it is.

I wrote this as a small Python package, [when-to-ask](https://github.com/claudiuhromei/when-to-ask), with no
model and no API key needed. The core decision fits in a few lines (slightly condensed here):

```python
def decide(interpretations, questions, *, cost_of_error, cost_of_asking):
    probs = probabilities(interpretations)
    best_index = max(range(len(probs)), key=probs.__getitem__)
    best, confidence = interpretations[best_index], probs[best_index]
    expected_cost = (1 - confidence) * cost_of_error

    if expected_cost > cost_of_asking and questions:
        gain, question = max(((information_gain(interpretations, q), q) for q in questions),
                             key=lambda pair: pair[0])
        if gain > 0:
            return Ask(question, gain, expected_cost)
    return Act(best, confidence, expected_cost)
```

Run on the robot, it acts straight away when there is one phone, and asks when there are two:

```text
== Robot: two phones (cost of error 5, cost of asking 1)
   2 candidate(s), uncertainty 1.00 bits
   ASK  Which phone do you mean: the one on the bed or the one on the desk?  (gain 1.00 bits)
   USER the one on the desk
   ACT  BRINGING(Theme(p2), Goal(bed))  (bring the phone from the desk to the bed, p=1.00)
```

Run on the change request, with four candidates (two reports × two source systems, weighted by how often each
is used), it asks about the report first, because that question splits the candidates best. Then it behaves
differently depending on the stakes:

```text
== Change request, low stakes (cost of error 3, cost of asking 1)
   ASK  Which monthly report: billing or risk?  (gain 0.97 bits)
   USER monthly billing report
   ACT  ADD_FIELD(field='tax code', report='monthly billing report', source='CRM')  (p=0.80)

== Change request, regulated (cost of error 10, cost of asking 1)
   ASK  Which monthly report: billing or risk?  (gain 0.97 bits)
   USER monthly billing report
   ASK  Should the tax code come from the CRM or the core system?  (gain 0.72 bits)
   USER core system
   ACT  ADD_FIELD(field='tax code', report='monthly billing report', source='core system')  (p=1.00)
```

In the low-stakes run the agent bets on the CRM, the usual source, and is wrong: this user wanted the core
system. At low stakes that is an acceptable bet, because the mistake is cheap to fix. In a regulated setting
it is not, and one more question is the better deal.

## Where the field is going

The idea of an agent that knows when it does not know is getting a lot of attention, from robotics to
protocols:

- **Calibrated uncertainty.** [KnowNo](https://arxiv.org/abs/2307.01928) (CoRL 2023) uses conformal
  prediction to give LLM planners a *set* of plausible actions and asks for help only when the set has more
  than one option: the same structure as the rule above, with statistical guarantees on top.
- **Choosing the question.** [ActivAsk](https://www.mdpi.com/2218-6581/15/8/154) (2026) decides when and what
  to ask a person during robotic grasping using expected free energy, an information-theoretic criterion close
  in spirit to information gain.
- **Pushing back.** Vision-language-action models are learning to refuse or question instructions that cannot
  be carried out, as in [RationalVLA](https://arxiv.org/abs/2506.10826) and
  [Instruct-Verify-and-Act](https://arxiv.org/abs/2508.16292).
- **Asking as a protocol feature.** The Model Context Protocol added *elicitation* in 2025, so that a tool can
  ask the user for missing input, and the [2026-07-28 specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
  lets a server request more input in the middle of a call. Clarification is moving from a prompt trick to a
  first-class part of how agents are built.

## What the toy hides

The decision rule is the easy part. In production the hard parts are elsewhere:

1. **Where the probabilities come from.** LLMs are not well calibrated out of the box. In practice the
   candidates and their weights come from grounding (what the camera or the documentation supports) far more
   than from the model's own confidence.
2. **Where the costs come from.** `cost_of_error` is a business decision, not a hyperparameter. Writing it
   down forces a useful conversation with the people who own the process.
3. **Asking well.** One question with concrete options ("the billing report or the risk report?") beats an
   open one ("which report?"). Batch the questions that do not depend on each other, and never ask the same
   thing twice.
4. **Knowing when to stop.** Some uncertainty is better left to the human reviewer at the end than resolved
   by a fifth question.

## Takeaways

- Resolve what you can from context before asking anything.
- Ask only when the expected cost of a wrong action exceeds the cost of a question.
- Ask the question that splits the candidates best, with concrete options.
- Let the stakes, not the model's mood, decide how cautious the agent is.

The code is on [GitHub](https://github.com/claudiuhromei/when-to-ask). If you work on agents that have to
deal with vague requests, in robotics or in enterprise software, I would be glad to compare notes:
{% include contact-link.html text="write me" %}.

*The research described here was carried out with the [SAG ART group]({{ site.sag_group_url }}) at the
University of Rome Tor Vergata. Read the papers: [EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1212/)
and [Findings of ACL 2025](https://aclanthology.org/2025.findings-acl.837/).*
