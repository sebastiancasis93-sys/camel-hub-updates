-- tools tab
setDefaultTab("Tools")

-- ================================================================
-- Camel Hub Universal TargetBot profiles
-- Monsters/Todo are created only if missing. Existing edits survive.
-- ================================================================

CamelUniversalProfiles = CamelUniversalProfiles or {}

local universalTargets = {
  Monsters = [==[{"looting":{"items":[{"count":1,"id":3386},{"count":1,"id":3392},{"count":1,"id":3366},{"count":1,"id":3420},{"count":1,"id":3414},{"count":8,"id":3035},{"count":1,"id":3364},{"count":1,"id":3360},{"count":30,"id":3043},{"count":1,"id":3438},{"count":1,"id":3079},{"count":1,"id":3389},{"count":1,"id":3554},{"count":1,"id":3422},{"count":1,"id":7402},{"count":1,"id":3428},{"count":30,"id":3031},{"count":1,"id":3280}],"maxDanger":10,"minCapacity":600,"containers":[],"everyItem":false},"targeting":[{"lureDelay":250,"lureMin":4,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":6,"regex":"^dragon lord$","dynamicLureDelay":false,"priority":8,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":8,"rePosition":false,"name":"Dragon Lord","rpSafe":false},{"lureDelay":250,"lureMin":3,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":5,"regex":"^demon$","dynamicLureDelay":true,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Demon","rpSafe":false},{"lureDelay":250,"lureMin":3,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":6,"regex":"^demodras$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Demodras","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^dragon$","dynamicLureDelay":false,"priority":20,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Dragon","rpSafe":false},{"lureDelay":600,"lureMin":1,"maxDistance":7,"anchorRange":3,"lureCount":4,"avoidAttacks":false,"rePositionAmount":2,"lureMax":5,"rpSafe":false,"chase":true,"priority":1,"name":"Elf Titan","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":10,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":8,"rePosition":false,"dynamicLure":false,"regex":"^elf titan$"},{"lureDelay":250,"lureMin":2,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":8,"rpSafe":false,"chase":true,"priority":1,"name":"Old Widow","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":true,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^old widow$"},{"lureDelay":250,"lureMin":1,"maxDistance":2,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":true,"priority":1,"name":"Training Monk","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^training monk$"},{"lureDelay":250,"lureMin":2,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":5,"rpSafe":false,"chase":true,"priority":1,"name":"Quara Predator","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^quara predator$"},{"lureDelay":250,"lureMin":3,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":6,"rpSafe":false,"chase":true,"priority":1,"name":"Quara Pincher Scout","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^quara pincher scout$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":true,"priority":1,"name":"Thornback","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^thornback$"},{"lureDelay":250,"lureMin":1,"maxDistance":7,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^defiler$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Defiler","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^son of verminor$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Son of Verminor","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^the abomination$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"The Abomination","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^fire mage$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Fire Mage","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Orshabaal","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^orshabaal$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^draken elite$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Draken Elite","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^skeleton warrior$","dynamicLureDelay":false,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Skeleton Warrior","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Undead Gladiator","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^undead gladiator$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":true,"priority":1,"name":"Phyrexian Colossus","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^phyrexian colossus$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^barbarian skullhunter$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Barbarian Skullhunter","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^barbarian bloodwalker$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Barbarian Bloodwalker","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^barbaria$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Barbaria","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^barbarian headsplitter$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Barbarian Headsplitter","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":true,"priority":1,"name":"Barbarian Brutetamer","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^barbarian brutetamer$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^big boss trolliver$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Big Boss Trolliver","rpSafe":false},{"lureDelay":250,"lureMin":2,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":3,"lureMax":4,"regex":"^phyrexian guardian$","dynamicLureDelay":false,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":true,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":8,"rePosition":false,"name":"Phyrexian Guardian","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^chimera$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Chimera","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^astaroth$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Astaroth","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Gorgon","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^gorgon$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Telquines","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^telquines$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Kobalos","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^kobalos$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Antahualla","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":false,"regex":"^antahualla$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Serpent Spawn","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^serpent spawn$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":true,"priority":1,"name":"Blightwalker","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^blightwalker$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^blood reaper$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Blood Reaper","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^green frog$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Green Frog","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^treiner$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Treiner","rpSafe":false},{"lureDelay":250,"lureMin":3,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":5,"regex":"^grim reaper$","dynamicLureDelay":true,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Grim Reaper","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^hydra$","dynamicLureDelay":false,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Hydra","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Fury","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^fury$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Frost Dragon","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^frost dragon$"},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^nightmare$","dynamicLureDelay":false,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Nightmare","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^bog raider$","dynamicLureDelay":false,"priority":1,"dynamicLure":true,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Bog Raider","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^hero$","dynamicLureDelay":false,"priority":1,"dynamicLure":false,"keepDistance":false,"danger":1,"chase":false,"keepDistanceRange":1,"lure":false,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Hero","rpSafe":false},{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"rpSafe":false,"chase":false,"priority":1,"name":"Hellspawn","keepDistance":false,"keepDistanceRange":1,"dynamicLureDelay":false,"danger":1,"delayFrom":2,"closeLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"lure":false,"anchor":false,"closeLureAmount":3,"rePosition":false,"dynamicLure":true,"regex":"^hellspawn$"},{"lureDelay":250,"lureMin":2,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":4,"regex":"^black demon$","chase":false,"priority":1,"keepDistance":false,"closeLure":false,"danger":1,"keepDistanceRange":1,"lure":false,"dynamicLureDelay":false,"dynamicLure":true,"faceMonster":false,"lureCavebot":false,"dontLoot":false,"diamondArrows":true,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"Black Demon","rpSafe":false}]}]==],
  Todo = [==[{"looting":{"items":[{"count":21,"id":3043},{"count":99,"id":3031},{"count":94,"id":3035}],"maxDanger":10,"minCapacity":100,"containers":[{"count":1,"id":37855}],"everyItem":false},"targeting":[{"lureDelay":250,"lureMin":1,"maxDistance":10,"anchorRange":3,"lureCount":1,"avoidAttacks":false,"rePositionAmount":5,"lureMax":3,"regex":"^.*$","chase":false,"priority":1,"keepDistance":false,"closeLure":false,"danger":1,"keepDistanceRange":1,"lure":false,"dynamicLureDelay":false,"dynamicLure":false,"faceMonster":false,"lureCavebot":false,"dontLoot":true,"diamondArrows":false,"delayFrom":2,"anchor":false,"closeLureAmount":3,"rePosition":false,"name":"*","rpSafe":false}]}]==]
}

local function ensureUniversalTargetProfiles()
  local ok, configName = pcall(function()
    return modules.game_bot.contentsPanel.config:getCurrentOption().text
  end)
  if not ok or type(configName) ~= "string" or configName == "" then return end

  local dir = "/bot/" .. configName .. "/targetbot_configs"
  if not g_resources.directoryExists(dir) then
    pcall(function() g_resources.makeDir(dir) end)
  end

  for name, payload in pairs(universalTargets) do
    local path = dir .. "/" .. name .. ".json"
    if not g_resources.fileExists(path) then
      pcall(function()
        g_resources.writeFileContents(path, payload)
      end)
    end
  end
end

CamelUniversalProfiles.ensureTargets = ensureUniversalTargetProfiles
CamelUniversalProfiles.targetNames = {"Monsters", "Todo"}
ensureUniversalTargetProfiles()

-- ================================================================
-- Energy Ring - behavior based on Sabuezo ULTRA FAST
-- ================================================================

local eringKey = "autoERing_Ultra"
if not storage[eringKey] then
  storage[eringKey] = {
    enabled = false,
    equipAt = 75,
    removeAt = 90,
    normalRing = 3004
  }
end

local eringCfg = storage[eringKey]
eringCfg.normalRing = eringCfg.normalRing or 3004

local ENERGY_RING = 3051
local ENERGY_RING_EQUIPPED = 3088
local ERING_SAFE_DELAY = 2000
local ERING_DAMAGE_SAMPLE = 250
local ERING_HEAVY_DAMAGE = 8

local eringUi = setupUI([[
Panel
  height: 142
  margin-top: 2
  background-color: #292A2A
  border: 1 black

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    text: Energy Ring
    height: 18
    color: #ffffff

  Panel
    id: body
    anchors.top: title.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin: 5

    Label
      id: labelEquip
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      color: #77D390
      text-align: center
      font: verdana-11px-rounded

    HorizontalScrollBar
      id: scrollEquip
      anchors.top: labelEquip.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 3
      minimum: 1
      maximum: 100
      step: 1

    Label
      id: labelRemove
      anchors.top: scrollEquip.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 8
      color: #ff5959
      text-align: center
      font: verdana-11px-rounded

    HorizontalScrollBar
      id: scrollRemove
      anchors.top: labelRemove.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 3
      minimum: 1
      maximum: 100
      step: 1

    Label
      id: labelNormal
      anchors.top: scrollRemove.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 8
      margin-right: 40
      color: #dfdfdf
      text-align: center
      text: Ring normal
      font: verdana-11px-rounded

    BotItem
      id: normalRing
      anchors.top: scrollRemove.bottom
      anchors.right: parent.right
      margin-top: 4
      width: 32
      height: 32
]])

local function updateERingLabels()
  eringUi.body.labelEquip:setText("Equipar Ring <= " .. eringCfg.equipAt .. "%")
  eringUi.body.labelRemove:setText("Quitar Ring >= " .. eringCfg.removeAt .. "%")
end

eringUi.title:setOn(eringCfg.enabled == true)
eringUi.title.onClick = function()
  eringCfg.enabled = not eringCfg.enabled
  eringUi.title:setOn(eringCfg.enabled)
end

eringUi.body.scrollEquip:setValue(eringCfg.equipAt)
eringUi.body.scrollEquip.onValueChange = function(_, value)
  eringCfg.equipAt = value
  updateERingLabels()
end

eringUi.body.scrollRemove:setValue(eringCfg.removeAt)
eringUi.body.scrollRemove.onValueChange = function(_, value)
  eringCfg.removeAt = value
  updateERingLabels()
end

eringUi.body.normalRing:setItemId(eringCfg.normalRing)
eringUi.body.normalRing.onItemChange = function(widget)
  eringCfg.normalRing = widget:getItemId()
end

updateERingLabels()

CamelEnergyRing = CamelEnergyRing or {}

local lastRingMove = 0
local lastDangerAt = now or 0
local lastHpSampleAt = now or 0
local lastHpSample = hppercent() or 100

local function canMoveRing()
  local pingDelay = g_game.getPing and g_game.getPing() * 2 or 0
  local moveDelay = math.max(pingDelay, 150)
  if now - lastRingMove < moveDelay then return false end
  lastRingMove = now
  return true
end

local function moveRingToFinger(itemId)
  if not itemId or itemId <= 0 then return false end

  local ring = findItem(itemId)
  if ring and canMoveRing() then
    g_game.move(ring, {x=65535, y=SlotFinger, z=0}, 1)
    return true
  end
  return false
end

local function setERingEnabled(value)
  eringCfg.enabled = value == true
  eringUi.title:setOn(eringCfg.enabled)
end

CamelEnergyRing.isOn = function() return eringCfg.enabled == true end
CamelEnergyRing.setOn = function() setERingEnabled(true) end
CamelEnergyRing.setOff = function() setERingEnabled(false) end

macro(20, function()
  if not eringCfg.enabled then return end

  local finger = getFinger()
  local fingerId = finger and finger:getId() or 0
  local hp = hppercent()

  if now - lastHpSampleAt >= ERING_DAMAGE_SAMPLE then
    if lastHpSample - hp >= ERING_HEAVY_DAMAGE then
      lastDangerAt = now
    end
    lastHpSample = hp
    lastHpSampleAt = now
  end

  if eringCfg.removeAt <= eringCfg.equipAt then
    eringCfg.removeAt = math.min(100, eringCfg.equipAt + 2)
    eringUi.body.scrollRemove:setValue(eringCfg.removeAt)
  end

  if hp <= eringCfg.equipAt then
    lastDangerAt = now
    if fingerId ~= ENERGY_RING_EQUIPPED then
      moveRingToFinger(ENERGY_RING)
    end
  else
    if fingerId == ENERGY_RING_EQUIPPED and hp >= eringCfg.removeAt then
      if canMoveRing() then
        g_game.move(finger, {x=65535, y=SlotBack, z=0}, 1)
      end
    elseif fingerId == 0 and now - lastDangerAt >= ERING_SAFE_DELAY then
      moveRingToFinger(eringCfg.normalRing)
    end
  end
end)

UI.Separator()

if type(storage.moneyItems) ~= "table" then
  storage.moneyItems = {3031, 3035}
end
macro(1000, "Exchange money", function()
  if not storage.moneyItems[1] then return end
  local containers = g_game.getContainers()
  for index, container in pairs(containers) do
    if not container.lootContainer then -- ignore monster containers
      for i, item in ipairs(container:getItems()) do
        if item:getCount() == 100 then
          for m, moneyId in ipairs(storage.moneyItems) do
            if item:getId() == moneyId.id then
              return g_game.use(item)            
            end
          end
        end
      end
    end
  end
end)

local moneyContainer = UI.Container(function(widget, items)
  storage.moneyItems = items
end, true)
moneyContainer:setHeight(35)
moneyContainer:setItems(storage.moneyItems)

UI.Separator()
