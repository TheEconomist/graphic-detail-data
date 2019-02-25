# Opinion on Brexit

These are the data for the interactive Graphic detail chart on Brexit: [Hostility to the prime minister’s Brexit deal is one thing that unites Britain](https://www.economist.com/graphic-detail/2019/02/22/profiles-of-a-divided-country).

The data for which was also used in the print article, "A polarised electorate has little desire for the government's compromise" (https://www.economist.com/graphic-detail/2019/02/23/british-voters-are-unimpressed-by-theresa-mays-brexit-deal)

The "tern plot" (a triangular scatter chart) presents 2,500 individual profiles of the British electorate (representing 25% of the total). The profiles are generated from a statistical model built by *The Economist* using microdata from YouGov, a pollster, from the following survey question asked of 90,000 British adults between November 27th and December 9th 2018. 

*The UK is currently scheduled to leave the EU on 29 March 2019. UK and EU negotiators recently completed an agreement on the terms of the UK’s exit from the EU, but this proposed deal has yet to be confirmed by the UK House of Commons. From most preferred to least preferred, how would you rank the following three options?*  
**No Deal:** leave the EU without a withdrawal agreement.  
**Proposed Deal:** leave the EU under the terms of the negotiated agreement.  
**Remain:** stop the exit process and remain in the EU.  

tern_plot.R contains code to plot the data in a triangular scatter plot

brexit_profiles.csv contains data for 2,500 of those profiles. A description of the variables follows below:

### brexit_profiles.csv

| Variable        | Description                                                                                                      |
| --------------- | ---------------------------------------------------------------------------------------------------------------- | 
| sex             | female / male                                                                                                    | 
| age_bucket      | age grouped into five buckets                                                                                    |
| lgbtq           | sexuality. straight; other                                                                                       |
| inc_bucket      | total gross household income                                                                                     | 
| educ_n          | coded 1-5. 1 = no formal qualifications; 2 = secondary school; 3 = further educ; 4 = graduate; 5 = post-graduate | 
| region6         | region of GB, split six ways                                                                                     |
| tenure3         | housing tenure. own home outright; mortgaged home; rent                                                          |
| poli_int_bucket | political interest: low; middling; high                                                                          |
| ge15_5          | 2015 general election vote, split five ways                                                                      |
| ge17_5          | 2017 general election vote                                                                                       |
| pop             | population of group, rounded to nearest hundred                                                                  |
| pred_deal       | modelled probability of individual choosing "deal"                                                               |
| pred_no_deal    | modelled probability of individual choosing "no deal"                                                            |
| pred_remain     | modelled probability of individual choosing "remain"                                                             |

