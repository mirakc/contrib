# Add the Mirakurun service ID
map(. + { msid: (.networkId * 100000 + .serviceId) })
