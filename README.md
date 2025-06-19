# Local.Politics
## A set of case studies using a mixture model to analyze the clustering structure of US local politics

This projects takes a simple question -- how are local political cultures constituted in the US? -- and explores them using a beta-binomial mixture model. The mixture model allows us to take aggregated vote totals for a set of communities (either counties, municipalities or voting districts) and a set of referendum questions and uncover through an unsupervised learning algorithm uncover a set of consistent voting blocs, patterns of  This permits two types of analysis: How are the clusters distributed among themselves? And, how do they relate to national-level politics? 

## Case studies: 

* San Francisco referendum data - City voting districts - ???
* Multnomah County (PDX) referendum data - Voting districts within several municipalities???
* King County referendum data - Voting districts within municipalities - ???
* Miami/Broward referendum data - Voting districts within municipalities - ???
* Maine referendum data - Municipalities - November ballots, 2008-2023, 64 questions across 423 municipalities
* Massachusetts referendum data - Municipalities - November ballots, ???-???.

## Model

The model was developed in the context of Maine's referendum data ([Arxiv paper]([https://pages.github.com/](https://arxiv.org/abs/2301.01677))) and is currently only suitable for referendum data. However, a similar model can be constructed that allows for candidate data as well. 
