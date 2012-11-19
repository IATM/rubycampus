#!/usr/bin/env ruby
require 'dcm2nii-ruby'
require 'fsl-ruby'
require 'narray'
require 'nifti'
require 'chunky_png'
require 'optparse'
require 'prawn'

options = {}
option_parser = OptionParser.new do |opts|

  opts.on("-f DICOMDIR", "The DICOM directory") do |dicomdir|
    options[:dicomdir] = dicomdir
  end

  opts.on("-o OUTPUTDIR", "The output directory") do |outputdir|
    options[:outputdir] = outputdir
  end

  opts.on("-d ORIENTATION", "The slices orientation, e.g. sagital, coronal or axial") do |orientation|
    options[:orientation] = orientation
  end

  opts.on("-s", "--studyInfo patfName,patlName,patId,studyDate, accessionNo", Array, "The study information for the report") do |study|
      options[:study] = study
  end

end

option_parser.parse!

LHipp_label = 17
RHipp_label = 53
LabelColor = ChunkyPNG::Color.rgb(255,0,0)
patfName = options[:study][0]
patlName = options[:study][1]
patId = options[:study][2]
studyDate = options[:study][3]
accessionNo = options[:study][4]

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

def get_2d_slice(ni3d, dim, slice_num,orientation)
  puts "Extracting 2D slice number #{slice_num} on dimension #{dim} for volume."
  #case orientation
    #when 'axial'
    if dim == 1
      ni3d[slice_num,true,true]
    elsif dim == 2
      ni3d[true,slice_num,true]
    elsif dim == 3
      ni3d[true,true,slice_num]
    else
      raise "No valid dimension specified for slice extraction"
    end
    #when 'sagital'
    #end
end

def normalise(x,xmin,xmax,ymin,ymax)
    xrange = xmax-xmin
    yrange = ymax-ymin
    ymin + (x-xmin) * (yrange.to_f / xrange)
end

def png_from_nifti_img(ni2d) # Create PNG object from NIFTI image NArray 2D Image
  puts "Creating PNG image for 2D nifti slice"
  # Create PNG
  png = ChunkyPNG::Image.new(ni2d.shape[0], ni2d.shape[1], ChunkyPNG::Color::TRANSPARENT)

  # Fill PNG with values from slice NArray
  png.height.times do |y|
    png.row(y).each_with_index do |pixel, x|
      val = ni2d[x,y]
      valnorm = normalise(val, ni2d.min, ni2d.max, 0, 255).to_i
      png[x,y] = ChunkyPNG::Color.rgb(valnorm, valnorm, valnorm)
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

beginning_time = Time.now

# CONVERT DICOM TO NIFTI
dn = Dcm2nii::Runner.new(options[:dicomdir],{anonymize: false, reorient_crop:false, reorient:false, output_dir: options[:outputdir]}) # creates an instance of the DCM2NII runner
dn.command # runs the utility
original_image = dn.get_nii # Returns the generated nifti file

# PERFORM BRAIN EXTRACTION
bet = FSL::BET.new(original_image, options[:outputdir], {fi_threshold: 0.5, v_gradient: 0})
bet.command
bet_image = bet.get_result

case options[:orientation]
when 'sagital'
  `fslswapdim #{bet_image} -z -x y #{bet_image}`
when 'coronal'
  `fslswapdim #{bet_image} x -z y #{bet_image}`
end

# PERFORM 'FIRST' SEGMENTATION
first = FSL::FIRST.new(bet_image, options[:outputdir]+'/test_brain_FIRST', {already_bet:true, structure: 'L_Hipp,R_Hipp'})
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

(1..3).each do |sel_dim|
	# Left Hippocampus
	sel_slice = lh_cog.values[sel_dim-1]
 	lh_anatomico_2d_slice = get_2d_slice(anatomico_3d_nifti, sel_dim, sel_slice, options[:orientation])
	lh_hipocampos_2d_slice = get_2d_slice(hipocampos_3d_nifti, sel_dim, sel_slice, options[:orientation])
	# Overlay hippocampus label map and flip for display
	lh_labeled_png = generate_label_map_png(lh_anatomico_2d_slice, lh_hipocampos_2d_slice, LHipp_label).flip_horizontally!
	# Save Labeled PNG
	lh_labeled_png.save("#{options[:outputdir]}/lh_#{sel_dim}_labeled.png")

	# Right Hippocampus
	sel_slice = rh_cog.values[sel_dim-1]
 	rh_anatomico_2d_slice = get_2d_slice(anatomico_3d_nifti, sel_dim, sel_slice, options[:orientation])
	rh_hipocampos_2d_slice = get_2d_slice(hipocampos_3d_nifti, sel_dim, sel_slice, options[:orientation])
	# Overlay hippocampus label map and flip for display
	rh_labeled_png = generate_label_map_png(rh_anatomico_2d_slice, rh_hipocampos_2d_slice, RHipp_label).flip_horizontally!
	# Save Labeled PNG
      rh_labeled_png.save("#{options[:outputdir]}/rh_#{sel_dim}_labeled.png")
end


# Generate PDF
Prawn::Document.generate("#{options[:outputdir]}/report.pdf") do |pdf|
  # Title
  pdf.text "Hippocampal Volume Analysis Report" , size: 15, style: :bold, :align => :center
  pdf.move_down 10

  # Report Info
  pdf.formatted_text [ { :text => "Accession No.: ", :styles => [:bold], size: 10 }, { :text => "#{accessionNo}", size: 10 }]
  pdf.formatted_text [ { :text => "Patient name: ", :styles => [:bold], size: 10 }, { :text => "#{patfName} #{patlName}", :styles => [:bold], size: 10 }]
  pdf.formatted_text [ { :text => "Patient ID: ", :styles => [:bold], size: 10 }, { :text => "#{patId}", size: 10 }]
  pdf.formatted_text [ { :text => "Patient Birthdate: ", :styles => [:bold], size: 10 }, { :text => "#{studyDate}", size: 10 }]
  pdf.move_down 5

  # SubTitle RH
  pdf.text "Right Hippocampus" , size: 13, style: :bold, :align => :center
  pdf.move_down 5

  # Images RH
  pdf.image "#{options[:outputdir]}/rh_3_labeled.png", :width => 200, :height => 200, :position => 20
  pdf.move_up 200
  pdf.image "#{options[:outputdir]}/rh_2_labeled.png", :width => 150, :height => 100, :position => 210
  pdf.image "#{options[:outputdir]}/rh_1_labeled.png", :width => 150, :height => 100, :position => 210
  pdf.move_down 5

  # SubTitle LH
  pdf.text "Left Hippocampus" , size: 13, style: :bold, :align => :center
  pdf.move_down 5

  # Images LH
  pdf.image "#{options[:outputdir]}/lh_3_labeled.png", :width => 200, :height => 200, :position => 20
  pdf.move_up 200
  pdf.image "#{options[:outputdir]}/lh_2_labeled.png", :width => 150, :height => 100, :position => 210
  pdf.image "#{options[:outputdir]}/lh_1_labeled.png", :width => 150, :height => 100, :position => 210
  pdf.move_down 5


  # Volumes Table
  pdf.table([ ["Right Hippocampus volume", "#{rhipp_vol} mm3"],
                   ["Left Hippocampus volume", "#{lhipp_vol} mm3"]])
end

end_time = Time.now
puts "Time elapsed #{(end_time - beginning_time)} seconds"


