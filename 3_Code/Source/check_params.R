check_params <- function(pars, recs){
  R.mean <- pars$R.mean == recs$R.mean
  R.sd <- pars$R.sd == recs$R.sd
  R.class <- pars$R.class == recs$R.class
  R.nsurveys <- pars$R.nsurveys == recs$R.nsurveys
  Iterations <- pars$Iterations == nrow(recs$pars)
  Ages <- pars$Ages == recs$Ages
  nsteps <- pars$nsteps == recs$nsteps
  
  nms <- c("R.mean", "R.sd","R.class", "R.nsurveys","Iterations", "Ages", "nsteps")
  
  trues <- which(c(R.mean, R.sd,R.class, R.nsurveys,Iterations, Ages, nsteps))
  wrong <- nms[-trues ]
  
  if(length(wrong)>0)
    stop(paste("Recruitment and Setup parameters do not match.", "\n", "check:", wrong))
  
  if(length(wrong)==0)
    message("Recruitment and Setup parameters match.")
    
}


