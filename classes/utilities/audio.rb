# encoding: ASCII-8BIT
#
# audio class which defines various attributes and behaviours which are used to migrate
# Audio content as separate collection in Jekyll
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Initiating this class leads to migration of audio content
#
class Audio

  #
  # Initialize the audio content migration process
  #
  def initialize
    File.delete('audio_images.log') if File.exist?('audio_images.log')
    self.migrate_audio_content
  end

  # Public: migrate audio content
  #
  # Gets all audio content from DB
  # to generate audio content jekyll front matter
  #
  def migrate_audio_content
    begin
      audio_data = Mediahelper.get_audio_content
      self.create_audio_posts_for_each_audio_content(audio_data)
    end
  end

  # Public: generates jekyll front matter for each audio post
  #
  # *audio_content* - Array of audio content records
  #
  # Returns success message
  #
  def create_audio_posts_for_each_audio_content(audio_content)
    begin
      audio_content.each do |audio|
        if  audio[0] > 0
          audio_front_matter = self.get_jekyll_front_matter_for_audio(audio)
          self.migrate_audio_by_adding_jekyll_front_matter(audio_front_matter, audio)
        else
          Immutable.log.info "Audio  #{audio[0]} does not have any audio content"
        end
      end
      abort('Successfully migrated audio content in specified destination')
    end
  end

  # Public: prepares jekyll front matter for audio content
  #
  # *audio* - Array audio content data to prepare jekyll front matter
  #
  # Returns audio content jekyll front matter
  #
  def get_jekyll_front_matter_for_audio(audio)
    begin
      front_matter = ''
      default_audio_image_thumb = 'DefaultVideoImage.jpg'
      audio_title = audio['Title'].gsub /"/, ''
      audio_description = ContentHelper.purify_by_removing_special_characters(audio['Description'])
      lq_file_path = audio['LowQFilePath']
      audio_file_path = "#{Immutable.config.s3url}/music/audio/#{ContentHelper.encode_url_string(audio['HighQFilePath'])}";
      audio_thumb_image = audio['ThumbImagePath'].to_s
      audio_poster = ''
      if audio_thumb_image && !audio_thumb_image.nil? && !audio_thumb_image.empty?
        audio_poster = audio['ThumbImagePath']
        audio_poster = "#{audio_poster}"
      elsif audio_thumb_image=='' || audio_thumb_image=='NULL' || audio_thumb_image==' ' || audio_thumb_image.empty?
        audio_poster = default_audio_image_thumb
      end
      audio_poster = "/images/uploadedImages/#{audio_poster}"
      audio_poster = ContentHelper.replace_image_sources_with_new_paths(audio_poster)
      if audio['duration'] == ':'
        audio['duration'] = '00:00'
      end
      front_matter = "---\nlayout: music \ntitle: \"#{audio_title}\""
      front_matter += "\ndate: #{audio['UploadDate'].strftime('%Y-%m-%d')}"
      front_matter += " \ndescription: \"#{audio_description}\""
      front_matter += "\naudio: \"#{audio_file_path}\"\naudio-duration: \"#{audio['duration']}\""
      front_matter += "\nsrc: \"#{audio_poster}\""
      front_matter += "\n---"
      return front_matter
    end
  end

  # Public: creates a jekyll page for audio content
  #
  # *audio_front_matter* - String audio content jekyll front matter to write to the file
  # *audio_data* - Array audio data to create a file name with title and date
  #
  # Return file by writing the audio content front matter to the given destination path
  #
  def migrate_audio_by_adding_jekyll_front_matter(audio_front_matter, audio_data)
    begin
      target_file_path = "#{Immutable.config.audio_destination_path}/"
      title = ContentHelper.purify_title_by_removing_special_characters(audio_data['Title'].downcase.strip)
      target_file_path += "#{audio_data['UploadDate'].strftime('%Y-%m-%d-%H-%M-%S')}-#{title}.md"
      migrated_audio_file_handler = File.open(target_file_path, 'w')
      migrated_audio_file_handler.write(audio_front_matter)
    end
  end
end
