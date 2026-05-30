# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.configure do |config|
  # Path to the wkhtmltopdf executable
  # Using the wkhtmltopdf-binary gem
  config.exe_path = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
  
  # Needed for wkhtmltopdf 0.12.6+ to use many wicked_pdf asset helpers
  config.enable_local_file_access = true
  
  # Layout file to be used for all PDFs
  config.layout = 'pdf'
  
  # Enable xvfb for running wkhtmltopdf without an X server (for server environments)
  # config.use_xvfb = true
  
  # Default page size
  config.page_size = 'A4'
  
  # Default orientation
  config.orientation = 'Portrait'
  
  # Default margin settings
  config.margin = {
    top: 20,
    bottom: 20,
    left: 20,
    right: 20
  }
  
  # Default DPI setting
  config.dpi = 300
  
  # Enable JavaScript
  config.enable_javascript = true
  
  # Enable images
  config.enable_images = true
  
  # Disable smart shrinking (helps with text sizing)
  config.disable_smart_shrinking = false
end