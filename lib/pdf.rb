Prawn::Document.generate('report.pdf') do |pdf|
  # Title
  pdf.text "Hippocampal Volume Analysis Report" , size: 15, style: :bold, :align => :center
  pdf.move_down 10

  # Report Info
  pdf.formatted_text [ { :text => "Accession No.: ", :styles => [:bold], size: 10 }, { :text => AccessionNo, size: 10 }]
  pdf.formatted_text [ { :text => "Patient name: ", :styles => [:bold], size: 10 }, { :text => PatientName, :styles => [:bold], size: 10 }]
  pdf.formatted_text [ { :text => "Patient ID: ", :styles => [:bold], size: 10 }, { :text => PatientID, size: 10 }]
  pdf.formatted_text [ { :text => "Patient Birthdate: ", :styles => [:bold], size: 10 }, { :text => PatientBirthdate, size: 10 }]
  pdf.move_down 5

  # SubTitle RH
  pdf.text "Right Hippocampus" , size: 13, style: :bold, :align => :center
  pdf.move_down 5

  # Images RH
  pdf.image "rh_axial.png", :width => 200, :height => 200, :position => 20
  pdf.move_up 200
  pdf.image "rh_sagital.png", :width => 150, :height => 100, :position => 210
  pdf.image "rh_coronal.png", :width => 150, :height => 100, :position => 210
  pdf.move_down 5

  # SubTitle LH
  pdf.text "Left Hippocampus" , size: 13, style: :bold, :align => :center
  pdf.move_down 5

  # Images LH
  pdf.image "lh_axial.png", :width => 200, :height => 200, :position => 20
  pdf.move_up 200
  pdf.image "lh_sagital.png", :width => 150, :height => 100, :position => 210
  pdf.image "lh_coronal.png", :width => 150, :height => 100, :position => 210
  pdf.move_down 5


  # Volumes Table
  pdf.table([ ["Right Hippocampus volume", "123.45"],
              ["Left Hippocampus volume", "223.45"]])
end