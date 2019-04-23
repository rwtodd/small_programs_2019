#pragma once

#include<cstddef>
#include<valarray>

namespace rwt::spiral {

	std::valarray<int> make_spiral (std::size_t size, int init_val, int incr);
	int is_prime (int x);

}