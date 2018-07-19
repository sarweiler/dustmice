SynthData {
	var <>dustFreqs, <>envDecays;

	*new {
		^super.new.init();
	}


	init { | arcDevice |
		dustFreqs = [50, 50, 50, 50, 50, 50, 50, 50];
		envDecays = [50, 50, 50, 50, 50, 50, 50, 50];
	}

	setDustFreq { | synthNum, dustFreqValue |
		dustFreqs[synthNum] = dustFreqValue;
	}

	setEnvDecay { | synthNum, envDecayValue |
		envDecays[synthNum] = envDecayValue;
	}
}