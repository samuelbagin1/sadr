# spustenie z korena repozitara: Rscript cvicenia/obrazky/generovat_grafy.R
# obrazky pouzivaju rovnake data a postupy ako priklady v readme
library(ggplot2)
library(viridisLite)

farby <- viridis(6, begin = 0.12, end = 0.82)
theme_set(theme_minimal(base_size = 13))
data <- as.data.frame(readxl::read_xlsx("cvicenia/01/data/data_vyuka.xlsx"))
prijmy <- na.omit(data[c("mprij", "pohlavie", "vzdelanie")])
plat <- prijmy$mprij
cas <- c(48,55,51,62,53,58,60,50,49,57,52,61,54,56,59,53,50,58,55,53)

set.seed(2026)
hod <- sample(1:6, size = 10000, replace = TRUE)
png("cvicenia/obrazky/01_simulacia.png", width = 1600, height = 700, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
barplot(prop.table(table(factor(hod, levels = 1:6))), col = farby,
        ylim = c(0,0.21), xlab = "hodnota na kocke", ylab = "relativna pocetnost",
        main = "10 000 hodov kockou")
abline(h = 1/6, lty = 2, lwd = 2)
plot(cumsum(hod == 6)/seq_along(hod), type = "l", log = "x",
     col = farby[3], xlab = "pocet hodov (logaritmicka os)",
     ylab = "podiel sestiek", main = "stabilizacia relativnej pocetnosti")
abline(h = 1/6, lty = 2)
dev.off()

png("cvicenia/obrazky/02_eda.png", width = 1800, height = 1300, res = 150)
par(mfrow = c(2,2), mar = c(4,4,3,1))
hist(plat, breaks = "Sturges", col = farby[3], border = "white",
     main = "histogram prijmov", xlab = "mesacny prijem (eur)", ylab = "pocet osob")
abline(v = mean(plat), col = farby[1], lwd = 2)
abline(v = median(plat), col = farby[6], lwd = 2, lty = 2)
legend("topright", c("priemer", "median"), col = farby[c(1,6)],
       lty = c(1,2), lwd = 2, bty = "n")
boxplot(mprij ~ pohlavie, data = prijmy, col = farby[c(2,5)],
        main = "boxplot podla pohlavia", xlab = "pohlavie", ylab = "mesacny prijem (eur)")
vioplot::vioplot(mprij ~ pohlavie, data = prijmy, col = farby[c(2,5)],
                main = "huslovy graf", xlab = "pohlavie", ylab = "mesacny prijem (eur)")
plot(ecdf(plat), col = farby[2], lwd = 2, main = "empiricka distribucna funkcia",
     xlab = "mesacny prijem (eur)", ylab = "podiel prijmov <= x", verticals = TRUE)
dev.off()

ggsave("cvicenia/obrazky/02_jitter.png",
       ggplot(prijmy, aes(factor(vzdelanie), mprij, color = factor(vzdelanie))) +
         geom_boxplot(outlier.shape = NA, width = 0.45, color = "grey45") +
         geom_jitter(size = 2.3,
                     position = position_jitter(width = 0.12, height = 0, seed = 2026)) +
         scale_color_viridis_d(begin = 0.1, end = 0.75, guide = "none") +
         labs(title = "jednotlive prijmy aj suhrn skupiny", x = "kod vzdelania",
              y = "mesacny prijem (eur)"), width = 9, height = 5, dpi = 160)

set.seed(2026)
intervaly <- matrix(NA_real_, nrow = 60, ncol = 2)
for (i in 1:60) intervaly[i,] <- stats::t.test(rnorm(30, mean = 3, sd = 1))$conf.int
pokryva <- intervaly[,1] <= 3 & intervaly[,2] >= 3
png("cvicenia/obrazky/03_intervaly.png", width = 1700, height = 1000, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
is_z <- mean(cas) + c(-1,1)*qnorm(0.975)*3.8/sqrt(length(cas))
is_t <- stats::t.test(cas)$conf.int
plot(mean(cas), 1, xlim = range(c(is_z,is_t)), ylim = c(0.5,2.5), yaxt = "n",
     xlab = "priemerny cas na webe (s)", ylab = "", pch = 19,
     main = "95 % intervaly pre ten isty priemer")
points(mean(cas), 2, pch = 19)
segments(c(is_z[1],is_t[1]), 1:2, c(is_z[2],is_t[2]), 1:2, col = farby[c(2,4)], lwd = 3)
axis(2, at = 1:2, labels = c("z", "t"), las = 1)
legend("topleft", c("z: sigma znama", "t: sigma neznama"),
       col = farby[c(2,4)], lty = 1, lwd = 3, bty = "n", cex = 0.85)
plot(rowMeans(intervaly), 1:60, xlim = range(intervaly), pch = 19, cex = 0.5,
     col = ifelse(pokryva, farby[3], "#B23A48"),
     xlab = "interval pre priemer", ylab = "opakovany vyber",
     main = "60 vyberov z populacie s priemerom 3")
segments(intervaly[,1], 1:60, intervaly[,2], 1:60,
         col = ifelse(pokryva, farby[3], "#B23A48"), lwd = 1.5)
abline(v = 3, lty = 2)
dev.off()

set.seed(2026)
x <- c(2,2,3,4,5,11,3,12,15,21)
boot_priemery <- numeric(10000)
for (i in seq_along(boot_priemery)) boot_priemery[i] <- mean(sample(x, length(x), replace = TRUE))
is_boot <- quantile(boot_priemery, c(0.025,0.975))
png("cvicenia/obrazky/03_bootstrap.png", width = 1600, height = 700, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
hist(x, col = farby[3], border = "white", main = "povodne merania (n = 10)",
     xlab = "hodnota merania", ylab = "pocet")
hist(boot_priemery, breaks = 40, col = farby[4], border = "white",
     main = "10 000 bootstrapovych priemerov", xlab = "priemer prevzorkovaneho vyberu", ylab = "pocet")
abline(v = is_boot, col = farby[1], lwd = 2, lty = 2)
abline(v = mean(x), col = farby[6], lwd = 2)
dev.off()

png("cvicenia/obrazky/04_testy.png", width = 1700, height = 750, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
qqnorm(cas, col = farby[2], pch = 19, main = "Q-Q graf casu na webe",
       xlab = "teoreticke normalne kvantily", ylab = "pozorovane casy (s)")
qqline(cas, col = farby[5], lwd = 2)
z <- (mean(cas)-55)/(3.8/sqrt(length(cas)))
grid <- seq(-3.5,3.5,length.out = 1000)
plot(grid, dnorm(grid), type = "l", lwd = 2, xlab = "z statistika", ylab = "hustota",
     main = "obojstranny z-test: H0 priemer = 55")
polygon(c(grid[grid <= -abs(z)], -abs(z)), c(dnorm(grid[grid <= -abs(z)]),0),
        col = adjustcolor(farby[3], alpha.f = 0.5), border = NA)
polygon(c(abs(z),grid[grid >= abs(z)]), c(0,dnorm(grid[grid >= abs(z)])),
        col = adjustcolor(farby[3], alpha.f = 0.5), border = NA)
abline(v = c(-1,1)*qnorm(0.975), col = "#B23A48", lty = 2, lwd = 2)
abline(v = z, col = farby[1], lwd = 2)
legend("topright", c("kriticke hranice", "pozorovane z", "plochy = p-hodnota"),
       lty = c(2,1,1), col = c("#B23A48",farby[1],farby[3]), bty = "n", cex = 0.7)
dev.off()

pred <- c(87,61,98,90,93,74,83,72,81,75,83)
po <- c(50,45,79,90,88,65,52,79,84,61,52)
png("cvicenia/obrazky/04_pary.png", width = 1500, height = 700, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
matplot(rbind(pred,po), type = "b", col = farby[3], lty = 1, pch = 19, xaxt = "n",
        xlab = "stav", ylab = "cas riesenia (s)", main = "rovnaki ziaci pred a po")
axis(1, at = 1:2, labels = c("pred", "po"))
boxplot(pred-po, col = farby[3], ylab = "pred - po (s)", main = "testujeme rozdiely v paroch")
stripchart(pred-po, method = "jitter", vertical = TRUE, add = TRUE, pch = 19, col = farby[1])
abline(h = 0, lty = 2)
dev.off()

prijmy$vzdelanie <- factor(prijmy$vzdelanie)
model <- aov(mprij ~ vzdelanie, data = prijmy)
png("cvicenia/obrazky/05_anova.png", width = 1800, height = 800, res = 150)
par(mfrow = c(1,2), mar = c(5,5,3,1))
boxplot(mprij ~ vzdelanie, data = prijmy, col = farby[c(2,3,5)],
        xlab = "kod vzdelania", ylab = "mesacny prijem (eur)", main = "tri skupiny prijmov")
plot(TukeyHSD(model), las = 1, col = farby[2])
dev.off()

png("cvicenia/obrazky/05_diagnostika.png", width = 1600, height = 750, res = 150)
par(mfrow = c(1,2), mar = c(4,4,3,1))
plot(fitted(model), residuals(model), pch = 19, col = farby[3],
     xlab = "predikovany prijem (eur)", ylab = "reziduum (eur)", main = "rezidua proti predikcii")
abline(h = 0, lty = 2)
qqnorm(residuals(model), pch = 19, col = farby[3], main = "Q-Q graf rezidui")
qqline(residuals(model), col = farby[1], lwd = 2)
dev.off()

cholesterol <- as.data.frame(readxl::read_xlsx("cvicenia/05/cholesterol.xlsx"))
png("cvicenia/obrazky/05_welch.png", width = 1300, height = 800, res = 150)
boxplot(Cholesterol ~ Dieta, data = cholesterol, col = farby[c(2,3,5)],
        xlab = "typ diety", ylab = "cholesterol (jednotka v subore neuvedena)",
        main = "porovnanie skupin s roznou variabilitou")
dev.off()

interakcie <- as.data.frame(readxl::read_xlsx("cvicenia/05/anova_interakcie.xlsx"))
interakcie$latencia <- factor(interakcie$latencia, levels = c("Nízka", "Vysoká"),
                             labels = c("nizka", "vysoka"))
interakcie$ui <- factor(interakcie$ui, levels = c("Jednoduché", "Zložité"),
                       labels = c("jednoduche", "zlozite"))
png("cvicenia/obrazky/05_interakcie.png", width = 1400, height = 850, res = 150)
interaction.plot(interakcie$latencia, interakcie$ui, interakcie$cas, fun = mean,
                 type = "b", col = farby[c(2,5)], pch = c(19,17), lwd = 3,
                 trace.label = "typ ui", xlab = "latencia siete",
                 ylab = "priemerny cas dokoncenia (s)",
                 main = "zavisi dopad latencie od rozhrania?")
dev.off()
