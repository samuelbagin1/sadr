cas <- c(48, 55, 51, 62, 53, 58, 60, 50, 49, 57, 52, 61, 54, 56, 59,53,
         50, 58, 55, 53)
jablko <- c(499.2,496.8,502.1,498.5,501,503,500.7,
            501.5,501.8,499.1,500.9,502.2,501.7, 500.4,
            500.2,501.1,499.9,500.2,501.1,500.8,499.3)
baterie <- c(12,19,16,13,15,12,14,20,15,19,17,20,
             13,9,11,20,12,19,8,13)
baterie1<- c(18.2,19.6,18.6,19.4,17,18.5,18,18.4,19,
             18,17.9,18.1)
pizza <- c(27,25,30,28,29,24,30,26,28,32,
           24,32,31,29,28,29,35,34,30,31,18,22)
pred <- c(87,61,98,90,93,74,83,72,81,75,83)
po <- c(50,45,79,90,88,65,52,79,84,61,52)
spotreba_A <-c(531.58, 541.89, 606.78, 570.68, 560.15, 598.93,
               575.45, 494.66, 511.84, 529.99, 588.70, 557.10)
spotreba_B <- c(491.33, 493.92, 590.72, 524.35, 513.79, 601.14,
                542.70,466.44, 501.47, 510.95, 577.17, 541.27)

odozva<-c(158.5,140.3,163.7,149.9,129.5,155.1,139.0,126.3,
          145.7,152.0,133.1,148.3,144.0,156.9,152.8,138.8,
          147.8,160)

library(latex2exp)
library(latexpdf)

#' # testy hypotez pre parametre normalneho rozdelenia
#' 
#' ## test pre strednu hodnotu $\mu$ a $\sigma$ pozname
#' priklad: udaje o dlzke casu v sekundach
#' ktory stravia pouzivatelia na www stranke, disperzia je znama
#' $\sigma=3.8$
#' 1. testujte hypotezu, ze klient stravi na stranke v priemere 55s,
#' hladina vyznamnosti $\alpha=0.5$.
#' tvar hypotez, overenie normality
#' $$H_0 \quad \mu=55 \qquad H_1 \quad \mu \neq 55$$
#' grafy na overenie zhody rozdelenia, default normalne
qqnorm(cas) # kvantil kvantil graf
qqline(cas) # prida sa ciara

#' shapiro wilk test
shapiro.test(cas)
#' p hodnota=0.74>0.05, nezamietame hypotezu o normalite dat
#' pozname disperziu, teda Z test kniznica DescTools
library(DescTools)
ZTest(cas, mu=55, sd_pop = 3.8)
#' rozdelenie podla Pvalue=0.72>0.05, nezamietam $H_0$
#' ano klient stravi na stranke v priemere 55s

#' kniznica broom, ktora umozni dat prehladnejsi vystup
library(broom)
broom::tidy(ZTest(cas, mu = 55, sd_pop = 3.8))
#' nova hypoteza: otazka v skutocnosti znela, ci zotrvaju na stranke aspon 58s
#' $$H_0 \quad \mu=58 \qquad \mu>58$$
ZTest(cas, mu = 58, alternative = 'g', sd_pop = 3.8)
#' p-hodnota=0.99 > 0.05, nezamietame $H_0$, nie je pravda ze zotrvaju viac ako 58s
#' ak by sme testovali napriklad na hladine vyznamnosti
#' $\alpha=0.1$, aj tak rozhodujeme: ak p-hodnota > 0.1, tak nezamietame nulovu hypotezu
#' test graficky
plot(function(x)dnorm(x,0.1), from = -3, to =3,
     main = TeX("test pre $\\mu$"),
     ylab = 'hustota'
     )
q <- qnorm(0.975, 0.1) # kvantil normalneho rozdelenia, hranica
z <- -0.35 # statistika vystupu
abline(v = z, col = 'blue')
abline(v = q, col = 'red')
abline(v = -q, col = 'red')


#' # test pre $\mu$ ak $\sigma$ nepozname
#' tento ze treba najviac pouzivat
#' testujeme testy z predosleho prikladu za predpokladu
#' ze $\sigma$ nepozname
t.test(cas, mu=55)
t.test(cas, mu=55)$p.value
#' p-hodnota > 0.05, nezamietame $H_0$, tvrdenie plati
#' 
#' ## druha hypoteza
t.test(cas, mu=58, alternative = 'g')
#' p-hodnota > 0.05, nezamietame $H_0$, teda nie je pravda ze vydrzia viac ako 58s

#'
#' # plnicka jablkovych stiav
#' firma predava jablkovu stavu v 0.5l baleniach.
#' plniaca linka presla servisom, potom sme namerali tieto hodnoty
#' plneneho objemu v ml. na hladine vyznamnosti $\alpha=0.1$ testujte
#' hypotezu, ze linka je dobre nastavena
#' $$H_0 \quad \mu=500 \qquad H_1 \quad \mu \neq 500$$
shapiro.test(jablko) # normalne rozdelenie, ok
t.test(jablko, mu = 500) # nemusim dat hladinu vyznamnosti
#' kedze hladina vyznamnosti $\alpha = 0.1$ a p-hodnota = 0.09 < 0.1, zamietame $H_0$
#' ak by bola 0.05, 0.09 > 0.05, tak by sme nezamietali



#' 
#' # zlozene alternativy
#' firma, ktora vyraba baterie do notebookov tvrdi, ze jednu vyrobi do 13 minut
#' overte toto tvrdenie, ak mate k dispozicii 20 merani, $\alpha = 0.05$.
#' spravte nulovu a alternativnu hypotezu
shapiro.test(baterie) # normalne rozdelenie
#' $$H_0 \quad \mu = 13 \qquad H_1 \quad \mu<13$$
t.test(baterie, mu = 13, alternative = 'l')
#' p-hodnota - 0.97 > 0.05, nezamietame nulovu hypotezu
#' neprijmame alternativy, trva mu to viac, odhad strednej hodnoty je 14.85
#' 
#' vyrobca tvrdi, ze baterky do elektronickych pristrojov
#' vydrzia aspon 19 hodin nepretrzitej prevadzky.
#' testujte, ak mame k dispozicii datovy subor baterie1
#' ak $\alpha$ dalej neuvedieme, bude 0.05

shapiro.test(baterie1) # normalne rozdelenie
#' $$H_0 \quad \mu = 19 \qquad H_1 \quad \mu>19$$
t.test(baterie1, mu = 19, alternative = 'g')
#' p-hodnota > 0.05, nezamietame nulovu hypotezu
#' nevydrzia viac ako 19 hodin
t.test(baterie1, mu = 19, alternative = 'l') # len ci dojde k sporu
#' zamietame $H_0$, prijmame $H_1$, co nie je spor
#' vydrzia menej ako 19



#'
#' ### priklad 
#' pizzeria ABC ma na letaku uvedene, ze pizzu dovezu do 30 min
#' casy dodavok su v datovom subore pizza
#' testujte na hladine vyznamnosti $\alpha = 0.05$. vyslovte zaver
shapiro.test(pizza) # normalne rozdelenie
#' $$H_0 \quad \mu = 30 \qquad H_1 \quad \mu<30$$
t.test(pizza, mu = 30, alternative = 'l')

#' 
#' # testy pre disperziu normalneho rozdelenia
#' v prvom priklade sme tvrdili, ze $\sigma=3.8$, datovy subor cas
#' na hladine vyznamnosti $\alpha=0.05$, overte toto tvrdenie
#' 
#' $$H_0 \quad \sigma^2 - 3.8^2 \qquad H_1 \sigma^2 \neq 3.8^2$$
#' kniznica DescTools, EnvStats
library(EnvStats)
EnvStats::varTest(cas, sigma.squared = 3.8^2)
EnvStats::varTest(cas, sigma.squared = 3.8^2)$p.value
#' nezamietame $H_0$, je pravdive
#' 
#' # dvojvyberove testy
#' merania idu v pare, vytvorime diferencie a tie zmysluplne testujeme.
#' su dane casy v sekundach, pred a po, pocas ktorych riesili ziaci kontrolne ulohy
#' pred a po cviceniach z pamatoveho pocitania. zlepsili cvicenia schopnost ziakov rychlejsie riesit ulohy?
#' $$H_0 \quad \mu_{pred}-\mu_{po}=0 \qquad H_1 \mu_{pred}-\mu_{po}>0$$
d <- pred - po
shapiro.test(d)
t.test(d, alternative = 'g')
#' p-hodnota = 0.005 < 0.05 zamietame $H_0$ teda prijimame $H_1$, zlepsili sa
t.test(pred, po, alternative = 'g', paired = T)
