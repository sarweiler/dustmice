MonomeArc {
	var device, <>brightness, <>resolution, <>encoderValues;

	*new { | arcDevice |
		^super.new.init(arcDevice);
	}


	init { | arcDevice |
		device = arcDevice;
		brightness = 8;
		resolution = 1024;
		encoderValues = [0, 0, 0, 0];
	}

	setSimpleVal { | enc, deltaVal |
		var val = this.prCalculateVisualEncoderVal(enc, deltaVal);

		this.prUpdateEncoderVal(enc, deltaVal);

		if(val <= 0, {
			device.ringall(enc, 0);
		}, {
			device.ringrange(enc, 0, val, brightness);
			if(val < 63, {
				device.ringrange(enc, val + 1, 63, 0);
			});
		});
	}

	setFancyVal { | enc, deltaVal |
		var val = this.prCalculateVisualEncoderVal(enc, deltaVal);
		var arrayPart1, arrayPart2, arrayFill, setArc;
		var arrayHalfSize = (val / 2).ceil;
		var arrayFall = [brightness - 2, brightness - 4, brightness - 6];
		var arrayRise = [brightness - 6, brightness - 4, brightness - 2];

		this.prUpdateEncoderVal(enc, deltaVal);

		if((val > 2) && (val <= 4), {
			arrayFall = arrayFall[1..2];
			arrayRise = arrayRise[0..1];
		});

		if((val <= 2), {
			arrayFall = arrayFall[2..2];
			arrayRise = arrayRise[0..0];
		});

		if(val <= 0, {
			device.ringmap(enc, Array.fill(64, 0));
		}, {
			arrayPart1 = Array.fill((arrayHalfSize - arrayFall.size.min(3)).max(0), brightness);
			arrayPart2 = Array.fill((arrayHalfSize - arrayRise.size.min(3)).max(0), brightness);
			arrayFill = Array.fill(64 - (arrayHalfSize * 2), 0);

			setArc = arrayPart1 ++ arrayFall ++ arrayFill ++ arrayRise ++ arrayPart2;

			device.ringmap(enc, setArc);
		});
	}


	/* Private methods */

	prCalculateEncVal { | enc, deltaVal |
		^((deltaVal + encoderValues[enc]).min(resolution - 1).max(0));
	}

	prUpdateEncoderVal { | enc, deltaVal |
		var encVal = this.prCalculateEncVal(enc, deltaVal);
		encoderValues[enc] = encVal;
	}

	prCalculateVisualEncoderVal { | enc, deltaVal |
		var encVal = this.prCalculateEncVal(enc, deltaVal);
		^((encVal / (resolution / 64)).max(0));
	}

}