statefull set, certain fields are immutable, cm and the labels are one of them, since the question asks you only need to use helm,
you can change the values manually inside the charts templates, adn with helm you can first set the replica to 0 and do upgrade and then again to 1 and then upgrade.
