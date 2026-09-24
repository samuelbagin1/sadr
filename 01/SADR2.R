# Uzitocne prikazy
diabetes <- read.csv("data/diabetes.csv")
str(diabetes)
names(diabetes)
head(diabetes)


library(readxl)
data <- readxl::read_xlsx("data/data_vyuka.xlsx")
str(data)
head(data)
View(data)

# chybajuce data
# kniznice: mice, Amelia
is.na(data)
# kolko ich napr v stlpci vzdelanie
sum(is.na(data$vzdelanie))
library(mice)
md.pattern(data)
library(Amelia)
missmap(data)

# kedze chybajuce data nedoplname, prislusne riadky vynechame
# a pracujeme s uplnym datasetom
new_data <- na.omit(data)
str(new_data)


# vhodne knzinice pre EDA
install.packages(psych)
install.packages(Hmisc)
install.packages(FSA)
install.packages(pastecs)
install.packages(moments)
install.packages(mosaic)
install.packages(ie2misc) # MAD
install.packages(modest) # modus

library(psych)
library(Hmisc)
library(FSA)
library(pastecs)
library(moments)
library(mosaic)
library(ie2misc) # MAD
library(modest) # modus

# charakteristiky polohy
# urcime charakteristiky polohy pre stlpec mprij, novy nazov plat
plat <- new_data$mprij
table(plat) # tabulka pocetnosti
prop.table(table(plat)) # relativne pocetnosti
cumsum(table(plat))

# tabulka tridnych pocetnosti, viacerymi prikazmi
# urcime hranice a pocetnosti pomocou prikazu hist
hist(plat, breaks = 3, plot = F)
tp <- hist(plat, breaks = 3, plot = F)
tp$breaks
tp$counts

# po jednom prikaze
min(plat)
max(plat)
mean(plat) # aritmeticky priemer ale nemam chybajuce hodnoty
mean(data$mprij, na.rm = T) # chybajuce sa vynechaju a zrata sa statistika
median(plat)
mfv(plat) # modus
quantile(plat)
quantile(plat, 0.1)

# prikazy pre harmonicky a geometricky priemer
harmonic.mean(plat)
geometric.mean(plat)

sort(plat)
sort(plat)[15]
sum(plat==1050) # pocet respondentov s platom 1050
sum(new_data$vek<40)

# charakteristiky rozptylu
# variacne rozpatie, odhad disperzie, snerodajna odchylka, kvartilove rozpatie IQR
max(plat)-min(plat)
range(plat)
var(plat) # variance - disperzia, rozptyl
sd(plat) # standard deviation - smerodajna odchylka
mad(plat) # medianova absolutna odchylka
madstat(plat) # priemerna absolutna
IQR(plat)

library(DescTools)
CoefVar(plat) # variacny koeficient

# preferovana kniznica moments
skew(plat) # sikmost, nie tato kniznica
moments::skewness(plat)
skewness(plat)
kurtosi(plat) # neopouzivat
kurtosis(plat)

# simulacie symetrickych a nesymetrickych rozdeleni a ich sikmosti
# normalne rozdelene data
s1 <- rnorm(1000, mean=0, sd=1)
skewness(s1)
hist(s1)
kurtosis(s1)

# chi kvadrat rozdelene data
s2 <- rchisq(1000, 5)
skewness(s2)
hist(s2)
kurtosis(s2)


# sumarne statistiky
describe(plat)
round(stat.desc(plat), 2)
summary(plat)


# charakteristiky pre kazdy stplec tabulky
inspect(new_data)
library(skimr)
skim(new_data)


# charakteristiky na vybranych podmnozinach
# muzi a zeny
tapply(new_data$mprij, new_data$pohlavie, mean)
tapply(new_data$mprij, new_data$pohlavie, summary)


# grafy EDA
# vhodne kniznice
library(ggplot2)
library(car)
library(carData)
library(vioplot)

# krabicove grafy
boxplot(plat, horizontal = T) # graficky
boxplot(plat, horizontal = T, outline = F)
boxplot.stats(plat)

# pre podmnoziny
boxplot(new_data$mprij~new_data$pohlavie)
boxplot(new_data$mprij~new_data$pohlavie+new_data$vzdelanie)

# huslovy graf
vioplot(plat, col = 'cyan')
vioplot(new_data$mprij~new_data$pohlavie)
par(mfrow=c(1,2))
boxplot(plat, col='darkolivegreen1')
vioplot(plat, col='#C0FF3E')
