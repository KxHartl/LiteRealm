# Gemini CLI / Antigravity Instructions (LiteRealm)

@AGENTS.md

## Gemini-specific

1. **Nemaš hook safety-net** kao Claude Code: pravilo 1 (PROAKTIVNI GIT) provodiš
   isključivo sam. Nakon svake logičke cjeline ODMAH pokreni
   `.\.ai\scripts\helpers\checkpoint.ps1 "feat: opis"` (bash: `checkpoint.sh`).
2. **Prije svakog završetka odgovora** pokreni `git status --porcelain` — ako izlaz
   nije prazan, commitaj prije nego odgovoriš korisniku. Ovo nije opcionalno.
3. Nemaš native subagente: kad pravilo 4 kaže "delegiraj", sam preuzmi ulogu tog
   agenta — ali prvo pročitaj njegovu definiciju iz `~/.agentbrain/agents/<ime>.md`
   i strogo poštuj njegove `writes_to` / `never_touches` granice.
