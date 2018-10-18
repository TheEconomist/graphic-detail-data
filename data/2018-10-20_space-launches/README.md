# Space launches

These are the data behind the "space launches" article, [The space race is dominated by new competitors](https://economist.com/graphic-detail/2018/10/18/the-space-race-is-dominated-by-new-contenders).

Principal data came from the Jonathan McDowell's JSR Launch Vehicle Database, available online at http://www.planet4589.org/space/lvdb/index.html.

Data files can be downloaded and processed through the included R/Jupyter script, `Data processing.ipynb`.

## Data files

| File     | Description            | Source                             |
| -------- | ---------------------- | ---------------------------------- |
| agencies | Space launch providers | Jonathan McDowell; _The Economist_ |

## Codebook

### agencies

| variable           | definition              |
| ------------------ | ----------------------- |
| agency             | org phase code          |
| count              | number of launches      |
| ucode              | org Ucode               |
| state_code         | responsible state       |
| type               | type of org             |
| class              | class of org            |
| tstart             | org/phase founding date |
| tstop              | org/phase ending date   |
| short_name         | short name              |
| name               | full name               |
| location           | plain english location  |
| longitude          |                         |
| latitude           |                         |
| error              | uncertainty in long/lat |
| parent             | parent org              |
| short_english_name | english short name      |
| english_name       | english full name       |
| unicode_name       | unicode full name       |
| agency_type        | type of agency          |
