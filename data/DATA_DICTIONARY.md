# Rječnik podataka i fizičkih veličina (Data Dictionary)

Standardizirane definicije signala, stupaca tablica, mjernih jedinica i senzorskih specifikacija.

## 1. Konvencija mjernih jedinica (SI sustav)

| Oznaka | Veličina | SI Jedinica | LaTeX simbol | Opis |
|---|---|---|---|---|
| `t` | Vrijeme | $\text{s}$ | $t$ | Vrijeme uzorkovanja signala |
| `q` | Kut zgloba | $\text{rad}$ ili $^\circ$ | $q_i$ | Generalizirana koordinata zgloba |
| `dq` | Kutna brzina | $\text{rad/s}$ | $\dot{q}_i$ | Prva derivacija kuta |
| `ddq` | Kutno ubrzanje | $\text{rad/s}^2$ | $\ddot{q}_i$ | Druga derivacija kuta |
| `tau` | Moment motora | $\text{N}\cdot\text{m}$ | $\tau_i$ | Upravljački ili izmjereni moment |
| `i_m` | Struja motora | $\text{A}$ | $I$ | Struja kroz namote pogona |
| `u_m` | Napon napajanja | $\text{V}$ | $U$ | Istosmjerni napon međukruga |
| `p_x, p_y, p_z` | Pozicija vrha | $\text{m}$ ili $\text{mm}$ | $p_x, p_y, p_z$ | Kartezijeve koordinate izvršnog organa |
| `F_ext` | Vanjska sila | $\text{N}$ | $F_{\text{ext}}$ | Sila interakcije s okolinom |

---

## 2. Specifikacija senzora i mjernih kanala

| Senzor / Kanal | Mjerno područje | Točnost / Razlučivost | Frekvencija ($f_s$) | Putanja sirovih podataka |
|---|---|---|---|---|
| Inkrementalni enkoder | $0 - 360^\circ$ | 2048 imp/okr (quadrature) | 1000 Hz | `data/raw/.../encoder.csv` |
| Momentno mjerilo | $\pm 20\text{ Nm}$ | $\pm 0.1\%\text{ FS}$ | 1000 Hz | `data/raw/.../torque.csv` |
| Strujni senzor (Hall) | $\pm 10\text{ A}$ | $\pm 0.5\%$ | 2000 Hz | `data/raw/.../current.csv` |
