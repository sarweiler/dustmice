s.boot
s.scope

//
// INITIALIZE GRID
//
(
~m = MonoM.new("/monome", 0);
~m.useDevice(0);
~m.darkness;

// GRID
~grid = MonomeGrid.new(~m);

~octaves = [24,36,48,60,72];
~keysHeld = 0;

~initGrid = {
	~grid.pitchValues.do({ | xpos, row |
		~m.levrow(0,row,[8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	})
};

~initGrid.value;

~setPitch = { | synthNum, octave, note |
	var frequency = ~calcPitch.value(octave, note);
	"oct: " + octave.postln;
	frequency.postln;
	~snths[synthNum].set(\freq, frequency);
};

~calcPitch = { | oct, note |
	var midiNote = ~octaves[oct - 1] + note;
	midiNote.midicps;
};

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
			row.postln;
			gridX.postln;
			~grid.setPitch(row, gridX);
			~setPitch.value(row, ~grid.octaveValues[row], ~grid.pitchValues[row]);
		},
		{
			// TODO: Check if edit mode active, not if 2 buttons held => Array.collect?
			if((buttonDown == 1) && (~keysHeld == 1),
				{
					var rowInEditMode = ~grid.rowInEditMode;
					rowInEditMode[gridY] = 1;
					~grid.rowInEditMode_(rowInEditMode);
					~grid.displayEditRow(gridY);
				},
				{
					if(~keysHeld == 0, {
						var rowInEditMode = ~grid.rowInEditMode;
						rowInEditMode[gridY] = 0;
						~grid.rowInEditMode_(rowInEditMode);
						~grid.displayRow(gridY);
					});

				}
			);

			if((~keysHeld == 2) && (~grid.rowInEditMode[gridY] == 1),
				{
					var row = gridY;
					~grid.setOctave(gridY, gridX + 1);
					~setPitch.value(row, ~grid.octaveValues[row], ~grid.pitchValues[row]);
				}
			);
		}
	);

	message.postln;
	~keysHeld.postln;

}, "/monome/grid/key");


// ARC
/*
~a = Arc.new("/monome", 0);
~a.useDevice(1);
~a.darkness;

~arcResolution = 1024;
~arcBrightness = 8;
~arcEncoderValues = [0,0,0,0];

~arcSetSimpleVal = { | enc, val |
	if(val <= 0, {
		~a.darkness;
	}, {
		~a.ringrange(enc, 0, val, ~arcBrightness);
		if(val < 63, {
			~a.ringrange(enc, val + 1, 63, 0);
		});
	});
};

~arcSetFancyVal = { | enc, val |
	var arrayPart1, arrayPart2, arrayFill, setArc;
	var arrayHalfSize = (val / 2).ceil;
	var arrayFall = [~arcBrightness - 2, ~arcBrightness - 4, ~arcBrightness - 6];
	var arrayRise = [~arcBrightness - 6, ~arcBrightness - 4, ~arcBrightness - 2];

	("enc val: " + val).postln;

	if((val > 2) && (val <= 4), {
		arrayFall = arrayFall[1..2];
		arrayRise = arrayRise[0..1];
	});

	if((val <= 2), {
		arrayFall = arrayFall[2..2];
		arrayRise = arrayRise[0..0];
	});

	if(val <= 0, {
		~a.ringmap(enc, Array.fill(64, 0));
	}, {
		arrayPart1 = Array.fill((arrayHalfSize - arrayFall.size.min(3)).max(0), ~arcBrightness);
		arrayPart2 = Array.fill((arrayHalfSize - arrayRise.size.min(3)).max(0), ~arcBrightness);
		arrayFill = Array.fill(64 - (arrayHalfSize * 2), 0);

		("arr1 size: " + arrayPart1.size).postln;
		("arr2 size: " + arrayPart2.size).postln;

		setArc = arrayPart1 ++ arrayFall ++ arrayFill ++ arrayRise ++ arrayPart2;

		("setArc size: " + setArc.size).postln;
		arrayFall.postln;
		arrayRise.postln;
		setArc.postln;

		~a.ringmap(enc, setArc);
	});
};


OSCFunc.newMatching({ | message |
	var enc = message[1];
	var encDelta = message[2];
	var encVal = (encDelta + ~arcEncoderValues[enc]).min(~arcResolution - 1).max(0);
	var encVisualVal = (encVal / (~arcResolution / 64)).max(0);
	~arcEncoderValues[enc] = encVal;
	encVisualVal.floor.postln;

	~arcSetFancyVal.value(enc, encVisualVal.floor);
}, "/monome/enc/delta");
*/
)


//
// INITIALIZE SYNTHDEF
//
(
SynthDef.new(\sineosc, { arg freq = 24.midicps, out = 0, dust_freq = 0.5, device = 0;
	var dust = Dust.kr(dust_freq);
	var env = Env([0.000001, 1, 0.000001], [0.1, 1], \exp).kr(0, dust);
	Out.ar(out, FreeVerb2.ar(LFTri.ar(freq, 0, 0.2) * env, SinOsc.ar(freq, 0, 0.2) * env, 0.8, 0.8, 0.1));
	SendTrig.kr(dust, device);
}).add;
)

//
// INITIALIZE SYNTHS
//
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

// visual feedback
OSCFunc.newMatching({ | message, time |
	var row = message[2];
	var xpos = ~grid.pitchValues[row];
	if(~grid.rowInEditMode[row] == 0, {
		~m.levset(xpos,row, 12);
		SystemClock.sched(0.1, {
			~m.levset(xpos,row, 8);
		});
	});
}, "/tr", s.addr);
)

