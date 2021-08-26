

library(Grym)
library(ggplot2)
library(dplyr)
library(tidyr)
library(furrr)
library(readxl)
set.seed(31)

Scenarios<-read_xlsx("../Grym_parameter_combinations.xlsx")
names(Scenarios)


for(i in 1:length(Scenarios$Scenarios)){
Pars_list<-list() #Create an empty parameters list. 

Pars_list$Iterations <- 10000
Pars_list$Scenario   <- Scenarios$Scenarios[i]
Pars_list$Area       <- "48.1"
Pars_list$Date       <- Sys.time()

filename<-paste("../2_Parameters/Setup_files/","Setup_pars_",Pars_list$Area,"_",Pars_list$Scenario,".rds", sep="")

file.exists(filename)

Pars_list$nsteps <- 365 #time steps
Pars_list$Ages <- 1:7 #Age classes

#reference date
Pars_list$Reference<-"2021/10/01"

#Interval sequences
Pars_list$spawnI	 <- 76:138
Pars_list$monitorI <- 93:107
Pars_list$fishingI <- 1:365

#Recruitment Variables
Pars_list$R.mean     <- Scenarios$`Mean proportional recruitment`[i]
Pars_list$R.sd       <- Scenarios$`SD of proportional recruitment`[i]
Pars_list$R.var      <- Pars_list$R.sd^2
Pars_list$R.class    <- 2
Pars_list$R.nsurveys <- Scenarios$`N. surveys`[i]

#Growth details 
Pars_list$t0   <- 0
Pars_list$K    <- 0.48
Pars_list$Linf <- 60

#Growth Period

Pars_list$f0 <- 21/365
Pars_list$f1 <- 135/365

Pars_list$a <- Scenarios$`Weight-length parameter - A (g)`[i]
Pars_list$b <- Scenarios$`Weight-length parameter - B`[i]

Pars_list$B0logsd <- 0.361

#Selectivity curve
Pars_list$sel50Min <- 30
Pars_list$sel50Max <- 35
Pars_list$selrange <- 11

#Maturity Curve
Pars_list$mat50Min <- Scenarios$`Min length, 50% mature (mm)`[i]
Pars_list$mat50Max <- Scenarios$`Max length, 50% mature (mm)`[i]
Pars_list$matrange <- Scenarios$`Range over which maturity occurs (mm)`[i]

Pars_list$rec_file <- paste0("Rec_pars_", Pars_list$Area,"_",
                             Pars_list$R.mean,"_",Pars_list$R.sd,".rds")

Pars_list$proj_file <- paste0("Proj_output_",
                              Pars_list$Area,"_",
                              Pars_list$Scenario,".rds")

saveRDS(Pars_list, 
        file = filename)
}
