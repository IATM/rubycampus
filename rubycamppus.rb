#!/usr/bin/env ruby
require 'dcm2nii-ruby'
require 'fsl-ruby'
require 'narray'
require 'nifti'
require 'chunky_png'

LHipp_label = 17
RHipp_label = 53
LabelColor = ChunkyPNG::Color.rgb(0,125,209)

# Decompress NIFTI .gz files
def decompress(filename)
  basename = File.basename(filename, '.nii.gz')
  dirname = File.dirname(filename)
  `gzip -d #{filename}`
  filename_d = dirname+'/'+basename+'.nii'
  return filename_d
end

def read_nifti(nii_file)
  NIFTI::NObject.new(nii_file, :narray => true).image.to_i
end

def get_2d_slice(ni3d, dim, slice_num)
  puts "Extracting 2D slice number #{slice_num} on dimension #{dim} for volume."
  if dim == 1
    ni3d[slice_num,true,true]
  elsif dim == 2
    ni3d[true,slice_num,true]
  elsif dim == 3
    ni3d[true,true,slice_num]
  else
    raise "No valid dimension specified for slice extraction"
  end
end

def png_from_nifti_img(ni2d) # Create PNG object from NIFTI image NArray 2D Image
  puts "Creating PNG image for 2D nifti slice"
  # Create PNG
  png = ChunkyPNG::Image.new(ni2d.shape[0], ni2d.shape[1], ChunkyPNG::Color::TRANSPARENT)

  # Fill PNG with values from slice NArray
  png.height.times do |y|
    png.row(y).each_with_index do |pixel, x|
      val = ni2d[x,y]
      png[x,y] = ChunkyPNG::Color.rgb(val, val, val)
    end
  end

  # return PNG
  return png
end

def generate_label_map_png(base_slice, label_slice,label) # Applies a label map over a base image
  base_png = png_from_nifti_img(base_slice)
  # Fill PNG with values from slice NArray
  base_png.height.times do |y|
    base_png.row(y).each_with_index do |pixel, x|
      val = label_slice[x,y]
      base_png[x,y] = LabelColor if val == label
    end
  end

  # return PNG
  return base_png
end

def generate_png_slice(nii_file, dim, slice)
  nifti = NIFTI::NObject.new(nii_file, :narray => true).image.to_i
  nifti_slice = get_2d_slice(nifti, dim, sel_slice)
  png = png_from_nifti_img(nifti_slice)
  return png
end

def coord_map(coord)
  lh = {}
  rh = {}
  axis = ["x", "y", "z"]

  (0..2).each do |i|
    lh[axis[i]] = coord[i].to_i.round
  end

  (3..5).each do |i|
    rh[axis[i-3]] = coord[i].to_i.round
  end
  return [lh,rh]
end
#### END METHODS ####

# CONVERT DICOM TO NIFTI
dn = Dcm2nii::Runner.new('/Users/simonmd/Desktop/rubycamppus_tests/input/dicom',{anonymize: false, reorient_crop:false, reorient:false, output_dir: '/Users/simonmd/Desktop/rubycamppus_tests/output'}) # creates an instance of the DCM2NII runner
dn.command # runs the utility
original_image = dn.get_nii # Returns the generated nifti file

# PERFORM BRAIN EXTRACTION
bet = FSL::BET.new(original_image, '/Users/simonmd/Desktop/rubycamppus_tests/output', {fi_threshold: 0.5, v_gradient: 0})
bet.command
bet_image = bet.get_result

# PERFORM 'FIRST' SEGMENTATION
first = FSL::FIRST.new(bet_image, '/Users/simonmd/Desktop/rubycamppus_tests/output/test_brain_FIRST', {already_bet:true, structure: 'L_Hipp,R_Hipp'})
first.command
first_images = first.get_result

# Get Hippocampal center of gravity coordinates
cog_coords = FSL::Stats.new(first_images[:origsegs], true, {cog_voxel: true}).command.split
lh_cog, rh_cog = coord_map(cog_coords)
puts "Left Hippocampus center of gravity voxel coordinates: #{lh_cog}"
puts "Right Hippocampus center of gravity voxel coordinates: #{rh_cog}"

# Get Hippocampal volumes
lhipp_vol = FSL::Stats.new(first_images[:firstseg], false, {low_threshold: LHipp_label - 0.5, up_threshold: LHipp_label + 0.5, voxels_nonzero: true}).command.split[0].to_i
puts "Left hippocampal volume: #{lhipp_vol}"
rhipp_vol = FSL::Stats.new(first_images[:firstseg], false, {low_threshold: RHipp_label - 0.5, up_threshold: RHipp_label + 0.5, voxels_nonzero: true}).command.split[0].to_i
puts "Right hippocampal volume: #{rhipp_vol}"

# Decompress files
anatomico_nii = decompress(bet_image)
hipocampos_nii= decompress(first_images[:firstseg])

# Set  nifti file
anatomico_3d_nifti = read_nifti(anatomico_nii)
hipocampos_3d_nifti = read_nifti(hipocampos_nii)

# Select the dimension to process
sel_dim = 2 # No hay manera de extraer eso del NIFTI. Para axiales parece que 1=sagital, 2=coronal, 3=axial
# Select slice to process
sel_slice = 120

anatomico_2d_slice = get_2d_slice(anatomico_3d_nifti, sel_dim, sel_slice)
hipocampos_2d_slice = get_2d_slice(hipocampos_3d_nifti, sel_dim, sel_slice)

# Overlay hippocampus label map and flip for display
labeled_png = generate_label_map_png(anatomico_2d_slice, hipocampos_2d_slice, LHipp_label).flip_horizontally!
# Save Labeled PNG
labeled_png.save('labeled.png', :interlace => true)