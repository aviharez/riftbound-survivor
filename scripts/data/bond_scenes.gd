class_name BondScenes
extends RefCounted
## Short bond story scenes, one per bond level (1..5) per character. Drafted by Claude, reviewed by Syifa.
## Each scene: [title, text]. Keep them short (they are read on a phone) and wholesome.

const SCENES := {
	"astra": [
		["First Light", "Astra: \"Everyone keeps calling me the new student. I only got here the night the Rift opened.\"\nShe turns the crystal staff over in her hands.\nAstra: \"But the academy feels like it was waiting for someone. Maybe that's silly.\""],
		["Borrowed Staff", "Astra: \"This staff isn't mine. I found it in the entrance hall, humming like it knew me.\"\nAstra: \"Every crit I land, it hums again. I think it's happy we're fighting back.\""],
		["Night Lessons", "You find Astra in the courtyard after midnight, practising the same spark over and over.\nAstra: \"If I get it right a hundred times, maybe I'll stop being scared the hundred and first.\""],
		["Names on the Wall", "Astra traces the names carved on the old student wall.\nAstra: \"They all left when the Rift came. I want to write mine next to theirs... after we win.\""],
		["Not New Anymore", "Astra: \"Lyra called me 'senpai' today. As a joke. Probably.\"\nShe laughs, then goes quiet.\nAstra: \"Thank you for staying. I don't feel new here anymore.\""],
	],
	"lyra": [
		["Champion's Pride", "Lyra: \"Duel Club champion, three years running! Not that there was anyone left to duel this year...\"\nShe flicks a tiny flame into the air and catches it.\nLyra: \"So the Rift will have to do.\""],
		["Ribbon Rules", "Lyra: \"The ribbon stays on. Always. It was my big sister's.\"\nLyra: \"She graduated before everything went wrong. I'm keeping her seat warm.\""],
		["Too Hot to Handle", "Lyra burned the kitchen curtains. Again.\nLyra: \"In my defence, the toast was looking at me funny.\"\nShe hands you a slightly charred piece anyway."],
		["Losing on Purpose", "Lyra: \"Want to know a secret? I lost a duel once. On purpose. The other kid needed the win more.\"\nLyra: \"Don't tell anyone. A champion has an image.\""],
		["Kindled", "Lyra: \"Fire isn't about burning things down. It's about keeping people warm.\"\nShe sits closer to the fire you share.\nLyra: \"...That was a very cool line. Write it down.\""],
	],
	"kael": [
		["On Watch", "Kael: \"Gate's secure. North wall is cracked, but holding.\"\nHe doesn't look up from sharpening his blade.\nKael: \"Someone has to keep watch while the rest of you sleep.\""],
		["The Dent", "There is a deep dent in Kael's armour, right over the heart.\nKael: \"First night of the Rift. It's a reminder, not a wound.\""],
		["Spellblade Basics", "Kael shows you how to hold a blade so a spell can run along it.\nKael: \"Relax your wrist. Magic hates a tight grip. So do swords.\""],
		["Off Duty", "You catch Kael feeding the courtyard cats.\nKael: \"...They were hungry. This is a security matter.\""],
		["Sworn", "Kael: \"I swore to protect the academy. I thought that meant the walls.\"\nKael: \"It means the people. It means you. I'll hold that line.\""],
	],
	"nym": [
		["Infirmary Rounds", "Nym: \"Sit still, please. This salve stings a tiny bit.\"\nIt stings more than a tiny bit.\nNym: \"See? All better. You were very brave.\""],
		["Talking to Plants", "Nym whispers to the seedlings on the windowsill.\nNym: \"They grow faster if you tell them about your day. Science! ...Probably.\""],
		["The Thorn Garden", "Nym: \"My roots hold the monsters still so nobody gets hurt. Even them, if I can help it.\"\nNym: \"Is that strange? Wanting to heal everything?\""],
		["Night Shift", "You find Nym asleep at her desk, surrounded by herb notes.\nYou put a blanket over her shoulders. She mumbles something about chamomile."],
		["Bloom", "Nym: \"The infirmary used to be so full. Now it's quiet, because you keep everyone safe.\"\nShe tucks a small flower behind your ear.\nNym: \"Prescription: smile more.\""],
	],
	"selene": [
		["Council Business", "Selene: \"The Student Council is still in session. Attendance: one. Me.\"\nShe adjusts her papers.\nSelene: \"Now two. You may sit.\""],
		["Cold Hands", "Selene: \"People say I'm cold. Literally, yes. Cryomancy.\"\nSelene: \"Figuratively... I'm working on it.\""],
		["The Agenda", "Selene's agenda has one item underlined three times: 'Bring everyone home.'\nSelene: \"It is the only motion that matters.\""],
		["Snowfall", "Selene makes it snow inside the Frost Tower, just a little.\nSelene: \"It's for morale. Do not tell the others I did something fun.\""],
		["Vice President", "Selene: \"The council needs a vice president. I am nominating you.\"\nSelene: \"The vote passed. One to zero. Congratulations.\""],
	],
	"noah": [
		["Lab Rules", "Noah: \"Rule one: don't touch the green flask. Rule two: definitely don't touch the purple one.\"\nNoah: \"Rule three: if something bubbles, run.\""],
		["Goggles", "Noah never takes his goggles off.\nNoah: \"Two explosions ago, I learned. Now I'm a goggles person.\""],
		["Antidote", "Noah: \"Every poison I brew, I brew its cure first. That's the deal I made with myself.\""],
		["Bubbling Over", "The cauldron overflows into a harmless glittery foam.\nNoah: \"...That was supposed to be a smoke bomb. This is better, honestly.\""],
		["Formula", "Noah hands you a tiny vial on a string.\nNoah: \"Luck potion. Placebo, probably. But I made it for you, so it counts.\""],
	],
	"raika": [
		["Weather Report", "Raika: \"Today's forecast: cloudy with a ninety percent chance of me zapping something!\"\nShe spins, raincoat flaring.\nRaika: \"Weather Club, reporting for duty!\""],
		["Hairclips", "Raika: \"These clips are lightning rods. Kind of. They look cute AND they work.\"\nRaika: \"Fashion is science.\""],
		["Thunder Fear", "During a storm, Raika is very quiet.\nRaika: \"I can make lightning... but loud thunder still makes me jump. Don't laugh.\""],
		["The Bell", "Raika rings the Bell Tower bell at sunset.\nRaika: \"So everyone out there knows the academy is still here. Still loud!\""],
		["Clear Skies", "Raika: \"Forecast for tomorrow: sunny, because you're around.\"\nShe grins.\nRaika: \"Okay, that was cheesy. Still true!\""],
	],
	"vesper": [
		["The Forbidden Wing", "Vesper: \"...You woke me up. It's fine. I was only asleep for... how long has it been?\"\nShe hugs her plush bunny closer.\nVesper: \"Never mind. Hello.\""],
		["Mr. Buttons", "Vesper: \"This is Mr. Buttons. He holds my gravity when I'm sleepy.\"\nVesper: \"Please don't drop him. Things get... heavy.\""],
		["Heavy Thoughts", "Vesper: \"Gravity pulls everything together. I wish people were that simple.\"\nShe yawns.\nVesper: \"You're easy, though. You just stay.\""],
		["Sealed Books", "Vesper reads a forbidden book upside down.\nVesper: \"It's safer this way. The words fall out instead of in.\""],
		["Awake", "Vesper: \"I've been awake for a whole day. For you. Don't make it weird.\"\nShe leans on your shoulder.\nVesper: \"...Okay. Nap now.\""],
	],
	"wren": [
		["Shelving", "Wren: \"Oh! Sorry, I didn't see you, I was... the books were... sorry.\"\nA floating book nudges her.\nWren: \"Hi. I'm Wren. I work in the library. Lived, actually.\""],
		["My Familiar", "Wren: \"The little spirit? It's my familiar. It likes poetry and hates dust.\"\nWren: \"Same, honestly.\""],
		["Overdue", "Wren: \"Someone borrowed a book eleven years ago. I'm going to find them. After the Rift.\""],
		["Reading Aloud", "Wren reads to you by lamplight. Her voice stops shaking after the first page."],
		["Bookmark", "Wren gives you a hand-pressed flower bookmark.\nWren: \"So you never lose your place. In books. Or... here.\""],
	],
	"sera": [
		["Instructor Sera", "Sera: \"Stance. Wider. Good.\"\nShe corrects your grip with two fingers.\nSera: \"Spellblade is patience first, sword second, magic third.\""],
		["The Braid", "Sera: \"The braid keeps my hair out of my eyes. Also my students used to tug it when they won.\"\nSera: \"I miss losing to them.\""],
		["Crescent", "Sera draws a perfect crescent of light in the air.\nSera: \"Clean form is kindness. It ends a fight quickly.\""],
		["Tea Break", "Sera: \"Instructors are allowed tea breaks. It's in the rules. I wrote the rules.\""],
		["Graduation", "Sera: \"You've learned everything I can teach in a duel hall.\"\nSera: \"The rest you'll learn by protecting people. Go on, student.\""],
	],
	"celeste": [
		["Professor Celeste", "Celeste: \"Mm... is it night already? Perfect. The stars only teach at night.\"\nShe adjusts her starry hat and immediately yawns."],
		["Falling Stars", "Celeste: \"Every star I call down, I thank. They come a very long way for us.\""],
		["Star Charts", "Celeste: \"This constellation is the Sleeping Cat. I named it. Obviously.\""],
		["Morning Person", "You find Celeste awake at dawn.\nCeleste: \"I haven't slept yet. That counts as a morning person, right?\""],
		["Your Star", "Celeste points at a faint star.\nCeleste: \"That one's yours now. I wrote it down. Professors are very official about these things.\""],
	],
	"runa": [
		["Rune Master", "Runa: \"I'm the Rune Master. Yes, really. Yes, I'm short. The robe is very official.\"\nThe sleeves cover her hands entirely."],
		["Prodigy", "Runa: \"I carved my first rune at four. It said 'snack'. It still works.\""],
		["Workshop Rules", "Runa: \"Never trace a rune backwards. It goes very badly. Ask the old west wall. Oh wait, you can't.\""],
		["Sleeves", "Runa: \"I'll grow into the robe. Eventually. Possibly.\"\nShe rolls the sleeves up three times. They roll back down."],
		["A Gift Rune", "Runa carves a tiny rune into a pebble for you.\nRuna: \"Protection. Top quality. Genius work. ...You're welcome.\""],
	],
	"lumi": [
		["Aether Lab", "Lumi: \"Welcome to the Arcana Lab! Mind the lenses, they bend light and occasionally time.\"\nHer prism earrings scatter tiny rainbows."],
		["Refraction", "Lumi: \"Light never really disappears. It just finds another path. Like people.\""],
		["Lab Coat", "Lumi: \"The coat has twelve pockets. Eleven are for notes. One is for emergency candy.\""],
		["Experiment", "Lumi: \"Hypothesis: the academy is happier with you in it. Data so far: strongly supportive.\""],
		["Spectrum", "Lumi hands you a small prism.\nLumi: \"Hold it to the light whenever things feel grey. There's always more colour than you think.\""],
	],
}


## Scene [title, text] for a character's bond level (1..5), or [] if none.
static func scene(id: String, level: int) -> Array:
	var list: Array = SCENES.get(id, [])
	return list[level - 1] if level >= 1 and level <= list.size() else []
