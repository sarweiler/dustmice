s.boot;
s.reboot;

/* ###Initialize controllers */
(

var gridPort = 15482;
var arcPort = 10537;

/* Grid */
~m = MonoM.new("/monome", 0);
~m.usePort(gridPort);
~m.darkness;
~grid = MonomeGrid.new(~m);


/* Arc */
~a = Arc.new("/monome", 0);
~a.usePort(arcPort);
~a.darkness;
~arc = MonomeArc.new(~a);

/* SynthData */

~synthData = SynthData.new();

/* Initial settings */
~octaves = [24,36,48,60,72];
~keysHeld = 0;

~grid.initGrid();


/* Helper functions */
~setPitch = { | synthNum, octave, note |
	var frequency = ~calcPitch.value(octave, note);
	~synths[synthNum].set(\freq, frequency);
};

~setDustFreq = { | synthNum, dustFreqVal |
	~synths[synthNum].set(\dust_freq, dustFreqVal / 100);
};

~setEnvDecay = { | synthNum, envDecayVal |
	("envDecay: " + envDecayVal).postln;
	~synths[synthNum].set(\env_decay, envDecayVal / 200);
};

~setArcState = {

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
	var currentEditRow = ~grid.rowInEditMode;
	// set dust freq
	if(currentEditRow != -1, {
		if(enc == 2, {
			var currentDustFreq = ~synthData.dustFreqs[currentEditRow];
			var newDustFreq = currentDustFreq + encDelta;
			~arc.setEncoderVal(enc, currentDustFreq);
			~arc.setFancyVal(enc, encDelta);
			~synthData.setDustFreq(currentEditRow, newDustFreq);
			~setDustFreq.value(currentEditRow, newDustFreq);
		});
		if(enc == 3, {
			var currentEnvDecay = ~synthData.envDecays[currentEditRow];
			var newEnvDecay = currentEnvDecay + encDelta;
			~arc.setEncoderVal(enc, currentEnvDecay);
			~arc.setFancyVal(enc, encDelta);
			~synthData.setEnvDecay(currentEditRow, newEnvDecay);
			~setEnvDecay.value(currentEditRow, newEnvDecay);
		});
	});
}, "/monome/enc/delta");


/* ###Initialize SynthDef */


SynthDef.new(\sineosc, { arg freq = 24.midicps, out = 0, dust_freq = 0.5, env_decay = 0.5, device = 0;
	var dust = Dust.kr(dust_freq);
	var env = Env([0.000001, 1, 0.000001], [0.01, env_decay], \exp).kr(0, dust);
	var sig = LFTri.ar(freq: freq);
	sig = sig * env;
	//Out.ar(out, FreeVerb2.ar(sig, sig, 0.8, 0.8, 0.1));
	Out.ar(out, sig!2);
	SendTrig.kr(dust, device);
}).add;




/* ###Initialize synths */


~synths = [
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

~synths[4].set(\dust_freq, 5)
~synths[4].get(\dust_freq, { | value |
	value.postln;
})