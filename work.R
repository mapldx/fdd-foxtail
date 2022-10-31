# install.packages("rjson")
library(rjson)
# install.packages("ghql")
library(ghql)
# install.packages("dplyr")
library(dplyr)
# install.packages("jsonlite")
library(jsonlite)
# install.packages("tidyverse")
library(tidyverse)
# install.packages("httr")
library(httr)

data <- read.csv("data.csv", colClasses = c(rep("character", 10)))
data <- data %>% select(address, chain, txn_hash, amount_in_usdt, timestamp)

data <- subset(data, chain == "eth_std")
set.seed(1210)
data <- as.data.frame(data[sample(1:nrow(data), 5), ])

data['has_lens'] <- NA
cli <- GraphqlClient$new(url = "https://api.lens.dev/")
for (row in 1:nrow(data)) {
  ref <- data[row,1]
  
  qry <- Query$new()
  q <- paste0('query DefaultProfile {
  defaultProfile(request: { ethereumAddress: "',ref,'"}) {
    id
    name
    bio
    isDefault
    followNftAddress
    metadata
    handle
    ownedBy
    stats {
      totalFollowers
      totalFollowing
      totalPosts
      totalComments
      totalMirrors
      totalPublications
      totalCollects
    }
  }
}')
  
  qry$query('x', q)
  
  res = NULL
  res <- cli$exec(qry$queries$x) %>% fromJSON()

  data[row, 6] <- length(res$data$defaultProfile)
  print("Successful: retrieved response")
}

data[which(data[,6] > 0),6] <- 1
data <- data %>% mutate_if(is.numeric,as.logical)

data['first_tx_hash'] <- NA
data['first_tx_timestamp'] <- NA
data['first_tx_from'] <- NA
data['first_tx_contractAddress'] <- NA

for (row in 1:nrow(data)) {
  ref <- data[row, 1]
  
  apikey <- INSERT_YOUR_ETHERSCAN_API_KEY
  req <- GET("https://api.etherscan.io/api", query = list(module = "account", action = "txlist", address = ref, startblock = "0", endblock = "99999999",
                                          page = "1", offset = "10", sort = "asc", apikey = apikey))
  res <- content(req)
  
  data[row, 7] <- res$result[[1]]$hash
  data[row, 8] <- res$result[[1]]$timeStamp
  data[row, 9] <- res$result[[1]]$from
  data[row, 10] <- res$result[[1]]$contractAddress
}
