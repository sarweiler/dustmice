s.boot
s.scope

/* ###Initialize controllers */
(

/* Grid */
~m = MonoM.new("/monome", 0);
~m.useDevice(0);
~m.darkness;
~grid = MonomeGrid.new(~m);


/* Arc */
~a = Arc.new("/monome", 0);
~a.useDevice(1);
~a.darkness;
~arc = MonomeArc.new(~a);


/* Initial settings */
~octaves = [24,36,48,60,72];
~keysHeld = 0;

~grid.pitchValues.do({ | xpos, row |
	~m.levrow(0,row,[8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
});


/* Helper functions */
~setPitch = { | synthNum, octave, note |
	var frequency = ~calcPitch.value(octave, note);
	~snths[synthNum].set(\freq, frequency);
};

~calcPitch = { | oct, note |
	var midiNote = ~octaves[oct - 1] + note;
	midiNote.midicps;
};


/* Grid OSC handling */
OSCFunc.newMatching({ | message, time, addr, recvPort |
	var gridX = message[1];
	var gridY = message[2];
	var buttonDown = message[3];

	if(buttonDown == 1,
		{ ~keysHeld = ~keysHeld + 1; },
		{ ~keysHeld = ~keysHeld - 1; });

	if((gridX < 15 && (~keysHeld == 1) && (buttonDown == 1)),
		{
			var row = gridY;
			~grid.setPitch(row, gridX);
			~setPitch.value(row, ~grid.octaveValues[row], ~grid.pitchValues[row]);
		},
		{
			// TODO: Check if edit mode active, not if 2 buttons held => Array.collect?
			if((buttonDown == 1) && (~keysHeld == 1),
				{
					~grid.rowInEditMode_(gridY);
					~grid.displayEditRow(gridY);
				},
				{
					if(~keysHeld == 0, {
						~grid.rowInEditMode_(-1);
						~grid.displayRow(gridY);
					});

				}
			);

			if((~keysHeld == 2) && (~grid.rowInEditMode == gridY),
				{
					var row = gridY;
					~grid.setOctave(gridY, gridX + 1);
					~setPitch.value(row, ~grid.octaveValues[row], ~grid.pitchValues[row]);
				}
			);
		}
	);
}, "/monome/grid/key");


/* Arc OSC handling */
OSCFunc.newMatching({ | message |
	var enc = message[1];
	var encDelta = message[2];
	~arc.setFancyVal(enc, encDelta);
}, "/monome/enc/delta");
)



/* ###Initialize SynthDef */

(
SynthDef.new(\sineosc, { arg freq = 24.midicps, out = 0, dust_freq = 0.5, device = 0;
	var dust = Dust.kr(dust_freq);
	var env = Env([0.000001, 1, 0.000001], [0.1, 1], \exp).kr(0, dust);
	Out.ar(out, FreeVerb2.ar(LFTri.ar(freq, 0, 0.2) * env, SinOsc.ar(freq, 0, 0.2) * env, 0.8, 0.8, 0.1));
	SendTrig.kr(dust, device);
}).add;
)



/* ###Initialize synths */

(
~snths = [
	Synth(\sineosc, [\out, 0, \device, 0]),
	Synth(\sineosc, [\out, 1, \device, 1]),
	Synth(\sineosc, [\out, 0, \device, 2]),
	Synth(\sineosc, [\out, 1, \device, 3]),
	Synth(\sineosc, [\out, 0, \device, 4]),
	Synth(\sineosc, [\out, 1, \device, 5]),
	Synth(\sineosc, [\out, 0, \device, 6]),
	Synth(\sineosc, [\out, 1, \device, 7])
];

/* Visual feedback */
OSCFunc.newMatching({ | message, time |
	var row = message[2];
	var xpos = ~grid.pitchValues[row];

	if(~grid.rowInEditMode != row, {
		~m.levset(xpos,row, 12);
		SystemClock.sched(0.1, {
			~m.levset(xpos,row, 8);
		});
	});
}, "/tr", s.addr);
)

