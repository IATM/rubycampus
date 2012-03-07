require "nifti"
require "hoe"
require "inline"

require 'png'

class NArray
  # returns all the indices to access the values of the NArray.  if start == 1,
  # then the first dimension (row) values are not returned, if start == 2,
  # then the first two dimensions are skipped.
  #
  # if a block is provided, the indices are yielded one at a time
  # [obviously, this could be made into a fast while loop instead of
  # recursive ... someone have at it]
  def indices(start=0, ar_of_indices=[], final=[], level=shape.size-1, &block)
    if level >= 0
      (1...(shape[level])).each do |s|
        new_indices = ar_of_indices.dup
        new_indices.unshift(s)
        if (new_indices.size == (shape.size - start))
          block.call(new_indices)
          final << new_indices 
        end
        indices(start, new_indices, final, level-1, &block)
      end
    end
    final
  end
end

# Read file:
obj = NIFTI::NObject.new("samples/slice_76.nii", :narray => true)

width = obj.header["dim"][1]
height = obj.header["dim"][2]

narr = obj.image

canvas = PNG::Canvas.new(width, height)

narr.indices do |n,m|
  val=(narr[n,m])
  canvas[n,m] = PNG::Color.new(val,val,val)
end
canvas.line 50, 200, 300, 200, PNG::Color::Green
canvas.line 200, 100, 200, 350, PNG::Color::Green

png = PNG.new canvas
png.save 'test.png'