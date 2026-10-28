#'
#' # zadanie 4
#' Samuel Bagin
library(readxl)
library(ggplot2)
library(viridisLite)
library(car)
library(latex2exp)

alfa <- 0.05
alfa_dva <- 0.10
farby <- viridis(5, end = 0.8)

#'
#' # 1. import a kontrola dat
cesty_skriptov <- c(
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
  unlist(lapply(sys.frames(), function(ramec) ramec$ofile), use.names = FALSE)
)
priecinok <- if (length(cesty_skriptov) > 0) {
  dirname(normalizePath(tail(cesty_skriptov, 1)))
} else {
  getwd()
}

prijem <- as.data.frame(read_xlsx(file.path(priecinok, "prijem.xlsx"), sheet = 1))
dieta <- as.data.frame(read_xlsx(file.path(priecinok, "dieta.xlsx"), sheet = 1))
names(prijem) <- tolower(names(prijem))
names(dieta) <- tolower(names(dieta))
str(prijem)
head(prijem)
colSums(is.na(prijem))
sum(duplicated(prijem))
anyDuplicated(prijem$respondent)
str(dieta)
head(dieta)
colSums(is.na(dieta))
sum(duplicated(dieta))

stopifnot(nrow(prijem) == 235, nrow(dieta) == 202,
          !anyNA(prijem), !anyNA(dieta), anyDuplicated(prijem$respondent) == 0,
          all(prijem$vek %in% 1:5), all(prijem$vzdelanie %in% 1:5),
          all(prijem$miesto %in% 1:4), all(prijem$sektor %in% 1:3),
          all(dieta$pohlavie %in% c("F", "M")),
          all(dieta$pred > 0), all(dieta$po > 0))

for (premenna in c("vek", "vzdelanie", "miesto", "sektor")) {
  prijem[[premenna]] <- factor(prijem[[premenna]])
}
dieta$pohlavie <- factor(dieta$pohlavie, levels = c("F", "M"), labels = c("zeny", "muzi"))
if (interactive()) {
  View(prijem)
  View(dieta)
}

#' prvy harok prijem obsahuje 235 osob dieta obsahuje 202 klientov.
#' v analyzovanych tabulkach nie su chybajuce hodnoty ani zhodne riadky.
#' prijem je cisty rocny prijem bez zadanej meny.
#' pre jednofaktorove analyzy a dietu volime $\alpha = 0,05$, pre dvojfaktorove analyzy zadanie urcuje $\alpha = 0,10$.

#'
#' ## pomocne vypocty a grafy
popis_skupin <- function(hodnoty, skupina, hladina = alfa) {
  vysledok <- do.call(rbind, lapply(split(hodnoty, skupina, drop = TRUE), function(x) {
    n <- length(x)
    chyba <- if (n > 1) qt(1 - hladina / 2, n - 1) * sd(x) / sqrt(n) else NA_real_
    data.frame(n = n, priemer = mean(x), median = median(x), sd = sd(x), rozptyl = var(x),
               minimum = min(x), maximum = max(x), dolna = mean(x) - chyba, horna = mean(x) + chyba,
               p_shapiro = if (n >= 3) shapiro.test(x)$p.value else NA_real_)
  }))
  vysledok$skupina <- factor(rownames(vysledok), levels = levels(droplevels(skupina)))
  vysledok
}

graf_skupin <- function(data, hodnota, skupina, nazov, os_y) {
  ggplot(data, aes(x = .data[[skupina]], y = .data[[hodnota]], fill = .data[[skupina]])) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_point(aes(color = .data[[skupina]]),
               position = position_jitter(width = 0.10, height = 0, seed = 2026),
               alpha = 0.45, size = 1.3) +
    scale_fill_manual(values = farby, guide = "none") +
    scale_color_manual(values = farby, guide = "none") + theme_minimal() +
    labs(title = nazov, x = skupina, y = os_y)
}

graf_normality <- function(data, hodnota, skupina, nazov) {
  ggplot(data, aes(sample = .data[[hodnota]], color = .data[[skupina]])) +
    stat_qq(size = 1.3) + stat_qq_line() + facet_wrap(vars(.data[[skupina]])) +
    scale_color_manual(values = farby, guide = "none") + theme_minimal() +
    labs(title = nazov, x = "teoreticke kvantily", y = "vyberove kvantily")
}

#'
#' # 2. prijem - jednofaktorova analyza rozptylu
#' pre kazdy faktor testujeme $H_0: \mu_1 = \cdots = \mu_k$, $H_1$: aspon dve stredne hodnoty sa lisia.
#' normalita v skupinach: $H_0$: normalne rozdelenie, $H_1$: rozdelenie nie je normalne.
#' Bartlettov test: $H_0: \sigma_1^2 = \cdots = \sigma_k^2$, $H_1$: aspon dva rozptyly sa lisia.
#' pri splnenych predpokladoch pouzijeme ANOVA a po vyznamnom vysledku Tukeyho-Kramerov post hoc test.
#' nezamietnutie $H_0$ nie je dokaz rovnosti priemerov ani dokaz splnenia predpokladov.
#' mierou efektu je $\eta^2 = \frac{SS_{faktor}}{SS_{celkove}}$, teda podiel vysvetlenej variability prijmu.

jednofaktorova <- function(premenna) {
  formula <- reformulate(premenna, response = "prijem")
  popis <- popis_skupin(prijem$prijem, prijem[[premenna]])
  print(popis)
  print(graf_skupin(prijem, "prijem", premenna, paste("rocny prijem podla", premenna), "cisty rocny prijem"))
  print(graf_normality(prijem, "prijem", premenna, paste("Q-Q grafy prijmu podla", premenna)))
  print(ggplot(popis, aes(skupina, priemer, ymin = dolna, ymax = horna, color = skupina)) +
          geom_pointrange() + scale_color_manual(values = farby, guide = "none") + theme_minimal() +
          labs(title = paste("priemery a 95 % intervaly -", premenna), x = premenna, y = "cisty rocny prijem"))

  bartlett <- bartlett.test(formula, data = prijem)
  print(bartlett)
  model <- aov(formula, data = prijem)
  tabulka <- summary(model)[[1]]
  print(summary(model))
  eta2 <- tabulka[1, "Sum Sq"] / sum(tabulka[, "Sum Sq"])
  print(c(eta2 = eta2))
  post <- NULL
  if (tabulka[1, "Pr(>F)"] < alfa) {
    post <- TukeyHSD(model, conf.level = 1 - alfa)
    print(post)
    plot(post, las = 1, col = farby[2])
  }

  # ANOVA sa podla zadania vypocita aj pri poruseni predpokladov.
  # Pri nerovnakych rozptyloch je alternativou Welchova ANOVA a Gamesov-Howellov post hoc test.
  # Pri silnej nenormalite zvazit robustnu analyzu priemerov alebo po odovodneni poradove testy.
  # Kruskalov-Wallisov test testuje poradia/rozdelenia, nie je vseobecne testom rovnosti priemerov.
  if (bartlett$p.value < alfa || any(popis$p_shapiro < alfa, na.rm = TRUE)) {
    print(oneway.test(formula, data = prijem, var.equal = FALSE))
    print(kruskal.test(formula, data = prijem))
  }
  list(popis = popis, bartlett = bartlett, model = model, tabulka = tabulka, eta2 = eta2, post = post)
}

#'
#' ## vek
vek <- jednofaktorova("vek")
#' Shapirove testy ani Bartlettov test pri $\alpha = 0,05$ nezamietaju normalitu a rovnost rozptylov.
#' ANOVA ($p = 0,09287$) nezamieta $H_0$, rozdiel priemerneho prijmu podla veku sa nepreukazal.
#' Vek vysvetluje asi 3,39 % variability prijmu, post hoc test nie je potrebny.

#'
#' ## sektor
sektor <- jednofaktorova("sektor")
#' Shapirove testy ani Bartlettov test pri $\alpha = 0,05$ nezamietaju normalitu a rovnost rozptylov.
#' ANOVA ($p = 0,85544$) nezamieta $H_0$, rozdiel priemerneho prijmu medzi sektormi sa nepreukazal.
#' Sektor vysvetluje iba asi 0,13 % variability prijmu.

#'
#' ## vzdelanie
vzdelanie <- jednofaktorova("vzdelanie")
#' Normalitu ani rovnost rozptylov pri $\alpha = 0,05$ nezamietame.
#' ANOVA ($p = 0,00247$) zamieta $H_0$, vzdelanie vysvetluje asi 6,87 % variability prijmu.
#' Tukeyho test preukazal vyssi prijem skupin 3 a 4 oproti skupine 1, ostatne rozdiely nie su vyznamne.

#'
#' ## miesto vykonavania prace
miesto <- jednofaktorova("miesto")
#' Normalitu ani rovnost rozptylov pri $\alpha = 0,05$ nezamietame.
#' ANOVA ($p = 4,24 \times 10^{-9}$) zamieta $H_0$, miesto vysvetluje asi 16,55 % variability prijmu, najviac zo sledovanych faktorov.
#' Tukeyho test preukazal vyssi prijem v okresnych a krajskych mestach oproti mensim obciam a mestam, ostatne rozdiely nie su vyznamne.

#'
#' # 3. prijem - dvojfaktorova analyza rozptylu, $\alpha = 0,10$

#'
#' ## upravene priemery a post hoc testy
#' Upravene priemery pocitame z modelovych predikcii cez rovnako vazene urovne druheho faktora.
#' Rozdiely overujeme t-testami linearnych kontrastov s Holmovou korekciou v ramci faktora jedneho modelu.
#' 90 % intervaly rozdielov su neupravene, preto rozhodujeme podla $p_{Holm}$.
upravene_porovnania <- function(model, data, premenna, druha, hladina = alfa_dva) {
  premenne <- c(premenna, druha)
  mriezka <- expand.grid(lapply(data[premenne], levels), stringsAsFactors = FALSE)
  names(mriezka) <- premenne
  for (v in premenne) mriezka[[v]] <- factor(mriezka[[v]], levels = levels(data[[v]]))
  X <- model.matrix(delete.response(terms(model)), data = mriezka, contrasts.arg = model$contrasts)
  L <- t(vapply(levels(data[[premenna]]), function(uroven) {
    colMeans(X[mriezka[[premenna]] == uroven, , drop = FALSE])
  }, numeric(ncol(X))))
  rownames(L) <- levels(data[[premenna]])
  odhady <- drop(L %*% coef(model))
  chyby <- sqrt(diag(L %*% vcov(model) %*% t(L)))
  kriticka <- qt(1 - hladina / 2, df.residual(model))
  priemery <- data.frame(skupina = factor(rownames(L), levels = levels(data[[premenna]])),
                         priemer = odhady, dolna = odhady - kriticka * chyby, horna = odhady + kriticka * chyby)

  dvojice <- combn(nrow(L), 2)
  testy <- do.call(rbind, lapply(seq_len(ncol(dvojice)), function(i) {
    a <- dvojice[1, i]
    b <- dvojice[2, i]
    kontrast <- L[b, ] - L[a, ]
    rozdiel <- sum(kontrast * coef(model))
    se <- sqrt(drop(kontrast %*% vcov(model) %*% kontrast))
    t <- rozdiel / se
    data.frame(dvojica = paste(rownames(L)[b], rownames(L)[a], sep = "-"),
               rozdiel = rozdiel, se = se, t = t, df = df.residual(model),
               dolna = rozdiel - kriticka * se, horna = rozdiel + kriticka * se,
               p = 2 * pt(abs(t), df.residual(model), lower.tail = FALSE))
  }))
  testy$p_holm <- p.adjust(testy$p, method = "holm")
  testy$vyznamny <- testy$p_holm < hladina
  list(priemery = priemery, testy = testy)
}

dvojfaktorova <- function(prvy, druhy) {
  premenne <- c(prvy, druhy)
  cat("\n", paste(premenne, collapse = " + "), "\n")
  pocty <- table(prijem[premenne])
  print(pocty)
  bunky <- interaction(prijem[premenne], drop = TRUE)
  popis <- popis_skupin(prijem$prijem, bunky, hladina = alfa_dva)
  print(popis)
  cat("prazdne bunky:", sum(pocty == 0), ", obsadene bunky s menej ako 3 osobami:",
      sum(pocty > 0 & pocty < 3), "\n")
  # Shapiro sa da vypocitat od troch osob. NA neoznacuje splnenu normalitu.
  # Pri mnohych testoch normality moze jednotliva mala p-hodnota vzniknut aj nahodou.
  levene <- car::leveneTest(prijem$prijem, bunky, center = median)
  print(levene)

  aditivny <- lm(reformulate(premenne, response = "prijem"), data = prijem)
  plny <- lm(as.formula(paste("prijem ~", prvy, "*", druhy)), data = prijem)
  interakcia <- anova(aditivny, plny)
  print(interakcia)
  p_interakcia <- interakcia[2, "Pr(>F)"]
  cat("parcialne eta2 interakcie:", (deviance(aditivny) - deviance(plny)) / deviance(aditivny), "\n")
  print(shapiro.test(residuals(plny)))

  # Pre dodane data sa vsade vyberie aditivny model. Ak by interakcia bola vyznamna,
  # interpretovali by sme jednoduche efekty A v jednotlivych urovniach B a naopak.
  if (p_interakcia < alfa_dva) {
    stop("Vyznamna interakcia: treba porovnat jednoduche efekty namiesto aditivnych priemerov.")
  }
  print(anova(lm(prijem ~ 1, data = prijem), aditivny))
  hlavne <- drop1(aditivny, test = "F")
  print(hlavne)
  efekty <- data.frame(faktor = premenne,
                       parcialne_eta2 = hlavne[premenne, "Sum of Sq"] /
                         (hlavne[premenne, "Sum of Sq"] + deviance(aditivny)))
  print(efekty)
  print(c(R2 = summary(aditivny)$r.squared))
  print(shapiro.test(residuals(aditivny)))

  # Doplnkova kontrola citlivosti: HC3 upravuje kovariancnu maticu pri nerovnakych rozptyloch.
  # Nie je to oprava prazdnych buniek ani zaruka spravnosti pri velmi malych skupinach.
  robustne <- car::Anova(aditivny, type = 2, white.adjust = "hc3")
  print(robustne)

  graf_data <- prijem
  graf_data$reziduum <- residuals(aditivny)
  graf_data$odhad <- fitted(aditivny)
  print(ggplot(graf_data, aes(odhad, reziduum)) +
          geom_point(color = farby[2], alpha = 0.55) + geom_hline(yintercept = 0, linetype = 2) +
          theme_minimal() + labs(title = paste("rezidua -", prvy, "+", druhy),
                                 x = "odhadnuty prijem", y = "reziduum"))
  print(ggplot(graf_data, aes(sample = reziduum)) + stat_qq(color = farby[2]) + stat_qq_line() +
          theme_minimal() + labs(title = paste("Q-Q graf rezidui -", prvy, "+", druhy),
                                 x = "teoreticke kvantily", y = "vyberove kvantily"))
  print(ggplot(prijem, aes(x = .data[[prvy]], y = prijem, color = .data[[druhy]], group = .data[[druhy]])) +
          stat_summary(fun = mean, geom = "line", linewidth = 0.6) +
          stat_summary(fun = mean, geom = "point", size = 2) +
          scale_color_manual(values = farby) + theme_minimal() +
          labs(title = paste("interakcny graf -", prvy, "a", druhy),
               subtitle = "pozorovane priemery obsadenych buniek", x = prvy, y = "priemerny rocny prijem", color = druhy))
  print(ggplot(prijem, aes(x = .data[[prvy]], y = prijem, fill = .data[[prvy]])) +
          geom_boxplot(alpha = 0.65) + facet_wrap(vars(.data[[druhy]])) +
          scale_fill_manual(values = farby, guide = "none") + theme_minimal() +
          labs(title = paste("rozdelenie prijmu -", prvy, "podla", druhy), x = prvy, y = "cisty rocny prijem"))

  post <- list()
  for (v in premenne) {
    if (hlavne[v, "Pr(>F)"] < alfa_dva) {
      dalsia <- setdiff(premenne, v)
      post[[v]] <- upravene_porovnania(aditivny, prijem, v, dalsia)
      cat("\nupravene priemery a post hoc testy:", v, "\n")
      print(post[[v]]$priemery)
      print(post[[v]]$testy)
      print(ggplot(post[[v]]$priemery, aes(skupina, priemer, ymin = dolna, ymax = horna, color = skupina)) +
              geom_pointrange() + scale_color_manual(values = farby, guide = "none") + theme_minimal() +
              labs(title = paste("upravene priemery -", v, "pri zohladneni", dalsia),
                   subtitle = "bodove 90 % intervaly spolahlivosti", x = v, y = "upraveny rocny prijem"))
    }
  }
  list(pocty = pocty, popis = popis, levene = levene, plny = plny, model = aditivny,
       interakcia = interakcia, hlavne = hlavne, efekty = efekty, robustne = robustne, post = post)
}

#'
#' ## miesto a vzdelanie
miesto_vzdelanie <- dvojfaktorova("miesto", "vzdelanie")
#' Pri $\alpha = 0,10$ sa interakcia nepreukazala ($p = 0,4700$), ale miesto ($p = 4,95 \times 10^{-8}$) aj vzdelanie ($p = 0,01806$) su vyznamne.
#' Holmova korekcia potvrdila dvojice (3, 1), (4, 1), (3, 2), (4, 2) pre miesto a (3, 1), (4, 1) pre vzdelanie.
#' Rovnost rozptylov ani normalitu rezidui nezamietame, normalitu jednej bunky vsak zamietame a vyznamnost oboch faktorov potvrdzuje aj HC3.

#'
#' ## vek a miesto
vek_miesto <- dvojfaktorova("vek", "miesto")
#' Interakcia sa nepreukazala ($p = 0,7115$), vyznamne je iba miesto ($p = 1,06 \times 10^{-8}$), nie vek ($p = 0,1530$).
#' Holmova korekcia potvrdila dvojice miest (3, 1), (4, 1), (3, 2), (4, 2) a HC3 potvrdzuje rozhodnutie o faktoroch.
#' Nerovnake rozptyly a bunka s iba dvoma osobami obmedzuju spolahlivost analyzy, klasicke post hoc vysledky preto berieme ako orientacne.

#'
#' ## vek a sektor
vek_sektor <- dvojfaktorova("vek", "sektor")
#' Normalitu ani rovnost rozptylov pri $\alpha = 0,10$ nezamietame, interakcia ($p = 0,9247$) ani sektor ($p = 0,89961$) nie su vyznamne.
#' Vek je tesne vyznamny ($p = 0,09918$), ale celkovy model ($p = 0,22777$) ani ziadna vekova dvojica po Holmovej korekcii vyznamne nie su.
#' HC3 vyznamnost veku nepotvrdzuje ($p = 0,1291$), preto je tento vysledok citlivy na pouzitu metodu.

#'
#' ## vek a vzdelanie
vek_vzdelanie <- dvojfaktorova("vek", "vzdelanie")
#' Pri $\alpha = 0,10$ sa interakcia nepreukazala ($p = 0,1633$), ale vek ($p = 0,08312$) aj vzdelanie ($p = 0,002336$) su v klasickom modeli vyznamne.
#' Holmova korekcia potvrdila nizsi prijem vekovej skupiny 56+ oproti 36 az 45 rokom a vyssi prijem vzdelanostnych skupin 3 a 4 oproti skupine 1.
#' Prazdne a male bunky obmedzuju analyzu, HC3 potvrdzuje iba vzdelanie, preto vyznamnost veku nie je robustna.

#'
#' # 4. dieta - percentualna strata hmotnosti
#' $strata\,(\%) = 100 \times \frac{hmotnost_{pred} - hmotnost_{po}}{hmotnost_{pred}}$.
#' 100 % je vlastna povodna hmotnost kazdeho klienta. Pocitame individualne percenta, nie percento z priemerov.
#' kladna strata znamena schudnutie a zaporna strata pribratie. Tieto hodnoty automaticky nevyradujeme.
dieta$strata_percent <- 100 * (dieta$pred - dieta$po) / dieta$pred
table(dieta$pohlavie)
table(dieta$pohlavie, pribratie = dieta$strata_percent < 0)

popis_diety <- popis_skupin(dieta$strata_percent, dieta$pohlavie)


popis_diety
print(graf_skupin(dieta, "strata_percent", "pohlavie", "percentualna strata hmotnosti", "strata hmotnosti (%)") +
        geom_hline(yintercept = 0, linetype = 2, color = farby[1]))
print(ggplot(dieta, aes(strata_percent, fill = pohlavie)) +
        geom_histogram(bins = 15, color = "white", alpha = 0.7) + facet_wrap(~ pohlavie) +
        scale_fill_manual(values = farby, guide = "none") + theme_minimal() +
        labs(title = "rozdelenie percentualneho ubytku", x = "strata hmotnosti (%)", y = "pocet klientov"))
print(graf_normality(dieta, "strata_percent", "pohlavie", "Q-Q grafy percentualnej straty"))
#' Priemerna strata hmotnosti bola 9,52835 % u zien a 9,10123 % u muzov.
#' Pribralo 20 zien a 19 muzov, tieto vecne mozne hodnoty ponechavame v analyze.
#' Zadanie predpoklada normalitu, no Shapirov test ju u muzov zamieta ($p = 0,008866$), preto vysledky t-testov hodnotime s touto vyhradou.

#'
#' ## rozdiel percentualnej straty medzi muzmi a zenami
#' $H_0: \mu_{zeny} = \mu_{muzi}$, $H_1: \mu_{zeny} \neq \mu_{muzi}$, $\alpha = 0,05$.
#' ide o dva nezavisle vybery klientov. Pred/po u tej istej osoby zostava sparovane pri vypocte percenta.
#' medzi pohlaviami nepouzivame parovy t-test ani neporovnavame samotne konecne hmotnosti.
test_rozptylov_dieta <- var.test(strata_percent ~ pohlavie, data = dieta)
test_rozptylov_dieta
#' F-test rozptylov: $F = 1,10441$, $p = 0,6216$, rovnost rozptylov nezamietame.
#' napriek tomu volime Welchov t-test, ktory rovnost rozptylov nepotrebuje.
test_pohlavie <- stats::t.test(strata_percent ~ pohlavie, data = dieta,
                              var.equal = FALSE, alternative = "two.sided", conf.level = 1 - alfa)
test_pohlavie
rozdiel_pohlavie <- mean(dieta$strata_percent[dieta$pohlavie == "zeny"]) -
  mean(dieta$strata_percent[dieta$pohlavie == "muzi"])
rozdiel_pohlavie
#' Welchov t-test ($p = 0,75543$) nezamieta $H_0$, rozdiel priemernej percentualnej straty medzi pohlaviami sa nepreukazal.
#' Zeny stratili priemerne o 0,42712 percentualneho bodu viac, 95 % interval rozdielu od -2,27314 do 3,12738 vsak obsahuje nulu.
#' Nezamietnutie $H_0$ nie je dokaz rovnakej ucinnosti programu pre obe pohlavia.

#'
#' ## predpoklad poradkyne pre zeny
#' $H_0: \mu_{zeny} = 13\,\%$, $H_1: \mu_{zeny} \neq 13\,\%$, $\alpha = 0,05$.
#' overujeme konkretny predpoklad, preto pouzijeme obojstranny jednovyberovy t-test.
zeny <- dieta$strata_percent[dieta$pohlavie == "zeny"]
test_zeny <- stats::t.test(zeny, mu = 13, alternative = "two.sided", conf.level = 1 - alfa)
test_zeny
c(rozdiel_od_predpokladu = mean(zeny) - 13)
#' Jednovyberovy t-test ($p = 0,0006188$) zamieta $H_0$, priemerna strata zien je nizsia nez predpokladanych 13 %.
#' Dosiahnuty priemer je 9,52835 % a jeho 95 % interval od 7,57930 % do 11,47740 % neobsahuje 13 %.
#' Predpoklad poradkyne pre zeny data nepodporuju, samostatny test tvrdenia o muzoch zadanie nepozaduje.

popis_diety$predpoklad <- c(13, 15)[match(as.character(popis_diety$skupina), c("zeny", "muzi"))]
print(ggplot(popis_diety, aes(skupina, priemer, ymin = dolna, ymax = horna, color = skupina)) +
        geom_pointrange() + geom_point(aes(y = predpoklad), shape = 4, size = 3, stroke = 1.1) +
        scale_color_manual(values = farby, guide = "none") + theme_minimal() +
        labs(title = "priemerna percentualna strata a 95 % intervaly",
             subtitle = "kriziky: predpoklady poradkyne 13 % a 15 %",
             x = "pohlavie", y = "strata povodnej hmotnosti (%)"))

#'
#' # zaver
#' Prijem sa pri $\alpha = 0,05$ lisi podla vzdelania a miesta prace, rozdiel podla veku a sektora sa nepreukazal.
#' Dvojfaktorove modely nepreukazali interakcie a vyznamnost veku je citliva na pouzitu metodu a obmedzenia dat.
#' Rozdiel percentualnej straty medzi pohlaviami sa nepreukazal, priemerna strata zien je vsak nizsia nez predpokladanych 13 %.
