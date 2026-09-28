library(tibble)
library(readxl)

diabetes <- read.csv("data/diabetes.csv")
str(diabetes)
View(diabetes)
data <- read_xlsx("data/data_vyuka.xlsx")
View(data)
hod <- sample(1:6, size=10, replace=TRUE)

table(hod)
prop.table(table(hod))
hist(hod)

for (n in c(10,100, 1000, 10000, 100000)) {
  print(prop.table(table(sample(1:6, size = n, replace = TRUE))))
}

plot(sin, from = -2*pi, to = 2*pi, xlab='os x', ylab='sinx')
hist(data$mprij)
boxplot(data$mprij)
boxplot(data$mprij, horizontal = T)
boxplot(data$mprij~data$pohlavie, horizontal = T)
