#### recalculate the quintiles from the 2015-16 HICES
#### split by urban rural 

library(tidyr)
library(readr)
library(sf)
library(rmapshaper)
library(readxl)
library(here)
library(ggplot2)
library(hrbrthemes)
library(wesanderson)
library(srvyr)
library(treemap)
library(treemapify)
library(ggridges)
library(gt)
library(haven)
library(foreign)
library(dplyr)

eth_hces1516 <- as.data.frame(read.spss(here::here("../MIMI_data/Ethiopia/HICES/ETH-HICE-2016/Data/SPSS 16/HCES_2015_2016_Expenditure.sav")))
eth_hces1516_demography <- as.data.frame(read.spss(here::here("../MIMI_data/Ethiopia/HICES/ETH-HICE-2016/Data/SPSS 16/HCES_2015_2016_DEMOGRAPHY.sav")))


unique(eth_hces1516_demography$ur)

eth_hces1516_demography$hhid <-  paste0(as.character(eth_hces1516_demography$CQ11),
                                "_",
                                as.character(eth_hces1516_demography$CQ12),
                                "_",
                                as.character(eth_hces1516_demography$CQ13),
                                "_",
                                as.character(eth_hces1516_demography$CQ14),
                                "_",
                                as.character(eth_hces1516_demography$CQ15),
                                "_",
                                as.character(eth_hces1516_demography$CQ16),
                                "_",
                                as.character(eth_hces1516_demography$CQ17),
                                "_",
                                as.character(eth_hces1516_demography$CQ18))

eth_pc <- eth_hces1516_demography %>% 
  dplyr::select(hhid, CQ1103) %>% 
  group_by(hhid) %>% 
  summarise(pc = n())

# create hhid 
eth_hces1516$hhid <- paste0(as.character(eth_hces1516$CQ11),
                            "_",
                            as.character(eth_hces1516$CQ12),
                            "_",
                            as.character(eth_hces1516$CQ13),
                            "_",
                            as.character(eth_hces1516$CQ14),
                            "_",
                            as.character(eth_hces1516$CQ15),
                            "_",
                            as.character(eth_hces1516$CQ16),
                            "_",
                            as.character(eth_hces1516$CQ17),
                            "_",
                            as.character(eth_hces1516$CQ18))

names(eth_hces1516)
#calculate the total expnediture per hh



x <- eth_hces1516 %>%
  dplyr::select(hhid, VALUE, CQ14, QUANTITY,STPRICE,FOOD,FOODEXP,EXPCC, ADEQUIV) %>%
  group_by(hhid, CQ14,ADEQUIV, EXPCC) %>%
  summarise(tot_val = sum(VALUE)) %>%
  left_join(eth_pc, by ="hhid") %>% 
  mutate(total_per_cap = tot_val/pc) %>%
  ungroup() %>%
  mutate(quintile =
           case_when(
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[2]]~
               "1",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[3]]~
               "2",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[4]]~
               "3",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[5]]~
               "4",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[6]]~
               "5",
           )) 
# mutate(quintile =
#          case_when(
#            total_per_cap<y[[2]]~
#              "exp quant 1",
#            total_per_cap<y[[3]]~
#              "exp quant 2",
#            total_per_cap<y[[4]]~
#              "exp quant 3",
#            total_per_cap<y[[5]]~
#              "exp quant 4",
#            total_per_cap<y[[6]]~
#              "exp quant 5",
#          )) %>%
# group_by(quintile) %>%
# summarise(n = n(),
#           max = max(total_per_cap),
#           min = min(total_per_cap), 
#           perc = n/30230)

quantile(x$total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)

x %>% 
  filter(EXPCC == "Expenditure Quantile 3") %>% 
  summarise(max(tot_val))

# mutate(quintile = 
#          case_when(
#            total_per_cap<y[[2]]~
#              "exp quant 1",
#            total_per_cap<y[[3]]~
#              "exp quant 2",
#            total_per_cap<y[[4]]~
#              "exp quant 3",
#            total_per_cap<y[[5]]~
#              "exp quant 4",
#            total_per_cap<y[[6]]~
#              "exp quant 5",
#          ))
# %>% 
  # group_by(EXPCC) %>% 
  # summarise(n())

y <- quantile(x$total_per_cap,probs = c(0,.111,.248,0.40,0.62, 1), na.rm = TRUE, type =9)
y 
max(x$total_per_cap)

c(0,0.2,.4,.6,.8,1)
unique(eth_hces1516$CQ14)

# need to ask about quintile calculation... but if it's ok then we can get this

# need to account for inflation during the year
CPI_2015 <- 207.288196	#world bank data (https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=ET)
CPI_2016 <- 221.0275341
prices_2016 <- CPI_2016/CPI_2015

CPI_eth <- data.frame(
  month = c("July", 
            "August",
            "September",
            "October",
            "November",
            "December",
            "January",
            "February",
            "March",
            "Paquma",
            "April",
            "May",
            "June"
            ),
  year = c(2015,2015,2015,2015,2015,2015,
           2016,2016,2016,2016,2016,2016,2016
           ),
  CPI = c(146.0,146.7,148.4,148.8,145.8,145.9,
          147.6,147.4,148.3,148.3,150.5,152.5,154.0
          )
)



CPI_eth <- CPI_eth %>% 
  mutate(ref_july_2015 = CPI/146.0) 


eth_hces1516 %>% 
  left_join(CPI_eth, by = c("MONTH" = "month"))



unique(eth_hces1516$hhid[eth_hces1516$MONTH=="Paquma"])
unique(eth_hces1516$MONTH)

eth_hces_urbrur_quint <- eth_hces1516 %>% 
  select(hhid, VALUE, UR, QUANTITY,STPRICE,FOOD,FOODEXP,EXPCC, ADEQUIV, MONTH) %>% 
  dplyr::mutate(ADEQUIV = ifelse(is.na(ADEQUIV),1,ADEQUIV)) %>% 
  group_by(hhid, UR,ADEQUIV, EXPCC, MONTH) %>% 
  summarise(tot_val = sum(VALUE)) %>% 
  left_join(CPI_eth, by = c("MONTH" = "month")) %>%
  # ungroup() %>% 
  # summarise(sum(is.na(ref_july_2015)))
  mutate(tot_val = ref_july_2015*tot_val) %>%
  ungroup() %>%
  # adjust for inflation
  mutate(total_per_cap = tot_val/ADEQUIV) %>% 
  ungroup() %>% 
  mutate(quintile =
           case_when(
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[2]]~
               "1",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[3]]~
               "2",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[4]]~
               "3",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[5]]~
               "4",
             total_per_cap<=quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[6]]~
               "5",
           )) %>% 
  group_by(UR) %>% 
  mutate(ur_quintile =
           case_when(
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[2]]~
               "1",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[3]]~
               "2",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[4]]~
               "3",
             total_per_cap<quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[5]]~
               "4",
             total_per_cap<=quantile(total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)[[6]]~
               "5",
           )) %>% 
  select(hhid, UR, quintile,total_per_cap, ur_quintile, EXPCC) 
 
  # filter(!is.na(ur_quintile))#only 2 hosueholds, random

## summarise the number in each quintile

quantile(eth_hces_urbrur_quint$total_per_cap,probs = seq(0,1,0.2), na.rm = TRUE)
summary(eth_hces_urbrur_quint$UR)

eth_hces_urbrur_quint %>%
  ungroup() %>% 
  group_by(UR, ur_quintile) %>% 
  summarise(n())#split into quintiles, but need to know what "Paquma" is 


eth_hces1516 %>% 
  select(hhid, VALUE, CQ14, QUANTITY,STPRICE,FOOD,FOODEXP,EXPCC, ADEQUIV) %>% 
  group_by(hhid, CQ14,ADEQUIV, EXPCC) %>% 
  summarise(tot_val = sum(VALUE)) %>% 
  mutate(total_per_cap = tot_val/round(ADEQUIV)) %>% 
  ungroup() %>% 
  mutate(urbrur = ifelse(CQ14 == "Rural", "Rural", "Urban")) %>% 
  group_by(urbrur,EXPCC) %>% 
  summarise(n())

write_csv(eth_hces_urbrur_quint, here::here("ethiopia/data/urb_rur_quintiles.csv"))
