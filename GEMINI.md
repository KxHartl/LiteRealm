# Gemini CLI / Antigravity Instructions (LiteRealm)

@AGENTS.md

## Gemini-specific

1. **Nemaš hook safety-net** kao Claude Code: pravilo 1 (PROAKTIVNI GIT) provodiš
   isključivo sam. Nakon svake logičke cjeline ODMAH pokreni
   `.\.ai\scripts\helpers\checkpoint.ps1 "feat: opis"` (bash: `checkpoint.sh`).
2. **Prije svakog završetka odgovora** pokreni `git status --porcelain` — ako izlaz
   nije prazan, commitaj prije nego odgovoriš korisniku. Ovo nije opcionalno.
3. **Imaš native subagente (Antigravity tools):** Kad pravilo 4 kaže "delegiraj", NE preuzimaj ulogu sam! Pročitaj definiciju agenta iz `~/.agentbrain/agents/<ime>.md`, iskoristi alat `define_subagent` da ga instanciraš koristeći taj file kao `system_prompt`, te mu delegiraj zadatak putem `invoke_subagent`. Tako štediš tokene glavnog konteksta i pravilno orkestriraš posao!
