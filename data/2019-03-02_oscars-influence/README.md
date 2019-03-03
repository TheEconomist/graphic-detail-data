# The Oscars’ influence has waned

These are the data for [The Oscars’ influence has waned][print story], published in the March 2nd issue of _The Economist_.

This chart uses film references in subsequent films, TV shows, video games and music videos as a proxy for a film’s influence. The references come from IMDb (which calls them “movie connections”) and are crowdsourced. For example, when Niles said "Of all the coffee joints in all the towns in all the world..." in an episode of *Frasier*, someone added this to the [*Casablanca* connections page](https://www.imdb.com/title/tt0034583/movieconnections?ref_=tt_ql_trv_6) and that counts as one reference for *Casablanca*. In addition to quotes, the dataset includes [camera techniques](https://www.youtube.com/watch?v=q9ZWxOBV7oI), visual references like film posters or memorabilia, music (parodies of the [scary strings from *Psycho*](https://www.youtube.com/watch?v=ymt7khg7r8s) crop up a lot), mentions, homages, actual clips of the film and spoofs.

We calculated the number of these references for each film in a given year as a percentage of all references to all films made in that year (stored as `count` and `annual_share` in our data file). For example, there are 3,291 references to *The Wizard of Oz*, and the 293 other films from 1939 with at least one reference have a total of 6,537 references, so *The Wizard of Oz* has 50.3% of all possible references. We then took the top 100 for each year and ranked them from largest to smallest on the chart. While this does not allow us to compare films across years (a film from 1965 has had 50 extra years to generate influences compared to a film from 2015, something we dubbed the “recency problem”), it does let us see which films generated the most references in a given year and compare them.

The list of movie references (`movie-links.list.gz`) is a frozen dataset from the end of 2017 available [here](ftp.fu-berlin.de/pub/misc/movies/database/frozendata/). It contains references going back to *L'arrivée d'un train à La Ciotat* (1896), and although it contains many films from 2017, releases from the end of that year are largely absent. Best Picture winner *The Shape of Water* was released on 22nd December 2017 for example and didn’t feature in the dataset. For this reason, we decided to only go up to the end of 2016.

As is customary with any dataset, the dates were a nightmare. For the first six years of the Oscars, the Academy accepted films that spanned two calendar years (from August in one year to July in the next). So *Wings*, the first Best Picture winner (or Outstanding Picture as it was known at the time), was released in 1927 but appears in the 1928 row on the chart (and actually received its award at a ceremony in 1929, just to add to the confusion). As well as compressing comparable films from two calendar years into one release year (we call this the `oscars_year` in the data file), we decided not to exclude the handful of films from the early years that weren’t technically eligible for the Best Picture Oscar like *Metropolis* (for being foreign) and *Steamboat Willie* (for being animated) as they help orient the reader. Also, somehow the latter incorrectly usurped the eye-opening surrealist film *Un Chien Andalou* as the most-referenced film of 1929 (lo siento señor Buñuel). Finally, we added a W to the `result` column if a film won the Best Picture Oscar, or an N if it was nominated.

There were many caveats about using this dataset. Anything crowdsourced is prone to error, and many of the more recent mentions on TV shows are just actors promoting their films on chat shows rather than more meaningful references like quotes or parodies. The list is now out of date (people are adding references all the time), and non-Western films are under-represented. It’s also important to note that lots of references doesn’t necessarily equate with quality (I'm looking at you, [*Manos: The Hands of Fate*](https://www.imdb.com/title/tt0060666/?ref_=nv_sr_1)).

The inspiration for this chart was a fascinating paper released at the end of 2018 by Dr Livio Bioglio and Ruggero G. Pensa at the University of Turin called [“Identification of key films and personalities in the history of cinema from a Western perspective”](https://appliednetsci.springeropen.com/articles/10.1007/s41109-018-0105-0). They created a connection network from the same dataset (having first excluded everything except film-to-film references) and generated an influence score for every film. Although they chose not to control for the recency problem, the top of their ranking does feature all the usual suspects.

## Data

Raw data are available at the [FTP site](ftp.fu-berlin.de/pub/misc/movies/database/frozendata/) mentioned above. Our count of the mentions for each movie is included in `movie-counts.csv`. All data are originally from IMDb.

| variable       | description                                                                                    |
| -------------- | ---------------------------------------------------------------------------------------------- |
| `movie_name`   | The name of the movie                                                                          |
| `release_year` | The year the movie was released                                                                |
| `oscars_year`  | The year the movie would have qualified for an Oscar\*                                         |
| `ceremony`     | The Oscars ceremony this film was nominated in (empty if not nominated for Best Picture)       |
| `result`       | `N` if nominated for Best Picture, `W` if Best Picture winner                                  |
| `count`        | number of mentions. Mentions are connections of 'referenced in', 'spoofed in' or 'featured in' |
| `overall_rank` | rank among all movies (by number of mentions)                                                  |
| `year_rank`    | rank among movies eligible for the Oscars in the same year                                     |
| `annual_share` | this movie’s share of mentions among all movies eligible in the same year                      |

\* This has historically been the year in which the movie first showed in a theatre in Los Angeles for a particular length of time. For example, *Casablanca* showed in New York in late 1942, but Los Angeles only in early 1943; it was judged (and won) among pictures released in 1943. We have adjusted for this as best we could using IMDb’s release data, also available at the [ftp site][ftpsite] in `release-dates.list.gz`, but ignored it in extreme cases (for example, *Godzilla* or *Gojira* as it is called in the original dataset was not released in US theatres until its 50th anniversary, so we counted its original Japanese release).

[print story]: https://www.economist.com/graphic-detail/2019/03/02/the-oscars-influence-has-waned
[ftpsite]: ftp://ftp.fu-berlin.de/pub/misc/movies/database/frozendata/
