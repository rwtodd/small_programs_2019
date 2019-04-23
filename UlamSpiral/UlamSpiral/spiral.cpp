#include "stdafx.h"
#include "spiral.h"
#include<cstdint>

namespace
{
	std::pair<std::size_t, std::size_t> center_loc (std::size_t size)
	{
		std::size_t half = size / 2;
		return std::make_pair (half - ((size & 1) ? 0 : 1), half);
	}

	// Utility function to do modular exponentiation. 
	// It returns (x^y) % p 
	std::uint64_t power (std::uint64_t x, std::uint64_t y, std::uint64_t p)
	{
		std::uint64_t res = 1;      // Initialize result 
		x = x % p;  // Update x if it is more than or 
					// equal to p 
		while (y > 0)
		{
			// If y is odd, multiply x with result 
			if (y & 1)
				res = (res*x) % p;

			// y must be even now 
			y = y >> 1; // y = y/2 
			x = (x*x) % p;
		}
		return res;
	}

	// This function is called for all k trials. It returns 
	// false if n is composite and returns false if n is 
	// probably prime. 
	// d is an odd number such that  d*2<sup>r</sup> = n-1 
	// for some r >= 1 
	bool millerTest (std::uint64_t d, std::uint64_t n)
	{
		// Pick a random number in [2..n-2] 
		// Corner cases make sure that n > 4 
		std::uint64_t a = 2 + rand () % (n - 4);

		// Compute a^d % n 
		std::uint64_t x = power (a, d, n);

		if (x == 1 || x == n - 1)
			return true;

		// Keep squaring x while one of the following doesn't 
		// happen 
		// (i)   d does not reach n-1 
		// (ii)  (x^2) % n is not 1 
		// (iii) (x^2) % n is not n-1 
		while (d != n - 1)
		{
			x = (x * x) % n;
			d *= 2;

			if (x == 1)      return false;
			if (x == n - 1)    return true;
		}

		// Return composite 
		return false;
	}

	// It returns false if n is composite and returns true if n 
	// is probably prime.  k is an input parameter that determines 
	// accuracy level. Higher value of k indicates more accuracy. 
	bool isPrime (std::uint64_t n, int k)
	{
		// Corner cases 
		if (n <= 1 || n == 4)  return false;
		if (n <= 3) return true;

		// Find r such that n = 2^d * r + 1 for some r >= 1 
		std::uint64_t d = n - 1;
		while (d % 2 == 0)
			d /= 2;

		// Iterate given nber of 'k' times 
		for (int i = 0; i < k; i++)
			if (!millerTest (d, n))
				return false;

		return true;
	}
}

// make a spiral with 'size' rows and 'size' columns
std::valarray<int>
rwt::spiral::make_spiral (std::size_t size, int init_val, int incr)
{
	// initialize a result valarray
	std::size_t end = size * size;
	std::valarray<int> result (end);
	
	// set the center value
	auto center = center_loc (size);
	std::size_t loc = center.first + center.second*size;
	result[loc] = init_val;
	// loop around and around until we fall out of bounds
	for(std::size_t turn = 0; /*infinite*/; ++turn)
	{
		std::size_t len = (turn >> 1) + 1;
		std::size_t direction = ((turn & 1) ? size : 1) * (((turn + 1) & 2) ? -1 : 1);

		for (std::size_t idx = 0; idx < len; ++idx)
		{
			loc += direction;
			init_val += incr;
			if ((loc < 0) || (loc >= end)) goto done;
			result[loc] = init_val;
		}
	}
	done:
	return result;
}

int rwt::spiral::is_prime (int x)
{
	return isPrime(x,20)?1:0;
}