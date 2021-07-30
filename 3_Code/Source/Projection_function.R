KrillProjection <- function(
        nsteps, Ages, #time step numbers and age classes
        spawnI,monitorI,fishingI, #Interval sequences
        R.mean,R.var,R.class,R.nsurveys, #Recruitment Variables
        t0,K,Linf,f0,f1, #Growth details
        a, b, #Length/Weight Details
        sel50Min,	sel50Max,	selrange, #Selectivity Parameters
        mat50Min,	mat50Max,	matrange, #Maturity parameters
        B0logsd, #biomass log cv
        prRecruitPars,prRecruit, #recruitment parameters and quantile function
        gamma=c(0,0.04,0.08,0.1),n.years=20 #Test details
        ) {
  if(!inherits(prRecruitPars, "matrix")) prRecruitPars <- as.matrix(prRecruitPars)
  # Create a sequence from 0-1 for each time step. The value is the proportion of that timestep in the year.
  Days <- seq(0,1,length=nsteps+1)
  #The proportion of an individual time step in the year (0.002739726 for daily timesteps)
  h <- 1/nsteps

  ## Spawning and monitoring interval are defined as inputs into the function.
  ## Should be as timesteps eg 76:138

  ## Ages, length at age and weight at age
  ages <- outer(Days,Ages,FUN="+")#Ages of each age class for every timestep
  ls <- vonBertalanffyRAL(ages,t0=t0,K=K,Linf=Linf,f0=f0,f1=f1)#length of each age class for every timestep
  ws <- powerLW(ls,a=a,b=b)#weight of each age class for every timestep

  ## Constant intra-annual natural mortality
  ms <- matrix(1,nsteps+1,length(Ages))#Proportion of mortality to apply for each timestep to each age class (if constant should all be one)
  Ms <- ctrapz(ms,h)# Cumulative timestep proportional mortality
  Msf <- final(Ms)#Sum of mortality for each age class (if constant across ages, should all be one.)

  ## Within year fishing pattern - season is first 90 days
  fwy <- double(nsteps+1) #Sequence of 0s for the length of the year
  fwy[fishingI] <- 1		#Set the fishing season increments to 1.
  fwy <- fwy/mean(fwy)  #Average the fishing mortality so the average is 1 across all increments.

  #B0logsd <- 0.2

  ## This function performs the a projection for each prescibed gamma.
  function(run) {
    ## Length based maturity and selectivity - ramp width is constant
    ## but the midpoint is selected uniformly from a range.
    gs <- rampOgive(ls,runif(1,mat50Min,mat50Max),matrange) #Maturity ogive
    ss <- rampOgive(ls,runif(1,sel50Min,sel50Max),selrange)  #Selectivity ogive

    ## Construct fishing mortalities from season and selectivity
    fs <- fwy*ss #Age + time step fishing mortality
    Fs <- ctrapz(fs,h) #Cumulative #Age + time step fishing mortality
    Fsf <- final(Fs) #Final yearly fishing mortality for each age class.

    ## Extract recruitment parameters for this run
    ps <- unname(prRecruitPars[run,])

    ## Natural mortalities from proprtional recruitment model
    M <- ps[1] #Yearly M from bootstrapped recruitment
    MMs <- M*Ms #Timestep cumulative mortality for each age class.

    ## Median spawning biomass estimated from 1000 samples
    R <- matrix(prRecruit(1000*length(Msf),ps[3],ps[4]),1000,length(Msf))
    ssb0 <- spawningB0S(R,gs,ws,Ms,M,spawn=spawnI)$median
    ## Stochastic initial age structure in the absence of fishing
    N0 <- ageStructureS(prRecruit(length(Msf),ps[3],ps[4]),Msf,M)
    ## Recruitment series
    Rs <- prRecruit(n.years,ps[3],ps[4])
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
    data.frame(Run=run,M=M,df)
  }
}



