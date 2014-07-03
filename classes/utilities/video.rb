# encoding: ASCII-8BIT

# Video class defines the migration logic and uses the related helper 
# class for fetching the data
#
# Author::    Sandeep A R  (mailto:sandeep.setty@costrategix.com)
# Copyright:: Copyright (c) 2014 Crossroads
# License::   MIT
#
# Initiating this class leads to migration of videos
#
class Video

  #
  # Create Video object by initializing the migration flow
  #
  def initialize
    #File.delete('media_images.log') if File.exist?('media_images.log');
    self.migrate_media_content();
  end

  #
  # Function to migrate the media content - FOR LATER USE
  #
  def migrate_media
    begin
      series_data = Mediahelper.get_all_series();
      self.process_series_data(series_data);
    end
  end

  #
  # Function to process the series data. - FOR LATER USE
  #
  # * get the message for each series
  #
  # video.process_series_data(array)
  #
  def process_series_data(series_data)
    begin
      series_data.each do |series|
        message_data = Mediahelper.get_all_messages_for_series(series[0]);
        process_message_data(message_data, series);
      end
      abort('Successfully migrated videos in specified destination');
    end
  end

  #
  # Function to get the media content
  # * gets all media content
  # * for every content creates the video post
  #
  def migrate_media_content
    begin
      media_content = Mediahelper.get_media_content;
      if media_content.fetchable? then
        self.create_video_posts_for_each_video_content(media_content);
      else
        Immutable.log.info "There are no media content available";
      end
    end
    abort('Successfully migrated media in the specified destination');
  end

  #
  # This method will process message details by collecting
  # all its media content before migration - FOR LATER USE
  #
  def process_message_data(message_data, series)
    begin
      message_data.each do |message|
        media_content = Mediahelper.get_video_media_content_for_message(message[0]);
        if media_content.fetchable? then
          self.create_video_posts_for_each_video_content(media_content);
        else
          Immutable.log.info "Message  #{message[0]} does not have any video content";
        end
      end
    end
  end


  #
  # Add media video content front matter
  # this can be used by liquid variables in media layout .
  #
  # * for every post check for video availability
  # * add the jekyll matter for every video file
  # * migrate the file to destination
  #
  # video.create_video_posts_for_each_video_content(array)
  #
  def create_video_posts_for_each_video_content(media_content)
    begin
      media_content.each do |media|
        if media['iPodVideo'].length > 0
          front_matter = self.get_jekyll_front_matter_video_post(media);
          self.migrate_by_adding_jekyll_front_matter(front_matter, media);
        end
      end
    end
  end

  #
  # This method returns the frontmatter YAML for the media
  # which is about to get migrated
  #
  # * purify the description to have a clean data
  # * get the related information for jekyll front matter
  # * prepares the layout required for jekyll
  #
  # video.get_jekyll_front_matter_video_post(array)
  #
  def get_jekyll_front_matter_video_post(media)
    front_matter = "";

    mainTitle = media['Title'].gsub /"/, '';
    video_description = ContentHelper.purify_by_removing_special_characters(media['Description']);
    video_poster = media['ThumbImagePath'];
    #ContentHelper.copy_required_media_images_to_folder(video_poster)
    video_poster = "/uploadedfiles/#{video_poster}"
    video_poster = ContentHelper.replace_image_sources_with_new_paths(video_poster)


    front_matter = "---\nlayout: media\ncategory: media\ntitle: \"#{mainTitle}\"";
    front_matter += "\ndate: #{media["UploadDate"].strftime("%Y-%m-%d")}";
    front_matter += "\ndescription: \"#{video_description}\""
    uri = URI.parse(ContentHelper.encode_url_string(media['iPodVideo']))
    video_filename = File.basename(uri.path)
    video_file_path = "#{Immutable.config.s3url}/other-media/video/#{video_filename}"
    front_matter += "\nvideo: \"#{video_file_path}\"";
    front_matter += "\nvideo-poster: \"#{video_poster}\"";
    front_matter += "\n---";
    return front_matter;
  end


  #
  # Creates a jekyll page by applying necessary front matter
  #
  # * specifies the destination path
  # * lower case the title and remove the trailing and leading spaces
  # * the file name format needs to be with the date, time appended to a title
  # * open the file and write the data
  #
  # video.migrate_by_adding_jekyll_front_matter(string, array)
  #
  def migrate_by_adding_jekyll_front_matter(jekyll_front_matter, media)
    begin
      target_file_path = "#{Immutable.config.video_destination_path}/";
      title = ContentHelper.purify_title_by_removing_special_characters(media["Title"].downcase.strip);
      target_file_path += "#{media["UploadDate"].strftime("%Y-%m-%d-%H-%M-%S")}-#{title}.md"
      migrated_message_file_handler = File.open(target_file_path, 'w')
      migrated_message_file_handler.write(jekyll_front_matter);
    end
  end
end
