# Claude Code Instructions (LiteRealm)

@AGENTS.md

## Claude-specific

1. **Hooks su aktivni** (`.claude/settings.json`): pisanje u `data/raw/` je blokirano
   na razini alata, a Stop hook te vraća na posao ako postoje necommitane promjene —
   commitaj svaku logičku cjelinu odmah, ne tek kad te hook prisili.
2. **Subagenti**: specijalisti iz pravila 4 postoje kao native subagenti u
   `.claude/agents/`. Delegiraj im poslove (Task tool) umjesto da ih radiš sam u
   glavnom kontekstu — to štedi tokene i drži fokus.
3. Ako hook poruka i korisnikova uputa proturječe, korisnik ima zadnju riječ.
