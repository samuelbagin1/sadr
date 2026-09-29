#| include: false
knitr::opts_chunk$set(
  fig.width = 15,
  fig.height = 14,
  out.width = "100%"
)
#'
library(palmerpenguins)
View(penguins)

# funkcia na zobrazovanie grafov podla skupin
grafy_podla_skupin <- function(data = NULL, stlpec = NULL, podla = NULL,
              skupiny = NULL, nazov_hodnoty = NULL, nazov_skupiny = NULL) {
  
  if (is.null(skupiny)) {
    if (is.null(stlpec) || length(stlpec) != 1L ||
        !(stlpec %in% names(data))) {
      stop("Zadaj existujúci stĺpec. Dostupné: ",
           paste(names(data), collapse = ", "))
    }
    
    if (!is.numeric(data[[stlpec]])) {
      stop("Stĺpec ", stlpec, " musí obsahovať čísla.")
    }
    
    if (is.null(podla)) {
      skupiny <- list("Všetky merania" = data[[stlpec]])
    } else {
      if (length(podla) != 1L || !is.character(podla)) {
        stop("Podla musí byť názov jedného alebo dvoch stĺpcov.")
      }
      
      stlpce_podla <- trimws(strsplit(podla, "+", fixed = TRUE)[[1]])
      
      if (length(stlpce_podla) < 1L || length(stlpce_podla) > 2L ||
          any(!nzchar(stlpce_podla)) ||
          !all(stlpce_podla %in% names(data))) {
        stop("Podla musí obsahovať jeden alebo dva existujúce stĺpce.")
      }
      
      skupina <- if (length(stlpce_podla) == 1L) {
        data[[stlpce_podla]]
      } else {
        interaction(data[[stlpce_podla[1L]]],
                    data[[stlpce_podla[2L]]],
                    drop = TRUE, sep = " + ")
      }
      
      skupiny <- split(data[[stlpec]], skupina, drop = TRUE)
    }
  }
  
  
  if (is.null(nazov_hodnoty)) {
    nazov_hodnoty <- if (is.null(stlpec)) "Hodnota" else stlpec
  }
  
  if (is.null(nazov_skupiny)) {
    nazov_skupiny <- if (is.null(podla)) "Skupina" else podla
  }
  
  if (length(skupiny) == 0 || any(!vapply(skupiny, is.numeric, logical(1))) || any(lengths(skupiny) < 2)) {
    stop("Skupiny musia obsahovat aspon dve ciselne merania.")
  }
  
  if (is.null(names(skupiny))) {
    names(skupiny) <- paste("Skupina", seq_along(skupiny))
  }
  
  # veridis color scheme
  farby <- grDevices::colorRampPalette(
    c("#440154", "#21918C", "#FDE725")
  )(length(skupiny))
  
  rozsah <- range(unlist(skupiny))
  krivky <- lapply(skupiny, density)
  horna <- max(vapply(krivky, function(k) max(k$y), numeric(1)))
  
  povodne_nastavenia <- par(no.readonly = TRUE)
  on.exit(par(povodne_nastavenia))
  par(
    mfrow = c(ceiling((length(skupiny) + 3) / 3), 3),
    mar = c(3.8, 3.8, 2.6, 0.8),
    mgp = c(2.2, 0.7, 0),
    cex.main = 0.85
  )
  
  # histogram kazdej skupiny
  for (i in seq_along(skupiny)) {
    hist(skupiny[[i]], probability = TRUE,
         xlim = rozsah, border = "white",
         main = paste(nazov_skupiny, ":", names(skupiny)[i]),
         xlab = nazov_hodnoty, ylab = "hustota")
  }
  
  # krivky hustoty
  plot(NA, xlim = rozsah, ylim = c(0, horna),
       xlab = nazov_hodnoty, ylab = "hustota",
       main = paste("hustota podla", nazov_skupiny))
  
  for (i in seq_along(krivky)) {
    lines(krivky[[i]], col = farby[i], lwd = 2)
  }
  
  legend("topright", legend = names(skupiny),
         col = farby, lwd = 2, bty = "n", cex = 0.65)
  
  # stlpcovy graf priemerov
  priemery <- vapply(skupiny, mean, numeric(1))
  barplot(priemery, col = farby, xlab = nazov_skupiny,
          ylab = paste("priemer:", nazov_hodnoty), main = paste("priemer podla", nazov_skupiny))
  
  # boxplot
  boxplot(skupiny, horizontal = TRUE, col = farby,
          xlab = nazov_hodnoty, ylab = nazov_skupiny, main = paste("Boxplot podľa", nazov_skupiny))
}

# funkcia na vypocet zakladnych vlastnosti podla stlpca a filtra
popisne_statistiky <- function(data = NULL, stlpec = NULL,
                               podla = NULL, skupiny = NULL) {
  vypocitaj <- function(x) {
    list(
      count = length(x),
      mean = mean(x),
      median = median(x),
      modus = modeest::mfv(x),
      kvantily = quantile(x),
      rozsah = setNames(range(x), c("minimum", "maximum")),
      IQR = IQR(x),
      rozptyl = var(x),
      smerodajna_odchylka = sd(x)
    )
  }
  
  if (is.null(data) || is.null(stlpec) ||
      length(stlpec) != 1L || !(stlpec %in% names(data))) {
    stop("Stĺpec neexistuje. Dostupné stĺpce: ",
         paste(names(data), collapse = ", "))
  }
  
  if (!is.numeric(data[[stlpec]])) {
    stop("Stĺpec ", stlpec, " musí obsahovať čísla.")
  }
  
  if (is.null(podla)) {
    return(vypocitaj(data[[stlpec]]))
  }
  
  if (!is.character(podla) || length(podla) != 1L || is.na(podla)) {
    stop("Podla musí byť názov jedného alebo dvoch stĺpcov.")
  }
  
  stlpce_podla <- trimws(strsplit(podla, "+", fixed = TRUE)[[1]])
  
  if (startsWith(trimws(podla), "+") ||
      endsWith(trimws(podla), "+") ||
      length(stlpce_podla) < 1L ||
      length(stlpce_podla) > 2L ||
      any(!nzchar(stlpce_podla)) ||
      !all(stlpce_podla %in% names(data))) {
    stop("Podla musí obsahovať jeden alebo dva existujúce stĺpce.")
  }
  
  skupina <- if (length(stlpce_podla) == 1L) {
    data[[stlpce_podla]]
  } else {
    interaction(
      data[[stlpce_podla[1L]]],
      data[[stlpce_podla[2L]]],
      drop = TRUE,
      sep = " + "
    )
  }
  
  stlpce_podla <- trimws(strsplit(podla, "+", fixed = TRUE)[[1]])

if (length(stlpce_podla) < 1L || length(stlpce_podla) > 2L ||
    !all(stlpce_podla %in% names(data))) {
  stop("Podla musí obsahovať jeden alebo dva existujúce stĺpce.")
}

skupina <- if (length(stlpce_podla) == 1L) {
  data[[stlpce_podla]]
} else {
  interaction(data[[stlpce_podla[1L]]],
              data[[stlpce_podla[2L]]],
              drop = TRUE, sep = " + ")
}

lapply(split(data[[stlpec]], skupina, drop = TRUE), vypocitaj)
}




data <- penguins
str(data)
head(data)
summary(data)
colSums(is.na(data))
mice::md.pattern(data)
#' pri 2 riadkoch chyba az 5 hodnot a pri 9 riadkoch chyba hodnota v stlpci pohlavia
Amelia::missmap(data)


#' dropnutie riadkov s prazdnymi hodnotami
clean_data <- na.omit(data)

clean_data$bill_len <- clean_data$bill_length_mm
clean_data$bill_dep <- clean_data$bill_depth_mm
clean_data$flipper_len <- clean_data$flipper_length_mm
clean_data$body_mass <- clean_data$body_mass_g

#'
#'# dlzka zobaka
hist(clean_data$bill_len)

par(mfrow = c(1, 3))
plot(density(clean_data$bill_len))
barplot(table(clean_data$bill_len))
boxplot(clean_data$bill_len, horizontal = T)

mean(clean_data$bill_len)
median(clean_data$bill_len)
modeest::mfv(clean_data$bill_len)
quantile(clean_data$bill_len)
range(clean_data$bill_len)
IQR(clean_data$bill_len)
var(clean_data$bill_len)
sd(clean_data$bill_len)

#' typicka dlzka zobaka je problizne 44mm, median je 44.5mm co znamena ze polovica tucniakov ma zobak kratsi ako median
#' polovica merani (1. a 3. kvantil - medzi 25% a 75% meranymi dat) lezi medzi 39.5mm a 48.6mm, sirka medzi kvartiloveho rozdielu je 9.1mm
#' najkratsi zobak meral 32.1mm a najdlhsi 59.6mm, smerodajna odchylka je 5.47mm
#' graf hustoty vsak ukazuje dva vrcholy, co naznacuje dve skupiny tucniakov

qqnorm(clean_data$bill_len)
qqline(clean_data$bill_len)

vioplot::vioplot(clean_data$bill_len)

moments::skewness(clean_data$bill_len)
moments::kurtosis(clean_data$bill_len)
#' rozdelenie je celkovo symetricke, comu zodpoveda sikmost 0.045

#' merane su roky 2007 az 2009


#'
#'## dlzka zobaka podla podskupin

#'### podla druhu
grafy_podla_skupin(clean_data, stlpec = "bill_len", podla = "species", nazov_hodnoty = "dlzka zobaka (mm)", nazov_skupiny = "druh")
popisne_statistiky(clean_data, stlpec = "bill_len", podla = "species")
#' Adelie maju vyrazne kratsie zobaky, ich priemer je o 10mm kratsi ako Chinstrap
#' najvacsi prekryv maju Chinstrap a Gentoo, Chinstrap ma vacsi priemer o 1.27mm a median o 2.15mm
#' najvacsiu smerodajnu odchylku 3.34mm ma Chinstrap a najmensiu 2.66mm Adelie
#' pri Gentoo boxplot ukazuje vychylny bod 59.6mm

#'
#'### podla ostrovu
grafy_podla_skupin(clean_data, stlpec = "bill_len", podla = "island", nazov_hodnoty = "dlzka zobaka (mm)", nazov_skupiny = "ostrov")
popisne_statistiky(clean_data, stlpec = "bill_len", podla = "island")
#' najdlhsie zobaky podla priemeru maju tucniaky na ostrove Biscoe
#' zlaty stred (median) je v rozmedzi 45.2mm a 45.8mm pre tucniaky z ostrovov Biscoe a Dream
#' smerodajna odchylka je najmensia pri tucniakoch z ostrovu Torgersen 3.02mm, maju taktiez najnizsie maximum 46mm

#'
#'### podla pohlavia
grafy_podla_skupin(clean_data, stlpec = "bill_len", podla = "sex", nazov_hodnoty = "dlzka zobaka (mm)", nazov_skupiny = "pohlavie")
popisne_statistiky(clean_data, stlpec = "bill_len", podla = "sex")
#' samci tucniaky maju vacsi rozptyl rozdelenia dlzok zobaka, var = 28.8mm
#' samci maju maximum dlzky zobaka vacsiu o 1mm
#' najcastejsie vyskytujuca sa hodnota u samiciek je 46.5mm a u samcov 41.1mm (moze to byt aj z dovodu viacej merani u jedneho druhu alebo ostrova)
#' median samcov je 46.8mm a samiciek 42.8mm, kde aj priemer blizko zasahuje: samci 45.9mm a samicky 42.1mm
#' samci maju priemerne dlhsie zobaky, kde maju aj vacsi rozptyl

grafy_podla_skupin(clean_data, stlpec = "bill_len", podla = "sex+island", nazov_hodnoty = "dlzka zobaka (mm)")
grafy_podla_skupin(clean_data, stlpec = "bill_len", podla = "island+species", nazov_hodnoty = "dlzka zobaka (mm)", nazov_skupiny = "pohlavie")
#' tucniaky druhu Adelie maju vzajomnu korelaciu na ostrovoch Biscoe a Dream, avsak tucniaky rovnakeho druhu na ostrove Torgersen nemaju prekryv rocnakych hodnot
adelie <- subset(clean_data, species == "Adelie")
table(
  ostrov = factor(adelie$island, levels = c("Dream", "Biscoe", "Torgersen")),
  pohlavie = adelie$sex
)
#' vzorky su rovnomerne rozlozene medzi pohlaviami


#'
#'# hlbka zobaka
popisne_statistiky(clean_data, stlpec = "bill_dep")
#' priemerna hlbka zobaka je 17.16mm, median 17.3mm a modus 17mm, smerodajna odchylka dat je 1.97mm
grafy_podla_skupin(clean_data, stlpec = "bill_dep")

#'
#'## podla podskupin
#'### podla pohlavia a ostrova
grafy_podla_skupin(clean_data, stlpec = "bill_dep", podla = "sex+island")
popisne_statistiky(clean_data, stlpec = "bill_dep", podla = "sex")
popisne_statistiky(clean_data, stlpec = "bill_dep", podla = "island")
#' najmensi rozptyl maju tucniaky oboch pohlavy na ostrove Dream
#' medzi tucniakov, ktore maju najhlbsie zobaky su samci z ostrovov Dream a Torgersen

#'
#'### podla druhu
grafy_podla_skupin(clean_data, stlpec = "bill_dep", podla = "species")
popisne_statistiky(clean_data, stlpec = "bill_dep", podla = "species")
#' najhlbsie zobaky maju maju druhy Adelie a Chinstrap, Adelie maju avsak vacsi rozptyl 1.49mm, avsak Chinstrap maju najvacsi IQR 1.9mm
#' Adelie a Chinstrap maju takmer zhodny priemer okolo 18.4mm
#' druh Gentoo patri k druhom s mensiou hlbkou, kde priemerna hodnota je 15mm a median 15mm s rovnakym modusom

#'
#'## korelacia hlbky zobaka a dlzky podla pohlavia
podla_pohlavia <- split(clean_data, clean_data$sex)
cor(podla_pohlavia$female$bill_len, podla_pohlavia$female$bill_dep)
cor(podla_pohlavia$male$bill_len, podla_pohlavia$male$bill_dep)
#' zaporne cisla, tendencia dlhsi zobak mensia hlbka

adelie_samice <- podla_pohlavia$female[podla_pohlavia$female$species == "Adelie",]
cor(adelie_samice$bill_len, adelie_samice$bill_dep)
adelie_samce <- podla_pohlavia$male[podla_pohlavia$male$species == "Adelie",]
cor(adelie_samce$bill_len, adelie_samce$bill_dep)
#' u samcov druhu Adelie nie je ziadny vyznamny vztah medzi dlzkou a hlbkou

chinstrap_samice <- podla_pohlavia$female[podla_pohlavia$female$species == "Chinstrap",]
cor(chinstrap_samice$bill_len, chinstrap_samice$bill_dep)
chinstrap_samce <- podla_pohlavia$male[podla_pohlavia$male$species == "Chinstrap",]
cor(chinstrap_samce$bill_len, chinstrap_samce$bill_dep)
#' pri samcoch je silnejsia korelacia 0.45 medzi dlzkou a hlbkou, cim dlhsi zobak tym hlbsi


gentoo_samice <- podla_pohlavia$female[podla_pohlavia$female$species == "Gentoo",]
cor(gentoo_samice$bill_len, gentoo_samice$bill_dep)
gentoo_samce <- podla_pohlavia$male[podla_pohlavia$male$species == "Gentoo",]
cor(gentoo_samce$bill_len, gentoo_samce$bill_dep)
#' u samiciek je silnejsia korelacia 0.43 medzi dlzkou a hlbkou, cim dlhsi zobak tym hlbsi



#'
#'# dlzka plutvy
popisne_statistiky(clean_data, stlpec = "flipper_len")
#' priemerna dlzka plutvy je 200.97mm, median 197mm a modus 190mm, smerodajna odchylka dat je 14.01
#' IQR je 23, kde minimum je 172mm a maximum 231mm
grafy_podla_skupin(clean_data, stlpec = "flipper_len")

#'
#'## podla podskupin
#'### podla pohlavia a ostrova
grafy_podla_skupin(clean_data, stlpec = "flipper_len", podla = "sex+island")
popisne_statistiky(clean_data, stlpec = "flipper_len", podla = "sex")
popisne_statistiky(clean_data, stlpec = "flipper_len", podla = "island")
#' najmensi rozptyl maju tucniaky na ostrove Torgersen, kde su aj 3 vychylky
#' medzi tucniakov, ktore maju najhlbsie plutvy a aj rozptyl su tucniaky z ostrova Biscoe

#'
#'### podla druhu
grafy_podla_skupin(clean_data, stlpec = "flipper_len", podla = "sex+species")
popisne_statistiky(clean_data, stlpec = "flipper_len", podla = "species")
#' najdlhsie plutvy maju tucniaky druhu Gentoo, kde je aj najvacsia priemerna hodnota 217.24mm s medianom 216 (obe pohlavia)
#' smerodajna odchylka je 6.59mm, is IQR 9.5, kde 3ti kvantil ma hodnotu 221 a prvy 212 pri Gentoo druhu



#'
#'# vaha tela
popisne_statistiky(clean_data, stlpec = "body_mass")
#' priemerna hmotnost tela je 4207g, median 4050g a modus 3800g, smerodajna odchylka dat je 805.22
#' IQR je 1225, kde minimum je 2700g a maximum 6300g
grafy_podla_skupin(clean_data, stlpec = "body_mass")


#'
#'## podla podskupin
#'### podla ostrova
grafy_podla_skupin(clean_data, stlpec = "body_mass", podla = "island")
popisne_statistiky(clean_data, stlpec = "body_mass", podla = "island")
#' najtazsie su tucniaky na ostrove Biscoe, kde je najvacsia smerodajna odchylka 790 s IQR 1150
#' na tomto ostrove je aj najvacsie maximum 6300g, kde priemerna hodnota je 4719g

#'
#'### podla druhu a pohlavia
grafy_podla_skupin(clean_data, stlpec = "body_mass", podla = "sex+species")
popisne_statistiky(clean_data, stlpec = "body_mass", podla = "sex+species")
#' v priemere (5484.8g a 4679.7g) su najtazsie tucniaky druhu Gentoo, kde maju najvyssi median pre samca 5500g a pre samicku 4700g
#' najvacsie IQR maju samci Adelie 500, samicky Gentoo 412.5

#'
#'## korelacia vaha tela a dlzka plutvy
cor(podla_pohlavia$female$body_mass, podla_pohlavia$female$flipper_len)
cor(podla_pohlavia$male$body_mass, podla_pohlavia$male$flipper_len)
#' corelacia je velmi silna medzi dlzkou plutvy a vahou (0.88 samice a 0.87 samci)


cor(adelie_samice$body_mass, adelie_samice$flipper_len)
cor(adelie_samce$body_mass, adelie_samce$flipper_len)
#' u drhuhu Adelie je korelacia u samcov silnejsia 0.36 ako u samic 0.27

cor(chinstrap_samice$body_mass, chinstrap_samice$flipper_len)
cor(chinstrap_samce$body_mass, chinstrap_samce$flipper_len)
#' najsilnejsia korelacia je u samcov druhu Chinstrap kde je 0.66


cor(gentoo_samice$body_mass, gentoo_samice$flipper_len)
cor(gentoo_samce$body_mass, gentoo_samce$flipper_len)
#' u samiciek je silnejsia korelacia 0.49 medzi vahou a dlzkou plutvy
