# fdd-foxtail

![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white)

As a challenge submission to Gitcoin Open Data Science Hackathon, Foxtail is a method-based analysis into testing the relationship between on-chain data and the behaviors of potential Sybils.

 <img src="https://i.imgur.com/P5WKBbe.png" width="600"/>

# Table of Contents

- [Abstract](#abstract)
- [Variables](#variables)
- [Methodology](#methodology)
- [Discussion](#discussion)
- [Limitations](#limitations)
- [Contributing](#contributing)

# Abstract

How the blockchain proves advantageous in a real-world capacity is in its ability to instantaneously and permanently retain a traceable record of events. In this use case, Gitcoin seeks to protect the integrity of its grants approval and allocation process by ensuring a one person, one vote decision-making approach.

In an effort to do so, there is a constant initiative to prevent and mitigate illegitimate influx from sybils, while protecting legitimate transactions. Foxtail is a proof-of-concept that aims to do just that by modeling relevant blockchain activity as a social network graph to provide grant stakeholders with the necessary insights to make the right decisions.

# Variables

| Variable Name                   | Description                                                                                |
|---------------------------------|--------------------------------------------------------------------------------------------|
| address                         | (as provided)                                                                              |
| chain                           | (as provided)                                                                              |
| txn_hash                        | (as provided)                                                                              |
| amount_in_usdt                  | (as provided)                                                                              |
| timestamp                       | (as provided)                                                                              |
| has_lens                        | Boolean value of a Lens Protocol profile linked the wallet                                 |
| first_tx_hash                   | Transaction hash of the wallet's first transaction                                         |
| first_tx_timestamp              | Timestamp of the wallet's first transaction                                                |
| first_tx_from                   | Originating address of the wallet's first transaction                                      |
| first_tx_contractAddress        | Contract address if any that interacted with the wallet on its first transaction           |
| preceding_tx_from*               | Array of wallet addresses that deposited funds to the wallet in question prior to txn_hash |
| preceding_tx_contractAddresses*  | Array of contract addresses that the wallet in question interacted with prior to txn_hash  |
| succeeding_tx_to*                | Array of wallet addresses that received funds from the wallet in question after txn_hash   |
| succeeding_tx_contractAddresses* | Array of contract addresses that the wallet in question interacted with after txn_hash     |
| last_tx_timestamp*               | Timestamp of the wallet's last transaction                                                 |

<sub>*not reflected in current state, though already made accessible</sub>

# Methodology

1. As a springboard, data from `hackathon-contributions-dataset_v2.csv` is utilized. In the R code, it is hereby referred to as `data.csv`. This can be retrieved from https://drive.google.com/drive/folders/17OdrV7SA0I56aDMwqxB6jMwoY3tjSf5w.

For our purposes, the data is cleaned and subset into transactions made on the `eth_std` chain. 5 random transactions, due to respective API limits, are then selected.

For reproducibility purposes, a random seed of `1210` is specified. This seed can be iterated over and changed to produce larger subsets of more variability.

2. As we identify the transaction's originating wallet as the contributor's identity, we initially take a look into their presence on other Web 3 social platforms. For our purposes, we utilize the Lens Protocol API as it is reportedly the platform with the largest userbase.

Similar platforms rapidly growing include: `mintkudos.xyz`, `wonderverse.xyz`, `dework.xyz`, and `mirror.xyz`. In addition to the `has_lens` variable as executed in the R code, the following code is another example of how we can easily add a function to probe the `mirror.xyz` API:

    ```
    rand['is_mirror'] <- NA
    qry <- Query$new()

    qry$query('x', 'query mirror($test: String!) {
    transactions(
      tags: [
        {
          name:"App-Name",
          values:["MirrorXYZ"]
        },
        {
          name: "Contributor",
          values: [$test]
        }
      ]
      sort: HEIGHT_DESC
      first: 1
    ) {
      edges {
        node {
          id
        }
      }
    }
    }')

    cli <- GraphqlClient$new(url = "https://arweave.net/graphql")
    for (row in 1:nrow(rand)) {
      ref <- rand[row,1]
      variables <- list(test = ref)
  
      res = NULL
      res <- cli$exec(qry$queries$x, variables) %>% fromJSON()
  
      rand[row, 7] <- length(res$data$transactions$edges)
      print("Successful: retrieved response")
    }
    ```

3. Onto on-chain activity, we utilize the provided information alongside what can be accessed via Etherscan API (or other blockchain explorers). To start, we investigate their `first_tx`. By doing so, we seek to find out about the following:

- where or what their funding source is, and
- how long before their contribution was made did the wallet get funded.

4. Next, we look into their `last_tx`. By doing so, we seek to make observations on the following:

- what was done with the remaining funds, and
- how long after their contribution was any activity made.

# Discussion

A social network graph yields insight into the flow of information. In this case, funds on the blockchain. 

I believe that the collection of such information provides for much more accurate ability for humans to make decisions compared to a form of artificial intelligence or machine learning model. The reason being is that wallet activity, as brought forth by human behavior is erratic. 

Given how Web 3 continues to be technology that is continuously adapted by hundreds of people everyday, it remains arguably difficult to predict new and even existing user wallet behavior.

Foxtail aims to be a modular solution that makes it easier to retrive and interpret relevant information in evaluating contributers and contributions. Now, the operative keyword being *modular*, a basic outline of the what and how on-chain data would be used to do so are:

- preceding and succeeding wallet activity,
- interaction with verified contracts increases trustworthiness,
- interaction with suspected sybils decreases trustworthiness, and
- having a profile on a Web 3 social platform increases trustworthiness.

Given the boilerplate structure already implemented, it would be relatively simple to:

- add functionality to probe other Web 3 social platforms as briefly demonstrated above, and
- add functionality to investigate transactions made on other chains such as `zksync`.

1. Why `has_lens`?

It follows suit with Gitcoin Passport. Given its record of how Web 2 platforms produce sufficient trustworthiness and uniqueness of a user, doing the same with Web 3 platforms upholds the nature of what Web 3 aims to be. 

In the long run, continuing to validate users with Web 2 platforms is counter-productive to the very purpose of Web 3.

2. Why `first_tx` and `last_tx`?

It is believed that likely human behavior leads to sybils avoiding any contact with fellow sybils. In the belief that it prevents arousing suspision, probing a wallet's preceding and succeeding transaction to a contribution yields insight to whether or not:

- funds are just exchanging wallets between the same user,
- suspicious activity is obfuscated by insignificant activity, and

**This is the fundamental assumption that Foxtail is built on.**

Between these two sets of variables with the information gathered, suspicious behavior is likely if:

- straight after a wallet funding, a contribution is made,
- a wallet has at least one interaction with that of a suspected sybil, or
- after a contribution, funds cycle back into another wallet with an already recorded contribution.

# Limitations

At its present state, Foxtail is a proof-of-concept. However, given its already implemented structure, it is relatively trivial to expand on it.

I only found out about this hackathon three weeks into its opened time committment. Thus, I only had a week to put together a work product. Between other commitments, I was limited into understanding the data set and premise of the problem, exploring the Gitcoin ecosystem and related literature, and ideating means of interpretation and prediction of past, present, and future data.
