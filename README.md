# Grym_Base_Case

The idea of this repository is to provide a base case implementation of the Grym assessment for <i>E. superba</i>.
The base cases will be performed using the same basic configuration as the assessments evaluated in during the 2010 WG-EMM that were fitted using the GYM software with the following changes: 
  
  1. they will be fitted in using the Grym package in R, 
  2. they will be area specific, 
  3. they will use updated biological parameters for each Subarea where they are available. 

The idea for having a base case is to essentially have assessments that are ready for management advice using previously agreed upon configurations available for WG-EMM-2021. They will provide the infrastructure for other implementations to be explored (such as RecMaker recruitment, different recruitment functions etc.) whilst still having assessments for each Subarea ready to go should these different implementations not be ready in time for WG-EMM-2021. 




## Grym package installation and use instructions

If you have not done so yet, download and install R (https://cloud.r-project.org/) and Rstudio (https://rstudio.com/products/rstudio/download/#download).
If you already have, make sure these are up to date.

### 1.	Install accessory packages
Start R studio. In the Console, type:

`install.packages(c("remotes","devtools","knitr","ggplot2","dplyr","tidyr","furrr","rmarkdown","future"))`

### 2.	Install the Grym package
In the Console, type:

`remotes::install_github("AustralianAntarcticDivision/Grym", build_vignettes=TRUE)`


### 3.	Explore the Grym’s help files and tutorials
In the Console, type:

`library(Grym)`

then,

`browseVignettes(package="Grym")`

This will open a web browser from which you can access a description of the Grym as well as an example (“Icefish”). It is recommended to view these documents as HTML pages.

Additional examples are located inside the Grym package directory. To find its location in your computer, type:

`find.package("Grym")`

You may then go to that location in your computer (outside of R Studio), and in the ‘examples’ subfolder, you will find the "Examples.html" file which contains further useful documentation.

### 4.	Download a repository from GitHub

The following applies to any repository but is here described for the Grym base case, here: https://github.com/ccamlr/Grym_Base_Case

On that repository’s page, go to ‘Code’ and ‘download ZIP’:
 
![](https://github.com/ccamlr/Grym_Base_Case/tree/master/Readme Images/Readme_img00.png)

Extract the contents of that zip file on your computer. In the folder ‘Grym_Base_Case-master’ you will find an R project file named ‘Grym_Base_Case.Rproj’:

![](Readme Images/Readme_img02.png)
 
Double click on that file. You are now inside the “Grym_Base_Case” R project, as shown by the icon at the top right corner of R Studio:
 
![](Readme Images/Readme_img01.png)
 
Whenever you wish to use the scripts contained in this repository, it is crucial to first open the R project file named “Grym_Base_Case.Rproj”. This will ensure that R Studio knows where all the files are.

Once inside the project, you may now run some simulations. Go to the file browser inside R studio and click on ‘3_Code’:
 
![](Readme Images/Readme_img03.png)

The code is embedded in an Rmarkdown file named “48.1_base_case.rmd”. Click on it, it will open inside R studio. 
Prior to running your first test, it is recommended to do a simulation with few runs otherwise it might take a long time. Inside the markdown, navigate to the line where the number of runs is set:

![](Readme Images/Readme_img04.png)
 
And change to `Runs<-100`, for example. Then save.
To execute the code, you must ‘knit’ the markdown, by clicking on the knit button:

![](Readme Images/Readme_img05.png)

Once the knitting process is finished, the result is shown in a pop-up window (48.1_base_case.html).

### 5.	Keeping your repository up to date

Because the repository will change over time, you must keep your version, on your computer, up to date. To update your repository, Simply re-download it as per Section 4 instructions.



#### A few points about this repository
#### Structure:
The code is designed to work in three tiers, at the bottom is the `Projection_function.R`, in the middle is an Rmarkdown for each Subarea (e.g. `48.1_base_case.rmd`), and at the top is an Rmarkdown which pulls together each Subarea Rmarkdown into one document.  

The reason for this structure is:
  1. The `Projection_function.R` contains the `KrillProjection()` function that will be used for each run of the Grym and has no hard coded or default biological parameter values. Once the base cases are done, in order to try different implementations this file would just need to be copied and renamed and then the `KrillProjection()` function modified for the desired implementation which is then easily passed up to each Subarea assessment. 
  2. Having each Subarea in their own Rmarkdown means that we can work on getting one area right first explaining where its values come from and how they are calculated and then quickly rolling it out to the other Subareas, it also means you can quickly test other implementations by only applying them to a single area first and making modifications where needed before rolling them out to other areas. 
  3. Finally having an overarching file means you can run all the subareas at once when you are happy with your models and have them in one document.  
  
- The Data folder contains data used for estimating parameters where it is publicly available. 

- The folder Parameters contains some preliminary parameter values, as discussed during EMM. This folder will be updated with the code and parameter values as they are calculated and discussed within issue #1. 

- The Code folder will contain the `Projection_function.R` file and the Subarea specific markdowns when they have been developed. 

- The Old_not_used folder contains old code which is not being used for varying reasons and may contain errors. 

#### About the code as it is now

- The `Projection_function.R` as it is now will produce consistent results with the 2010 example when given the same input values. 
- The function itself could use some more comments on what is happening at each step and Simon and Dale will work on that soon. 
- Naming conventions have tried to stay consistent with the examples in the GrymExamples package as much as possible. - There is two flow charts in the flow-charts.html which are a work in progress (the colors need fixing) which show in both overly simplified, and very detailed, how the Grym is constructed in `KrillProjection` function. 

- Having started with 48.1 the `48.1_base_case.rmd` provides detailed steps for each of the parameter inputs to the projections, but the overall document is still a work in progress.
- The rest of the Subareas will be implemented very quickly once the table in issue #1 is completed. 

