#'
#' # zadanie 5
#' samuel bagin
library(ggplot2)
library(viridisLite)
library(nortest)
library(latex2exp)
library(tseries)

alfa <- 0.05
velkosti <- seq(20, 300, 20)
opakovania <- 1000
ciel <- 0.95
farby <- viridis(4, end = 0.8)
set.seed(2026)

#'
#' # 1. rozdelenia a metodika
#' $h_0: x \sim \mathrm{n}(\mu,\sigma^2)$, kde $\mu$ a $\sigma^2$ su nezname. alternativa $h_1$: rozdelenie nie je normalne.
#' testujeme na hladine $\alpha = 0{,}05$ a $h_0$ zamietame pri $p < \alpha$.
#' nezamietnutie $h_0$ nie je dokaz normality, najma pri malych vzorkach.

generatory <- list(
  rovnomerne = function(n) runif(n, min = 0, max = 1),
  cauchyho = function(n) rcauchy(n, location = 0, scale = 1),
  exponencialne = function(n) rexp(n, rate = 1)
)

#' pre rozdelenia $\mathrm{u}(0,1)$, $\mathrm{c}(0,1)$ a $\mathrm{exp}(1)$ pri $n \in \{20,40,\ldots,300\}$ generujeme $b = 1000$ nezavislych vzoriek.
#' vsetky styri testy dostanu rovnaku vzorku. $p$-hodnoty prveho opakovania ukazuju jeden priebeh a podiel zamietnuti odhaduje silu testu.
#' pre rozne velkosti generujeme nove vzorky, nejde o postupne rozsirovanie tej istej vzorky.

#'
#' # 2. testy normality
#' SW porovnava usporiadane hodnoty s normalnymi kvantilmi, AD porovnava distribucne funkcie s vacsou vahou chvostov.
#' lill sleduje najvacsi rozdiel distribucnych funkcii a zohladnuje odhad priemeru a rozptylu zo vzorky.
#' jb hodnoti odchylku sikmosti $s$ od $0$ a spicatosti $k$ od $3$.

testy_normality <- function(x) {
  c(sw = shapiro.test(x)$p.value,
    ad = ad.test(x)$p.value,
    jb = tseries::jarque.bera.test(x)$p.value,
    lill = lillie.test(x)$p.value)
}

#' $\bar{x} = \frac{1}{n}\sum_{i=1}^{n}x_i$, $m_r = \frac{1}{n}\sum_{i=1}^{n}(x_i - \bar{x})^r$, $s = \frac{m_3}{m_2^{3/2}}$ a $k = \frac{m_4}{m_2^2}$.
#' $\mathrm{jb} = \frac{n}{6}\left(s^2 + \frac{(k - 3)^2}{4}\right)$ ma pri $h_0$ asymptoticky rozdelenie $\chi^2_2$.
#' preto je $p$-hodnota jb pri malych vzorkach iba priblizna.

#'
#' # 3. simulacia a diagnosticke grafy
#' prvu vzorku pre kazde rozdelenie a velkost ulozime aj pre grafy, aby sme zobrazovali tie iste data, ktore testujeme.
simulacie <- setNames(lapply(names(generatory), function(rozdelenie) {
  setNames(lapply(velkosti, function(n) {
    vzorka <- generatory[[rozdelenie]](n)
    p <- cbind(testy_normality(vzorka),
               replicate(opakovania - 1, testy_normality(generatory[[rozdelenie]](n))))
    list(vzorka = vzorka,
         vysledky = data.frame(rozdelenie = rozdelenie, n = n, test = rownames(p),
                               p = p[, 1], sila = rowMeans(p < alfa), row.names = NULL))
  }), as.character(velkosti))
}), names(generatory))

vysledky <- do.call(rbind, lapply(simulacie, function(rozdelenie) {
  do.call(rbind, lapply(rozdelenie, function(simulacia) simulacia$vysledky))
}))

vysledky$rozdelenie <- factor(vysledky$rozdelenie, levels = names(generatory))
vysledky$test <- factor(vysledky$test, levels = c("sw", "ad", "jb", "lill"))
rownames(vysledky) <- NULL

popisy_rozdeleni <- setNames(as.character(TeX(c(
  "rovnomerne $u(0,1)$", "cauchyho $c(0,1)$", "exponencialne $\\exp(1)$"
))), levels(vysledky$rozdelenie))
popisy_testov <- TeX(c("$sw$", "$ad$", "$jb$", "$lill$"))

stopifnot(nrow(vysledky) == 180, !anyNA(vysledky),
          all(vysledky$p >= 0 & vysledky$p <= 1),
          all(vysledky$sila >= 0 & vysledky$sila <= 1))

#' ## normalne q-q grafy ako na cviceni
#' riadky zodpovedaju rozdeleniam a stlpce velkostiam $n = 20,100,300$.
#' pri normalnom rozdeleni by body priblizne sledovali referencnu priamku. systematicke zakrivenie alebo odchylky v chvostoch upozornuju na nenormalitu.
vykresli_qq <- function() {
  povodne <- par(mfrow = c(3, 3), mar = c(4, 4, 3, 1))
  on.exit(par(povodne))
  for (rozdelenie in names(simulacie)) {
    for (n in c(20, 100, 300)) {
      x <- simulacie[[rozdelenie]][[as.character(n)]]$vzorka
      qqnorm(x, main = paste(rozdelenie, "n =", n),
             xlab = "teoreticke normalne kvantily", ylab = "vyberove kvantily",
             pch = 19, cex = 0.6, col = farby[1])
      qqline(x, col = farby[4], lwd = 2)
    }
  }
}
vykresli_qq()

#' ## histogramy a krabicove grafy ako na cviceni
#' pre $n = 100$ doplname pohlad na tvar rozdelenia, symetriu a extremne hodnoty. rozsahy osi sa prisposobuju jednotlivym rozdeleniam.
#' boxplot sam osebe normalitu nepotvrdzuje ani nevyvracia, doplna q-q graf a testy.
vykresli_tvary <- function() {
  povodne <- par(mfrow = c(3, 2), mar = c(4, 4, 3, 1))
  on.exit(par(povodne))
  for (rozdelenie in names(simulacie)) {
    x <- simulacie[[rozdelenie]][["100"]]$vzorka
    hist(x, breaks = "FD", main = paste(rozdelenie, "n = 100"),
         xlab = "hodnota", ylab = "pocetnost", col = farby[2], border = "white")
    boxplot(x, horizontal = TRUE, main = paste(rozdelenie, "n = 100"),
            xlab = "hodnota", col = farby[3])
  }
}
vykresli_tvary()

#'
#' # 4. vyvoj $p$-hodnot
p_hodnoty <- reshape(vysledky[c("rozdelenie", "n", "test", "p")],
                     idvar = c("rozdelenie", "n"), timevar = "test", direction = "wide")
rownames(p_hodnoty) <- NULL
print(p_hodnoty, row.names = FALSE)

graf_p <- ggplot(vysledky, aes(n, p, color = test, group = test)) +
  geom_hline(yintercept = alfa, linetype = 2, color = "grey40") +
  geom_line(linewidth = 0.65) + geom_point(size = 1.5) +
  facet_wrap(~ rozdelenie, ncol = 1, labeller = as_labeller(popisy_rozdeleni, default = label_parsed)) +
  scale_color_manual(values = farby, labels = popisy_testov) +
  scale_x_continuous(breaks = seq(20, 300, 40)) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() + theme(legend.position = "bottom") +
  labs(title = TeX("vyvoj $p$-hodnot testov normality"),
       subtitle = TeX("prve opakovanie. prerusovana ciara: $\\alpha = 0.05$"),
       x = TeX("velkost vzorky $n$"), y = TeX("$p$-hodnota"), color = "test")
print(graf_p)

#' detail pri rozhodovacej hranici ponechava vsetky data a iba priblizuje zobrazenu cast osi.
graf_p_detail <- graf_p +
  coord_cartesian(ylim = c(0, 0.1)) +
  labs(title = TeX("detail $p$-hodnot pri rozhodovacej hranici"))
print(graf_p_detail)

#' jednotlive $p$-hodnoty nemusia s rastucim $n$ klesat, pretoze sa menia nahodne vzorky.
#' pri rovnomernom rozdeleni v prvom priebehu sw a ad zamietaju od $n = 40$, jb a lill az od $n = 100$ pri vsetkych dalsich skumanych velkostiach.
#' pri cauchyho rozdeleni takto vsetky testy zamietaju od $n = 40$, pri exponencialnom uz od $n = 20$.

#'
#' # 5. sila testov a minimalna velkost vzorky
sila_testov <- reshape(vysledky[c("rozdelenie", "n", "test", "sila")],
                       idvar = c("rozdelenie", "n"), timevar = "test", direction = "wide")
rownames(sila_testov) <- NULL
print(sila_testov, row.names = FALSE)

#' silu odhadujeme ako $\hat{\pi}(n) = \frac{1}{b}\sum_{r=1}^{b}\mathbf{1}\{p_r(n) < \alpha\}$.
#' rozlisujeme dve hranice, aby sme odlisili jeden nahodny priebeh od opakovanych simulacii.
#' $n_{\min,p} = \min\{n: p_1(m) < \alpha\ \forall m \geq n\}$ pouziva iba prve opakovanie, teda data z grafu $p$-hodnot.
#' $n_{\min,95} = \min\{n: \hat{\pi}(m) \geq 0{,}95\ \forall m \geq n\}$ pouziva odhad sily zo vsetkych opakovani.
#' v oboch definiciach $n,m \in \{20,40,\ldots,300\}$. ak hranicu nedosiahneme, zapiseme NA.
#' v tabulke n_min_p oznacuje prvu hranicu a n_min_sila druhu. samotne zamietanie od urciteho $n$ v prvom priebehu nezarucuje 95-percentnu silu.
#' ide o zvolene simulacne kriterium a empiricky odhad, nie o univerzalnu hranicu ani dokaz asymptotickej konzistentnosti.

skupiny <- split(vysledky, list(vysledky$rozdelenie, vysledky$test), drop = TRUE)
n_min <- do.call(rbind, lapply(skupiny, function(data) {
  data <- data[order(data$n), ]
  splna_p <- vapply(seq_len(nrow(data)), function(i) {
    all(data$p[i:nrow(data)] < alfa)
  }, logical(1))
  splna_sila <- vapply(seq_len(nrow(data)), function(i) {
    all(data$sila[i:nrow(data)] >= ciel)
  }, logical(1))
  data.frame(rozdelenie = data$rozdelenie[1], test = data$test[1],
             n_min_p = if (any(splna_p)) min(data$n[splna_p]) else NA_integer_,
             n_min_sila = if (any(splna_sila)) min(data$n[splna_sila]) else NA_integer_)
}))
rownames(n_min) <- NULL
n_min <- n_min[order(n_min$rozdelenie, n_min$test), ]
print(n_min, row.names = FALSE)

graf_sily <- ggplot(vysledky, aes(n, sila, color = test, group = test)) +
  geom_hline(yintercept = ciel, linetype = 2, color = "grey40") +
  geom_line(linewidth = 0.65) + geom_point(size = 1.5) +
  facet_wrap(~ rozdelenie, ncol = 1, labeller = as_labeller(popisy_rozdeleni, default = label_parsed)) +
  scale_color_manual(values = farby, labels = popisy_testov) +
  scale_x_continuous(breaks = seq(20, 300, 40)) +
  scale_y_continuous(limits = c(0, 1), labels = function(x) TeX(paste0("$", 100 * x, "\\%$"))) +
  theme_minimal() + theme(legend.position = "bottom") +
  labs(title = TeX("podiel zamietnuti normality z $b = 1000$ opakovani"),
       subtitle = TeX("prerusovana ciara: ciel $95\\%$"),
       x = TeX("velkost vzorky $n$"), y = TeX("odhad sily $\\hat{\\pi}(n)$"), color = "test")
print(graf_sily)

#'
#' # 6. zdovodnenie vysledkov
#' nasledujuce porovnanie testov pouziva hranicu $n_{\min,95}$ z opakovanych simulacii.
#'
#' ## rovnomerne rozdelenie
#' rozdelenie je symetricke, ale ohranicene a plochsie nez normalne, jeho sikmost je $0$ a spicatost $1{,}8$.
#' sw dosiahne $n_{\min,95} = 80$, ad $120$, jb $140$ a lill $220$. sw teda v tejto simulacii odhali odlisny tvar najskor.
#' jb sa pri malych vzorkach opiera iba o rozdiel spicatosti a lill reaguje na maximalnu odchylku distribucnych funkcii, preto tu potrebuju viac dat.

#'
#' ## cauchyho rozdelenie
#' rozdelenie je symetricke, ale ma velmi tazke chvosty. stredna hodnota, rozptyl ani populacna sikmost a spicatost neexistuju.
#' extremne hodnoty vyrazne odlisuju vzorky od normality, vsetky styri testy dosiahnu $n_{\min,95} = 40$.
#' vyberove momenty pre jb sa daju vypocitat, ale nemozno ich interpretovat ako odhady existujucich populacnych momentov.

#'
#' ## exponencialne rozdelenie
#' rozdelenie je pravostranne asymetricke so sikmostou $2$ a spicatostou $9$, preto sa od normalneho lisi tvarom aj pravym chvostom.
#' sw a ad dosiahnu $n_{\min,95} = 40$, jb a lill $60$. sw a ad su pri malych vzorkach v tejto simulacii citlivejsie.
#' jb pri vacsom $n$ spolahlivo zachyti odchylku sikmosti aj spicatosti, ad navyse zdoraznuje rozdiely v chvostoch.

#'
#' # zaver
#' samotna symetria nezarucuje normalitu: cauchyho rozdelenie testy odhalia rychlo, rovnomerne potrebuje viac dat.
#' sw ma najmensie alebo zhodne $n_{\min,95}$ vo vsetkych troch rozdeleniach, pri exponencialnom je rovnako rychly aj ad.
#' uvedene hranice platia pre zvolene semeno, hladinu, pocet opakovani a skumanu mriezku. najmensia jednotliva $p$-hodnota neurcuje najsilnejsi test.
