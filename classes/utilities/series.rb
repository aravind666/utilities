
class Series
	#
	# initialize series migration
	#
	def initialize
		series_data = Mediahelper.get_all_series()
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
      series_title = series['Title'].to_s
      series_image_file.gsub!('../../../', '')
      series_image_file1.gsub!('../../../', '')
      series_title.gsub!( /"/, '')
      series_title.gsub!( ':', '-')
      if series_image_file1=='' || series_image_file1.nil?
        series_image = "http://www.crossroads.net/players/media/series/#{series_image_file}"
      else
        series_image = "http://www.crossroads.net/players/media/series/#{series_image_file1}"
      end
      permalink = Contenthelper.purify_title_by_removing_special_characters(series_title.downcase.strip)
      series_description = Contenthelper.purify_by_removing_special_characters(series['Description'])
      series_description = series_description.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      front_matter = "---\nlayout: series\nseries: \"#{series_title}\"\npermalink: \"\/#{permalink}/\""
      front_matter += "\ntitle: #{series_title}"
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
      #puts series_front_matter
      target_file_path = "#{Immutable.config.series_destination_path}/"
      title = Contenthelper.purify_title_by_removing_special_characters(series_data['Title'].downcase.strip)
      target_file_path += "#{series_data['StartDate'].strftime('%Y-%m-%d-%H-%M-%S')}-#{title}.md"
      migrated_audio_file_handler = File.open(target_file_path, 'w')
      migrated_audio_file_handler.write(series_front_matter)
    end
  end
end
