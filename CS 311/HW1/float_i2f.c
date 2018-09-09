// George Petrou, gzp3@psu.edu
#include "float_i2f.h"

unsigned power(unsigned base, unsigned pow) {
	if (pow == 0)
		return 1;	

	return base * power(base, pow - 1);
}

float_bits float_i2f(int input) {
	const unsigned SIGN_BIT = 31;
	const unsigned EXP_BITS = 23;
	const unsigned FRAC_MASK = 0x7FFFFF;
	const unsigned BIAS = 127;

	float_bits sign = 0, exp = 0, frac = 0;

	// Sign
	// Bit 31.
	if (input < 0) {
		sign = 1;
		input = -input;
	} else if (input == 0)
		return 0;

	// Exponent
	// Bits 30 - 23
	int expInput = input;
	unsigned expStartBitNumber = 0;
	exp = 0;
	while (expInput >>= 1)
		expStartBitNumber++;
	exp = expStartBitNumber + BIAS;

	// Fraction
	// Bits 22 - 0
	if (expStartBitNumber > EXP_BITS) {
		unsigned numResidueBits = expStartBitNumber - EXP_BITS;
		unsigned residue = input & (power(2, numResidueBits)-1);

		int fracInput = input;
		unsigned fractionCap = power(2, expStartBitNumber);
		unsigned fracRaw = (fracInput & (fractionCap-1)) >> numResidueBits;

		if (residue != 0) {
			unsigned residueCap = power(2, numResidueBits);
		
			// Round up.
			if (residue << 1 > residueCap) {
				frac = (fracRaw + 1) & FRAC_MASK;
				if (frac == 0)
					exp++;

			// Round to even or odd.
			} else if (residue << 1 == residueCap) {
				if (fracRaw & 0x1) {
					frac = (fracRaw + 1) & FRAC_MASK;
					if (frac == 0)
						exp++;
				} else {
					frac = fracRaw & FRAC_MASK;
				}
			
			// Round down.
			} else {
				frac = fracRaw & FRAC_MASK;
			}
		} else
			frac = fracRaw & FRAC_MASK;	// No need to worry about rounding.
	} else {
		frac = (input << (EXP_BITS - expStartBitNumber)) & FRAC_MASK;
	}

	return (sign << SIGN_BIT) | (exp << EXP_BITS) | (frac);
}
