#A starting point for the development of the base case
#Script to run the Grym with input parameters for each subarea.

library(Grym)
library(dplyr)
library(tidyr)
library(furrr)
set.seed(123)

#Function to convert dates (given as "dd/mm") into increments as required by Grym
Grym_dates=function(StartDate,MyDate){
  if(as.numeric(difftime(as.Date(paste0(MyDate,"/2000"),format = "%d/%m/%Y"),
                         as.Date(paste0(StartDate,"/2000"),format = "%d/%m/%Y"),
                         units="days"))>=0){
    Val=as.numeric(difftime(as.Date(paste0(MyDate,"/2000"),format = "%d/%m/%Y"),
                            as.Date(paste0(StartDate,"/2000"),format = "%d/%m/%Y"),
                            units="days"))+1
  }else{
    Val=as.numeric(difftime(as.Date(paste0(MyDate,"/2001"),format = "%d/%m/%Y"),
                            as.Date(paste0(StartDate,"/2000"),format = "%d/%m/%Y"),
                            units="days"))+1
  }
  return(Val)
}

#Parameters that are identical for all areas################

#Number of simulation runs
Nits=10000

#Number of cores to use, type availableCores() to see what you've got
Ncores=6

#Gamma values to test
Gammas=seq(0,0.1,by=0.001)

#Reference Start Date:
StartDate="01/10"

#Number of years to project
n.years=20

#Survey data/Recruitment:
R.mean=0.3        #Estimated mean of the number of individuals in the reference age class as a proportion of all individuals of that age or older
R.var=0.06528025  #Estimated variance of the number of individuals in the reference age class as a proportion of all individuals of that age or older
R.class=3         #Reference age class
R.nsurveys=17     #Number of surveys used to estimate `R.mean` and `R.var`

Surv_start=Grym_dates(StartDate,"01/01") #First Day of Survey (dd/mm)	
Surv_end=Grym_dates(StartDate,"15/01")   #Last Day of Survey (dd/mm)	

#Maturity
Mat_Lmin=31 #Min length, 50% are mature	
Mat_Lmax=36 #Max length, 50% are mature	
Mat_R=12    #Range over which maturity occurs

#Spawning Season
Spawn_start=Grym_dates(StartDate,"15/12") #First Day of Spawning Season (dd/mm)	
Spawn_end=Grym_dates(StartDate,"15/02")   #Last Day of Spawning Season (dd/mm)	

#Selectivity
Sel_Lmin=30    #Min length, 50% Selected	
Sel_Lmax=35    #Max length, 50% Selected	
Sel_R=11       #Range over which selection occurs	

#Fishing Season (Year-round)
FS_start=1 
FS_end=365
###########################################

#Subarea-specific parameters###############
SSP=data.frame(
  Area='48.1',
  k_=0.45,                            #VB k factor
  GS=Grym_dates(StartDate,"21/10"),   #Date - start growth period (dd/mm)
  GE=Grym_dates(StartDate,"12/02")    #Date - end growth period (dd/mm)
)
SSP=rbind(SSP,
          data.frame(
            Area='48.2',
            k_=0.45,                            #VB k factor
            GS=Grym_dates(StartDate,"21/10"),   #Date - start growth period (dd/mm)
            GE=Grym_dates(StartDate,"05/02")    #Date - end growth period (dd/mm)   
            )       
          )
SSP=rbind(SSP,
          data.frame(
            Area='48.3',
            k_=0.55,                            #VB k factor
            GS=Grym_dates(StartDate,"09/10"),   #Date - start growth period (dd/mm)
            GE=Grym_dates(StartDate,"27/02")    #Date - end growth period (dd/mm)   
          )       
)
###########################################


## Recruitment model selection
prRecruitPars <- prRecruitParsGYM
prRecruitsQuantile <- prRecruitsQuantileGYM
prRecruits <- prRecruitsGYM

## Model
GammaProjections <- function(R.mean,R.var,R.class,R.nsurveys,
                            gamma=Gammas,Surv_start,Surv_end,
                            Mat_Lmin,Mat_Lmax,Mat_R,Spawn_start,Spawn_end,
                            Sel_Lmin,Sel_Lmax,Sel_R,
                            FS_start,FS_end,k_,GS,GE,n.years) {
  
  ## Daily time steps with 8 age classes
  nsteps <- 365
  Ages <- 0:7
  Days <- seq(0,1,length=nsteps+1)
  h <- 1/nsteps
  
  ## Spawning and monitoring interval
  spawnI <- Spawn_start:Spawn_end
  monitorI <- Surv_start:Surv_end
  
  ## Ages, length at age and weight at age
  ages <- outer(Days,Ages,FUN="+")
  ls <- vonBertalanffyRAL(ages,t0=0,K=k_,Linf=60,f0=GS/365,f1=GE/365)
  ws <- powerLW(ls,1,3)
  
  ## Constant intra-annual natural mortality
  ms <- matrix(1,nsteps+1,length(Ages))
  Ms <- ctrapz(ms,h)
  Msf <- final(Ms)
  
  ## Within year fishing pattern - season is first 90 days
  fwy <- double(nsteps+1)
  fwy[FS_start:FS_end] <- 1
  fwy <- fwy/mean(fwy)
  
  ## Recruitment survey - parameters for the observed ratios
  ps0 <- prRecruitPars(Msf,R.mean,R.var,r=R.class)
  
  B0logsd <- 0.6
  
  ## This function performs one projection for each prescribed gamma.
  function(OneProjection) {
    
    ## Length based maturity and selectivity - ramp width is constant
    ## but the midpoint is selected uniformly from a range.
    gs <- rampOgive(ls,runif(1,Mat_Lmin,Mat_Lmax),Mat_R) #Maturity
    ss <- rampOgive(ls,runif(1,Sel_Lmin,Sel_Lmax),Sel_R) #Selectivity
    
    ## Construct fishing mortalities from season and selectivity
    fs <- fwy*ss #Fishing pattern * selectivity
    Fs <- ctrapz(fs,h)
    Fsf <- final(Fs)
    
    ## Boostrap resample to account for uncertainty in R.mean and R.var
    repeat {
      Rbt <- prBootstrap(prRecruits,ps0,R.nsurveys,Msf,r=R.class)
      ps <- tryCatch(prRecruitPars(Msf,R.mean,R.var,r=R.class),error=function(e) e)
      if(!inherits(ps,"error")) break
    }
    
    ## Natural mortalities from proprtional recruitment model
    M <- ps$M
    MMs <- M*Ms
    
    ## Median spawning biomass estimated from 1000 samples
    R <- matrix(prRecruits(1000*length(Msf),ps),1000,length(Msf))
    ssb0 <- spawningB0S(R,gs,ws,Ms,M,spawn=spawnI)$median
    
    ## Stochastic initial age structure in the absence of fishing
    N0 <- ageStructureS(prRecruits(length(Msf),ps),Msf,M)
    
    ## Recruitment series
    Rs <- prRecruits(n.years,ps)
    
    ## Matrix of annual summaries
    n <- (1+n.years)*length(gamma)
    df <- matrix(0,n,11)
    colnames(df) <- c("Year","Gamma","R","N","B","B0","SSN","SSB","SSB0","Catch","F")
    
    ## Initial projection assuming no fishing
    pr0 <- project(ws,MMs,Nref=N0,yield=0)
    pr0$F <- pr0$Y <- 0
    
    ## Initial biomass in monitoring period + log Normal error
    b0 <- meanStock(pr0$B,period=monitorI)
    b0 <- rlnorm(1,log(b0)-B0logsd^2/2,B0logsd)
    
    k <- 0
    ## Project for each gamma ratio
    for(g in gamma) {
      ## Target catch
      catch <- g*b0
      
      ## Reset to virgin state
      pr <- pr0
      ssb <- spawningStock(pr$B,gs,spawnI)
      
      for(yr in 0:n.years) {
        
        if(yr > 0) {
          ## Recruitment depletion
          r <- min(1,ssb/(0.2*ssb0))
          ## Project over year
          N0 <- advance(pr$N,r*Rs[yr])
          pr <- projectC(ws,MMs,Fs,fs,catch,Nref=N0,yield=1,Fmax=1.5)
          #if(pr$F==1.5) return(NULL)
        }
        ssb <- spawningStock(pr$B,gs,spawnI)
        
        ## Collate annual summaries
        df[k<-k+1,] <- c(yr,g,initial(pr$N)[1],sum(initial(pr$N)),sum(initial(pr$B)),b0,
                         spawningStock(pr$N,gs,spawnI),ssb,ssb0,sum(pr$Y),pr$F)
        
      }
    }
    data.frame(Run=OneProjection,M=M,df)
  }
}


OUT=NULL #To Store outputs
#Loop over Subareas 
for(a in c('48.1','48.2','48.3')){
cat(paste0('Subarea ',a,'\n'))
  #Define per-run parameters
  k_=SSP$k_[SSP$Area==a]
  GS=SSP$GS[SSP$Area==a]
  GE=SSP$GE[SSP$Area==a]
  
  
  
#Run projections for each gamma
sim <- GammaProjections(R.mean,R.var,R.class,R.nsurveys,
                       gamma=Gammas,Surv_start,Surv_end,
                       Mat_Lmin,Mat_Lmax,Mat_R,Spawn_start,Spawn_end,
                       Sel_Lmin,Sel_Lmax,Sel_R,
                       FS_start,FS_end,k_,GS,GE,n.years)

#Run 'sim' Nits times, in parallel
plan(multisession,workers=Ncores)  #Start multisession
df <- future_map_dfr(1:Nits,sim,.options = future_options(seed = TRUE))
plan(sequential) #End multisession

## Results
#Gamma 1:
#Choose a yield, gamma 1, so that the probability of the spawning biomass dropping below 20% of its
#median pre-exploitation level over a 20-year harvesting period is 10%.
Gamma1=df %>% group_by(Gamma,Run) %>% summarize(Dep=min(SSB/SSB0)) %>% summarize(Pr=mean(Dep < 0.2))
#Given the gamma values tested, gamma 1 is:
ga1=max(Gamma1$Gamma[Gamma1$Pr<=0.1])
#Gamma 2:
#Choose a yield, gamma 2, so that the median escapement at the end of a 20 year period is 75% of the
#median pre-exploitation level.
Gamma2= df %>%  group_by(Gamma) %>% filter(Year %in% max(Year)) %>% summarise(ssb=median(SSB),ssb0=median(SSB0))
Gamma2$Ratio=Gamma2$ssb/Gamma2$ssb0
#Given the gamma values tested, gamma 2 is:
ga2=max(Gamma2$Gamma[Gamma2$Ratio>=0.75])
#The actual Gamma is the smallest of the two gammas:
ga=min(ga1,ga2)
gx=which(c(ga1,ga2)==ga) #Which gamma is min?
if(length(gx)==2){gx=3} #gx=3 when gamma1 and gamma2 are equal
OUT=rbind(OUT,cbind(a,ga1,ga2,ga,gx))


}

OUT=as.data.frame(OUT)
colnames(OUT)[1]="Subarea"
OUT$ga1=as.numeric(OUT$ga1)
OUT$ga2=as.numeric(OUT$ga2)
OUT$ga=as.numeric(OUT$ga)
OUT$gx=as.numeric(OUT$gx)


OUT$ga[is.finite(OUT$ga)==F]=NA
write.csv(OUT,'OUT.csv',row.names = F)
