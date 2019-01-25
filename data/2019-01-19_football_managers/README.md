# Football managers

This is the methodology for an article about football managers: [Managers in football matter much less than most fans think](https://www.economist.com/graphic-detail/2019/01/19/managers-in-football-matter-much-less-than-most-fans-think).

## Source data

The data used for this analysis came from a variety of sources. They can be examined [here](source_files).

- Data for fixtures in Europe's "big five" leagues (in England, Spain, Germany, Italy and France) came from [Football-data.co.uk](http://www.football-data.co.uk/data.php). We downloaded results for all matches in those leagues between August 1st 2004 and December 31st 2018, and compiled them into a single [spreadsheet](source_files/big_five_league_fixtures.csv), named `big_five_league_fixtures.csv`.

- Data for managers' tenures came from [Transfermarkt.co.uk](https://www.transfermarkt.co.uk/). We scraped the tenure dates for all managers at clubs that had appeared in the big five leagues between 2004 and 2018, using a Python script. We have not included the scraping script in this repository, but we have included two output files:
  - `TM_league_season_teams_df.csv`, which lists each team that played in each league in each season.
  - `TM_team_managers_df.csv`, which lists each manager that ever worked for any of these teams, including his start and end dates.

- Data for players' skill came from [FIFAindex.com](https://www.fifaindex.com/). This website keeps a record of player ratings between 2004 and 2019 in the FIFA video game series, which is produced by Electronic Arts. For our analysis we needed estimates of player ability that did not rely on their teams' results. FIFA's ratings were the only publicly available data that covered at least 10 years. A full description of their methodology is available [here](http://www.espnfc.co.uk/blog/espn-fc-united-blog/68/post/2959703/fifa-17-player-ratings-system-blends-advanced-stats-and-subjective-scouting). 

- We have not included the Python script that we used to scrape the FIFA ratings, but we have included two output files:
  - `FIFA_league_season_teams_df.csv`, which lists each team that played in each league in each season.
  - `FIFA_team_season_players_df.csv`, which lists each player employed by each team in each season, including his skill rating and positions.

## Methodology

Our aim was to measure how much impact managers have on their teams. To do so, we had to calculate how successful their teams ought to have been, given the skill of their players, and then determine which managers consistently achieved better results than expected. We could then explore how effectively a manager's past performance predicts his future impact. Because knockout tournaments involve clubs in other divisions, and because league matches make up the vast majority of a football team's fixture list, we limited our analysis to these games.

The calculations and modelling described below were conducted in two scripts: `fixtures_and_managers_joining_script.ipynb` and `manager_ratings_script.R`.


### Step 1: convert FIFA player ratings into match forecasts

- FIFA's player ratings use a combination of objective data (such as shots, passes and tackles) and subjective evaluations by 9,000 dedicated users. The worst players who regularly start matches for top-division clubs score about 65, whereas the likes of Lionel Messi and Cristiano Ronaldo can gain scores of up to 95.

- Though these numbers are far from perfect, a team's preseason ratings can be turned into very accurate forecasts for the season ahead. Across  the 15 seasons that we predicted in five leagues, the average error between a team's expected points and its actual tally was 7.7 points. (When we compared our forecasts to preseason betting markets for the last three English campaigns, as provided by [@OmarChaudhuri](https://twitter.com/OmarChaudhuri), we found that our average error of 8.5 points was not much worse than the wisdom of the crowds, which was 8.1 points.)

- To turn FIFA player ratings into team forecasts, we had to account for the fact that the ratings are not strictly linear. The gap in actual player skill is bigger between 90 and 85 than between 70 and 65. And ratings have become slightly lower over time.
  - First we divided players into three positional groups: goalkeepers, defenders (everyone who could play in a defensive position) and attackers (everyone else). 
  - Then for each FIFA edition we [z-scored](https://en.wikipedia.org/wiki/Standard_score) players in each position group, so that their ratings were denominated in standard deviations above or below the mean for that year. 
  - Then we optimised a function to find an exponent, which would transform the linear ratings so that higher z-scores were further exaggerated, choosing the exponent value that gave use the best match predictions.
  - Then for each positional group we added together a team's exponentiated z-scores, so that the team had a separate total for its first-choice goalkeeper, its five best defenders and seven best attackers. (We chose these squad numbers to best represent a club's first team, plus a couple of substitutes; we found that the predictive power of a team's results started to dwindle around the 14th and 15th player.)
  - We could then feed these exponentiated-z-score-sums for two opposing teams into a [multinomial logistic regression](https://en.wikipedia.org/wiki/Multinomial_logistic_regression), which calculated the effect that each positional group has on winning, drawing and losing matches. We created a separate regression for each league, because draws seemed to be more common in some countries than others.
  - The coefficients were similarly large for attackers and defenders, but very small for goalkeepers. This meant that goalkeepers were given very little weight in our modelling. (In fact, [analysis](https://www.economist.com/game-theory/2018/02/09/why-footballs-goalkeepers-are-cheap-and-unheralded) by the 21st Club, a football consultancy, suggests that the best goalkeepers would contribute about four points a season to an average club: still much lower than the best attackers, but much higher than our results here.)
  - The forecasts for each match are contained in a spreadsheet named `big_five_league_expected_points_manager_tenures_df.csv`, in columns called `home_expected_points` and `away_expected_points`.

![Image](charts/fifa_ratings_vs_points_added.png?raw=true)

- Once we had determined the relationship between a team's player ratings and the number of league points it won, we were able to calculate the impact of individual players.
  - For each player in each position group in each season, we measured how many points an average team in each league would improve (or worsen) if they hired this player. We then compared this impact to that of an average player from the same position group.
  - For example, if an average team (such as Celta Vigo) replaced an average starting-team attacker (such as Kevin Mirallas) with Lionel Messi, he would improve that team by roughly 9.2 points per season.
  - The player ratings in terms of points added per season are contained in a spreadsheet named `player_ratings_df.csv`.
- Finally, we checked whether our player-based forecasts were biased towards strong or weak teams. When we plotted actual vs expected points for each team in each season, we found no sign that our predictions were skewed in this way: top-of-the-league sides were just as likely to overperform as relegation contenders.
  - A dataframe containing the actual and expected points for each team in each season is contained in a spreadsheet named `team_season_performance_df.csv`.

![Image](charts/expected_vs_actual_points.png?raw=true)


### Step 2: use team forecasts to identify which managers overperform, and by how much

- Now that we had reliable forecasts of how successful teams ought to have been, we could identify which managers had consistently overachieved relative to the skill of their players.

- However, we found that there was only a very weak link between a manager's past performance and his future results. Among managers with multiple tenures of at least 15 games, we found that only 51% of those who had overachieved in any given tenure did so in their next job.

- To reflect this strong regression to the mean, we calculated how many games of league-average performance should be added to a manager's record when predicting his future impact. We optimised a function which showed that the best predictions came from adding 461 games of 0 overperformance to a manager's actual results.

- For a manager who had taken charge of one season of 38 games, this meant that 8% of his record would be carried over: 38 / (38 + 461) = 0.076. For a manager with ten seasons of 38 games, we would project 45% of his over-performance to be retained: 380 / (380 + 461) = 0.451.

![Image](charts/klopp.png?raw=true)

- We used the latest projections for each manager to produce our final table of manager ratings, measured in terms of points added to an average team per season. These are contained in a spreadsheet named `player_ratings_df.csv`.
