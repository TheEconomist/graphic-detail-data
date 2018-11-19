# War, democracy and wealth

This is the methodology for an article about warfare: [Which countries are most likely to fight wars?](https://www.economist.com/graphic-detail/2018/11/10/which-countries-are-most-likely-to-fight-wars)


## Source data

The data used for this analysis came from a variety of sources. They can be examined [here](source_data).

* Conflict data for the years 1900-88 came from the Peace Research Institute Oslo (PRIO), using the 2.0 version of the Battle Deaths Dataset. This is compatible with the Correlates of War project, and is available online at: https://www.prio.org/Data/Armed-Conflict/Battle-Deaths/Old-versions/The-Battle-Deaths-Dataset-version-20/

* Conflict data for the years 1989-2017 came from the Uppsala Conflict Data Program (UCDP), using the 18.1 version of the Georeferenced Event Dataset, which is available online at: http://ucdp.uu.se/downloads/

* Additional conflict data for the coalition forces in the Iraq and Afghanistan wars came from: http://icasualties.org/

* **NB**: all death tolls in the conflict data refer to soldiers or civilians who were killed in direct combat -- i.e. by weapons during a conflict that involved at least one state army. The death tolls exclude fatalities from starvation, disease, terrorism or democide.

* Data for countries' historical population and GDP per capita came from the 2018 version of the Maddison Project database: https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2018

* Data about countries' level of democracy came from the Polity IV dataset, which is available online at: http://www.systemicpeace.org/inscrdata.html. These scores range from -10 (totally autocratic) to +10 (totally democratic).

Codebooks for these datasets, where available, are included in their respective directories.


## Amendments to source data

Where possible, the source data have been left untouched. However, in some instances we have made small amendments to the data, in order to account for missing values or observations. These amendments are listed below.


### PRIO data

* Between 1900 and 1990, any data which originally referred to Russia have been changed to the Soviet Union, and any data which originally referred to Serbia have been changed to Yugoslavia. This is to create uniform geographical entities across that period.

* Some countries are listed as involved in large interstate conflicts, but with no death tolls provided at all. We have excluded these from the data. For countries that have no central death toll estimate, we have used the high estimate.

* In most [extrasystemic wars](https://www.pcr.uu.se/research/ucdp/definitions/#Extra-systemic_conflict), which are usually between colonial powers and occupied territories, the database contains no estimates of the (usually substantial) death tolls for the occupied territories. We have added some estimates to the data, by counting any deaths that are not attributed to the colonial power as belonging to the occupied territory.


### UCDP data

* Between 1900 and 1990, any data which originally referred to Russia have been changed to the Soviet Union, and any data which originally referred to Serbia have been changed to Yugoslavia. This is to create uniform geographical entities across that period.

* Because various recent wars in Syria have been excluded from the 18.1 version of the Georeferenced Event Dataset,  we have created a [separate spreadsheet](source_data/UCDP_conflict_data/UCDP_18.1_conflict_deaths_in_syria.csv), named `UCDP_18.1_conflict_deaths_in_syria.csv`. This contains annual death tolls in Syria, which we have derived from `UCDP_18.1_state_conflict_data.csv`.


### iCasualties data

* Because the UCDP database tends to attribute deaths from large military coalitions to a single, primary country, for the Iraq and Afghanistan wars we have created estimates of deaths for each coalition country from: http://icasualties.org/. These are stored in a [spreadsheet](source_data/icasualties_conflict_data/icasualties_conflict_deaths_in_iraq_and_afghanistan.csv) named `icasualties_conflict_deaths_in_iraq_and_afghanistan.csv`.


### Maddison data

* Because many countries do not have population or GDP per capita data going all the way back to 1900, we have created interpolations for large swathes of their history. These interpolations require benchmark figures for each country in 1900.

* We have generated these benchmarks using Maddison's global and regional averages, and have stored them in a [spreadsheet](source_data/maddison_economic_data/maddison_cleaned_regions.csv) named `maddison_cleaned_regions.csv`.

* Europe's historical benchmarks are derived from Maddison's figures for Eastern Europe (as most missing European observations are from this region). Asia's benchmarks come from Maddison's East Asia. The Middle East's benchmarks come from Maddison's Western Asia.

* Because the Middle East and Africa have no observations before 1950, we have estimated 1900 benchmarks for them. Since global GDP per capita and population were both approximately 60% smaller in 1900 than in 1950, both the Middle East and Africa have been given 1900 benchmarks that are 60% lower than their 1950 figures. 

* Because Maddison's data contain no figures for Eritrea, Somalia or Papua New Guinea, we have added estimates for those to `maddison_country_data.xlsx` using data from the World Bank.

* Maddison also makes no provision for the historical divisions of Germany (East and West), Vietnam (North and South) or Yemen (North and South). In years in which those countries were split in two, we have divided Maddison's population estimates as follows: 
   * Germany: 80% of population in the West, 20% in the East
   * Yemen: 80% of population in the North, 20% in the South
   * Vietnam: 55% of population in the North, 45% in the South. 
   * The same GDP per capita figures have been used for both halves of these countries. These estimates have been added to `maddison_country_data.xlsx`.
   
   
## Methodology

Our aim was to create a single dataframe that contained the following information for each country in each year since 1900:

* Population
* Wealth
* Level of democracy
* Deaths suffered in combat, including all interstate, civil and extrasystemic wars

We could then use this dataset to explore relationships between wealth, democracy and belligerence. 

These topics have been covered heavily in academic literature. One common approach has been to look at pairs of countries (or "dyads") in interstate wars, and to determine which variables make a dyad more likely to engage in conflict. For a seminal paper on this, see: [The Kantian Peace: The Pacific Benefits of Democracy, Interdependence, and International Organizations, 1885-1992](https://www.jstor.org/stable/25054099), by John R. Oneal and Bruce Russett. The authors find statistically significant evidence that high levels of democracy, trade and membership of international organisations reduce the risk that two countries will fight each other.

Our approach was more modest. We wanted to see whether the relationship between democracy and peace was strictly linear -- i.e. whether every step from autocracy to political freedom is associated with a decrease in hostility. We also wanted to examine the relationship between warfare and GDP per capita.

When looking at *where* wars have been fought since 1900, we noted that the bloodiest wars have shifted gradually from Europe and the Americas, to Asia, and then to the Middle East and Africa. So our hypothesis was that countries might become more militant as they gain a small amount of wealth and political competition. Some academic studies have indeed found a curved relationship between levels of democracy and the risk of civil war, such as: [Toward a Democratic Civil Peace? Democracy, Political Change, and Civil War, 1816-1992](https://www.jstor.org/stable/3117627), by Havard Hegre, Tanja Ellingsen, Scott Gates and Nils Petter Gleditsch.

We did not seek to explain exactly why middlingly democratic or developed countries might be more hostile, which could be grounds for further research with more variables. Our study was intended to be descriptive and speculative, rather than to identify a causal relationship. 


### Step 1:  calculate the overall annual death toll in each conflict

First we went through the PRIO and UCDP databases, tallying how many people overall were killed in each year of each conflict. As mentioned above, these death tolls only include people who were killed in direct combat, rather than through starvation, disease, terrorism or democide.

The [script](war_conflicts_script.ipynb) used to do this is named `war_conflicts_script.ipynb`. Its [output file](output_data/conflict_years_df.csv), named `conflict_years_df.csv`, contains the following variables:

| Variable             | Definition                                                               |
| ---------------------|--------------------------------------------------------------------------|
| year                 | Year in which deaths occurred                                            |
| start_year           | Year in which conflict started                                           |
| COW_id               | Unique ID for conflict from Correlates of War                            |
| UCDP_id              | Unique ID for conflict from UCDP                                         |
| conflict_type        | Always state-based, since all conflicts involve at least one state army  |
| state_conflict_type  | Interstate, extrasystemic, internal or internationalised internal        |
| conflict_name        | Name of conflict                                                         |
| side_a               | First belligerent                                                        |
| side_b               | Second belligerent                                                       |
| best_deaths          | Best estimate of annual death toll                                       |
| low_deaths           | Low estimate of annual death toll                                        |
| high_deaths          | High estimate of annual death toll                                       |
| country              | Country in which conflict occurred                                       |
| region               | Region in which conflict occurred                                        |


### Step 2:  calculate the annual death toll for each country in each conflict

Next we went through the PRIO and UCDP databases again, this time tallying how many deaths each country suffered overall in each conflict. Because we had already identified what share of a conflict's deaths happened in each year, we were now able to estimate what share of each country's deaths in a conflict happened in each year.

Because the UCDP database disaggregated deaths of civilians from those of soldiers, we attributed all civilian deaths to the country in which a conflict happened.

We also patched in data about recent wars in Syria from `UCDP_18.1_conflict_deaths_in_syria` and in Iraq and Afghanistan from `icasualties_conflict_deaths_in_iraq_and_afghanistan`.

The [script](war_country_years_script.ipynb) used to do this is named `war_country_years_script.ipynb`. Its [output file](output_data/country_conflict_years_df.csv), named `country_conflict_years_df.csv`, contains the following variables:

| Variable                  | Definition                                                               |
| --------------------------|--------------------------------------------------------------------------|
| participant_country       | Name of country                                                          |
| participant_country_id    | Country's [Gleditsch and Ward][gleditsch] number                         |
| participant_maddison_code | Three-letter code used to identify country in Maddison's data            |
| participant_region        | Country's region                                                         |
| participant_deaths        | Best estimate for a country's overall deaths in a conflict               |
| conflict_name             | Name of conflict                                                         |
| conflict_start_year       | Year in which conflict started                                           |
| conflict_end_year         | Year in which conflict ended                                             |
| COW_id                    | Unique ID for conflict from Correlates of War                            |
| UCDP_id                   | Unique ID for conflict from UCDP                                         |
| state_conflict_type       | Interstate, extrasystemic, internal or internationalised internal        |
| year                      | Year in which country's deaths occurred                                  |
| year_deaths_share         | Percentage of a country's deaths that occurred in this year              |
| year_deaths               | Number of deaths that a country suffered in this year                    |


### Step 3:  produce a dataframe of each country's deaths, population, wealth and democratic status in each year since 1900

Next we generated estimates for each country's GDP per capita and population in each year since 1900, using linear interpolations of Maddison's data. For countries that were missing historical observations, we used the regional benchmarks described above to provide estimates in 1900, which could then be used for the interpolations.

For data on each country's level of democracy, we used scores from the Polity IV dataset, which has observations for each country going back to 1800 or its date of independence. These scores range from -10 (totally autocratic) to +10 (totally democratic). For countries that had never previously received a Polity score -- i.e. those that had not yet gained independence -- we assigned a special -11 score, which generally indicates colonies.

We could then create a dataframe of each country's deaths in all conflicts in each year since 1900, and join population, wealth and democracy figures for each year to that dataframe.

The [script](war_maddison_and_polity_interpolation_script.ipynb) used to do this is named `war_maddison_and_polity_interpolation_script.ipynb`. Its [output file](output_data/maddison_and_polity_country_years_df.csv), named `maddison_and_polity_country_years_df.csv`, contains the following variables:

| Variable                           | Definition                                                               |
| -----------------------------------|--------------------------------------------------------------------------|
| maddison_code                      | Three-letter code used to identify country in Maddison's data            |
| country_name                       | Name of country                                                          |
| country_region                     | Country's region                                                         |
| year                               | Year to which data pertains                                              |
| population                         | Maddison's estimate of country's population                              |
| gdp_per_capita                     | Maddison's estimate of country's GDP per capita                          |
| interpolated_gdp_per_capita        | Our interpolated estimate of country's GDP per capita                    |
| interpolated_population            | Our interpolated estimate of country's population                        |
| country_year_conflict_deaths       | Number of deaths country suffered in this year                           |
| country_year_conflict_death_rate   | Number of deaths country suffered per capita                             |
| country_involved_in_conflict       | Dummy variable: 1 if country suffered at least 100 deaths                |
| country_democracy_scores           | Country's score on Polity scale                                          |


### Step 4:  examine relationships between democracy, wealth and warfare

Next we created logistic regressions to estimate the probability that a country would be involved in a conflict in any year, given its level of democracy or wealth. We defined "being involved in a conflict" as suffering at least 100 deaths in a year, though we also tried other thresholds (25 deaths and 1000 deaths) and found similar results.

For both wealth and democracy, we created third-order polynomial equations to predict the probability of fighting a war in a given year (e.g. `country_involved_in_conflict ~ wealth + wealth^2 + wealth^3`). For wealth we used the logarithm of GDP per capita with base 2.

Both wealth and democracy had statistically significant relationships with the probability that a country is involved in a conflict. However, the polynomial equations showed that there was a very notable spike in belligerence among countries in the middle of both the democratic and wealth spectrum, before a sharp drop among the richest and most democratic countries.

| Democracy vs chance of conflict                    | Wealth vs chance of conflict                              |
| ---------------------------------------------------|-----------------------------------------------------------|
| ![Image](charts/democracy_deaths_100.png?raw=true) | ![Image](charts/wealth_deaths_100.png?raw=true)           |
   
The third-order polynomial model fit for belligerence versus democracy (pseudo r-squared of 0.028) was better than the fit for belligerence versus wealth (pseudo r-squared of 0.015), suggesting that the relationship between war and regime type is closer than the one between war and economic development. It was possible to make a combined regression that included polynomials for democracy and wealth in which both variables were statistically significant. This suggests that rich democracies are more peaceful than middle-income ones.

The [script](war_regression_script.ipynb) used to do this is named `war_regression_script.ipynb`. Its [output file](output_data/regression_df.csv), named `regression_df.csv`, contains the following variables:

| Variable                                          | Definition                                                               |
| --------------------------------------------------|--------------------------------------------------------------------------|
| maddison_code                                     | Three-letter code used to identify country in Maddison's data            |
| country_name                                      | Name of country                                                          |
| country_region                                    | Country's region                                                         |
| year                                              | Year to which data pertains                                              |
| population                                        | Maddison's estimate of country's population                              |
| gdp_per_capita                                    | Maddison's estimate of country's GDP per capita                          |
| interpolated_gdp_per_capita                       | Our interpolated estimate of country's GDP per capita                    |
| interpolated_population                           | Our interpolated estimate of country's population                        |
| country_year_conflict_deaths                      | Number of deaths country suffered in this year                           |
| country_year_conflict_death_rate                  | Number of deaths country suffered per capita                             |
| country_involved_in_conflict                      | Dummy variable: 1 if country suffered at least 100 deaths                |
| country_democracy_scores                          | Country's score on Polity scale                                          |
| log2_interpolated_gdp_per_capita                  | Logarithm of our interpolated GDP per capita estimate, base 2            |
| log2_interpolated_gdp_per_capita_squared          | Logarithm of our interpolated GDP per capita estimate, base 2, squared   |
| log2_interpolated_gdp_per_capita_cubed            | Logarithm of our interpolated GDP per capita estimate, base 2, cubed     |
| first_order_gdp_predicted_conflict_rate           | Logistic regression of conflict rate, using wealth                       |
| second_order_gdp_predicted_conflict_rate          | Logistic regression, using wealth and wealth^2                           |
| third_order_gdp_predicted_conflict_rate           | Logistic regression, using wealth, wealth^2 and wealth^3                 |
| rescaled_country_democracy_scores                 | Polity scores, rescaled so that -10 = 0, +10 = 20                        |
| rescaled_country_democracy_scores_squared         | Polity scores, rescaled and squared so that -10 = 0, +10 = 400           |
| rescaled_country_democracy_scores_cubed           | Polity scores, rescaled and cubed so that -10 = 0, +10 = 8000            |
| first_order_democracy_predicted_conflict_rate     | Logistic regression of conflict rate, using rescaled democracy score     |
| second_order_democracy_predicted_conflict_rate    | Logistic regression, using democracy and democracy^2                     |
| third_order_democracy_predicted_conflict_rate     | Logistic regression, using democracy, democracy^2 and democracy^3        |
| combined_polynomial_predicted_conflict_rate       | Logistic regression, using polynomials for both wealth and democracy     |
   
   
## Robustness checks

We showed our working and findings to a few political scientists, who suggested some robustness checks that we could use to see how strong the observed relationships between belligerence, democracy and wealth were when we sliced up the data into various segments. Our results are below, and the [charts](charts) included in this repository. The spike in belligerence for partially democratic countries seems to exist in most of these segments, whereas the curved relationship between warfare and wealth seems to be less robust.


### Using different death thresholds to define conflict

| Democracy vs chance of conflict, 25 deaths a year               | Wealth vs chance of conflict, 25 deaths a year                 |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_deaths_25.png?raw=true)               | ![Image](charts/wealth_deaths_25.png?raw=true)                 |

| Democracy vs chance of conflict, 1000 deaths a year             | Wealth vs chance of conflict, 1000 deaths a year               |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_deaths_1000.png?raw=true)             | ![Image](charts/wealth_deaths_1000.png?raw=true)               |


### Using different types of conflict

| Democracy vs chance of conflict, interstate wars                | Wealth vs chance of conflict, interstate wars                  |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_conflicts_interstate.png?raw=true)    | ![Image](charts/wealth_conflicts_interstate.png?raw=true)      |

| Democracy vs chance of conflict, civil wars                     | Wealth vs chance of conflict, civil wars                       |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_conflicts_civil.png?raw=true)         | ![Image](charts/wealth_conflicts_civil.png?raw=true)           |


### Using different time periods

| Democracy vs chance of conflict, years pre-1989                 | Wealth vs chance of conflict, years pre-1989                   |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_years_pre_1989.png?raw=true)          | ![Image](charts/wealth_years_pre_1989.png?raw=true)            |

| Democracy vs chance of conflict, years post-1989                | Wealth vs chance of conflict, years post-1989                  |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_years_post_1989.png?raw=true)         | ![Image](charts/wealth_years_post_1989.png?raw=true)           |


### Using regions

| Democracy vs chance of conflict, Europe                         | Wealth vs chance of conflict, Europe                           |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_region_europe.png?raw=true)           | ![Image](charts/wealth_region_europe.png?raw=true)             |

| Democracy vs chance of conflict, Americas                       | Wealth vs chance of conflict, Americas                         |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_region_americas.png?raw=true)         | ![Image](charts/wealth_region_americas.png?raw=true)           |

| Democracy vs chance of conflict, Asia                           | Wealth vs chance of conflict, Asia                             |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_region_asia.png?raw=true)             | ![Image](charts/wealth_region_asia.png?raw=true)               |

| Democracy vs chance of conflict, Africa                         | Wealth vs chance of conflict, Africa                           |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_region_africa.png?raw=true)           | ![Image](charts/wealth_region_africa.png?raw=true)             |

| Democracy vs chance of conflict, Middle East                    | Wealth vs chance of conflict, Middle East                      |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_region_middle_east.png?raw=true)      | ![Image](charts/wealth_region_middle_east.png?raw=true)        |


### Using different components of the Polity democracy index

One problem with using the Polity democracy scores to assess civil wars is that the index contains components that explicitly account for "factionalism". These components could therefore be endogenously giving mid-spectrum scores to countries that have violent conflicts between opposing groups. In [The Effect of Political Regime on Civil War: Unpacking Anocracy]("https://www.jstor.org/stable/27638616"), James Vreeland notes problems with the "regulation of participation" (PARREG) and "competitiveness of participation" (PARCOMP) variables in Polity's index. 

Mr Vreeland suggests that other components in Polity's democracy index are more reliable for measuring democracy, such as "constraints on chief executive" (XCONST), "competitiveness of executive recruitment" (XRCOMP) and "openness of executive recruitment" (XROPEN): 

*"The above three measures, which deal with the recruitment and constraints of the chief executive, are reasonable variables to use when testing hypotheses about the relationship between political regime and civil war. None of them are explicitly defined by political violence or civil war."*

These three components of the index are themselves bundled into two measures in the Polity data: "executive recruitment" (EXREC) and "executive constraint" (EXCONST). When we plotted belligerence against EXREC, we still found evidence of a spike in conflicts among countries in the middle of the democracy scale; the relationship did not hold for EXCONST.

| Executive recruitment vs chance of conflict                     | Executive constraints vs chance of conflict                    |
| ----------------------------------------------------------------|----------------------------------------------------------------|
| ![Image](charts/democracy_polity_EXREC.png?raw=true)            | ![Image](charts/democracy_polity_EXCONST.png?raw=true)         |


### With thanks

Many thanks to the political scientists who read a summary of our methodology and findings, and suggested various robustness checks, further reading and ways to improve the analysis:

* John Oneal, University of Alabama
* Mike Poznansky, University of Pittsburgh
* Jessica Weeks, University of Wisconsin—Madison
* Nils Metternich, University College London

[gleditsch]: https://www.andybeger.com/states/reference/gwstates.html