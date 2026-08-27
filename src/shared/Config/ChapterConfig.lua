--!strict

export type ChapterPresentation = {
  flavor: string,
  mechanic: string,
  tier: string,
}

return {
  RiverbankWelcome = {
    flavor = "Follow the river and find the first safe stepping stones.",
    mechanic = "Stepping stones",
    tier = "Forgiving",
  },
  MoleBurrowBounce = {
    flavor = "A burrow full of roots, lanterns, and surprising springs.",
    mechanic = "Bounce pads",
    tier = "Forgiving",
  },
  RattyRiverStones = {
    flavor = "The current is lively today. Keep your footing.",
    mechanic = "Moving logs",
    tier = "Forgiving",
  },
  ToadHallGate = {
    flavor = "Toad Hall is close, but its gate has ideas of its own.",
    mechanic = "Sweeper gate",
    tier = "Easy",
  },
  LibraryTumble = {
    flavor = "Mind the shelves. And the books. Especially the books.",
    mechanic = "Timed shelves",
    tier = "Easy",
  },
  RunawayCaravan = {
    flavor = "The caravan has started rolling. Catch it if you can.",
    mechanic = "Moving caravan",
    tier = "Easy",
  },
  TavernBarrelHop = {
    flavor = "A barrel is only a chair if it stays still.",
    mechanic = "Rolling barrels",
    tier = "Easy-medium",
  },
  CourtroomChaos = {
    flavor = "Order in the court! Preferably before the gavel lands.",
    mechanic = "Gavel timing",
    tier = "Easy-medium",
  },
  JailbreakBars = {
    flavor = "Moonlight, iron bars, and one very determined escape.",
    mechanic = "Timed gates",
    tier = "Easy-medium",
  },
  LaundryCartEscape = {
    flavor = "Board the cart. Hold on. Try not to lose the laundry.",
    mechanic = "Guided cart",
    tier = "Medium",
  },
  BargeCrossing = {
    flavor = "Cargo shifts, ropes creak, and the river keeps moving.",
    mechanic = "Moving barge",
    tier = "Medium",
  },
  TrainTunnelDash = {
    flavor = "Watch the signals and use the alcoves when the whistle calls.",
    mechanic = "Train timing",
    tier = "Medium",
  },
  WildWoodGusts = {
    flavor = "The Wild Wood is breathing. Move with the gusts.",
    mechanic = "Wind lanes",
    tier = "Medium-high",
  },
  BadgerLanternPath = {
    flavor = "A quiet lantern path hides a golden detour.",
    mechanic = "Light puzzle",
    tier = "Medium-high",
  },
  MotorcarMadness = {
    flavor = "The road is winding, the engines are loud, and Toad is delighted.",
    mechanic = "Motorcar hazards",
    tier = "Medium-high",
  },
  RoadsideConeSprint = {
    flavor = "A final road sprint rewards brave shortcuts.",
    mechanic = "Slalom sprint",
    tier = "High",
  },
  HomecomingRingRun = {
    flavor = "The banners are up. One last flight toward home.",
    mechanic = "Aerial rings",
    tier = "High",
  },
  ToadHallFireworks = {
    flavor = "Toad Hall opens its doors for a spectacular homecoming.",
    mechanic = "Finale sequence",
    tier = "Spectacular",
  },
}
