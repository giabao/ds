﻿/*
Copyright (c) 2008-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;
import haxe.ds.Vector;

using de.polygonal.ds.Bits;

/**
	<h3>An array data structure that compactly stores individual bits (boolean values).</h3>
	
	_<o>Worst-case running time in Big O notation</o>_
**/
class BitVector implements Hashable
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	var mBits:Vector<Int>;
	var mArrSize:Int;
	var mBitSize:Int;
	
	/**
		Creates a bit-vector capable of storing a total of `size` bits.
	**/
	public function new(size:Int)
	{
		mBits = null;
		mBitSize = 0;
		mArrSize = 0;
		
		resize(size);
		
		key = HashKey.next();
	}
	
	/**
		Destroys this object by explicitly nullifying the array storing the bits.
		<o>1</o>
	**/
	public function free()
	{
		mBits = null;
	}
	
	/**
		The exact number of bits that the bit-vector can store.
		<o>1</o>
	**/
	inline public function capacity():Int
	{
		return mBitSize;
	}
	
	/**
		The total number of bits set to one.
		<o>n</o>
	**/
	inline public function size():Int
	{
		var c = 0;
		for (i in 0...mArrSize)
			c += mBits[i].ones();
		return c;
	}
	
	/**
		The total number of 32-bit integers allocated for storing the bits.
		<o>1</o>
	**/
	inline public function bucketSize():Int
	{
		return mArrSize;
	}
	
	/**
		Returns true if the bit at index `i` is 1.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError index out of range (debug only).
	**/
	inline public function has(i:Int):Bool
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		return ((mBits[i >> 5] & (1 << (i & (32 - 1)))) >> (i & (32 - 1))) != 0;
	}
	
	/**
		Sets the bit at index `i` to one.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError index out of range (debug only).
	**/
	inline public function set(i:Int)
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		var p = i >> 5;
		mBits[p] = mBits[p] | (1 << (i & (32 - 1)));
	}
	
	/**
		Sets the bit at index `i` to zero.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError index out of range (debug only).
	**/
	inline public function clr(i:Int)
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		var p = i >> 5;
		mBits[p] = mBits[p] & (~(1 << (i & (32 - 1))));
	}
	
	/**
		Sets all bits in the bit-vector to zero.
		<o>n</o>
	**/
	inline public function clrAll()
	{
		for (i in 0...mArrSize) mBits[i] = 0;
	}
	
	/**
		Sets all bits in the bit-vector to one.
		<o>n</o>
	**/
	inline public function setAll()
	{
		for (i in 0...mArrSize) mBits[i] = -1;
	}
	
	/**
		Clears all bits in the range [`min`, `max`).
		
		This is faster than clearing individual bits by using the `clr` method.
		<o>n</o>
		@throws de.polygonal.ds.error.AssertError min out of range (debug only).
		@throws de.polygonal.ds.error.AssertError max out of range (debug only).
	**/
	public function clrRange(min:Int, max:Int)
	{
		assert(min >= 0 && min <= max && max < mBitSize, 'min/max out of range ($min/$max)');
		
		var current = min;
		
		while ( current < max )
		{
			var binIndex = current >> 5;
			var nextBound = (binIndex + 1) << 5;
			var mask = -1 << (32 - nextBound + current);
			mask &= (max < nextBound) ? -1 >>> (nextBound - max) : -1;
			mBits[binIndex] &= ~mask;
			
			current = nextBound;
		}
	}
	
	/**
		Sets all bits in the range [`min`, `max`).
		
		This is faster than setting individual bits by using the `set` method.
		<o>n</o>
		@throws de.polygonal.ds.error.AssertError min out of range (debug only).
		@throws de.polygonal.ds.error.AssertError max out of range (debug only).
	**/
	public function setRange(min:Int, max:Int)
	{
		assert(min >= 0 && min <= max && max < mBitSize, 'min/max out of range ($min/$max)');
		
		var current = min;
		
		while ( current < max )
		{
			var binIndex = current >> 5;
			var nextBound = (binIndex + 1) << 5;
			var mask = -1 << (32 - nextBound + current);
			mask &= (max < nextBound) ? -1 >>> (nextBound - max) : -1;
			mBits[binIndex] |= mask;
			
			current = nextBound;
		}
	}
	
	/**
		Sets the bit at index `i` to one if `cond` is true or clears the bit at index `i` if `cond` is false.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError index out of range (debug only) (debug only).
	**/
	inline public function ofBool(i:Int, cond:Bool)
	{
		cond ? set(i) : clr(i);
	}
	
	/**
		Returns the bucket at index `i`.
		
		A bucket is a 32-bit integer for storing the bit flags.
		@throws de.polygonal.ds.error.AssertError `i` out of range (debug only).
	**/
	inline public function getBucketAt(i:Int):Int
	{
		assert(i >= 0 && i < mArrSize, 'i index out of range ($i)');
		
		return mBits[i];
	}
	
	/**
		Writes all buckets to `output`.
		
		A bucket is a 32-bit integer for storing the bit flags.
		@return the total number of buckets.
	**/
	inline public function getBuckets(output:Array<Int>):Int
	{
		var t = mBits;
		for (i in 0...mArrSize) output[i] = t[i];
		return mArrSize;
	}
	
	/**
		Resizes the bit-vector to `x` bits.
		
		Preserves existing values if the new size > old size.
		<o>n</o>
	**/
	public function resize(x:Int)
	{
		if (mBitSize == x) return;
		
		var newSize = x >> 5;
		if ((x & (32 - 1)) > 0) newSize++;
		
		if (mBits == null)
		{
			mBits = new Vector(newSize);
			
			for (i in 0...newSize) mBits[i] = 0;
		}
		else
		if (newSize < mArrSize)
		{
			mBits = new Vector(newSize);
			
			for (i in 0...newSize) mBits[i] = 0;
		}
		else
		if (newSize > mArrSize)
		{
			var t = new Vector<Int>(newSize);
			Vector.blit(mBits, 0, t, 0, mArrSize);
			for (i in mArrSize...newSize) t[i] = 0;
			mBits = t;
		}
		else if (x < mBitSize)
		{
			for (i in 0...newSize) mBits[i] = 0;
		}
		
		mBitSize = x;
		mArrSize = newSize;
	}
	
	/**
		Writes the data in this bit-vector to a byte array.
		
		The number of bytes equals `bucketSize()` * 4 and the number of bits equals `capacity()`.
		<o>n</o>
		@param bigEndian the byte order (default is little endian)
	**/
	public function toBytes(bigEndian = false):haxe.io.BytesData
	{
		#if flash
		var output = new flash.utils.ByteArray();
		if (!bigEndian) output.endian = flash.utils.Endian.LITTLE_ENDIAN;
		for (i in 0...mArrSize)
			output.writeInt(mBits[i]);
		return output;
		#else
		var output = new haxe.io.BytesOutput();
		output.bigEndian = bigEndian;
		for (i in 0...mArrSize)
			output.writeInt32(mBits[i]);
		return output.getBytes().getData();
		#end
	}
	
	/**
		Copies the bits from `bytes` into this bit vector.
		
		The bit-vector is resized to the size of `bytes`.
		<o>n</o>
		@param bigEndian the input byte order (default is little endian)
		@throws de.polygonal.ds.error.AssertError `input` is null (debug only).
	**/
	public function ofBytes(bytes:haxe.io.BytesData, bigEndian = false)
	{
		#if flash
		var input = bytes;
		input.position = 0;
		if (!bigEndian) input.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#else
		var input = new haxe.io.BytesInput(haxe.io.Bytes.ofData(bytes));
		input.bigEndian = bigEndian;
		#end
		
		var k =
		#if neko
		neko.NativeString.length(bytes);
		#else
		bytes.length;
		#end
		
		var numBytes = k & 3;
		var numIntegers = (k - numBytes) >> 2;
		mArrSize = numIntegers + (numBytes > 0 ? 1 : 0);
		mBitSize = mArrSize << 5;
		mBits = new Vector<Int>(mArrSize);
		for (i in 0...mArrSize) mBits[i] = 0;
		for (i in 0...numIntegers)
		{
			#if flash
			mBits[i] = input.readInt();
			#elseif cpp
			mBits[i] = (cast input.readInt32()) & 0xFFFFFFFF;
			#else
			mBits[i] = cast input.readInt32();
			#end
		}
		var index = numIntegers << 5;
		var shift = 0, t = 0;
		for (i in 0...numBytes)
		{
			var b = input.readByte();
			for (j in 0...8)
			{
				if ((b & 1) == 1) set(index);
				b >>= 1;
				index++;
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var bv = new de.polygonal.ds.BitVector(40);
		for (i in 0...bv.capacity()) {
		    if (i & 1 == 0) {
		        bv.set(i);
		    }
		}
		trace(bv);</pre>
		<pre class="console">
		{ BitVector set/all: 20/40 }
		[
		  0 -> b01010101010101010101010101010101
		  1 -> b00000000000000000000000001010101
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ BitVector set/all: ${size()}/${capacity()} }';
		if (size() == 0) return s;
		s += "\n[\n";
		for (i in 0...mArrSize)
			s += Printf.format("  %4d -> %#.32b\n", [i, mBits[i]]);
		s += "]";
		return s;
	}
	
	/**
		Creates a copy of this bit vector.
		<o>n</o>
	**/
	public function clone():BitVector
	{
		var copy = new BitVector(mBitSize);
		var t = copy.mBits;
		Vector.blit(mBits, 0, copy.mBits, 0, mArrSize);
		return copy;
	}
}