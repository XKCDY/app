//
//  Fortunes.swift
//  XKCDY
//
//  Created by Max Isom on 8/6/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation

struct Fortune {
    let comicId: Int
    let text: String
}

struct Fortunes {
    private let fortunes = [
        1327: "We're firing you, but the online headline-writing division wants to hire you.",
        1835: "I take the view that \"open-faced sandwiches\" are not sandwiches, but all other physical objects are.",
        1541: "Anyway, we should totally go watch a video story or put some food in our normal mouths!",
        79: "Of course, you don't wanna limit yourself to the strict forms of the meter.  That could get pretty difficult.",
        1539: "[10 years later] Man, why are people so comfortable handing Google and Facebook control over our nuclear weapons?",
        1577: "The few dozen doors that have little Christmas trees on them are a nice touch.",
        1540: "Instead of bobcat, package contained chair.",
        2276: "Turns out I've been \"practicing social distancing\" for years without even realizing it was a thing!",
        845: "During the week, I research my character by living in his house and raising his children.",
        1196: "About one in three North American subway stops are in NYC.",
        1821: "My trash can broke recently and I had to get rid of it. When I picked it up, I suffered a brief but harrowing existential crisis.",
        1533: "WARNING: This item was aged by the same inexorable passage of time that also processes nuts.",
        1936: "I just want to stay up long enough to watch the ball drop into the hole number 2018.",
        2013: "It traveled so far to reach me. I owed it my best.",
        968: "I wanna hold your hand so I don't fall out of your gyrocopter.",
        1619: "Due to a minor glitch, 'discharge patient' does not cause the algorithm to exit, but instead leads back to 'hunt down and capture patient'.",
        1850: "I had fun visiting the museum at Dover Air Force Base, unless they don't have a museum, in which case I've never been to Delaware in my life.",
        2016: "SUB[59]: The submission numbers for my accepted OEIS submissions in chronological order",
        536: "If you think space elevators are good, but just too boring and practical, check out the 'space fountain'.",
        1579: "And when I think about it, a lot of \"things I want to do\" are just learning about and discussing new tools for tinkering with the chain.",
        921: "You can arrange a pickup of your sword in Rivendell between the hours of noon and 7:00 PM.",
        170: "I hear that these days Bill Watterson is happy just painting in the Ohio woods with his father and doesn't get any mail or talk to anyone.",
        348: "We should probably talk about this before the wedding.",
        1661: "BREAKING: Senator's bold pro-podium stand leads to primary challenge from prescriptivist base.",
        1426: "I tried oxidizing them, but your bank uses some really weird paper and it wouldn't light.",
        2303: "Type IIII error: Mistaking tally marks for Roman numerals",
        520: "Unless the CS students finish the robot revolution before you finish the cephalopod one.",
        164: "There are so many well-meaning conservatives around here who just assume global warming is only presented as a moral issue for political reasons.",
        390: "Well, *I* think I'm real.  Look at me.  Look at my face.  Cut me and I'll bleed.  What more do you want?  Please don't go.",
        864: "It's hard to fit in the backseat of my flying car with my android Realdoll when we're both wearing jetpacks.",
        2260: "If Google Maps stops letting you navigate to (Clay County District) A in West Virginia, you can try Jump, OH -> Ina, IL -> Big Hole, TX.",
        38: "There used to be these ads, see . . .",
        316: "Spherical or parabolic reflectors would of course lead to aberrant behavior.",
        1739: "'What was the original problem you were trying to fix?' 'Well, I noticed one of the tools I was using had an inefficiency that was wasting my time.'",
        37: "I do this constantly",
        2313: "Deep in some corner of my heart, I suspect that real times tables are wrong about 6x7=42 and 8x7=56.",
        1335: "This image stays roughly in sync with the day (assuming the Earth continues spinning). Shortcut: xkcd.com/now",
        1097: "BUT WHAT IF I REASSURE MYSELF WITH A JOKE AND THEN DON'T WORRY ABOUT THE RASH AND IT TURNS OUT TO BE DEATH MITES AND I COULD HAVE CAUGHT IT",
        401: "When charged particles of more than 5 TeV pass through a bubble chamber, they leave a trail of candy.",
        938: "'We're not sure how to wipe out the chimeral T-cells after they've destroyed the cancer. Though I do have this vial of smallpox ...'",
        1897: "\"Crowdsourced steering\" doesn't sound quite as appealing as \"self driving.\"",
        642: "And I even got out my adorable new netbook!",
        120: "I don't understand why people are so disingenuous!  I just want someone to walk with!",
        1338: "Bacteria still outweigh us thousands to one--and that's not even counting the several pounds of them in your body.",
        809: "The test didn't (spoiler alert) destroy the world, but the fact that they were even doing those calculations makes theirs the coolest jobs ever.",
        528: "Disclaimer: I have not actually tried the beta yet.  I hear it's quite pleasant and hardly Hitler-y at all.",
        73: "A tribute to Buttercup Festival",
        906: "When advertisers figure this out, our only weapon will be blue sharpies and \"[disputed]\".",
        891: "If you're 15 or younger, then just remember that it's nevertheless probably too late to be a child prodigy.",
        1583: "Why are we spending billions to ruin Mars with swarms of robots when Elon Musk has promised to ruin Mars for a FRACTION of the cost?",
        529: "If you get your hands on that one, it's the worst place to have a breaking-up conversation.",
        306: "His date works for Red Hat, who hired a coach for her, too.  He advised her to 'rent lots of movies like Hitch.  Guys love those.'",
        1620: "SOUND DOGS MAKE: [BARKING] [HISSING] [LIGHTSABER NOISES] [FLUENT ENGLISH] [SWEARING]",
        2248: "\"Off-by-one errors\" isn't the easiest theme to build a party around, but I've seen worse.",
        2301: "It's possible the bread and shell can be split into a top and bottom flavor, and some models additionally suggest Strange Bread and Charm Shells.",
        545: "'Hey, everyone, you can totally trust that I didn't do a word count on MY edit!'",
        200: "You could at least not wear the lab coat everywhere, dude.",
        1778: "Sometimes, parts of a slowly-rising mountain suddenly rise REALLY fast, which is extra interesting.",
        2341: "I vaguely and irrationally resent how useful WebPlotDigitizer is.",
        271: "It's kinda Zen when you think about it, if you don't think too hard.",
        1648: "The Romeo and Butt-Head film actually got two thumbs up from Siskel and Oates.",
        1650: "Does it get taller first and then widen, or does it reach full width before getting taller, or alternate, or what?",
        583: "Can't and shouldn't.",
        301: "Fun game: try to post a YouTube comment so stupid that people realize you must be joking.  (Hint: this is impossible)",
        492: "A veteran Scrabble player will spot the 'OSTRICH' option.",
        905: "New research shows over 60% of the financial collapse's toxic assets were created by power drills.",
        1734: "\"I've noticed you physics people can be a little on the reductionist side.\" \"That's ridiculous. Name ONE reductionist word I've ever said.\"",
        450: "And then a second one, to drain the sea.",
        1373: "I'M PLUGGING IN MY PHONE BUT THE BATTERY ON THE SCREEN ISN'T CHARGING",
        1630: "I always have to turn off nature documentaries when they show these scenes.",
        2312: "Hello and welcome to Millibar Millibarn Attometer, an advice show for the Planck era.",
        337: "That track ('Battle Without Honor or Humanity') -- like 'Ride of the Valkyries' -- improves *any* activity.",
        2286: "Technically now it's a 34-foot zone.",
        1771: "It me, your father.",
        1382: "Every year: 'It's <year>--I want my jetpack [and also my free medical care covering all my jetpack-related injuries]!'",
        957: "Funding was quickly restored to the NHC and the APA was taken back off hurricane forecast duty.",
        1465: "Washable, though only once.",
        1994: "I was just disassembling it over the course of five hours so it would fit in the trash more efficiently.",
        1475: "\"Technically that sentence started with 'well', so--\" \"Ooh, a rock with a fossil in it!\"",
        1879: "'Hey! Put her down!' 'No, it's ok! The next chance for me to be carried to a blood cauldron isn't until 2024!'",
        105: "It's possible.  Better to be on the safe side.",
        1869: "This restaurant is great! I was feeling really sick, but then I ate there and felt better!",
        362: "Blade Runner: Classic, but incredibly slow.",
        567: "Sure, we could stop dictators and pandemics, but we could also make the signs on every damn diagram make sense.",
        2339: "Canada's travel restrictions on the US are 99% about keeping out COVID and 1% about keeping out people who say 'pod.'",
        908: "There's planned downtime every night when we turn on the Roomba and it runs over the cord.",
        501: "The only blood these contracts are signed in is from me cutting my hand trying to open the goddamn CD case.",
        448: "As my standard, I use going to sleep at midnight and waking up at 8 AM.",
        1813: "My favorite might be U+1F609 U+1F93F WINKING FACE VOMITING.",
        1450: "I'm working to bring about a superintelligent AI that will eternally torment everyone who failed to make fun of the Roko's Basilisk people.",
        1728: "Take THAT, piece of 1980s-era infrastructure I've inexplicably maintained on my systems for 15 years despite never really learning how it works.",
        1513: "I honestly didn't think you could even USE emoji in variable names. Or that there were so many different crying ones.",
        1198: "'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.'",
        1679: "BREAKING: Channing Tatum and his friends explore haunted city",
        1846: "On the other hand, as far as they know, my system is working perfectly.",
        1262: "I guess it's a saying from the Old Country.",
        1614: "[Dog returns with the end of a string in its mouth] [Voice drifts down from the sky] Kites are fun!",
        2264: "If you're going to let it burn up, make sure it happens over the deep end of the bathtub and not any populated parts of the house!",
        41: "I don't want to talk about it",
        2179: "Kind of rude of them to simultaneously issue an EVACUATION - IMMEDIATE alert, a SHELTER IN PLACE alert, and a 911 TELEPHONE OUTAGE alert.",
        150: "I've looked into this, and I can't figure out a way to do it cheaply.  And I guess it wouldn't be sanitary.",
        1853: "I'm not totally locked into my routine—twice a year, I take a break to change the batteries in my smoke detectors.",
        2122: "Terms I'm going to start using: The Large Dipper, great potatoes, the Big Hadron Collider, and Large Orphan Annie.",
        2328: "My shooting will improve over the short term, but over the long term the universe will take more shots.",
        1680: "It also brings all the boys, and everything else, to the yard.",
        380: "U+FDD0 is actually Unicode for the eye of the basilisk, though for safety reasons no font actually renders it."
    ]

    func getRandom() -> Fortune {
        let index = Int(arc4random_uniform(UInt32(fortunes.count)))

        return Fortune(comicId: Array(fortunes.keys)[index], text: Array(fortunes.values)[index])
    }
}
