MonomeGrid {
	var device, <>pitchValues, <>octaveValues, <>rowInEditMode;

	*new { | gridDevice |
		^super.new.init(gridDevice);
	}


	init { | gridDevice |
		device = gridDevice;
		pitchValues = [0,0,0,0,0,0,0,0];
		octaveValues = [1,1,1,1,1,1,1,1];
		rowInEditMode = -1;
	}


	displayRow { | row |
		var fillRowBefore, fillRowAfter, toFill, setRow;

		fillRowBefore = Array.fill(pitchValues[row], 2);
		toFill = 15 - fillRowBefore.size;
		fillRowAfter = Array.fill(toFill, 0);
		setRow = fillRowBefore ++ Array.with(8) ++ fillRowAfter;
		device.levrow(0,row,setRow);
	}


	displayEditRow { | row |
		var fillActiveOctave, fillOctaveAfter, setRow;

		fillActiveOctave = Array.fill(octaveValues[row], 10);
		fillOctaveAfter = Array.fill(15 - fillActiveOctave.size, 4);
		setRow = fillActiveOctave ++ fillOctaveAfter ++ Array.with(0);
		~m.levrow(0,row,setRow);
	}


	setPitch { | row, xpos |
		pitchValues[row] = xpos;
		this.displayRow(row);
	}


	setOctave { | row, octave |
		if(rowInEditMode == row,
			{
				if(octave > 5, {
					octave = 5;
				});
				octaveValues[row] = octave;
				this.displayEditRow(row);
			}
		);
	}
}