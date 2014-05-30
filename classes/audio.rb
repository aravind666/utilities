# encoding: ASCII-8BIT

# message class which defines various attributes and behaviours which are used to migrate
# Message Audio content as seperate posts in Jekyll
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Instiating this class leads to migration of Audios
#

class Audio
	
	#
	# Create Content object by initilizing the migration flow
	#
	def initialize
		self.migrate_audio() 
	end
	
	#
	#This method actually migrates the content by creating the front matter
	#
	def migrate_audio
		begin
			series_data = Mediahelper.get_all_series() 
			self.process_series_data(series_data)
		end
	end
	
	#
	# This method will process series data by collecting all its respective messages
	#
	def process_series_data(series_data)
		begin
      series_data.each do |series|
        message_data = Mediahelper.get_all_messages_for_series(series[0])
        process_message_data(message_data, series)
      end
      abort('Successfully migrated audio content in specified destination')
    end
	end
	
	#
  # This method will process message details by collecting
  # all its audio content before migration
  #
  def process_message_data(message_data, series)
    begin
      message_data.each do |message|
        audio_content = Mediahelper.get_audio_content_for_message(message[0])
        if audio_content.column_names.size === 0 then
          Immutable.log.info "Message  #{message[0]} does not have any audio content"
        else
          front_matter = self.get_jekyll_frontmatter_for_audio(audio_content,series)
        end
      end
    end
  end
  
	#
  # Prepare Jekyll Frontmatter for migrated audio content
  #
  #
  def get_jekyll_frontmatter_for_audio(audio_content,series)
		begin
			# Audio
			audio_content.each do |audio|
				front_matter = ''
				audio_title = Contenthelper.purify_title_by_removing_special_characters(audio['Title'])
				audio_description = Contenthelper.purify_by_removing_special_characters(audio['Description'])

				audio_path = audio['LowQFilePath'] + audio['HighQFilePath'];
				front_matter =  "---\nlayout: music \ntitle: \"#{audio_title}\""
        front_matter += "\nseries: \"#{series[1]}\""
				front_matter += "\ndate: #{audio["ActiveDate"].strftime("%Y-%m-%d")}"
				front_matter += " \ndescription: \"#{audio_description}\""
				front_matter += "\naudio: \"#{audio_path}\"\n audio-duration: \"#{audio['duration']}\""
				front_matter += "\n---"
				self.migrate_audio_by_adding_jekyll_front_matter(front_matter, audio)
			end
		end
  end
  
  #
  # Creates a jekyll page by applying neccessary frontmatter
  #
  def migrate_audio_by_adding_jekyll_front_matter(jekyll_front_matter, audio_data)
    begin
      target_file_path = "#{Immutable.config.audio_destination_path}/";
      title = Contenthelper.purify_title_by_removing_special_characters(audio_data["Title"].downcase.strip);
      target_file_path += "#{audio_data["ActiveDate"].strftime("%Y-%m-%d")}-#{title}.md";
      migrated_audio_file_handler = File.open(target_file_path, 'w');
      migrated_audio_file_handler.write(jekyll_front_matter);
    end
  end
  
end


