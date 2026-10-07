# ako vypracovat zadania v sadr

tento navod zachytava styl dohodnuty pri vypracovani a upravach zadania 2. aktualne poziadavky z tejto session maju prednost pred starsimi prikladmi kodu, v ktorych sa este objavuju pomocne funkcie.

## podklady a postup pred pracou

1. precitaj zadanie, pozri dataset a prislusnu prednasku.
2. precitaj pdf aj r skript z cvicenia a pouzi kniznice, funkcie a postupy, ktore sa na nom preberali.
3. pozri predchadzajuce vypracovanie ako vzor stylu, ale respektuj neskorsie opravy a preferencie.
4. pred riesenim strucne zhrn, co bude obsahovat kazda poduloha, a vyziadaj si podstatne upresnenia.
5. pred vytvorenim, upravou, vymazanim alebo formatovanim suboru zhrn zmeny a vyziadaj si schvalenie podla pouzivatelskych pokynov v `AGENTS.md`.
6. po schvaleni vykonaj dohodnute zmeny a overenie; na rovnaky schvaleny rozsah sa nepytaj znova.

na otazky pouzi `AskUserTool`, ak je dostupny, inak dostupny nastroj na otazky. pri zapise mimo povoleneho pracovneho priecinka pouzi aj schvalenie vyzadovane prostredim.

referencie z tejto session:

- `cvicenia/03/SADR3.R`: vzor kratkeho priameho kodu.
- `cvicenia/03/SADR3.pdf`: postupy a vysledky z cvicenia.
- `prednasky/sadr_3.pdf`: teoria k intervalom spolahlivosti.
- `zadania/01/Zadanie1_Bagin.R`: usporiadanie analyzy a komentovanie konkretnych vysledkov.
- `zadania/02/zadanie2_bagin.R`: aktualny vzor so zapracovanymi opravami.

## celkovy styl kodu

pis priame vypracovanie zadania, nie vseobecny program na spracovanie lubovolnych dat. jednotlivy blok ma obsahovat potrebne vypocty, vypis vysledkov, pripadny graf a kratky zaver.

- nedefinuj vlastne funkcie cez `function()` ani anonymne funkcie.
- pouzivaj existujuce funkcie z r a kniznic z cvicenia.
- opakovane vypocty ries jednoduchym cyklom `for`, ak tym kod skratis.
- pri `tapply()` alebo `lapply()` pouzi existujucu funkciu namiesto novej anonymnej funkcie.
- odstran pomocne funkcie na formatovanie textu, nadpisov a vystupov.
- nepouzivaj `sekcia()`, `cat()` ani `print()`.
- pis co najmenej potrebneho kodu; suvisiace riadky drz pri sebe.
- pouzi jednoduche nazvy ako `data`, `spotreba`, `priemer`, `is_t`, `normalita` a `intervaly`.
- bez potreby nepridavaj zlozite hladanie ciest, univerzalne validacie ani automaticku instalaciu balikov.
- zjednodusenie kodu nesmie odstranit podulohy alebo podstatne vysledky zadania.

komentare, vlastne nazvy premennych, nadpisy a popisy grafov pis malymi pismenami a bez diakritiky. zachovaj presny zapis nazvov suborov, kniznic, existujucich funkcii a konstant, napriklad `Kontajner_spotreba.xlsx`, `Rmisc`, `group.CI()` alebo `TRUE`.

## nadpisy a clenienie

nadpis zapis pomocou `#' #`; podnadpis pomocou `#' ##`. bezprostredne pred kazdym nadpisom musi byt prazdny komentar `#'`.

```r
#'
#' # 1. import a uprava dat
data <- as.data.frame(readxl::read_xlsx("Kontajner_spotreba.xlsx"))
names(data) <- tolower(names(data))
head(data)
colSums(is.na(data))

#'
#' # 2. priprava premennych
data$hodina <- factor(format(data$cas, "%H", tz = "UTC"))

#'
#' # 3. intervaly spolahlivosti
#'
#' ## hodiny dna
intervaly$hodina
```

hlavne casti usporiadaj podla poduloh zadania. vnutri nich oddel jednotlive premenne, casove dimenzie alebo porovnania; nepouzivaj dlhe oddelovace a vypisovane textove sekcie.

## vypisovanie vysledkov

vypis priamo premennu alebo vyraz. neobaluj ho do `print()` a nevytvaraj textove vypisy cez `cat()`.

```r
head(data)
summary(spotreba)
mean(spotreba)
sd(spotreba)
shapiro.test(sample(spotreba, 5000))
is_t
normalita$mesiac
intervaly$mesiac
```

aj grafy zapis priamo:

```r
ggplot(graf_data, aes(skupina, priemer, ymin = dolna, ymax = horna)) +
  geom_pointrange() +
  theme_minimal()
```

pri spustani celeho skriptu v rstudio pouzi **source with echo**, aby sa priame vystupy aj grafy zobrazili. pri overovani mimo rstudio nastav zobrazenie vysledkov v spustacom prikaze, nepridavaj kvoli tomu `print()` do riesenia.

```r
source("zadanie2_bagin.R", echo = TRUE)
```

## komentovanie zaverov

na zavery pouzivaj `#'`, nie obycajny `#` ani vypisovany text. jeden blok zaveru ma mat najviac dve az tri vety a patri hned za prislusny vysledok alebo graf.

komentuj iba zistenie a jeho vecny vyznam. nevysvetluj, aku funkciu, test alebo graf si prave pouzil, a neopisuj fungovanie prikazov.

vhodny styl:

```r
normalita$typ_dna
#' normalitu zamietame pri pracovnych dnoch aj vikendoch, pretoze obe p-hodnoty su mensie ako 0,05.

intervaly$typ_dna
grafy$typ_dna + labs(title = "95 % intervaly podla typu dna", x = "typ dna")
#' priemer pracovnych dni je 4345,73 kwh a vikendov 3391,56 kwh, rozdiel je 28,13 % oproti vikendu.
#' intervaly sa neprekryvaju a aj pocas vikendu zostavaju odbery vyrazne.
```

cisla musia pochadzat z overeneho vypoctu nad aktualnym datasetom. pri zmene dat aktualizuj aj komentare; nepouzivaj zaver prevzaty z ineho prikladu.

do dvoch az troch viet zahrn podstatne obmedzenie, ak meni interpretaciu. kratky zaver ma byt stale vecne presny.

## grafy a farby

uprednostni farebnu schemu viridis. ponechaj jednoduche osi, citatelne nazvy a legendu tam, kde treba rozlisit skupiny alebo metody.

```r
library(viridisLite)
farby <- viridis(3, end = 0.8)

hist(spotreba, col = farby[2], border = "white",
     main = "rozdelenie spotreby", xlab = "spotreba (kwh)", ylab = "pocet merani")

ggplot(graf_data, aes(skupina, priemer, ymin = dolna, ymax = horna, color = metoda)) +
  geom_pointrange(position = position_dodge(0.5)) +
  scale_color_viridis_d(begin = 0.1, end = 0.75) +
  theme_minimal()
```

grafy zobrazuj v rstudio. trvale exporty grafov a tabuliek vytvaraj iba na poziadavku; docasne graficke vystupy mozu sluzit na schvalene overenie.

## metody a kniznice

vychadzaj z prislusneho cvicenia, nie z najkomplikovanejsieho dostupneho riesenia. nepouzivaj mechanicky vsetky kniznice z prednasky, ak pre dane zadanie nemaju vyznam.

pri zadani 2 boli vhodne:

- `readxl` na nacitanie excelu.
- zakladne r na upravu casu, faktory, opisne statistiky a `shapiro.test()`.
- `stats::t.test()` a `Rmisc::CI()` na interval priemeru.
- `Rmisc::group.CI()` a `tapply()` na skupinove intervaly.
- `mosaic` na bootstrap postupom z cvicenia.
- `plotrix::plotCI()` a `ggplot2::geom_pointrange()` na intervaly.
- `viridisLite` a `scale_color_viridis_d()` na farby.

typicky zapis bootstrapu:

```r
library(mosaic)
set.seed(2026)
boot_data <- do(10000) * mean(resample(spotreba))
is_boot <- confint(boot_data)
is_boot
```

v tomto zapise ponechaj `resample()` bez predpony `mosaic::`, aby `confint()` spravne rozpoznal povodny bodovy odhad. pri kolizii nazvov pouzi predponu balika tam, kde je potrebna, napriklad `stats::t.test()`.

## vecna spravnost zaverov

pri zadani 2 sa ukazali tieto pravidla, ktore treba respektovat aj v dalsich ulohach:

- rovnaka casova znacka s odlisnou hodnotou nie je automaticky duplicitny zaznam na vymazanie.
- vysoke alebo odlahle hodnoty nevyraduj bez vecneho dovodu.
- mesiace rozlisuj aj podla roka a upozorni na nekompletne obdobia.
- pri porovnavani priemerov nezamienaj hodinovu spotrebu s mesacnym suctom.
- nezamietnutie normality nie je dokaz normalneho rozdelenia.
- limit `shapiro.test()` je 5000 hodnot; vacsiu skupinu diagnostikuj reprodukovatelnym nahodnym podvyberom.
- intervaly pocitaj zo vsetkych hodnot skupiny, nie iba z podvyberu pre normalitu.
- interval priemeru neobsahuje automaticky 95 % merani a nepredpoveda maximalnu spotrebu.
- prekryv alebo neprekryv intervalov nenahradza test rozdielu priemerov.
- casova zavislost moze zmensit deklarovanu neistotu; bezny bootstrap jednotlivych hodnot ju neodstrani.
- podobnost metod nepotvrdzuje ich spolocne predpoklady.
- samotny pozorovany vzor nedokazuje jeho pricinu.

do riesenia nepridavaj dalsie testy alebo pokrocile metody nad dohodnuty rozsah. kratke komentare maju pomenovat podstatne obmedzenia bez rozsiahlej metodickej diskusie.

matematicke symboly zapisuj cez unicode, napriklad `H₀`, `α`, `μ` a `σ`; nepouzivaj latexove delimitery ani prikazy. kratke matematicke vyrazy v texte uvadzaj v spatnych apostrofoch a samostatne odvodenia v bloku `text`.

## overenie pred odovzdanim

over syntax, spustenie nad dodanym datasetom, ciselne vysledky a vykreslenie grafov. skontroluj aj zhodu komentarov so skutocnymi vysledkami.

vysledny skript ma splnat:

- ziadne vlastne ani anonymne `function()`.
- ziadne `print()`, `cat()` ani `sekcia()`.
- zavery cez `#'`, najviac dve az tri vety na blok.
- prazdny komentar `#'` pred kazdym nadpisom `#' #` alebo `#' ##`.
- male pismena a ziadna diakritika vo vlastnom texte.
- priame vypisy premennych a vyrazov.
- jednoduche bloky kodu a potrebne cykly.
- farby viridis, kde su vhodne.
- zachovane poziadavky zadania a postup z cvicenia.

pri odovzdani strucne napis, ktory subor vznikol alebo sa zmenil a co bolo overene.
