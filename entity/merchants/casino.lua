package.path = package.path .. ";data/scripts/entity/merchants/?.lua;"
require ("consumer")
require ("stringutility")

consumerName = "Casino"%_t
consumerIcon = "data/textures/icons/pixel/casino.png"
consumedGoods = {"Beer", "Wine", "Liquor", "Food", "Luxury Food", "Water", "Medical Supplies"}
