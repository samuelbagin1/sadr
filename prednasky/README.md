# SADR — vysvetlené prednášky

[← Navigácia predmetu](../README.md) · [Praktické použitie v R →](../cvicenia/README.md)

Zhrnutie vychádza z piatich PDF v tomto priečinku. Týždne označujú poradie materiálov `sadr_1.pdf` až `sadr_5.pdf`, nie dodatočne odvodené kalendárne dátumy. Vzorce sú zapísané v LaTeXu pre náhľad Markdownu s podporou matematiky, napríklad na GitHube.

Každá téma sa začína vysvetlením **čo** rieši, **ako** pri nej postupujeme a **prečo** daný postup dáva zmysel. Nasledujú podrobnosti, vzorce a príklady; pri výbere metódy vždy sleduj aj jej predpoklady.

## Navigácia podľa týždňov

1. [Pravdepodobnosť a náhodné premenné](#tyzden-1) — experiment, udalosti, definície pravdepodobnosti, σ-algebra, miera, diskrétne a spojité premenné, distribučná funkcia a momenty.
2. [Opisná štatistika a EDA](#tyzden-2) — populácia a výber, typy premenných, početnosti, priemery, kvantily, variabilita, šikmosť, špicatosť a grafy.
3. [Odhady a intervaly spoľahlivosti](#tyzden-3) — vlastnosti odhadov, momentová metóda, MLE, najmenšie štvorce, intervaly pre priemer a rozptyl, bootstrap.
4. [Testovanie hypotéz](#tyzden-4) — hypotézy, chyby, sila, p-hodnota, z-test, t-test, test rozptylu, párové a nezávislé výbery, F-test a Welchov test.
5. [ANOVA a porovnávanie skupín](#tyzden-5) — rozklad variability, predpoklady, post-hoc testy, miery efektu, dva faktory, interakcie, Bartlettov a Leveneov test.

## Značenie

| Symbol | Význam |
|---|---|
| $X$, $x_i$ | Náhodná premenná; jej konkrétne pozorovanie. |
| $n$, $n_i$, $k$ | Počet pozorovaní; počet v skupine; počet skupín. |
| $\mu$, $\sigma^2$, $\sigma$ | Populačná stredná hodnota, rozptyl a smerodajná odchýlka. |
| $\bar x$, $s^2$, $s$ | Výberový priemer, nevychýlený výberový rozptyl a výberová smerodajná odchýlka. |
| $\theta$, $\hat\theta$ | Neznámy parameter a jeho odhad. |
| $\alpha$, $1-\alpha$ | Hladina významnosti a hladina spoľahlivosti. |
| $z_p$, $t_{\nu,p}$, $\chi^2_{\nu,p}$, $F_{\nu_1,\nu_2;p}$ | Kvantily normálneho, Studentovho, chí-kvadrát a F-rozdelenia; index $p$ je pravdepodobnosť **naľavo** od kvantilu. |

<a id="tyzden-1"></a>
## 1. týždeň: Pravdepodobnosť a náhodné premenné

**Podklad:** [sadr_1.pdf](sadr_1.pdf) · **Prax:** [simulácia v R](../cvicenia/README.md#tyzden-1)

### 1.1 Prečo štatisticky analyzujeme dáta

- **Čo:** Z meraní zisťujeme vlastnosti procesu a neistotu našich záverov.
- **Ako:** Položíme otázku, zozbierame porovnateľné dáta, preskúmame ich a zvolíme odhad alebo test podľa otázky.
- **Prečo:** Jedno rýchle spustenie programu môže byť náhoda. Opakované merania umožnia posúdiť, či zrýchlenie pretrváva aj pri bežnom kolísaní výkonu.

Zber a správa dát poskytujú merania; štatistika pomáha odlíšiť systematický vzor od náhodného kolísania a vyjadriť neistotu. Data mining hľadá vzory, strojové učenie vytvára predikčné modely a matematická štatistika dáva pravidlá na odhadovanie a testovanie. Jazyk R tieto postupy spája s importom, spracovaním a vizualizáciou dát; ďalšie funkcie poskytujú balíky z CRAN.

**Príklad:** Dva behy toho istého programu trvajú rôzne dlho. Samotný rozdiel časov ešte neukazuje, že nová verzia je rýchlejšia; potrebujeme opakované merania a posúdenie variability.

### 1.2 Experiment, výsledok a udalosť

- **Čo:** Rozlišujeme postup merania, jeden konkrétny výsledok a skupinu výsledkov, ktorá nás zaujíma.
- **Ako:** Pri API určíme, čo je jeden pokus, aké výsledky pripúšťame a čo presne znamená udalosť „pomalá odpoveď“.
- **Prečo:** Bez hranice, napríklad 100 ms, by „pomalá odpoveď“ nemala jednoznačný význam a jej pravdepodobnosť by sme nevedeli konzistentne počítať.

**Náhodný experiment** je opakovateľný postup s neistým výsledkom. **Pokus** je jedno vykonanie, napríklad jedna požiadavka na API. Veľkosť dát vieme kontrolovať, okamžitú záťaž siete často nie.

- $\omega$ je jeden výsledok, $\Omega$ množina všetkých výsledkov.
- Udalosť $A$ je množina výsledkov, ktoré spĺňajú zadanú podmienku.
- $\Omega$ je istá udalosť, $\varnothing$ nemožná udalosť.
- $A^c$ znamená „nenastalo A“, $A\cap B$ „nastali obe“, $A\cup B$ „nastala aspoň jedna“.
- Disjunktné udalosti sa vylučujú: $A\cap B=\varnothing$. To **nie je to isté** ako nezávislosť.

**Príklad:** Pri kocke je $\Omega=\{1,2,3,4,5,6\}$ a „padlo párne číslo“ je $A=\{2,4,6\}$. Pri čase odozvy je prirodzený priestor $[0,\infty)$ a „odozva aspoň 100 ms“ je $[100,\infty)$.

### 1.3 Tri prístupy k pravdepodobnosti

- **Čo:** Pravdepodobnosť vyjadruje mieru výskytu udalosti v zvolenom modeli.
- **Ako:** Pri rovnako možných výsledkoch počítame ich podiel, pri meraniach relatívnu početnosť; všeobecný model musí spĺňať axiómy.
- **Prečo:** Pri spravodlivej kocke poznáme šancu šestky z modelu. Pri poruchách servera ju musíme odhadnúť z dát; predpoklad rovnako pravdepodobných výsledkov by tam nemal opodstatnenie.

**Klasická pravdepodobnosť** platí pre konečný počet rovnako pravdepodobných výsledkov:

$$P(A)=\frac{|A|}{|\Omega|}.$$

Pri dvoch rozlíšiteľných spravodlivých kockách máme 36 usporiadaných dvojíc. Súčet 7 nastane pri šiestich, teda $P(A)=6/36=1/6$. Súčty 2 až 12 samy osebe nie sú rovnako pravdepodobné.

**Štatistický prístup** odhaduje pravdepodobnosť relatívnou početnosťou:

$$\hat p_n=\frac{k_n}{n}.$$

Pri nezávislom opakovaní za rovnakých podmienok sa relatívna početnosť stabilizuje pri skutočnej pravdepodobnosti; opisuje to zákon veľkých čísel. Neznamená to, že každých šesť hodov musí obsahovať jednu šestku ani že sa odchýlka zmenšuje po každom hode.

**Axiomatický prístup** stanovuje všeobecné pravidlá platné aj pre nekonečné priestory:

$$P(A)\geq0,\qquad P(\Omega)=1,\qquad
P\!\left(\bigcup_{i=1}^{\infty}A_i\right)=\sum_{i=1}^{\infty}P(A_i)
\quad\text{pre navzájom disjunktné }A_i.$$

Z toho vyplýva $P(\varnothing)=0$, $P(A^c)=1-P(A)$ a $P(A\cup B)=P(A)+P(B)-P(A\cap B)$. Pravidlá samy neurčia pravdepodobnosť poruchy konkrétneho servera; tú musí určiť model alebo merania.

### 1.4 σ-algebra, miera a pravdepodobnostný priestor

- **Čo:** Ide o rámec určujúci možné výsledky, prípustné udalosti a ich pravdepodobnosti.
- **Ako:** Zvolíme priestor výsledkov a udalosti, ktorým vieme priradiť mieru; uzavretosť na doplnky a zjednotenia umožní skladať ďalšie otázky.
- **Prečo:** Ak vieme vyhodnotiť „odozva nad 100 ms“, chceme korektne vyhodnotiť aj opačnú udalosť a kombinácie intervalov. Tento rámec drží ich pravdepodobnosti vo vzájomnom súlade.

**σ-algebra** $\mathcal S$ určuje, ktorým množinám výsledkov priraďujeme pravdepodobnosť. Obsahuje $\Omega$ a $\varnothing$ a je uzavretá na doplnky a spočítateľné zjednotenia; tým aj na spočítateľné prieniky. Umožňuje korektne skladať udalosti aj v spojitých modeloch.

**Miera** priraďuje množinám nezápornú veľkosť, prázdnej množine nulu a spĺňa spočítateľnú aditivitu. Dĺžka intervalu je príklad miery. Pravdepodobnosť je miera navyše normalizovaná podmienkou $P(\Omega)=1$.

Trojica $(\Omega,\mathcal S,P)$ tvorí **pravdepodobnostný priestor**. Pri konečnej kocke môžeme zvoliť za $\mathcal S$ všetky podmnožiny $\Omega$; pri reálnych časoch používame merateľné množiny, napríklad intervaly a ich spočítateľné kombinácie.

### 1.5 Náhodná premenná, PMF, hustota a CDF

- **Čo:** Náhodná premenná číselne opisuje výsledok; jej rozdelenie hovorí, kde a ako často očakávame hodnoty.
- **Ako:** Pri počtoch sčítame bodové pravdepodobnosti, pri spojitých časoch integrujeme hustotu. CDF priamo dá pravdepodobnosť neprekročenia hranice.
- **Prečo:** Počet chýb „presne tri“ a čas „najviac 100 ms“ sú odlišné otázky. Správny typ rozdelenia určí, či počítame body alebo plochu pod krivkou.

Náhodná premenná $X:\Omega\to\mathbb R$ priradí výsledku číslo. Musí byť merateľná: udalosť $\{\omega:X(\omega)\leq x\}$ patrí do $\mathcal S$ pre každé $x$.

**Diskrétna premenná** má konečne alebo spočítateľne veľa možných hodnôt, napríklad počet chýb. Nemusia to byť celé čísla. Jej pravdepodobnostná funkcia (PMF) spĺňa:

$$p_i=P(X=x_i),\qquad p_i\geq0,\qquad\sum_i p_i=1.$$

**Spojitá premenná s hustotou** modeluje napríklad čas. Hustota (PDF) nie je pravdepodobnosť jedného bodu; pravdepodobnosť je **plocha** pod krivkou:

$$f(x)\geq0,\quad\int_{-\infty}^{\infty}f(x)\,dx=1,\quad
P(a\leq X\leq b)=\int_a^b f(x)\,dx,\quad P(X=x)=0.$$

Hustota môže byť aj väčšia ako 1; celková plocha musí zostať 1. Obmedzenie na po častiach spojité hustoty v prednáške je praktické zjednodušenie.

**Distribučná funkcia** (CDF) funguje pre oba typy:

$$F(x)=P(X\leq x),\qquad
F(x)=\sum_{x_i\leq x}p_i\ \text{(diskrétne)},\qquad
F(x)=\int_{-\infty}^x f(t)\,dt\ \text{(s hustotou)}.$$

Je neklesajúca, sprava spojitá, s limitami 0 a 1. Všeobecne $P(a<X\leq b)=F(b)-F(a)$; pri spojitom modeli môžeme bez zmeny pravdepodobnosti zahrnúť aj bod $a$. Pri diskrétnom modeli treba na krajné body dávať pozor.

**Príklad maxima dvoch kociek:** Pre $X=\max(K_1,K_2)$ je $P(X\leq j)=j^2/36$ a $P(X=j)=[j^2-(j-1)^2]/36=(2j-1)/36$, kde $j=1,\dots,6$. Maximum 6 je pravdepodobnejšie než maximum 1.

### 1.6 Momenty: poloha, variabilita a tvar

- **Čo:** Momenty zhrnú rozdelenie pomocou čísel: kde má stred, ako veľmi kolíše a aký má tvar.
- **Ako:** Hodnoty alebo ich mocniny vážime pravdepodobnosťami; pri rozptyle počítame štvorce odchýlok od stredu.
- **Prečo:** Kladné a záporné odchýlky by sa pri obyčajnom sčítaní rušili. Umocnenie zachytí ich veľkosť, takže rozlíšime stabilný server od kolísavého aj pri rovnakom priemernom čase.

Začiatočný moment je $m'_r=E(X^r)$; centrálny moment je $m_r=E[(X-\mu)^r]$, pokiaľ existujú. Prvý začiatočný moment je stredná hodnota a druhý centrálny moment rozptyl:

$$\mu=E(X)=\sum_i x_i p_i\quad\text{alebo}\quad\int_{-\infty}^{\infty}x f(x)\,dx,$$

$$\sigma^2=\operatorname{Var}(X)=E[(X-\mu)^2]=E(X^2)-[E(X)]^2,\qquad\sigma=\sqrt{\sigma^2}.$$

Stredná hodnota je dlhodobý priemer; nemusí byť možným jednotlivým výsledkom. Rozptyl má štvorcové jednotky, smerodajná odchýlka pôvodné jednotky. Pre transformáciu platí $E(aX+b)=aE(X)+b$ a $\operatorname{Var}(aX+b)=a^2\operatorname{Var}(X)$.

### Videá k témam 1. týždňa

Všetky uvedené videá sú v angličtine; pri dlhších kurzoch sú uvedené konkrétne časti.

| Témy | Video a odporúčaná časť |
|---|---|
| Experiment, udalosti, klasická pravdepodobnosť, axiómy a spočítateľná aditivita | [MIT — Introduction to Probability](https://ocw.mit.edu/courses/res-6-012-introduction-to-probability-spring-2018/resources/lecture-videos/), časti **01.2–01.9**. |
| Pravdepodobnostný model a rozdelenie premennej | [StatQuest — Probability Distributions](https://youtu.be/oI3hZJqXJuc). |
| Distribučná funkcia a výpočet pravdepodobností | [MIT — Calculating a Cumulative Distribution Function](https://www.youtube.com/watch?v=wQ6Q9W3Y1ZE). |
| Diskrétna premenná a očakávaná hodnota | [StatQuest — Expected Values, Main Ideas](https://youtu.be/KLs_7b7SKi4). |
| Hustota, integrál a spojitá stredná hodnota | [StatQuest — Expected Values for Continuous Variables](https://youtu.be/OSPr6G6Ka-U); MIT z prvého riadka, časti **08.2–08.4**, aj pre CDF a rozptyl. |
| Momenty a rozptyl | [Z Statistics — Descriptive Statistics](https://www.zstatistics.com/descriptive-statistics), videá **Moments** a **Variance and Standard deviation**. |

[↑ Navigácia](#navigácia-podľa-týždňov)

<a id="tyzden-2"></a>
## 2. týždeň: Opisná štatistika a EDA

**Podklad:** [sadr_2.pdf](sadr_2.pdf) · **Prax:** [štatistiky a grafy v R](../cvicenia/README.md#tyzden-2)

### 2.1 Populácia, vzorka a premenné

- **Čo:** Určujeme, o kom chceme hovoriť, koho sme zmerali a aký význam majú stĺpce tabuľky.
- **Ako:** Vymedzíme populáciu, spôsob výberu, jednotku pozorovania a typ každej premennej ešte pred výpočtami.
- **Prečo:** Dotazník iba medzi študentmi nemusí opisovať príjmy všetkých obyvateľov. Ani správne vypočítaný priemer neopraví nevhodný výber ľudí alebo nesprávne chápané kódy kategórií.

**Populácia** sú všetky jednotky, o ktorých chceme hovoriť. **Výber** sú jednotky, ktoré máme zmerané. Úplné šetrenie zisťuje celú populáciu; náhodný výber umožňuje odvodiť neistotu zovšeobecnenia. Ani veľká účelovo vybraná vzorka nemusí byť reprezentatívna.

V dátovej tabuľke jeden riadok predstavuje objekt alebo pozorovanie, stĺpce jeho vlastnosti. Jednorozmerná analýza skúma jeden znak, viacrozmerná viac znakov a ich vzťahy.

| Typ premennej | Príklad | Čo má význam |
|---|---|---|
| Kvantitatívna spojitá | Čas odozvy, príjem | Rozdiely, priemer, rozptyl. |
| Kvantitatívna diskrétna | Počet požiadaviek | Početnosti, súčty, priemer. |
| Kvalitatívna nominálna | Typ databázy | Kategórie a ich početnosti, bez prirodzeného poradia. |
| Kvalitatívna ordinálna | Stupeň spokojnosti | Poradie má význam, rozostupy medzi kódmi nemusia. |

Číselný kód vzdelania je kategória, nie meraná veľkosť. Priemer kódov preto nemá rovnaký význam ako priemer príjmov.

**EDA** je prvé spoznanie dát: kontrola typov, rozsahu, chýbajúcich a odľahlých hodnôt, výpočet súhrnov a vhodné grafy. Najprv treba vedieť, čo znamená riadok, jednotka a nula. Odľahlý bod môže byť chyba aj pravdivá dôležitá informácia; automatické vymazanie nie je čistenie s odôvodnením.

### 2.2 Početnosti a triedne intervaly

- **Čo:** Zisťujeme, koľko pozorovaní patrí k jednotlivým hodnotám alebo intervalom.
- **Ako:** Zvolíme neprekrývajúce sa triedy pokrývajúce dáta, spočítame pozorovania a vydelíme ich celkovým počtom, ak chceme podiely.
- **Prečo:** Pri stovkách rôznych príjmov je zoznam hodnôt neprehľadný. Triedy ukážu koncentráciu príjmov; relatívne početnosti navyše umožnia porovnať rôzne veľké skupiny.

Po usporiadaní $x_{(1)}\leq\dots\leq x_{(n)}$ počítame absolútne početnosti $n_j$, relatívne početnosti $f_j=n_j/n$ a ich kumulatívne súčty. Pre spojité dáta ich často zoskupíme do intervalov.

Sturgesovo orientačné pravidlo pre počet tried je $k\approx1+\log_2 n\approx1+3{,}322\log_{10}n$. Pri rovnako širokých triedach je šírka $h\approx(x_{\max}-x_{\min})/k$; stred triedy je priemer jej hraníc. Príliš málo tried zakryje tvar, príliš veľa zvýrazní šum. Pri rôznych šírkach má histogram používať hustotu, aby pravdepodobnosť reprezentovala **plocha**, nie samotná výška stĺpca.

### 2.3 Miery polohy a výber správneho priemeru

- **Čo:** Hľadáme jednu hodnotu, ktorá vystihne stred dát vzhľadom na konkrétnu otázku.
- **Ako:** Pri sčítavaných veličinách používame aritmetický priemer, pri násobnom raste geometrický a pri rýchlostiach na rovnakých úsekoch harmonický; typickú prostrednú hodnotu opisuje medián.
- **Prečo:** Správny priemer musí zachovať veličinu, na ktorej záleží: celkový súčet, konečný násobný rast alebo celkový čas cesty. Jeden vzorec preto nevyhovuje všetkým situáciám.

$$\bar x=\frac1n\sum_{i=1}^n x_i,\qquad
\bar x_G=\left(\prod_{i=1}^n x_i\right)^{1/n},\qquad
\bar x_H=\frac{n}{\sum_{i=1}^n 1/x_i}.$$

- **Aritmetický priemer** zachováva celkový súčet. Hodí sa napríklad na priemernú spotrebu alebo príjem; je citlivý na extrémy a pri zmesi rôznych skupín nemusí byť typickou hodnotou.
- **Geometrický priemer** pre kladné hodnoty zachováva násobný rast. Rast príjmu z 10 000 na 12 000 a potom na 12 500 má priemerný ročný koeficient $\sqrt{1{,}2\cdot(12\,500/12\,000)}=\sqrt{1{,}25}\approx1{,}1180$, teda približne **11,80 % ročne**. Sú to dve obdobia, nie tri.
- **Harmonický priemer** používame pri sadzbách s rovnakým množstvom v čitateli. Polovica trasy rýchlosťou 20 a polovica 80 km/h dá $2/(1/20+1/80)=32$ km/h. Pri rovnakých časoch by bol vhodný aritmetický priemer. Priemerné časy jednej operácie sa bez ďalších podmienok priemerujú aritmeticky; harmonický priemer časov v príklade prednášky zodpovedá inému váženiu, napríklad podľa výkonu.

**Medián** je stred usporiadaných dát; pri párnom počte priemer dvoch stredných hodnôt. Je odolnejší voči extrémom než priemer. **Modus** je najpočetnejšia hodnota, môže ich byť viac. Pri veľmi jemne meraných spojitých dátach môže presný modus slabo vystihovať typickú hodnotu.

### 2.4 Kvantily, kvartily a odľahlé hodnoty

- **Čo:** Kvantily opisujú hranice podielov dát; pravidlo IQR vyznačuje nezvyčajne vzdialené pozorovania.
- **Ako:** Dáta usporiadame, určíme príslušné kvantily a porovnáme krajné hodnoty s hranicami odvodenými od kvartilov.
- **Prečo:** Pri odozvách nás môže viac zaujímať 95. percentil než priemer: ukáže čas, ktorý neprekročilo približne 95 % meraní. Odľahlé hodnoty potom preveríme, lebo môžu odhaliť chybu aj skutočné preťaženie.

Kvantily opisujú hranice podielov rozdelenia: $Q_1=Q_{0{,}25}$, $Q_2=Q_{0{,}5}$, $Q_3=Q_{0{,}75}$. Existuje viac výpočtových konvencií. Prednáškovému pravidlu pre vnútorné kvantily zodpovedá v R `quantile(x, type = 2)`; predvolené `type = 7` interpoluje inak. Porovnávanie výsledkov preto vyžaduje rovnakú definíciu.

$$IQR=Q_3-Q_1,\qquad\text{kvartilová odchýlka}=IQR/2.$$

Tukeyho hranice $Q_1-1{,}5IQR$ a $Q_3+1{,}5IQR$ označia potenciálne odľahlé body. Hranice s $3IQR$ označujú vzdialenejšie extrémy. Ide o diagnostické pravidlo, nie o dôkaz chyby ani formálny test s hladinou významnosti. Fúzy štandardného boxplotu siahajú po najkrajnejšie **pozorované** body v hraniciach; nemusia siahať po minimum a maximum.

### 2.5 Variabilita a tvar dát

- **Čo:** Opisujeme rozptýlenie meraní, asymetriu rozdelenia a výskyt extrémov.
- **Ako:** K polohe pridáme odchýlku alebo IQR, podľa potreby relatívnu variabilitu, šikmosť a špicatosť; výsledok porovnáme s grafom.
- **Prečo:** Priemer 100 ms môže znamenať takmer stále 100 ms aj striedanie krátkych a veľmi dlhých odoziev. Pre používateľa sú tieto procesy rozdielne; samotný priemer ich nerozlíši.

$$R=x_{\max}-x_{\min},\qquad
s^2=\frac{1}{n-1}\sum_{i=1}^n(x_i-\bar x)^2,\qquad s=\sqrt{s^2},\qquad
CV=\frac{s}{\bar x}\cdot100\%.$$

Menovateľ $n-1$ koriguje odhad populačného rozptylu, keď priemer odhadujeme z rovnakých dát. Pri opise celej konečnej populácie môže mať význam menovateľ $n$; treba vedieť, čo práve počítame. Nízky rozptyl opakovaných meraní znamená dobrú opakovateľnosť, ale nevylučuje systematickú chybu.

CV porovnáva **relatívnu** variabilitu kladných pomerových veličín s prirodzenou nulou. Pri priemere blízkom nule alebo pri teplotách v °C býva zavádzajúci. Hranice typu „10 % je málo, 25 % veľa“ závisia od oblasti.

Priemerná absolútna odchýlka od priemeru je $n^{-1}\sum_i|x_i-\bar x|$. Odlišný pojem je mediánová absolútna odchýlka $\operatorname{median}|x_i-\operatorname{median}(x)|$; R `mad()` ju štandardne ešte násobí približne 1,4826. Skratka MAD preto bez uvedenia definície nestačí.

Pre empirické centrálne momenty $m_r=n^{-1}\sum_i(x_i-\bar x)^r$:

$$g_1=\frac{m_3}{m_2^{3/2}},\qquad g_2=\frac{m_4}{m_2^2},\qquad\text{exces}=g_2-3.$$

Kladná šikmosť znamená dlhší pravý chvost, záporná ľavý. Nulová šikmosť sama nedokazuje symetriu ani normalitu. Špicatosť opisuje najmä náchylnosť k extrémnym hodnotám, nie iba výšku vrcholu. Normálne rozdelenie má teoretickú špicatosť 3 a exces 0. Balíky môžu používať rôzne korekcie výberových momentov.

### 2.6 Ktorý graf prečo používať

- **Čo:** Graf prevádza vlastnosti vzorky do obrazu, v ktorom vidíme tvar, skupiny a nezvyčajné hodnoty.
- **Ako:** Najprv určíme otázku: tvar rozdelenia, rozdiel skupín, jednotlivé merania alebo podiel pod hranicou. Až potom zvolíme graf z tabuľky.
- **Prečo:** Otázku „koľko ľudí má príjem do 1 200 €?“ zodpovie CDF priamo, zatiaľ čo na porovnanie typických príjmov viacerých skupín sa jednoduchšie číta boxplot.

| Graf | Praktická otázka a dôvod použitia | Ako ho čítať |
|---|---|---|
| Histogram | Sú príjmy sústredené pri jednej hodnote, alebo majú dlhý pravý chvost? Zachytí tvar, ktorý jeden priemer skryje. | Os x obsahuje hodnoty, os y početnosť alebo hustotu. Skontroluj citlivosť na triedy. |
| Boxplot | Ktorá skupina má vyšší typický príjem a väčšiu variabilitu? Umožňuje rýchle porovnanie skupín. | Medián, box medzi kvartilmi, fúzy a odľahlé body; neukazuje podrobne viacvrcholový tvar. |
| Husľový graf | Nie sú v jednej skupine dve odlišné podskupiny? Ukáže odhad hustoty. | Širšie miesto znamená väčšiu hustotu; vyhladenie môže pri malej vzorke vytvárať zdanlivé štruktúry. |
| Jitter | Koľko meraní sa prekrýva na rovnakej pozícii? Ukáže jednotlivé pozorovania. | Malý posun rozdelí prekrývajúce sa body; pri skupinách posúvaj najmä vodorovne, aby zostala meraná výška zachovaná. |
| Empirická CDF | Aký podiel ľudí má príjem najviac 1 200 €? Odpovedá priamo kumulatívnym podielom. | $F_n(x)=n^{-1}\sum_i\mathbf1(x_i\leq x)$; výška schodu je podiel hodnôt najviac x. |

R má základné grafické funkcie, `lattice` pre panelové grafy a `ggplot2` pre skladanie dát, mapovania estetík, geometrických vrstiev a tém. [Kód, obrázky a konkrétne interpretácie](../cvicenia/README.md#tyzden-2) sú v cvičeniach.

### Videá k témam 2. týždňa

| Témy | Video |
|---|---|
| Populácia, vzorka a opisné charakteristiky | [StatQuest — Estimating the Mean, Variance and Standard Deviation](https://youtu.be/SzZ6GpcfoQY). |
| Priemer, medián, modus, geometrický/harmonický priemer, CV, šikmosť a špicatosť | [Z Statistics — Descriptive Statistics](https://www.zstatistics.com/descriptive-statistics), samostatné videá **The Mean**, **Advanced Means**, **The Median**, **The Mode**, **Coefficient of Variation**, **Skewness**, **Kurtosis**. |
| Kvantily | [StatQuest — Quantiles and Percentiles](https://youtu.be/IFKQLDmRK0Y). |
| Početnosti, triedy a histogram | [StatQuest — Histograms](https://youtu.be/qBigTkBLU6g). |
| IQR, odľahlé hodnoty a boxplot | [StatQuest — Boxplots are Awesome](https://youtu.be/fHLhBnmwUM0). |
| Husľový graf a odhad hustoty | [Violin Plot — Simply Explained](https://www.youtube.com/watch?v=Rw00VmP--qk). |
| Histogram, hustota a empirická CDF | [TU Delft — Graphical Representation of Data](https://ocw.tudelft.nl/course-lectures/graphical-representation-data/), vložené video. |
| Import, typy premenných, EDA a grafy v R | [Penn State — Getting Started: Basic R](https://online.stat.psu.edu/stat484-485/Lesson01), vložené videá; [Posit — videá pre začiatočníkov](https://education.rstudio.com/learn/beginner/), **A Gentle Introduction to Tidy Statistics in R**. |

[↑ Navigácia](#navigácia-podľa-týždňov)

<a id="tyzden-3"></a>
## 3. týždeň: Odhady a intervaly spoľahlivosti

**Podklad:** [sadr_3.pdf](sadr_3.pdf) · **Prax:** [intervaly a bootstrap v R](../cvicenia/README.md#tyzden-3)

### 3.1 Bodový odhad a jeho vlastnosti

- **Čo:** Z konečnej vzorky odhadujeme neznámy populačný parameter; rôzne vzorky dajú rôzne výsledky.
- **Ako:** Zvolíme štatistiku, napríklad priemer, a posudzujeme jej vychýlenie, variabilitu a správanie pri rastúcom počte meraní.
- **Prečo:** Dve metódy môžu v jednej vzorke vyjsť podobne, ale pri opakovaní mať inú presnosť. Vlastnosti odhadu vysvetľujú, ktorej metóde dôverovať v dlhodobom používaní.

Náhodný výber $X_1,\dots,X_n$ v základnom modeli tvorí súbor nezávislých, rovnako rozdelených premenných (**i.i.d.**). Konkrétne merania $x_1,\dots,x_n$ sú jeho realizácia. **Štatistika** $T(X_1,\dots,X_n)$ je funkcia dát bez neznámych parametrov, sama je náhodnou premennou. Odhad pred meraním kolíše; po meraní dostaneme konkrétne číslo.

| Vlastnosť | Definícia a zmysel |
|---|---|
| Nevychýlenosť | $E(\hat\theta)=\theta$: pri opakovaní sa odhad v priemere nepomýli jedným smerom. Jediný odhad sa stále môže líšiť. |
| Konzistentnosť | Pre každé $\varepsilon>0$ platí $P(\lvert\hat\theta_n-\theta\rvert>\varepsilon)\to0$: rastúci výber približuje odhad parametru. |
| Výdatnosť/efektívnosť | V zvolenej triede odhadov má najmenší rozptyl. MVUE je nevychýlený odhad s minimálnym rozptylom medzi nevychýlenými odhadmi. |
| Dostatočnosť | Štatistika zachová všetku informáciu o danom parametri obsiahnutú vo vzorke; nejde iba o to, že „použije všetky riadky“. |

Vychýlenie je $\operatorname{Bias}(\hat\theta)=E(\hat\theta)-\theta$. Celkovú kvadratickú chybu rozkladáme na $MSE(\hat\theta)=\operatorname{Var}(\hat\theta)+\operatorname{Bias}(\hat\theta)^2$; menší bias sám osebe nemusí znamenať presnejší odhad.

### 3.2 Ako odhady hľadáme

- **Čo:** Potrebujeme pravidlo, podľa ktorého z dát vyberieme hodnotu parametra modelu.
- **Ako:** Momentová metóda zladí momenty, MLE maximalizuje vierohodnosť dát a najmenšie štvorce minimalizujú štvorce odchýlok predikcií.
- **Prečo:** Každá metóda vyjadruje iné kritérium zhody. Pri počtoch porúch môžeme zlaďovať očakávaný počet, pri predikcii času výpočtu minimalizovať chyby priamky; vhodnosť závisí od modelu a cieľa.

**Momentová metóda:** Porovnáme teoretické momenty závislé od parametrov s empirickými momentmi a vyriešime rovnice. Napríklad pri $X\sim\operatorname{Poisson}(\lambda)$ platí $E(X)=\lambda$, preto $\hat\lambda=\bar x$.

**Maximálna vierohodnosť (MLE):** Hľadáme parameter, pri ktorom majú pozorované dáta najvyššiu spoločnú pravdepodobnosť alebo hustotu. Pri nezávislých pozorovaniach:

$$L(\theta)=\prod_{i=1}^n f(x_i;\theta),\qquad
\ell(\theta)=\sum_{i=1}^n\log f(x_i;\theta),\qquad
\hat\theta_{MLE}=\operatorname*{arg\,max}_{\theta}L(\theta).$$

Pre Poissonovo rozdelenie:

$$\ell(\lambda)=\left(\sum_i x_i\right)\log\lambda-n\lambda-\sum_i\log(x_i!),\quad
\ell'(\lambda)=\frac{\sum_i x_i}{\lambda}-n=0\Rightarrow\hat\lambda=\bar x.$$

Jeho rozptyl je $\operatorname{Var}(\hat\lambda)=\lambda/n$. V normálnom modeli $N(\mu,\sigma^2)$ je $\hat\mu=\bar x$, ale **MLE rozptylu** je $n^{-1}\sum_i(x_i-\bar x)^2$, kým **nevychýlený odhad** $s^2$ má menovateľ $n-1$.

**Najmenšie štvorce (LSE):** Minimalizujeme $\sum_i(y_i-\hat y_i)^2$. Napríklad priamku času výpočtu podľa veľkosti vstupu nastavíme tak, aby mala čo najmenší súčet štvorcov zvislých odchýlok. Pri nezávislých normálnych chybách s rovnakým rozptylom sa odhad regresných koeficientov zhoduje s MLE.

**Bootstrap** numericky odhaduje neistotu už zvolenej štatistiky opakovaným výberom s vracaním; podrobne v časti 3.6.

### 3.3 Čo znamená interval spoľahlivosti

- **Čo:** Interval kvantifikuje neistotu bodového odhadu pri zvolenom modeli a hladine spoľahlivosti.
- **Ako:** Použijeme postup s určeným dlhodobým pokrytím; pri bežných intervaloch priemeru pridávame a odčítavame kritický násobok štandardnej chyby.
- **Prečo:** Rovnaký odhad 54,7 s z 20 a z 2 000 nezávislých návštev nemusíme poznať rovnako presne. Interval ukáže tento rozdiel a pomôže posúdiť, či máme dosť údajov na rozhodnutie.

Bodový odhad hovorí „priemer je 54,7 s“. Interval doplní presnosť odhadu. Náhodné hranice $L(X),U(X)$ pri správnom modeli spĺňajú:

$$P_\theta\{L(X)\leq\theta\leq U(X)\}=1-\alpha.$$

**95 % sa vzťahuje na postup:** Pri opakovanom odbere dát približne 95 % takto vytvorených intervalov obsahuje pevný skutočný parameter. Po výpočte už hranice nie sú náhodné; frekventistický interval nehovorí, že parameter má 95 % pravdepodobnosť ležať práve v tomto pevnom intervale. Tiež neobsahuje automaticky 95 % jednotlivých meraní.

Vyššia spoľahlivosť a väčšia variabilita interval rozširujú. Väčšie $n$ ho zvyčajne zužuje približne tempom $1/\sqrt n$: na polovičnú chybu potrebujeme asi štvornásobnú vzorku. **Smerodajná odchýlka** opisuje merania; **štandardná chyba** $SE(\bar X)=\sigma/\sqrt n$ opisuje kolísanie priemeru.

### 3.4 Intervaly pre strednú hodnotu

- **Čo:** Ohraničujeme populačný priemer, nie jednotlivé budúce merania.
- **Ako:** Rozlíšime známe populačné $\sigma$ a jeho odhad zo vzorky, zvolíme z- alebo t-kvantil a podľa otázky jednu alebo dve konečné hranice.
- **Prečo:** Odhad rozptylu pridáva neistotu, preto sa pri neznámom $\sigma$ používa t-rozdelenie. Pri kontrole priemernej čakacej doby môže stačiť horná hranica; pri všeobecnom odhade chceme obe.

Pre nezávislé normálne merania sú nasledujúce intervaly presné. Pri nenormálnych dátach môžu byť približné vďaka centrálnej limitnej vete; samotné pravidlo „n > 30“ nezaručuje vhodnosť pri silnej šikmosti, extrémoch alebo závislosti.

**Známa populačná odchýlka:** $Z=(\bar X-\mu)/(\sigma/\sqrt n)\sim N(0,1)$.

$$IS_\mu=\left[\bar x-z_{1-\alpha/2}\frac{\sigma}{\sqrt n},\ \bar x+z_{1-\alpha/2}\frac{\sigma}{\sqrt n}\right].$$

Jednostranná dolná hranica je $L=\bar x-z_{1-\alpha}\sigma/\sqrt n$, interval $[L,\infty)$. Horná hranica je $U=\bar x+z_{1-\alpha}\sigma/\sqrt n$, interval $(-\infty,U]$. Používame $1-\alpha$, nie $1-\alpha/2$.

**Neznáma populačná odchýlka:** Nahradíme $\sigma$ odhadom $s$ a normálny kvantil Studentovým:

$$T=\frac{\bar X-\mu}{s/\sqrt n}\sim t_{n-1},\qquad
IS_\mu=\left[\bar x-t_{n-1,1-\alpha/2}\frac{s}{\sqrt n},\ \bar x+t_{n-1,1-\alpha/2}\frac{s}{\sqrt n}\right].$$

Jednostranné intervaly získame rovnakou náhradou v predchádzajúcich vzorcoch. Studentovo rozdelenie má hrubšie chvosty, pretože navyše odhadujeme rozptyl; s rastúcim počtom stupňov voľnosti sa približuje normálnemu. Aj pre veľkú vzorku zostáva t-postup prirodzenou voľbou, ak $\sigma$ nepoznáme.

**Príklad z prednášky:** Pre 20 časov na webe je $\bar x=54{,}7$, $s\approx4{,}1052$. Pri známom $\sigma=3{,}8$ je 95 % interval približne **[53,0346; 56,3654] s**; pri neznámom $\sigma$ **[52,7787; 56,6213] s**. Ten druhý je širší.

### 3.5 Interval pre rozptyl a odchýlku

- **Čo:** Odhadujeme, ako presne poznáme variabilitu celého procesu.
- **Ako:** Výberový rozptyl prepojíme s chí-kvadrát rozdelením, vypočítame dve hranice a pri požiadavke na odchýlku ich odmocníme.
- **Prečo:** Plnička môže mať správny priemerný objem, ale príliš často výrazne podlievať alebo prelievať. Interval rozptylu pomôže posúdiť stabilitu, ktorú interval priemeru nevyjadruje.

Pri normálnych nezávislých meraniach platí $(n-1)s^2/\sigma^2\sim\chi^2_{n-1}$. Rozdelenie je nesymetrické, preto sú hranice tiež nesymetrické:

$$IS_{\sigma^2}=\left[\frac{(n-1)s^2}{\chi^2_{n-1,1-\alpha/2}},\ \frac{(n-1)s^2}{\chi^2_{n-1,\alpha/2}}\right].$$

V dolnej hranici je **väčší** kvantil v menovateli. Interval pre $\sigma$ dostaneme odmocnením oboch hraníc. Jednostranná horná hranica rozptylu je $(n-1)s^2/\chi^2_{n-1,\alpha}$, dolná $(n-1)s^2/\chi^2_{n-1,1-\alpha}$. Dolný koniec horného intervalu je 0.

**Prečo:** Pri kontrole kvality nestačí správny priemer objemu nápoja, potrebujeme aj malú variabilitu plnenia. Tento interval vyjadruje neistotu rozptylu; na odchýlky od normality je citlivejší než bežný t-interval priemeru.

### 3.6 Bootstrapové odhady neistoty

- **Čo:** Bootstrap približuje výberové kolísanie zvolenej štatistiky pomocou opakovaného prevzorkovania dát.
- **Ako:** Vytvárame rovnako veľké výbery s vracaním, pri každom znovu vypočítame štatistiku a z jej kolísania odhadneme chybu či interval.
- **Prečo:** Pre medián alebo zložitejší ukazovateľ nemusíme mať jednoduchý analytický vzorec. Prevzorkovanie vytvorí rôzne možné zloženia vzorky a ukáže citlivosť výsledku na to, ktoré hodnoty sme pozorovali.

Z pôvodných $n$ hodnôt vyberieme **s vracaním** novú vzorku rovnakej veľkosti. Vypočítame štatistiku $\hat\theta_b^*$ a opakujeme to $B$-krát, napríklad 10 000-krát. Niektoré pôvodné hodnoty sa zopakujú a iné sa v jednej vzorke neobjavia. Bez vracania by pri rovnakom rozsahu priemer zostal rovnaký.

$$\bar\theta^*=\frac1B\sum_b\hat\theta_b^*,\qquad
SE_{boot}=\sqrt{\frac1{B-1}\sum_b(\hat\theta_b^*-\bar\theta^*)^2}.$$

| Interval | Konštrukcia | Zmysel |
|---|---|---|
| Percentilový | $[q^*_{\alpha/2},q^*_{1-\alpha/2}]$ | Priamo použije kvantily bootstrapových odhadov. Definícia nevyžaduje normálny tvar, ale pri silnom biase či nevhodnej vzorke môže mať zlé pokrytie. |
| Basic, reverzný | $[2\hat\theta-q^*_{1-\alpha/2},2\hat\theta-q^*_{\alpha/2}]$ | Obráti bootstrapové chyby okolo pôvodného odhadu. |
| Interval s bootstrapovou SE z prednášky | $\hat\theta\pm t_{n-1,1-\alpha/2}SE_{boot}$ | Približný postup. Nie je totožný so studentizovaným **bootstrap-t**, ktorý prevzorkúva aj štandardizovanú štatistiku. |
| BCa | Kvantily upravené o bias a akceleráciu | Korigujú vychýlenie a asymetriu; vyžadujú ďalší výpočet. |

**Praktický príklad:** Neistota mediánu času odozvy nemá taký jednoduchý vzorec ako neistota priemeru. Bootstrap umožní sledovať, ako medián kolíše pri prevzorkovaní. Pôvodný medián je stále bodovým odhadom; priemer bootstrapových mediánov ho automaticky nenahrádza.

Bootstrap nevyžaduje zvoliť parametrické rozdelenie dát, **má však predpoklady**. Bežný bootstrap jednotlivých riadkov predpokladá vhodný nezávislý výber a reprezentatívne dáta. Neopraví výberové skreslenie ani časovú závislosť; pri časových radoch treba napríklad blokový bootstrap. Viac opakovaní zníži simulačný šum, nepridá nové informácie do malej vzorky.

### Videá k témam 3. týždňa

| Témy | Video |
|---|---|
| Bodové odhady, nevychýlenosť a výberové kolísanie | [StatQuest — Estimating the Mean, Variance and Standard Deviation](https://youtu.be/SzZ6GpcfoQY); [Why Dividing by N Underestimates the Variance](https://youtu.be/sHRBg6BhKjI). |
| Momentová metóda, MLE a ich teória | [MIT — MLE and the Method of Moments](https://ocw.mit.edu/courses/18-650-statistics-for-applications-fall-2016/resources/lecture-6-video/); intuitívne [StatQuest — Maximum Likelihood](https://youtu.be/XepXtl9YKwc). |
| Najmenšie štvorce | [StatQuest — Fitting a Line to Data](https://youtu.be/PaFPbb66DxQ). |
| Interpretácia intervalov a bootstrap | [StatQuest — Confidence Intervals](https://youtu.be/TqOeMYtOc1w); [Bootstrapping: Main Ideas](https://youtu.be/Xz0x-8-cgaQ). |
| Známe/neznáme σ, jednostranné hranice a šírka intervalu | [JB Statistics — Confidence Intervals](https://www.jbstatistics.com/category/confidence-intervals/), videá **5.3, 5.5–5.8**. |
| Interval a test rozptylu | [JB Statistics — Inference for One Variance](https://www.jbstatistics.com/introduction-to-inference-for-one-variance/), vložené video. |

[↑ Navigácia](#navigácia-podľa-týždňov)

<a id="tyzden-4"></a>
## 4. týždeň: Testovanie hypotéz

**Podklad:** [sadr_4.pdf](sadr_4.pdf) · **Prax:** [testy a výstupy R](../cvicenia/README.md#tyzden-4); [nezávislé výbery](../cvicenia/README.md#tyzden-5)

### 4.1 Čo test zisťuje a ako ho naplánovať

- **Čo:** Overujeme konkrétne tvrdenie o populácii pomocou vzorky a vopred určených pravidiel rozhodovania.
- **Ako:** Tvrdenie preložíme na parameter a hypotézy, zvolíme alternatívu, hladinu a vhodnú testovaciu štatistiku.
- **Prečo:** „Plnička funguje správne“ je nejasné: môže ísť o priemerný objem aj variabilitu. Presná hypotéza určí, aké dáta potrebujeme a čo bude výsledok vôbec znamenať.

Test posúdi, či sú pozorované dáta dostatočne nezlučiteľné s **nulovou hypotézou** $H_0$. Alternatíva $H_1$ určuje hľadaný smer alebo odlišnosť. Môžeme testovať rozdelenie, priemery, rozptyly alebo vzťahy; výber testu musí vychádzať z otázky a spôsobu zberu dát.

1. Urči parameter a nezávislosť/párovanie meraní.
2. Formuluj $H_0$, $H_1$ a vopred zvoľ $\alpha$.
3. Skontroluj predpoklady a dáta graficky.
4. Vypočítaj štatistiku a p-hodnotu alebo ju porovnaj s kritickými hranicami.
5. Uveď rozhodnutie, rozdiel v pôvodných jednotkách, interval a vecný význam.

Obojstranná alternatíva je $\theta\ne\theta_0$, pravostranná $\theta>\theta_0$, ľavostranná $\theta<\theta_0$. Smer nevyberáme až podľa nameraného rozdielu. Pri jednostrannom teste má nulová hypotéza zahŕňať opačný smer aj rovnosť; výpočet sa robí na hraničnej hodnote $\theta_0$.

### 4.2 Chyby, sila a p-hodnota

- **Čo:** Rozhodnutie testu môže byť nesprávne; p-hodnota posudzuje extrémnosť dát za nulovej hypotézy a sila schopnosť odhaliť konkrétny rozdiel.
- **Ako:** Vopred obmedzíme chybu I. druhu hladinou $\alpha$ a naplánujeme dostatočnú vzorku vzhľadom na rozdiel, ktorý má praktický význam.
- **Prečo:** Pri kontrole plničky nechceme zbytočne zastavovať správnu linku, ale ani prehliadnuť chybnú. Samotné nezamietnutie pri malej vzorke nemusí znamenať, že sme problém vylúčili.

| Skutočnosť | Nezamietneme $H_0$ | Zamietneme $H_0$ |
|---|---|---|
| $H_0$ platí | Správne rozhodnutie | Chyba I. druhu, pravdepodobnosť najviac $\alpha$. |
| Platí konkrétna alternatíva | Chyba II. druhu, pravdepodobnosť $\beta$. | Správne odhalenie, sila $1-\beta$. |

Sila závisí od skutočného rozdielu, variability, rozsahu vzorky a hladiny testu. Pri rovnakom postupe a rozsahu zníženie $\alpha$ spravidla zníži silu. Väčší výber môže pomôcť odhaliť menší rozdiel.

**P-hodnota** je pri platnosti $H_0$ pravdepodobnosť výsledku aspoň takého extrémneho, ako sme pozorovali, v smere alternatívy. Nie je to pravdepodobnosť pravdivosti $H_0$, veľkosť efektu ani pravdepodobnosť, že „výsledok vznikol náhodou“.

- $p\leq\alpha$: zamietame $H_0$ na danej hladine.
- $p>\alpha$: nezamietame $H_0$; môže ísť aj o malú silu testu.

**Nezamietnutie rovnosti nie je dôkaz rovnosti.** Významný rozdiel nemusí byť prakticky dôležitý a nevýznamný rozdiel nemusí byť zanedbateľný. Kritický obor a p-hodnota sú dva spôsoby toho istého rozhodovania pri zhodnom teste.

### 4.3 Test normality a Q-Q graf

- **Čo:** Posudzujeme, či normálny model primerane opisuje príslušné dáta alebo chyby následnej analýzy.
- **Ako:** Porovnáme kvantily s normálnymi kvantilmi a doplníme Shapirov–Wilkov test; vyberieme správny objekt diagnostiky, napríklad rozdiely pri pároch.
- **Prečo:** Referenčné t- a chí-kvadrát výpočty sa opierajú o modelové predpoklady. Silne šikmé časy môžu najmä pri malej vzorke viesť k inej skutočnej chybovosti, než sľubuje použitý test.

Parametrické postupy často vychádzajú z normálneho modelu. Q-Q graf porovnáva výberové kvantily s teoretickými normálnymi kvantilmi; približná priamka podporuje použiteľnosť modelu, systematické zakrivenie odhaľuje odchýlky. **Shapirov–Wilkov test** má $H_0$: populácia je normálne rozdelená; $H_1$: nie je.

Malá p-hodnota ukazuje nesúlad s normalitou. Veľká ju nedokazuje; malá vzorka nemusí odhaliť problém a veľká môže odhaliť aj nepodstatnú odchýlku. Pri párovom teste kontrolujeme **rozdiely**, pri ANOVA chyby v skupinách alebo rezíduá, nie bezmyšlienkovite všetky zmiešané hodnoty naraz. Neparametrické testy majú tiež predpoklady; nie sú automatickým riešením akejkoľvek nenormality.

### 4.4 Jeden priemer: z-test a t-test

- **Čo:** Zisťujeme, či je populačný priemer zlučiteľný so zadanou hodnotou, napríklad 55 s.
- **Ako:** Rozdiel medzi výberovým a referenčným priemerom vydelíme štandardnou chybou a posúdime ho v z- alebo t-rozdelení podľa znalosti $\sigma$.
- **Prečo:** Odchýlka jednej sekundy má inú výpovednú hodnotu pri presnom a pri veľmi neistom odhade. Štandardizácia vyjadrí rozdiel v jednotkách jeho neistoty, nie iba v sekundách.

Pre $H_0:\mu=\mu_0$ pri známom populačnom $\sigma$:

$$Z=\frac{\bar x-\mu_0}{\sigma/\sqrt n},\qquad
p_{obojs.}=2[1-\Phi(|Z|)].$$

Zamietame pri $|Z|\geq z_{1-\alpha/2}$; jednostranne pri $Z\geq z_{1-\alpha}$ alebo $Z\leq z_\alpha$. Známe $\sigma$ musí pochádzať z nezávislej informácie o populácii, nie z `sd()` tej istej vzorky.

Pri neznámom $\sigma$ používame:

$$T=\frac{\bar x-\mu_0}{s/\sqrt n}\sim t_{n-1}\quad\text{za }H_0.$$

Kritické hodnoty a p-hodnoty počítame z t-rozdelenia. Pre obojstranný test je podmienkou zamietnutia $|T|\geq t_{n-1,1-\alpha/2}$; absolútna hodnota je nevyhnutná.

**Príklad:** Pri časoch na webe a $\mu_0=55$ vyjde z-test $p\approx0{,}7240$, t-test $p\approx0{,}7474$. Na hladine 0,05 rozdiel nepreukážeme. Netvrdíme, že skutočný priemer je presne 55 s.

**Pozor na „aspoň“:** Na hľadanie dôkazu $\mu>58$ testujeme $H_0:\mu\leq58$ proti $H_1:\mu>58$. Na overovanie, či sa reklamované „aspoň 58 s“ porušuje, je otázka opačná: $H_0:\mu\geq58$ proti $H_1:\mu<58$. Nezamietnutie prvého testu nedokazuje, že používatelia trávia menej ako 58 s.

### 4.5 Jeden rozptyl: chí-kvadrát test

- **Čo:** Overujeme referenčnú hodnotu populačného rozptylu alebo jeho prekročenie.
- **Ako:** Výberový rozptyl vztiahneme k referenčnému rozptylu a pomocou chí-kvadrát rozdelenia posúdime, či je pomer neobvykle veľký alebo malý.
- **Prečo:** Pri senzore nemusí byť problémom priemerná odchýlka, ale nestabilné meranie. Preto otázka „meria dostatočne konzistentne?“ vyžaduje test variability, nie test priemeru.

Pri normálnych nezávislých pozorovaniach testujeme $H_0:\sigma^2=\sigma_0^2$ štatistikou:

$$Q=\frac{(n-1)s^2}{\sigma_0^2}\sim\chi^2_{n-1}.$$

Obojstranne zamietame pri $Q\leq\chi^2_{n-1,\alpha/2}$ alebo $Q\geq\chi^2_{n-1,1-\alpha/2}$. Pri $H_1:\sigma^2>\sigma_0^2$ používame horný chvost, pri menšom rozptyle dolný. Príklad: overenie, či variabilita plničky neprekročila povolenú hodnotu, aj keď je priemer správny.

Nezamieňaj s chí-kvadrát testom zhody početností: má podobnú referenčnú distribúciu, ale inú hypotézu a štatistiku.

### 4.6 Párové výbery

- **Čo:** Porovnávame dve merania patriace tomu istému objektu alebo inak vopred zodpovedajúcim si objektom.
- **Ako:** Pre každý pár vytvoríme rozdiel a testujeme jeho priemer; zachováme správne párovanie a skontrolujeme rozdielové dáta.
- **Prečo:** Pri hodnotení tréningu nás zaujíma zmena každého žiaka. Odčítanie môže odstrániť stabilné rozdiely medzi rýchlejšími a pomalšími žiakmi, ktoré by v nezávislom porovnaní zväčšovali šum.

Párovanie vzniká zo spôsobu merania: pred a po na rovnakom človeku, dva algoritmy na rovnakých vstupoch. Pre $D_i=X_i-Y_i$ riešime jeden priemer rozdielov:

$$T=\frac{\bar D-\delta_0}{s_D/\sqrt n}\sim t_{n-1}.$$

**Prečo párovať:** Individuálne rozdiely sa odčítajú, takže systematickú zmenu často vidíme presnejšie. Ak zmeriam rýchlosť žiakov pred tréningom a po ňom, nechcem rozdiel medzi dvoma náhodne zostavenými triedami.

Nezávislé majú byť páry navzájom. Pre presný malovýberový test predpokladáme normalitu rozdielov, nie každého merania osobitne. Znamienko rozdielu určuje smer alternatívy; pre $D=pred-po$ znamená kladný rozdiel skrátenie času.

### 4.7 Dva nezávislé výbery: rozptyly a priemery

- **Čo:** Porovnávame dve populácie, pričom merania medzi skupinami netvoria páry.
- **Ako:** F-test rieši rozptyly; priemery porovnáva združený t-test pri spoločnom rozptyle alebo Welchov test bez tohto predpokladu.
- **Prečo:** Pri dodávateľoch nás môže zaujímať rýchlosť aj spoľahlivosť dodávok. Rozdiel priemerov a rozdiel variability sú samostatné otázky; nesmieme jednu zameniť za druhú.

**F-test rozptylov** pre dve nezávislé normálne populácie používa $F=s_X^2/s_Y^2\sim F_{n_X-1,n_Y-1}$ za $H_0:\sigma_X^2=\sigma_Y^2$. Obojstranne sú kritické oba chvosty s hladinou $\alpha/2$. Ak pomer obrátime, musíme obrátiť aj stupne voľnosti; na obojstranný test nemožno mechanicky použiť horný kvantil $1-\alpha$.

**Združený t-test** predpokladá spoločný populačný rozptyl:

$$s_p^2=\frac{(n_X-1)s_X^2+(n_Y-1)s_Y^2}{n_X+n_Y-2},\qquad
T=\frac{\bar X-\bar Y-\delta_0}{s_p\sqrt{1/n_X+1/n_Y}}\sim t_{n_X+n_Y-2}.$$

**Welchov t-test** spoločný rozptyl nevyžaduje:

$$T=\frac{\bar X-\bar Y-\delta_0}{\sqrt{s_X^2/n_X+s_Y^2/n_Y}},\qquad
\nu\approx\frac{(s_X^2/n_X+s_Y^2/n_Y)^2}{(s_X^2/n_X)^2/(n_X-1)+(s_Y^2/n_Y)^2/(n_Y-1)}.$$

V R sa $\nu$ ponecháva **desatinné**. Zaokrúhľovanie nadol v tabuľkovom výpočte je len konzervatívne zjednodušenie. Welchov test je rozumná predvolená voľba aj vtedy, keď rozptyly môžu byť podobné; samotné nezamietnutie F-testu ich rovnosť nedokazuje. Predbežné testovanie rozptylov nie je povinná podmienka použitia Welcha.

**Príklad:** Dvaja dodávatelia majú rôznu variabilitu dodacích lehôt. Otázka „ktorý má stabilnejšie dodávky?“ patrí rozptylom; otázka „líšia sa priemerné lehoty?“ patrí Welchovmu testu. Odpovede môžu byť odlišné.

### Videá k témam 4. týždňa

| Témy | Video |
|---|---|
| Nulová a alternatívna hypotéza, rozhodovanie | [StatQuest — Hypothesis Testing and the Null Hypothesis](https://youtu.be/0oc49DyA3hU). |
| P-hodnota, kritické oblasti a chyby interpretácie | [StatQuest — p-values](https://youtu.be/vemZtEM63GY); [How to Calculate p-values](https://youtu.be/JQc3yx0-Q9E). |
| Chyby a sila testu | [StatQuest — Statistical Power](https://youtu.be/Rsc5znwR5FA). |
| Normalita a Q-Q graf | [Matthew E. Clapham — Shapiro-Wilk Test](https://www.youtube.com/watch?v=eh9eYLBecWk); [StatQuest — QQ Plots](https://youtu.be/okjYjClSjOg). |
| Z-test, t-test a jednostranné alternatívy | [JB Statistics — Hypothesis Testing](https://www.jbstatistics.com/category/hypothesis-testing/), príslušné vložené videá. |
| Jeden rozptyl a F-test dvoch rozptylov | [JB Statistics — Variances](https://www.jbstatistics.com/category/variances/), videá **10.1–10.4**. |
| Párový, združený a Welchov t-test | [StatQuest — Which t-test to Use](https://youtu.be/nnBJeb_I-q8); [JB Statistics — Inference for Two Means](https://www.jbstatistics.com/category/inference-for-two-means/), párové a Welchove postupy. |

[↑ Navigácia](#navigácia-podľa-týždňov)

<a id="tyzden-5"></a>
## 5. týždeň: ANOVA a porovnávanie skupín

**Podklad:** [sadr_5.pdf](sadr_5.pdf) · **Prax:** [ANOVA, post-hoc testy a interakcie v R](../cvicenia/README.md#tyzden-5)

### 5.1 Prečo ANOVA a čo vyžaduje

- **Čo:** Jedným spoločným testom posudzujeme rovnosť priemerov viacerých nezávislých skupín.
- **Ako:** Merania rozdelíme podľa faktora, preveríme modelové predpoklady a porovnáme medziskupinovú variabilitu s variabilitou vnútri skupín.
- **Prečo:** Pri troch druhoch materiálu nechceme vyberať významnú dvojicu zo série neupravených testov. Spoločný test dá prvú kontrolovanú odpoveď, či sa vôbec niektorý priemer líši.

Ak porovnávame priemery viacerých skupín, séria neupravených dvojvýberových testov zvyšuje pravdepodobnosť aspoň jedného falošného nálezu. ANOVA najprv rieši jednu spoločnú otázku:

$$H_0:\mu_1=\cdots=\mu_k,\qquad H_1:\exists i,j:\mu_i\ne\mu_j.$$

**Príklad:** Líši sa priemerný príjem medzi troma kategóriami vzdelania? Faktor je vzdelanie, jeho úrovne sú kategórie a závislá premenná je číselný príjem. ANOVA testuje **priemery**, hoci v názve má rozptyl.

Klasický model vyžaduje nezávislé pozorovania, približne normálne chyby v skupinách a spoločný rozptyl. Nezávislosť je vlastnosť návrhu zberu, neoverí ju Shapirov test. Kontrolujeme skupinové grafy, rezíduá a homogenitu rozptylov. Nevyvážený dizajn má rôzne počty pozorovaní v skupinách; v kombinácii s rôznymi rozptylmi je obzvlášť problematický.

### 5.2 Jednofaktorový model a rozklad variability

- **Čo:** Rozlišujeme rozdiely medzi skupinovými priemermi a náhodné kolísanie meraní v rámci rovnakej skupiny.
- **Ako:** Celkový súčet štvorcov rozdelíme na skupinovú a reziduálnu časť, upravíme ich stupňami voľnosti a vytvoríme F-pomer.
- **Prečo:** Za rovnosti priemerov oba priemerné štvorce odhadujú spoločný rozptyl chýb. Skutočné rozdiely priemerov zväčšujú najmä medziskupinovú časť, čo umožní odlíšiť systematický rozdiel od šumu.

$$Y_{ij}=\mu+\alpha_i+\varepsilon_{ij},\qquad\varepsilon_{ij}\overset{iid}{\sim}N(0,\sigma^2).$$

Parameter $\alpha_i$ predstavuje efekt skupiny. Pre jednoznačnosť parametrov volíme obmedzenie, napríklad $\sum_i\alpha_i=0$, alebo referenčnú kategóriu. Pri nevyváženom dizajne treba rozlišovať nevážený priemer skupinových priemerov a celkový priemer vážený počtami.

S označením $\bar y_i$ pre skupinový a $\bar y$ pre celkový výberový priemer:

$$S_T=\sum_i\sum_j(y_{ij}-\bar y)^2,\qquad
S_A=\sum_i n_i(\bar y_i-\bar y)^2,\qquad
S_E=\sum_i\sum_j(y_{ij}-\bar y_i)^2,\qquad S_T=S_A+S_E.$$

Sú to **súčty štvorcov**, nie samy osebe odhady rozptylu. Na porovnanie ich delíme stupňami voľnosti:

$$MS_A=\frac{S_A}{k-1},\qquad MS_E=\frac{S_E}{n-k},\qquad
F=\frac{MS_A}{MS_E}\sim F_{k-1,n-k}\quad\text{za }H_0.$$

Ak sú skupinové rozdiely veľké v porovnaní s vnútroskupinovým šumom, F rastie. Nespoliehame sa na samotné porovnanie $S_A$ a $S_E$, pretože majú rôzne stupne voľnosti.

| Zdroj | Stupne voľnosti | Súčet štvorcov | Priemerný štvorec | Test |
|---|---|---|---|---|
| Faktor | $k-1$ | $S_A$ | $MS_A$ | $F=MS_A/MS_E$ |
| Rezíduá | $n-k$ | $S_E$ | $MS_E$ | Referenčná variabilita |
| Celkom | $n-1$ | $S_T$ | — | — |

Zamietame pri $F\geq F_{k-1,n-k;1-\alpha}$ alebo $p\leq\alpha$. Výsledok hovorí, že sa líši aspoň jeden priemer; neurčí konkrétne dvojice a sám nedokazuje príčinný vplyv vzdelania na príjem.

### 5.3 Bartlettov a Leveneov test rozptylov

- **Čo:** Posudzujeme, či je predpoklad spoločného rozptylu skupín primeraný.
- **Ako:** Pri dobre odôvodnenom normálnom modeli použijeme Bartlettov test; Leveneov test porovnáva absolútne odchýlky od skupinového centra a jeho mediánová verzia je robustnejšia.
- **Prečo:** Rovnaký rozdiel priemerov môže mať inú neistotu v pokojnej a v silne kolísavej skupine. Diagnostika upozorní, keď by spoločný odhad šumu túto odlišnosť zakryl.

Oba testujú $H_0:\sigma_1^2=\cdots=\sigma_k^2$ proti odlišnosti aspoň jednej dvojice.

**Bartlettov test** je účinný pri normálnych dátach, ale citlivý na nenormalitu. Pre $s_p^2=\sum_i(n_i-1)s_i^2/(n-k)$:

$$C=1+\frac{\sum_i1/(n_i-1)-1/(n-k)}{3(k-1)},\qquad
B=\frac{(n-k)\log s_p^2-\sum_i(n_i-1)\log s_i^2}{C}\approx\chi^2_{k-1}.$$

**Leveneov test** porovnáva absolútne odchýlky $z_{ij}=|y_{ij}-c_i|$ od skupinového centra. Pôvodná verzia používa priemer, robustnejšia Brownova–Forsythova verzia medián. Na hodnoty $z$ aplikuje F-porovnanie medzi skupinami:

$$W=\frac{\sum_i n_i(\bar z_i-\bar z)^2/(k-1)}{\sum_i\sum_j(z_{ij}-\bar z_i)^2/(n-k)}.$$

Pri približne rovnakých rozptyloch nemajú byť skupinové absolútne odchýlky systematicky rôzne. Mediánová verzia je menej citlivá na odľahlé hodnoty a nenormalitu. [NIST vysvetľuje rozdiely medzi verziami](https://www.itl.nist.gov/div898/handbook/eda/section3/eda35a.htm).

**Praktická otázka:** Majú diéty podobne rozptýlené hodnoty cholesterolu? Ak nie, priemery porovnáme Welchovou ANOVA, aby sme nespoliehali na spoločný rozptyl. Veľká p-hodnota diagnostického testu nie je dôkazom splnenia predpokladu.

### 5.4 Keď predpoklady nesedia

- **Čo:** Hľadáme postup zodpovedajúci skutočným vlastnostiam dát aj pôvodnej otázke.
- **Ako:** Pri nerovnakých rozptyloch zvážime Welcha, pri vhodnej otázke o poradí Kruskalov–Wallisov test a pri odôvodnenej zmene škály transformáciu.
- **Prečo:** Výmena metódy mení predpoklady a niekedy aj testovanú vlastnosť. Pri šikmých príjmoch preto nemožno automaticky vyhlásiť test poradí za test toho istého priemeru ako pri ANOVA.

- **Welchova ANOVA:** Porovnáva priemery bez predpokladu rovnakých rozptylov. Stále potrebuje nezávislé merania a primeranú použiteľnosť normálnej aproximácie.
- **Kruskalov–Wallisov test:** Používa poradia na porovnanie rozdelení nezávislých skupín. Ako test polohy/mediánov ho interpretujeme pri porovnateľných tvaroch a rozptyloch; nie je všeobecne testom rovnosti priemerov.
- **Transformácia:** Napríklad logaritmus môže zmierniť šikmosť a rozdiely rozptylov. Musíme potom interpretovať výsledok na transformovanej škále a rešpektovať definičný obor, pri logaritme kladné hodnoty.

Welchova ANOVA používa váhy $w_i=n_i/s_i^2$, $W=\sum_iw_i$ a vážený priemer $\bar y_w=\sum_iw_i\bar y_i/W$. Ak $A=\sum_i(1-w_i/W)^2/(n_i-1)$, potom:

$$F_W=\frac{\sum_iw_i(\bar y_i-\bar y_w)^2/(k-1)}{1+2(k-2)A/(k^2-1)},\qquad
\nu_1=k-1,\quad\nu_2=\frac{k^2-1}{3A}.$$

### 5.5 Post-hoc testy: ktoré skupiny sa líšia

- **Čo:** Spresňujeme spoločný výsledok ANOVA na konkrétne rozdiely skupín.
- **Ako:** Zvolíme rodinu porovnaní a metódu zodpovedajúcu rozptylom; čítame rozdiely, simultánne intervaly a upravené p-hodnoty.
- **Prečo:** Pri troch kategóriách vzdelania môže rozdiel vytvárať hlavne tretia kategória. Post-hoc test určí podporené dvojice a zároveň zohľadní, že sme sa pýtali na viac rozdielov naraz.

**Prečo:** Po spoločnom náleze potrebujeme porovnania dvojíc, ktoré zohľadnia násobné testovanie. FWER je pravdepodobnosť aspoň jednej chyby I. druhu v celej rodine porovnaní.

- **Tukey HSD / Tukey–Kramer:** Pre dvojice pri spoločnom rozptyle, pri nerovnakých počtoch upravené štandardné chyby. Interval rozdielu je:

$$\bar y_i-\bar y_j\ \pm\ q_{k,n-k;1-\alpha}\sqrt{\frac{MS_E}{2}\left(\frac1{n_i}+\frac1{n_j}\right)}.$$

- **Scheffého test:** Chráni celú rodinu lineárnych kontrastov, nielen párové rozdiely. Pri samotných dvojiciach býva konzervatívnejší. Pre dvojicu nahrádza kritický násobok hodnotou $\sqrt{(k-1)F_{k-1,n-k;1-\alpha}}$ pri štandardnej chybe $\sqrt{MS_E(1/n_i+1/n_j)}$.
- **Gamesov–Howellov test:** Vhodný pre dvojice po Welchovej ANOVA. Používa výberové rozptyly každej dvojice, Welchove stupne voľnosti a studentizované rozpätie; nepoužíva spoločný $MS_E$.

V tabuľke čítame odhad rozdielu, interval a **upravenú p-hodnotu**. Ak interval rozdielu obsahuje nulu, na danej hladine rozdiel nepreukážeme. Neznamená to, že skupiny sú totožné. Prekryv dvoch samostatných intervalov priemerov tento postup nenahrádza.

### 5.6 Miery efektu: aký veľký je rozdiel

- **Čo:** Kvantifikujeme veľkosť rozdielu alebo podiel variability priradenej faktoru.
- **Ako:** Popri p-hodnote uvedieme rozdiely v pôvodných jednotkách a vhodnú mieru, napríklad etu alebo omegu, s interpretáciou pre daný odbor.
- **Prečo:** Pri obrovskej vzorke môže byť významné aj zrýchlenie o zanedbateľný zlomok sekundy. Miera efektu pomôže odlíšiť ľahko detegovateľný nález od zmeny užitočnej v praxi.

$$\eta^2=\frac{S_A}{S_T},\qquad
\eta_p^2=\frac{S_A}{S_A+S_E},\qquad
\omega^2=\frac{S_A-(k-1)MS_E}{S_T+MS_E}\quad\text{(jednofaktorový model)}.$$

$\eta^2$ vyjadruje podiel výberovej variability priradenej faktoru; v jednofaktorovom modeli sa rovná parciálnej ete. Pri viacerých faktoroch parciálna eta vynecháva ostatné zdroje variability. $\omega^2$ koriguje optimizmus odhadu; môže vyjsť mierne záporná, čo sa prakticky často interpretuje ako efekt blízky nule.

Orientačné prahy pre etu 0,01/0,06/0,14 sa označujú ako malý/stredný/veľký efekt, ale odborový význam musí posúdiť kontext. Miery efektu sú odhady s neistotou; nie sú úplne nezávislé od vlastností vzorky.

**Príklad:** V cvičných príjmoch vychádza $\eta^2\approx0{,}616$. Približne 61,6 % výberovej variability príjmu je v tomto jednofaktorovom rozklade medzi kategóriami vzdelania. Neznamená to, že vzdelanie spôsobuje 61,6 % príjmu jednotlivca.

### 5.7 Dvojfaktorová ANOVA a interakcie

- **Čo:** Skúmame dva faktory súčasne a zisťujeme, či účinok jedného závisí od úrovne druhého.
- **Ako:** Porovnáme kombinácie faktorov, zostavíme aditívny model alebo model s interakciou a rozdiely posúdime spolu s interakčným grafom a diagnostikou.
- **Prečo:** Zložité UI môže pri dobrej sieti fungovať podobne ako jednoduché, ale pri vysokej latencii výrazne zaostávať. Priemer cez obe siete by skryl podmienku, v ktorej je problém najväčší.

Bez interakcie sú účinky aditívne:

$$Y_{ijp}=\mu+\alpha_i+\beta_j+\varepsilon_{ijp}.$$

S interakciou:

$$Y_{ijp}=\mu+\alpha_i+\beta_j+(\alpha\beta)_{ij}+\varepsilon_{ijp}.$$

Testujeme nulovosť efektu A, efektu B a v druhom modeli aj všetkých interakčných členov. V R `y ~ A + B` označuje aditívny model; `y ~ A * B` sa rozvinie na `A + B + A:B`. Interakcia znamená, že **rozdiel medzi úrovňami A závisí od úrovne B**, nie všeobecne násobenie meraní.

**Príklad bez výraznej interakcie:** Laborant a chromatograf môžu každý systematicky posúvať výsledok DEG. Model skúma oba faktory naraz. Nezamietnutie interakcie však nedokazuje, že je presne nulová.

**Príklad s interakciou:** Pri nízkej latencii je priemerný čas jednoduchého/zložitého UI približne 15,42/17,39 s; pri vysokej 24,02/45,81 s. Rozdiel UI sa zväčší z približne 1,97 na 21,80 s. Jediné tvrdenie „UI spomaľuje o X sekúnd“ by tento vzor skrylo.

V týchto konkrétnych dátach však Leveneov test odhalí rozdielne rozptyly buniek ($p\approx0{,}0073$). Sú preto dobrým príkladom interakčného vzoru aj potreby diagnostiky: klasickú F-p-hodnotu nemožno vydávať za výsledok s overenou homogenitou. Vecný vzor priemerov zostáva viditeľný; pre formálne závery treba zohľadniť nerovnaké rozptyly.

**Interakčný graf:** Na osi x je faktor A, každá čiara úroveň faktora B, na osi y skupinový priemer. Rovnobežné čiary zodpovedajú podobným rozdielom; neparalelnosť naznačuje interakciu. Čiary sa nemusia pretínať. Samotný graf neurčuje štatistickú významnosť, tú posúdi model a neistota.

Ak je interakcia významná, interpretujeme prednostne konkrétne kombinácie a jednoduché účinky; priemerné hlavné účinky nemajú byť jediným záverom. Na samostatný odhad chyby a plnej interakcie potrebujeme vhodné opakovania v kombináciách faktorov.

V ortogonálnom vyváženom dizajne je $S_T=S_A+S_B+S_{AB}+S_E$; bez interakcie odpadne $S_{AB}$. Pri nevyvážených dátach závisí prisúdenie súčtov štvorcov od typu analýzy. Predvolená `aov()` používa sekvenčné súčty štvorcov, takže záleží aj na poradí faktorov. To je relevantné pre `anova1.xlsx`, kde sa počty v bunkách líšia.

### Videá k témam 5. týždňa

| Témy | Video |
|---|---|
| Princíp ANOVA, rozklad variability a F-test | [StatQuest — t-tests and ANOVA](https://youtu.be/NF5_btOaCig); [JB Statistics — One-Way ANOVA](https://www.jbstatistics.com/category/anova/), úvod, vzorce a príklad. |
| Predpoklady jednofaktorovej ANOVA | [University of Amsterdam — Assumptions and F-test](https://video.uva.nl/media/5.2%2BOne-way%2BANOVA%2B-%2BAssumptions%2Band%2BF-test%2B%7C%2BInferential%2BStatistics%2B%7C%2BAnalysis%2Bof%2Bvariance%2B%7C%2BUvA/0_h7ob59fi). |
| Bartlettov a Leveneov test | [Dragonfly Statistics — Bartlett Test in R](https://www.youtube.com/watch?v=CMPn0eJ1zqs); [Levene's Test — Explained Simply](https://www.youtube.com/watch?v=AjybNw-gAns). |
| Kruskalov–Wallisov test ako alternatíva | [Intellectus — video Kruskal Wallis Test](https://www.intellectus360.com/video-tutorials.html), príslušné vložené video. |
| Welchova ANOVA a Games–Howell | [Todd Grande — Brown-Forsythe and Welch Tests](https://www.youtube.com/watch?v=n4FhXAMSbco); [Games-Howell Post Hoc Test](https://www.youtube.com/watch?v=oagLeAOaevk). Videá používajú SPSS, princíp platí aj v R. |
| Tukeyho a Scheffého porovnania | [Post-Hoc Tests Explained](https://www.youtube.com/watch?v=qBSsuXvVN2Q). |
| Dva faktory, interakcie, grafy a miery efektu | [TileStats — Two-way ANOVA: Basics and Interaction](https://www.youtube.com/watch?v=9yIobRrZAyg); [Two-way ANOVA — videá s R](https://lbelzile.github.io/experimental/example/twowayanova.html), najmä **Interaction plot**, **Effect size and power**. |

[↑ Navigácia](#navigácia-podľa-týždňov)

## Zdroje a presnosť interpretácie

Hlavný obsah tvorí vysvetlenie lokálnych prednášok, nie prepis videí. Odkazy na videá boli vyhľadané 28. 10. 2026, prednostne cez [oficiálny index StatQuest](https://statquest.org/video_index.html), [JB Statistics](https://www.jbstatistics.com/) a univerzitné zdroje. Stránky kurzov obsahujú konkrétne vložené videá; nejde o odkazy na výsledky vyhľadávania.

Zhrnutie spresňuje niektoré zjednodušenia a preklepy v podkladoch: rozdiel medzi MLE a nevychýleným rozptylom, jednostranné kvantily, absolútne hodnoty v obojstranných testoch, význam nezamietnutia hypotézy, predpoklady bootstrapu a interpretáciu interakcií. Implementáciu potvrdzuje dokumentácia R: [t.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html), [shapiro.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/shapiro.test.html), [aov](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/aov.html).
