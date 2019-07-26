If everyone had voted, Hillary Clinton would probably be president
================

This readme details (some of) the data used to produce *The Economist*’s
graphic detail piece “The silent near-majority: If everyone had voted,
Hillary Clinton would probably be president” [published
on](https://www.economist.com/graphic-detail/2019/07/06/if-everyone-had-voted-hillary-clinton-would-probably-be-president)
July 7 2019. We do not release this code due to its proprietary nature,
but do provide methodological details in [a post on our Medium
blog](http://medium.economist.com/would-donald-trump-be-president-if-all-americans-actually-voted-95c4f960798).

## Chart data

The main image was generated using the included data file
`state_level_estimates_with_probs.csv`. See the following data
dictionary for a walk-through of different
variables:

### Data dictionary:

| variable                    | description                                                                                              |
| --------------------------- | -------------------------------------------------------------------------------------------------------- |
| `state_abb`                 | state abbreviation                                                                                       |
| `rep_2016_actual`           | Donald Trump’s actual two-party vote share in the state                                                  |
| `dem_2016_actual`           | Hillary Clinton’s actual vote share in the state                                                         |
| `dem_2016_pred`             | Our prediction of Hillary Clinton’s vote share under 2016 turnout                                        |
| `rep_2016_pred`             | Our prediction of Donald trump’s vote share under 2016 turnout                                           |
| `total_evs_2016`            | The state’s number of electoral votes in 2016                                                            |
| `dem_mandatory`             | Our prediction of Hillary Clinton’s vote share if everyone had voted in 2016                             |
| `rep_mandatory`             | Our prediction of Donald Trump’s vote share if everyone had voted in 2016                                |
| `winner_2016`               | A dummy variable indicating which party won in 2016                                                      |
| `dem_ev_2016`               | How many electoral votes Hillary Clinton actually won in 2016                                            |
| `dem_evs_2016pred`          | Our prediction of how many electoral votes Hillary Clinton would have won in 2016 under 2016 turnout     |
| `dem_evs_mandatory`         | Our prediction of how many electoral votes Hillary Clinton would have won in 2016 under mandatory voting |
| `dem_probability_mandatory` | Our predicted probability of Clinton winning the state under mandatory voting                            |
| `dem_probability_2016pred`  | Our predicted probability of Clinton winning the state under 2016 turnout                                |

### Template R analysis

``` r
# load libraries
library(tidyverse)
```

    ## Registered S3 methods overwritten by 'ggplot2':
    ##   method         from 
    ##   [.quosures     rlang
    ##   c.quosures     rlang
    ##   print.quosures rlang

    ## ── Attaching packages ───────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.1.1     ✔ purrr   0.3.2
    ## ✔ tibble  2.1.3     ✔ dplyr   0.8.1
    ## ✔ tidyr   0.8.3     ✔ stringr 1.4.0
    ## ✔ readr   1.3.1     ✔ forcats 0.4.0

    ## ── Conflicts ──────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
# import data
state_estimates <- read_csv('state_level_estimates_with_probs.csv')
```

    ## Parsed with column specification:
    ## cols(
    ##   state_abb = col_character(),
    ##   rep_2016_actual = col_double(),
    ##   dem_2016_actual = col_double(),
    ##   dem_2016_pred = col_double(),
    ##   rep_2016_pred = col_double(),
    ##   total_evs_2016 = col_double(),
    ##   dem_mandatory = col_double(),
    ##   rep_mandatory = col_double(),
    ##   winner_2016 = col_character(),
    ##   dem_ev_2016 = col_double(),
    ##   dem_evs_2016pred = col_double(),
    ##   dem_evs_mandatory = col_double(),
    ##   dem_probability_mandatory = col_double(),
    ##   dem_probability_2016pred = col_double()
    ## )

``` r
# take a look
head(state_estimates)
```

    ## # A tibble: 6 x 14
    ##   state_abb rep_2016_actual dem_2016_actual dem_2016_pred rep_2016_pred
    ##   <chr>               <dbl>           <dbl>         <dbl>         <dbl>
    ## 1 AK                  0.584           0.416         0.470         0.530
    ## 2 AL                  0.644           0.356         0.405         0.595
    ## 3 AR                  0.643           0.357         0.377         0.623
    ## 4 AZ                  0.519           0.481         0.480         0.520
    ## 5 CA                  0.339           0.661         0.646         0.354
    ## 6 CO                  0.473           0.527         0.549         0.451
    ## # … with 9 more variables: total_evs_2016 <dbl>, dem_mandatory <dbl>,
    ## #   rep_mandatory <dbl>, winner_2016 <chr>, dem_ev_2016 <dbl>,
    ## #   dem_evs_2016pred <dbl>, dem_evs_mandatory <dbl>,
    ## #   dem_probability_mandatory <dbl>, dem_probability_2016pred <dbl>

## Underlying data

The state-level estimates were generated from a much more fine-grained
dataset of predicted voting behaviour for more than 29,000 different
demographic groups in the US. These estimates are included in the
`targets_with_turnout_and_predictions.csv` file and the variables are
detailed
below:

### Data dictionary:

| variable                 | description                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------ |
| `state`                  | An index for which state the group is in                                             |
| `sex`                    | The sex of the group                                                                 |
| `age`                    | The age of the group                                                                 |
| `race`                   | The race of the group                                                                |
| `edu`                    | The educational attainment of the group                                              |
| `inc`                    | The income category of the group                                                     |
| `voter_validated`        | Whether or not the group voted in the 2016 election                                  |
| `n`                      | The predicted number of people in the group                                          |
| `state_name`             | The name of the state                                                                |
| `ICPSRCode`              | The ICPSR code for the state                                                         |
| `state_abb`              | The state’s abbreviation                                                             |
| `region`                 | The region the group is in                                                           |
| `region_7`               | An expanded region variable                                                          |
| `abb`                    | Another state abbreviation (oops\!)                                                  |
| `cell_pred_trump_vote`   | The share of the group we predict would vote for Donald Trump                        |
| `cell_pred_clinton_vote` | The share of the group we predict would vote for Hillary Clinton                     |
| `state_clinton`          | The share of state in which the group resides that voted for Hillary Clinton in 2016 |
| `state_trump`            | The share of state in which the group resides that voted for Donald Trump in 2016    |
| `state_clinton_margin`   | Hillary Clinton’s vote margin in the state in which the group resides                |
| `state_median_income`    | The median income of the state in which the voter resides                            |
| `state_white_protestant` | The share of the state in which the voter lives that is white and protestant         |
| `state_black_pct`        | The share of the state in which the voter lives that is African American             |
| `state_hispanic_pct`     | The share of the state in which the voter lives that is Hispanic                     |
| `state_obama`            | The share of state in which the group resides that voted for Barack Obama in 2012    |
| `state_romney`           | The share of state in which the group resides that voted for Mitt Romney in 2012     |
| `state_vap_turnout_2012` | The share of state in which the group resides that voted in the 2012 election        |
| `state_vap_turnout_2016` | The share of state in which the group resides that voted in the 2016 election        |

### Template R analysis

``` r
# load libraries
library(tidyverse)

# import data
underlying_data <- read_csv('targets_with_turnout_and_predictions.csv')
```

    ## Parsed with column specification:
    ## cols(
    ##   .default = col_double(),
    ##   sex = col_character(),
    ##   age = col_character(),
    ##   race = col_character(),
    ##   edu = col_character(),
    ##   inc = col_character(),
    ##   voter_validated = col_character(),
    ##   state_name = col_character(),
    ##   state_abb = col_character(),
    ##   region = col_character(),
    ##   region_7 = col_character(),
    ##   abb = col_character()
    ## )

    ## See spec(...) for full column specifications.

``` r
# take a look
head(underlying_data)
```

    ## # A tibble: 6 x 27
    ##   state sex   age   race  edu   inc   voter_validated     n state_name
    ##   <dbl> <chr> <chr> <chr> <chr> <chr> <chr>           <dbl> <chr>     
    ## 1     1 Fema… 18-29 Blac… Coll… 0-20k N               2782. Alabama   
    ## 2     1 Fema… 18-29 Blac… Coll… 0-20k Y               2043. Alabama   
    ## 3     1 Fema… 18-29 Blac… Coll… 20-4… N               2155. Alabama   
    ## 4     1 Fema… 18-29 Blac… Coll… 20-4… Y               1583. Alabama   
    ## 5     1 Fema… 18-29 Blac… Coll… 40-8… N                819. Alabama   
    ## 6     1 Fema… 18-29 Blac… Coll… 40-8… Y                601. Alabama   
    ## # … with 18 more variables: ICPSRCode <dbl>, state_abb <chr>,
    ## #   region <chr>, region_7 <chr>, abb <chr>, cell_pred_trump_vote <dbl>,
    ## #   cell_pred_clinton_vote <dbl>, state_clinton <dbl>, state_trump <dbl>,
    ## #   state_clinton_margin <dbl>, state_median_income <dbl>,
    ## #   state_white_protestant <dbl>, state_black_pct <dbl>,
    ## #   state_hispanic_pct <dbl>, state_obama <dbl>, state_romney <dbl>,
    ## #   state_vap_turnout_2012 <dbl>, state_vap_turnout_2016 <dbl>
