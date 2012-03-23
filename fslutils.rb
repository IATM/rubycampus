#!/usr/bin/env ruby

# Requirements
require "nifti"
require "hoe"
require "inline"
require 'png'
require 'prawn'

CursorColor = PNG::Color::Green
SegColor = PNG::Color::Red
PatientName = 'Gabriel Castrillon'
PatientID = 'CC79589827'
PatientBirthdate = '12/11/1990'
StudyDate = '03/20/2012'
AccessionNo = '0033453775'

# Bring OptionParser into the namespace
require 'optparse'
options = {}
option_parser = OptionParser.new do |opts|
  
  # Create a flag
  opts.on("-b BRAIN") do |brain| 
    options[:brain] = brain
  end
  
  opts.on("-s STATS") do |stats| 
    options[:stats] = stats
  end 
end

option_parser.parse!
puts options.inspect

coord = `fslstats -t #{options[:stats]} -C`.split


lh = {}
rh = {}
axis = ["x", "y", "z"]

(0..2).each do |i|
  lh[axis[i]] = coord[i].to_i.round
end

(3..5).each do |i|
  rh[axis[i-3]] = coord[i].to_i.round
end

puts lh.inspect

def fsl_roi(file, structure, x, y, z)
  basename = File.basename(file, '.nii.gz')
  dirname = File.dirname(file)
  filenames = {}
  filenames[:ax] = fn(dirname, basename, structure, 'axial')
  filenames[:sag] = fn(dirname, basename, structure, 'sag')
  filenames[:cor] = fn(dirname, basename, structure, 'cor')
  `fslroi #{file} #{filenames[:sag]} #{x} 1 0 -1 0 -1`
  `fslswapdim #{filenames[:sag]} y z x #{filenames[:sag]}`
  
  `fslroi #{file} #{filenames[:cor]} 0 -1 #{y} 1 0 -1`
  `fslswapdim #{filenames[:cor]} x z y #{filenames[:cor]}`
  
  `fslroi #{file} #{filenames[:ax]} 0 -1 0 -1 #{z} 1`
  return filenames
end

def fn(dirname, basename, structure, orientation)
  file_name = dirname+'/'+basename+'_'+structure+'_'+orientation+'.nii.gz'
  return file_name
end

filenames_brain_lh = fsl_roi(options[:brain], 'lh', lh['x'], lh['y'], lh['z'])
filenames_stats_lh = fsl_roi(options[:stats], 'lh', lh['x'], lh['y'], lh['z'])


#cmd = `du -sh #{brain_file}`
#system(cmd)

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

# Read files :
def decompress(filename)
  basename = File.basename(filename, '.nii.gz')
  dirname = File.dirname(filename)
  `gzip -d #{filename}`
  filename_d = dirname+'/'+basename+'.nii'
  return filename_d
end

def image_gen(brain_slice, stats_slice, coordinates, orientation)
  brain_slice_d = decompress(brain_slice)
  stats_slice_d = decompress(stats_slice)
  crosshair_size = 50
  brain_hash = read_file(orientation,"brain",brain_slice_d)
  stats_hash = read_file(orientation,"stats",stats_slice_d)
  if orientation == 'axial'
      hipocenter = [coordinates["x"],coordinates["y"]] 
  elsif orientation == 'coronal'
      hipocenter = [coordinates["x"],coordinates["z"]]
  elsif orientation == 'sagital'
      hipocenter = [coordinates["y"],coordinates["z"]]
  end
  puts hipocenter.inspect
  # Create PNG
  generate_png(brain_hash,stats_hash, hipocenter, crosshair_size)
end

#Axial
image_gen(filenames_brain_lh[:ax], filenames_stats_lh[:ax], lh, 'axial')
#Sagital
image_gen(filenames_brain_lh[:sag], filenames_stats_lh[:sag], lh, 'sagital')
#Coronal
image_gen(filenames_brain_lh[:cor], filenames_stats_lh[:cor], lh, 'coronal')

################# PDF Generation ##################
Prawn::Document.generate('report.pdf') do |pdf| 
  # Title
  pdf.text "Hippocampal Volume Analysis Report" , size: 15, style: :bold, :align => :center
  pdf.move_down 10
  
  # Report Info
  pdf.formatted_text [ { :text => "Accession No.: ", :styles => [:bold], size: 10 }, { :text => AccessionNo, size: 10 }]
  pdf.formatted_text [ { :text => "Patient name: ", :styles => [:bold], size: 10 }, { :text => PatientName, :styles => [:bold], size: 10 }]
  pdf.formatted_text [ { :text => "Patient ID: ", :styles => [:bold], size: 10 }, { :text => PatientID, size: 10 }]
  pdf.formatted_text [ { :text => "Patient Birthdate: ", :styles => [:bold], size: 10 }, { :text => PatientBirthdate, size: 10 }]
  pdf.move_down 10

  # SubTitle
  pdf.text "Right Hippocampus" , size: 13, style: :bold, :align => :center
  pdf.move_down 5
  
  # Images
  pdf.image "axial.png", :width => 300, :height => 300, :position => 7
  pdf.move_up 300
  pdf.image "sagital.png", :width => 200, :height => 150, :position => 310
  pdf.image "coronal.png", :width => 200, :height => 150, :position => 310
  pdf.move_down 10
  
  # Volumes Table
  pdf.table([ ["Right Hippocampus volume", "123.45"],
            ["Left Hippocampus volume", "223.45"]])
end