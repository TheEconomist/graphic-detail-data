# Housekeeping
lapply(c('data.table', 'nnet', 'lubridate', 'doParallel'), require, character.only = TRUE)

workers <- makeCluster(detectCores() - 1, outfile = '')
registerDoParallel(workers)
setwd('/Users/jamestozer/Dropbox/Coding scripts/Backpage/Football managers/output_files/')

set.seed(123)
options(scipen = 999)
ReplacementLevelStdevs <- -3 # Z-score of a replacement player

# Load matches
matches <- (fread('big_five_league_expected_points_manager_tenures_df.csv'))[,
  .(league_country, date, home_team, home_FIFA_team_id, home_TM_team_id, away_team,
  away_FIFA_team_id, result, season, home_TM_manager_name, away_TM_manager_name)]

TeamIDLookup <- unique(matches[, .(home_FIFA_team_id, home_TM_team_id)])

names(TeamIDLookup) <- gsub('home_', '', names(TeamIDLookup))

matches[, date := as.Date(date)
  ][result == '', result := NA_character_
  ][, result := as.factor(result)
  ][, result := relevel(result, ref = 'D')]

# Load players
players <- fread('FIFA_team_season_players_df.csv')

players[, season := as.integer(paste0('20', substr(FIFA_edition, 6, 7)))
  ][, PosGroup := ifelse(FIFA_player_DF == 1, 'defence', ifelse(FIFA_player_GK == 1,
    'goalkeeper', ifelse(FIFA_player_MF == 1 | FIFA_player_AT == 1, 'attack',
    NA_character_)))] # Separate into attackers, defenders, and goalies

setorder(players, -FIFA_player_rating)

# Rank each player on his team at his position
players[, TeamPosRank := 1:.N, by = c('FIFA_team_name', 'season', 'PosGroup') 
  ][, Include := ifelse((PosGroup == 'attack' & TeamPosRank < 8) | (PosGroup == 'defence' &
    TeamPosRank < 6) | (PosGroup == 'goalkeeper' & TeamPosRank == 1), TRUE, FALSE)]

# Only use top 7 attackers, 5 defenders, and goalie for each team
players <- players[Include == TRUE]

players[, ZScore := (FIFA_player_rating - (mean(FIFA_player_rating))) /
  (sd(FIFA_player_rating)), by = c('season', 'PosGroup')]

# This function calculates the sum of the exponentiated z-scores above replacement
# for each position group on each team in each year
popplayers <- function(exponent, tempplayers) {
  tempplayers[, ExponentialZScoreAboveReplacement := ifelse(ZScore < ReplacementLevelStdevs, 0, # Cap negative z-scores at -3
    (ZScore - ReplacementLevelStdevs)^exponent)] # Fit z-scores above replacement to a curve, so superstars are worth more
  for (pos in unique(tempplayers$PosGroup)) { # Sum adjusted z-scores above replacement for all of a team's starters
    tempplayers[PosGroup == pos, (paste0('Team', pos, 'ZScoreSum')) :=
      sum(ExponentialZScoreAboveReplacement), by = c('season', 'FIFA_team_id')
      ][, (paste0('Team', pos, 'ZScoreSum')) := ifelse(is.na(get(paste0('Team',
        pos, 'ZScoreSum'))), mean(get(paste0('Team', pos, 'ZScoreSum')),
        na.rm = TRUE), get(paste0('Team', pos, 'ZScoreSum'))), by = c('season',
        'FIFA_team_id')]
  }
  return(tempplayers)
}

# This function projects the probabilities of each match result given player z-scores
proj <- function(exponent, tempplayers, tempmatches) {
  for (var in c('tempplayers', 'tempmatches')) assign(var, as.data.table(get(var)))
  tempplayers <- popplayers(exponent, tempplayers)
  for (side in c('home', 'away')) { # Merge sum of team exponentiated z-scores onto match results
    temp <- unique(tempplayers[, c('season', 'FIFA_team_id', paste0('Team',
      unique(tempplayers$PosGroup), 'ZScoreSum')), with = FALSE])
    names(temp)[2:5] <- paste0(side, '_', names(temp)[2:5])  
    tempmatches <- merge(tempmatches, temp, by = c('season', paste0(side, '_FIFA_team_id')),
      all.x = TRUE)
  }
  for (country in unique(tempmatches$league_country)) {
    assign(paste0(country, 'Mod'),  multinom(result ~ home_TeamattackZScoreSum + # Fit multinomial logit model for each country to win/lose/draw
      home_TeamgoalkeeperZScoreSum + home_TeamdefenceZScoreSum +
      away_TeamattackZScoreSum + away_TeamgoalkeeperZScoreSum + away_TeamdefenceZScoreSum,
      tempmatches[league_country == country]), envir = .GlobalEnv)
    tempmatches[country == league_country, (c('DrawProb', 'AwayWinProb', 'HomeWinProb')) := # Predict player-based win probabilities
      as.data.table(predict(get(paste0(country, 'Mod')), .SD, type = 'probs'))]
  }
  return(tempmatches)
}

# This function calculates the average error of the match projections across the five leagues
loss <- function(logexponent) {
  exponent <- exp(logexponent)
  tempmatches <- proj(exponent, players, matches[!is.na(result)])
  return(mean(c(EnglandMod$deviance/(nrow(tempmatches[league_country == 'England'])), # Calculate average error of multinomial models across 5 top leagues
    FranceMod$deviance/(nrow(tempmatches[league_country == 'France'])),                
    GermanyMod$deviance/(nrow(tempmatches[league_country == 'Germany'])),
    ItalyMod$deviance/(nrow(tempmatches[league_country == 'Italy'])),
    SpainMod$deviance/(nrow(tempmatches[league_country == 'Spain'])))))
}

# Find exponent to apply to player z-scores above replacement that yields best fit
PlayerExponent <- optimize(loss, c(-10, 10)) 

# Use exponent to generate player ratings, and then use those to forecast match results
players <- popplayers(exp(PlayerExponent$minimum), players)

matches <- proj(exp(PlayerExponent$minimum), players, matches)

# Assign expected points values to each match based on result forecasts
matches[, HomeExpectedPoints := DrawProb + (3 * HomeWinProb)
  ][, AwayExpectedPoints := DrawProb + (3 * AwayWinProb)
  ][, AvgHomeExpectedPoints := mean(HomeExpectedPoints), by = c('season',
    'home_FIFA_team_id')
  ][, AvgAwayExpectedPoints := mean(AwayExpectedPoints), by = c('season',
    'away_FIFA_team_id')]

# Generate dataframe of team strengths, based on expected points per season
teamstrength <- unique(matches[, .(season, league_country, home_FIFA_team_id,
  AvgHomeExpectedPoints)])

setnames(teamstrength, 'home_FIFA_team_id', 'away_FIFA_team_id')

teamstrength <- merge(teamstrength, unique(matches[, .(season, away_FIFA_team_id,
  AvgAwayExpectedPoints)]), by = c('season', 'away_FIFA_team_id'), all.x = TRUE)

teamstrength[, ExpectedPtsPer38 := 19 * (AvgHomeExpectedPoints +
  AvgAwayExpectedPoints)] # calculate expected points per team-season

setorder(teamstrength, season, league_country, -ExpectedPtsPer38)

teamstrength[, ExpectedPtsRank := 1:.N, by = c('season', 'league_country')]

setnames(teamstrength, 'away_FIFA_team_id', 'FIFA_team_id')

# Identify the average team in each league
AvgTeams <- teamstrength[ExpectedPtsRank == 10] 

setorder(players, PosGroup, -ExponentialZScoreAboveReplacement)

# Calculates how many points per season a player would add to an average team
CalcPlayerImpact <- function(i, dat) { 
  impacts <- data.table(country = unique(matches$league_country), impact = NA_real_)
  for (countrynum in 1:(nrow(impacts))) {
    AvgTeamID <- AvgTeams[season == dat$season[i] & league_country == impacts$country[countrynum]]$FIFA_team_id
    tempmatches <- matches[season == dat$season[i] & league_country == impacts$country[countrynum] &
      ((home_FIFA_team_id == AvgTeamID) | ((away_FIFA_team_id == AvgTeamID)))]
    tempmatches[home_FIFA_team_id == AvgTeamID, (paste0('home_Team', dat$PosGroup[i],
      'ZScoreSum')) := (get(paste0('home_Team', dat$PosGroup[i], 'ZScoreSum'))) +
      dat$ExponentialZScoreAboveReplacement[i] - ((-ReplacementLevelStdevs)^(exp(PlayerExponent$minimum)))
      ][away_FIFA_team_id == AvgTeamID, (paste0('away_Team', dat$PosGroup[i],
        'ZScoreSum')) := (get(paste0('away_Team', dat$PosGroup[i], 'ZScoreSum'))) +
        dat$ExponentialZScoreAboveReplacement[i] - ((-ReplacementLevelStdevs)^(exp(PlayerExponent$minimum)))
      ][, (c('DrawProb', 'AwayWinProb', 'HomeWinProb')) :=
        as.data.table(predict(get(paste0(impacts$country[countrynum], 'Mod')), .SD,
        type = 'probs'))
      ][, NewHomeExpectedPoints := DrawProb + (3 * HomeWinProb)
      ][, NewAwayExpectedPoints := DrawProb + (3 * AwayWinProb)]
    impacts$impact[countrynum] <- (((mean(tempmatches[home_FIFA_team_id == AvgTeamID]$NewHomeExpectedPoints)) +
      (mean(tempmatches[away_FIFA_team_id == AvgTeamID]$NewAwayExpectedPoints))) * 19) -
      AvgTeams[season == dat$season[i] & FIFA_team_id == AvgTeamID]$ExpectedPtsPer38
  }
  return(data.table(Index = i, PointsAboveAverage = mean(impacts$impact)))
}

# For each player in 2019, calculate their contribution to an average team
players[, Index := .I]

system.time(PlayerImpacts <- foreach(i = players[season ==  2019]$Index,
  .packages = c('data.table', 'nnet'), .combine = rbind,
  .export = paste0(unique(matches$league_country), 'Mod')) %dopar% CalcPlayerImpact(i,
  dat = players))

players <- merge(players, PlayerImpacts, by = 'Index', all.x = TRUE)

setorder(players, -PointsAboveAverage)

# Calculate difference between actual and expected points per game
matches[, ActualHomePts := ifelse(result == 'H', 3L, ifelse(result == 'D', 1L, 0L))
  ][, ActualAwayPts := ifelse(result == 'A', 3L, ifelse(result == 'D', 1L, 0L))
  ][, HomePtsAboveExpectation := ActualHomePts - HomeExpectedPoints
  ][, AwayPtsAboveExpectation := ActualAwayPts - AwayExpectedPoints
  ][, (paste0(c('home_', 'away_'), 'TenureWithTeam')) := NA_integer_]

# Import dataframe of manager tenures, by date
ManagerDates <- merge((fread('manager_all_tenures_performance_df.csv'))[,
  .(TM_manager_name, TM_manager_start_date, TM_manager_end_date, TM_team_id)],
  TeamIDLookup, by = 'TM_team_id', all.x = TRUE)

for (var in c('start', 'end')) ManagerDates[, (paste0('TM_manager_', var, '_date')):=
  as.Date(get(paste0('TM_manager_', var, '_date')))]

setorder(ManagerDates, TM_manager_name, TM_manager_start_date)

ManagerDates[, TenureWithTeam := 1:.N, by = c('TM_manager_name', 'FIFA_team_id')
  ][, TM_team_id := NULL]

vars <- c('TM_manager_name', 'TM_manager_start_date', 'TenureWithTeam',
  'FIFA_team_id')

# For managers who return to a club, determine which tenure a match belongs to
for (side in c('home_', 'away_')) {
  for (i in (max(ManagerDates$TenureWithTeam)):2) {
    setnames(ManagerDates, vars, paste0(side, vars))
    setnames(ManagerDates, paste0(side, 'TenureWithTeam'), paste0('Temp', side,
      'TenureWithTeam'))
    matches <- merge(matches, ManagerDates[(get(paste0('Temp', side,
      'TenureWithTeam'))) == i, -'TM_manager_end_date', with = FALSE],
      by = paste0(side, c('TM_manager_name', 'FIFA_team_id')), all.x = TRUE)
    matches[date >= (get(paste0(side, 'TM_manager_start_date'))) & is.na(get(paste0(side,
      'TenureWithTeam'))), (paste0(side, 'TenureWithTeam')) := get(paste0('Temp',
      side, 'TenureWithTeam'))
      ][, (c(paste0(side, 'TM_manager_start_date'), paste0('Temp', side,
        'TenureWithTeam'))) := NULL]
    setnames(ManagerDates, paste0('Temp', side, 'TenureWithTeam'),
      paste0(side, 'TenureWithTeam'))
    setnames(ManagerDates, paste0(side, vars), vars)
  }
  matches[is.na(get(paste0(side, 'TenureWithTeam'))), (paste0(side,
    'TenureWithTeam')) := 1L]
}

setorder(matches, date)

# Export dataframe of expected points for each match in the five leagues
fwrite(matches, 'expected_points_df.csv')

# Create a dataframe of manager tenures, to add in their expected point totals
TeamNameLookup <- unique(matches[, .(home_FIFA_team_id, home_team)])

names(TeamNameLookup) <- c('FIFA_team_id', 'Team')

vars <- c('TM_manager_name', 'FIFA_team_id', 'TenureWithTeam')

# Merge in data for both home and away matches
managers <- matches[!is.na(result), .(HomePtsAboveExpectation = sum(HomePtsAboveExpectation),
  HomeMatches = nrow(.SD)), by = eval(paste0('home_', vars))]

setnames(managers, paste0('home_', vars), paste0('away_', vars))

managers <- merge(managers, matches[!is.na(result),
  .(AwayPtsAboveExpectation = sum(AwayPtsAboveExpectation),
  AwayMatches = nrow(.SD)), by = eval(paste0('away_', vars))],
  by = paste0('away_', vars), all.x = TRUE)

setnames(managers, paste0('away_', vars), vars)

managers[is.na(managers)] <- 0

managers <- managers[TM_manager_name != '']

# Sum the home and away points above expectation for each manager tenure
managers[, NextTenurePtsAboveExpectation := HomePtsAboveExpectation + AwayPtsAboveExpectation
  ][, NextTenureMatches := HomeMatches + AwayMatches]

managers <- merge(managers, ManagerDates, by = c('TM_manager_name',
  'FIFA_team_id', 'TenureWithTeam'), all.x = TRUE)

managers <- merge(managers[, .(TM_manager_name, FIFA_team_id, TenureWithTeam,
  NextTenureMatches, NextTenurePtsAboveExpectation, TM_manager_start_date,
  TM_manager_end_date)], TeamNameLookup, by = 'FIFA_team_id', all.x = TRUE)

setorder(managers, TM_manager_name, TM_manager_start_date)

# For each manager tenure, calculate the matches, points and expected points for the previous tenures
managers[, PastTenureMatches := ifelse(TM_manager_name == shift(TM_manager_name,
  1), shift(NextTenureMatches, 1), NA_integer_)
  ][, PastTenurePtsAboveExpectation := ifelse(TM_manager_name == shift(TM_manager_name,
    1), shift(NextTenurePtsAboveExpectation, 1), NA_real_)
  ][is.na(PastTenureMatches), (paste0('PastTenure', c('Matches',
    'PtsAboveExpectation'))) := 0]

# Re-centre points above expectation to a sum of 0
for (group in paste0(c('Past', 'Next'), 'Tenure')) managers[, (paste0('Adj',
  group, 'PtsAboveExpectation')) := (get(paste0(group, 'PtsAboveExpectation'))) -
  (((sum(get(paste0(group, 'PtsAboveExpectation')), na.rm = TRUE)) /
  (sum(get(paste0(group, 'Matches')), na.rm = TRUE))) *
  (get(paste0(group, 'Matches'))))]

# Add these adjusted points above expectation for all previous tenures to dataframe
managers[, AdjNextTenurePtsAboveExpectationPerGame := AdjNextTenurePtsAboveExpectation /
  NextTenureMatches
  ][, PrevCareerMatches := cumsum(PastTenureMatches), by = TM_manager_name
  ][, PrevCareerAdjPtsAboveExpectation := cumsum(AdjPastTenurePtsAboveExpectation),
    by = TM_manager_name]

# This function predicts future managerial outperformance based on historical results
proj <- function(par, dat) {
  dat <- as.data.table(dat)
  dat[, Proj := PrevCareerAdjPtsAboveExpectation / (PrevCareerMatches + par)] # Regresses manager performance to the mean, using a weighted average
  dat$Proj
}

# This function calculates the error of the above prediction
loss <- function(par, dat) {
  dat[, Proj := proj(par, .SD)
    ][, ErrSq := (Proj - AdjNextTenurePtsAboveExpectationPerGame)^2]
  sqrt(weighted.mean(dat$ErrSq, dat$NextTenureMatches))
}

# Exclude managers with no previous tenures
traindat <- managers[PrevCareerMatches != 0]

# Optimize the loss function to get the weight for regressing managers to the mean
RegressionToMean <- optimize(loss, dat = traindat, interval = c(0, 10000))

# Add empty rows to the managers dataframe, which will be filled with current predictions of their impact
managers <- rbindlist(list(managers, data.table(TM_manager_name = unique(managers$TM_manager_name),
  TM_manager_start_date = Sys.Date())), use.names = TRUE, fill = TRUE)

setorder(managers, TM_manager_name, TM_manager_start_date)

# Calculate projections for all manager tenures, and then filter for the latest tenure
managers[, PrevCareerMatches := ifelse(is.na(PrevCareerMatches) &
  TM_manager_name == (shift(TM_manager_name, 1)), (shift(PrevCareerMatches, 1)) +
  (shift(NextTenureMatches, 1)), PrevCareerMatches)
  ][is.na(NextTenureMatches), (c('NextTenureMatches',
    'AdjNextTenurePtsAboveExpectationPerGame')) := 0
  ][, PrevCareerAdjPtsAboveExpectation := ifelse(is.na(PrevCareerAdjPtsAboveExpectation) &
    TM_manager_name == (shift(TM_manager_name, 1)), (shift(PrevCareerAdjPtsAboveExpectation, 1)) +
    (shift(AdjNextTenurePtsAboveExpectation, 1)) - ((shift(NextTenureMatches, 1)) *
    (((sum(PastTenurePtsAboveExpectation, na.rm = TRUE)) / (sum(PastTenureMatches, na.rm = TRUE))) - 
       ((sum(NextTenurePtsAboveExpectation, na.rm = TRUE)) / (sum(NextTenureMatches, na.rm = TRUE))))), PrevCareerAdjPtsAboveExpectation)
  ][, Proj := proj(RegressionToMean$minimum, .SD)
  ][, PrevCareerAdjPtsAboveExpectationPerGame := PrevCareerAdjPtsAboveExpectation /PrevCareerMatches
  ][, ProjPointsAboveAverage := Proj * 38
  ][, IsActive := ifelse(is.na(FIFA_team_id) & ((shift(TM_manager_end_date, 1)) == '2019-07-01'), TRUE, FALSE)
  ][, CurrentTeam := ifelse(IsActive, shift(Team, 1), NA_character_)]

setorder(managers, -Proj)

# Export rankings of managers
managersout <- managers[is.na(FIFA_team_id) & !is.na(Proj),
  .(TM_manager_name, CurrentTeam, PrevCareerMatches,
    PrevCareerAdjPtsAboveExpectation, ProjPointsAboveAverage)]

fwrite(managersout, 'manager_ratings_df.csv')

# Export rankings of players
playersout <- players[!is.na(PointsAboveAverage), .(FIFA_player_name, FIFA_player_rating, PosGroup, PointsAboveAverage)]

fwrite(playersout, 'player_ratings_df.csv')

# Test the accuracy of the player-based result projections, for each team season
ModelAccuracy <- matches[, .(HomeExpectedPoints = sum(HomeExpectedPoints),
  ActualHomePts = sum(ActualHomePts)), by = c('home_team', 'season')]

names(ModelAccuracy)[1] <- 'away_team'

ModelAccuracy <- merge(ModelAccuracy, matches[, .(AwayExpectedPoints = sum(AwayExpectedPoints),
  ActualAwayPts = sum(ActualAwayPts)), by = c('away_team', 'season')],
  by = c('away_team', 'season'), all.x = TRUE)

ModelAccuracy[, ExpectedPoints := HomeExpectedPoints + AwayExpectedPoints
  ][, ActualPoints := ActualHomePts + ActualAwayPts
  ][, Err := abs(ActualPoints - ExpectedPoints)
  ][, ErrSq := (ActualPoints - ExpectedPoints)^2]
sqrt(mean(ModelAccuracy$ErrSq))