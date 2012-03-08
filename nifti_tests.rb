# Requirements
require "nifti"
require "hoe"
require "inline"
require 'png'

CursorColor = PNG::Color::Green
SegColor = PNG::Color::Red

# Get indices from nifti files
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

def read_file(orientation,layer,filepath)
  h = {"orientation" => orientation, "data" => {"brain" => {},"stats" => {} }}
  nobj = NIFTI::NObject.new(filepath, :narray => true)
  # Get image dimensions
  width = nobj.header["dim"][1]
  height = nobj.header["dim"][2]
  # Get image
  nobj_img = nobj.image  
  # Fill hash
  h["data"][layer]["image_data"] = nobj_img
  h["data"][layer]["dims"] = [width,height]
  return h
end

def create_canvas(hash)
  width = hash["data"]["brain"]["dims"][0]
  height = hash["data"]["brain"]["dims"][1]
  # Create canvas
  canvas = PNG::Canvas.new(width, height)
end

def fill_canvas(brain_hash,stats_hash,canvas)
  # Load brain pixel intensities to canvas
  brainimg = brain_hash["data"]["brain"]["image_data"]
  statsimg = stats_hash["data"]["stats"]["image_data"]
  brainimg.indices do |n,m|
    val=(brainimg[n,m])
    canvas[n,m] = PNG::Color.new(val,val,val)
  end
  statsimg.indices do |n,m|
    val=(statsimg[n,m])
    canvas[n,m] = SegColor if val != 0
  end
  return canvas
end

def fill_crosshair(center=[200,200],size=50,canvas)
  arm = (size/2).floor.to_i
  xstart = center[0]-arm
  xend = center[0]+arm
  ystart = center[1]-arm
  yend = center[1]+arm
  canvas.line xstart, center[1], xend, center[1], CursorColor # Horizontal
  canvas.line center[0], ystart, center[0], yend, CursorColor # Vertical
  return canvas
end

def generate_png(brain_hash,stats_hash, crosshair_center, crosshair_size)
  # Create canvas
  canvas = create_canvas(brain_hash)
  # Fill canvas
  comp_canvas = fill_canvas(brain_hash,stats_hash,canvas)
  # Fill cursor
  cursor_comp_canvas = fill_crosshair(crosshair_center,crosshair_size, comp_canvas)

  # Create PNG
  png = PNG.new cursor_comp_canvas
  filename = brain_hash["orientation"] + ".png"
  png.save filename
end
############## END METHODS ###############

# Read files:
axial_brain_hash = read_file("axial","brain","samples/slice_76.nii")
axial_stats_hash = read_file("axial","stats","samples/slice_76_stats.nii")

axial_hipocenter = [140,250] # donde colocar el crosshairs para esa proyeccion, sacado del archivo generado, por ahora hardcoded
crosshair_size = 50

# Create PNG
generate_png(axial_brain_hash,axial_stats_hash, axial_hipocenter, crosshair_size)