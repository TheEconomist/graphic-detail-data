## Replication package for "Out in the Open"

## PLOT A

# Load democracy data:
democracy <- read.csv("democracy-v3.0.csv")

# Restrict by year:
democracy <- democracy[democracy$year %in% 1960:2019, ]

# Selecting our democracy variable as 50 percent of more of adults can vote in free and fair elections:
democracy$boix_democracy <- ifelse(democracy$democracy_femalesuffrage, "Democracies", "Non-Democracies")

# Boix et al only gives data up to 2015, which presents a difficulty for later years. Rather than attempting to code states as democratic or non-democratic ourselves, which would be prone to error and not peer-reviewed, we use the 2015 coding for countries for the years 2016-2019. Democratic transtitions (be it to or from) are rare - only three countries changed in the period 2005-2015.
temp <- democracy[democracy$year == 2015 & !is.na(democracy$year), ]

for(i in c(2016, 2017, 2018, 2019)){
  temp$year <- i
  democracy <- rbind(democracy, 
                     temp)
}

democracy <- democracy[, c("ccode", "year", "boix_democracy")]

# Load real gdppc (ppp-adjusted constant 2011 dollars, 'rgdpanpc') data from the Maddison project:
mad_gdppc <- read.csv("maddison_project_gdppc.csv")

# Restrict by year:
mad_gdppc <- mad_gdppc[mad_gdppc$year %in% 1960:2019, ]

# Adjust dollars for inflation to get 2020 dollars instead of 2011 dollars:
mad_gdppc$rgdpnapc <- mad_gdppc$rgdpnapc * 1.15

# Maddison only gives data up to 2016 (and for 3 units which did not experience later epidemics, 2015), but has much better coverage for earlier years than those supplying more recent data, such as the World Bank. Merging the two is not easy as the methodologies are different. We therefore carry forward values from 2016 to 2017, 2018, and 2019, for the small number of epidemics happening in those years.
temp <- mad_gdppc[mad_gdppc$year == 2016 & !is.na(mad_gdppc$year), ]

for(i in c(2017, 2018, 2019)){
temp$year <- i
mad_gdppc <- rbind(mad_gdppc, temp)
}

# This loads all epidemics with at least one death between 1960 and 2019:
emdat_full <- read.csv("emdat_full.csv")
emdat_full <- emdat_full[emdat_full$Disaster.Type == "Epidemic" &
                           !is.na(emdat_full$Disaster.Type) &
                           emdat_full$Year >= 1960 &
                           emdat_full$Year <= 2019 &
                           !is.na(emdat_full$Year) &
                           emdat_full$Total.Deaths > 0 &
                           !is.na(emdat_full$Total.Deaths), ]

# Create country-year ID
emdat_full$year <- emdat_full$Start.Year
emdat_full$id <- paste0(emdat_full$ISO, "_", emdat_full$year)

# Add description
emdat_full$description <- ave(emdat_full$Event.Name, emdat_full$id,
                              FUN = function(x){
                                x[x == ""] <- "unknown"
                                x <- unique(x)
                                paste(x, collapse = ", ")
                              } )
# This collapses deadly epidemics happening in multiple regions in the same year. In a very small number of cases, different epidemic diseases broke out at the same time in the same country. We count these as one epidemic event, with total deaths being the sum over them (counting them separately makes for a very similar graph). 
emdat_full$Total.Deaths <- ave(emdat_full$Total.Deaths, emdat_full$id, FUN = sum)
emdat_full <- emdat_full[!duplicated(emdat_full$id), ]

# Get correlates of war country codes to facilitate merging:
library(countrycode)
mad_gdppc$ccode <- countrycode(mad_gdppc$countrycode, "iso3c", "cown")
# Fixing a few states (other with missing country codes were not considered independent by the democracy dataset):
mad_gdppc$ccode[mad_gdppc$countrycode == "CSK"] <- 315  
mad_gdppc$ccode[mad_gdppc$countrycode == "SRB"] <- 342
mad_gdppc$ccode[mad_gdppc$countrycode == "SUN"] <- 364
mad_gdppc$ccode[mad_gdppc$countrycode == "YUG"] <- 347

emdat_full$ccode <- countrycode(emdat_full$ISO, "iso3c", "cown")
# Fixing Yugoslavia (other with missing country codes were not considered independent by the democracy dataset):
emdat_full$ccode[emdat_full$Country == "Yugoslavia"] <- 347 

# Merging the three:
pdat <- merge(democracy, mad_gdppc[, c("ccode", "year", "rgdpnapc", "pop")], by = c("ccode", "year"))
pdat <- merge(pdat, emdat_full[, c("ccode", "year", "Total.Deaths", "Continent", "description")])

# Get our variables:
pdat$dead_per_100k <- 100*pdat$Total.Deaths / pdat$pop # (population is in thousands)


ggplot(pdat, aes(x=rgdpnapc, y = dead_per_100k, col = boix_democracy))+
  geom_point()+geom_smooth(method = lm)+
  scale_y_continuous(trans = "log10", labels = function(x) format(x, scientific = FALSE), limits = c(0.001, 150))+
  scale_x_continuous(trans = "log10")

# In the plot, we allow the slopes of democracy and non-democracy to vary with income, i.e. for an interaction effect between democracy and income. We find that the two tend to go together.

# We provide two sets of confidence intervals here, standard confidence intervals and country-clustered ones. For the page, we selected the country-clustered confidence intervals (which are wider): 
library(estimatr)
lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy * log(rgdpnapc), data = pdat, cluster = ccode) 
lm_model <- lm(log(dead_per_100k) ~ boix_democracy * log(rgdpnapc), data = pdat) 
summary(lm_robust)

pdat <- cbind(pdat, exp(predict(lm_robust, newdata = pdat, interval = "confidence")[[1]]))
colnames(pdat)[(ncol(pdat)-2):ncol(pdat)] <- c("fit_interaction", "lwr_interaction", "upr_interaction")

pdat <- cbind(pdat, exp(predict(lm_model, newdata=pdat, interval = "confidence")))
colnames(pdat)[(ncol(pdat)-2):ncol(pdat)] <- c("fit_interaction_standard_CI", "lwr_interaction_standard_CI", "upr_interaction_standard_CI")

pdat$actual_vs_predicted <- abs(pdat$dead_per_100k - pdat$fit)
pdat$country_year <- paste0(pdat$country, " (", pdat$year, ")")

library(ggplot2)
ggplot(pdat, aes(x=rgdpnapc, y=dead_per_100k, col = boix_democracy, group = boix_democracy))+
  geom_point(alpha = 0.2, size = log(pdat$Total.Deaths)/3)+
  theme_minimal()+
  theme(legend.title = element_blank(), legend.position = "bottom")+
  geom_ribbon( aes(ymin = lwr_interaction, ymax = upr_interaction, fill = boix_democracy, color = NULL), alpha = .15) +
  geom_line( aes(y = fit_interaction), size = 1)+
  xlab("GDP per capita, PPP-adjusted 2020 USD\n")+
  ggtitle("Epidemics in Democracies and Non-Democracies (1960-2019)\n\nSubtitle: In the past half-century, epidemics have been more deadly in non-democracies")+
  ylab("Deaths per 100 000 population")+
  scale_y_continuous(trans = "log10", labels = function(x) format(x, scientific = FALSE), limits = c(0.001, 150))+
  scale_x_continuous(trans = "log10")

# Robustness checks:

# The most conservative and straightforward way to test for differences between democracies and non-democracies:
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + log(rgdpnapc), data = pdat, cluster = ccode))

# Conclusion: significantly higher deaths in non-democracies (p = 0.001)

# Additionally control: continent fixed effects and income
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + log(rgdpnapc) + Continent, data = pdat, cluster = ccode))

# Conclusion: significantly higher deaths in non-democracies (p = 0.009)

# Additionally control: income spline
library(splines)
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + bs(log(rgdpnapc)) + Continent, data = pdat, cluster = ccode))

# Conclusion: significantly higher deaths in non-democracies (p = 0.01)

# Additionally control: year spline, continent fixed effects and income 
library(splines)
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + log(rgdpnapc) + bs(year) + Continent, data = pdat, cluster = ccode))

# Conclusion: borderline significantly higher deaths in non-democracies (p < 0.11)

# Weighting by log population
library(splines)
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + log(rgdpnapc), data = pdat, cluster = ccode, weights = log(pop)))

# Conclusion: borderline significantly higher deaths in non-democracies (p < 0.02)

# Weighting by log income (imperfect proxy for data quality)
library(splines)
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ boix_democracy + log(rgdpnapc), data = pdat, cluster = ccode, weights = log(rgdpnapc)))

# Conclusion: borderline significantly higher deaths in non-democracies (p < 0.01)

# But what about other definitions of democracy? 
# The Polity Projects provides a widely used autocracy-democracy dimension (polity2). By convention countries with a score of 7 or more are coded as democratic:
polity <- read.csv("p4v2016.csv")
polity$polity_democracy <- ifelse(polity$polity2 >= 7, "Democracies (Polity)", "Non-Democracies (Polity)")

# Carry forward values as previously:
temp <- polity[polity$year == 2016, ]
for(i in c(2017, 2018, 2019)){
  temp$year <- i
  polity <- rbind(polity, 
                     temp)
}

pdat <- merge(pdat, polity[, c("ccode", "year", "polity2", "polity_democracy")], by = c("ccode", "year"), all.x = T)

# Binary polity2 measure:
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ polity_democracy + log(rgdpnapc), data = pdat, cluster = ccode))
# Conclusion: significantly higher deaths in non-democracies (p < 0.01)

# Continuous polity2 measure:
summary(lm_robust <- lm_robust(log(dead_per_100k) ~ polity_democracy + log(rgdpnapc), data = pdat, cluster = ccode))
# Conclusion: significantly higher deaths in non-democracies (p < 0.001)

# Replication of plot:
library(estimatr)
lm_robust <- lm_robust(log(dead_per_100k) ~ polity_democracy * log(rgdpnapc), data = pdat, cluster = ccode) 

pdat <- cbind(pdat, exp(predict(lm_robust, newdata = pdat, interval = "confidence")[[1]]))
colnames(pdat)[(ncol(pdat)-2):ncol(pdat)] <- c("fit_interaction_polity", "lwr_interaction_polity", "upr_interaction_polity")

library(ggplot2)
ggplot(pdat[!is.na(pdat$polity_democracy), ], aes(x=rgdpnapc, y=dead_per_100k, col = polity_democracy, group = polity_democracy))+
  geom_point(alpha = 0.2)+
  theme_minimal()+
  theme(legend.title = element_blank(), legend.position = "bottom")+
  geom_ribbon( aes(ymin = lwr_interaction_polity, ymax = upr_interaction_polity, fill = polity_democracy, color = NULL), alpha = .15) +
  geom_line( aes(y = fit_interaction_polity), size = 1)+
  xlab("GDP per capita, PPP-adjusted 2020 USD\n")+
  ggtitle("Epidemics in Democracies and Non-Democracies (1960-2019)\n\nSubtitle: In the past half-century, epidemics have been more deadly in non-democracies")+
  ylab("Deaths per 100 000 population")+
  scale_y_continuous(trans = "log10", labels = function(x) format(x, scientific = FALSE), limits = c(0.001, 150))+
  scale_x_continuous(trans = "log10")



# Plot B:

# Load democracy data:
boix <- read.csv("democracy-v3.0.csv")
boix$boix_democracy <- boix$democracy_femalesuffrage
boix <- boix[boix$year == 2015 & !is.na(boix$ccode), ]
boix$boix_democracy <- ifelse(boix$boix_democracy, "Democracies", "Non-Democracies")
boix$boix_democracy <- factor(boix$boix_democracy, levels = c("Non-Democracies", "Democracies"))

# Load Covid-19 data:
# library (readr)
# cv <- read_csv(url("https://raw.githubusercontent.com/TheEconomist/corona/master/output-data/case_data/dat.timeseries.csv?token=AEBNHB3SOYRWZNSIGP67KN262UJCC"))
# saveRDS(cv, "covid19data.RDS")
cv <- readRDS("covid19data.RDS")

# Merge the two:
library(countrycode)
boix$iso2c <- countrycode(boix$ccode, "cown", "iso2c")
boix$iso2c[boix$ccode == 342] <- "RS"
boix$iso2c[boix$ccode == 348] <- "ME"
boix$iso2c[boix$ccode == 529] <- "ET"
boix$iso2c[boix$ccode == 624] <- "SD"
boix$iso2c[boix$ccode == 818] <- "VN"

cv <- merge(cv, boix[, c("boix_democracy", "iso2c")])
cv <- cv[!is.na(cv$boix_democracy), ]
cv$date <- as.Date(cv$date)

# New cases and deaths:
cv <- cv[order(cv$date), ]

# Cases two weeks ago:
cv$confirmed_lagged_two_weeks <- ave(cv$confirmed, cv$country.name, FUN = function(x){
  c(rep(0, 13), x)[1:length(x)]
})

# Exclude if no date or democracy data
cv <- cv[!is.na(cv$boix_democracy) & !is.na(cv$date), ]

# Load Freedom House data:
fh <- read.csv("freedomhouse.csv")
colnames(fh)[1] <- "country"
fh <- fh[fh$Edition == "2020", ]

# This makes media freedom correspond to the relevant term in the Freedom House codebook
fh$media_freedom <- fh$D1

# This ensures smooth merging by making names correspond
fh$country[fh$country == 'Russia'] <- "Russian Federation"
fh$country[fh$country == 'Bahamas'] <- "Bahamas, The"
fh$country[fh$country == 'Brunei'] <- "Brunei Darussalam"
fh$country[fh$country == 'Congo (Kinshasa)'] <- "Congo, Dem. Rep."
fh$country[fh$country == 'Congo (Brazzaville)'] <- "Congo, Rep."
fh$country[fh$country == 'Egypt'] <- "Egypt, Arab Rep."
fh$country[fh$country == 'The Gambia'] <- "Gambia, The"
fh$country[fh$country == 'Iran'] <- "Iran, Islamic Rep."
fh$country[fh$country == 'South Korea'] <- "Korea, Rep."
fh$country[fh$country == 'Kyrgyzstan'] <- "Kyrgyz Republic"
fh$country[fh$country == 'Laos'] <- "Lao PDR"
fh$country[fh$country == 'Slovakia'] <- "Slovak Republic"
cv$country[cv$country.name == "Cuba"] <- "Cuba"

# Merging the two
cv <- merge(cv, fh, by = "country", all.x = T)
summary(cv$media_freedom)

# Exclude if less than 1000 confirmed cases (which makes for more volatile ratios)
pdat <- cv[cv$confirmed >= 1000, ]
pdat$maxdate <- ave(pdat$date, pdat$country, FUN = max, na.rm = T)
pdat <- pdat[pdat$date == pdat$maxdate, ]
pdat <- pdat[!duplicated(pdat$country), ]

# Plot:
ggplot(pdat[pdat$confirmed_lagged_two_weeks >= 1000, ], aes(x=media_freedom, col = boix_democracy, y = deaths / confirmed_lagged_two_weeks))+geom_jitter(alpha = 0.5, width = 0.2)+geom_smooth(method = "lm", col = "black")+theme_minimal()+ylab("Deaths per Confirmed Case two weeks prior\n(20th of May 2020)")+xlab("Media Freedom\n(Freedom House index, 2020)")+theme(legend.title = element_blank())


# Plot C:

# Load Oxford data on government policies:
da <- read.csv("OxCGRT_20200525.csv")[, c("CountryName", "CountryCode", "Date", "StringencyIndex", "C6_Stay.at.home.requirements", "C6_Flag")]
da$Date <- base::as.Date(as.character(da$Date), format = "%Y%m%d")
da <- da[da$Date >= as.Date("2020-02-15"), ]

colnames(da) <- c("country", "countrycode", "date", "strindex", "C6_Stay.at.home.requirements", "C6_Flag")
da$iso3c <- da$countrycode

# Load mobility data (updated):
mob <- read.csv("Global_Mobility_Report.csv")

# Cannot utilize sub-national data here:
mob <- mob[mob$sub_region_1 == "" & mob$sub_region_2 == "", ]
mob$sub_region_1 <- mob$sub_region_2 <- NULL

# Get to long format:
library(reshape2)
mob <- melt(mob, id.vars=c("country_region_code", "country_region", "date"))
colnames(mob) <- c("iso2c", "country", "date", "type", "mobility")
mob <- mob[!is.na(mob$mobility) & !is.na(mob$country) & !is.na(mob$type), ]
# Get correct date format:
mob$date <- as.Date(mob$date)
mob$country[mob$country == "Myanmar (Burma)"] <- "Myanmar"
mob$country[mob$country == "Czechia"] <- "Czech Republic"
mob$country[mob$country == "Kyrgyzstan"] <- "Kyrgyz Republic"
mob$country[mob$country == "Slovakia"] <- "Slovak Republic"

da <- merge(da, mob, by = c("country", "date"))

# Load boix data:
boix <- read.csv("democracy-v3.0.csv")
boix$boix_democracy <- boix$democracy_femalesuffrage
boix <- boix[boix$year == 2015, ] # As previously, 2015 is the most recent year

# Get total population from WDI:
pop <- WDI(country = "all", indicator = c("population" = "SP.POP.TOTL"), start = 2015, extra = T)
pop <- pop[!is.na(pop$population), ]
pop$last_year <- ave(pop$year, pop$country, FUN = max)
pop <- pop[pop$year == pop$last_year, ]

library(countrycode)
da$ccode <- countrycode(da$iso3c, "iso3c", "cown")
da$ccode[da$country == "Bosnia and Herzegovina"] <- 346
da$ccode[da$country == "Serbia"] <- 342
da$ccode[da$country == "Vietnam"] <- 818

da <- merge(da, pop[, c("iso3c", "population", "income")], by = "iso3c", all.x = T)
da <- merge(da, boix[, c("year", "ccode", "boix_democracy")], by = "ccode", all.x = T)

da$country_mobility_type <- paste0(da$country, "_", da$type)

# Restrict to sample we can use:
da <- da[complete.cases(da[, c("mobility", "boix_democracy", "date", "country_mobility_type", "C6_Stay.at.home.requirements", "population", "cellphones")]), ]

# Exclude residential movement (we consider places were the policy caused reduction):
da <- da[da$type != "residential_percent_change_from_baseline", ]

# Function to summarize the data weighted by population
x_intervals <- function(dat){
  
  dat <- na.omit(dat)
  
  x <- dat[, 1]
  y <- dat[, 2]
  
  x <- x[!is.na(y)]
  y <- y[!is.na(y)]
  
  y <- round(y/10000, 0)
  y[y<1] <- 1
  
  x <- rep(x, y)
  
  x <- sort(x)
  N <- length(x)
  top_99 <- x[ceiling(0.995*N)]
  top_95 <- x[ceiling(0.975*N)]
  top_90 <- x[ceiling(0.95*N)]
  temp_mean <- mean(x, na.rm = T)
  bot_90 <- x[floor((1-0.95)*N)]
  bot_95 <- x[floor((1-0.975)*N)]
  bot_99 <- x[floor((1-0.995)*N)]
  
  return(c(
    "top_95" = as.numeric(top_95),
    "top_90" = as.numeric(top_90),
    "mean" = as.numeric(temp_mean),
    "bot_90" = as.numeric(bot_90),
    "bot_95" = as.numeric(bot_95)
  ))
}

# Function to calculate summary of movement changes if "C6. Stay at home requirements" are at the national level and equal to 2 or more, weighted by country population, for both democracies and non-democracies by movement category:
calc_movement_changes <- function(data = da){
  da = data
  for(i in unique(da$type)){
    obs_intervals <- data.frame(rbind(
      c(x_intervals(da[da$C6_Flag != 0 & 
                         da$C6_Stay.at.home.requirements >= 2 & 
                         da$boix_democracy  == 0 &
                         da$type %in% i, c("mobility", "population")]),
        type = "Non-Democracies"),
      c(x_intervals(da[da$C6_Flag != 0 & 
                         da$C6_Stay.at.home.requirements >= 2 & 
                         da$boix_democracy  == 1 &
                         da$type %in% i, c("mobility", "population")]), 
        type = "Democracies")))
    
    obs_intervals$category <- i 
    obs_intervals$description <- "Observed reduction in retail and recreation movement when asked to restrict travel from home to essential trips"
    
    if(i == unique(da$type)[1]){
      res <- obs_intervals
    } else {
      res <- rbind(res, obs_intervals)
    }
  }
  res <- data.frame(res)
  for(i in 1:5){
    res[, i] <- as.numeric(res[, i])
  }
  
  return(res)}

# Calculate for March
res_march <- calc_movement_changes(data = da[da$date >= as.Date("2020-03-01") 
                                             & da$date <= as.Date("2020-04-01"), ])
res_march$month <- "March"

# Calculate for April
res_april <- calc_movement_changes(data = da[da$date >= as.Date("2020-04-01") 
                                             & da$date <= as.Date("2020-05-01"), ])
res_april$month <- "April"

# Calculate for May
res_may <- calc_movement_changes(data = da[da$date >= as.Date("2020-05-01") 
                                           & da$date <= as.Date("2020-06-01"), ])
res_may$month <- "May"

res_by_month <- rbind(res_march,
                      res_april,
                      res_may)

ggplot(res_by_month, aes(x=month, y=mean, 
                         col = category, 
                         group = type,
                         linetype = type))+
  geom_line()+
  theme_minimal()+
  facet_grid(.~category)+
  theme(legend.title=element_blank(),
        strip.background = element_blank(), 
        strip.text = element_blank())+xlab("")+ylab("% Change in Movement")



