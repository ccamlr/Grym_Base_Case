KrillProjection <- function(
	nsteps, Ages, #time step numbers and age classes
	spawnI,monitorI,fishingI, #Interval sequences
	R.mean,R.var,R.class,R.nsurveys, #Recruitment Variables
	t0,K,Linf,f0,f1, #Growth details 
	a, b, #Length/Weight Details
	sel50Min,	sel50Max,	selrange, #Selectivity Parameters
	mat50Min,	mat50Max,	matrange, #Maturity parameters
	B0logsd, #biomass log cv
	prRecruitPars=prRecruitParsGYM,	prRecruitsQuantile=prRecruitsQuantileGYM,	prRecruits=prRecruitsGYM, #recruitment functions
	gamma=c(0,0.04,0.08,0.1),n.years=20 #Test details
	) {

	Days <- seq(0,1,length=nsteps+1)
	h <- 1/nsteps
	## Spawning and monitoring interval
	
	## Ages, length at age and weight at age
	ages <- outer(Days,Ages,FUN="+")
	ls <- vonBertalanffyRAL(ages,t0=t0,K=K,Linf=Linf,f0=f0,f1=f1)
	ws <- powerLW(ls,a=a,b=b)
	## Constant intra-annual natural mortality
	ms <- matrix(1,nsteps+1,length(Ages))
	Ms <- ctrapz(ms,h)
	Msf <- final(Ms)
	## Within year fishing pattern - season is first 90 days
	fwy <- double(nsteps+1)
	fwy[fishingI] <- 1
	fwy <- fwy/mean(fwy)
	## Recruitment survey - parameters for the observed ratios
	ps0 <- prRecruitPars(Msf,R.mean,R.var,r=R.class)
	#B0logsd <- 0.2
	
	## This function performs the a projection for each prescibed gamma.
	function(run) {
		## Length based maturity and selectivity - ramp width is constant
		## but the midpoint is selected uniformly from a range.
		gs <- rampOgive(ls,runif(1,mat50Min,mat50Max),matrange)
		ss <- rampOgive(ls,runif(1,sel50Min,sel50Max),selrange)
		## Construct fishing mortalities from season and selectivity
		fs <- fwy*ss
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
		data.frame(Run=run,M=M,df)
	}
}



