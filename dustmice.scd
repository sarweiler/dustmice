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

~gridPitchValues = [0,0,0,0,0,0,0,0];
~gridOctaveValues = [1,1,1,1,1,1,1,1];
~gridRowInEditMode = [0,0,0,0,0,0,0,0]; // TODO: Boolean

~octaves = [24,36,48,60,72];

~keysHeld = 0;

~initGrid = {
	~gridPitchValues.do({ | xpos, row |
		~m.levrow(0,row,[8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	})
};

~initGrid.value;

~gridSetPitch = { | row, xpos |
	~gridDisplayRow.value(row);
	~gridPitchValues[row] = xpos;
	~setPitch.value(row, ~gridOctaveValues[row], ~gridPitchValues[row]);
};

~gridSetOctave = { | row, octave |
	if(~gridRowInEditMode[row] == 1,
		{
			if(octave > 5, {
				octave = 5;
			});
			~gridOctaveValues[row] = octave;
			~gridDisplayEditRow.value(row);
			~setPitch.value(row, ~gridOctaveValues[row], ~gridPitchValues[row]);
		}
	)
};

~gridDisplayRow = { | row |
	var fillRowBefore;
	var fillRowAfter;
	var toFill;
	var setRow;

	fillRowBefore = Array.fill(~gridPitchValues[row], 2);
	toFill = 15 - fillRowBefore.size;
	fillRowAfter = Array.fill(toFill, 0);
	setRow = fillRowBefore ++ Array.with(8) ++ fillRowAfter;
	~m.levrow(0,row,setRow);
};

~gridDisplayEditRow = { | row |
	var fillActiveOctave, fillOctaveAfter, setRow;

	fillActiveOctave = Array.fill(~gridOctaveValues[row], 10);
	fillOctaveAfter = Array.fill(15 - fillActiveOctave.size, 4);
	setRow = fillActiveOctave ++ fillOctaveAfter ++ Array.with(0);
	~m.levrow(0,row,setRow);
};

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
		{ ~gridSetPitch.value(gridY, gridX); },
		{
			// TODO: Check if edit mode active, not if 2 buttons held => Array.collect?
			if((buttonDown == 1) && (~keysHeld == 1),
				{
					~gridRowInEditMode[gridY] = 1;
					~gridDisplayEditRow.value(gridY);
				},
				{
					if(~keysHeld == 0, {
						~gridRowInEditMode[gridY] = 0;
						~gridDisplayRow.value(gridY);
					});

				}
			);

			if((~keysHeld == 2) && (~gridRowInEditMode[gridY] == 1),
				{ ~gridSetOctave.value(gridY, gridX + 1); }
			);
		}
	);

	message.postln;
	~keysHeld.postln;
	//~m.ledset(message[1], message[2], message[3]);
	//~m.levset(message[1] - 1, message[2], 6);

}, "/monome/grid/key");


// ARC
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
	var xpos = ~gridPitchValues[row];
	if(~gridRowInEditMode[row] == 0, {
		~m.levset(xpos,row, 12);
		SystemClock.sched(0.1, {
			~m.levset(xpos,row, 8);
		});
	});
}, "/tr", s.addr);
)


~m.ledall(0);
~m.levrow(0,2,[2,2,2,2,2,2,8]);
~m.levrow(0, 2, [ 8, 8, 15, 2, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ]);


//
//
// legacy midi stuff
//
//

MIDIClient.init;
MIDIIn.connectAll;

(
MIDIFunc.cc({ |val, deviceNum, chan, src|
	if((deviceNum >= 0) && (deviceNum <= 7), {
		"FADE".postln;
		"val: " + val.postln;
		"num: " + deviceNum.postln;
		"chan: " + chan.postln;
		"src: " + src.postln;
		"-----".postln;

		~snths[deviceNum].set(
			\dust_freq, val / 8
		);
	})
});

MIDIFunc.cc({ |val, deviceNum, chan, src|
	if((deviceNum >= 16) && (deviceNum <= 23), {
		deviceNum = deviceNum - 16;
		"KNOB".postln;
		"val: " + val.postln;
		"num: " + deviceNum.postln;
		"chan: " + chan.postln;
		"src: " + src.postln;
		"-----".postln;

		~snths[deviceNum].set(
			\freq, val * 8
		);
	});
});
)
