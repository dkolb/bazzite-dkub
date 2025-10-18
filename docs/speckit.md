# SpecKit (Spec-Driven Development) — Quick Reference

This project uses GitHub's SpecKit (https://github.com/github/spec-kit) as part of a spec-driven development workflow. SpecKit helps you write executable specifications, generate implementation plans and tasks, and drive implementation with supported AI agents.

Purpose
- Treat specifications as first-class, executable artifacts.
- Move from vague requirements to actionable tasks and code via the `specify` CLI and the SpecKit slash commands.

Quick setup
1. Install the Specify CLI (recommended persistent installation):
   uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

2. Initialize a project (example):
   specify init my-project --ai copilot

Core commands (slash commands available to your AI assistant after init)
- /speckit.constitution — Create or update project principles and guidelines that govern development decisions.
- /speckit.specify — Describe the feature or system in natural language (focus on what and why).
- /speckit.plan — Generate a technical implementation plan (tech stack, architecture, constraints).
- /speckit.tasks — Break the plan into actionable tasks.
- /speckit.implement — Execute tasks and build the feature (automated by supported AI agents where available).

Useful specify CLI flags
- --ai <agent> : Choose an AI assistant (claude, gemini, copilot, cursor-agent, windsurf, qwen, etc.)
- --here : Initialize in current directory
- --no-git : Skip git init
- --force : Force overwrite when initializing into non-empty directory

Recommended workflow
1. Run `/speckit.constitution` to set project principles.
2. Run `/speckit.specify` to author the spec (scenarios, acceptance criteria).
3. Run `/speckit.plan` to produce a technical plan.
4. Run `/speckit.tasks` to produce a task list and assign priorities.
5. Run `/speckit.implement` to generate or execute the implementation with your AI assistant.
6. Use `/speckit.clarify` if any parts of the spec are underspecified before planning.

Notes and caveats
- SpecKit integrates with multiple AI agents; choose one supported in your environment.
- The `specify init` command will scaffold templates and enable slash commands in your agent environment.
- Treat SpecKit outputs (plans/tasks) as living artifacts — review and refine them.

References
- SpecKit repo: https://github.com/github/spec-kit
- Use `specify check` to verify installed tools and agent availability.

---

This file is intended as a human-facing quick reference. For deeper usage, read the SpecKit README and docs in the upstream repository.