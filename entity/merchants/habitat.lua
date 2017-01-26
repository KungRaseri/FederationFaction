package.path = package.path .. ";data/scripts/lib/?.lua;data/scripts/entity/merchants/?.lua"
require ("consumer")
require ("stringutility")

consumerName = "Habitat"%_t
consumerIcon = "data/textures/icons/pixel/habitat.png"
consumedGoods = {"Beer", "Wine", "Liquor", "Food", "Tea", "Luxury Food", "Spices", "Vegetable", "Fruit", "Cocoa", "Coffee", "Wood", "Meat", "Water"}
