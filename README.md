# Social Intervention Hack

_[Harry Rickards](http://rckrds.uk), Veselin Vankov ([Twitter](http://www.twitter.com/vesko_ski), [LinkedIn](http://uk.linkedin.com/in/veskoski))_

Analyse alcohol and drug data to predict the effect an intervention would have. In other words, if a commissioner is considering spending on a new intervention initiative, the app can predict the effects of that intervention. Technically, it does this using [Support Vector Machines](http://scikit-learn.org/stable/modules/svm.html) (see `svm_guide.pdf`).

**Very** messy code, as it was for a hackathon. Models currently untrained.

## Data

[Local Alcohol Profiles for England](http://www.lape.org.uk/data.html)
[NHS Reference Costs](https://www.gov.uk/government/collections/nhs-reference-costs)
[National Drug Treatment Monitoring System](https://www.gov.uk/government/collections/nhs-reference-costs) _(scraped)_

Specific data on previous interventions could have been used; it would have been good if that was available in a lot more granular format.
