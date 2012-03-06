require "nifti"
# Read file:
obj = NIFTI::NObject.new("samples/brain.nii", :narray => true)
# Display some key information about the file:
 # puts obj.header['pixdim']
#  puts obj.header['scl_inter']

max = obj.image.max
puts max
#stddev = obj.image.stddev
