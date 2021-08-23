library(Grym)
library(furrr)
library(dplyr)
library(ggplot2)
source('./Source/check_params.R')
source('./Source/Projection_function.R')

scens <- list.files("../2_Parameters/Setup_files/")
init<-c(seq(0,0.08, by=0.02), seq(0.085, 0.135, by=0.002))
rec1<-c(seq(0,0.014, by=0.002),0.02,0.03, seq(0.04, 0.056, by=0.002))
rec2<-c(seq(0,0.026, by=0.002),0.02,0.03, seq(0.04, 0.056, by=0.002))
rec3<-c(seq(0,0.02, by=0.001))
rec4<-c(seq(0,0.02, by=0.001))
rec5<-c(0,seq(0.06,0.095, by=0.001))

testvals<-list(init, init, init, init, init, init, 
     rec1,rec1,rec1,rec1,rec1, rec1,
     rec2,rec2,rec2,rec2,rec2,rec2,
     rec3,rec3,rec3,rec3,rec3,rec3,
     rec4,rec4,rec4,rec4,rec4,rec4,
     rec5,rec5,rec5,rec5,rec5,rec5)

tictoc::tic()

for(i in 1:length(scens)){
  print(paste("starting ", scens[i]))
pars<-readRDS(paste0("../2_Parameters/Setup_files/", scens[i]))

recs<-readRDS(paste0("../2_Parameters/Recruitment_vectors/Rec_pars_",pars$Area,"_",pars$R.mean,"_",pars$R.sd,".rds"))

check_params(pars, recs)



Project<-KrillProjection(pars$nsteps, pars$Ages,					 #time step numbers and age classes
								 pars$spawnI,pars$monitorI,pars$fishingI,			 #Interval sequences
								 pars$R.mean,pars$R.var,pars$R.class,pars$R.nsurveys,#Recruitment Variables
								 pars$t0,pars$K,pars$Linf,pars$f0,pars$f1,								 #Growth details 
								 pars$a, pars$b, 								 					 #Length/Weight Details
								 pars$sel50Min,	pars$sel50Max,	pars$selrange,	 #Selectivity Parameters
								 pars$mat50Min,	pars$mat50Max,	pars$matrange,  #Maturity parameters
								 pars$B0logsd,
								 prRecruitPars=recs$pars, prRecruit=recs$recdist,
								 gamma=testvals[[i]],#gammas to test
								 n.years=20                      #Number of years
								 )

Runs <- pars$Iterations
Runs

plan(multiprocess, workers= availableCores()-1)
df_48_1 <- future_map_dfr(1:Runs,Project,.options = furrr_options(seed = TRUE),.progress=T)
plan(sequential)

df_48_1$Scenario <- pars$Scenario

saveRDS(df_48_1, 
        file= paste0("../4_Output/Projections/",pars$proj_file))

results <- list()
results$Scenario <-  pars$Scenario
results$Gamma1 <- df_48_1 %>% group_by(Gamma,Run) %>% 
	summarize(Dep=min(SSB/SSB0)) %>% 
	summarize(Pr=mean(Dep < 0.2))
results$Gamma1
#Given the gamma values tested, gamma 1 is:
results$Gamma_1 <- max(results$Gamma1$Gamma[results$Gamma1$Pr<=0.1])
results$Gamma_1

#What is the approximate Gamma that meets 10% depletion to test.
results$test_gamma_1 <-approx(results$Gamma1$Pr,results$Gamma1$Gamma,0.1)$y
results$test_gamma_1


#Gamma 2:
results$Gamma2 <- df_48_1 %>%  group_by(Gamma) %>% 
	filter(Year %in% max(Year)) %>% 
	summarise(ssb=median(SSB),ssb0=median(SSB0))

results$Gamma2$Escapement<-results$Gamma2$ssb/results$Gamma2$ssb0

results$Gamma2

#Given the gamma values tested, gamma 2 is:
results$Gamma_2<-max(results$Gamma2$Gamma[results$Gamma2$Escapement>=0.75])

#What is the approximate Gamma that meets 75% escapement to test.
results$test_gamma_2 <- approx(results$Gamma2$Escapement,results$Gamma2$Gamma,0.75)$y
results$test_gamma_2

#The actual Gamma is the smallest of the two gammas:
results$GammaToUse<-which(c(results$Gamma_1,results$Gamma_2)==
                            min(results$Gamma_1,results$Gamma_2)) #Which gamma is min?
if(length(results$GammaToUse)==2){results$GammaToUse=3} #when gamma1 and gamma2 are equal
results$Selected_gamma<-as.data.frame(cbind(results$Gamma_1, results$Gamma_2,
                                            results$GammaToUse,results$Scenario))
names(results$Selected_gamma) <- c("Gamma_1", "Gamma_2", "Gamma_choice", "Scenario")
results$Selected_gamma

saveRDS(results, file=paste0("../4_Output/Selected_gamma/","Selected_gamma_",pars$proj_file))
}

tictoc::toc()
