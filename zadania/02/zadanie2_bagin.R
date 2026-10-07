#'
#' # zadanie 2 - spotreba staveniska
library(readxl)
library(Rmisc)
library(mosaic)
library(plotrix)
library(ggplot2)
library(viridisLite)

set.seed(2026)
farby <- viridis(3, end = 0.8)

#'
#' # 1. import a uprava dat
data <- as.data.frame(read_xlsx("Kontajner_spotreba.xlsx", sheet = "Kontajnery"))
names(data) <- tolower(names(data))
str(data)
head(data)
colSums(is.na(data))
data$datum <- as.Date(data$datum, tz = "UTC")
data$cas <- format(data$cas, "%H:%M:%S", tz = "UTC")
data$datum_cas <- as.POSIXct(paste(data$datum, data$cas), tz = "UTC")
head(data)
range(data$datum)
sum(duplicated(data[c("datum", "cas", "spotreba")]))
data[duplicated(data$datum_cas) | duplicated(data$datum_cas, fromLast = TRUE), ]
data[substr(data$cas, 4, 8) != "00:00", ]
table(table(data$datum))
#' data obsahuju 8904 merani od 1. 12. 2022 do 6. 12. 2023 bez chybajucich hodnot a uplne zhodnych zaznamov.
#' zaznam 6. 2. 2023 ma cas 15:31 (ma byt 15:00), a dna 29. 10. 2023 sa cas 02:00 opakuje s odlisnou spotrebou, zatial co 01:00 chyba.
#' vsetky zaznamy zostavaju zachovane, pretoze pricinu casovych nezrovnalosti nepozname.
#' 
max(data$spotreba)

#'
#' # 2. casove premenne
data$den_merania <- as.integer(data$datum - min(data$datum)) + 1
data$hodina <- factor(substr(data$cas, 1, 2), levels = sprintf("%02d", 0:23))
data$den_tyzdna <- factor(format(data$datum, "%u"), levels = 1:7,
                          labels = c("pondelok", "utorok", "streda", "stvrtok", "piatok", "sobota", "nedela"))

data$typ_dna <- factor(ifelse(as.integer(data$den_tyzdna) <= 5, "pracovny den", "vikend"),
                       levels = c("pracovny den", "vikend"))
data$mesiac <- factor(format(data$datum, "%Y-%m"))
head(data)
table(data$hodina)
table(data$den_tyzdna)
table(data$typ_dna)
table(data$mesiac)
#' hodiny maju 371 merani okrem hodiny 01 s 370 a hodiny 02 s 372 zaznamami, kazdy den tyzdna ma 1272 merani.
#' pracovne dni zahrnaju pondelok az piatok vratane sviatkov a zaznam 15:31 patri do hodiny 15.
#' december 2023 obsahuje iba sest dni a zostava oddeleny od decembra 2022.

#'
#' # 3. intervaly spolahlivosti
#'
#' ## vyvoj spotreby
spotreba <- data$spotreba
denne_priemery <- aggregate(spotreba ~ datum, data = data, mean)
ggplot(denne_priemery, aes(datum, spotreba)) +
  geom_line(color = farby[2], linewidth = 0.5) + theme_minimal() +
  labs(title = "vyvoj spotreby", x = "datum", y = "priemerna hodinova spotreba (kwh)")
#' zimne hodnoty su vyssie nez letne a celkovy priemer skryva vyrazne zmeny pocas roka.
#' bez udajov o teplote a prevadzke nemozno urcit pricinu tohto vzoru.

#'
#' ## rozdelenie spotreby
summary(spotreba)
sd(spotreba)
moments::skewness(spotreba)
hist(spotreba, breaks = 50, col = farby[2], border = "white",
     main = "rozdelenie hodinovej spotreby", xlab = "spotreba (kwh)", ylab = "pocet merani")
#' rozdelenie je pravostranne zosikmene so sikmostou 1,647.
#' priemer 4073,11 kwh prevysuje median 3102,59 kwh, pretoze ho zvysuju vysoke spotreby.
boxplot(spotreba, horizontal = TRUE, col = farby[3],
        main = "hodinova spotreba", xlab = "spotreba (kwh)")
length(boxplot.stats(spotreba)$out)
#' 252 hodnot je oznacenych ako odlahle a maximum dosahuje 27751,57 kwh.
#' samotna odlahlost nie je dokaz chyby, preto tieto hodnoty nevyradujeme.
qqnorm(spotreba, pch = 16, cex = 0.35, col = farby[1],
       main = "normalne kvantily spotreby", xlab = "teoreticke kvantily", ylab = "spotreba (kwh)")
qqline(spotreba, col = farby[2], lwd = 2)
#' horne hodnoty sa vyrazne odchyluju od priamky, preto normalne rozdelenie spotreby nie je podlozene.

#'
#' ## casova zavislost
acf_spotreby <- acf(spotreba, lag.max = 48, plot = FALSE)
plot(acf_spotreby, ci = 0, col = farby[1], main = "casova zavislost spotreby",
     xlab = "oneskorenie v pocte zaznamov", ylab = "autokorelacia")
as.numeric(acf_spotreby$acf)[c(2, 25)]
#' autokorelacia je 0,954 pri posune o jeden zaznam a 0,781 pri posune o 24 zaznamov.
#' merania nie su nezavisle, preto mozu byt vypocitane intervaly prilis uzke.

#'
#' ## normalita
shapiro.test(sample(spotreba, 5000))
#' p-hodnota je mensia ako 0,05, preto normalitu zamietame.
#' vzhladom na casovu zavislost je tento zaver orientacny.

#'
#' ## celkovy priemer
alfa <- 0.05
n <- length(spotreba)
priemer <- mean(spotreba)
is_vzorec <- priemer + c(-1, 1) * qt(1 - alfa / 2, n - 1) * sd(spotreba) / sqrt(n)
is_t <- as.numeric(stats::t.test(spotreba)$conf.int)
is_vzorec
is_t
CI(spotreba)
plotCI(1, priemer, li = is_t[1], ui = is_t[2], col = farby[1], pch = 19,
       xaxt = "n", xlab = "", ylab = "priemerna hodinova spotreba (kwh)", main = "95 % interval priemeru")
axis(1, at = 1, labels = "cele obdobie")
#' priemerna hodinova spotreba je 4073,11 kwh a jej 95 % interval je od 3998,84 do 4147,38 kwh.
#' vsetky tri vypocty sa zhoduju, ale interval nevyjadruje rozsah jednotlivych merani.

#'
#' ## hladina spolahlivosti
is_90 <- as.numeric(stats::t.test(spotreba, conf.level = 0.9)$conf.int)
is_90
stats::t.test(spotreba, alternative = "less")$conf.int
stats::t.test(spotreba, alternative = "greater")$conf.int
hladiny <- data.frame(hladina = c("90 %", "95 %"), priemer = priemer,
                      dolna = c(is_90[1], is_t[1]), horna = c(is_90[2], is_t[2]))
ggplot(hladiny, aes(hladina, priemer, ymin = dolna, ymax = horna, color = hladina)) +
  geom_pointrange() + scale_color_viridis_d(begin = 0.1, end = 0.75, guide = "none") +
  theme_minimal() + labs(title = "hladina spolahlivosti", x = "hladina", y = "priemerna spotreba (kwh)")
#' 90 % interval od 4010,78 do 4135,44 kwh je uzsi nez 95 % interval, pricom priemer zostava rovnaky.
#' jednostranne hranice su 4010,78 a 4135,44 kwh a obmedzuju priemer, nie najvyssiu spotrebu.

#'
#' ## bootstrap
boot_celkovo <- do(10000) * mean(resample(spotreba))
is_boot <- confint(boot_celkovo)
is_boot
hist(boot_celkovo$mean, breaks = 40, col = farby[2], border = "white",
     main = "rozdelenie bootstrapovych priemerov", xlab = "priemerna spotreba (kwh)", ylab = "pocet vyberov")
abline(v = priemer, col = farby[1], lwd = 2)
abline(v = c(is_boot$lower, is_boot$upper), col = farby[3], lty = 2, lwd = 2)
#' bootstrapove priemery su priblizne symetricke okolo 4073,11 kwh a 95 % interval je od 4000,17 do 4148,33 kwh.
#' blizkost oboch intervalov nepotvrdzuje nezavislost povodnych merani.

#'
#' ## skupinove vypocty
intervaly <- normalita <- grafy <- boot_vybery <- is_tapply <- list()
for (premenna in c("hodina", "den_tyzdna", "typ_dna", "mesiac")) {
  ci <- group.CI(as.formula(paste("spotreba ~", premenna)), data = data)
  names(ci) <- c("skupina", "t_horna", "priemer", "t_dolna")
  ci$skupina <- factor(ci$skupina, levels = levels(data[[premenna]]))
  ci$n <- as.numeric(table(data[[premenna]])[as.character(ci$skupina)])
  ci$boot_dolna <- ci$boot_horna <- NA_real_
  testy <- data.frame(skupina = ci$skupina, n_test = pmin(ci$n, 5000), w = NA_real_, p = NA_real_)
  boot_vybery[[premenna]] <- list()
  is_tapply[[premenna]] <- lapply(tapply(spotreba, data[[premenna]], stats::t.test), "[[", "conf.int")
  for (i in seq_len(nrow(ci))) {
    x <- spotreba[data[[premenna]] == ci$skupina[i]]
    test <- shapiro.test(if (length(x) > 5000) sample(x, 5000) else x)
    testy$w[i] <- unname(test$statistic)
    testy$p[i] <- test$p.value
    boot_data <- do(10000) * mean(resample(x))
    boot_ci <- confint(boot_data)
    ci$boot_dolna[i] <- boot_ci$lower
    ci$boot_horna[i] <- boot_ci$upper
    boot_vybery[[premenna]][[i]] <- boot_data$mean
  }
  intervaly[[premenna]] <- ci
  normalita[[premenna]] <- testy
  graf_data <- rbind(data.frame(skupina = ci$skupina, priemer = ci$priemer,
                                dolna = ci$t_dolna, horna = ci$t_horna, metoda = "t-interval"),
                     data.frame(skupina = ci$skupina, priemer = ci$priemer,
                                dolna = ci$boot_dolna, horna = ci$boot_horna, metoda = "bootstrap"))
  grafy[[premenna]] <- ggplot(graf_data, aes(skupina, priemer, ymin = dolna, ymax = horna, color = metoda)) +
    geom_pointrange(position = position_dodge(0.5)) + scale_color_viridis_d(begin = 0.1, end = 0.75) +
    theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom") +
    labs(y = "priemerna hodinova spotreba (kwh)", color = "metoda")
}

#'
#' ## hodiny dna
normalita$hodina
#' normalitu zamietame vo vsetkych 24 hodinovych skupinach, pretoze ich p-hodnoty su mensie ako 0,05.
intervaly$hodina
grafy$hodina + labs(title = "95 % intervaly podla hodin", x = "hodina dna")
#' najvyssi priemer je o 07. hodine s 5666,55 kwh a najnizsi o 18. hodine s 3233,09 kwh, ich intervaly sa neprekryvaju.
#' susedne hodiny maju casto prekryvajuce sa intervaly a obe metody poskytuju podobne vysledky.

#'
#' ## dni v tyzdni
normalita$den_tyzdna
#' normalitu zamietame vo vsetkych siedmich dnoch tyzdna, pretoze ich p-hodnoty su mensie ako 0,05.
intervaly$den_tyzdna
grafy$den_tyzdna + labs(title = "95 % intervaly podla dni", x = "den tyzdna")
#' najvyssi priemer ma streda s 4506,80 kwh a najnizsi nedela s 3291,48 kwh, ich intervaly sa neprekryvaju.
#' intervaly blizkych pracovnych dni sa prekryvaju, preto z nich nemozno jednoznacne urcit poradie skutocnych priemerov.

#'
#' ## pracovne dni a vikendy
normalita$typ_dna
#' normalitu zamietame pri pracovnych dnoch aj vikendoch, pretoze obe p-hodnoty su mensie ako 0,05.
intervaly$typ_dna
grafy$typ_dna + labs(title = "95 % intervaly podla typu dna", x = "typ dna")
rozdiel_typ <- diff(rev(intervaly$typ_dna$priemer))
percento_typ <- 100 * rozdiel_typ / intervaly$typ_dna$priemer[2]
c(rozdiel_kwh = rozdiel_typ, rozdiel_percent = percento_typ)
#' priemer pracovnych dni je 4345,73 kwh a vikendov 3391,56 kwh, rozdiel je 954,17 kwh alebo 28,13 % oproti vikendu.
#' intervaly sa neprekryvaju a vyrazna vikendova spotreba poukazuje na pretrvavajuce odbery aj mimo pracovnych dni.

#'
#' ## mesiace
normalita$mesiac
#' normalitu zamietame vo vsetkych 13 mesacnych skupinach, pretoze ich p-hodnoty su mensie ako 0,05.
intervaly$mesiac
grafy$mesiac + labs(title = "95 % intervaly podla mesiacov", x = "rok a mesiac")
#' najvyssi priemer ma januar 2023 s 8443,97 kwh a najnizsi september 2023 s 1112,71 kwh, ich intervaly sa neprekryvaju.
#' december 2023 ma iba 144 merani a jeho priemer neopisuje cely mesiac, preto nie je rovnocenny decembru 2022.

#'
#' # zaver
#' najvyssia priemerna zataz je rano, pocas pracovnych dni a v zimnej casti sledovaneho obdobia.
#' casova zavislost moze intervaly zuzit a samotny prekryv ani neprekryv intervalov nenahradza test rozdielu priemerov.
#' intervaly opisuju neistotu priemeru, nie buduce spicky spotreby.
