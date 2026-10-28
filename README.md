# SADR — Štatistická analýza dát v R

Študijné materiály, vysvetlenia a praktické príklady k piatim dostupným týždňom predmetu.

## Hlavná navigácia

1. **[Prednášky — vysvetlená teória, vzorce a videá](prednasky/README.md)**: od pravdepodobnosti po ANOVA, s predpokladmi a praktickým významom.
2. **[Cvičenia — grafy, testy a kód v R](cvicenia/README.md)**: na čo sú postupy dobré, ako a prečo ich použiť, ako čítať výsledky; s lokálnymi obrázkami.
3. **[Zadania](zadania/)**: pôvodné zadania a existujúce vypracovania.
4. **[HOW_TO.md](HOW_TO.md)**: pravidlá a zaužívaný štýl vypracovania zadaní v tomto repozitári.

## Navigácia podľa týždňov

1. **Pravdepodobnosť a základy R** — experimenty, udalosti, pravdepodobnostný priestor, náhodné premenné, rozdelenia a momenty; v R objekty, import a simulácia kocky.
   [Teória a videá](prednasky/README.md#tyzden-1) · [Cvičenie a obrázok](cvicenia/README.md#tyzden-1) · [Prednáška PDF](prednasky/sadr_1.pdf)
2. **Opisná štatistika a EDA** — typy premenných, početnosti, priemery, kvantily, variabilita a tvar dát; histogram, boxplot, husľový graf, jitter a empirická CDF.
   [Teória a videá](prednasky/README.md#tyzden-2) · [Cvičenie, R a obrázky](cvicenia/README.md#tyzden-2) · [Prednáška PDF](prednasky/sadr_2.pdf)
3. **Odhady a intervaly spoľahlivosti** — bodové odhady, momentová metóda, MLE, najmenšie štvorce, intervaly priemeru a rozptylu, bootstrap a pokrytie intervalov.
   [Teória a videá](prednasky/README.md#tyzden-3) · [Cvičenie, R a obrázky](cvicenia/README.md#tyzden-3) · [Prednáška PDF](prednasky/sadr_3.pdf)
4. **Testovanie hypotéz** — hypotézy, p-hodnota, chyby a sila; normalita, z-test, t-test, rozptyl a párové merania.
   [Teória a videá](prednasky/README.md#tyzden-4) · [Cvičenie, R a obrázky](cvicenia/README.md#tyzden-4) · [Prednáška PDF](prednasky/sadr_4.pdf)
5. **Nezávislé výbery a ANOVA** — F-test a Welchov t-test, porovnanie viacerých skupín, Bartlett/Levene, post-hoc testy, miery efektu, rezíduá a dvojfaktorové interakcie.
   [Teória a videá](prednasky/README.md#tyzden-5) · [Cvičenie, R a obrázky](cvicenia/README.md#tyzden-5) · [Prednáška PDF](prednasky/sadr_5.pdf)

Číslovanie vychádza z poradia prednášok a cvičení. Druhé cvičenie je uložené v `cvicenia/01/SADR2.*`; priečinok `cvicenia/02` preto v navigácii nenájdeš. Prednáška 4 už vysvetľuje aj nezávislé výbery, ktoré sa prakticky precvičujú v týždni 5.

## Rýchle odkazy podľa potreby

| Potrebujem | Kam prejsť |
|---|---|
| Vybrať správny test | [Rozhodovacia tabuľka](cvicenia/README.md#vyber-testu) |
| Spustiť príklady v R | [Pracovný adresár a balíky](cvicenia/README.md#spustenie) |
| Pochopiť histogram, boxplot a ďalšie grafy | [EDA s obrázkami](cvicenia/README.md#tyzden-2) |
| Pochopiť neistotu odhadu a bootstrap | [Intervaly a bootstrap](cvicenia/README.md#tyzden-3) |
| Správne interpretovať test a p-hodnotu | [Testovanie hypotéz](prednasky/README.md#tyzden-4) |
| Porovnať skupiny a interpretovať interakciu | [ANOVA v praxi](cvicenia/README.md#tyzden-5) |
| Precvičiť staršie otázky a súhrnné údaje | [Doplnkové pracovné listy](cvicenia/README.md#doplnky) |
| Znova vygenerovať obrázky | [Postup a R skript](cvicenia/README.md#obrazky) |

## Zadania a existujúce riešenia

| Zadanie | Zadanie PDF | Riešenie v R | Výstup HTML |
|---|---|---|---|
| 1 | [Zadanie1.pdf](zadania/01/Zadanie1.pdf) | [Zadanie1_Bagin.R](zadania/01/Zadanie1_Bagin.R) | [Zadanie1_Bagin.html](zadania/01/Zadanie1_Bagin.html) |
| 2 | [Zadanie2.pdf](zadania/02/Zadanie2.pdf) | [zadanie2_bagin.R](zadania/02/zadanie2_bagin.R) | [zadanie2_bagin.html](zadania/02/zadanie2_bagin.html) |
| 3 | [Zadanie3.pdf](zadania/03/Zadanie3.pdf) | [zadanie3_bagin.R](zadania/03/zadanie3_bagin.R) | [zadanie3_bagin.html](zadania/03/zadanie3_bagin.html) |
| 4 | [Zadanie4.pdf](zadania/04/Zadanie4.pdf) | [zadanie4_bagin.R](zadania/04/zadanie4_bagin.R) | [zadanie4_bagin.html](zadania/04/zadanie4_bagin.html) |

Odkazy sprístupňujú existujúce súbory; táto dokumentácia nepredstavuje revíziu jednotlivých vypracovaní.

## Ako sa z materiálov učiť

Pre každý týždeň si najprv prejdi otázku a princíp v prednáškach, potom spusti príklad v cvičeniach a vysvetli si graf aj záver vlastnými slovami. Videá sú priradené k témam priamo pri týždňoch prednášok; sú prevažne v angličtine. Pri teste vždy rozlišuj praktickú otázku, predpoklady, rozhodnutie a veľkosť rozdielu.

Matematika v README používa LaTeX a potrebuje náhľad s podporou matematických vzorcov, napríklad GitHub. R ukážky používajú relatívne cesty **z koreňa tohto repozitára**. Obsah dokumentácie zodpovedá miestnym materiálom a overeniu z 28. 10. 2026.
