#'
#' # zadanie 4
#' Samuel Bagin
library(readxl)
library(ggplot2)
library(viridisLite)
library(car)

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

#' prvy harok prijem.xlsx obsahuje 235 osob, druhy harok nie je tabulka respondentov.
#' dieta.xlsx obsahuje 202 klientov. V analyzovanych tabulkach nie su chybajuce hodnoty ani zhodne riadky.
#' kody kategorii su faktory, nie spojite ciselne premenne; respondent je iba identifikator.
#' vek: 1 = 18-25 r., 2 = 26-35 r., 3 = 36-45 r., 4 = 46-55 r., 5 = 56 a viac rokov.
#' vzdelanie: 1 = ZS/SS bez maturity, 2 = SS s maturitou, 3 = VS 1. stupna,
#' 4 = VS 2. stupna, 5 = VS 3. stupna.
#' miesto: 1 = mensia obec, 2 = mensie mesto, 3 = okresne mesto, 4 = krajske mesto.
#' sektor: 1 = sluzby, 2 = vyroba, 3 = obchod.
#' prijem je cisty ROCNY prijem. Zadanie neuvadza menu, preto ju v grafoch nedoplname.
#' pre jednofaktorove analyzy a dietu volime α = 0,05; pre dvojfaktorove analyzy zadanie urcuje α = 0,10.
#' predpokladame nezavisle osoby a nezavisle chyby; to nemozno overit zo samotnej tabulky.
#' pozorovacie data o prijme ukazuju suvislosti, nedokazuju pricinnu zavislost.

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
#' pre kazdy faktor testujeme H₀: µ₁ = ... = µₖ, H₁: aspon dve stredne hodnoty sa lisia.
#' normalita v skupinach: H₀ = normalne rozdelenie, H₁ = rozdelenie nie je normalne.
#' Bartlettov test: H₀: σ₁² = ... = σₖ², H₁: aspon dva rozptyly sa lisia.
#' pri splnenych predpokladoch pouzijeme ANOVA a po vyznamnom vysledku Tukeyho-Kramerov post hoc test.
#' TukeyHSD pri roznych velkostiach skupin zohladnuje ich pocty.
#' nezamietnutie H₀ nie je dokaz rovnosti priemerov ani dokaz splnenia predpokladov.
#' mierou efektu je η² = SS_faktor / SS_celkove, teda podiel vysvetlenej variability prijmu.

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
  # Kruskalov-Wallisov test testuje poradia/rozdelenia; nie je vseobecne testom rovnosti priemerov.
  if (bartlett$p.value < alfa || any(popis$p_shapiro < alfa, na.rm = TRUE)) {
    print(oneway.test(formula, data = prijem, var.equal = FALSE))
    print(kruskal.test(formula, data = prijem))
  }
  list(popis = popis, bartlett = bartlett, model = model, tabulka = tabulka, eta2 = eta2, post = post)
}

#'
#' ## vek
vek <- jednofaktorova("vek")
#' Shapirove p-hodnoty su 0,9491; 0,8372; 0,1745; 0,9258; 0,2824, Bartlett p = 0,2691.
#' na hladine 0,05 predpoklady nezamietame, Q-Q grafy kontrolujeme aj vizualne.
#' ANOVA: F(4, 230) = 2,0172, p = 0,09287. H₀ nezamietame, rozdiel priemerov podla veku sa nepreukazal.
#' priemery skupin 1-5 su 13798,58; 14147,28; 14475,46; 14300,88; 12967,39.
#' η² = 0,03389, vek opisuje asi 3,39 % variability prijmu. Post hoc test nie je potrebny.

#'
#' ## sektor
sektor <- jednofaktorova("sektor")
#' vsetky Shapirove p-hodnoty su nad 0,05 a Bartlett p = 0,5498.
#' ANOVA: F(2, 232) = 0,1562, p = 0,85544. H₀ nezamietame.
#' priemery sluzieb, vyroby a obchodu su 13983,38; 14151,77; 14045,74.
#' η² = 0,00135, sektor opisuje iba asi 0,13 % variability prijmu.

#'
#' ## vzdelanie
vzdelanie <- jednofaktorova("vzdelanie")
#' najmensia Shapirova p-hodnota je 0,06207 a Bartlett p = 0,1823; pri α = 0,05 predpoklady nezamietame.
#' ANOVA: F(4, 230) = 4,2432, p = 0,00247. H₀ zamietame, priemerny prijem sa podla vzdelania lisi.
#' η² = 0,06872, vzdelanie opisuje asi 6,87 % variability prijmu.
#' Tukey: vyznamne su dvojice 3-1 (rozdiel 1358,06; p_adj = 0,00615)
#' a 4-1 (rozdiel 1552,36; p_adj = 0,00422). Vyssi prijem maju skupiny 3 a 4 oproti skupine 1.
#' ostatne dvojice nie su na hladine 0,05 vyznamne; pre skupinu 5 nepreukazujeme vyssi prijem oproti 1.

#'
#' ## miesto vykonavania prace
miesto <- jednofaktorova("miesto")
#' vsetky Shapirove p-hodnoty su nad 0,05 a Bartlett p = 0,1096.
#' ANOVA: F(3, 231) = 15,2736, p = 4,24e-9. H₀ zamietame.
#' η² = 0,16552, miesto opisuje asi 16,55 % variability prijmu, najviac zo sledovanych faktorov.
#' Tukey: vyznamne su 3-1, 4-1, 3-2 a 4-2 (p_adj = 0,000172; 0,0000003; 0,00326; 0,0000039).
#' okresne a krajske mesta maju vyssi priemer nez mensie obce a mensie mesta.
#' rozdiely 2-1 a 4-3 nie su vyznamne. Priemery skupin 1-4: 12893,61; 13343,12; 14404,64; 14941,95.
#' samotny prekryv intervalov v grafe nenahradza post hoc test.

#'
#' # 3. prijem - dvojfaktorova analyza rozptylu, α = 0,10
#' plny model: prijem = µ + Aᵢ + Bⱼ + (AB)ᵢⱼ + ε.
#' interakcia: H₀ = vsetky odhadnutelne interakcne efekty su nulove, H₁ = aspon jeden je nenulovy.
#' porovname vnorene modely A + B a A * B pomocou parcialneho F-testu.
#' kedze interakcia nie je v ziadnej dvojici vyznamna, hlavne efekty hodnotime v aditivnom modeli A + B.
#' pre faktor A: H₀ = vsetky jeho efekty po zohladneni B su nulove, H₁ = aspon jeden je nenulovy;
#' analogicky pre B. Drop1 testuje kazdy faktor po zohladneni druheho, ide o testy typu II.
#' pri nerovnakych poctoch osob nepouzivame sekvencne sucty stvorcov zavisle od poradia faktorov.
#' celkovy F-test modelu ma H₀: oba hlavne efekty su nulove. Zamietnutie znamena aspon jeden efekt,
#' nie automaticky vyznamnost oboch faktorov. Tu hodnotime aj kazdy faktor osobitne.
#' mierou efektu je parcialne η² = SS_efekt / (SS_efekt + SS_chyba).
#' pri interakcii pouzijeme SS_efekt = RSS_aditivny - RSS_plny a SS_chyba = RSS_plny.
#' parcialne η² faktorov sa nesu scitat. R² doplnkovo opisuje vysvetlenu variabilitu celeho modelu.

#'
#' ## upravene priemery a post hoc testy
#' pre kazdu uroven spriemerujeme modelove predikcie cez rovnako vazene urovne druheho faktora.
#' ide o upravene priemery, ktore zohladnuju druhy faktor; v aditivnom modeli ich rozdiel nezavisi od tychto vah.
#' rozdiely testujeme t-testami linearnych kontrastov modelu, so spolocnym rezidualnym rozptylom.
#' Holmova korekcia kontroluje viacnasobne porovnavania v ramci jedneho faktora jedneho modelu.
#' intervaly rozdielov su neupravene 90 %, preto rozhodujeme podla p_holm, nie podla ich prekryvu s nulou.
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
  cat("prazdne bunky:", sum(pocty == 0), "; obsadene bunky s menej ako 3 osobami:",
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
#' vsetky bunky maju aspon 4 osoby. V bunke miesto 2, vzdelanie 3 je Shapiro p = 0,06115 < 0,10.
#' normalitu tejto bunky pri zvolenej hladine zamietame; pri viacnasobnej diagnostike zaver neprecenujeme.
#' Levene p = 0,7553, rovnost rozptylov nezamietame. Normalitu rezidui aditivneho modelu nezamietame (p = 0,6008).
#' interakcia: F(12, 215) = 0,9789, p = 0,4700; nepreukazala sa, parcialne η² = 0,05181.
#' aditivny model: miesto p = 4,95e-8, vzdelanie p = 0,01806. Oba faktory su pri α = 0,10 vyznamne.
#' celkovy model p = 2,95e-9; R² = 0,20799. Parcialne η²: miesto 0,14954, vzdelanie 0,05088.
#' post hoc miesto: vyznamne 3-1, 4-1, 3-2, 4-2; p_holm = 0,0003035; 0,0000012; 0,004629; 0,0000197.
#' rozdiely po zohladneni vzdelania su 1413,56; 1924,96; 963,78 a 1475,18.
#' post hoc vzdelanie: vyznamne iba 3-1 a 4-1; p_holm = 0,02286 a 0,04370, rozdiely 1137,56 a 1167,76.
#' HC3 potvrdi vyznamnost oboch faktorov (miesto p = 4,98e-8, vzdelanie p = 0,00948).
#' pri vyraznej nenormalite by bolo vhodne overit zavery robustnym modelom alebo vhodnym bootstrapom rezidui.

#'
#' ## vek a miesto
vek_miesto <- dvojfaktorova("vek", "miesto")
#' bunka vek 3, miesto 3 ma iba 2 osoby, preto v nej normalitu Shapirovym testom neoverime.
#' ostatne testovatelne bunky maju p > 0,10. Levene p = 0,08426 < 0,10, rovnost rozptylov zamietame.
#' ANOVA sa vykona podla zadania, ale predpoklad spolocneho rozptylu nie je podlozeny.
#' interakcia: F(12, 215) = 0,7398, p = 0,7115; nepreukazala sa, parcialne η² = 0,03965.
#' aditivny model: vek p = 0,1530, miesto p = 1,06e-8. Pri zohladneni miesta vek nie je vyznamny.
#' vyznamny je iba faktor miesto, teda nepreukazujeme vyznamnost oboch faktorov sucasne.
#' celkovy model p = 3,17e-8; R² = 0,18967. Parcialne η²: vek 0,02893, miesto 0,16124.
#' post hoc miesto: vyznamne 3-1, 4-1, 3-2, 4-2; rozdiely 1504,35; 2025,80; 1008,72; 1530,17.
#' p_holm = 0,0001302; 0,00000034; 0,003369; 0,0000102. Dvojice 2-1 a 4-3 vyznamne nie su.
#' odporucane riesenie je model s heteroskedasticitou, HC3 alebo wild bootstrap aj pre kontrasty.
#' HC3: vek p = 0,1834, miesto p = 3,18e-8; rozhodnutie o faktoroch sa nemeni.
#' uvedene post hoc p-hodnoty su klasicke a pri nerovnosti rozptylov ich berieme ako orientacne.

#'
#' ## vek a sektor
vek_sektor <- dvojfaktorova("vek", "sektor")
#' vsetky bunky maju aspon 4 osoby, Shapirove p-hodnoty su nad 0,10 a Levene p = 0,7315.
#' interakcia: F(8, 220) = 0,3910, p = 0,9247; nepreukazala sa, parcialne η² = 0,01402.
#' aditivny model: vek p = 0,09918, sektor p = 0,89961. Vek je pri α = 0,10 iba tesne vyznamny.
#' celkovy model p = 0,22777 vyznamny nie je; nepreukazujeme celkovy prinos dvojice faktorov.
#' R² = 0,03479. Parcialne η²: vek 0,03349, sektor 0,00093.
#' po Holmovej korekcii sa nepreukaze ziadna dvojica vekovych kategorii (minimum p_holm = 0,17883).
#' vyznamny omnibus test jedneho faktora nemusi viest k vyznamnej dvojici po korekcii.
#' HC3: vek p = 0,1291, sektor p = 0,9095. Hranicny klasicky vysledok veku teda nie je robustny.
#' aj v plnom modeli s interakciou je test typu II pre vek p = 0,1060; zaver zavisi od specifikacie modelu.

#'
#' ## vek a vzdelanie
vek_vzdelanie <- dvojfaktorova("vek", "vzdelanie")
#' prazdne su bunky vek 1/vzdelanie 5 a vek 3/vzdelanie 5.
#' vek 3/vzdelanie 3 a vek 5/vzdelanie 2 maju po 1 osobe;
#' vek 5/vzdelanie 4 a vek 5/vzdelanie 5 maju po 2 osobach. V tychto 4 bunkach normalitu neoverime.
#' v bunke vek 5/vzdelanie 1 je Shapiro p = 0,03674 < 0,10, normalitu zamietame.
#' Levene p = 0,7138, rovnost rozptylov nezamietame, no male bunky obmedzuju silu diagnostiky.
#' Bartlettov test pre vsetky bunky nemoze byt pouzity, lebo dve obsadene bunky maju iba 1 osobu.
#' interakcia: F(14, 212) = 1,3828, p = 0,1633; nepreukazala sa, parcialne η² = 0,08368.
#' test ma 14 stupnov volnosti namiesto 16, pretoze 2 kombinacie chybaju.
#' ide iba o odhadnutelnu cast interakcie; nepreukazana interakcia nie je dokaz jej nepritomnosti.
#' aditivny model je odhadnutelny, ale pri prazdnych bunkach vyzaduje predpoklad aditivity.
#' vek p = 0,08312, vzdelanie p = 0,002336. V klasickom aditivnom modeli su oba faktory pri α = 0,10 vyznamne.
#' celkovy model p = 0,001806; R² = 0,10193. Parcialne η²: vek 0,03566, vzdelanie 0,07042.
#' post hoc vek: vyznamna iba dvojica 5-3; rozdiel -1713,62, p_holm = 0,07822.
#' po zohladneni vzdelania ma vek 56+ nizsi upraveny prijem nez vek 36-45 rokov.
#' post hoc vzdelanie: vyznamne 3-1 a 4-1, rozdiely 1377,94 a 1434,98; p_holm = 0,00666 a 0,01119.
#' HC3: vek p = 0,14194, vzdelanie p = 0,00442. Vyznamnost veku je citliva na pouzitu metodu.
#' odporucame doplnit male/prazdne bunky a overit zavery robustnym modelom alebo wild bootstrapom.
#' transformacia ani neparametricky test chybajuce kombinacie nenahradia; pripadne spajanie kategorii musi mat vecny dovod.

#'
#' ## obmedzenia dvojfaktorovej analyzy
#' v grafoch spojnice sleduju priemery kategorii, nie spojity priebeh faktora.
#' pri prazdnych bunkach ide iba o zobrazene existujuce kombinacie, chybajuce priemery nedoplname.
#' v ziadnej dvojici sme pri α = 0,10 nepreukazali interakciu, tym vsak jej presnu nulovost nedokazujeme.
#' pri poruseni rozptylov nemoze samostatna Welchova jednofaktorova ANOVA nahradit test dvoch faktorov a interakcie.
#' klasicke post hoc porovnania vychadzaju z aditivneho modelu; ich nominalna hladina nezohladnuje vyber modelu.
#' testy jednotlivych faktorov a styroch modelov hodnotime samostatne, bez spolocnej korekcie celej ulohy.
#' post hoc dvojice v ramci faktora su korigovane Tukeyho alebo Holmovou metodou.

#'
#' # 4. dieta - percentualna strata hmotnosti
#' strata (%) = 100 × (hmotnost_pred - hmotnost_po) / hmotnost_pred.
#' 100 % je vlastna povodna hmotnost kazdeho klienta. Pocitame individualne percenta, nie percento z priemerov.
#' kladna strata znamena schudnutie a zaporna strata pribratie; tieto hodnoty automaticky nevyradujeme.
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
#' 103 zien stratilo priemerne 9,52835 % (sd = 9,97264 p. b.), 99 muzov 9,10123 % (sd = 9,48953 p. b.).
#' pribralo 20 zien a 19 muzov. Tieto zaporne straty su vecne mozne a zostavaju v analyze.
#' zadanie pri kazdom teste predpoklada normalitu, preto pouzijeme parametricke testy.
#' doplnkova diagnostika: Shapiro p = 0,7550 pre zeny a p = 0,008866 pre muzov.
#' u muzov empiricka diagnostika normalitu zamieta, vysledok t-testu preto hodnotime aj s tymto obmedzenim.
#' pri priblizne 100 osobach na skupinu je t-test pomerne robustny; pri silnych odchylkach by sme overili
#' rozdiel priemerov bootstrapom nezavislych osob. Wilcoxonov test vseobecne netestuje rovnost priemerov.

#'
#' ## rozdiel percentualnej straty medzi muzmi a zenami
#' H₀: µ_zeny = µ_muzi, H₁: µ_zeny ≠ µ_muzi, α = 0,05.
#' ide o dva nezavisle vybery klientov. Pred/po u tej istej osoby zostava sparovane pri vypocte percenta;
#' medzi pohlaviami nepouzivame parovy t-test ani neporovnavame samotne konecne hmotnosti.
test_rozptylov_dieta <- var.test(strata_percent ~ pohlavie, data = dieta)
test_rozptylov_dieta
#' F-test rozptylov: F = 1,10441, p = 0,6216, rovnost rozptylov nezamietame.
#' napriek tomu volime Welchov t-test, ktory rovnost rozptylov nepotrebuje.
test_pohlavie <- stats::t.test(strata_percent ~ pohlavie, data = dieta,
                              var.equal = FALSE, alternative = "two.sided", conf.level = 1 - alfa)
test_pohlavie
rozdiel_pohlavie <- mean(dieta$strata_percent[dieta$pohlavie == "zeny"]) -
  mean(dieta$strata_percent[dieta$pohlavie == "muzi"])
rozdiel_pohlavie
#' t = 0,31191, df = 199,98, p = 0,75543. H₀ nezamietame, rozdiel priemernych percent sa nepreukazal.
#' zeny mali vyssi priemerny ubytok o 0,42712 percentualneho bodu.
#' 95 % interval rozdielu zeny - muzi je (-2,27314; 3,12738) p. b. a obsahuje nulu.
#' nezamietnutie nie je dokaz rovnakej ucinnosti programu pre obe pohlavia.

#'
#' ## predpoklad poradkyne pre zeny
#' H₀: µ_zeny = 13 %, H₁: µ_zeny ≠ 13 %, α = 0,05.
#' overujeme konkretny predpoklad, preto pouzijeme obojstranny jednovyberovy t-test.
zeny <- dieta$strata_percent[dieta$pohlavie == "zeny"]
test_zeny <- stats::t.test(zeny, mu = 13, alternative = "two.sided", conf.level = 1 - alfa)
test_zeny
c(rozdiel_od_predpokladu = mean(zeny) - 13)
#' t = -3,53300, df = 102, p = 0,0006188. H₀ zamietame.
#' priemerny ubytok zien 9,52835 % je o 3,47165 percentualneho bodu nizsi nez predpokladanych 13 %.
#' 95 % interval priemernej straty zien je (7,57930; 11,47740) % a neobsahuje 13 %.
#' predpoklad poradkyne pre zeny preto data nepodporuju; priemerny ubytok je statisticky vyznamne nizsi.
#' 15 % pre muzov je uvedenych v opise, ale samostatny test tohto tvrdenia zadanie nepozaduje.

popis_diety$predpoklad <- c(13, 15)[match(as.character(popis_diety$skupina), c("zeny", "muzi"))]
print(ggplot(popis_diety, aes(skupina, priemer, ymin = dolna, ymax = horna, color = skupina)) +
        geom_pointrange() + geom_point(aes(y = predpoklad), shape = 4, size = 3, stroke = 1.1) +
        scale_color_manual(values = farby, guide = "none") + theme_minimal() +
        labs(title = "priemerna percentualna strata a 95 % intervaly", subtitle = "kriziky: predpoklady poradkyne 13 % a 15 %",
             x = "pohlavie", y = "strata povodnej hmotnosti (%)"))

#'
#' # zaver
#' pri α = 0,05 sa prijem lisi podla vzdelania a miesta prace, rozdiel podla veku a sektora sa nepreukazal.
#' v klasickych dvojfaktorovych aditivnych modeloch pri α = 0,10:
#' miesto + vzdelanie: oba faktory vyznamne; vek + miesto: vyznamne iba miesto;
#' vek + sektor: vek tesne vyznamny, no ziadna dvojica a ani celkovy model nie su vyznamne;
#' vek + vzdelanie: oba faktory vyznamne, vekova dvojica 5-3 sa lisi pri Holmovej korekcii.
#' interakcie sa nepreukazali. Vysledky veku su citlive: pri HC3 nie je vek vyznamny v ziadnej dvojici.
#' pri veku a mieste je porusena rovnost rozptylov; pri veku a vzdelani chybaju kombinacie a su male bunky.
#' medzi pohlaviami sa rozdiel percentualnej straty nepreukazal, ale priemerna strata zien je nizsia nez 13 %.
