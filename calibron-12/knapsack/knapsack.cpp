// knapsack.cpp : This is a program to brute-force the Calibron 12 puzzle via a backtracking
// search.  https://www.amazon.com/Calibron-12-Brain-Teaser-Difficult/dp/B00A7EZX74
// I immediately recognized it as having the flavor of NP-Complete problems like knapsack 
// and subset-sum, so I didn't try to find a more elegant approach. 
//
// I wrote it in C++ because I feared the search might take a long time, but it actually found
// a solution in seconds, the first time I tried to run it (in debug mode from the IDE)!  When I ran
// it in Release mode, it returned in a fraction of a second.
//
// So, probably a python solution would have been quicker to write and would have sufficed.
// Oh well!  This was still a fun exercise in premature optimization.  I was actaully thinking
// about changing out the vectors in the recursive calls for stack-allocated arrays, to save
// more time, but that's clearly pointless now.

#include "pch.h"
#include <iostream>
#include<algorithm>
#include<vector>

// the blocks have a width and height. For laughs, let's hold it in a single 16-bit value
// to make copies ultra-cheap.
class Block
{
private:
	uint16_t data;
    Block(uint16_t d): data(d) {}
public:
	Block &operator=(const Block &other)
	{
		data = other.data;  
		return *this;
	}

	Block (uint8_t w, uint8_t h) : data( (static_cast<uint16_t>(w) << 8) | h ) {}
	Block transpose () const { return Block( (data << 8)|(data >> 8) ); }
	inline uint8_t height () const { return data & 0xff; }
	inline uint8_t width () const { return data >> 8; }
};

// X,Y pair... same as blocks, let's map the data into a 16-bit value to make copies
// painless.
class Position
{
private:
	const uint16_t data;
public:
	Position (uint8_t x, uint8_t y) : data ((static_cast<uint16_t>(x) << 8) | y) {}
	inline uint8_t y () const { return data & 0xff; }
	inline uint8_t x () const { return data >> 8; }
	inline bool done () const { return y() >= 56;  }
};


// The board is 56x56, but I'll make it 64x57 with a full row at the end so that
// I don't have to check the bounds manually.
class Board
{
private:
	// ~ (2^56 - 1)
	static const uint64_t EMPTY_ROW = ~UINT64_C (72057594037927935);
	static const uint64_t FULL_ROW = ~UINT64_C (0);

	uint64_t bitmap[57]; // 56 rows plus 1 buffer to streamline logic.

	static constexpr uint64_t widths[33] =
	{
	  UINT64_C (0),  // 2^0 - 1 ... etc..
	  UINT64_C (1),
	  UINT64_C (3),
	  UINT64_C (7),
	  UINT64_C (15),
	  UINT64_C (31),
	  UINT64_C (63),
	  UINT64_C (127),
	  UINT64_C (255),
	  UINT64_C (511),
	  UINT64_C (1023),
	  UINT64_C (2047),
	  UINT64_C (4095),
	  UINT64_C (8191),
	  UINT64_C (16383),
	  UINT64_C (32767),
	  UINT64_C (65535),
	  UINT64_C (131071),
	  UINT64_C (262143),
	  UINT64_C (524287),
	  UINT64_C (1048575),
	  UINT64_C (2097151),
	  UINT64_C (4194303),
	  UINT64_C (8388607),
	  UINT64_C (16777215),
	  UINT64_C (33554431),
	  UINT64_C (67108863),
	  UINT64_C (134217727),
	  UINT64_C (268435455),
	  UINT64_C (536870911),
	  UINT64_C (1073741823),
	  UINT64_C (2147483647),
	  UINT64_C (4294967295)
	};

public:
	Board ()
	{
		std::fill (std::begin (bitmap), std::end (bitmap), EMPTY_ROW);
		bitmap[56] = FULL_ROW;
	}

	// see if a block fits at `p`, and place it there if so. Return success/fail.
	bool check_and_set (const Block &b, const Position &p)
	{
		const auto wmap = widths[b.width ()];
		const auto x = p.x ();
		const auto beg = &bitmap[p.y ()];
		const auto end = &(bitmap[std::min(p.y () + b.height (), 57)]);
		auto found = std::find_if (beg, end, 
									[&](uint64_t b) { return ((wmap << x) & b) != 0; });
		if (found == end)
		{
			std::transform (beg, &bitmap[p.y () + b.height ()], beg,
							[&](uint64_t b) { return ((wmap << x) | b); });
			return true;
		}
		return false;
	}

	// clear a block from position p
	void clear (const Block &b, const Position &p)
	{
		const auto wmap = widths[b.width ()];
		const auto x = p.x ();
		const auto beg = &bitmap[p.y ()];
		std::transform (beg, &bitmap[p.y () + b.height ()], beg,
							[&](uint64_t b) { return (~(wmap << x) & b); });
	}

	// identify the upper-leftmost empty location after `cur`.
	Position
	next_free (const Position &cur) const
	{
		auto x = cur.x ();
		auto y = cur.y ();
		while (y < 56)
		{
			while (x < 56)
			{
				if (((widths[1] << x) & bitmap[y]) == 0) goto done;
				++x;
			}
			++y; x = 0;
		}
	done:
		return Position{ x, y };
	}

};

void report (const Position &pos, const Block &b)
{
	std::cout << "Block[" << static_cast<int>(b.width ()) << "x" << static_cast<int>(b.height ()) << 
		"] at [" << static_cast<int>(pos.x ()) << "," << static_cast<int>(pos.y ()) << "]" << std::endl;
}

bool
iterate (Board &b, Position pos, const std::vector<Block> & blocks)
{
	auto beg = blocks.begin ();
	auto cur = *beg++;
	std::vector<Block> remaining{ beg, blocks.end () };
	auto extras = remaining.size ();
	size_t replace_idx = 0;
	
	while (true)
	{
		// Phase 1... try to place the piece one way...
		if (b.check_and_set (cur, pos))
		{
			Position next_pos = b.next_free (pos);
			if ((extras == 0) || iterate (b, next_pos, remaining))
			{
				report (pos, cur);
				return true;
			}
			else
			{
				b.clear (cur, pos);
			}
		}
	
		// Phase 2.. try to place the piece transposed...
		cur = cur.transpose ();
		if (b.check_and_set (cur, pos))
		{
			Position next_pos = b.next_free (pos);
			if ((extras == 0) || iterate (b, next_pos, remaining))
			{
				report (pos, cur);
				return true;
			}
			else
			{
				b.clear (cur, pos);
			}
		}

		// swap for the next iteration...
		if (replace_idx >= extras) break;
		auto tmp = remaining[replace_idx];
		remaining[replace_idx] = cur;
		cur = tmp;
		++replace_idx;
	}
	return false; // no more options!
}


int main()
{
	std::vector<Block> blockset{
		Block (21,14), Block (21,18), Block (10,7), Block (17,14),
		Block (28,7), Block (28,14), Block (32,10), Block (14,4), Block (28,6), Block (32,11),
		Block (21,18), Block (21,14)
	};
	Board board;
	iterate (board, Position (0, 0), blockset);
	return 0;
}
