# encoding: ASCII-8BIT
#
# series class which defines various attributes and behaviours which are used to migrate
# Series content as separate collection in Jekyll
#
# Author::    Hanumantharaju T (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Initiating this class leads to migration of series content
#
class Series

	#
	# initialize series migration
	#
	def initialize
		series_data = Mediahelper.get_all_series
		self.process_series_data(series_data)
	end
	
	#
  # This method will process all series data
  #
  def process_series_data(series_data)
    begin
      series_data.each do |series|
        front_matter = self.get_jekyll_frontmatter_for_series(series);
        self.migrate_audio_by_adding_jekyll_front_matter(front_matter, series)
      end
      abort('Successfully migrated series in specified destination');
    end
  end

  # Public: prepares jekyll front matter for series content
  #
  # *series* - Array series content data to prepare jekyll front matter
  #
  # Returns series content jekyll front matter
  #
  def get_jekyll_frontmatter_for_series(series)
    begin
      front_matter = ''
      series_image = ''
      series_title = ''

      series_image_file = series['ImageFile'].to_s
      series_image_file1 = series['ImageFile1'].to_s
      series_image_file2 = series['ImageFile2'].to_s
      series_title = series['Title'].to_s
      series_description =  series['Description'].to_s
      series_image_file.gsub!('../../../', '')
      series_image_file1.gsub!('../../../', '')
      #series_title.gsub!( /"/, '')
      #series_title.gsub!( ':', '-')
      if series_image_file2 != ''
        series_image = series_image_file2
      elsif series_image_file1 != ''
        series_image = series_image_file1
      elsif series_image_file != ''
        series_image = series_image_file
      else
        series_image = 'GenericCrnerSign.jpg'
      end
      if series_image['img/graphics/']
        series_image = series_image.gsub('img/graphics/', '')
      end

      series_image = ContentHelper.replace_image_sources_with_new_paths("/players/media/series/#{series_image}")
      permalink = ContentHelper.purify_title_by_removing_special_characters(series_title.downcase.strip)
      series_description = ContentHelper.purify_by_removing_special_characters(series_description)
      series_description = series_description.strip_control_characters
      series_description = series_description.encode('utf-8', 'binary', :invalid => :replace,:undef => :replace, :replace => '')

      front_matter = "---\nlayout: series\nseries: \"#{series_title}\"\npermalink: \"\/#{permalink}/\""
      front_matter += "\ntitle: \"#{series_title}\""
      front_matter += "\ndate: #{series['StartDate'].strftime('%Y-%m-%d %H:%M:%S')}"
      front_matter += "\nendDate: #{series['EndDate'].strftime('%Y-%m-%d %H:%M:%S')}"
      front_matter += "\ndescription: \"#{series_description}\""
      front_matter += "\nsrc: \"#{series_image}\""
      front_matter += "\n---"
      return front_matter
    end
  end

  # Public: creates a jekyll page for series content
  #
  # *series_front_matter* - String series content jekyll front matter to write to the file
  # *series_data* - Array series data to create a file name with title and date
  #
  # Return file by writing the series content front matter to the given destination path
  #
  def migrate_audio_by_adding_jekyll_front_matter(series_front_matter, series_data)
    begin
      target_file_path = "#{Immutable.config.series_destination_path}/"
      title = ContentHelper.purify_title_by_removing_special_characters(series_data['Title'].downcase.strip)
      target_file_path += "#{series_data['StartDate'].strftime('%Y-%m-%d-%H-%M-%S')}-#{title}.md"
      migrated_audio_file_handler = File.open(target_file_path, 'w')
      migrated_audio_file_handler.write(series_front_matter)
    end
  end
end
