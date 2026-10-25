library (latexpdf)
#' # Dva nezavisle vybery
#' Najry test o rovnosti, nerovosti disperzli
#' Priklad Dva druhy plastickej hmoty (vyroba plastovych okien)
#' sme vystavili svetlu po dobu 6 mesiacoy. Odolnost voci svetlu v dnoch sme zaznamenali, Vyroba prveho plastu je lacnejsia,
#' Zistite, ci su rozdiely v odolnosti voci svetlu pre dva druhy plastov $\alpha=0.05$
prvy <- c(85,87,92,80,84,86) druhy <- c(89,89,90,84,92)
#; Krabicove grafy
boxplot(prvy,druhy,col=c('red', 'blue'), horizontal = T)
boxplot(prvy, druhy, col=c('red', 'blue'), horizontal = T, range=0)
shapiro.test(prvy) # su normalne rozdelene 
shapiro.test(druhy) # su normalne rozdelene var. test (pry, druny)
#' Phodnota > 0.05, nezamietam $H_O$ rovnost disperzil
#' Test strednych hodnot
t.test(prvy, druhy, paired = F, var.equal = T)
#' p-hodnota > 0.05, nezamietam hypotezu o rovnosti strednych hodnot
#' default pre t.test var.equal = F
#' 
#' # Dvojvyberovy, nerovnake disperzie
#' 
#' Priklad firma odobera ochranne pracovne pomocky od dvoch
#' dodavatelov AA, BB. zaznamenali sme tieto dlzky dodavok od objednavky 
#' na hladine vyznamnosti $\alpha = 0.05$ testujte hypotezu ze dlzky dodavok su rovnake

aa <- c(10, 12, 15, 25, 18 ,20, 15, 25, 30)
bb <- c(15, 15, 18, 10, 16, 12, 15)
boxplot(aa, bb, col = c('red', 'blue'), horizontal = T, range = 0)
shapiro.test(aa)
shapiro.test(bb)
var.test(aa, bb) # test pre rovnosti disperzii
#' zamietame hypotezu o rovnosti disperzii
t.test(aa, bb, paired = F, var.equal = F)
#' p-hodnota > 0.05, nezamietame hypotezu o rovnosti strednych hodnot
#' 
#' # Anova
#' test rovnosti strednych hodnot pre viac ako dve skupiny
#' je nutne aby, boli splenene dve podmienky
#' normalita dat v triedach a rovnosti disperzii v triedach
#' 
#' Priklad: nase vyukove data, k dispozicii mame dat o priemernom prijme 
#' pre tri podmnoziny (faktor vzdelanie -zs, ss, vs)
#' testujeme hypotezu o rovnosti strednych hodnot, ze faktor druh vzdelania 
#' je statisticky nevyznamny


data <- read_xlsx('data_vyuka.xlsx')
new_data <- na.omit(data)

boxplot(new_data$mprij~new_data$vzdelanie, col = brewer.pal(3, 'Pastel2'), xlab = 'vzdelanie', ylab = 'prijem')
ggline(new_data, x = 'vzdelanie', y = 'mprij', add = c('mean_ci', 'violin', 'jitter'))

#' overenie podmienok pre ANOVA
#' normalita dat
tapply(new_data$mprij, new_data$vzdelanie, shapiro.test)
#' data v triedach su normalne rozdelene
#' rovnost disperzii
bartlett.test(new_data$mprij, new_data$vzdelanie)
#' p-hodnota > 0.05, disperzie v triedach sa rovnaju, ANOVA
#' 
#' faktorizujeme
vzdelanie <- factor(new_data$vzdelanie)
vzdelanie

View(new_data)
anova <- aov(new_data$mprij~vzdelanie)
anova
summary.aov(anova)

