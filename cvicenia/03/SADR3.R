library(latexpdf)
library(latex2exp)
X <- c(48,55,51,62,53,58,60,50,49,57,52,61,54,56,59,53,50,58,55,53)
length(X)
mean(X)       
boxplot(X)
shapiro.test(X)

#' kedzee P hodnota >0.05, nezamietame hypotezu o normalite
#' IS pre $\mu$ ak $\sigma=3.8$, obojstranny aj jednostranny
#' podla vzorca

alfa <- 0.05
n <- length(X)
sigma <- 3.8
qnorm(1-alfa/2)
is <- mean(X)+c(-1,1)*qnorm(1-alfa/2)*sigma/sqrt(n)
isj <- c(mean(X) - qnorm(1-alfa/2)*sigma/sqrt(n), Inf)
isj
isj <- c(-Inf, mean(X) - qnorm(1-alfa/2)*sigma/sqrt(n))
isj

#' prikazmi R, IS su prepojene s testami, takze
#' zvycajne ma prikaz tvar ...test a vo vystupe najdeme IS
library(DescTools)
ZTest(X, sd_pop = 3.8)
ZTest(X, sd_pop = 3.8)$conf.int

#' jednostranne
ZTest(X, sd = 3.8, alternative = "less")$conf.int
ZTest(X, sd = 3.8, alternative = "greater")$conf.int

#' zmena alfy
ZTest(X, sd = 3.8, conf.level = 0.9)$conf.int


#'# IS pre $\mu$ ak $\sigma$ nepozname
#'najcastejsie pouzivany interval, t test v standartnej kniznici
t.test(X)

#' jednostranne a 90% IS
t.test(X, alternative = "l")$conf.int
t.test(X, alternative = "g")$conf.int
t.test(X, conf.level = 0.9)

#' nakreslime si pomocou pltrix, nie celkom nazorne lavy a pravy bod IS vlozime do premennych

dd <- t.test(X)$conf.int[1]
dd
hh <- t.test(X)$conf.int[2]
library(plotrix)
plotCI(1, mean(X), li=dd, ui=hh, main = "IS pre strednu hodnotu")

data <- readxl::read_xlsx('data_vyuka.xlsx')
new_data <- na.omit(data)

library(Rmisc)
CI(X)
CI(X, ci = 0.9)
CI_pohlavie <- group.CI(mprij~pohlavie, data = new_data)
CI_pohlavie
group.CI(mprij~vzdelanie, data = new_data)
tapply(new_data$mprij, new_data$vzdelanie, t.test)

library(ggplot2)
data <- data.frame(skupina = c("muzi", "zeny"), priemer = c(1067.045, 1157.609),
                   dolna = c(933.66, 1008.71), horna = c(1200.4, 1306.49))
data
ggplot(data, aes(x=skupina, y=priemer, ymin=dolna, ymax=horna)) +
  geom_pointrange(color = "blue", size = 0.8, fatten = 3) +
  theme_minimal(base_size = 14)

library(DescTools)
VarTest(X)
VarTest(X, conf.level = 0.9)
VarTest(X, alternative = "l")
VarTest(X, alternative = "l")


k <- 0
for( i in 1:100) {
  a <- rnorm(30, mean = 3, sd = 1)
  is <- t.test(a)$conf.int
  if (3 < is[[1]] || 3 > is[[2]]) {
    k <- k+1
  }
}
k
