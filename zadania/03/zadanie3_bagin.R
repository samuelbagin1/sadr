#'
#' # zadanie 3
#' Samuel Bagin
library(readxl)
library(ggplot2)
library(viridisLite)
library(latexpdf)

alfa <- 0.05
farby <- viridis(4, end = 0.8)
farby_hranic <- viridis(2, begin = 0.05, end = 0.65)
nazvy_modelov <- c("Eurokod", "MC LoAI", "MC LoAII", "MC LoAIII")

#'
#' # 1. import a uprava dat
cesty_skriptov <- c(
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
  unlist(lapply(sys.frames(), function(ramec) ramec$ofile), use.names = FALSE)
)
priecinok <- if (length(cesty_skriptov) > 0) {
  dirname(normalizePath(tail(cesty_skriptov, 1)))
} else {
  getwd()
}
subor_dat <- file.path(priecinok, "Modely_pretlacenie.xlsx")

data <- as.data.frame(read_xlsx(subor_dat, sheet = "data"))
str(data)
head(data)
colSums(is.na(data))
sum(duplicated(data))

stlpce <- c("Eurokod", "Eexp", "MCLoAI", "LoAIexp",
            "MCLoAII", "LoAIIexp", "MCLoAIII", "LoAIIIexp")

hodnoty <- as.matrix(data[stlpce])

#' data obsahuju 55 riadkov a 8 ciselnych stlpcov bez chybajucich hodnot a zhodnych riadkov.
#' kazdy model ma vlastny stlpec modelovych aj experimentalnych hodnot.

View(data)

podiely <- data.frame(
  Eurokod = data$Eexp / data$Eurokod,
  MCLoAI = data$LoAIexp / data$MCLoAI,
  MCLoAII = data$LoAIIexp / data$MCLoAII,
  MCLoAIII = data$LoAIIIexp / data$MCLoAIII
)
head(podiely)
#' podiel $x = V_{exp} / V_{model}$, hodnota pod 1 znamena nadhodnotenie odolnosti modelom.
#' riadky v ramci dvojice zostavaju sparovane, nepouzivame podiel priemerov stlpcov.

dlhe_data <- data.frame(
  model = factor(rep(nazvy_modelov, each = nrow(podiely)), levels = nazvy_modelov),
  podiel = unlist(podiely, use.names = FALSE)
)
popis <- do.call(rbind, lapply(podiely, function(x) {
  data.frame(n = length(x), priemer = mean(x), median = median(x),
             sd = sd(x), rozptyl = var(x), minimum = min(x), maximum = max(x),
             pod_1 = sum(x < 1), podiel_pod_1 = mean(x < 1))
}))
popis
#' priemery: Eurokod 1,18980, MC LoAI 1,17797, MC LoAII 1,11822 a MC LoAIII 1,20134.
#' podiel pod 1 ma Eurokod v 8 pripadoch, MC LoAI v 0, MC LoAII v 16 a MC LoAIII v 16.
#' vsetky pozorovane pripady su bezpecne iba pri MC LoAI, jeho minimum je 1,00073.

#'
#' # 2. priklad 1 - graficka struktura a bezpecnost modelov
#'
#' ## rozdelenie podielov
graf_histogram <- ggplot(dlhe_data, aes(podiel, fill = model)) +
  geom_histogram(aes(y = after_stat(density)), bins = 12, color = "white", alpha = 0.7) +
  geom_density(aes(color = model), linewidth = 0.7) +
  geom_vline(xintercept = 1, color = farby_hranic[1], linetype = 2) +
  facet_wrap(~ model, ncol = 2) +
  scale_fill_manual(values = farby, guide = "none") +
  scale_color_manual(values = farby, guide = "none") + theme_minimal() +
  labs(title = "rozdelenie podielov experimentalnej a modelovej odolnosti",
       x = "podiel Vexp / Vmodel", y = "hustota")
print(graf_histogram)

graf_boxplot <- ggplot(dlhe_data, aes(model, podiel, fill = model)) +
  geom_boxplot(alpha = 0.65, outlier.shape = NA) +
  geom_point(aes(color = model), position = position_jitter(width = 0.08, height = 0, seed = 2026),
             alpha = 0.5, size = 1.4) +
  geom_hline(yintercept = 1, color = farby_hranic[1], linetype = 2) +
  scale_fill_manual(values = farby, guide = "none") +
  scale_color_manual(values = farby, guide = "none") + theme_minimal() +
  labs(title = "porovnanie modelov a hranica bezpecnosti", x = "model", y = "podiel Vexp / Vmodel")
print(graf_boxplot)
#' MC LoAI ma najmensi rozptyl a jeho body lezia nad hranicou 1.
#' MC LoAII ma priemer najblizsie k 1, ale spolu s MC LoAIII vykazuje najvacsiu variabilitu.
#' odlahle hodnoty automaticky neodstranujeme, pretoze nemame dokaz chyby merania.

#'
#' ## predpoklady testov
graf_qq <- ggplot(dlhe_data, aes(sample = podiel, color = model)) +
  stat_qq(size = 1.5) + stat_qq_line() + facet_wrap(~ model, ncol = 2) +
  scale_color_manual(values = farby, guide = "none") + theme_minimal() +
  labs(title = "normalne kvantilove grafy podielov", x = "teoreticke kvantily", y = "vyberove kvantily")
print(graf_qq)
normalita <- do.call(rbind, lapply(podiely, function(x) {
  test <- shapiro.test(x)
  data.frame(W = unname(test$statistic), p = test$p.value)
}))
normalita
#' zadanie predpoklada normalne rozdelenie podielov, Q-Q grafy a Shapirov-Wilkov test ho doplnkovo kontroluju.
#' p-hodnoty su 0,67986, 0,14902, 0,49113 a 0,14045, preto normalitu na hladine 0,05 nezamietame.
#' nezamietnutie nie je dokaz normality. Dalej predpokladame nezavisle skusky v ramci kazdeho modelu;
#' tento predpoklad nemozno overit iba z dodanej tabulky. Medzi modelmi nezavislost nevyzadujeme,
#' pretoze testujeme kazdy model osobitne a nerobime dvojvyberove porovnania.

#'
#' ## jednostranny jednovyberovy t-test
#' pre kazdy model: $H_0: \mu ≤ 1 \qquad H_1: \mu > 1$, kde $\mu$ je stredna hodnota podielu.
#' hranicny pripad H_0 je $\mu = 1$. Testujeme na hladine $\alpha = 0,05$.
#' testova statistika: $t = (priemer - 1) / (s / \sqrt{n})$, pri hranici $H_0$ ma $n - 1$ stupnov volnosti.
testy_priemeru <- lapply(podiely, function(x) {
  stats::t.test(x, mu = 1, alternative = "greater", conf.level = 1 - alfa)
})
testy_priemeru
bezpecnost <- do.call(rbind, lapply(testy_priemeru, function(test) {
  data.frame(priemer = unname(test$estimate), t = unname(test$statistic),
             df = unname(test$parameter), p = test$p.value,
             dolna_95 = test$conf.int[1], horna_95 = test$conf.int[2])
}))
bezpecnost$rozhodnutie <- ifelse(bezpecnost$p < alfa, "zamietame H0: priemer je nad 1", "H0 nezamietame")
bezpecnost
#' p-hodnoty: Eurokod 1,019e-11, MC LoAI 1,597e-18, MC LoAII 0,0005005, MC LoAIII 1,313e-7.
#' pri vsetkych styroch modeloch zamietame $H_0$ v prospech $\mu > 1$: modely su bezpecne v priemere.
#' dolne jednostranne $95 %$ hranice priemeru su 1,15210, 1,15500, 1,06136 a 1,14406.
#' t-test priemeru nezarucuje, ze kazdy podiel je aspon 1, v troch modeloch uz data ukazuju opak.
#' ani 55 bezpecnych pozorovani pri MC LoAI nezarucuje bezpecnost vsetkych buducich skusok.

#'
#' ## intervaly priemerov pre graficke porovnanie
#' v grafe su konecne obojstranne 95 % intervaly, jednostranne intervaly vyssie maju hornu hranicu Inf.
intervaly_priemeru <- do.call(rbind, lapply(podiely, function(x) {
  ci <- stats::t.test(x, conf.level = 1 - alfa)$conf.int
  data.frame(priemer = mean(x), dolna = ci[1], horna = ci[2])
}))
intervaly_priemeru$model <- factor(nazvy_modelov, levels = nazvy_modelov)
graf_priemerov <- ggplot(intervaly_priemeru, aes(model, priemer, ymin = dolna, ymax = horna, color = model)) +
  geom_pointrange() + geom_hline(yintercept = 1, color = farby_hranic[1], linetype = 2) +
  scale_color_manual(values = farby, guide = "none") + theme_minimal() +
  labs(title = "priemery a obojstranne 95 % intervaly spolahlivosti",
       x = "model", y = "priemerny podiel Vexp / Vmodel")
print(graf_priemerov)
#' z hladiska bezpecnosti, presnosti a malej variability sa najlepsie javi MC LoAI.
#' MC LoAII je priemerom blizsie k 1, no ma 16 pozorovani pod 1 a vyrazne vacsi rozptyl.

#'
#' # 3. priklad 2 - konzistentnost modelov
test_rozptylu <- function(x, sigma2_0, alternativa = c("greater", "less", "two.sided")) {
  alternativa <- match.arg(alternativa)
  df <- length(x) - 1
  chi2 <- df * var(x) / sigma2_0
  p_dolna <- pchisq(chi2, df = df)
  p_horna <- pchisq(chi2, df = df, lower.tail = FALSE)
  p <- switch(alternativa, greater = p_horna, less = p_dolna,
              two.sided = min(1, 2 * min(p_dolna, p_horna)))
  data.frame(rozptyl = var(x), sigma2_0 = sigma2_0, chi2 = chi2, df = df, p = p)
}

#'
#' ## nutna poziadavka - rozptyl nema presiahnut 0,05
#' pre kazdy model: $H_0: \sigma^2 ≤ 0,05, \qquad H_1: \sigma^2 > 0,05 \qquad \alpha = 0,05$.
#' tento pravostranny test zistuje, ci vieme preukazat prekrocenie povoleneho rozptylu.
testy_nutne <- do.call(rbind, lapply(podiely, test_rozptylu, sigma2_0 = 0.05, alternativa = "greater"))
kriticka_nutna <- qchisq(1 - alfa, df = testy_nutne$df)
testy_nutne$kriticka_hodnota <- kriticka_nutna
testy_nutne$rozhodnutie <- ifelse(testy_nutne$p < alfa, "zamietame H0: rozptyl presahuje 0,05", "H0 nezamietame")
testy_nutne
#' p-hodnoty su 0,99648 priblizne 1, 0,08769 a 0,07523. $H_0$ nezamietame pri ziadnom modeli.
#' prekrocenie 0,05 sa teda na hladine 0,05 nepreukazalo, ale to este nepotvrdzuje splnenie poziadavky.
#' vyberove rozptyly MC LoAII 0,06349 a MC LoAIII 0,06442 uz prevysuju odporucanu hranicu.

#'
#' ## doplnkove overenie splnenia nutnej poziadavky
#' pre kazdy model: $H_0: \sigma^2 ≥ 0,05 \qquad H_1: \sigma^2 < 0,05 \qquad \alpha = 0,05$.
#' tento lavostranny test umoznuje priamo podlozit, ze rozptyl lezi pod povolenou hranicou.
testy_splnenia <- do.call(rbind, lapply(podiely, test_rozptylu, sigma2_0 = 0.05, alternativa = "less"))
testy_splnenia$horna_95 <- (testy_splnenia$df * testy_splnenia$rozptyl /
                          qchisq(alfa, df = testy_splnenia$df))
testy_splnenia$rozhodnutie <- ifelse(testy_splnenia$p < alfa, "rozptyl pod 0,05 je podlozeny", "splnenie nie je preukazane")
testy_splnenia
#' Eurokod: p = 0,00352, horna jednostranna 95 % hranica rozptylu 0,03954.
#' MC LoAI: p = 6,543e-11, horna hranica 0,01467. Pri oboch je rozptyl pod 0,05 podlozeny.
#' pri MC LoAII a MC LoAIII su p-hodnoty 0,91231 a 0,92477, splnenie poziadavky nevieme preukazat.

#'
#' ## idealna poziadavka - rozptyl 0,01
#' pre kazdy model: $H_0: \sigma^2 = 0,01 \qquad H_1: \sigma^2 ≠ 0,01 \qquad \alpha = 0,05$.
#' slovo idealne interpretujeme ako rovnost s 0,01, preto pouzivame obojstranny test.
testy_idealne <- do.call(rbind, lapply(podiely, test_rozptylu, sigma2_0 = 0.01, alternativa = "two.sided"))
testy_idealne$kriticka_dolna <- qchisq(alfa / 2, df = testy_idealne$df)
testy_idealne$kriticka_horna <- qchisq(1 - alfa / 2, df = testy_idealne$df)
testy_idealne$rozhodnutie <- ifelse(testy_idealne$p < alfa, "zamietame H0: rozptyl sa lisi od 0,01", "H0 nezamietame")
testy_idealne
#' p-hodnoty su 8,990e-11, 0,80468, 2,559e-43 a 2,968e-44.
#' iba pri MC LoAI nezamietame idealny rozptyl 0,01 a jeho vyberovy rozptyl je 0,01036.
#' pri ostatnych modeloch $H_0$ zamietame a pozorovane rozptyly su vyssie ako 0,01.
#' nezamietnutie rovnosti pri MC LoAI neznamena dokaz presnej rovnosti rozptylu s 0,01.

#'
#' ## intervaly rozptylov
intervaly_rozptylu <- do.call(rbind, lapply(podiely, function(x) {
  df <- length(x) - 1
  data.frame(rozptyl = var(x), dolna = df * var(x) / qchisq(1 - alfa / 2, df),
             horna = df * var(x) / qchisq(alfa / 2, df))
}))
intervaly_rozptylu$model <- factor(nazvy_modelov, levels = nazvy_modelov)
intervaly_rozptylu
graf_rozptylov <- ggplot(intervaly_rozptylu, aes(model, rozptyl, ymin = dolna, ymax = horna, color = model)) +
  geom_pointrange() +
  geom_hline(yintercept = 0.01, color = farby_hranic[2], linetype = 1) +
  geom_hline(yintercept = 0.05, color = farby_hranic[1], linetype = 2) +
  scale_color_manual(values = farby, guide = "none") + theme_minimal() +
  labs(title = "rozptyly a obojstranne 95 % intervaly spolahlivosti",
       subtitle = "plna ciara: ideal 0,01; prerusovana ciara: maximum 0,05",
       x = "model", y = "rozptyl podielu Vexp / Vmodel")
print(graf_rozptylov)
#' obojstranne intervaly: Eurokod (0,01978, 0,04235), MC LoAI (0,00734, 0,01572),
#' MC LoAII (0,04499, 0,09634), MC LoAIII (0,04566, 0,09776).
#' posledne dva intervaly obsahuju 0,05, preto z tychto dat nemame jednoznacny zaver o prekroceni hranice.

#'
#' # zaver
#' vsetky styri modely maju statisticky preukazany priemerny podiel nad 1.
#' poziadavku bezpecnosti v kazdej jednotlivej skuske vsak v dodanych datach splna iba MC LoAI.
#' Eurokod aj MC LoAI maju podlozeny rozptyl pod 0,05, iba MC LoAI je zlucitelny s idealnym rozptylom 0,01.
#' MC LoAI preto predstavuje najlepsi kompromis bezpecnosti, presnosti a konzistentnosti v tychto datach.
#' pri MC LoAII a MC LoAIII je vyberovy rozptyl nad limitom, no jeho prekrocenie nie je na hladine 0,05 preukazane.
#' testy hodnotime samostatne na hladine 0,05 pre kazdy model, bez korekcie na viacnasobne testovanie.

