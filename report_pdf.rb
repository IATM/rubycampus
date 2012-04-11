class ReportPdf < Prawn::Document
  require "digest"
  def initialize(report, view, current_user, current_ip)
    super(top_margin: 70)
    @report = report
    @reportmd5 =  Digest::MD5.hexdigest(report.text)
    @view = view
    repeat :all do
      header
      order_info
    end
    bounding_box([margin_box.left, cursor-10], :width => margin_box.width) do
      studies
      clinical_info
      findings
      signatures
    end
    footer(current_user, current_ip)
    pagination
    encrypt_document(:owner_password => :random,
                     :permissions => { :print_document     => true,
                                       :modify_contents    => false,
                                       :copy_contents      => false,
                                       :modify_annotations => false })
  end
  
  def header
    move_up 40
    image "#{Rails.root}/public"+@report.work_order.imaging_center.logo_url(:thumb) if @report.work_order.imaging_center.logo?
    move_down 10
    text I18n.t('pdf.title') , size: 15, style: :bold, :align => :center
  end
  
  def order_info
    move_down 20
    formatted_text [ { :text => "#{I18n.t('pdf.order_no')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.code}", size: 10 }]
    formatted_text [ { :text => "#{I18n.t('pdf.patient_name')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.patient.first_name} #{@report.work_order.patient.last_name} (#{@report.work_order.patient.age},#{ @report.work_order.patient.sex})", :styles => [:bold], size: 10 }]
    formatted_text [ { :text => "#{I18n.t('pdf.patient_id')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.patient.patident}", size: 10 }]
    formatted_text [ { :text => "#{I18n.t('pdf.imaging_center')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.imaging_center.name} , #{@report.work_order.imaging_center.location}", size: 10 }]
    formatted_text [ { :text => "#{I18n.t('pdf.billing_scheme')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.billing_scheme.name} , #{@report.work_order.billing_scheme.code}", size: 10 }]
    formatted_text [ { :text => "#{I18n.t('pdf.created_at')}: ", :styles => [:bold], size: 10 }, { :text => "#{@report.work_order.created_at.to_s(:short)}", size: 10 }]
    move_down 5
    stroke_horizontal_rule
  end
  
  def studies
    text "#{I18n.t('pdf.studies')}: ", size: 10, style: :bold
    @report.work_order.studies.each do |study|
			text "[#{study.modality}] #{study.description}", size: 10
		end
  end
  
  def clinical_info
    move_down 10
    text "#{I18n.t('pdf.clinical_info')}: ", size: 10, style: :bold
    text @report.work_order.clinical_info, size: 10
    move_down 5
    stroke_horizontal_rule
    end
  
  def findings
    move_down 10
    text "#{I18n.t('pdf.findings')}: ", size: 12, style: :bold
    text @report.text
  end
  
  def signatures
    move_down 20
    if @report.users
				@report.users.each do |radiologist|
					if radiologist.has_role? :radiologist
					  image "#{Rails.root}/public"+radiologist.firma_url(:thumb) if radiologist.firma?
					  text "#{radiologist.first_name} #{radiologist.last_name}, MD", size: 12, style: :bold
					  formatted_text [{ :text => "#{I18n.t('pdf.license_no')} #{radiologist.medical_license_no}", :size => 10 }]
					  formatted_text [{ :text => " (#{I18n.t('pdf.digitally_signed_on')} #{@report.signed_at.to_s(:short) if @report.signed_at})", :styles => [:italic], :size => 8 }]
          end
				end
		end
		move_down 10
		if @report.users
				@report.users.each do |transcriptionist|
					if transcriptionist.has_role? :transcriptionist
					  formatted_text [ { :text => "#{I18n.t('pdf.transcribed_by')}: ", :styles => [:bold] }, { :text => "#{transcriptionist.first_name} #{transcriptionist.last_name}" }]
          end
				end
		end
  end
  
  def footer(curruser, currip)
    move_down 20
    formatted_text [ { :text => "#{I18n.t('pdf.printed_at')}: ", :styles => [:bold], size: 7 }, { :text => "#{Time.zone.now}", size: 7 },
                     { :text => " #{I18n.t('pdf.by')}: ", :styles => [:bold], size: 7 }, { :text => "#{curruser.first_name} #{curruser.last_name}", size: 7 },
                     { :text => " #{I18n.t('pdf.from')}: ", :styles => [:bold], size: 7 }, { :text => "#{currip}", size: 7 },
                     { :text => " #{I18n.t('pdf.md5')}: ", :styles => [:bold], size: 7 }, { :text => "#{@reportmd5}", size: 7 }
                   ]
  end
  
  def pagination
    string = I18n.t('pdf.page') + ' <page> ' + I18n.t('pdf.of') + ' <total>'
      options = { :at => [bounds.right - 150, 0],
                  :size => 10,
                  :width => 150,
                  :align => :right,
                  :start_count_at => 1,
                  :color => "333333" }
      number_pages string, options
  end
end